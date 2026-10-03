extends Control
## Menu principal - Brothers of Legacy : Tears and Blood
## Le fond est ton image ; par-dessus, on place des zones cliquables invisibles
## (elles s'illuminent au survol) et des textes (ressources, stats, titres).
## Astuce : appuie sur F1 pendant le jeu pour afficher toutes les zones et les recaler.

const BG_PATH := "res://assets/ui/menu_bg.png"

# Toutes les positions sont mesurées sur l'image en 1024x576.
# Elles sont converties en pourcentages : ça marche quelle que soit la résolution réelle.
const REF := Vector2(1024, 576)

# Les 6 grandes cartes (id, titre affiché, zone sur l'image)
const CARTES := [
	{"id": "aventure",   "titre": "AVENTURE",           "rect": Rect2(252, 124, 164, 146)},
	{"id": "deck",       "titre": "DECK",               "rect": Rect2(434, 124, 152, 146)},
	{"id": "invocation", "titre": "AUTEL D'INVOCATION", "rect": Rect2(604, 124, 154, 146)},
	{"id": "fusion",     "titre": "AUTEL DE FUSION",    "rect": Rect2(252, 294, 164, 146)},
	{"id": "echos",      "titre": "ÉCHOS SANGUINS",     "rect": Rect2(434, 294, 152, 146)},
	{"id": "reliquaire", "titre": "LE RELIQUAIRE",      "rect": Rect2(604, 294, 154, 146)},
]

# La barre du bas (5 icônes) - renomme-les comme tu veux
const BAS := [
	{"id": "quetes",    "titre": "Quêtes",      "rect": Rect2(276, 472, 72, 70)},
	{"id": "boutique",  "titre": "Boutique",    "rect": Rect2(374, 472, 72, 70)},
	{"id": "succes",    "titre": "Succès",      "rect": Rect2(474, 466, 72, 76)},
	{"id": "social",    "titre": "Social",      "rect": Rect2(574, 472, 72, 70)},
	{"id": "bestiaire", "titre": "Bestiaire",   "rect": Rect2(672, 472, 72, 70)},
]

# Boutons divers
const AUTRES := [
	{"id": "aide",       "titre": "Aide",       "rect": Rect2(10, 12, 50, 50)},
	{"id": "parametres", "titre": "Paramètres", "rect": Rect2(966, 12, 50, 50)},
	{"id": "heros",      "titre": "Mon héros",  "rect": Rect2(68, 110, 122, 120)},
	# Le bouclier sur la statue de droite
	{"id": "guilde",     "titre": "Guilde",     "rect": Rect2(956, 380, 56, 100)},
]

# Bouton du compte (pseudo), au-dessus du panneau du héros
const RECT_COMPTE := Rect2(64, 64, 130, 26)


# Textes de la barre de ressources (mis à jour depuis la sauvegarde)
var _lbl_stamina: Label
var _lbl_or: Label
var _lbl_niveau: Label
var _lbl_gemmes: Label
var _lbl_recharge: Label
var _lbl_xp: Label

var _zones: Array[Button] = []
var _debug := false
var _bouton_compte: Button
var _fenetre_compte: FenetreCompte


