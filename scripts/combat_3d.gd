class_name Combat3D
extends SubViewportContainer
## COMBATS EN 2,5D : le champ de bataille est une scène 3D (sol, décor, lumières, ombres, météo)
## où les figurines peintes se tiennent sur un SOCLE, comme des pions sur un plateau de jeu.
## Les règles ne changent pas : EcranCombat rejoue le même journal, et appelle ces fonctions pour animer.
## Les noms, barres de vie et textes flottants restent en 2D, placés au-dessus des figurines.
##
## - Chaque unité est un PION : un socle 3D (liseré de son élément) + la figurine peinte, éclairée
##   en relief par les torches et les sorts (shader figurine_3d.gdshader), qui respire et se balance.
##   Les pions tombent sur le plateau au début, glissent pour attaquer et basculent au K.O.
## - Chaque sort a un effet selon l'élément du lanceur et sa forme (une cible : projectile ;
##   plusieurs : effet au sol ou du ciel ; alliés : aura et anneaux).
## - Chaque Acte a son ambiance (couleurs, brume, pluie, neige, cendres, lucioles…).
## - Caméra cinéma (option, décochée par défaut) : ralenti et léger rapprochement sur les moments
##   forts. Jamais de tremblement (mal de mer, v0.63).
##
## Le décor peint (fond du combat) est coupé en deux : le haut est dressé au fond comme une toile,
## le bas devient le SOL et s'étend jusqu'à la caméra.

const SHADER_FIGURINE := preload("res://scripts/figurine_3d.gdshader")

const LARGEUR := 32.0           # largeur du décor (unités 3D)
const COUPE := 0.65             # part du décor dressée au fond ; le reste devient le sol
const Z_FOND := -6.0
const Z_PRES := 9.0
const LARGEUR_DECOR := 27.0     # largeur de la toile de fond d'un décor 3D (cadre + balancement)
const TASSEMENT_DECOR := 0.85   # hauteur de la toile de fond d'un décor 3D (1 = proportions exactes)
const VISEE_DECOR := 1.8        # la caméra vise un peu plus haut avec un décor 3D (plus de ciel)
const LARGEUR_MAX := 2.1         # largeur maxi (mètres) d'une figurine normale ou de boss
const TUILE_SOL := 6.0          # taille (en mètres) d'une répétition de la texture de sol
const HAUTEUR_UNITE := 2.3
const HAUTEUR_BOSS := 3.0
const HAUTEUR_GEANT := 7.5
const H_SOCLE := 0.13           # épaisseur du socle 3D

## AMBIANCE DE CHAQUE ACTE : météo, lumière ambiante, couleur des torches, réglages d'image, brume.
const AMBIANCES := {
	1: {"meteo": "braises", "amb": Color(0.66, 0.55, 0.55), "torche": Color(1.0, 0.55, 0.25), "sat": 1.12, "contraste": 1.08, "brume": 0.0},
	2: {"meteo": "pluie", "amb": Color(0.5, 0.56, 0.7), "torche": Color(1.0, 0.75, 0.45), "sat": 0.82, "contraste": 1.05, "brume": 0.0113, "c_brume": Color(0.25, 0.3, 0.38)},
	3: {"meteo": "braises", "amb": Color(0.66, 0.52, 0.48), "torche": Color(1.0, 0.5, 0.2), "sat": 1.1, "contraste": 1.08, "brume": 0.0},
	4: {"meteo": "lucioles", "amb": Color(0.45, 0.62, 0.6), "torche": Color(0.4, 1.0, 0.8), "sat": 0.95, "contraste": 1.06, "brume": 0.009, "c_brume": Color(0.1, 0.28, 0.25)},
	5: {"meteo": "cendres", "amb": Color(0.68, 0.52, 0.45), "torche": Color(1.0, 0.45, 0.2), "sat": 1.08, "contraste": 1.1, "brume": 0.0},
	6: {"meteo": "neige", "amb": Color(0.62, 0.66, 0.78), "torche": Color(0.75, 0.85, 1.0), "sat": 0.75, "contraste": 1.04, "brume": 0.0135, "c_brume": Color(0.3, 0.32, 0.4)},
	7: {"meteo": "spores", "amb": Color(0.5, 0.65, 0.48), "torche": Color(0.6, 1.0, 0.45), "sat": 0.95, "contraste": 1.06, "brume": 0.0113, "c_brume": Color(0.06, 0.1, 0.06), "sol": Color(0.9, 0.82, 1.0)},
	8: {"meteo": "cendres_rouges", "amb": Color(0.72, 0.45, 0.45), "torche": Color(1.0, 0.25, 0.2), "sat": 1.15, "contraste": 1.12, "brume": 0.0},
	9: {"meteo": "poussiere_or", "amb": Color(0.66, 0.58, 0.62), "torche": Color(1.0, 0.7, 0.45), "sat": 0.9, "contraste": 1.05, "brume": 0.0135, "c_brume": Color(0.2, 0.13, 0.15)},
	10: {"meteo": "cendres", "amb": Color(0.58, 0.58, 0.58), "torche": Color(1.0, 0.7, 0.5), "sat": 0.6, "contraste": 1.08, "brume": 0.0158, "c_brume": Color(0.17, 0.09, 0.08)},
	11: {"meteo": "orage", "amb": Color(0.58, 0.48, 0.7), "torche": Color(0.8, 0.5, 1.0), "sat": 1.0, "contraste": 1.1, "brume": 0.009, "c_brume": Color(0.16, 0.1, 0.16), "sol": Color(0.72, 0.8, 0.68)},
	12: {"meteo": "etincelles_or", "amb": Color(0.72, 0.58, 0.45), "torche": Color(1.0, 0.65, 0.25), "sat": 1.1, "contraste": 1.1, "brume": 0.0},
	13: {"meteo": "etincelles_violettes", "amb": Color(0.6, 0.5, 0.72), "torche": Color(0.75, 0.45, 1.0), "sat": 1.05, "contraste": 1.1, "brume": 0.0},
	# Décors des autres modes (utilisés dès que leur toile et leur sol sont dans assets/combat3d)
	"tour_enfer": {"meteo": "cendres_rouges", "amb": Color(0.74, 0.44, 0.4), "torche": Color(1.0, 0.35, 0.15), "sat": 1.15, "contraste": 1.12, "brume": 0.0},
	"tour_paradis": {"meteo": "plumes", "amb": Color(0.8, 0.76, 0.68), "torche": Color(1.0, 0.88, 0.6), "sat": 0.95, "contraste": 1.04, "brume": 0.009, "c_brume": Color(0.55, 0.52, 0.45)},
	"donjon_feu": {"meteo": "cendres", "amb": Color(0.72, 0.5, 0.42), "torche": Color(1.0, 0.45, 0.15), "sat": 1.12, "contraste": 1.1, "brume": 0.0},
	"donjon_nature": {"meteo": "spores", "amb": Color(0.52, 0.64, 0.46), "torche": Color(0.65, 1.0, 0.4), "sat": 0.95, "contraste": 1.06, "brume": 0.0113, "c_brume": Color(0.08, 0.12, 0.06)},
	"donjon_eau": {"meteo": "bulles", "amb": Color(0.45, 0.58, 0.72), "torche": Color(0.45, 0.85, 1.0), "sat": 0.9, "contraste": 1.05, "brume": 0.0135, "c_brume": Color(0.06, 0.14, 0.2)},
	"donjon_tenebres": {"meteo": "etincelles_violettes", "amb": Color(0.5, 0.46, 0.62), "torche": Color(0.65, 0.4, 1.0), "sat": 0.85, "contraste": 1.1, "brume": 0.0113, "c_brume": Color(0.08, 0.06, 0.12)},
	"donjon_sacre": {"meteo": "poussiere_or", "amb": Color(0.72, 0.66, 0.58), "torche": Color(1.0, 0.82, 0.5), "sat": 0.95, "contraste": 1.06, "brume": 0.009, "c_brume": Color(0.25, 0.2, 0.16), "sol": Color(0.68, 0.62, 0.58)},
	"donjon_neutre": {"meteo": "cendres_rouges", "amb": Color(0.7, 0.42, 0.42), "torche": Color(1.0, 0.2, 0.18), "sat": 1.0, "contraste": 1.12, "brume": 0.009, "c_brume": Color(0.18, 0.04, 0.05), "sol": Color(0.62, 0.55, 0.55)},
	"donjon_savoir": {"meteo": "poussiere_parchemin", "amb": Color(0.62, 0.56, 0.62), "torche": Color(0.6, 0.75, 1.0), "sat": 0.9, "contraste": 1.06, "brume": 0.009, "c_brume": Color(0.12, 0.1, 0.16)},
	"sanctuaire": {"meteo": "etincelles_or", "amb": Color(0.72, 0.62, 0.55), "torche": Color(1.0, 0.7, 0.35), "sat": 1.05, "contraste": 1.06, "brume": 0.0},
	"arene": {"meteo": "poussiere_or", "amb": Color(0.62, 0.6, 0.66), "torche": Color(1.0, 0.6, 0.3), "sat": 1.05, "contraste": 1.08, "brume": 0.0, "sol": Color(0.55, 0.52, 0.55)},
	"guerre": {"meteo": "cendres", "amb": Color(0.66, 0.52, 0.5), "torche": Color(1.0, 0.45, 0.2), "sat": 1.05, "contraste": 1.1, "brume": 0.009, "c_brume": Color(0.16, 0.1, 0.1)},
}

