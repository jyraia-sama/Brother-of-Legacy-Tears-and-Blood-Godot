class_name EcranGuerre
extends Control
## GUERRE DES BANNIÈRES (Guilde → Guerre) : une guerre de guildes par semaine, en asynchrone.
##   Champ de bataille : la forteresse ennemie (Remparts, Tours, Donjon), éclaireur, assauts.
##   Notre forteresse   : nos postes et les étoiles que l'ennemi nous a prises.
##   Ma défense         : l'équipe que l'ennemi affronte sur mon poste (figée au début de la guerre).
##   Journal            : tout ce qui s'est passé, avec rediffusion des assauts.
##   Membres            : participation de chacun (assauts, étoiles).
## Règles et calculs côté serveur : supabase/08_guerre.sql.

const SCENE := "res://scenes/guerre.tscn"
const FOND := "res://assets/fonds/guerre.png"
const FOND_SECOURS := "res://assets/fonds/guilde.png"
const FOND_COMBAT := "res://assets/fonds/guerre_combat.png"

static var onglet_memo := "bataille"

const ONGLETS := [["bataille", "Champ de bataille"], ["nous", "Notre forteresse"], ["defense", "Ma défense"],
	["journal", "Journal"], ["membres", "Membres"]]
const C_NOUS := Color("6fb8ff")
const C_EUX := Color("ff6a5a")
const C_VERT := Color("8fe07a")

var _etat: Dictionary = {}
var _onglet := "bataille"
var _boutons_onglet := {}
var _contenu: VBoxContainer
var _bandeau: HBoxContainer
var _message: Label
var _lbl_phase: Label
var _occupe := false

# Défense en cours d'édition
var _slots_def: Array = []
var _selection_uid := -1
var _def_modifiee := false

# Assaut en préparation : poste visé et équipe choisie (uids)
var _cible: Dictionary = {}
var _slots_assaut: Array = []


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiCommun.fond_image(self, FOND if ResourceLoader.exists(FOND) else FOND_SECOURS, UiCommun.TEINTE_FOND)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + cote, 50)
	for cote in ["top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 22)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 10)
	marge.add_child(colonne)

	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var retour := UiCommun.bouton("← Guilde")
	retour.custom_minimum_size = Vector2(140, 44)
	retour.pressed.connect(_retour)
	entete.add_child(retour)
	entete.add_child(UiCommun.label("GUERRE DES BANNIÈRES", 34, UiCommun.C_OR))
	_lbl_phase = UiCommun.label("", 17, UiCommun.C_DOUX)
	_lbl_phase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_phase.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entete.add_child(_lbl_phase)
	var aide := UiCommun.bouton("?", 22)
	aide.custom_minimum_size = Vector2(46, 44)
	aide.tooltip_text = "Les règles de la guerre"
	aide.pressed.connect(_aide)
	entete.add_child(aide)

	if not EnLigne.est_connecte():
		colonne.add_child(UiCommun.label("La guerre se joue en ligne : connecte-toi à ton compte.", 20))
		return
	var rafraichir := UiCommun.bouton("↻ Actualiser")
	rafraichir.pressed.connect(_charger)
	entete.add_child(rafraichir)

	var cadre_bandeau := PanelContainer.new()
	cadre_bandeau.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	colonne.add_child(cadre_bandeau)
	_bandeau = HBoxContainer.new()
	_bandeau.add_theme_constant_override("separation", 30)
	_bandeau.alignment = BoxContainer.ALIGNMENT_CENTER
	cadre_bandeau.add_child(_bandeau)

	var onglets := HFlowContainer.new()
	onglets.add_theme_constant_override("h_separation", 8)
	colonne.add_child(onglets)
	for o in ONGLETS:
		var b := UiCommun.bouton(o[1], 18)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(200, 44)
		b.pressed.connect(_changer_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglet[o[0]] = b

	_message = UiCommun.label("", 18, Color(1.0, 0.8, 0.5))
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(_message)

	var cadre := PanelContainer.new()
	cadre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cadre.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	colonne.add_child(cadre)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cadre.add_child(defil)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 10)
	defil.add_child(_contenu)

	_slots_def = Guerre.slots_defense()
	_onglet = onglet_memo
	_charger()
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_phase)
	add_child(minuterie)
	if Tutoriel.premiere_fois("guide_guerre"):
		_aide.call_deferred()


