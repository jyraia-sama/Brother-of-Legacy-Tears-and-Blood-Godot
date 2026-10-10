class_name CombatClasse
extends Node
## ARÈNE CLASSÉE : déroulement d'un combat MANUEL à deux joueurs (ajouté par l'écran de combat).
##
## Les deux appareils calculent le même combat (même graine, mêmes équipes, CombatMoteur en mode
## manuel). Chaque action a un numéro (0, 1, 2...) et le serveur garde la liste des actions :
##  - quand c'est au tour d'une de MES unités : je choisis (minuteur de 15 s, sinon l'IA choisit),
##    j'envoie l'action au serveur et je joue celle qu'il a retenue ;
##  - quand c'est au tour d'une unité ADVERSE : je lis les actions du serveur (toutes les secondes).
##    Si l'adversaire ne joue plus, l'IA joue à sa place au bout de 40 s, et s'il a quitté le jeu
##    depuis 60 s, la victoire par forfait est réclamée.
## À la fin, le résultat (le même des deux côtés) est envoyé au serveur, qui calcule les points.

const MINUTEUR := 15.0
const ATTENTE_ABSENCE := 42          # un peu plus que le délai du serveur (40 s)
const ATTENTE_FORFAIT := 62

var ecran: EcranCombat
var moteur: CombatMoteur
## Accès au serveur (remplaçable par un faux serveur pour les tests).
var reseau: Object = EnLigne
## Tests automatiques uniquement : faux serveur par camp (vide dans le jeu).
static var reseaux_test := {}
var _match: Dictionary
var _camp := 0
var _n := 0
var _cache := {}                     # n -> action déjà connue
var _fin := false
var _rattrapage := 0                 # reprise d'un combat : actions déjà jouées (rejouées sans animation)

# Interface
var _panneau: PanelContainer
var _lbl_titre: Label
var _lbl_info: Label
var _barre_temps: ProgressBar
var _zone_boutons: HBoxContainer
var _boutons_cibles: Array = []
var _choix_fait := {}
var _action_en_cours := {}
var _temps_restant := 0.0
var _choix_ouvert := false
var _halo: Panel


func _ready() -> void:
	_match = ecran.demande_combat["match"]
	_camp = ecran.mon_camp()
	if reseaux_test.has(_camp):
		reseau = reseaux_test[_camp]
	_construire()
	var ab := ecran._bouton("Abandonner")
	ab.pressed.connect(func():
		FenetreSimple.confirmer(ecran, "Abandonner le combat ?", "Le combat compte comme une défaite.", "Abandonner", _abandonner))
	ecran.barre_haut.add_child(ab)
	moteur.demarrer_manuel()
	# Reprise (jeu relancé pendant le combat) : on récupère les actions déjà jouées
	var r: Dictionary = await reseau.appeler("ac_actions", {"p_match": _match["id"], "p_depuis": 0})
	if r.ok and r.data is Dictionary:
		for a in r.data.get("actions", []):
			_cache[int(a["n"])] = a["action"]
		_rattrapage = _cache.size()
		if str(r.data.get("etat", "en_cours")) != "en_cours":
			await _verifier_fin_serveur()
			return
	_boucle()


# =====================================================================
# Boucle du combat
# =====================================================================

func _boucle() -> void:
	await _jouer_evenements()
	while not _fin:
		var c := moteur.prochain_acteur()
		await _jouer_evenements()
		if c.is_empty():
			break
		var action: Dictionary
		if int(c["camp"]) == _camp:
			action = await _mon_action(c)
		else:
			action = await _action_adverse(c)
		if _fin:
			return
		moteur.jouer_action(c, action)
		_n += 1
		await _jouer_evenements()
	if not _fin:
		_terminer(moteur.resultat_classe())


func _jouer_evenements() -> void:
	for ev in moteur.nouveaux_evenements():
		if _fin:
			return
		if _n < _rattrapage:
			ecran._appliquer_sans_animation(ev)
		else:
			await ecran._jouer(ev)