var _vp: SubViewport
var _monde: Node3D
var _camera: Camera3D
var _cam_base := Transform3D()
var _unites := {}               # idx -> {pion, fig, mat, socle, lisere, ombre, pos, hauteur, frac, largeur, rayon, boss, ko}
var _tw_cam: Tween
var _env: Environment
var vitesse := 1.0
var acte: Variant = 1           # ambiance : numéro d'Acte ou clé de décor d'un mode (à régler avant construire)
var camera_cinema := false      # ralenti et rapprochement sur les moments forts
var _n_poses := 0


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp = SubViewport.new()
	_vp.msaa_3d = Viewport.MSAA_2X
	_vp.own_world_3d = true
	add_child(_vp)
	_monde = Node3D.new()
	_vp.add_child(_monde)
	resized.connect(_replacer)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


## L'écran change de forme (rotation du téléphone, fenêtre) : on recale les unités dans le cadre.
func _replacer() -> void:
	if _camera == null:
		return
	for idx in _unites:
		var u: Dictionary = _unites[idx]
		var p := _pos_unite(u["frac"], float(u.get("largeur", 0.0)))
		var dx := p.x - Vector3(u["pos"]).x
		if absf(dx) < 0.001:
			continue
		u["pos"] = p
		for cle in ["pion", "ombre"]:
			var n: Node3D = u[cle]
			n.position.x += dx


func _ambiance() -> Dictionary:
	return AMBIANCES.get(acte, AMBIANCES[1])


## Construit le décor à partir de l'image de fond du combat.
## Avec chemin_sol (texture de sol raccordable, vue du dessus) : l'image de fond est entièrement dressée
## au fond (coupée à « coupe », là où commence son sol peint) et le sol 3D est carrelé avec la texture.
func construire(chemin_fond: String, teinte_nuit: Color, chemin_sol := "", coupe := COUPE) -> void:
	var amb := _ambiance()
	var tex: Texture2D = load(chemin_fond) if chemin_fond != "" and ResourceLoader.exists(chemin_fond) else null
	var tex_sol: Texture2D = load(chemin_sol) if chemin_sol != "" and ResourceLoader.exists(chemin_sol) else null
	if tex_sol == null:
		coupe = COUPE
	var ratio := 9.0 / 16.0
	if tex:
		ratio = float(tex.get_height()) / float(tex.get_width())
	var h_image := LARGEUR * ratio

	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = teinte_nuit
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = amb["amb"]
	_env.ambient_light_energy = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.glow_enabled = true
	_env.glow_intensity = 0.7
	_env.glow_bloom = 0.05
	_env.glow_hdr_threshold = 1.1
	_env.adjustment_enabled = true
	_env.adjustment_saturation = float(amb["sat"])
	_env.adjustment_contrast = float(amb["contraste"])
	if float(amb.get("brume", 0.0)) > 0.0:
		_env.fog_enabled = true
		_env.fog_light_color = amb.get("c_brume", Color(0.3, 0.3, 0.35))
		_env.fog_density = float(amb["brume"])
		_env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = _env
	_monde.add_child(we)

	# Toile de fond : le haut de l'image, dressé au fond
	var fond := MeshInstance3D.new()
	var q := QuadMesh.new()
	# Décor fait pour la 3D : toile juste assez large pour le cadre (et légèrement tassée en hauteur),
	# pour que le château et le ciel restent dans l'image au lieu de dépasser en haut.
	var l_fond := LARGEUR_DECOR if tex_sol else LARGEUR
	if tex_sol:
		h_image = l_fond * ratio * TASSEMENT_DECOR
	q.size = Vector2(l_fond, h_image * coupe)
	fond.mesh = q
	var mf := StandardMaterial3D.new()
	mf.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mf.albedo_color = Color(0.72, 0.68, 0.68)
	mf.disable_fog = true
	if tex:
		mf.albedo_texture = tex
		mf.uv1_scale = Vector3(1, coupe, 1)
	fond.material_override = mf
	fond.position = Vector3(0, h_image * coupe / 2.0, Z_FOND)
	_monde.add_child(fond)

	# Sol : le bas de l'image, couché et étiré jusqu'à la caméra (raccord parfait avec la toile)
	var sol := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(LARGEUR, Z_PRES - Z_FOND)
	sol.mesh = p
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.85, 0.8, 0.8)
	ms.roughness = 0.95
	if tex_sol:
		# Carrelage : une tuile tous les TUILE_SOL mètres, filtrage anisotrope pour rester net au loin
		ms.albedo_texture = tex_sol
		ms.uv1_scale = Vector3(LARGEUR / TUILE_SOL, (Z_PRES - Z_FOND) / TUILE_SOL, 1)
		ms.texture_repeat = true
		ms.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		# « sol » (AMBIANCES) : teinte du sol 3D pour qu'il garde la couleur du sol peint de la toile
		# (la lumière et la brume de l'Acte l'éclaircissent ou le colorent sinon).
		ms.albedo_color = Color(0.95, 0.88, 0.85) * (amb.get("sol", Color.WHITE) as Color)
	elif tex:
		ms.albedo_texture = tex
		ms.uv1_scale = Vector3(1, 1.0 - COUPE, 1)
		ms.uv1_offset = Vector3(0, COUPE, 0)
	else:
		ms.albedo_color = Color(0.25, 0.2, 0.2)
	sol.material_override = ms
	sol.position = Vector3(0, 0, (Z_FOND + Z_PRES) / 2.0)
	_monde.add_child(sol)

	# Lumières : lune (ombres), torches de chaque côté (couleur de l'Acte), lueur devant
	var lune := DirectionalLight3D.new()
	lune.light_color = Color(0.85, 0.8, 1.0)
	lune.light_energy = 0.5
	lune.shadow_enabled = true
	lune.shadow_opacity = 0.75
	lune.rotation_degrees = Vector3(-52, 25, 0)
	_monde.add_child(lune)
	var c_torche: Color = amb["torche"]
	_torche(Vector3(-9.5, 1.4, -2.5), c_torche)
	_torche(Vector3(9.5, 1.4, -2.5), c_torche.lerp(Color(1, 0.4, 0.2), 0.1))
	# Lumière rasante de chaque côté : fait ressortir le relief des figurines
	for cote in [-1.0, 1.0]:
		var r := OmniLight3D.new()
		r.light_color = c_torche.lerp(Color.WHITE, 0.35)
		r.light_energy = 1.1
		r.omni_range = 11.0
		r.position = Vector3(cote * 7.0, 2.2, 3.5)
		_monde.add_child(r)
	var devant := OmniLight3D.new()
	devant.light_color = Color(1.0, 0.85, 0.7)
	devant.light_energy = 0.55
	devant.omni_range = 14.0
	devant.position = Vector3(0, 5, 6)
	_monde.add_child(devant)
	_meteo(str(amb["meteo"]))

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.position = Vector3(0, 4.6, 13.2)
	_monde.add_child(_camera)
	_camera.look_at(Vector3(0, VISEE_DECOR if tex_sol else 1.0, 1.0))
	_cam_base = _camera.transform


