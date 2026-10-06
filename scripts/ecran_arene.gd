class_name EcranArene
extends Control
## ARÈNE JcJ
##   Combattre  : 3 adversaires proches de ton classement (+ Gardien si pas assez de joueurs).
##   Défense    : l'équipe que les autres joueurs affrontent quand tu n'es pas là.
##   Classement : top 100 de la saison.
##   Historique : tes attaques et les attaques subies par ta défense (avec Revanche).
##   Boutique   : objets à échanger contre des Insignes d'Arène.
## Points, essais, Insignes et achats sont gérés par le serveur (supabase/02_arene.sql).

const SCENE := "res://scenes/arene.tscn"
const FOND := "res://assets/fonds/arene.png"

static var scene_retour := ""
## Onglet à rouvrir en revenant d'un combat
static var onglet_memo := "combattre"

const ONGLETS := [["combattre", "Combattre"], ["defense", "Défense"], ["classement", "Classement"],
	["historique", "Historique"], ["boutique", "Boutique"]]
const C_VERT := Color("8fe07a")
const C_ROUGE := Color("e0604f")

var _etat: Dictionary = {}          # arene_etat()
var _onglet := "combattre"
var _boutons_onglet := {}
var _contenu: VBoxContainer
var _bandeau: HBoxContainer
var _message: Label
var _lbl_saison: Label
var _adversaires: Array = []
var _occupe := false