func _ready() -> void:
	# Jeu en ligne configuré et pas encore de compte ouvert : on propose de se connecter
	# (ou de jouer hors ligne) avant tout le reste, y compris le choix du héros.
	if EnLigne.doit_proposer_connexion():
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_creer_fond()
		FenetreCompte.ouvrir(self, true, _apres_connexion_demarrage)
		return
	# Tout premier lancement (ou après "Nouvelle partie") : choix du héros de départ
	if not Sauvegarde.a_choisi_heros_depart():
		get_tree().change_scene_to_file.call_deferred(EcranChoixHeros.SCENE)
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	for c in CARTES:
		_creer_zone(c.rect, c.id, c.titre)
		# Titre sur le bandeau rouge en bas de la carte
		var r: Rect2 = c.rect
		_creer_texte(c.titre, Rect2(r.position.x, r.end.y - 16, r.size.x, 14), 20)

	for c in BAS:
		_creer_zone(c.rect, c.id, c.titre)
	for c in AUTRES:
		_creer_zone(c.rect, c.id, c.titre)
	_creer_texte("GUILDE", Rect2(940, 478, 88, 16), 15)
	_creer_bouton_compte()

	# Barre de ressources en haut (valeurs réelles de la sauvegarde)
	_lbl_stamina = _creer_texte("", Rect2(276, 20, 80, 20), 22)
	_lbl_or = _creer_texte("", Rect2(404, 20, 68, 20), 22)
	_lbl_niveau = _creer_texte("", Rect2(540, 20, 110, 20), 22)
	_lbl_gemmes = _creer_texte("", Rect2(702, 20, 68, 20), 22)
	# Petites lignes sous la barre : recharge de la stamina et XP du compte
	_lbl_recharge = _creer_texte("", Rect2(256, 40, 120, 12), 13)
	_lbl_xp = _creer_texte("", Rect2(520, 40, 150, 12), 13)
	# Numéro de version (clic = journal des mises à jour)
	var v := Button.new()
	v.text = "%s  ·  Nouveautés" % Version.texte()
	v.flat = true
	v.focus_mode = Control.FOCUS_NONE
	v.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.75))
	v.tooltip_text = "Journal des mises à jour"
	v.pressed.connect(func(): FenetreChangelog.ouvrir(self))
	add_child(v)
	_placer(v, Rect2(880, 552, 140, 20))
	if Sauvegarde.admin_actif():
		var adm := _creer_texte("MODE ADMIN ACTIF", Rect2(880, 536, 140, 14), 14)
		adm.add_theme_color_override("font_color", Color("ff5a4a"))
	_maj_ressources()
	# La stamina se recharge avec le temps : on rafraîchit l'affichage chaque seconde
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_ressources)
	add_child(minuterie)

	# Stats du héros de départ (panneau de gauche)
	var h := Sauvegarde.get_heros_depart()
	var s := Sauvegarde.stats_heros(int(h.get("uid", -1)))
	if not s.is_empty():
		var u := UnitesData.get_unite(h["id"])
		_creer_texte("%s  Niv. %d" % [u["nom"], int(h["niveau"])], Rect2(60, 232, 140, 16), 15)
		_creer_texte("ATK %d" % s["atk"], Rect2(100, 256, 82, 16), 18)
		_creer_texte("DEF %d" % s["def"], Rect2(100, 277, 82, 16), 18)
		_creer_texte("PV %d" % s["pv"], Rect2(100, 297, 82, 16), 18)

	# Pastilles : quêtes et succès à réclamer
	_pastille("quetes", Quetes.a_reclamer())
	_pastille("succes", Succes.a_reclamer())

	# Secret : 5 touches rapides sur la lune rouge (ou taper ARNAUD) -> Donjon d'Arnaud
	var lune := Button.new()
	lune.flat = true
	lune.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		lune.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	lune.pressed.connect(_toucher_lune)
	add_child(lune)
	_placer(lune, Rect2(160, 12, 80, 50))
	# Secret : 3 touches rapides sur le blason au centre de la barre du haut (ou taper BELIER)
	# -> le Sanctuaire du Bélier
	var blason := Button.new()
	blason.flat = true
	blason.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		blason.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	blason.pressed.connect(_toucher_blason)
	add_child(blason)
	_placer(blason, Rect2(488, 2, 48, 58))

	# Guide des premiers pas (nouveau joueur)
	Tutoriel.preparer_etape()
	_creer_guide()

	# Le jeu vient d'être mis à jour : on montre les nouveautés
	FenetreChangelog.verifier_mise_a_jour(self)
	EnLigne.etat_change.connect(_sur_etat_compte)
	_sur_etat_compte()


## Petite pastille rouge avec un nombre sur une icône de la barre du bas.
func _pastille(id: String, n: int) -> void:
	if n <= 0:
		return
	for c in BAS:
		if c.id == id:
			var r: Rect2 = c.rect
			var l := _creer_texte(str(n), Rect2(r.end.x - 20, r.position.y - 2, 22, 18), 15)
			var st := StyleBoxFlat.new()
			st.bg_color = Color("d0202a")
			st.set_corner_radius_all(10)
			st.border_color = Color(1, 0.85, 0.6)
			st.set_border_width_all(2)
			l.add_theme_stylebox_override("normal", st)
			l.add_theme_color_override("font_color", Color.WHITE)