# =====================================================================
# Chargement
# =====================================================================

func _charger() -> void:
	_message.text = "Chargement…"
	var r := await EnLigne.appeler("guerre_etat")
	if not is_inside_tree():
		return
	if not r.ok or not (r.data is Dictionary):
		_message.text = r.erreur if not r.ok else "Réponse inattendue du serveur."
		if not r.ok and "404" in str(r.erreur):
			_message.text = "La Guerre des Bannières n'est pas encore installée sur le serveur (fichier supabase/08_guerre.sql)."
		return
	_etat = r.data
	if str(_etat.get("code", "")) != "ok":
		_message.text = Guerre.texte_erreur(str(_etat.get("code", "")))
		return
	_message.text = ""
	# Première visite : la défense de guerre part automatiquement (copie de l'Arène ou du Deck)
	if _etat.get("ma_defense") == null and Arene.equipe_depuis_slots(_slots_def).size() > 0:
		var err: String = await Guerre.envoyer_defense(_slots_def)
		if err == "":
			var r2 := await EnLigne.appeler("guerre_etat")
			if r2.ok and r2.data is Dictionary:
				_etat = r2.data
	_maj_bandeau()
	_maj_phase()
	_changer_onglet(_onglet)


func _guerre() -> Dictionary:
	return _etat.get("guerre") if _etat.get("guerre") is Dictionary else {}


func _en_assaut() -> bool:
	return str(_etat.get("phase", "")) == "assaut" and bool(_guerre().get("en_cours", false))


func _maj_phase() -> void:
	if _etat.is_empty():
		return
	var fin := EnLigne.date_vers_unix(str(_etat.get("fin_phase", "")))
	var reste := maxi(0, fin - int(Time.get_unix_time_from_system()))
	var phase: String = Guerre.PHASES.get(str(_etat.get("phase", "")), "?")
	var suite := {"preparation": "les assauts commencent dans", "assaut": "fin des assauts dans", "bilan": "nouvelle guerre dans"}
	_lbl_phase.text = "Phase : %s  ·  %s %s" % [phase, suite.get(str(_etat.get("phase", "")), ""), _duree(reste)]


func _maj_bandeau() -> void:
	for c in _bandeau.get_children():
		c.queue_free()
	var g := _guerre()
	var gu: Dictionary = _etat.get("guilde", {})
	if g.is_empty():
		_bandeau.add_child(_bloc("Ta guilde", str(gu.get("nom", "?")), UiCommun.C_OR))
		_bandeau.add_child(_bloc("Inscription", "Inscrite ✓" if bool(gu.get("inscrite", false)) else "Non inscrite",
			C_VERT if bool(gu.get("inscrite", false)) else C_EUX))
		_bandeau.add_child(_bloc("Bilan", "%d V · %d N · %d D" % [int(gu.get("victoires", 0)), int(gu.get("egalites", 0)), int(gu.get("defaites", 0))], UiCommun.C_TEXTE))
		return
	var nous: Dictionary = g["nous"]
	var eux: Dictionary = g["eux"]
	_bandeau.add_child(_bloc(str(nous["nom"]), "%d ★" % int(nous["etoiles"]), C_NOUS))
	_bandeau.add_child(UiCommun.label("contre", 20, UiCommun.C_DOUX))
	_bandeau.add_child(_bloc(str(eux["nom"]), "%d ★" % int(eux["etoiles"]), C_EUX))
	var moi: Dictionary = g["moi"]
	if bool(g.get("finie", false)):
		var gg := str(g.get("gagnant", ""))
		_bandeau.add_child(_bloc("Résultat", {"nous": "VICTOIRE", "eux": "Défaite", "egalite": "Égalité"}.get(gg, "?"),
			C_VERT if gg == "nous" else (C_EUX if gg == "eux" else UiCommun.C_LEGENDE)))
	else:
		_bandeau.add_child(_bloc("Mes assauts du jour", "%d / %d" % [int(moi["attaques_restantes"]), int(_etat["reglages"]["attaques_jour"])], UiCommun.C_LEGENDE))
		_bandeau.add_child(_bloc("Éclaireur", "Disponible" if int(moi["eclaireurs_restants"]) > 0 else "Parti", UiCommun.C_TEXTE))
		_bandeau.add_child(_bloc("Unités épuisées", str((moi["fatigue"] as Array).size()), UiCommun.C_DOUX))
	_bandeau.add_child(_bloc("Mes étoiles", "%d ★ en %d assaut%s" % [int(moi["etoiles_total"]), int(moi["attaques_total"]),
		"s" if int(moi["attaques_total"]) > 1 else ""], UiCommun.C_TEXTE))