# Défense en cours d'édition
var _slots_def: Array = []
var _selection_uid := -1
var _def_modifiee := false


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiCommun.fond_image(self, FOND, UiCommun.TEINTE_FOND)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + cote, 60)
	for cote in ["top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 26)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)

	# --- En-tête ---
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var retour := UiCommun.bouton("← Retour")
	retour.custom_minimum_size = Vector2(140, 44)
	retour.pressed.connect(_retour)
	entete.add_child(retour)
	var titre := UiCommun.label("ARÈNE", 36, UiCommun.C_OR)
	entete.add_child(titre)
	_lbl_saison = UiCommun.label("", 17, UiCommun.C_DOUX)
	_lbl_saison.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_saison.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entete.add_child(_lbl_saison)

	if not EnLigne.est_connecte():
		_ecran_non_connecte(colonne)
		return

	var rafraichir := UiCommun.bouton("↻ Actualiser")
	rafraichir.pressed.connect(func(): _charger(true))
	entete.add_child(rafraichir)

	# --- Bandeau : palier, points, rang, essais, Insignes ---
	var cadre_bandeau := PanelContainer.new()
	cadre_bandeau.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	colonne.add_child(cadre_bandeau)
	_bandeau = HBoxContainer.new()
	_bandeau.add_theme_constant_override("separation", 34)
	cadre_bandeau.add_child(_bandeau)

	# --- Onglets ---
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for o in ONGLETS:
		var b := UiCommun.bouton(o[1], 19)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(200, 46)
		b.pressed.connect(_changer_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglet[o[0]] = b
	# Arène classée en temps réel (combat manuel contre un joueur connecté)
	var classee := UiCommun.bouton("ARÈNE CLASSÉE (temps réel)", 19)
	classee.custom_minimum_size = Vector2(300, 46)
	classee.add_theme_color_override("font_color", Color("ffd060"))
	classee.pressed.connect(func():
		EcranArenaClassee.scene_retour_classee = scene_file_path
		get_tree().change_scene_to_file(EcranArenaClassee.SCENE))
	onglets.add_child(classee)

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

	_slots_def = Arene.slots_defense()
	_onglet = onglet_memo
	for k in _boutons_onglet:
		_boutons_onglet[k].button_pressed = (k == _onglet)
	_charger(true)

	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_compte_a_rebours)
	add_child(minuterie)


func _ecran_non_connecte(colonne: VBoxContainer) -> void:
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(centre)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	vb.add_child(UiCommun.label("L'Arène se joue en ligne : connecte-toi à ton compte." if EnLigne.configure()
		else "Le jeu en ligne n'est pas encore configuré (voir SUPABASE.md).", 20))
	if EnLigne.configure():
		var b := UiCommun.bouton("Se connecter")
		b.pressed.connect(func(): FenetreCompte.ouvrir(self, false, func(): get_tree().reload_current_scene()))
		vb.add_child(b)


# ---------------------------------------------------------------
# Chargement
# ---------------------------------------------------------------

func _charger(adversaires_aussi := false) -> void:
	_message.text = "Chargement…"
	var r := await EnLigne.appeler("arene_etat")
	if not is_inside_tree():
		return
	if not r.ok or not (r.data is Dictionary):
		_message.text = r.erreur if not r.ok else "L'Arène n'est pas encore installée sur le serveur (lance supabase/02_arene.sql)."
		return
	_etat = r.data
	_message.text = ""
	# Pas encore de défense sur le serveur : on enregistre automatiquement celle du joueur
	# (ou son équipe du Deck), sinon les autres joueurs ne le trouvent jamais comme adversaire.
	if (_etat.get("equipe", []) as Array).is_empty() and await _defense_automatique():
		return
	_maj_bandeau()
	if adversaires_aussi:
		await _charger_adversaires()
	_changer_onglet(_onglet)
	_proposer_recompenses()


## Envoie la défense locale (ou l'équipe du Deck) au serveur. Renvoie true si l'Arène a été rechargée.
func _defense_automatique() -> bool:
	var slots := Arene.slots_defense()
	if Arene.equipe_depuis_slots(slots).is_empty():
		slots = Sauvegarde.get_slots()
	var equipe := Arene.equipe_depuis_slots(slots)
	if equipe.is_empty():
		return false
	var r := await EnLigne.appeler("arene_definir_defense", {"p_equipe": equipe, "p_puissance": Arene.puissance(equipe)})
	if not is_inside_tree() or not (r.ok and str(r.data) == "ok"):
		if is_inside_tree() and r.ok:
			_message.text = "Défense automatique refusée : " + Arene.texte_erreur(str(r.data))
		return false
	Arene.definir_slots_defense(slots)
	await _charger(true)
	if is_inside_tree():
		_message.text = "Ta défense a été enregistrée automatiquement avec ton équipe (modifiable dans l'onglet Défense)."
	return true


func _charger_adversaires() -> void:
	var r := await EnLigne.appeler("arene_adversaires")
	if not is_inside_tree():
		return
	_adversaires = r.data if r.ok and r.data is Array else []


func _maj_bandeau() -> void:
	for c in _bandeau.get_children():
		c.queue_free()
	var palier := str(_etat.get("palier", "bronze"))
	_bandeau.add_child(_bloc("PALIER", Arene.nom_palier(palier), Arene.couleur_palier(palier)))
	_bandeau.add_child(_bloc("POINTS", str(int(_etat.get("points", 0))), UiCommun.C_LEGENDE))
	_bandeau.add_child(_bloc("RANG", "%d" % int(_etat.get("rang", 0)), UiCommun.C_TEXTE))
	_bandeau.add_child(_bloc("SAISON", "%d V · %d D" % [int(_etat.get("victoires", 0)), int(_etat.get("defaites", 0))], UiCommun.C_TEXTE))
	var gratuits := int(_etat.get("essais_gratuits_restants", 0))
	var txt_essais := "%d gratuits" % gratuits if gratuits > 0 else "%d à %d gemmes" % [int(_etat.get("essais_payants_restants", 0)), int(_etat.get("cout_essai_gemmes", 20))]
	_bandeau.add_child(_bloc("COMBATS AUJOURD'HUI", txt_essais, C_VERT if gratuits > 0 else UiCommun.C_DOUX))
	_bandeau.add_child(_bloc("INSIGNES D'ARÈNE", str(int(_etat.get("insignes", 0))), Color("e0b35a")))
	_maj_compte_a_rebours()


func _bloc(titre: String, valeur: String, couleur: Color) -> Control:
	var vb := VBoxContainer.new()
	vb.add_child(UiCommun.label(titre, 13, UiCommun.C_DOUX))
	vb.add_child(UiCommun.label(valeur, 24, couleur))
	return vb


func _maj_compte_a_rebours() -> void:
	if _etat.is_empty() or _lbl_saison == null:
		return
	var reste := EnLigne.date_vers_unix(str(_etat.get("fin_saison", ""))) - int(Time.get_unix_time_from_system())
	_lbl_saison.text = "   Saison %d · fin dans %s" % [int(_etat.get("saison", 1)), Calendrier.texte_duree(maxi(0, reste))]


# ---------------------------------------------------------------
# Onglets
# ---------------------------------------------------------------

func _changer_onglet(id: String) -> void:
	_onglet = id
	onglet_memo = id
	for k in _boutons_onglet:
		_boutons_onglet[k].button_pressed = (k == id)
	_vider(_contenu)
	match id:
		"combattre": _afficher_combattre()
		"defense": _afficher_defense()
		"classement": _afficher_classement()
		"historique": _afficher_historique()
		"boutique": _afficher_boutique()


# ---------- Combattre ----------

func _afficher_combattre() -> void:
	if (_etat.get("equipe", []) as Array).is_empty():
		_titre("Prépare d'abord ton équipe de défense")
		_texte("Avant d'attaquer, choisis l'équipe que les autres joueurs affronteront quand tu n'es pas là (onglet Défense).")
		var b := UiCommun.bouton("Préparer ma défense")
		b.custom_minimum_size = Vector2(260, 46)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(func(): _changer_onglet("defense"))
		_contenu.add_child(b)
		return

	var ligne_att := HBoxContainer.new()
	ligne_att.add_theme_constant_override("separation", 10)
	_contenu.add_child(ligne_att)
	var lt := UiCommun.label("Ton équipe d'attaque (Deck) :", 18, UiCommun.C_OR)
	lt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne_att.add_child(lt)
	var att := Arene.equipe_attaque()
	for u in att:
		ligne_att.add_child(_mini_unite(u))
	var p_att := UiCommun.label("Puissance %s" % _nombre(Arene.puissance(att)), 17, UiCommun.C_DOUX)
	p_att.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne_att.add_child(p_att)
	var deck := UiCommun.bouton("Modifier (Deck)")
	deck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deck.pressed.connect(func():
		EcranDeck.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranDeck.SCENE))
	ligne_att.add_child(deck)

	var ligne := HBoxContainer.new()
	_contenu.add_child(ligne)
	var t := UiCommun.label("Adversaires", 22, UiCommun.C_OR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(t)
	var autres := UiCommun.bouton("↻ Autres adversaires")
	autres.pressed.connect(func():
		await _charger_adversaires()
		_changer_onglet("combattre"))
	ligne.add_child(autres)

	for a in _adversaires:
		_contenu.add_child(_carte_adversaire(a))
	# Pas assez de joueurs : le Gardien de l'Arène complète la liste
	if _adversaires.size() < 3:
		_contenu.add_child(_carte_adversaire({}))


func _carte_adversaire(a: Dictionary) -> Control:
	var gardien := a.is_empty()
	var p := PanelContainer.new()
	var palier := "bronze" if gardien else str(a.get("palier", "bronze"))
	p.add_theme_stylebox_override("panel", UiCommun.style_carte(Arene.couleur_palier(palier).darkened(0.25)))
	var m := _marge(p, 10)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	m.add_child(ligne)
	var equipe: Array = Arene.equipe_gardien() if gardien else Arene.nettoyer(a.get("equipe", []))
	var av := UiCommun.avatar("" if gardien else str(a.get("heros_vitrine", "")), "G" if gardien else str(a.get("pseudo", "?")), 64)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(av)
	var infos := VBoxContainer.new()
	infos.custom_minimum_size = Vector2(300, 0)
	ligne.add_child(infos)
	if gardien:
		infos.add_child(UiCommun.label("Gardien de l'Arène", 22, UiCommun.C_TEXTE))
		infos.add_child(UiCommun.label("Le reflet de ta défense (entraînement)", 15, UiCommun.C_DOUX))
		infos.add_child(UiCommun.label("Victoire : 10 points max", 15, UiCommun.C_DOUX))
	else:
		infos.add_child(UiCommun.label(EnLigne.nom_complet(str(a.get("pseudo", "?"))), 22, UiCommun.C_TEXTE))
		infos.add_child(UiCommun.label("%s · %d points · Niv. %d" % [Arene.nom_palier(palier), int(a.get("points", 0)), int(a.get("niveau", 1))], 15, Arene.couleur_palier(palier)))
		if str(a.get("guilde", "")) != "":
			infos.add_child(UiCommun.label("Guilde : " + str(a.get("guilde")), 15, UiCommun.C_DOUX))
	infos.add_child(UiCommun.label("Puissance %s" % _nombre(Arene.puissance(equipe)), 15, UiCommun.C_DOUX))
	var equipe_box := HBoxContainer.new()
	equipe_box.add_theme_constant_override("separation", 6)
	equipe_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(equipe_box)
	for u in equipe:
		equipe_box.add_child(_mini_unite(u))
	var b := UiCommun.bouton("Combattre", 19)
	b.custom_minimum_size = Vector2(180, 52)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_attaquer.bind(a))
	ligne.add_child(b)
	return p