func _torche(pos: Vector3, couleur: Color) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = couleur
	l.light_energy = 2.4
	l.omni_range = 10.0
	_monde.add_child(l)
	var tw := create_tween().set_loops()       # vacillement
	tw.tween_property(l, "light_energy", 1.9, 0.18 + randf() * 0.2)
	tw.tween_property(l, "light_energy", 2.6, 0.2 + randf() * 0.2)
	var b := _particules(couleur, 26, 2.2)
	b.position = pos
	b.direction = Vector3.UP
	b.spread = 22.0
	b.initial_velocity_min = 0.5
	b.initial_velocity_max = 1.4
	b.gravity = Vector3(0, 0.35, 0)
	b.emitting = true
	_monde.add_child(b)


# =====================================================================
# Météo de l'Acte
# =====================================================================

func _meteo(type: String) -> void:
	match type:
		"pluie", "orage":
			var p := _particules(Color(0.7, 0.78, 0.95, 0.55), 380, 0.9, 0.012)
			p.mesh = _goutte()
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(15, 0.2, 8)
			p.position = Vector3(0, 9, 1)
			p.direction = Vector3(0.12, -1, 0)
			p.spread = 2.0
			p.gravity = Vector3.ZERO
			p.initial_velocity_min = 13.0
			p.initial_velocity_max = 15.0
			p.scale_amount_curve = null
			p.emitting = true
			_monde.add_child(p)
			if type == "orage":
				_eclairs_lointains()
		"neige":
			var n := _boite_flottante(Color(0.95, 0.97, 1.0), 220, 7.0, 0.035)
			n.direction = Vector3(0.2, -1, 0)
			n.spread = 25.0
			n.initial_velocity_min = 0.6
			n.initial_velocity_max = 1.1
			n.gravity = Vector3(0.1, -0.15, 0)
			n.position = Vector3(0, 4.5, 1)
			n.emission_box_extents = Vector3(15, 3.5, 7)
			n.scale_amount_curve = null
		"lucioles", "spores":
			var c := Color(0.5, 1.0, 0.75) if type == "lucioles" else Color(0.75, 1.0, 0.45)
			var l := _boite_flottante(c, 60 if type == "lucioles" else 90, 6.0, 0.035 if type == "lucioles" else 0.025)
			l.direction = Vector3.UP
			l.spread = 180.0
			l.initial_velocity_min = 0.1
			l.initial_velocity_max = 0.4
			l.gravity = Vector3(0, 0.02, 0)
			l.position = Vector3(0, 1.6, 0)
			l.emission_box_extents = Vector3(13, 1.4, 5)
		"cendres", "cendres_rouges":
			var g := _boite_flottante(Color(0.55, 0.52, 0.5) if type == "cendres" else Color(0.75, 0.25, 0.22), 140, 7.0, 0.03)
			g.direction = Vector3(0.4, -1, 0)
			g.spread = 40.0
			g.initial_velocity_min = 0.3
			g.initial_velocity_max = 0.8
			g.gravity = Vector3(0.12, -0.1, 0)
			g.position = Vector3(0, 4.5, 1)
			g.emission_box_extents = Vector3(15, 3.5, 7)
			_braises(Color(1.0, 0.5, 0.25), 40)
		"bulles":
			var b := _boite_flottante(Color(0.55, 0.82, 1.0), 70, 6.0, 0.03)
			b.direction = Vector3.UP
			b.spread = 15.0
			b.initial_velocity_min = 0.3
			b.initial_velocity_max = 0.7
			b.gravity = Vector3(0, 0.05, 0)
			b.position = Vector3(0, 2.0, 0)
			b.emission_box_extents = Vector3(13, 2.0, 5)
		"plumes":
			var f := _boite_flottante(Color(1.0, 0.95, 0.8), 70, 9.0, 0.04)
			f.direction = Vector3(0.3, -1, 0)
			f.spread = 35.0
			f.initial_velocity_min = 0.2
			f.initial_velocity_max = 0.5
			f.gravity = Vector3(0.05, -0.06, 0)
			f.position = Vector3(0, 4.5, 1)
			f.emission_box_extents = Vector3(15, 3.5, 7)
			f.scale_amount_curve = null
			_braises(Color(1.0, 0.9, 0.6), 40)
		"poussiere_or", "poussiere_parchemin":
			var d := _boite_flottante(Color(1.0, 0.85, 0.55) if type == "poussiere_or" else Color(0.85, 0.78, 0.62), 90, 7.0, 0.022)
			d.direction = Vector3(1, 0.2, 0)
			d.spread = 60.0
			d.initial_velocity_min = 0.1
			d.initial_velocity_max = 0.3
			d.gravity = Vector3.ZERO
			d.position = Vector3(0, 1.8, 0)
			d.emission_box_extents = Vector3(13, 1.8, 5)
		"etincelles_or":
			_braises(Color(1.0, 0.75, 0.3), 90)
		"etincelles_violettes":
			_braises(Color(0.75, 0.45, 1.0), 90)
		_:
			_braises(Color(1.0, 0.6, 0.3), 70)


## Particules réparties dans un volume au-dessus du terrain.
func _boite_flottante(couleur: Color, nombre: int, vie: float, taille: float) -> CPUParticles3D:
	var p := _particules(couleur, nombre, vie, taille)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.preprocess = vie
	p.emitting = true
	_monde.add_child(p)
	return p


## Braises qui montent du sol.
func _braises(couleur: Color, nombre: int) -> void:
	var b := _particules(couleur, nombre, 6.0)
	b.position = Vector3(0, 0.3, 0)
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	b.emission_box_extents = Vector3(13, 0.2, 5)
	b.direction = Vector3.UP
	b.spread = 40.0
	b.initial_velocity_min = 0.15
	b.initial_velocity_max = 0.5
	b.gravity = Vector3(0.05, 0.08, 0)
	b.preprocess = 6.0
	b.emitting = true
	_monde.add_child(b)