func _bloc(titre: String, valeur: String, couleur: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_child(UiCommun.label(titre, 14, UiCommun.C_DOUX))
	v.add_child(UiCommun.label(valeur, 22, couleur))
	return v


func _changer_onglet(id: String) -> void:
	_onglet = id
	onglet_memo = id if id != "assaut" else "bataille"
	for k in _boutons_onglet:
		_boutons_onglet[k].button_pressed = (k == id or (id == "assaut" and k == "bataille"))
	for c in _contenu.get_children():
		c.queue_free()
	if _etat.is_empty():
		return
	_bloc_butin()
	match id:
		"bataille": _afficher_bataille()
		"nous": _afficher_nous()
		"defense": _afficher_defense()
		"journal": _afficher_journal()
		"membres": _afficher_membres()
		"assaut": _afficher_assaut()


## Butin en attente : bandeau doré en haut de chaque onglet.
func _bloc_butin() -> void:
	if not bool(_etat.get("butin_en_attente", false)):
		return
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	_contenu.add_child(h)
	var l := UiCommun.label("Le butin de la dernière guerre t'attend !", 20, UiCommun.C_LEGENDE)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := UiCommun.bouton("Réclamer le butin", 18)
	b.custom_minimum_size = Vector2(240, 46)
	UiCommun.bouton_vif(b)
	b.pressed.connect(_reclamer)
	h.add_child(b)


# =====================================================================
# Champ de bataille / notre forteresse
# =====================================================================

func _afficher_bataille() -> void:
	var g := _guerre()
	if g.is_empty() or not bool(g.get("en_cours", false)) and not bool(g.get("finie", false)):
		_ecran_sans_guerre()
		return
	if not bool(g.get("en_cours", false)):
		_titre("Dernière guerre : contre %s" % str(g["eux"]["nom"]))
		_texte("La prochaine guerre commence mercredi. En attendant, prépare ta défense de guerre.")
	else:
		_titre("La forteresse de %s" % str(g["eux"]["nom"]))
		if bool(g.get("legion", false)):
			_texte("Aucune guilde à ta mesure cette semaine : la LÉGION DE LA SOIF se dresse devant vous. Ses postes sont les reflets de défenses de vrais joueurs. Elle attaque aussi votre forteresse, chaque jour un peu plus : prenez-lui plus d'étoiles qu'elle ne vous en prend !")
		_texte("Perce les Remparts, puis les Tours, puis le Donjon : une couche s'ouvre quand chaque poste de la précédente a été pris au moins une étoile. ★ victoire · ★★ 3 unités debout · ★★★ aucune perte.")
	_forteresse(g["postes_eux"], false)


func _afficher_nous() -> void:
	var g := _guerre()
	if g.is_empty():
		_ecran_sans_guerre()
		return
	_titre("Notre forteresse")
	_texte("Les étoiles indiquent ce que %s a pris sur chaque poste. Les défenses sont figées pour toute la guerre." % str(g["eux"]["nom"]))
	_forteresse(g["postes_nous"], true)


func _forteresse(postes: Array, la_notre: bool) -> void:
	# Une couche est ouverte quand toutes les couches inférieures ont chacune au moins 1 étoile par poste
	var ouverte := [true, true, true]
	for c in [1, 2]:
		ouverte[c] = ouverte[c - 1] and postes.filter(func(p): return int(p["couche"]) == c - 1 and int(p["etoiles"]) == 0).is_empty()
	for c in [2, 1, 0]:
		var de_la_couche := postes.filter(func(p): return int(p["couche"]) == c)
		if de_la_couche.is_empty():
			continue
		var tete := HBoxContainer.new()
		tete.add_theme_constant_override("separation", 12)
		_contenu.add_child(tete)
		tete.add_child(UiCommun.label(str(Guerre.COUCHES[c]).to_upper(), 22, Guerre.COULEURS_COUCHE[c]))
		if not la_notre and not ouverte[c]:
			tete.add_child(UiCommun.label("🔒 fermée : perce d'abord la couche précédente", 16, UiCommun.C_DOUX))
		var grille := HFlowContainer.new()
		grille.add_theme_constant_override("h_separation", 12)
		grille.add_theme_constant_override("v_separation", 12)
		_contenu.add_child(grille)
		for p in de_la_couche:
			grille.add_child(_carte_poste(p, la_notre, ouverte[c]))


func _carte_poste(p: Dictionary, la_notre: bool, ouverte: bool) -> Control:
	var panneau := PanelContainer.new()
	panneau.custom_minimum_size = Vector2(330, 0)
	var couleur: Color = Guerre.COULEURS_COUCHE[int(p["couche"])]
	var pris := int(p["etoiles"])
	panneau.add_theme_stylebox_override("panel", UiCommun.style_carte(
		(C_EUX if la_notre else C_VERT) if pris == 3 else couleur.darkened(0.2), 0.05, 2))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panneau.add_child(v)
	var h := HBoxContainer.new()
	v.add_child(h)
	var nom := UiCommun.label(str(p["nom"]) + ("  (toi)" if bool(p.get("moi", false)) else ""), 18,
		UiCommun.C_LEGENDE if bool(p.get("moi", false)) else UiCommun.C_TEXTE)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nom)
	h.add_child(UiCommun.label(Guerre.texte_etoiles(pris), 22, UiCommun.C_LEGENDE if pris > 0 else UiCommun.C_DOUX))
	v.add_child(UiCommun.label("Puissance %s" % _nombre(int(p["puissance"])), 15, UiCommun.C_DOUX))
	# Éléments (toujours visibles) ou unités (si révélées)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	v.add_child(ligne)
	var equipe = p.get("equipe")
	if equipe is Array and not (equipe as Array).is_empty():
		for u in Arene.nettoyer(equipe):
			ligne.add_child(UiCommun.portrait(str(u["id"]), 46))
	else:
		for el in p.get("elements", []):
			var pastille := UiCommun.label("●", 26, UiCommun.COULEURS_ELEMENT.get(str(el), Color.WHITE))
			pastille.tooltip_text = str(UnitesData.ELEMENTS.get(str(el), el))
			ligne.add_child(pastille)
		if not la_notre:
			ligne.add_child(UiCommun.label("  équipe inconnue", 14, UiCommun.C_DOUX))
	if la_notre or not _en_assaut():
		return panneau
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 8)
	v.add_child(boutons)
	var moi: Dictionary = _guerre()["moi"]
	if not (equipe is Array):
		var ecl := UiCommun.bouton("Éclaireur", 15)
		ecl.disabled = int(moi["eclaireurs_restants"]) <= 0
		ecl.tooltip_text = "Révèle les unités de ce poste (1 fois par jour)."
		ecl.pressed.connect(_eclaireur.bind(int(p["numero"])))
		boutons.add_child(ecl)
	var att := UiCommun.bouton("Attaquer" if pris < 3 else "Pris ★★★", 15)
	att.disabled = not ouverte or pris >= 3 or int(moi["attaques_restantes"]) <= 0
	if not ouverte:
		att.tooltip_text = "Couche fermée."
	elif int(moi["attaques_restantes"]) <= 0:
		att.tooltip_text = "Plus d'assaut aujourd'hui."
	if not att.disabled:
		UiCommun.bouton_vif(att, Color("b8402f"))
	att.pressed.connect(func():
		_cible = p
		_slots_assaut = _equipe_par_defaut()
		_changer_onglet("assaut"))
	boutons.add_child(att)
	return panneau