func _attaquer(a: Dictionary) -> void:
	if _occupe:
		return
	var equipe := Arene.equipe_attaque()
	if equipe.is_empty():
		_message.text = "Ton équipe est vide : ajoute des héros dans le Deck."
		return
	var gratuits := int(_etat.get("essais_gratuits_restants", 0))
	if gratuits > 0:
		_lancer(a, false)
		return
	if int(_etat.get("essais_payants_restants", 0)) <= 0:
		_message.text = Arene.texte_erreur("plus_d_essais")
		return
	var cout := int(_etat.get("cout_essai_gemmes", 20))
	FenetreSimple.confirmer(self, "Combat supplémentaire",
		"Tu as utilisé tes combats gratuits du jour.\nCombattre quand même pour %d gemmes ? (tu en as %d)" % [cout, Sauvegarde.get_gemmes()],
		"Payer %d gemmes" % cout, func():
			if Sauvegarde.get_gemmes() < cout:
				_message.text = "Pas assez de gemmes."
				return
			_lancer(a, true))


func _lancer(a: Dictionary, payant: bool) -> void:
	_occupe = true
	_message.text = "Préparation du combat…"
	var r := await EnLigne.appeler("arene_commencer", {"p_adversaire": null if a.is_empty() else a["id"], "p_payant": payant})
	_occupe = false
	if not is_inside_tree():
		return
	if not r.ok:
		_message.text = r.erreur
		return
	var d: Dictionary = r.data
	if not d.get("ok", false):
		_message.text = Arene.texte_erreur(str(d.get("erreur", "")))
		return
	if payant:
		Sauvegarde.depenser_gemmes(int(_etat.get("cout_essai_gemmes", 20)))
	var ennemis: Array
	var nom := "Gardien de l'Arène"
	if d.get("adversaire") is Dictionary:
		ennemis = Arene.nettoyer(d["adversaire"].get("equipe", []))
		nom = EnLigne.nom_complet(str(d["adversaire"].get("pseudo", "?")))
	else:
		ennemis = Arene.equipe_gardien()
	EcranCombat.demande = {"mode": "arene", "type": "arene", "combat": d["combat"], "graine": int(d["graine"]),
		"adversaire": nom, "equipe": Arene.equipe_attaque(), "ennemis": ennemis, "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


# ---------- Défense ----------

func _afficher_defense() -> void:
	_titre("Équipe de défense")
	_texte("Les autres joueurs affrontent cette équipe quand tu n'es pas là. Places 1-2 : Avant · places 3-5 : Arrière.\nClique un héros de ta collection puis une place (clique une place occupée pour la vider).")

	var places := HBoxContainer.new()
	places.add_theme_constant_override("separation", 12)
	_contenu.add_child(places)
	for i in 5:
		var uid := int(_slots_def[i])
		var b: Button
		if uid >= 0:
			b = UiCommun.carte_heros(Sauvegarde.get_heros(uid), 150, 190)
		else:
			b = Button.new()
			b.custom_minimum_size = Vector2(150, 190)
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_DOUX.darkened(0.4)))
			b.text = "Place %d\n%s\n(vide)" % [i + 1, "Avant" if i < 2 else "Arrière"]
		b.pressed.connect(_clic_place.bind(i))
		places.add_child(b)
		if i == 1:
			places.add_child(VSeparator.new())

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 10)
	_contenu.add_child(boutons)
	var copier := UiCommun.bouton("Copier mon équipe du Deck")
	copier.pressed.connect(func():
		_slots_def = Sauvegarde.get_slots()
		_def_modifiee = true
		_changer_onglet("defense"))
	boutons.add_child(copier)
	var envoyer := UiCommun.bouton("Enregistrer la défense")
	envoyer.custom_minimum_size = Vector2(260, 44)
	envoyer.pressed.connect(_enregistrer_defense)
	boutons.add_child(envoyer)
	var equipe := Arene.equipe_depuis_slots(_slots_def)
	var info := "Puissance %s" % _nombre(Arene.puissance(equipe))
	if _def_modifiee:
		info += "   ·   modifications NON enregistrées"
	elif not (_etat.get("equipe", []) as Array).is_empty():
		info += "   ·   enregistrée sur le serveur ✓"
	var li := UiCommun.label(info, 17, Color(1.0, 0.8, 0.5) if _def_modifiee else UiCommun.C_DOUX)
	li.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boutons.add_child(li)

	_titre("Ta collection")
	var grille := GridContainer.new()
	grille.columns = 9
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	_contenu.add_child(grille)
	var heros := Sauvegarde.liste_heros().duplicate()
	heros.sort_custom(func(x, y): return int(x["niveau"]) > int(y["niveau"]))
	for h in heros:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h, 132, 168)
		if uid == _selection_uid:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_LEGENDE, 0.1, 4))
		if uid in _slots_def:
			UiCommun.badge(carte, "Défense", UiCommun.C_OR)
		carte.pressed.connect(func():
			_selection_uid = -1 if _selection_uid == uid else uid
			_changer_onglet("defense"))
		grille.add_child(carte)