# ---------- Mes unités ----------

func _mon_action(c: Dictionary) -> Dictionary:
	var choix := {}
	if _cache.has(_n):
		choix = _cache[_n]
	else:
		choix = await _choisir(c)
	# Le serveur garde la première action reçue pour ce numéro
	while not _fin:
		var r: Dictionary = await reseau.appeler("ac_jouer", {"p_match": _match["id"], "p_n": _n, "p_camp": int(c["camp"]), "p_action": choix})
		if r.ok and r.data is Dictionary and r.data.get("ok", false):
			return r.data["action"]
		if r.ok and r.data is Dictionary and r.data.get("erreur", "") == "termine":
			await _verifier_fin_serveur()
			return {}
		_info("Connexion difficile… nouvel essai.")
		await get_tree().create_timer(1.5).timeout
	return {}


## Affiche les actions possibles et attend le choix du joueur (ou la fin du minuteur).
func _choisir(c: Dictionary) -> Dictionary:
	_choix_fait = {}
	_choix_ouvert = true
	_montrer_halo(int(c["idx"]))
	_panneau.visible = true
	_lbl_titre.text = UiCommun.t("À toi : %s") % c["nom"]
	_info("Choisis une action.")
	for b in _zone_boutons.get_children():
		b.queue_free()
	for a in moteur.actions_possibles(c):
		_zone_boutons.add_child(_carte_action(c, a))
	_temps_restant = MINUTEUR
	while _choix_fait.is_empty() and not _fin:
		await get_tree().process_frame
		_temps_restant -= get_process_delta_time()
		_barre_temps.value = maxf(0.0, _temps_restant)
		if _temps_restant <= 0.0:
			_choix_fait = {"type": "auto"}
			_info("Temps écoulé : action automatique.")
	_fermer_choix()
	return _choix_fait


# ---------- Cartes d'action (lisibles, une par sort) ----------

const C_CARTE_ATTAQUE := Color("c8b48a")
const C_CARTE_SORT := Color("ffb040")

## Une carte cliquable : icône + nom, ce que fait le sort en 1 à 3 lignes courtes, recharge.
func _carte_action(c: Dictionary, a: Dictionary) -> Control:
	var est_sort: bool = a["type"] == "skill"
	var dispo: bool = a["dispo"]
	var coul: Color = C_CARTE_SORT if est_sort else C_CARTE_ATTAQUE
	# Carte = panneau qui prend la hauteur de son texte (cliquable comme un bouton)
	var b := PanelContainer.new()
	b.custom_minimum_size = Vector2(250, 0)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if dispo else Control.CURSOR_ARROW
	var styles := {}
	for etat in ["normal", "hover", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.13, 0.07, 0.06, 0.96) if etat != "hover" else Color(0.27, 0.14, 0.08, 0.98)
		st.border_color = coul if etat != "disabled" else Color(0.35, 0.33, 0.33)
		st.set_border_width_all(3 if etat == "hover" else 2)
		st.set_corner_radius_all(10)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		styles[etat] = st
	b.add_theme_stylebox_override("panel", styles["normal"] if dispo else styles["disabled"])
	if dispo:
		b.mouse_entered.connect(func(): b.add_theme_stylebox_override("panel", styles["hover"]))
		b.mouse_exited.connect(func(): b.add_theme_stylebox_override("panel", styles["normal"]))
		b.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_clic_action(a))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	# Nom
	var icone := "⚔ " if not est_sort else "✦ "
	var nom := UiCommun.label(icone + str(a["nom"]), 19, coul if dispo else Color(0.6, 0.58, 0.58))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nom)
	# Ce que fait le sort
	var lignes := texte_court(str(a.get("description", "")))
	var eff := UiCommun.label("\n".join(lignes.map(func(l): return "• " + l)), 15,
		Color(0.95, 0.92, 0.88) if dispo else Color(0.55, 0.53, 0.53))
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eff.size_flags_vertical = Control.SIZE_EXPAND_FILL     # le pied reste en bas de la carte
	vb.add_child(eff)
	# Pied : cible et recharge
	var pied := ""
	var cibles: Array = a["cibles"]
	if cibles.size() > 1:
		pied = "🎯 Tu choisis la cible"
	elif est_sort:
		pied = {"ennemis": "Touche tous les ennemis", "allies": "Sur toute l'équipe", "soi": "Sur lui-même",
			"avant": "Ennemis de l'Avant", "arriere": "Ennemis de l'Arrière", "aleatoire": "Ennemis au hasard",
			"allie_faible": "L'allié le plus blessé"}.get(_cible_sort(c, a["nom"]), "Cible automatique")
	else:
		pied = "Cible automatique"
	if est_sort:
		if a.get("silence", false):
			pied = "⛔ Réduit au silence"
		elif int(a["recharge"]) > 0:
			pied = UiCommun.t("⏳ Prêt dans %d tour%s") % [int(a["recharge"]), "s" if int(a["recharge"]) > 1 else ""]
		elif not dispo:
			pied = "Inutile pour l'instant"
		else:
			var r := CombatMoteur.recharge_sort({"chance": _chance(c, a["nom"])})
			pied += UiCommun.t("  ·  recharge %d tour%s") % [r, "s" if r > 1 else ""]
	var lp := UiCommun.label(pied, 14, Color("ffd060") if dispo else Color("ff8a6a"))
	vb.add_child(lp)
	for l in [nom, eff, lp]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## Description simplifiée d'un sort pour l'arène classée, en lignes courtes :
