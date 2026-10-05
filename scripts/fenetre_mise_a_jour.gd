class_name FenetreMiseAJour
extends CanvasLayer
## Fenêtre « Mise à jour disponible » (version ordinateur).
## Ouverte par l'autoload MiseAJour au lancement, ou depuis les Paramètres (« Rechercher une mise à jour »).
## resultat : "maj" (mise à jour rapide), "installation" (installation complète nécessaire),
##            "pret" (déjà téléchargée, il reste à redémarrer), "a_jour" ou "erreur" (recherche manuelle).

var resultat := "maj"

var _vb: VBoxContainer
var _boutons: HBoxContainer
var _barre: ProgressBar
var _info: Label
var _bloquee := false   # mise à jour obligatoire : pas de « Plus tard »


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bloquee = MiseAJour.obligatoire() and resultat in ["maj", "installation", "pret"]

	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := UiCommun.style_panneau(UiCommun.C_OR, Color(0.08, 0.02, 0.03, 0.97))
	style.set_content_margin_all(24)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(680, 0)
	centre.add_child(panneau)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 12)
	panneau.add_child(_vb)

	match resultat:
		"a_jour":
			_titre("TON JEU EST À JOUR")
			_texte("Tu joues à la dernière version : v%s." % MiseAJour.version_actuelle, UiCommun.C_TEXTE)
			_ligne_boutons()
			_ajouter_bouton("OK", queue_free)
		"erreur":
			_titre("MISE À JOUR")
			_texte("Impossible de vérifier les mises à jour pour le moment. Vérifie ta connexion Internet et réessaie plus tard.", UiCommun.C_TEXTE)
			_ligne_boutons()
			_ajouter_bouton("OK", queue_free)
		"pret":
			_titre("MISE À JOUR PRÊTE")
			_texte("La version v%s est téléchargée. Relance le jeu pour en profiter." % str(MiseAJour.fiche.get("version", "")), UiCommun.C_TEXTE)
			_nouveautes()
			_ligne_boutons()
			if not _bloquee:
				_ajouter_bouton("Plus tard", queue_free)
			_ajouter_bouton(_texte_redemarrer(), MiseAJour.redemarrer, true)
		"installation":
			_titre("NOUVELLE VERSION : v%s" % str(MiseAJour.fiche.get("version", "")))
			_texte("Cette version demande de réinstaller le jeu (le moteur ou les réglages ont changé).\nTa partie est conservée : elle est enregistrée sur ton appareil et sur ton compte.", UiCommun.C_TEXTE)
			_nouveautes()
			_texte(_aide_installation(), UiCommun.C_DOUX, 15)
			_ligne_boutons()
			if not _bloquee:
				_ajouter_bouton("Plus tard", queue_free)
			_ajouter_bouton("Télécharger l'installation", MiseAJour.ouvrir_installation, true)
		_:
			_titre("MISE À JOUR DISPONIBLE : v%s" % str(MiseAJour.fiche.get("version", "")))
			var taille := int((MiseAJour.fiche.get("pck", {}) as Dictionary).get("taille", 0))
			var t := "Tu joues à la version v%s." % MiseAJour.version_actuelle
			if taille > 0:
				t += " Téléchargement : %.0f Mo." % (taille / 1048576.0)
			if _bloquee:
				t += "\nCette mise à jour est obligatoire pour continuer à jouer en ligne."
			_texte(t, UiCommun.C_TEXTE)
			_nouveautes()
			_barre = UiCommun.barre(UiCommun.C_OR, 620, 22)
			_barre.max_value = 1.0
			_barre.visible = false
			_vb.add_child(_barre)
			_info = _texte("", UiCommun.C_DOUX, 15)
			_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_info.visible = false
			_ligne_boutons()
			if not _bloquee:
				_ajouter_bouton("Plus tard", queue_free)
			_ajouter_bouton("Mettre à jour", _lancer, true)


func _process(_delta: float) -> void:
	if _barre == null or not MiseAJour.en_cours:
		return
	var p := MiseAJour.progression()
	if p >= 0.0:
		_barre.value = p
		_info.text = "Téléchargement… %d %%  (%.1f Mo)" % [int(p * 100), MiseAJour.octets_recus() / 1048576.0]
	else:
		_info.text = "Téléchargement… %.1f Mo" % (MiseAJour.octets_recus() / 1048576.0)


func _lancer() -> void:
	_boutons.visible = false
	_barre.visible = true
	_barre.value = 0
	_info.visible = true
	_info.text = "Téléchargement…"
	MiseAJour.telechargement_termine.connect(_fin, CONNECT_ONE_SHOT)
	MiseAJour.telecharger()


