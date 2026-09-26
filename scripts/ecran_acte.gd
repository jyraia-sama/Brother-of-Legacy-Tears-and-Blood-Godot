extends Control
## Écran de sélection des chapitres d'un Acte.
##
## Une grande image par Acte : res://assets/actes/acte_01.png ... acte_12.png
## Des boutons invisibles sont posés sur les 6 vignettes et sur la flèche retour.
##
## POUR CHANGER L'IMAGE D'UN ACTE : remplace le fichier en gardant le même nom.
##
## SI LES BOUTONS NE TOMBENT PAS PILE SUR LES VIGNETTES (nouvelle image) :
##   1. Coche "Afficher Zones" dans l'Inspecteur (ou appuie sur F2 en jeu)
##      -> les zones cliquables apparaissent en rouge.
##   2. Ajuste les valeurs dans ZONES_PAR_ACTE plus bas pour cet Acte.
##
## POUR OUVRIR L'ÉCRAN D'UN ACTE depuis une autre scène :
##   ActesData.acte_courant = 3
##   get_tree().change_scene_to_file("res://scenes/ecran_acte.tscn")

signal chapitre_choisi(acte: int, chapitre: int)

const SCENE_PLATEAU := "res://scenes/plateau.tscn"
signal retour_demande

## Numéro de l'Acte (1 à 12). Laisse 0 pour utiliser ActesData.acte_courant.
@export_range(0, 12) var acte: int = 0
## Affiche les zones cliquables en rouge (pour les régler). Raccourci en jeu : F2.
@export var afficher_zones: bool = false
## Scène à ouvrir avec la flèche retour. Vide = retour automatique à l'écran précédent.
@export_file("*.tscn") var scene_retour: String = ""

# Zones cliquables, en FRACTIONS de l'image (0.0 = bord gauche/haut, 1.0 = bord droit/bas).
# Format : Rect2(x, y, largeur, hauteur). Mesurées sur l'image de l'Acte I.
const ZONES_DEFAUT := {
	"retour": Rect2(0.015, 0.011, 0.056, 0.096),
	1: Rect2(0.138, 0.239, 0.236, 0.308),
	2: Rect2(0.392, 0.239, 0.233, 0.308),
	3: Rect2(0.646, 0.239, 0.230, 0.308),
	4: Rect2(0.138, 0.569, 0.236, 0.313),
	5: Rect2(0.392, 0.569, 0.233, 0.313),
	6: Rect2(0.646, 0.569, 0.230, 0.313),
}

# Si une image d'Acte a ses vignettes ailleurs, mets ici SEULEMENT les zones à corriger.
# Exemple :
#   5: { 1: Rect2(0.14, 0.25, 0.23, 0.30), "retour": Rect2(0.02, 0.02, 0.06, 0.1) },
const ZONES_PAR_ACTE := {
}

var _fond: TextureRect
var _boutons: Array[Button] = []

# Bulle d'information affichée au survol d'un chapitre
var _info: PanelContainer
var _info_acte: Label
var _info_titre: Label
var _info_texte: Label

func _ready() -> void:
	ActesData.charger()
	if acte == 0:
		acte = ActesData.acte_courant
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fond noir (bandes si l'écran n'est pas en 16:9)
	var noir := ColorRect.new()
	noir.color = Color.BLACK
	noir.set_anchors_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(noir)

	var texture := ActesData.get_image(acte)

	# Conteneur qui garde les proportions de l'image
	var ratio := AspectRatioContainer.new()
	ratio.set_anchors_preset(Control.PRESET_FULL_RECT)
	ratio.stretch_mode = AspectRatioContainer.STRETCH_FIT
	ratio.ratio = (texture.get_width() / float(texture.get_height())) if texture else 16.0 / 9.0
	add_child(ratio)

	_fond = TextureRect.new()
	_fond.texture = texture
	_fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fond.stretch_mode = TextureRect.STRETCH_SCALE
	ratio.add_child(_fond)

	var zones := _zones_pour_acte(acte)
	for i in range(1, 7):
		if not ActesData.chapitre_debloque(acte, i):
			_voile_verrouille(zones[i])
		var b := _creer_bouton(zones[i])
		b.pressed.connect(_on_chapitre.bind(i))
		b.mouse_entered.connect(_montrer_info.bind(i, zones[i]))
		b.mouse_exited.connect(_cacher_info)
	var r := _creer_bouton(zones["retour"])
	r.pressed.connect(_on_retour)

	_creer_panneau_info()
	_maj_affichage_zones()

# Voile sombre + mention "VERROUILLÉ" sur un chapitre pas encore accessible
func _voile_verrouille(zone: Rect2) -> void:
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.62)
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voile.anchor_left = zone.position.x + zone.size.x * 0.04
	voile.anchor_top = zone.position.y + zone.size.y * 0.06
	voile.anchor_right = zone.end.x - zone.size.x * 0.04
	voile.anchor_bottom = zone.end.y - zone.size.y * 0.06
	_fond.add_child(voile)
	var l := Label.new()
	l.text = "VERROUILLÉ"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.85, 0.75, 0.6))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voile.add_child(l)