## sans « (30 % de chance par tour) » (ici on choisit soi-même), sans la petite phrase d'ambiance.
static func texte_court(desc: String) -> Array:
	var re := RegEx.new()
	re.compile("^\\(\\d+ ?% de chance par tour\\)\\s*")
	var t := re.sub(desc.strip_edges(), "")
	# « Tourne sur lui-même, lame tendue : inflige ... » -> « Inflige ... »
	var i := t.find(" : ")
	if i > 0 and not t.substr(0, i).contains("%"):
		t = t.substr(i + 3)
	t = t.replace(" de puissance de skill", " de puissance").replace("puissance de skill", "puissance")
	t = t.replace("de chance d'infliger", "de chance :").replace("toute l'équipe", "l'équipe")
	var l: Array = []
	for morceau in t.split(" ; ", false):
		var m := morceau.strip_edges().trim_suffix(".")
		if m != "":
			l.append(m.substr(0, 1).to_upper() + m.substr(1))
	if l.is_empty():
		l.append("Attaque normale")
	return l


func _cible_sort(c: Dictionary, nom: String) -> String:
	for sk in c["actifs"]:
		if sk["nom"] == nom:
			return str(sk.get("cible", ""))
	return ""


func _chance(c: Dictionary, nom: String) -> float:
	for sk in c["actifs"]:
		if sk["nom"] == nom:
			return float(sk.get("chance", 0.3))
	return 0.3


func _clic_action(a: Dictionary) -> void:
	if not _choix_ouvert:
		return
	_effacer_cibles()
	var cibles: Array = a["cibles"]
	if cibles.is_empty():
		_choix_fait = {"type": a["type"], "skill": a["nom"], "cible": -1}
		return
	if cibles.size() == 1:
		_choix_fait = {"type": a["type"], "skill": a["nom"], "cible": int(cibles[0])}
		return
	_action_en_cours = a
	_info(UiCommun.t("%s : choisis une cible.") % a["nom"])
	for idx in cibles:
		var carte: Dictionary = ecran._cartes[int(idx)]
		var racine: Control = carte["racine"]
		var b := Button.new()
		b.flat = false
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 0.2, 0.1, 0.12)
		st.border_color = Color("ff5a3a")
		st.set_border_width_all(3)
		st.set_corner_radius_all(12)
		b.add_theme_stylebox_override("normal", st)
		var st2 := st.duplicate() as StyleBoxFlat
		st2.bg_color = Color(1, 0.3, 0.1, 0.3)
		b.add_theme_stylebox_override("hover", st2)
		b.add_theme_stylebox_override("pressed", st2)
		b.position = racine.position - Vector2(6, 6)
		b.size = racine.size + Vector2(12, 12)
		b.pressed.connect(func():
			_choix_fait = {"type": _action_en_cours["type"], "skill": _action_en_cours["nom"], "cible": int(idx)})
		ecran._arene.add_child(b)
		_boutons_cibles.append(b)


