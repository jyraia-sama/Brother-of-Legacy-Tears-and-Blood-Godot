class_name FenetreEnregistreur
extends CanvasLayer
## FENÊTRE DE L'ENREGISTREUR DE PARTIE (Menu Admin → « 🎥 Enregistreur de partie »).
## Activer / couper l'enregistrement, voir les dernières lignes, ajouter une note « bug ici »,
## puis copier, enregistrer ou télécharger le journal pour le transmettre.

const C_ENR := Color("e0503c")

var _case: CheckBox
var _etat: Label
var _apercu: RichTextLabel
var _note: LineEdit
var _flash: Label


static func ouvrir(parent: Node) -> void:
	parent.add_child(FenetreEnregistreur.new())


func _ready() -> void:
	layer = 72
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.75)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1250.0, vp.x - 40.0), minf(780.0, vp.y - 40.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_ENR, Color(0.06, 0.02, 0.02, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label(UiCommun.t("🎥 ENREGISTREUR DE PARTIE"), 26, C_ENR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton(UiCommun.t("Fermer"), 16)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)

	var aide := UiCommun.label(UiCommun.t("Note les écrans, les clics, les combats et toutes les erreurs du jeu pendant que tu joues. ")
		+ UiCommun.t("Quand un bug arrive : ajoute une note (ou appuie sur F8 sur PC : note + capture d'écran), puis copie ou enregistre le journal et envoie-le à Claude."), 15, UiCommun.C_DOUX)
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(aide)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 20)
	vb.add_child(ligne)
	_case = CheckBox.new()
	UiCommun.habiller_case(_case)
	_case.text = UiCommun.t("Enregistrer mes parties")
	_case.focus_mode = Control.FOCUS_NONE
	_case.button_pressed = Enregistreur.actif()
	_case.toggled.connect(func(oui: bool):
		Enregistreur.activer(oui)
		_maj())
	ligne.add_child(_case)
	_etat = UiCommun.label("", 16, UiCommun.C_TEXTE)
	_etat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(_etat)

	var ln := HBoxContainer.new()
	ln.add_theme_constant_override("separation", 8)
	vb.add_child(ln)
	_note = LineEdit.new()
	_note.placeholder_text = UiCommun.t("Décris ce qui ne va pas (ex. : le zoom saute quand je retire un héros)")
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.add_theme_font_size_override("font_size", 16)
	_note.text_submitted.connect(func(_t: String): _ajouter_note())
	ln.add_child(_note)
	var b_note := UiCommun.bouton(UiCommun.t("🐞 Marquer un bug"), 16)
	b_note.pressed.connect(_ajouter_note)
	ln.add_child(b_note)

	_apercu = RichTextLabel.new()
	_apercu.bbcode_enabled = true
	_apercu.scroll_following = true
	_apercu.selection_enabled = true
	_apercu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apercu.add_theme_font_size_override("normal_font_size", 14)
	_apercu.add_theme_color_override("default_color", UiCommun.C_TEXTE)
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0, 0, 0, 0.45)
	fond.set_content_margin_all(8)
	_apercu.add_theme_stylebox_override("normal", fond)
	vb.add_child(_apercu)

	var bas := HFlowContainer.new()
	bas.add_theme_constant_override("h_separation", 8)
	bas.add_theme_constant_override("v_separation", 8)
	vb.add_child(bas)
	_ajouter_bouton(bas, UiCommun.t("📋 Copier le journal"), _copier)
	if OS.has_feature("web"):
		_ajouter_bouton(bas, UiCommun.t("⬇ Télécharger le journal"), _telecharger)
	else:
		_ajouter_bouton(bas, UiCommun.t("💾 Enregistrer un fichier"), _enregistrer)
	if FileAccess.file_exists(Enregistreur.FICHIER_PRECEDENT):
		_ajouter_bouton(bas, UiCommun.t("📋 Copier le journal précédent"), _copier_precedent).tooltip_text = \
			UiCommun.t("Le journal du lancement d'avant (utile si le jeu a planté ou s'est fermé).")
	_ajouter_bouton(bas, UiCommun.t("🗑 Effacer"), func():
		Enregistreur.effacer()
		_maj())
	_flash = UiCommun.label("", 15, Color("8aff9a"))
	bas.add_child(_flash)

	_maj()
	var minuteur := Timer.new()
	minuteur.wait_time = 1.0
	minuteur.autostart = true
	minuteur.timeout.connect(_maj)
	add_child(minuteur)


func _ajouter_bouton(parent: Control, texte: String, action: Callable) -> Button:
	var b := UiCommun.bouton(texte, 15)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _maj() -> void:
	if Enregistreur.actif():
		_etat.text = UiCommun.t("● Enregistrement en cours  ·  %d lignes  ·  %d erreurs  ·  %d alertes") % [
			Enregistreur.nb_lignes(), Enregistreur.nb_erreurs(), Enregistreur.nb_alertes()]
		_etat.add_theme_color_override("font_color", C_ENR)
	else:
		_etat.text = UiCommun.t("Enregistrement coupé")
		_etat.add_theme_color_override("font_color", UiCommun.C_DOUX)
	var lignes := Enregistreur.dernieres(250)
	var t := ""
	for l in lignes:
		var c := ""
		if " ERREUR " in l or " ERR " in l:
			c = "#ff7a6a"
		elif " ALERT " in l:
			c = "#ffc070"
		elif " BUG " in l:
			c = "#ff5aff"
		elif " ECRAN " in l:
			c = "#ffd27a"
		elif " COMBAT " in l:
			c = "#8ad0ff"
		var s := l.replace("[", "[lb]")
		t += ("[color=%s]%s[/color]" % [c, s] if c != "" else s) + "\n"
	if t == "":
		t = UiCommun.t("[color=#a8968c](vide)[/color]")
	if _apercu.text != t:
		_apercu.text = t


func _ajouter_note() -> void:
	if not Enregistreur.actif():
		_montrer(UiCommun.t("Active d'abord l'enregistrement."), Color("ffb08a"))
		return
	var chemin := Enregistreur.marquer_bug(_note.text.strip_edges())
	_note.text = ""
	_montrer(UiCommun.t("Bug marqué") + (UiCommun.t(" + capture d'écran") if chemin != "" else "") + ".", Color("8aff9a"))
	_maj()


func _copier() -> void:
	DisplayServer.clipboard_set(Enregistreur.texte())
	_montrer(UiCommun.t("Journal copié : colle-le dans ta conversation avec Claude."), Color("8aff9a"))


func _copier_precedent() -> void:
	DisplayServer.clipboard_set(Enregistreur.texte_precedent())
	_montrer(UiCommun.t("Journal précédent copié."), Color("8aff9a"))


func _enregistrer() -> void:
	var chemin := Enregistreur.exporter()
	if chemin == "":
		_montrer(UiCommun.t("Impossible d'écrire le fichier."), Color("ff7a6a"))
		return
	var global := ProjectSettings.globalize_path(chemin)
	DisplayServer.clipboard_set(global)
	_montrer(UiCommun.t("Fichier enregistré : %s (chemin copié)") % global.get_file(), Color("8aff9a"))
	if not OS.has_feature("mobile"):
		OS.shell_open(ProjectSettings.globalize_path("user://"))


func _telecharger() -> void:
	var nom := "journal_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	JavaScriptBridge.download_buffer(Enregistreur.texte().to_utf8_buffer(), nom, "text/plain")
	_montrer(UiCommun.t("Téléchargement lancé."), Color("8aff9a"))


func _montrer(texte: String, couleur: Color) -> void:
	_flash.text = texte
	_flash.add_theme_color_override("font_color", couleur)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