func _ecran_sans_guerre() -> void:
	var gu: Dictionary = _etat.get("guilde", {})
	var phase := str(_etat.get("phase", ""))
	_titre("Pas de guerre en cours")
	if phase == "preparation":
		_texte("C'est la PRÉPARATION (lundi et mardi). Les assauts commencent mercredi : prépare ta défense de guerre dans l'onglet « Ma défense ».")
	elif phase == "assaut":
		_texte("Les assauts ont commencé, mais ta guilde n'est pas inscrite (ou aucun membre n'a de défense).")
	else:
		_texte("C'est le BILAN (dimanche). La prochaine guerre se prépare dès lundi.")
	var inscrite := bool(gu.get("inscrite", false))
	_texte("Inscription de la guilde : %s. L'inscription reste valable chaque semaine." % ("OUI ✓" if inscrite else "non"))
	if str(gu.get("mon_role", "")) in ["chef", "officier"]:
		var b := UiCommun.bouton("Retirer la guilde des guerres" if inscrite else "Inscrire la guilde à la guerre", 18)
		b.custom_minimum_size = Vector2(380, 48)
		if not inscrite:
			UiCommun.bouton_vif(b)
		b.pressed.connect(_inscrire.bind(not inscrite))
		_contenu.add_child(b)
	else:
		_texte("Seuls le chef et les officiers peuvent inscrire la guilde.")
	_texte("S'il n'y a pas d'autre guilde à votre mesure, vous affronterez la Légion de la Soif : la guerre a toujours lieu.")