func _goutte() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.012, 0.35, 0.012)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.82, 1.0, 0.35)
	m.material = mat
	return m


## Orage : de temps en temps, le ciel s'illumine (sans bouger la caméra).
func _eclairs_lointains() -> void:
	var l := DirectionalLight3D.new()
	l.light_color = Color(0.8, 0.75, 1.0)
	l.light_energy = 0.0
	l.rotation_degrees = Vector3(-30, -20, 0)
	_monde.add_child(l)
	var tw := create_tween().set_loops()
	tw.tween_interval(4.0 + randf() * 3.0)
	tw.tween_property(l, "light_energy", 1.6, 0.05)
	tw.tween_property(l, "light_energy", 0.2, 0.08)
	tw.tween_property(l, "light_energy", 1.2, 0.05)
	tw.tween_property(l, "light_energy", 0.0, 0.35)


func _particules(couleur: Color, nombre: int, vie: float, taille := 0.035) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = nombre
	p.lifetime = vie
	p.preprocess = vie
	var m := SphereMesh.new()
	m.radius = taille
	m.height = taille * 2.0
	m.radial_segments = 6
	m.rings = 3
	m.material = _mat_lueur(couleur)
	p.mesh = m
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 1))
	courbe.add_point(Vector2(1, 0))
	p.scale_amount_curve = courbe
	return p


func _mat_lueur(couleur: Color, force := 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	mat.emission_enabled = true
	mat.emission = couleur
	mat.emission_energy_multiplier = force
	mat.disable_fog = true
	if couleur.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


# =====================================================================
# Unités (pions)
# =====================================================================

## Position 3D (au sol) à partir de la position « écran » (fractions) utilisée en 2D.
## La profondeur vient de frac.y ; la position horizontale est calculée pour que les pieds tombent
## à un endroit précis de l'ÉCRAN (et non du monde) : ainsi la perspective ne pousse jamais une
## unité proche hors du cadre, et les rangs sont décalés en diagonale pour ne pas se cacher.
func position_sol(frac: Vector2) -> Vector3:
	var t := clampf((frac.y - 0.3) / 0.5, 0.0, 1.0)
	var z := lerpf(-4.2, 4.8, t)
	var cote := signf(frac.x - 0.5)
	return Vector3(_x_pour_ecran(0.5 + cote * absf(frac.x - 0.5), z), 0, z)


## Position au sol d'une figurine : comme position_sol, mais recalée pour qu'elle reste entière
## dans le cadre (on tient compte de sa largeur, avec une petite marge au bord de l'écran).
func _pos_unite(frac: Vector2, largeur: float) -> Vector3:
	var p := position_sol(frac)
	var mini := _x_pour_ecran(0.015, p.z) + largeur / 2.0
	var maxi := _x_pour_ecran(0.985, p.z) - largeur / 2.0
	if mini < maxi:
		p.x = clampf(p.x, mini, maxi)
	return p


## Abscisse au sol (à la profondeur z) qui apparaît à la fraction sx de la largeur de l'écran,
## vue depuis la position de repos de la caméra.
func _x_pour_ecran(sx: float, z: float) -> float:
	var vue := _cam_base.affine_inverse() * Vector3(0, 0, z)
	var profondeur := maxf(0.5, -vue.z)
	var t := size if size.x > 1.0 and size.y > 1.0 else Vector2(_vp.size)
	var aspect := t.x / t.y if t.x > 1.0 and t.y > 1.0 else 16.0 / 9.0
	var demi := tan(deg_to_rad(_camera.fov) / 2.0) * aspect * profondeur
	return (sx * 2.0 - 1.0) * demi - vue.x


func ajouter(idx: int, chemin_figurine: String, frac: Vector2, boss: bool, geant: bool, vers_gauche: bool, couleur_element: Color) -> void:
	var tex: Texture2D = load(chemin_figurine)
	var h := HAUTEUR_GEANT if geant else (HAUTEUR_BOSS if boss else HAUTEUR_UNITE)
	# Figurines très larges (quadrupèdes, poses étirées) : on limite leur largeur en réduisant la hauteur
	var ratio := float(tex.get_width()) / float(tex.get_height())
	if not geant:
		h = minf(h, h * LARGEUR_MAX / maxf(0.01, h * ratio))
	var largeur := h * ratio
	var pos := _pos_unite(frac, largeur)
	var rayon := clampf(largeur * 0.42, 0.55, 2.4 if geant else 1.15)

	# Le pion : socle + figurine, déplacé et basculé d'un bloc
	var pion := Node3D.new()
	pion.position = pos
	_monde.add_child(pion)

	var socle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = rayon
	cyl.bottom_radius = rayon * 1.07
	cyl.height = H_SOCLE
	cyl.radial_segments = 40
	cyl.rings = 1
	socle.mesh = cyl
	var mso := StandardMaterial3D.new()
	mso.albedo_color = Color(0.2, 0.17, 0.17)
	mso.metallic = 0.35
	mso.roughness = 0.5
	socle.material_override = mso
	socle.position.y = H_SOCLE / 2.0
	socle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pion.add_child(socle)
	# Liseré gravé de l'élément, sur le pourtour du socle
	var lisere := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = rayon * 0.985
	t.outer_radius = rayon * 1.05
	t.rings = 40
	t.ring_segments = 6
	lisere.mesh = t
	var ml := _mat_lueur(couleur_element, 1.6)
	lisere.material_override = ml
	lisere.scale = Vector3(1, 0.5, 1)
	lisere.position.y = H_SOCLE * 0.62
	lisere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pion.add_child(lisere)
	var tl := create_tween().set_loops()        # le liseré « respire »
	tl.tween_interval(randf())
	tl.tween_property(ml, "emission_energy_multiplier", 2.6, 1.4).set_trans(Tween.TRANS_SINE)
	tl.tween_property(ml, "emission_energy_multiplier", 1.2, 1.4).set_trans(Tween.TRANS_SINE)

	# La figurine peinte : un plan face à la caméra (la caméra ne tourne pas), éclairé en relief
	var fig := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(largeur, h)
	q.center_offset = Vector3(0, h / 2.0, 0)
	q.subdivide_depth = 10
	q.subdivide_width = 2
	fig.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_FIGURINE
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("texel", Vector2(1.0 / tex.get_width(), 1.0 / tex.get_height()))
	mat.set_shader_parameter("hauteur", h)
	mat.set_shader_parameter("retourne", 1.0 if vers_gauche else 0.0)
	mat.set_shader_parameter("phase", randf() * TAU)
	mat.set_shader_parameter("balance", 0.35 if geant else 1.0)
	mat.set_shader_parameter("couleur_lisere", couleur_element)
	fig.material_override = mat
	fig.position.y = H_SOCLE * 0.85
	fig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pion.add_child(fig)

	# Ombre douce au sol (reste au sol quand le pion saute)
	var ombre := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rayon * 1.35
	c.bottom_radius = rayon * 1.35
	c.height = 0.01
	c.radial_segments = 24
	ombre.mesh = c
	var mo := StandardMaterial3D.new()
	mo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mo.albedo_color = Color(0, 0, 0, 0.4)
	ombre.material_override = mo
	ombre.position = pos + Vector3(0, 0.006, 0)
	_monde.add_child(ombre)

	_unites[idx] = {"pion": pion, "fig": fig, "mat": mat, "socle": socle, "lisere": lisere, "ombre": ombre,
		"pos": pos, "hauteur": h, "frac": frac, "largeur": largeur, "rayon": rayon, "boss": boss or geant,
		"gauche": vers_gauche, "ko": false}
	_poser(idx)


## Arrivée sur le plateau : le pion tombe et se pose (le boss, plus lourd, soulève la poussière).
func _poser(idx: int) -> void:
	var u: Dictionary = _unites[idx]
	var pion: Node3D = u["pion"]
	var pos: Vector3 = u["pos"]
	var lourd: bool = u["boss"]
	var delai := 0.05 * _n_poses + (0.35 if lourd else 0.0)
	_n_poses += 1
	pion.position = pos + Vector3(0, 6.0 if lourd else 3.5, 0)
	pion.visible = false
	var tw := create_tween()
	tw.tween_interval(delai)
	tw.tween_callback(func(): pion.visible = true)
	tw.tween_property(pion, "position", pos, 0.34 if lourd else 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_ecraser(idx, 0.16 if lourd else 0.1, 0.22)
		_poussiere(pos, u["rayon"] * (1.8 if lourd else 1.1), 30 if lourd else 12)
		if lourd:
			_eclair_lumiere(pos + Vector3(0, 1.0, 0.8), Color(1.0, 0.45, 0.25), 6.0, 0.6)
			_moment_fort(pos + Vector3(0, u["hauteur"] * 0.5, 0), 0.0))


func a(idx: int) -> bool:
	return _unites.has(idx)


## Où apparaît une unité à l'écran : pieds et sommet de la tête (en pixels, dans ce conteneur).
func ecran(idx: int) -> Dictionary:
	var u: Dictionary = _unites[idx]
	var pieds: Vector3 = Vector3(u["pos"]) + Vector3(0, H_SOCLE, 0)
	var tete: Vector3 = pieds + Vector3(0, u["hauteur"], 0)
	return {"pieds": _camera.unproject_position(pieds) * _echelle(), "tete": _camera.unproject_position(tete) * _echelle()}


## Position à l'écran d'un point quelconque du sol (pour les unités sans figurine).
func ecran_sol(frac: Vector2) -> Vector2:
	return _camera.unproject_position(position_sol(frac)) * _echelle()


func _echelle() -> Vector2:
	var t := Vector2(_vp.size)
	return Vector2(size.x / maxf(1.0, t.x), size.y / maxf(1.0, t.y))


func _centre(idx: int) -> Vector3:
	var u: Dictionary = _unites[idx]
	return Vector3(u["pos"]) + Vector3(0, H_SOCLE + float(u["hauteur"]) * 0.5, 0.15)


# =====================================================================
# Animations des pions
# =====================================================================

## Tasse puis détend la figurine (élastique).
func _ecraser(idx: int, force: float, duree: float) -> void:
	var mat: ShaderMaterial = _unites[idx]["mat"]
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("ecrase", v), force, -force * 0.4, duree * 0.45 / vitesse).set_trans(Tween.TRANS_SINE)
	tw.tween_method(func(v: float): mat.set_shader_parameter("ecrase", v), -force * 0.4, 0.0, duree * 0.55 / vitesse).set_trans(Tween.TRANS_SINE)


