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
## Position des yeux des deux frères dans l'illustration (fraction de l'image) : les gouttes en partent.
const OEIL_LARME := Vector2(0.236, 0.335)
const OEIL_SANG := Vector2(0.815, 0.345)
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
	# Image affichée « en couverture » : on retrouve où tombent les yeux des frères à l'écran
	var tex_taille := Vector2(16, 9)
	if ResourceLoader.exists(IMAGE):
		tex_taille = (load(IMAGE) as Texture2D).get_size()
	var echelle := maxf(s.x / tex_taille.x, s.y / tex_taille.y)
	var decal := (s - tex_taille * echelle) / 2.0
	_sceau.source_larme = (decal + OEIL_LARME * tex_taille * echelle) / s
	_sceau.source_sang = (decal + OEIL_SANG * tex_taille * echelle) / s
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
	_sceau.queue_redraw()


func _changer(p: String) -> void:
	_phase = p
	_t_phase = 0.0


# =====================================================================
# Le Sceau des Frères (dessiné) : deux moitiés, larmes et gouttes de sang qui coulent des yeux des frères
# =====================================================================
class Sceau extends Control:
	var niveau := 0.0        # remplissage 0 → 1
	var ecart := 1.0         # écartement des moitiés (1 = brisé, 0 = ressoudé)
	var soude := false
	var onde := -1.0         # onde de choc (secondes depuis la soudure)
	var temps := 0.0
	## Points de départ des gouttes (les yeux des frères), en fraction de l'écran
	var source_larme := Vector2(0.18, 0.4)
	var source_sang := Vector2(0.82, 0.4)
	var _gouttes: Array = []     # {cote, u, vitesse}
	var _prochaine := 0.0
	var _dernier := 0.0

	func _draw() -> void:
		var s := size
		var c := Vector2(s.x * 0.5, s.y * 0.53)
		var r := minf(s.x, s.y) * 0.13
		var dx := r * 0.32 * ecart
		var rot := deg_to_rad(7.0) * ecart        # moitiés légèrement inclinées tant qu'elles sont brisées
		var dt := clampf(temps - _dernier, 0.0, 0.1)
		_dernier = temps

		# Halo de chaque moitié, qui grandit avec le remplissage
		for i in 8:
			var a := (0.025 + 0.05 * niveau) * (1.0 - i / 8.0)
			draw_circle(c + Vector2(-dx - r * 0.25, 0), r * (1.1 + i * 0.13), Color(EcranChargement.C_LARME, a))
			draw_circle(c + Vector2(dx + r * 0.25, 0), r * (1.1 + i * 0.13), Color(EcranChargement.C_SANG, a))

		# Cercle de runes qui tourne lentement
		var rr := r * 1.32
		for k in 24:
			var a0 := temps * 0.25 + k * TAU / 24.0
			draw_arc(c, rr, a0, a0 + TAU / 48.0, 6, Color(EcranChargement.C_OR, 0.25 + 0.35 * niveau), 2.0, true)
		draw_arc(c, rr * 1.06, 0, TAU, 96, Color(EcranChargement.C_OR, 0.12), 1.0, true)

		_gouttes_couler(s, c, r, dx, dt)
		_moitie(c + Vector2(-dx, 0), r, -1, rot, EcranChargement.C_LARME)
		_moitie(c + Vector2(dx, 0), r, 1, -rot, EcranChargement.C_SANG)

		if not soude:
			var h := r * 1.05
			draw_line(c + Vector2(0, -h), c + Vector2(0, h), Color(1, 1, 1, 0.04 + 0.25 * niveau), 2.0)
		else:
			draw_arc(c, r * 1.08, 0, TAU, 96, Color(1, 0.95, 0.85, 0.9), 3.0, true)

		# Onde de choc après la soudure
		if onde >= 0.0:
			var k := clampf(onde / 1.6, 0.0, 1.0)
			var ro := r + k * s.length() * 0.7
			draw_arc(c, ro, 0, TAU, 128, Color(1, 0.93, 0.8, (1.0 - k) * 0.8), 6.0 * (1.0 - k) + 1.0, true)
			draw_arc(c, ro * 0.82, 0, TAU, 128, Color(EcranChargement.C_LARME, (1.0 - k) * 0.5), 3.0, true)
			draw_arc(c, ro * 0.7, 0, TAU, 128, Color(EcranChargement.C_SANG, (1.0 - k) * 0.5), 3.0, true)

	## Une moitié du médaillon : cerclage doré, intérieur sombre, liquide qui monte avec le niveau.
	func _moitie(centre: Vector2, r: float, cote: int, rot: float, couleur: Color) -> void:
		var pts := PackedVector2Array()
		var n := 48
		for i in n + 1:
			var a := -PI / 2.0 + PI * i / n
			pts.append(Vector2(cos(a) * r * cote, sin(a) * r))
		var tr := Transform2D(rot, centre)
		var forme := tr * pts
		draw_colored_polygon(forme, Color(0.04, 0.02, 0.04, 0.94))
		if niveau > 0.001:
			var surface := r - 2.0 * r * niveau
			var liq := PackedVector2Array()
			var cols := PackedColorArray()
			for p in pts:
				var vague := sin(temps * 3.0 + p.x * 0.09 * cote) * r * 0.03 * (1.0 - niveau * 0.7)
				var q := Vector2(p.x, maxf(p.y, surface + vague))
				liq.append(q)
				# plus sombre au fond, plus vif près de la surface
				var prof := clampf((q.y - surface) / (2.0 * r), 0.0, 1.0)
				cols.append(couleur.lightened(0.35 * (1.0 - prof)).darkened(0.55 * prof))
			draw_polygon(tr * liq, cols)
			var h := PackedVector2Array()
			for p in liq:
				if absf(p.y - surface) < r * 0.07 and absf(p.x) < r * 0.97:
					h.append(p)
			if h.size() >= 2:
				draw_polyline(tr * h, Color(1, 1, 1, 0.45), 2.0, true)
		# reflet de verre
		var reflet := PackedVector2Array()
		for i in 13:
			var a := -PI / 2.0 + 0.25 + 0.9 * i / 12.0
			reflet.append(Vector2(cos(a) * r * 0.82 * cote, sin(a) * r * 0.82))
		draw_polyline(tr * reflet, Color(1, 1, 1, 0.18), 3.0, true)
		# cerclage doré (double)
		draw_polyline(forme, EcranChargement.C_OR.darkened(0.35), 7.0, true)
		draw_polyline(forme, EcranChargement.C_OR, 3.0, true)
		var interieur := PackedVector2Array()
		for p in pts:
			interieur.append(p * 0.9)
		draw_polyline(tr * interieur, Color(EcranChargement.C_OR, 0.45), 1.0, true)
		draw_line(tr * Vector2(0, -r), tr * Vector2(0, r), EcranChargement.C_OR, 3.0, true)
		# gemme de chaque moitié
		var g := tr * Vector2(r * 0.5 * cote, 0)
		draw_circle(g, r * 0.11, EcranChargement.C_OR.darkened(0.3))
		draw_circle(g, r * 0.08, couleur.lightened(0.15 + 0.4 * niveau))
		draw_circle(g + Vector2(-r * 0.025, -r * 0.025), r * 0.025, Color(1, 1, 1, 0.7))

	## Les gouttes coulent des yeux des frères en arc jusqu'à leur moitié du Sceau.
	func _gouttes_couler(s: Vector2, c: Vector2, r: float, dx: float, dt: float) -> void:
		if not soude and niveau < 0.999 and temps >= _prochaine:
			_prochaine = temps + randf_range(0.12, 0.28)
			_gouttes.append({"cote": -1 if randf() < 0.5 else 1, "u": 0.0, "v": randf_range(0.8, 1.1), "dx": randf_range(0.2, 0.7)})
		var restantes: Array = []
		for gt in _gouttes:
			gt["u"] = float(gt["u"]) + dt * float(gt["v"]) * (0.5 + float(gt["u"]) * 1.4)
			var u: float = gt["u"]
			if u >= 1.0:
				continue
			var cote: int = gt["cote"]
			var depart := (source_larme if cote < 0 else source_sang) * s
			var arrivee := c + Vector2((dx + r * float(gt["dx"])) * cote, r - 2.0 * r * niveau - r * 0.05)
			var ctrl := Vector2(lerpf(depart.x, arrivee.x, 0.45), minf(depart.y, arrivee.y) - s.y * 0.12)
			var col := EcranChargement.C_LARME if cote < 0 else EcranChargement.C_SANG
			# traînée lumineuse
			for k in 6:
				var uu := maxf(u - k * 0.025, 0.0)
				draw_circle(_bezier(depart, ctrl, arrivee, uu), r * (0.07 - k * 0.009), Color(col, 0.55 - k * 0.08))
			var p := _bezier(depart, ctrl, arrivee, u)
			draw_circle(p, r * 0.16, Color(col, 0.18))
			draw_circle(p, r * 0.1, Color(col, 0.35))
			draw_circle(p, r * 0.065, col.lightened(0.25))
			draw_circle(p + Vector2(-r * 0.02, -r * 0.02), r * 0.02, Color(1, 1, 1, 0.85))
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