# =====================================================================
# Assaut : choix de l'équipe (unités non épuisées)
# =====================================================================

func _fatigue() -> Array:
	var g := _guerre()
	return (g.get("moi", {}).get("fatigue", []) as Array).map(func(x): return int(x)) if not g.is_empty() else []


func _equipe_par_defaut() -> Array:
	var f := _fatigue()
	var s: Array = []
	for uid in Sauvegarde.get_slots():
		s.append(int(uid) if int(uid) >= 0 and not int(uid) in f else -1)
	return s


func _afficher_assaut() -> void:
	var p := _cible
	if p.is_empty():
		_changer_onglet("bataille")
		return
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	_contenu.add_child(h)
	var annuler := UiCommun.bouton("← Champ de bataille")
	annuler.pressed.connect(func(): _changer_onglet("bataille"))
	h.add_child(annuler)
	h.add_child(UiCommun.label("Assaut : %s (%s) · puissance %s · %s" % [str(p["nom"]), Guerre.COUCHES[int(p["couche"])],
		_nombre(int(p["puissance"])), Guerre.texte_etoiles(int(p["etoiles"]))], 20, UiCommun.C_OR))
	_texte("Choisis jusqu'à 5 unités : clique une unité puis une place. Les unités grisées sont ÉPUISÉES (elles ont déjà attaqué aujourd'hui). Celles que tu engages seront épuisées jusqu'à demain.")

	var places := HBoxContainer.new()
	places.add_theme_constant_override("separation", 12)
	_contenu.add_child(places)
	for i in 5:
		var uid := int(_slots_assaut[i])
		var b: Button
		if uid >= 0:
			b = UiCommun.carte_heros(Sauvegarde.get_heros(uid), 140, 178)
		else:
			b = Button.new()
			b.custom_minimum_size = Vector2(140, 178)
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_DOUX.darkened(0.4)))
			b.text = "Place %d\n%s\n(vide)" % [i + 1, "Avant" if i < 2 else "Arrière"]
		b.pressed.connect(_clic_place_assaut.bind(i))
		places.add_child(b)
		if i == 1:
			places.add_child(VSeparator.new())
	var equipe := Arene.equipe_depuis_slots(_slots_assaut)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	_contenu.add_child(bas)
	var lancer := UiCommun.bouton("⚔ Lancer l'assaut", 20)
	lancer.custom_minimum_size = Vector2(280, 52)
	lancer.disabled = equipe.is_empty() or _occupe
	if not lancer.disabled:
		UiCommun.bouton_vif(lancer, Color("b8402f"))
	lancer.pressed.connect(_lancer_assaut)
	bas.add_child(lancer)
	var vider := UiCommun.bouton("Vider")
	vider.pressed.connect(func():
		_slots_assaut = [-1, -1, -1, -1, -1]
		_changer_onglet("assaut"))
	bas.add_child(vider)
	var pu := UiCommun.label("Ta puissance : %s   ·   la sienne : %s" % [_nombre(Arene.puissance(equipe)), _nombre(int(p["puissance"]))], 17, UiCommun.C_DOUX)
	pu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bas.add_child(pu)
	_grille_collection(_slots_assaut, _fatigue(), "Assaut")


func _clic_place_assaut(i: int) -> void:
	if _selection_uid >= 0:
		var ancienne := _slots_assaut.find(_selection_uid)
		if ancienne >= 0:
			_slots_assaut[ancienne] = _slots_assaut[i]
		_slots_assaut[i] = _selection_uid
		_selection_uid = -1
	else:
		_slots_assaut[i] = -1
	_changer_onglet("assaut")