# ---------- Guide des premiers pas ----------

func _creer_guide() -> void:
	if not Tutoriel.visible():
		return
	var i := Tutoriel.etape_courante()
	var e: Dictionary = Tutoriel.ETAPES[i]
	var fait := Tutoriel.faite(e["id"])
	var p := PanelContainer.new()
	var st := UiCommun.style_panneau(UiCommun.C_OR if fait else Color("c89a50"), Color(0.06, 0.02, 0.03, 0.9))
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	add_child(p)
	_placer(p, Rect2(8, 318, 238, 146))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("PREMIERS PAS  %d/%d" % [i + 1, Tutoriel.ETAPES.size()], 15, UiCommun.C_DOUX)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var x := Button.new()
	x.text = "×"
	x.flat = true
	x.focus_mode = Control.FOCUS_NONE
	x.tooltip_text = "Masquer le guide (réaffichable dans les Paramètres)"
	x.add_theme_font_size_override("font_size", 22)
	x.pressed.connect(func():
		FenetreSimple.confirmer(self, "Masquer le guide ?", "Tu pourras le réafficher dans les Paramètres.", "Masquer", func():
			Tutoriel.masquer(true)
			get_tree().reload_current_scene()))
	tete.add_child(x)
	vb.add_child(UiCommun.label(str(e["titre"]) + ("  — fait !" if fait else ""), 19, UiCommun.C_OR))
	var d := UiCommun.label(e["texte"], 14, UiCommun.C_TEXTE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(d)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 8)
	vb.add_child(bas)
	var r := UiCommun.label("Récompense : " + Quetes.texte_recompense(e["recompense"]), 13, Color("ffb070"))
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bas.add_child(r)
	var b := UiCommun.bouton("Réclamer" if fait else "Y aller", 16)
	b.custom_minimum_size = Vector2(120, 40)
	if fait:
		b.pressed.connect(_reclamer_guide)
	else:
		var zone: String = e["zone"]
		b.pressed.connect(_on_bouton.bind(zone, zone))
	bas.add_child(b)
	if not fait:
		_mettre_en_avant(e["zone"])
	# Tout premier passage : mot d'accueil
	if i == 0 and not Tutoriel.faite("deck") and not "bienvenue" in Tutoriel._etat()["vus"]:
		Tutoriel._etat()["vus"].append("bienvenue")
		Sauvegarde.sauvegarder()
		FenetreSimple.ouvrir.call_deferred(self, "Bienvenue, héros !",
			"Le guide PREMIERS PAS (à gauche) t'accompagne pour tes débuts : suis ses étapes, le bouton concerné brille dans le menu, et chaque étape rapporte une récompense.\n\nLe bouton « ? » en haut à gauche explique tout le jeu. N'oublie pas ta récompense de connexion dans les Quêtes !",
			[["C'est parti !", null]])