func _pencher(idx: int, valeur: float, duree: float) -> void:
	var mat: ShaderMaterial = _unites[idx]["mat"]
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("penche", v), 0.0, valeur, duree * 0.3 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): mat.set_shader_parameter("penche", v), valeur, 0.0, duree * 0.7 / vitesse).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _eclat(idx: int, couleur: Color, duree: float) -> void:
	var mat: ShaderMaterial = _unites[idx]["mat"]
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("eclat", Color(couleur, v * couleur.a)), 1.0, 0.0, duree / vitesse)


## Attaque : le pion se ramasse, glisse vers sa cible en se penchant, frappe et revient.
func elan(att: int, cible: int, duree_aller: float, duree_retour: float, geant := false) -> void:
	if not a(att):
		return
	var u: Dictionary = _unites[att]
	var pion: Node3D = u["pion"]
	var depart: Vector3 = u["pos"]
	var arrivee: Vector3 = _unites[cible]["pos"] if a(cible) else depart
	var vers: Vector3 = depart.lerp(arrivee, 0.06 if geant else 0.42)
	var sens := signf(arrivee.x - depart.x)
	if sens == 0.0:
		sens = -1.0 if u["gauche"] else 1.0
	_ecraser(att, 0.08, duree_aller + duree_retour)
	_pencher(att, sens * 0.35, duree_aller + duree_retour + 0.15)
	var tw := create_tween()
	tw.tween_property(pion, "position", vers + Vector3(0, 0.18, 0), duree_aller).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(pion, "rotation:z", -sens * 0.12, duree_aller)
	tw.tween_property(pion, "position", depart, duree_retour).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(pion, "rotation:z", 0.0, duree_retour)
	tw.tween_callback(func(): _poussiere(depart, u["rayon"], 6))


## Coup reçu : éclair rouge, le pion est repoussé et vacille sur son socle, étincelles.
func touche(idx: int, critique: bool) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var pion: Node3D = u["pion"]
	_eclat(idx, Color(1.0, 0.85, 0.75) if critique else Color(1.0, 0.35, 0.25), 0.3)
	var recul := 1.0 if u["gauche"] else -1.0          # recule vers son propre camp
	var force := 0.45 if critique else 0.25
	_pencher(idx, recul * force, 0.55)
	if not u["ko"]:
		var tr := create_tween()
		tr.tween_property(pion, "position:x", u["pos"].x + recul * force * 0.6, 0.05 / vitesse)
		tr.parallel().tween_property(pion, "rotation:z", -recul * force * 0.35, 0.05 / vitesse)
		tr.tween_property(pion, "position:x", u["pos"].x, 0.22 / vitesse).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tr.parallel().tween_property(pion, "rotation:z", 0.0, 0.3 / vitesse).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_eclats(_centre(idx) + Vector3(0, 0.1, 0.2), Color(1.0, 0.85, 0.4) if critique else Color(1.0, 0.45, 0.3), 28 if critique else 14)
	if critique:
		_eclair_lumiere(_centre(idx) + Vector3(0, 0, 0.8), Color(1.0, 0.8, 0.5), 4.0, 0.25)


func soin(idx: int) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var p := _particules(Color(0.5, 1.0, 0.6), 24, 0.9, 0.05)
	p.one_shot = true
	p.preprocess = 0.0
	p.explosiveness = 0.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.direction = Vector3.UP
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0
	p.gravity = Vector3.ZERO
	p.position = u["pos"] + Vector3(0, 0.6, 0)
	p.emitting = true
	_monde.add_child(p)
	_eclat(idx, Color(0.55, 1.0, 0.6), 0.5)
	_anneau_sol(u["pos"], Color(0.45, 1.0, 0.55), u["rayon"] * 1.6, 0.6)
	_jeter(p, 1.5)