func _lancer_assaut() -> void:
	if _occupe:
		return
	var slots := _slots_assaut
	var equipe := Arene.equipe_depuis_slots(slots)
	var uids: Array = []
	for i in slots.size():
		if int(slots[i]) >= 0:
			uids.append(int(slots[i]))
	for i in equipe.size():
		equipe[i]["uid"] = uids[i]
	_occupe = true
	_message.text = "Les troupes se mettent en marche…"
	var envoi := equipe.map(func(u):
		var c: Dictionary = u.duplicate()
		c.erase("uid")
		return c)
	var r := await EnLigne.appeler("guerre_commencer", {"p_numero": int(_cible["numero"]), "p_equipe": envoi, "p_uids": uids})
	_occupe = false
	if not is_inside_tree():
		return
	if not r.ok:
		_message.text = r.erreur
		return
	var d: Dictionary = r.data
	if str(d.get("code", "")) != "ok":
		_message.text = Guerre.texte_erreur(str(d.get("code", "")))
		_charger()
		return
	EcranCombat.demande = {"mode": "guerre", "type": "arene", "attaque": str(d["attaque"]), "graine": int(d["graine"]),
		"adversaire": str(d.get("nom", _cible["nom"])), "couche": int(_cible["couche"]),
		"equipe": equipe, "ennemis": Arene.nettoyer(d["defense"]), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _eclaireur(numero: int) -> void:
	if _occupe:
		return
	_occupe = true
	var r := await EnLigne.appeler("guerre_eclaireur", {"p_numero": numero})
	_occupe = false
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		_message.text = "Ton éclaireur est revenu : l'équipe du poste est révélée."
		_charger()
	else:
		_message.text = r.erreur if not r.ok else Guerre.texte_erreur(str(r.data.get("code", "")))


# =====================================================================
# Ma défense
# =====================================================================

func _afficher_defense() -> void:
	_titre("Ma défense de guerre")
	var g := _guerre()
	if bool(g.get("en_cours", false)):
		_texte("Pendant une guerre, ta défense est FIGÉE : ce que tu changes ici comptera pour la prochaine guerre.")
	_texte("L'équipe que l'ennemi affronte sur ton poste. Places 1-2 : Avant · places 3-5 : Arrière. Clique un héros puis une place (une place occupée se vide d'un clic).")
	var places := HBoxContainer.new()
	places.add_theme_constant_override("separation", 12)
	_contenu.add_child(places)
	for i in 5:
		var uid := int(_slots_def[i])
		var b: Button
		if uid >= 0:
			b = UiCommun.carte_heros(Sauvegarde.get_heros(uid), 140, 178)
		else:
			b = Button.new()
			b.custom_minimum_size = Vector2(140, 178)
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_DOUX.darkened(0.4)))
			b.text = "Place %d\n%s\n(vide)" % [i + 1, "Avant" if i < 2 else "Arrière"]
		b.pressed.connect(_clic_place_def.bind(i))
		places.add_child(b)
		if i == 1:
			places.add_child(VSeparator.new())
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 10)
	_contenu.add_child(boutons)
	var copier := UiCommun.bouton("Copier ma défense d'Arène")
	copier.pressed.connect(func():
		_slots_def = Arene.slots_defense()
		_def_modifiee = true
		_changer_onglet("defense"))
	boutons.add_child(copier)
	var envoyer := UiCommun.bouton("Enregistrer la défense")
	envoyer.custom_minimum_size = Vector2(260, 44)
	if _def_modifiee:
		UiCommun.bouton_vif(envoyer)
	envoyer.pressed.connect(func():
		_message.text = "Enregistrement…"
		var err: String = await Guerre.envoyer_defense(_slots_def)
		if not is_inside_tree():
			return
		if err == "":
			_def_modifiee = false
			_message.text = "Défense de guerre enregistrée !"
			_charger()
		else:
			_message.text = err)
	boutons.add_child(envoyer)
	var info := "Puissance %s" % _nombre(Arene.puissance(Arene.equipe_depuis_slots(_slots_def)))
	info += "   ·   modifications NON enregistrées" if _def_modifiee else ("   ·   enregistrée ✓" if _etat.get("ma_defense") != null else "")
	var li := UiCommun.label(info, 17, Color(1.0, 0.8, 0.5) if _def_modifiee else UiCommun.C_DOUX)
	li.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boutons.add_child(li)
	_grille_collection(_slots_def, [], "Défense")