## Fait briller (contour doré pulsé) le bouton du menu vers lequel le guide envoie.
func _mettre_en_avant(zone: String) -> void:
	for liste in [CARTES, BAS, AUTRES]:
		for c in liste:
			if c.id != zone:
				continue
			var cadre := Panel.new()
			cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var st := StyleBoxFlat.new()
			st.bg_color = Color(1.0, 0.8, 0.3, 0.08)
			st.border_color = Color(1.0, 0.82, 0.35)
			st.set_border_width_all(4)
			st.set_corner_radius_all(8)
			cadre.add_theme_stylebox_override("panel", st)
			add_child(cadre)
			_placer(cadre, c.rect)
			var tw := create_tween().set_loops()
			tw.tween_property(cadre, "modulate:a", 0.25, 0.7).set_trans(Tween.TRANS_SINE)
			tw.tween_property(cadre, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
			return


func _reclamer_guide() -> void:
	var l := Tutoriel.reclamer()
	if l.is_empty():
		return
	Audio.son("coffre")
	FenetreSimple.ouvrir(self, "Étape réussie !", "\n".join(l), [["Suite", get_tree().reload_current_scene]])


# ---------- Secret ----------

var _touches_lune := 0
var _derniere_touche := 0
var _saisie := ""


func _toucher_lune() -> void:
	var t := Time.get_ticks_msec()
	_touches_lune = _touches_lune + 1 if t - _derniere_touche < 1500 else 1
	_derniere_touche = t
	if _touches_lune >= 5:
		_ouvrir_donjon_arnaud()


var _touches_blason := 0
var _derniere_touche_blason := 0


func _toucher_blason() -> void:
	var t := Time.get_ticks_msec()
	_touches_blason = _touches_blason + 1 if t - _derniere_touche_blason < 1200 else 1
	_derniere_touche_blason = t
	if _touches_blason >= 3:
		_ouvrir_sanctuaire()


func _ouvrir_sanctuaire() -> void:
	Audio.son("coffre")
	get_tree().change_scene_to_file(Sanctuaire.SCENE)


func _ouvrir_donjon_arnaud() -> void:
	Audio.son("coffre")
	get_tree().change_scene_to_file(DonjonArnaud.SCENE)


func _apres_connexion_demarrage() -> void:
	get_tree().reload_current_scene()


# ---------- Compte ----------

func _creer_bouton_compte() -> void:
	_bouton_compte = Button.new()
	_bouton_compte.flat = true
	_bouton_compte.focus_mode = Control.FOCUS_NONE
	_bouton_compte.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_bouton_compte.add_theme_font_size_override("font_size", 16)
	_bouton_compte.add_theme_color_override("font_outline_color", Color.BLACK)
	_bouton_compte.add_theme_constant_override("outline_size", 6)
	_bouton_compte.pressed.connect(_ouvrir_compte)
	add_child(_bouton_compte)
	_placer(_bouton_compte, RECT_COMPTE)
	_maj_bouton_compte()


func _maj_bouton_compte() -> void:
	if _bouton_compte == null:
		return
	_bouton_compte.visible = EnLigne.configure()
	if EnLigne.est_connecte():
		_bouton_compte.text = "● " + EnLigne.nom_complet()
		_bouton_compte.tooltip_text = "Mon compte"
		_bouton_compte.add_theme_color_override("font_color", Color("8fe07a") if EnLigne.reseau_ok else Color("e0b35a"))
	elif EnLigne.connexion_en_cours():
		_bouton_compte.text = "Connexion…"
		_bouton_compte.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.7))
	else:
		_bouton_compte.text = "Se connecter"
		_bouton_compte.tooltip_text = "Hors ligne : clique pour te connecter"
		_bouton_compte.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))


func _ouvrir_compte() -> void:
	if is_instance_valid(_fenetre_compte):
		return
	_fenetre_compte = FenetreCompte.ouvrir(self)


func _sur_etat_compte() -> void:
	_maj_bouton_compte()
	# Session perdue au lancement (mot de passe changé, compte supprimé...) : on redemande.
	if EnLigne.doit_proposer_connexion() and not is_instance_valid(_fenetre_compte):
		_fenetre_compte = FenetreCompte.ouvrir(self, true)
	# Arrivée par le lien « mot de passe oublié » : on demande le nouveau mot de passe.
	elif EnLigne.lien_mot_de_passe and EnLigne.est_connecte() and not EnLigne.connexion_en_cours() \
			and not is_instance_valid(_fenetre_compte):
		_fenetre_compte = FenetreCompte.ouvrir(self)


func _maj_ressources() -> void:
	var st := Sauvegarde.get_stamina()
	var mx := Sauvegarde.get_stamina_max()
	_lbl_stamina.text = "%d/%d" % [st, mx]
	_lbl_recharge.text = "" if st >= mx else "+1 dans %s" % Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())
	_lbl_or.text = str(Sauvegarde.get_or())
	var niv := Sauvegarde.get_niveau_compte()
	_lbl_niveau.text = "Niv. %d" % niv
	_lbl_gemmes.text = str(Sauvegarde.get_gemmes())
	if Sauvegarde.niveau_compte_max_atteint():
		_lbl_xp.text = "Niveau MAX"
	else:
		_lbl_xp.text = "XP %d / %d" % [Sauvegarde.get_xp_compte(), Sauvegarde.xp_pour_niveau(niv)]