func _clic_place(i: int) -> void:
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


func _enregistrer_defense() -> void:
	var equipe := Arene.equipe_depuis_slots(_slots_def)
	if equipe.is_empty():
		_message.text = Arene.texte_erreur("vide")
		return
	_message.text = "Enregistrement…"
	var r := await EnLigne.appeler("arene_definir_defense", {"p_equipe": equipe, "p_puissance": Arene.puissance(equipe)})
	if not is_inside_tree():
		return
	if r.ok and str(r.data) == "ok":
		Arene.definir_slots_defense(_slots_def)
		_def_modifiee = false
		await _charger(true)
		_message.text = "Défense enregistrée ! Les autres joueurs peuvent maintenant t'affronter."
	else:
		_message.text = r.erreur if not r.ok else Arene.texte_erreur(str(r.data))


# ---------- Classement ----------

func _afficher_classement() -> void:
	_titre("Classement de la saison %d" % int(_etat.get("saison", 1)))
	_texte("Paliers : Bronze · Argent 1100 · Or 1300 · Platine 1500 · Diamant 1800 · Légende = top 10 avec 1800 points ou plus.")
	var chargement := UiCommun.label("Chargement…", 16, UiCommun.C_DOUX)
	_contenu.add_child(chargement)
	var r := await EnLigne.appeler("arene_classement", {"p_limite": 100})
	if not is_inside_tree() or _onglet != "classement":
		return
	chargement.queue_free()
	if not r.ok:
		_texte(r.erreur)
		return
	for l in r.data:
		var moi := str(l.id) == EnLigne.id_joueur()
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_LEGENDE if moi else Arene.couleur_palier(str(l.palier)).darkened(0.45)))
		var m := _marge(p, 6)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 16)
		m.add_child(ligne)
		var rang := UiCommun.label("#%d" % int(l.rang), 24, UiCommun.C_LEGENDE if int(l.rang) <= 3 else UiCommun.C_TEXTE)
		rang.custom_minimum_size = Vector2(70, 0)
		rang.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(rang)
		var av := UiCommun.avatar(str(l.heros_vitrine), str(l.pseudo), 46)
		av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(av)
		var nom := UiCommun.label(EnLigne.nom_complet(str(l.pseudo)) + ("  (toi)" if moi else ""), 20)
		nom.custom_minimum_size = Vector2(260, 0)
		nom.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(nom)
		var pal := UiCommun.label(Arene.nom_palier(str(l.palier)), 18, Arene.couleur_palier(str(l.palier)))
		pal.custom_minimum_size = Vector2(120, 0)
		pal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(pal)
		var pts := UiCommun.label("%d pts" % int(l.points), 20, UiCommun.C_LEGENDE)
		pts.custom_minimum_size = Vector2(130, 0)
		pts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(pts)
		var vd := UiCommun.label("%d V · %d D" % [int(l.victoires), int(l.defaites)], 16, UiCommun.C_DOUX)
		vd.custom_minimum_size = Vector2(130, 0)
		vd.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(vd)
		var gu := UiCommun.label(str(l.guilde), 16, UiCommun.C_DOUX)
		gu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(gu)
		var profil := UiCommun.bouton("Profil", 15)
		profil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		profil.pressed.connect(func(): EcranSocial.ouvrir_profil(self, str(l.id)))
		ligne.add_child(profil)
		_contenu.add_child(p)
	if (r.data as Array).is_empty():
		_texte("Personne n'est encore classé cette saison.")