func _zones_pour_acte(n: int) -> Dictionary:
	var z := ZONES_DEFAUT.duplicate()
	if ZONES_PAR_ACTE.has(n):
		for cle in ZONES_PAR_ACTE[n]:
			z[cle] = ZONES_PAR_ACTE[n][cle]
	return z

func _creer_bouton(zone: Rect2) -> Button:
	var b := Button.new()
	b.anchor_left = zone.position.x
	b.anchor_top = zone.position.y
	b.anchor_right = zone.position.x + zone.size.x
	b.anchor_bottom = zone.position.y + zone.size.y
	b.offset_left = 0
	b.offset_top = 0
	b.offset_right = 0
	b.offset_bottom = 0
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	_fond.add_child(b)
	_boutons.append(b)
	return b

func _maj_affichage_zones() -> void:
	var vide := StyleBoxEmpty.new()
	# Survol : léger halo doré
	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(1.0, 0.85, 0.5, 0.10)
	survol.set_corner_radius_all(18)
	var appui: StyleBoxFlat = survol.duplicate()
	appui.bg_color = Color(1.0, 0.85, 0.5, 0.20)
	# Mode réglage : zones rouges visibles
	var debug := StyleBoxFlat.new()
	debug.bg_color = Color(1, 0, 0, 0.25)
	debug.border_color = Color(1, 0, 0, 0.9)
	debug.set_border_width_all(3)

	for b in _boutons:
		b.add_theme_stylebox_override("normal", debug if afficher_zones else vide)
		b.add_theme_stylebox_override("hover", debug if afficher_zones else survol)
		b.add_theme_stylebox_override("pressed", appui)
		b.add_theme_stylebox_override("focus", vide)

# ---------- Bulle d'information ----------

func _creer_panneau_info() -> void:
	_info = PanelContainer.new()
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.03, 0.94)
	style.border_color = Color(0.85, 0.65, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_info.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	_info.add_child(vbox)

	_info_acte = _label_info(15, Color(0.8, 0.55, 0.55))
	_info_titre = _label_info(24, Color(1.0, 0.85, 0.55))
	_info_texte = _label_info(18, Color(0.92, 0.88, 0.85))
	vbox.add_child(_info_acte)
	vbox.add_child(_info_titre)
	vbox.add_child(_info_texte)

	_fond.add_child(_info)
	_info.visible = false

func _label_info(taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l

func _montrer_info(numero: int, zone: Rect2) -> void:
	var a := ActesData.get_acte(acte)
	var chap := ActesData.get_chapitre(acte, numero)
	_info_acte.text = ("Acte %s : %s" % [a.get("romain", ""), a.get("titre", "")]).to_upper()
	_info_titre.text = "Chapitre %d : %s" % [numero, chap.get("titre", "")]
	if ActesData.est_termine(acte, numero):
		_info_titre.text += "  (terminé)"
	_info_texte.text = chap.get("description", "") + "\n\n" + Echos.texte_loot(acte, numero)
	if not ActesData.chapitre_debloque(acte, numero):
		_info_texte.text += "\n\nVERROUILLÉ : termine d'abord le chapitre précédent."

	# À droite de la vignette, sauf pour la colonne de droite (à gauche)
	var largeur := 0.20   # 20 % de la largeur de l'image
	var hauteur := 0.21
	var x := zone.end.x + 0.005
	if x + largeur > 1.0:
		x = zone.position.x - largeur - 0.005
	var y := zone.position.y + 0.02
	_info.anchor_left = x
	_info.anchor_top = y
	_info.anchor_right = x + largeur
	_info.anchor_bottom = y + hauteur
	_info.offset_left = 0
	_info.offset_top = 0
	_info.offset_right = 0
	_info.offset_bottom = 0
	_info.visible = true

func _cacher_info() -> void:
	_info.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			afficher_zones = not afficher_zones
			_maj_affichage_zones()
		elif event.keycode == KEY_ESCAPE:
			_on_retour()

func _on_chapitre(numero: int) -> void:
	if not ActesData.chapitre_debloque(acte, numero):
		return
	print("Acte %d - Chapitre %d : %s" % [acte, numero, ActesData.get_chapitre(acte, numero).get("titre", "")])
	chapitre_choisi.emit(acte, numero)
	ActesData.acte_courant = acte
	ActesData.chapitre_courant = numero
	get_tree().change_scene_to_file(SCENE_PLATEAU)

func _on_retour() -> void:
	retour_demande.emit()
	var cible := scene_retour
	if cible == "":
		cible = ActesData.scene_precedente
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)