func _clic_place_def(i: int) -> void:
	if _selection_uid >= 0:
		var ancienne := _slots_def.find(_selection_uid)
		if ancienne >= 0:
			_slots_def[ancienne] = _slots_def[i]
		_slots_def[i] = _selection_uid
		_selection_uid = -1
	else:
		_slots_def[i] = -1
	_def_modifiee = true
	_changer_onglet("defense")


## Collection : clique un héros pour le sélectionner (les épuisés sont grisés et non cliquables).
func _grille_collection(slots: Array, epuises: Array, badge: String) -> void:
	_titre("Ta collection")
	var grille := HFlowContainer.new()
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	_contenu.add_child(grille)
	var heros := Sauvegarde.liste_heros().duplicate()
	heros.sort_custom(func(x, y):
		var fx: bool = int(x["uid"]) in epuises
		var fy: bool = int(y["uid"]) in epuises
		if fx != fy:
			return fy
		return Arene.puissance([Arene.combattant(int(x["uid"]), 0)]) > Arene.puissance([Arene.combattant(int(y["uid"]), 0)]))
	for h in heros:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h, 124, 158)
		if uid in epuises:
			carte.disabled = true
			carte.modulate = Color(0.45, 0.45, 0.45)
			UiCommun.badge(carte, "Épuisé", UiCommun.C_DOUX)
		elif uid == _selection_uid:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_LEGENDE, 0.1, 4))
		if uid in slots:
			UiCommun.badge(carte, badge, UiCommun.C_OR)
		carte.pressed.connect(func():
			_selection_uid = -1 if _selection_uid == uid else uid
			_changer_onglet(_onglet))
		grille.add_child(carte)


# =====================================================================
# Journal / membres
# =====================================================================

func _afficher_journal() -> void:
	var g := _guerre()
	if g.is_empty():
		_ecran_sans_guerre()
		return
	_titre("Journal de guerre")
	for j in g.get("journal", []):
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		_contenu.add_child(h)
		var camp = j.get("camp")
		var couleur := UiCommun.C_LEGENDE if camp == null else (C_NOUS if bool(j.get("nous", false)) else C_EUX)
		h.add_child(UiCommun.label(_heure(str(j.get("cree_le", ""))), 15, UiCommun.C_DOUX))
		var t := UiCommun.label(str(j["texte"]), 17, couleur)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(t)
		if j.get("attaque") != null:
			var b := UiCommun.bouton("▶ Revoir", 14)
			b.pressed.connect(_revoir.bind(str(j["attaque"])))
			h.add_child(b)