# ---------- Historique ----------

func _afficher_historique() -> void:
	_titre("Derniers combats")
	var chargement := UiCommun.label("Chargement…", 16, UiCommun.C_DOUX)
	_contenu.add_child(chargement)
	var r := await EnLigne.appeler("arene_historique")
	if not is_inside_tree() or _onglet != "historique":
		return
	chargement.queue_free()
	if not r.ok:
		_texte(r.erreur)
		return
	if (r.data as Array).is_empty():
		_texte("Aucun combat pour l'instant.")
	for h in r.data:
		var attaque: bool = h.attaque
		var victoire: bool = h.victoire == true
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiCommun.style_carte((C_VERT if victoire else C_ROUGE).darkened(0.5)))
		var m := _marge(p, 8)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 16)
		m.add_child(ligne)
		var icone := UiCommun.label("⚔" if attaque else "◆", 28, UiCommun.C_OR)
		icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(icone)
		var infos := VBoxContainer.new()
		infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(infos)
		var autre := str(h.autre_pseudo)
		var texte := ("Tu as attaqué %s" if attaque else "%s a attaqué ta défense") % autre
		infos.add_child(UiCommun.label(texte, 19))
		infos.add_child(UiCommun.label(_date(str(h.date)), 14, UiCommun.C_DOUX))
		var pts := int(h.points) if h.points != null else 0
		var res := UiCommun.label("%s   %s%d pts" % ["VICTOIRE" if victoire else "DÉFAITE", "+" if pts >= 0 else "", pts], 20, C_VERT if victoire else C_ROUGE)
		res.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ligne.add_child(res)
		if not attaque and h.autre_id != null:
			var rev := UiCommun.bouton("Revanche", 16)
			rev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var id_autre := str(h.autre_id)
			rev.pressed.connect(func(): _revanche(id_autre))
			ligne.add_child(rev)
		_contenu.add_child(p)