func _fin(ok: bool, message: String) -> void:
	for b in _boutons.get_children():
		b.queue_free()
	_boutons.visible = true
	if ok:
		_barre.value = 1.0
		_info.text = "Mise à jour installée ! " + ("Le jeu va redémarrer pour l'appliquer." if _peut_redemarrer() else "Le jeu va se fermer : rouvre-le pour jouer à la nouvelle version.")
		_info.add_theme_color_override("font_color", UiCommun.C_LEGENDE)
		if not _bloquee:
			_ajouter_bouton("Plus tard", queue_free)
		_ajouter_bouton(_texte_redemarrer(), MiseAJour.redemarrer, true)
	else:
		_barre.visible = false
		_info.text = message
		_info.add_theme_color_override("font_color", Color(1.0, 0.5, 0.45))
		if not _bloquee:
			_ajouter_bouton("Plus tard", queue_free)
		_ajouter_bouton("Réessayer", _lancer, true)


# ---------------------------------------------------------------------

func _titre(t: String) -> void:
	var l := UiCommun.label(t, 28, Color(1.0, 0.85, 0.55))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)


func _texte(t: String, couleur: Color, taille := 18) -> Label:
	var l := UiCommun.label(t, taille, couleur)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 620
	_vb.add_child(l)
	return l


## Liste des nouveautés depuis la version jouée (tirées du journal des versions publié).
func _nouveautes() -> void:
	var liste: Array = MiseAJour.fiche.get("nouveautes", [])
	var texte := ""
	for v in liste:
		if not (v is Dictionary) or MiseAJour.comparer(str(v.get("version", "")), MiseAJour.version_actuelle) <= 0:
			continue
		texte += "[color=#ffd27a][b]v%s — %s[/b][/color]\n" % [v.get("version", ""), v.get("titre", "")]
		for c in v.get("changements", []):
			texte += "• %s\n" % c
		texte += "\n"
	if texte == "":
		return
	var cadre := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.35)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(12)
	cadre.add_theme_stylebox_override("panel", s)
	_vb.add_child(cadre)
	# Hauteur ajustée au texte, avec défilement au-delà d'une certaine taille
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cadre.add_child(defil)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.scroll_active = false
	rt.text = texte.strip_edges()
	rt.custom_minimum_size.x = 600
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_size_override("normal_font_size", 16)
	rt.add_theme_font_size_override("bold_font_size", 17)
	rt.add_theme_color_override("default_color", UiCommun.C_TEXTE)
	defil.add_child(rt)
	var hauteur_max := clampf(get_viewport().get_visible_rect().size.y - 440.0, 120.0, 380.0)
	defil.custom_minimum_size = Vector2(600, hauteur_max)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(rt):
		defil.custom_minimum_size.y = minf(rt.get_content_height() + 4.0, hauteur_max)


## Windows et Mac relancent le jeu tout seuls ; Android le ferme (le joueur le rouvre).
func _peut_redemarrer() -> bool:
	return MiseAJour.peut_redemarrer()


func _texte_redemarrer() -> String:
	return "Redémarrer maintenant" if _peut_redemarrer() else "Fermer le jeu"


func _aide_installation() -> String:
	if MiseAJour.plateforme() == "android":
		return "Sur Android : ouvre le fichier .apk téléchargé et choisis « Installer » (ou « Mettre à jour »). Si le téléphone le demande, autorise ton navigateur à installer des applications. Ta partie est conservée."
	if MiseAJour.plateforme() == "macos":
		return "Sur Mac : ouvre le fichier .zip téléchargé, glisse l'application dans « Applications » à la place de l'ancienne, puis lance-la (si le Mac la bloque : Réglages Système → Confidentialité et sécurité → « Ouvrir quand même »)."
	return "Sur Windows : décompresse le fichier .zip téléchargé et remplace l'ancien dossier du jeu par le nouveau, puis lance BrothersOfLegacy.exe."


func _ligne_boutons() -> void:
	_boutons = HBoxContainer.new()
	_boutons.add_theme_constant_override("separation", 14)
	_boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	_vb.add_child(_boutons)


func _ajouter_bouton(texte: String, action: Callable, principal := false) -> void:
	var b := UiCommun.bouton(texte, 18)
	b.custom_minimum_size = Vector2(240, 46)
	if principal:
		b.add_theme_color_override("font_color", UiCommun.C_LEGENDE)
	b.pressed.connect(action)
	_boutons.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if not _bloquee and not MiseAJour.en_cours:
			queue_free()