func _effacer_cibles() -> void:
	for b in _boutons_cibles:
		if is_instance_valid(b):
			b.queue_free()
	_boutons_cibles.clear()


func _fermer_choix() -> void:
	_choix_ouvert = false
	_effacer_cibles()
	_panneau.visible = false
	if _halo != null:
		_halo.visible = false


# ---------- Unités adverses ----------

func _action_adverse(c: Dictionary) -> Dictionary:
	_montrer_halo(int(c["idx"]))
	_panneau.visible = true
	_lbl_titre.text = UiCommun.t("Tour adverse : %s") % c["nom"]
	for b in _zone_boutons.get_children():
		b.queue_free()
	_barre_temps.value = 0
	var debut := Time.get_ticks_msec()
	while not _fin:
		if _cache.has(_n):
			break
		var r: Dictionary = await reseau.appeler("ac_actions", {"p_match": _match["id"], "p_depuis": _n})
		if r.ok and r.data is Dictionary:
			var d: Dictionary = r.data
			for a in d.get("actions", []):
				_cache[int(a["n"])] = a["action"]
			if _cache.has(_n):
				break
			if str(d.get("etat", "")) != "en_cours":
				await _verifier_fin_serveur()
				return {}
			var absent := int(d.get("adversaire_absent", 0))
			var attente := int(d.get("depuis_derniere", 0))
			if absent >= ATTENTE_FORFAIT:
				_info("L'adversaire a quitté le combat…")
				var f: Dictionary = await reseau.appeler("ac_forfait", {"p_match": _match["id"]})
				if f.ok and f.data is Dictionary and f.data.get("ok", false):
					_afficher_bilan(f.data)
					return {}
			elif attente >= ATTENTE_ABSENCE:
				# L'adversaire ne joue plus : l'IA joue à sa place
				var j: Dictionary = await reseau.appeler("ac_jouer", {"p_match": _match["id"], "p_n": _n, "p_camp": int(c["camp"]), "p_action": {"type": "auto"}})
				if j.ok and j.data is Dictionary and j.data.get("ok", false):
					_cache[_n] = j.data["action"]
					break
			var s := int((Time.get_ticks_msec() - debut) / 1000.0)
			_info(UiCommun.t("L'adversaire réfléchit… %d s") % s if absent < 10 else UiCommun.t("L'adversaire ne répond plus (%d s)…") % absent)
		else:
			_info("Connexion difficile…")
		await get_tree().create_timer(1.0).timeout
	_fermer_choix()
	return _cache.get(_n, {"type": "auto"})


# =====================================================================
# Fin du combat
# =====================================================================

func _terminer(gagnant: int) -> void:
	_fin = true
	_fermer_choix()
	var r := {}
	for essai in 5:
		var rep: Dictionary = await reseau.appeler("ac_terminer", {"p_match": _match["id"], "p_gagnant": gagnant})
		if rep.ok and rep.data is Dictionary and rep.data.get("ok", false):
			r = rep.data
			break
		await get_tree().create_timer(2.0).timeout
	if r.is_empty():
		r = {"gagnant": gagnant, "delta": null, "erreur": "Le résultat n'a pas pu être envoyé."}
	_afficher_bilan(r)


func _verifier_fin_serveur() -> void:
	var r: Dictionary = await reseau.appeler("ac_terminer", {"p_match": _match["id"], "p_gagnant": -1})
	if r.ok and r.data is Dictionary:
		_afficher_bilan(r.data)