func _revanche(id_joueur: String) -> void:
	var r := await EnLigne.appeler("arene_fiche", {"p_joueur": id_joueur})
	if not is_inside_tree():
		return
	if not r.ok or not (r.data is Dictionary):
		_message.text = Arene.texte_erreur("introuvable")
		return
	_attaquer(r.data)


# ---------- Boutique ----------

func _afficher_boutique() -> void:
	_titre("Boutique de l'Arène")
	_texte("Échange tes Insignes d'Arène (gagnées à chaque combat et en fin de saison). Les limites se remettent à zéro à chaque saison.")
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	_contenu.add_child(grille)
	var achats: Dictionary = _etat.get("achats", {})
	for art in _etat.get("boutique", []):
		var id := str(art.id)
		var deja := int(achats.get(id, 0))
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(390, 0)
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(Arene.couleur_objet(id).darkened(0.3)))
		var m := _marge(p, 12)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 6)
		m.add_child(vb)
		var haut := HBoxContainer.new()
		haut.add_theme_constant_override("separation", 12)
		vb.add_child(haut)
		haut.add_child(UiCommun.icone_objet(id, 48))
		var noms := VBoxContainer.new()
		haut.add_child(noms)
		noms.add_child(UiCommun.label("%s%s" % [Arene.nom_objet(id), " x%d" % int(art.quantite) if int(art.quantite) > 1 else ""], 19))
		noms.add_child(UiCommun.label("Achetés : %d / %d" % [deja, int(art.limite)], 14, UiCommun.C_DOUX))
		var b := UiCommun.bouton("Acheter · %d Insignes" % int(art.prix))
		b.disabled = deja >= int(art.limite) or int(_etat.get("insignes", 0)) < int(art.prix)
		b.pressed.connect(_acheter.bind(id))
		vb.add_child(b)
		grille.add_child(p)