## SORT : le lanceur s'élève un instant dans une lueur de son élément, puis l'effet part selon
## l'élément et la forme du sort (une cible ennemie, plusieurs, ou des alliés).
func sort(idx: int, couleur: Color, element := "neutre", cibles: Array = []) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var pion: Node3D = u["pion"]
	var tw := create_tween()
	tw.tween_property(pion, "position:y", 0.35, 0.14 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pion, "position:y", 0.0, 0.2 / vitesse).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_ecraser(idx, -0.08, 0.35)
	_eclat(idx, Color(couleur, 0.6), 0.5)
	_eclair_lumiere(_centre(idx) + Vector3(0, 0, 0.9), couleur, 5.0, 0.5)
	_anneau_sol(u["pos"], couleur, u["rayon"] * 1.5, 0.5)
	# Cibles qui ont une figurine
	var ennemis: Array = []
	var allies: Array = []
	for c in cibles:
		var ci := int(c)
		if not a(ci):
			continue
		if bool(_unites[ci]["gauche"]) == bool(u["gauche"]):
			allies.append(ci)
		else:
			ennemis.append(ci)
	if ennemis.size() == 1:
		_projectile(idx, ennemis[0], couleur, element)
	elif ennemis.size() > 1:
		for k in ennemis.size():
			_zone(ennemis[k], couleur, element, 0.06 * k / vitesse)
	for k in allies.size():
		_aura(allies[k], couleur, 0.05 * k / vitesse)


## K.O. : le pion bascule sur le bord de son socle et tombe à plat, comme une pièce renversée.
func ko(idx: int) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	u["ko"] = true
	var cote := 1.0 if u["gauche"] else -1.0
	var mat: ShaderMaterial = u["mat"]
	var tw := create_tween()
	tw.tween_method(func(v: float): _basculer(idx, cote * v), 0.0, 1.0, 0.45 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(func(v: float): _basculer(idx, cote * v), 1.0, 0.9, 0.08 / vitesse)
	tw.tween_method(func(v: float): _basculer(idx, cote * v), 0.9, 1.0, 0.1 / vitesse)
	var tm := create_tween().set_parallel(true)
	tm.tween_method(func(v: float): mat.set_shader_parameter("sombre", v), 0.0, 1.0, 0.5 / vitesse)
	tm.tween_property(u["lisere"], "scale", Vector3(0.01, 0.01, 0.01), 0.5 / vitesse)
	get_tree().create_timer(0.45 / vitesse).timeout.connect(func():
		var bord := Vector3(u["pos"]) + Vector3(cote * (float(u["rayon"]) + float(u["hauteur"]) * 0.5), 0, 0)
		_poussiere(bord, u["rayon"] * 1.4, 18))
	if u["boss"] or _camp_vaincu(bool(u["gauche"])):
		_moment_fort(_centre(idx), 0.5)


func _camp_vaincu(gauche: bool) -> bool:
	for i in _unites:
		var v: Dictionary = _unites[i]
		if bool(v["gauche"]) == gauche and not v["ko"]:
			return false
	return true


## Bascule de la figurine (v : -1..1, 0 = debout, ±1 = couchée) : elle tombe de son socle par le bord
## extérieur (vers l'arrière de son camp) et s'étend au sol ; le socle reste en place, éteint.
func _basculer(idx: int, v: float) -> void:
	var u: Dictionary = _unites[idx]
	var fig: Node3D = u["fig"]
	var cote := signf(v) if v != 0.0 else 1.0
	var angle := absf(v) * 1.5
	var pivot := Vector3(cote * float(u["rayon"]) * 0.8, H_SOCLE * 0.85, 0)
	var b := Basis(Vector3(0, 0, 1), -cote * angle)
	var base := Vector3(0, H_SOCLE * 0.85, 0)
	# en tombant, la figurine glisse du socle jusqu'au sol
	var descente := Vector3(0, -H_SOCLE * 0.85 * absf(v), 0)
	fig.transform = Transform3D(b, pivot + b * (base - pivot) + descente)


func revivre(idx: int) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	u["ko"] = false
	var pion: Node3D = u["pion"]
	pion.transform = Transform3D(Basis(), u["pos"])
	(u["fig"] as Node3D).transform = Transform3D(Basis(), Vector3(0, H_SOCLE * 0.85, 0))
	var mat: ShaderMaterial = u["mat"]
	mat.set_shader_parameter("sombre", 0.0)
	u["lisere"].scale = Vector3(1, 0.5, 1)
	_ecraser(idx, 0.12, 0.3)
	soin(idx)


func trembler(_force: float) -> void:
	pass       # caméra fixe : jamais de tremblement (mal de mer, v0.63)


## Mise à jour immédiate (mode « Passer »).
func etat_ko(idx: int, oui: bool) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	if oui:
		u["ko"] = true
		_basculer(idx, 1.0 if u["gauche"] else -1.0)
		(u["mat"] as ShaderMaterial).set_shader_parameter("sombre", 1.0)
		u["lisere"].scale = Vector3(0.01, 0.01, 0.01)
	else:
		revivre(idx)


# =====================================================================
# Effets des sorts (par élément)
# =====================================================================

## Une seule cible ennemie : un projectile part du lanceur vers la cible.
##   feu : boule de feu  ·  eau : éclat de glace  ·  nature : spirale d'épines
##   ténèbres : orbe d'ombre ondulante  ·  sacré : rayon du ciel  ·  neutre : onde tranchante
func _projectile(de: int, vers: int, couleur: Color, element: String) -> void:
	var a3 := _centre(de) + Vector3(0, 0.2, 0.3)
	var b3 := _centre(vers) + Vector3(0, 0, 0.3)
	var duree := 0.32 / vitesse
	if element == "sacre":
		_faisceau_ciel(vers, couleur, 0.12 / vitesse)
		return
	var noeud := Node3D.new()
	noeud.position = a3
	_monde.add_child(noeud)
	var coeur := MeshInstance3D.new()
	match element:
		"eau":
			var pr := PrismMesh.new()
			pr.size = Vector3(0.18, 0.7, 0.18)
			coeur.mesh = pr
			coeur.material_override = _mat_lueur(couleur.lightened(0.4), 2.5)
			coeur.rotation.z = -signf(b3.x - a3.x) * PI * 0.5
		_:
			var sp := SphereMesh.new()
			sp.radius = 0.22 if element != "tenebres" else 0.3
			sp.height = sp.radius * 2.0
			coeur.mesh = sp
			coeur.material_override = _mat_lueur(couleur.lightened(0.3) if element != "tenebres" else Color(0.25, 0.08, 0.35), 3.0)
	noeud.add_child(coeur)
	var lum := OmniLight3D.new()
	lum.light_color = couleur
	lum.light_energy = 3.0
	lum.omni_range = 4.0
	noeud.add_child(lum)
	var trainee := _particules(couleur, 40, 0.35, 0.06)
	trainee.local_coords = false
	trainee.direction = Vector3.UP
	trainee.spread = 180.0
	trainee.initial_velocity_min = 0.2
	trainee.initial_velocity_max = 0.8 if element != "nature" else 2.0
	trainee.gravity = Vector3(0, 0.5 if element == "feu" else 0.0, 0)
	trainee.emitting = true
	noeud.add_child(trainee)
	var haut := 1.2 if element == "feu" else (0.3 if element == "eau" else 0.7)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var p := a3.lerp(b3, t) + Vector3(0, sin(t * PI) * haut, 0)
		if element == "tenebres":
			p += Vector3(0, sin(t * 18.0) * 0.18, cos(t * 14.0) * 0.18)
		elif element == "nature":
			p += Vector3(0, sin(t * 22.0) * 0.25, cos(t * 22.0) * 0.25)
		noeud.position = p, 0.0, 1.0, duree).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		coeur.visible = false
		trainee.emitting = false
		_impact(b3, couleur, element)
		_jeter(noeud, 0.6))