func _abandonner() -> void:
	if _fin:
		return
	_fin = true
	_fermer_choix()
	var r: Dictionary = await reseau.appeler("ac_abandonner", {"p_match": _match["id"]})
	_afficher_bilan(r.data if r.ok and r.data is Dictionary else {"gagnant": 1 - _camp})


func _afficher_bilan(d: Dictionary) -> void:
	_fin = true
	_fermer_choix()
	var g = d.get("gagnant")
	var gagnant := int(g) if g != null else -1
	var victoire := gagnant == _camp
	var lignes: Array = []
	if d.get("forfait", false):
		lignes.append("Victoire par forfait : l'adversaire a quitté le combat." if victoire else "Défaite par abandon.")
	if gagnant == -1:
		lignes.append("Égalité : le temps est écoulé avec autant de PV de chaque côté.")
	var delta = d.get("delta")
	if delta != null:
		lignes.append(UiCommun.t("Points de classement : %s%d  (total %s)") % ["+" if int(delta) >= 0 else "", int(delta), str(d.get("points", "?"))])
	if d.has("erreur"):
		lignes.append(str(d["erreur"]))
	Sauvegarde.ajouter_stat("combats_arene")
	Sauvegarde._stat("combats_classes")
	if victoire:
		Sauvegarde.ajouter_stat("combats_gagnes")
		Sauvegarde._stat("victoires_classees")
	EcranCombat.resultat = {"mode": "classee", "victoire": victoire}
	ecran._afficher_resultat(victoire, lignes, "ÉGALITÉ" if gagnant == -1 else "")


# =====================================================================
# Interface
# =====================================================================

func _construire() -> void:
	_panneau = PanelContainer.new()
	var st := UiCommun.style_panneau(UiCommun.C_OR, Color(0.06, 0.02, 0.03, 0.94))
	st.set_content_margin_all(12)
	st.bg_color.a = 0.95     # bien opaque : le texte des sorts doit rester lisible
	_panneau.add_theme_stylebox_override("panel", st)
	_panneau.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panneau.anchor_left = 0.12
	_panneau.anchor_right = 0.88
	_panneau.anchor_top = 1.0
	_panneau.anchor_bottom = 1.0
	_panneau.offset_top = -190
	_panneau.grow_vertical = Control.GROW_DIRECTION_BEGIN   # grandit vers le haut si un sort a beaucoup de texte
	_panneau.offset_bottom = -8
	_panneau.visible = false
	ecran.add_child(_panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panneau.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	_lbl_titre = UiCommun.label("", 22, UiCommun.C_OR)
	_lbl_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(_lbl_titre)
	_lbl_info = UiCommun.label("", 17, Color("ffe0a0"))
	tete.add_child(_lbl_info)
	_barre_temps = UiCommun.barre(Color("ffb040"), 0, 8)
	_barre_temps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barre_temps.max_value = MINUTEUR
	vb.add_child(_barre_temps)
	_zone_boutons = HBoxContainer.new()
	_zone_boutons.add_theme_constant_override("separation", 10)
	_zone_boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_zone_boutons)


func _info(t: String) -> void:
	if _lbl_info != null:
		_lbl_info.text = t


## Cercle doré autour de l'unité qui agit.
func _montrer_halo(idx: int) -> void:
	if _halo == null:
		_halo = Panel.new()
		_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 0.8, 0.3, 0.08)
		st.border_color = Color("ffd060")
		st.set_border_width_all(3)
		st.set_corner_radius_all(14)
		_halo.add_theme_stylebox_override("panel", st)
		ecran._arene.add_child(_halo)
		var tw := _halo.create_tween().set_loops()
		tw.tween_property(_halo, "modulate:a", 0.35, 0.5)
		tw.tween_property(_halo, "modulate:a", 1.0, 0.5)
	var racine: Control = ecran._cartes[idx]["racine"]
	_halo.position = racine.position - Vector2(8, 8)
	_halo.size = racine.size + Vector2(16, 16)
	_halo.visible = true