func _revoir(id: String) -> void:
	var r := await EnLigne.appeler("guerre_revoir", {"p_attaque": id})
	if not is_inside_tree():
		return
	if not (r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok"):
		_message.text = "Rediffusion impossible."
		return
	var d: Dictionary = r.data
	EcranCombat.demande = {"mode": "guerre_revoir", "type": "arene", "graine": int(d["graine"]),
		"adversaire": str(d.get("nom", "?")), "attaquant": str(d.get("attaquant", "?")), "couche": 0,
		"equipe": Arene.nettoyer(d["equipe"]), "ennemis": Arene.nettoyer(d["defense"]), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _afficher_membres() -> void:
	var g := _guerre()
	if g.is_empty():
		_ecran_sans_guerre()
		return
	_titre("Participation de la guilde")
	var liste: Array = g.get("membres", [])
	if liste.is_empty():
		_texte("Personne n'a encore attaqué. À l'assaut !")
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 40)
	_contenu.add_child(grille)
	for e in ["Membre", "Assauts", "Étoiles"]:
		grille.add_child(UiCommun.label(e, 15, UiCommun.C_OR))
	for m in liste:
		grille.add_child(UiCommun.label(str(m["pseudo"]), 17))
		grille.add_child(UiCommun.label(str(int(m["attaques"])), 17))
		grille.add_child(UiCommun.label("%d ★" % int(m["etoiles"]), 17, UiCommun.C_LEGENDE))
	var r: Dictionary = _etat.get("reglages", {})
	_texte("Butin (pour chaque membre qui a attaqué au moins une fois) : Sceaux de guilde (victoire %d, égalité %d, défaite %d, +%d par étoile gagnée), or et coffres." % [
		int(r.get("sceaux", {}).get("victoire", 0)), int(r.get("sceaux", {}).get("egalite", 0)),
		int(r.get("sceaux", {}).get("defaite", 0)), int(r.get("sceaux_par_etoile", 0))])


# =====================================================================
# Actions
# =====================================================================

func _inscrire(oui: bool) -> void:
	var r := await EnLigne.appeler("guerre_inscrire", {"p_oui": oui})
	if not is_inside_tree():
		return
	if r.ok and str(r.data) == "ok":
		_message.text = "La guilde est inscrite à la Guerre des Bannières !" if oui else "La guilde ne participera plus aux guerres."
		_charger()
	else:
		_message.text = r.erreur if not r.ok else Guerre.texte_erreur(str(r.data))


func _reclamer() -> void:
	var r := await EnLigne.appeler("guerre_reclamer")
	if not is_inside_tree():
		return
	if not (r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok"):
		_message.text = r.erreur if not r.ok else Guerre.texte_erreur(str(r.data.get("code", "")))
		return
	var d: Dictionary = r.data
	var lignes := Quetes.donner(d.get("recompense", {}))
	lignes.push_front("Sceaux de guilde : +%d" % int(d.get("sceaux", 0)))
	var titre: String = {"victoire": "Butin de la victoire", "egalite": "Butin de l'égalité", "defaite": "Butin de guerre"}.get(str(d.get("resultat", "")), "Butin")
	FenetreSimple.ouvrir(self, titre, "\n".join(lignes), [["Merci !", null]])
	_charger()


func _aide() -> void:
	var r: Dictionary = _etat.get("reglages", {})
	FenetreSimple.ouvrir(self, "La Guerre des Bannières", """Une guerre de guildes par semaine, chacun joue quand il veut.

• LUNDI-MARDI, préparation : le chef inscrit la guilde (une fois pour toutes) et chacun prépare sa DÉFENSE DE GUERRE.
• MERCREDI-SAMEDI, assauts : %d assauts par jour et par membre contre la forteresse ennemie.
• DIMANCHE, bilan : la guilde qui a le plus d'étoiles gagne. Chaque membre qui a attaqué réclame son butin.

LA FORTERESSE : un poste par membre, rangés par puissance en Remparts, Tours et Donjon. Une couche s'ouvre quand chaque poste de la précédente a été pris au moins une étoile.

LES ÉTOILES : ★ victoire · ★★ victoire avec 3 unités debout ou plus · ★★★ aucune perte. Seul le meilleur résultat sur un poste compte : on peut réattaquer pour faire mieux.

LA FATIGUE : une unité qui a attaqué est épuisée jusqu'au lendemain. Toute ta collection compte !

L'ÉCLAIREUR : une fois par jour, il révèle les unités d'un poste (sinon seuls ses éléments sont visibles).

LA LÉGION DE LA SOIF : sans guilde à votre mesure, vous affrontez cette armée fantôme, faite des reflets de défenses de vrais joueurs. Elle attaque votre forteresse un peu plus chaque jour.""" % int(r.get("attaques_jour", 2)), [["Compris !", null]])


# =====================================================================
# Outils
# =====================================================================

func _titre(t: String) -> void:
	_contenu.add_child(UiCommun.label(t, 24, UiCommun.C_OR))


func _texte(t: String) -> void:
	var l := UiCommun.label(t, 17, UiCommun.C_TEXTE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(l)


func _nombre(n: int) -> String:
	var s := str(absi(n))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return s + r


func _duree(s: int) -> String:
	if s >= 86400:
		return "%d j %d h" % [s / 86400, (s % 86400) / 3600]
	if s >= 3600:
		return "%d h %02d min" % [s / 3600, (s % 3600) / 60]
	return "%d min %02d s" % [s / 60, s % 60]


func _heure(iso: String) -> String:
	if iso.length() < 19:
		return ""
	var t := EnLigne.date_vers_unix(iso) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	var jours := ["dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam."]
	return "%s %02d:%02d" % [jours[int(d.weekday)], d.hour, d.minute]


func _retour() -> void:
	get_tree().change_scene_to_file(EcranGuilde.SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_retour()