## Impact d'un projectile.
func _impact(pos: Vector3, couleur: Color, element: String) -> void:
	_eclair_lumiere(pos, couleur, 6.0, 0.35)
	match element:
		"feu":
			_eclats(pos, Color(1.0, 0.55, 0.15), 40)
			_eclats(pos, Color(1.0, 0.85, 0.4), 16)
			_fumee(pos, 10)
		"eau":
			_eclats(pos, Color(0.7, 0.9, 1.0), 30)
			_anneau_sol(Vector3(pos.x, 0, pos.z - 0.15), Color(0.55, 0.85, 1.0), 1.6, 0.4)
		"tenebres":
			_eclats(pos, Color(0.6, 0.3, 0.9), 26)
			_volutes(Vector3(pos.x, 0, pos.z - 0.2), Color(0.45, 0.2, 0.7), 18)
		"nature":
			_eclats(pos, Color(0.55, 1.0, 0.4), 30)
		_:
			_eclats(pos, couleur.lightened(0.3), 26)
			_anneau_sol(Vector3(pos.x, 0, pos.z - 0.15), couleur, 1.4, 0.35)


## Plusieurs cibles : l'effet frappe chaque cible sur place.
##   feu : colonne de flammes  ·  eau : pics de glace  ·  nature : ronces qui jaillissent
##   ténèbres : flaque d'ombre et volutes  ·  sacré : piliers de lumière  ·  neutre : onde de choc
func _zone(idx: int, couleur: Color, element: String, delai: float) -> void:
	if delai > 0.0:
		await get_tree().create_timer(delai).timeout
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var pos: Vector3 = u["pos"]
	match element:
		"sacre":
			_faisceau_ciel(idx, couleur, 0.0)
		"feu":
			var f := _particules(Color(1.0, 0.5, 0.15), 60, 0.55, 0.09)
			f.one_shot = true
			f.preprocess = 0.0
			f.explosiveness = 0.5
			f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			f.emission_sphere_radius = float(u["rayon"]) * 0.7
			f.direction = Vector3.UP
			f.spread = 12.0
			f.initial_velocity_min = 4.0
			f.initial_velocity_max = 7.0
			f.gravity = Vector3(0, -2, 0)
			f.position = pos + Vector3(0, 0.1, 0.1)
			f.emitting = true
			_monde.add_child(f)
			_jeter(f, 1.2)
			_eclair_lumiere(pos + Vector3(0, 1.2, 0.6), Color(1.0, 0.5, 0.2), 6.0, 0.5)
			_fumee(pos + Vector3(0, 1.5, 0), 8)
		"eau", "nature":
			var c := Color(0.65, 0.9, 1.0, 0.9) if element == "eau" else Color(0.3, 0.55, 0.2)
			for k in 5:
				var ang := TAU * k / 5.0 + randf() * 0.5
				var p := pos + Vector3(cos(ang), 0, sin(ang) * 0.6) * float(u["rayon"]) * 1.05
				_pic(p, c, 0.9 + randf() * 0.6, element == "eau")
			_eclats(pos + Vector3(0, 0.5, 0.3), Color(0.7, 0.95, 1.0) if element == "eau" else Color(0.5, 1.0, 0.35), 20)
			_eclair_lumiere(pos + Vector3(0, 1.0, 0.6), couleur, 4.0, 0.4)
		"tenebres":
			_flaque(pos, Color(0.12, 0.03, 0.18, 0.8), float(u["rayon"]) * 1.4)
			_volutes(pos, Color(0.55, 0.25, 0.85), 24)
			_eclair_lumiere(pos + Vector3(0, 1.0, 0.6), Color(0.6, 0.3, 1.0), 2.2, 0.5)
		_:
			_anneau_sol(pos, couleur.lightened(0.3), float(u["rayon"]) * 2.4, 0.4)
			_eclats(pos + Vector3(0, 0.4, 0.3), couleur.lightened(0.3), 20)
			_eclair_lumiere(pos + Vector3(0, 1.0, 0.6), couleur, 4.0, 0.3)


## Sort sur des alliés : colonne de lumière douce de l'élément et anneaux qui montent.
func _aura(idx: int, couleur: Color, delai: float) -> void:
	if delai > 0.0:
		await get_tree().create_timer(delai).timeout
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var pos: Vector3 = u["pos"]
	for k in 3:
		var anneau := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = float(u["rayon"]) * 1.0
		t.outer_radius = float(u["rayon"]) * 1.08
		t.rings = 32
		t.ring_segments = 4
		anneau.mesh = t
		var m := _mat_lueur(Color(couleur.lightened(0.25), 0.9), 2.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		anneau.material_override = m
		anneau.position = pos + Vector3(0, 0.1, 0)
		anneau.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_monde.add_child(anneau)
		var tw := create_tween()
		tw.tween_interval(k * 0.12 / vitesse)
		tw.tween_property(anneau, "position:y", float(u["hauteur"]) * 0.9, 0.6 / vitesse).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.6 / vitesse)
		tw.parallel().tween_property(anneau, "scale", Vector3(0.6, 1, 0.6), 0.6 / vitesse)
		tw.tween_callback(anneau.queue_free)
	_eclat(idx, Color(couleur, 0.45), 0.6)
	var g := _particules(couleur.lightened(0.3), 20, 0.9, 0.04)
	g.one_shot = true
	g.preprocess = 0.0
	g.explosiveness = 0.3
	g.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	g.emission_sphere_radius = float(u["rayon"])
	g.direction = Vector3.UP
	g.initial_velocity_min = 1.2
	g.initial_velocity_max = 2.4
	g.gravity = Vector3.ZERO
	g.position = pos + Vector3(0, 0.2, 0)
	g.emitting = true
	_monde.add_child(g)
	_jeter(g, 1.4)


