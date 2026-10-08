class_name EcranChargement
extends CanvasLayer
## ÉCRAN DE CHARGEMENT : « le Sceau des Frères se reforme ».
##
## Au lancement du jeu, entre les deux frères (image assets/ui/chargement.png), le médaillon brisé
## apparaît, vide. Des larmes bleues tombent dans la moitié de la Larme, des gouttes de sang dans
## celle du Sang : elles le remplissent au rythme du chargement des images du menu.
## À 100 %, les deux moitiés se ressoudent dans un éclair, une onde balaie l'écran, le titre apparaît,
## puis le menu se dévoile. Une phrase de l'histoire s'affiche en bas (différente à chaque lancement).
##
## Version web : la page de téléchargement (outils/web/chargement.html) joue déjà le remplissage
## pendant le téléchargement du jeu ; ici on enchaîne directement sur la fin (le Sceau se ressoude).
## Un clic ou une touche accélère l'animation.
##
##   EcranChargement.lancer(get_tree())     (une seule fois par lancement : main_menu.gd)

const IMAGE := "res://assets/ui/chargement.png"
## Ce qu'on charge pendant l'animation (les images du menu principal), pour un menu fluide ensuite.
const A_CHARGER := ["res://assets/ui/menu_freres.png", "res://assets/personnages/kael_valcendre.png",
	"res://assets/plateaux/pion_aine.png", "res://assets/personnages/aine.png"]
const DUREE_MIN := 2.6           # secondes de remplissage au minimum (pour profiter du spectacle)
const C_LARME := Color("3f9dff")
const C_SANG := Color("d11426")
const C_OR := Color("d9a64a")

const PHRASES := [
	"« Je t'avais promis de venir. »",
	"La Larme à l'aîné, le Sang au cadet. Le Sceau aux deux.",
	"Chaque année, la pierre bleue se couvre de rosée.",
	"Le Mal a choisi Kaël. Toi, tu as choisi ton frère.",
	"Deux moitiés d'un même médaillon. Deux moitiés d'une même lignée.",
	"Les Valcendre ne s'agenouillent pas. Ils se relèvent.",
	"Une larme pour ceux qu'on a perdus. Du sang pour ceux qu'on va sauver.",
	"Le domaine a brûlé. La lignée, elle, brûle encore.",
]

static var fait := false

var _t := 0.0
var _progres := 0.0           # 0 → 1 (affiché)
var _charge := 0.0            # 0 → 1 (réel)
var _phase := "remplir"       # remplir → souder → onde → fin
var _t_phase := 0.0
var _rapide := false
var _web := false
var _a_charger: Array = []

var _fond: Control
var _sceau: Sceau
var _flash: ColorRect
var _titre: Label
var _phrase: Label
var _pourcent: Label
var _racine: Control


static func lancer(arbre: SceneTree) -> void:
	if fait:
		return
	fait = true
	var e := EcranChargement.new()
	arbre.root.add_child.call_deferred(e)      # au-dessus de toutes les scènes, survit aux changements


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_web = OS.has_feature("web")
	_racine = Control.new()
	_racine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_racine.mouse_filter = Control.MOUSE_FILTER_STOP
	_racine.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton or ev is InputEventScreenTouch) and ev.pressed:
			_rapide = true)
	add_child(_racine)

	var noir := ColorRect.new()
	noir.color = Color("07040a")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(noir)
	_fond = Control.new()
	_fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(_fond)
	if ResourceLoader.exists(IMAGE):
		var img := TextureRect.new()
		img.texture = load(IMAGE)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fond.add_child(img)
	else:
		_fond.add_child(Lueurs.new())          # en attendant l'illustration : lueurs bleue et rouge

	_sceau = Sceau.new()
	_sceau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sceau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(_sceau)

	_titre = _label("BROTHERS OF LEGACY", 54, Color("f4e6d0"))
	_titre.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_titre.modulate.a = 0.0
	_racine.add_child(_titre)
	var sous := _label("TEARS  AND  BLOOD", 26, Color("f4e6d0"))
	sous.name = "Sous"
	_titre.add_child(sous)

	_phrase = _label(PHRASES[randi() % PHRASES.size()], 20, Color(0.85, 0.78, 0.72))
	_phrase.modulate.a = 0.0
	_racine.add_child(_phrase)
	_pourcent = _label("", 15, Color(0.7, 0.62, 0.58, 0.8))
	_racine.add_child(_pourcent)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(_flash)

	for c in A_CHARGER:
		if ResourceLoader.exists(c) and ResourceLoader.load_threaded_request(c) == OK:
			_a_charger.append(c)
	if _web:
		# La page web a déjà rempli le Sceau pendant le téléchargement : on passe à la fin.
		_progres = 1.0
		_charge = 1.0
	_disposer()
	get_viewport().size_changed.connect(_disposer)
	create_tween().tween_property(_phrase, "modulate:a", 1.0, 0.8).set_delay(0.3)