func _acheter(id: String) -> void:
	if _occupe:
		return
	_occupe = true
	var r := await EnLigne.appeler("arene_acheter", {"p_article": id})
	_occupe = false
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary and r.data.get("ok", false):
		Sauvegarde.ajouter_objet(id, int(r.data.quantite))
		await _charger()
		_message.text = "%s x%d ajouté au Reliquaire." % [Arene.nom_objet(id), int(r.data.quantite)]
	else:
		_message.text = r.erreur if not r.ok else Arene.texte_erreur(str(r.data.get("erreur", "")))


# ---------- Récompenses de fin de saison ----------

func _proposer_recompenses() -> void:
	var liste: Array = _etat.get("recompenses", [])
	if liste.is_empty():
		return
	var texte := ""
	for rec in liste:
		texte += "Saison %d : %s (rang %d, %d points)\n   → %d Insignes et %d gemmes\n" % [int(rec.saison),
			Arene.nom_palier(str(rec.palier)), int(rec.rang), int(rec.points), int(rec.insignes), int(rec.gemmes)]
	FenetreSimple.ouvrir(self, "FIN DE SAISON", texte, [["Réclamer", func():
		var r := await EnLigne.appeler("arene_reclamer")
		if r.ok and r.data is Dictionary and r.data.get("ok", false):
			Sauvegarde.ajouter_gemmes(int(r.data.gemmes))
			if is_inside_tree():
				await _charger()
				_message.text = "Récompenses reçues : +%d Insignes, +%d gemmes." % [int(r.data.insignes), int(r.data.gemmes)]]])


# ---------------------------------------------------------------
# Outils
# ---------------------------------------------------------------

func _mini_unite(u: Dictionary) -> Control:
	var h := {"id": u["id"], "niveau": int(u.get("niveau", 1)), "etoiles": int(u.get("etoiles", 1)), "xp": 0}
	var c := UiCommun.carte_heros(h, 104, 136)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _titre(texte: String) -> void:
	_contenu.add_child(UiCommun.label(texte, 22, UiCommun.C_OR))


func _texte(texte: String) -> void:
	var l := UiCommun.label(texte, 16, UiCommun.C_DOUX)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(l)


func _marge(parent: Control, valeur: int) -> MarginContainer:
	var m := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + cote, valeur)
	parent.add_child(m)
	return m


func _nombre(n: int) -> String:
	var s := str(n)
	var res := ""
	while s.length() > 3:
		res = " " + s.right(3) + res
		s = s.left(s.length() - 3)
	return s + res


func _date(iso: String) -> String:
	var u := EnLigne.date_vers_unix(iso)
	if u <= 0:
		return ""
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_datetime_string_from_unix_time(u + bias, true).left(16)


func _vider(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _retour() -> void:
	onglet_memo = "combattre"
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else "res://scenes/aventure.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_retour()