## Rayon de lumière qui tombe du ciel sur une unité.
func _faisceau_ciel(idx: int, couleur: Color, delai: float) -> void:
	if delai > 0.0:
		await get_tree().create_timer(delai).timeout
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var pos: Vector3 = u["pos"]
	var col := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = float(u["rayon"]) * 0.75
	cy.bottom_radius = float(u["rayon"]) * 0.55
	cy.height = 14.0
	cy.radial_segments = 20
	cy.cap_top = false
	cy.cap_bottom = false
	col.mesh = cy
	var m := _mat_lueur(Color(couleur.lightened(0.45), 0.55), 3.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	col.material_override = m
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	col.position = pos + Vector3(0, 7.0, 0)
	col.scale = Vector3(0.05, 1, 0.05)
	_monde.add_child(col)
	var tw := create_tween()
	tw.tween_property(col, "scale", Vector3(1, 1, 1), 0.1 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.15 / vitesse)
	tw.tween_property(col, "scale", Vector3(0.02, 1, 0.02), 0.3 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(col.queue_free)
	_eclair_lumiere(pos + Vector3(0, 1.5, 0.6), couleur.lightened(0.3), 8.0, 0.5)
	_anneau_sol(pos, couleur.lightened(0.3), float(u["rayon"]) * 2.0, 0.45)
	_eclats(pos + Vector3(0, 0.3, 0.3), couleur.lightened(0.4), 24)


## Pic de glace ou ronce qui jaillit du sol puis se retire.
func _pic(pos: Vector3, couleur: Color, hauteur: float, glace: bool) -> void:
	var pic := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = 0.16 if glace else 0.1
	c.height = hauteur
	c.radial_segments = 5 if glace else 6
	pic.mesh = c
	var m := StandardMaterial3D.new()
	m.albedo_color = couleur
	m.roughness = 0.15 if glace else 0.8
	m.metallic = 0.2 if glace else 0.0
	if glace:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(0.4, 0.7, 1.0)
		m.emission_energy_multiplier = 0.6
	pic.material_override = m
	pic.position = pos + Vector3(0, -hauteur / 2.0, 0)
	pic.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
	_monde.add_child(pic)
	var tw := create_tween()
	tw.tween_property(pic, "position:y", hauteur * 0.45, 0.1 / vitesse).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35 / vitesse)
	tw.tween_property(pic, "position:y", -hauteur / 2.0, 0.25 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(pic.queue_free)


## Flaque d'ombre qui s'étend au sol puis s'efface.
func _flaque(pos: Vector3, couleur: Color, rayon: float) -> void:
	var f := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rayon
	c.bottom_radius = rayon
	c.height = 0.01
	c.radial_segments = 28
	f.mesh = c
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = couleur
	f.material_override = m
	f.position = pos + Vector3(0, 0.012, 0)
	f.scale = Vector3(0.05, 1, 0.05)
	_monde.add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "scale", Vector3.ONE, 0.18 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35 / vitesse)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.4 / vitesse)
	tw.tween_callback(f.queue_free)


## Volutes d'ombre qui montent en spirale.
func _volutes(pos: Vector3, couleur: Color, nombre: int) -> void:
	var v := _particules(couleur, nombre, 0.9, 0.07)
	v.one_shot = true
	v.preprocess = 0.0
	v.explosiveness = 0.4
	v.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	v.emission_ring_axis = Vector3.UP
	v.emission_ring_radius = 0.7
	v.emission_ring_inner_radius = 0.3
	v.emission_ring_height = 0.1
	v.direction = Vector3.UP
	v.spread = 10.0
	v.initial_velocity_min = 1.0
	v.initial_velocity_max = 2.2
	v.orbit_velocity_min = 0.6
	v.orbit_velocity_max = 1.0
	v.gravity = Vector3.ZERO
	v.position = pos + Vector3(0, 0.1, 0)
	v.emitting = true
	_monde.add_child(v)
	_jeter(v, 1.4)


func _fumee(pos: Vector3, nombre: int) -> void:
	var f := CPUParticles3D.new()
	f.amount = nombre
	f.lifetime = 1.2
	f.one_shot = true
	f.explosiveness = 0.7
	var sp := SphereMesh.new()
	sp.radius = 0.35
	sp.height = 0.7
	sp.radial_segments = 8
	sp.rings = 4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.12, 0.1, 0.1, 0.35)
	m.vertex_color_use_as_albedo = true
	sp.material = m
	f.mesh = sp
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(1, 1, 1, 0))
	f.color_ramp = grad
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 0.5))
	courbe.add_point(Vector2(1, 1.6))
	f.scale_amount_curve = courbe
	f.direction = Vector3.UP
	f.spread = 50.0
	f.initial_velocity_min = 0.5
	f.initial_velocity_max = 1.2
	f.gravity = Vector3(0, 0.4, 0)
	f.position = pos
	f.emitting = true
	_monde.add_child(f)
	_jeter(f, 1.6)


## Nuage de poussière au sol (pion qui se pose, qui tombe…).
func _poussiere(pos: Vector3, rayon: float, nombre: int) -> void:
	var p := CPUParticles3D.new()
	p.amount = maxi(4, nombre)
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.95
	var sp := SphereMesh.new()
	sp.radius = 0.12
	sp.height = 0.24
	sp.radial_segments = 6
	sp.rings = 3
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.45, 0.38, 0.33, 0.45)
	sp.material = m
	p.mesh = sp
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 1))
	courbe.add_point(Vector2(1, 0))
	p.scale_amount_curve = courbe
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = rayon
	p.emission_ring_inner_radius = rayon * 0.8
	p.emission_ring_height = 0.05
	p.direction = Vector3(0, 0.3, 0)
	p.spread = 180.0
	p.flatness = 0.8
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.8
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.gravity = Vector3.ZERO
	p.position = pos + Vector3(0, 0.08, 0)
	p.emitting = true
	_monde.add_child(p)
	_jeter(p, 1.0)


## Anneau lumineux qui s'élargit au sol.
func _anneau_sol(pos: Vector3, couleur: Color, rayon: float, duree: float) -> void:
	var a3 := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.0
	t.rings = 40
	t.ring_segments = 4
	a3.mesh = t
	var m := _mat_lueur(Color(couleur, 0.9), 3.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	a3.material_override = m
	a3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	a3.position = pos + Vector3(0, 0.03, 0)
	a3.scale = Vector3(0.2, 0.05, 0.2)
	_monde.add_child(a3)
	var tw := create_tween()
	tw.tween_property(a3, "scale", Vector3(rayon, 0.05, rayon), duree / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, duree / vitesse)
	tw.tween_callback(a3.queue_free)


## Lumière brève (éclaire les figurines alentour en relief).
func _eclair_lumiere(pos: Vector3, couleur: Color, energie: float, duree: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.light_energy = 0.0
	l.omni_range = 6.0
	l.position = pos
	_monde.add_child(l)
	var tl := create_tween()
	tl.tween_property(l, "light_energy", energie, 0.06 / vitesse)
	tl.tween_property(l, "light_energy", 0.0, duree / vitesse)
	tl.tween_callback(l.queue_free)


func _eclats(pos: Vector3, couleur: Color, nombre: int, anneau := false) -> void:
	var p := _particules(couleur, nombre, 0.5, 0.045)
	p.one_shot = true
	p.preprocess = 0.0
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 2.0 if not anneau else 3.0
	p.initial_velocity_max = 4.5 if not anneau else 5.0
	p.gravity = Vector3(0, -6, 0)
	p.position = pos
	p.emitting = true
	_monde.add_child(p)
	_jeter(p, 1.0)


func _jeter(n: Node, apres: float) -> void:
	get_tree().create_timer(apres).timeout.connect(func():
		if is_instance_valid(n):
			n.queue_free())


# =====================================================================
# Caméra cinéma (option)
# =====================================================================

## Moment fort (arrivée d'un boss, coup fatal) : la caméra se rapproche doucement de l'action,
## avec un ralenti si « ralenti » > 0. Sans l'option « Caméra cinéma », rien ne se passe.
## Jamais de tremblement ni de mouvement brusque.
func _moment_fort(cible: Vector3, ralenti: float) -> void:
	if not camera_cinema or _camera == null:
		return
	var depart := _cam_base
	var vers := depart
	vers.origin = depart.origin.lerp(cible + Vector3(0, 1.2, 4.5), 0.15)
	if _tw_cam:
		_tw_cam.kill()
	_tw_cam = create_tween()
	_tw_cam.set_ignore_time_scale(true)
	_tw_cam.tween_property(_camera, "transform", vers, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tw_cam.tween_interval(0.5)
	_tw_cam.tween_property(_camera, "transform", depart, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if ralenti > 0.0:
		Engine.time_scale = 0.35
		get_tree().create_timer(ralenti, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