func _label(t: String, taille: int, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _disposer() -> void:
	var s := get_viewport().get_visible_rect().size
	_titre.size = Vector2(s.x, 70)
	_titre.position = Vector2(0, s.y * 0.13)
	var sous: Label = _titre.get_node("Sous")
	sous.size = Vector2(s.x, 40)
	sous.position = Vector2(0, 64)
	_phrase.size = Vector2(s.x - 40, 40)
	_phrase.position = Vector2(20, s.y * 0.87)
	_pourcent.size = Vector2(s.x, 24)
	_pourcent.position = Vector2(0, s.y * 0.87 + 34)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_rapide = true


func _process(delta: float) -> void:
	_t += delta
	_t_phase += delta
	var vitesse := 3.0 if _rapide else 1.0
	match _phase:
		"remplir":
			# Avancement réel des images du menu, mais jamais plus vite que DUREE_MIN
			var ok := 0
			for c in _a_charger:
				var st := ResourceLoader.load_threaded_get_status(c)
				if st != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					ok += 1
			if not _web:
				_charge = 1.0 if _a_charger.is_empty() else float(ok) / _a_charger.size()
			var plafond := minf(_charge, _t * vitesse / DUREE_MIN)
			_progres = move_toward(_progres, plafond, delta * vitesse * 0.9)
			_pourcent.text = "%d %%" % int(round(_progres * 100.0))
			if _progres >= 0.999 and _t_phase > 0.4:
				_progres = 1.0
				_changer("souder")
		"souder":
			# Les deux moitiés se rapprochent, puis se ressoudent
			_pourcent.text = ""
			var k := clampf(_t_phase * vitesse / 0.7, 0.0, 1.0)
			_sceau.ecart = lerpf(1.0, 0.0, k * k * (3.0 - 2.0 * k))
			if k >= 1.0:
				_flash.color.a = 0.95
				_sceau.soude = true
				_sceau.onde = 0.0
				create_tween().tween_property(_flash, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				create_tween().tween_property(_titre, "modulate:a", 1.0, 0.9).set_delay(0.15)
				_changer("onde")
		"onde":
			_sceau.onde = _t_phase * vitesse
			if _t_phase * vitesse > 1.9:
				_changer("fin")
				for c in _a_charger:
					ResourceLoader.load_threaded_get(c)       # récupère (ou abandonne) les chargements
				var tw := create_tween()
				tw.tween_property(_racine, "modulate:a", 0.0, 0.7 / vitesse)
				tw.tween_callback(queue_free)
	_sceau.niveau = _progres
	_sceau.temps = _t
	_sceau.queue_redraw()      # (les moitiés du médaillon se placent dans Sceau._process)


func _changer(p: String) -> void:
	_phase = p
	_t_phase = 0.0


# =====================================================================
# Le Sceau des Frères : médaillon peint en deux moitiés, larmes et gouttes de sang qui tombent du haut de l'écran
# =====================================================================
class Sceau extends Control:
	## Illustration du médaillon (outils/sources/sceau_source.png), coupée en deux le long de la fissure :
	## pour chaque moitié, la version « vide » (verre éteint) et le « liquide » seul, révélé par un shader.
	const DOSSIER := "res://assets/ui/sceau/"
	const LIQUIDE_Y := Vector2(0.228, 0.729)        # haut et bas du liquide dans l'image (fraction)
	const CIBLE_X := {-1: Vector2(0.30, 0.46), 1: Vector2(0.54, 0.70)}   # où tombent les gouttes

	var niveau := 0.0        # remplissage 0 → 1
	var ecart := 1.0         # écartement des moitiés (1 = brisé, 0 = ressoudé)
	var soude := false
	var onde := -1.0         # onde de choc (secondes depuis la soudure)
	var temps := 0.0
	var _gouttes: Array = []
	var _prochaine := 0.0
	var _dernier := 0.0
	var _moities := {}       # -1 / 1 -> {vide: TextureRect, liquide: TextureRect}
	var _dessus: Control
	var _image := true

	func _ready() -> void:
		_image = ResourceLoader.exists(DOSSIER + "gauche_vide.png")
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
uniform float niveau = 0.0;
uniform float y0 = 0.2;
uniform float y1 = 0.8;
uniform float temps = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float vague = sin(UV.x * 38.0 + temps * 3.2) * 0.006 + sin(UV.x * 17.0 - temps * 2.1) * 0.004;
	float surface = y1 - niveau * (y1 - y0) + vague * (1.0 - niveau * 0.6);
	if (UV.y < surface) { discard; }
	float bord = smoothstep(0.014, 0.0, UV.y - surface);
	c.rgb = mix(c.rgb, vec3(1.0), bord * 0.55);
	c.rgb *= 1.0 + 0.25 * sin(temps * 2.0 + UV.y * 20.0) * 0.2;
	COLOR = c;
}
"""
		if _image:
			for cote in [-1, 1]:
				var nom := "gauche" if cote < 0 else "droite"
				var v := TextureRect.new()
				v.texture = load(DOSSIER + nom + "_vide.png")
				var l := TextureRect.new()
				l.texture = load(DOSSIER + nom + "_liquide.png")
				var m := ShaderMaterial.new()
				m.shader = shader
				m.set_shader_parameter("y0", LIQUIDE_Y.x)
				m.set_shader_parameter("y1", LIQUIDE_Y.y)
				l.material = m
				for t in [v, l]:
					t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					t.stretch_mode = TextureRect.STRETCH_SCALE
					t.mouse_filter = Control.MOUSE_FILTER_IGNORE
					add_child(t)
				_moities[cote] = {"vide": v, "liquide": l}
		_dessus = Control.new()
		_dessus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dessus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_dessus.draw.connect(_dessiner_dessus)
		add_child(_dessus)

	## Carré où est affiché le médaillon entier (ailes comprises)
	func _cadre() -> Rect2:
		var cote := minf(size.x, size.y) * 0.5
		var c := Vector2(size.x * 0.5, size.y * 0.53)
		return Rect2(c - Vector2(cote, cote) / 2.0, Vector2(cote, cote))

	func _process(_delta: float) -> void:
		if not _image:
			return
		var cadre := _cadre()
		var dx := cadre.size.x * 0.05 * ecart
		for cote in _moities:
			var m: Dictionary = _moities[cote]
			for k in ["vide", "liquide"]:
				var t: TextureRect = m[k]
				t.position = cadre.position + Vector2(dx * cote, 0)
				t.size = cadre.size
				t.pivot_offset = cadre.size / 2.0
				t.rotation = deg_to_rad(4.0) * ecart * -cote
			var mat: ShaderMaterial = m["liquide"].material
			mat.set_shader_parameter("niveau", niveau)
			mat.set_shader_parameter("temps", temps)
		_dessus.queue_redraw()

	func _draw() -> void:
		# Derrière le médaillon : halos et cercle de runes
		var cadre := _cadre()
		var c := cadre.get_center()
		var r := cadre.size.x * 0.27
		for i in 8:
			var a := (0.03 + 0.06 * niveau) * (1.0 - i / 8.0)
			draw_circle(c + Vector2(-r * 0.45, 0), r * (1.0 + i * 0.16), Color(EcranChargement.C_LARME, a))
			draw_circle(c + Vector2(r * 0.45, 0), r * (1.0 + i * 0.16), Color(EcranChargement.C_SANG, a))
		var rr := cadre.size.x * 0.56
		for k in 32:
			var a0 := temps * 0.18 + k * TAU / 32.0
			draw_arc(c, rr, a0, a0 + TAU / 64.0, 6, Color(EcranChargement.C_OR, 0.18 + 0.3 * niveau), 2.0, true)
		draw_arc(c, rr * 1.04, 0, TAU, 128, Color(EcranChargement.C_OR, 0.1), 1.0, true)

	func _dessiner_dessus() -> void:
		var cadre := _cadre()
		var c := cadre.get_center()
		var dt := clampf(temps - _dernier, 0.0, 0.1)
		_dernier = temps
		_gouttes_couler(cadre, dt)
		if soude:
			# la fissure brille encore un instant
			var a := clampf(1.0 - onde / 1.2, 0.0, 1.0)
			_dessus.draw_line(c + Vector2(0, -cadre.size.y * 0.36), c + Vector2(0, cadre.size.y * 0.36), Color(1, 0.95, 0.85, a), 4.0)
		if onde >= 0.0:
			var k := clampf(onde / 1.6, 0.0, 1.0)
			var ro := cadre.size.x * 0.3 + k * size.length() * 0.7
			_dessus.draw_arc(c, ro, 0, TAU, 128, Color(1, 0.93, 0.8, (1.0 - k) * 0.8), 6.0 * (1.0 - k) + 1.0, true)
			_dessus.draw_arc(c, ro * 0.82, 0, TAU, 128, Color(EcranChargement.C_LARME, (1.0 - k) * 0.5), 3.0, true)
			_dessus.draw_arc(c, ro * 0.7, 0, TAU, 128, Color(EcranChargement.C_SANG, (1.0 - k) * 0.5), 3.0, true)

	## Les gouttes tombent verticalement du haut de l'écran jusqu'à la surface du liquide de leur moitié.
	func _gouttes_couler(cadre: Rect2, dt: float) -> void:
		var r := cadre.size.x * 0.27
		if not soude and niveau < 0.999 and temps >= _prochaine:
			_prochaine = temps + randf_range(0.12, 0.28)
			_gouttes.append({"cote": -1 if randf() < 0.5 else 1, "u": 0.0, "v": randf_range(0.8, 1.1), "x": randf()})
		var restantes: Array = []
		var dx := cadre.size.x * 0.05 * ecart
		for gt in _gouttes:
			gt["u"] = float(gt["u"]) + dt * float(gt["v"]) * (0.5 + float(gt["u"]) * 1.4)
			var u: float = gt["u"]
			if u >= 1.0:
				continue
			var cote: int = gt["cote"]
			var bx: Vector2 = CIBLE_X[cote]
			var surface := LIQUIDE_Y.y - niveau * (LIQUIDE_Y.y - LIQUIDE_Y.x)
			var arrivee := cadre.position + Vector2(lerpf(bx.x, bx.y, float(gt["x"])) * cadre.size.x + dx * cote, surface * cadre.size.y)
			var depart := Vector2(arrivee.x, -r * 0.3)
			var col := EcranChargement.C_LARME if cote < 0 else EcranChargement.C_SANG
			# chute accélérée, avec une traînée verticale
			var p := depart.lerp(arrivee, u * u)
			var vitesse := 2.0 * u
			_dessus.draw_line(p - Vector2(0, r * (0.15 + 0.6 * vitesse)), p, Color(col, 0.35), r * 0.05, true)
			_dessus.draw_line(p - Vector2(0, r * (0.08 + 0.3 * vitesse)), p, Color(col.lightened(0.3), 0.6), r * 0.03, true)
			_dessus.draw_circle(p, r * 0.14, Color(col, 0.18))
			_dessus.draw_circle(p, r * 0.09, Color(col, 0.35))
			_dessus.draw_circle(p, r * 0.055, col.lightened(0.3))
			_dessus.draw_circle(p + Vector2(-r * 0.017, -r * 0.017), r * 0.017, Color(1, 1, 1, 0.85))
			restantes.append(gt)
		_gouttes = restantes

	func _bezier(a: Vector2, b: Vector2, c2: Vector2, t: float) -> Vector2:
		return a.lerp(b, t).lerp(b.lerp(c2, t), t)


## Fond de secours (avant l'illustration) : lueur bleue à gauche, rouge à droite.
class Lueurs extends Control:
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size
		for i in 14:
			var k := i / 14.0
			draw_circle(Vector2(s.x * 0.12, s.y * 0.5), s.y * (0.9 - k * 0.6), Color(EcranChargement.C_LARME, 0.018))
			draw_circle(Vector2(s.x * 0.88, s.y * 0.5), s.y * (0.9 - k * 0.6), Color(EcranChargement.C_SANG, 0.018))