# ---------- Construction ----------

func _creer_fond() -> void:
	var tex: Texture2D = load(BG_PATH)
	if tex == null:
		push_error("FOND : impossible de charger " + BG_PATH)
		return
	print("FOND : image chargée, taille = ", tex.get_size())
	var fond := TextureRect.new()
	fond.texture = tex
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _placer(ctrl: Control, r: Rect2) -> void:
	# Ancre le contrôle en pourcentage de l'écran => il suit le redimensionnement
	ctrl.anchor_left = r.position.x / REF.x
	ctrl.anchor_top = r.position.y / REF.y
	ctrl.anchor_right = r.end.x / REF.x
	ctrl.anchor_bottom = r.end.y / REF.y
	ctrl.offset_left = 0
	ctrl.offset_top = 0
	ctrl.offset_right = 0
	ctrl.offset_bottom = 0


func _creer_zone(r: Rect2, id: String, titre: String) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = titre
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(1.0, 0.85, 0.4, 0.12)
	survol.border_color = Color(1.0, 0.8, 0.3, 0.95)
	survol.set_border_width_all(3)
	survol.set_corner_radius_all(6)

	var appui := survol.duplicate() as StyleBoxFlat
	appui.bg_color = Color(1.0, 0.25, 0.15, 0.3)

	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", appui)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("style_survol", survol)

	add_child(b)
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(id, titre))
	_zones.append(b)


func _creer_texte(texte: String, r: Rect2, taille: int) -> Label:
	var l := Label.new()
	l.text = texte
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	_placer(l, r)
	return l


# ---------- Actions ----------

func _on_bouton(id: String, titre: String) -> void:
	print("Clic : ", id)
	match id:
		"aventure":
			# L'écran Aventure reviendra toujours ici (et pas à l'écran des Actes)
			ActesData.scene_menu = scene_file_path
			ActesData.scene_precedente = scene_file_path
			get_tree().change_scene_to_file("res://scenes/aventure.tscn")
		"fusion":
			EcranFusion.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranFusion.SCENE)
		"parametres":
			FenetreSauvegarde.ouvrir(self)
		"deck":
			EcranDeck.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranDeck.SCENE)
		"echos":
			EcranEchos.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranEchos.SCENE)
		"invocation":
			EcranInvocation.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranInvocation.SCENE)
		"reliquaire":
			EcranReliquaire.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranReliquaire.SCENE)
		"bestiaire":
			EcranBestiaire.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranBestiaire.SCENE)
		"social":
			EcranSocial.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranSocial.SCENE)
		"guilde":
			EcranGuilde.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranGuilde.SCENE)
		"quetes":
			EcranBase.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranQuetes.SCENE)
		"succes":
			EcranBase.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranSucces.SCENE)
		"boutique":
			EcranBase.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranBoutique.SCENE)
		"heros":
			EcranBase.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranHeros.SCENE)
		"aide":
			FenetreAide.ouvrir(self)
		_:
			_message("« %s » : écran pas encore créé." % titre)


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Brothers of Legacy"
	d.dialog_text = texte
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	d.popup_centered()


# F1 : affiche / masque toutes les zones cliquables (pour les recaler)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.unicode > 0:
		_saisie = (_saisie + char(event.unicode).to_lower()).right(6)
		if _saisie == "arnaud":
			_ouvrir_donjon_arnaud()
			return
		if _saisie == "belier" or _saisie.ends_with("bélier".right(6)):
			_ouvrir_sanctuaire()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_debug = not _debug
		for b in _zones:
			var style: StyleBox = b.get_meta("style_survol") if _debug else StyleBoxEmpty.new()
			b.add_theme_stylebox_override("normal", style)
