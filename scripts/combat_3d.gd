class_name Combat3D
extends SubViewportContainer
## COMBATS EN 2,5D : le champ de bataille est une scène 3D (sol, décor, lumières, ombres, braises,
## caméra vivante) où les figurines peintes du jeu se tiennent debout, toujours tournées vers la caméra.
## Les règles ne changent pas : EcranCombat rejoue le même journal, et appelle ces fonctions pour animer.
## Les noms, barres de vie et textes flottants restent en 2D, placés au-dessus des figurines.
##
## Le décor peint (fond du combat) est coupé en deux : le haut (65 %) est dressé au fond comme une toile,
## le bas (35 %) devient le SOL et s'étend jusqu'à la caméra. Les deux se raccordent sans couture.

const LARGEUR := 32.0           # largeur du décor (unités 3D)
const COUPE := 0.65             # part du décor dressée au fond ; le reste devient le sol
const Z_FOND := -6.0
const Z_PRES := 9.0
const LARGEUR_DECOR := 27.0     # largeur de la toile de fond d'un décor 3D (cadre + balancement)
const TASSEMENT_DECOR := 0.85   # hauteur de la toile de fond d'un décor 3D (1 = proportions exactes)
const VISEE_DECOR := 1.8        # la caméra vise un peu plus haut avec un décor 3D (plus de ciel)
const TUILE_SOL := 6.0          # taille (en mètres) d'une répétition de la texture de sol
const HAUTEUR_UNITE := 2.3
const HAUTEUR_BOSS := 3.0
const HAUTEUR_GEANT := 7.5

var _vp: SubViewport
var _monde: Node3D
var _camera: Camera3D
var _cam_base := Transform3D()
var _unites := {}               # idx -> {sprite, ombre, pos, hauteur, camp, base_scale}
var _tw_cam: Tween
var vitesse := 1.0


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


## L'écran change de forme (rotation du téléphone, fenêtre) : on recale les unités dans le cadre.
func _replacer() -> void:
	if _camera == null:
		return
	for idx in _unites:
		var u: Dictionary = _unites[idx]
		var p := position_sol(u["frac"])
		var dx := p.x - Vector3(u["pos"]).x
		if absf(dx) < 0.001:
			continue
		u["pos"] = p
		for cle in ["sprite", "ombre", "anneau"]:
			var n: Node3D = u[cle]
			n.position.x += dx


## Construit le décor à partir de l'image de fond du combat.
## Avec chemin_sol (texture de sol raccordable, vue du dessus) : l'image de fond est entièrement dressée
## au fond (coupée à « coupe », là où commence son sol peint) et le sol 3D est carrelé avec la texture.
func construire(chemin_fond: String, teinte_nuit: Color, chemin_sol := "", coupe := COUPE) -> void:
	var tex: Texture2D = load(chemin_fond) if chemin_fond != "" and ResourceLoader.exists(chemin_fond) else null
	var tex_sol: Texture2D = load(chemin_sol) if chemin_sol != "" and ResourceLoader.exists(chemin_sol) else null
	if tex_sol == null:
		coupe = COUPE
	var ratio := 9.0 / 16.0
	if tex:
		ratio = float(tex.get_height()) / float(tex.get_width())
	var h_image := LARGEUR * ratio

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = teinte_nuit
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.56, 0.6)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
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
		ms.albedo_color = Color(0.95, 0.88, 0.85)
	elif tex:
		ms.albedo_texture = tex
		ms.uv1_scale = Vector3(1, 1.0 - COUPE, 1)
		ms.uv1_offset = Vector3(0, COUPE, 0)
	else:
		ms.albedo_color = Color(0.25, 0.2, 0.2)
	sol.material_override = ms
	sol.position = Vector3(0, 0, (Z_FOND + Z_PRES) / 2.0)
	_monde.add_child(sol)

	# Lumières : lune (ombres), torches chaudes de chaque côté, lueur devant
	var lune := DirectionalLight3D.new()
	lune.light_color = Color(0.85, 0.8, 1.0)
	lune.light_energy = 0.55
	lune.shadow_enabled = true
	lune.shadow_opacity = 0.75
	lune.rotation_degrees = Vector3(-52, 25, 0)
	_monde.add_child(lune)
	_torche(Vector3(-9.5, 1.4, -2.5), Color(1.0, 0.55, 0.25))
	_torche(Vector3(9.5, 1.4, -2.5), Color(1.0, 0.5, 0.25))
	var devant := OmniLight3D.new()
	devant.light_color = Color(1.0, 0.85, 0.7)
	devant.light_energy = 0.8
	devant.omni_range = 14.0
	devant.position = Vector3(0, 5, 6)
	_monde.add_child(devant)
	_poussieres()

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.position = Vector3(0, 4.6, 13.2)
	_monde.add_child(_camera)
	_camera.look_at(Vector3(0, VISEE_DECOR if tex_sol else 1.0, 1.0))
	_cam_base = _camera.transform
	# Lent mouvement de caméra « vivant »
	var tw := create_tween().set_loops()
	tw.tween_property(_camera, "position:x", 0.45, 7.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_camera, "position:x", -0.45, 7.0).set_trans(Tween.TRANS_SINE)


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


## Braises et poussières qui flottent sur tout le champ de bataille.
func _poussieres() -> void:
	var b := _particules(Color(1.0, 0.6, 0.3), 70, 6.0)
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
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = couleur
	mat.emission_enabled = true
	mat.emission = couleur
	mat.emission_energy_multiplier = 2.0
	m.material = mat
	p.mesh = m
	var courbe := Curve.new()
	courbe.add_point(Vector2(0, 1))
	courbe.add_point(Vector2(1, 0))
	p.scale_amount_curve = courbe
	return p


# =====================================================================
# Unités
# =====================================================================

## Position 3D (au sol) à partir de la position « écran » (fractions) utilisée en 2D.
## La profondeur vient de frac.y ; la position horizontale est calculée pour que les pieds tombent
## à un endroit précis de l'ÉCRAN (et non du monde) : ainsi la perspective ne pousse jamais une
## unité proche hors du cadre, et les rangs sont décalés en diagonale pour ne pas se cacher.
func position_sol(frac: Vector2) -> Vector3:
	var t := clampf((frac.y - 0.3) / 0.5, 0.0, 1.0)
	var z := lerpf(-2.6, 4.6, t)
	var cote := signf(frac.x - 0.5)
	return Vector3(_x_pour_ecran(0.5 + cote * _ecart_centre(frac), z), 0, z)


## Formation en quinconce (distance au centre de l'écran, en fraction de largeur) : une unité
## n'est jamais juste derrière une autre de profondeur voisine, même si celle de devant est un boss.
func _ecart_centre(frac: Vector2) -> float:
	var dx := absf(frac.x - 0.5)
	if dx < 0.2:                       # Avant : fond près du centre, devant un peu en retrait
		return 0.07 if frac.y < 0.5 else 0.18
	if dx < 0.3:                       # unité invitée, entre les deux rangs
		return 0.25
	if frac.y < 0.45:                  # Arrière, du fond vers le devant
		return 0.27
	if frac.y < 0.7:
		return 0.41
	return 0.30


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
	var pos := position_sol(frac)
	var s := Sprite3D.new()
	s.texture = tex
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	# Bords adoucis (pré-passe opaque : contours lissés, ombres conservées) et filtrage avec mipmaps
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	s.shaded = true
	s.flip_h = vers_gauche
	s.pixel_size = h / float(tex.get_height())
	s.centered = true
	s.offset = Vector2(0, tex.get_height() / 2.0)       # pivot aux pieds
	s.position = pos
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_monde.add_child(s)
	# Ombre douce au sol + liseré de l'élément
	var ombre := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = h * 0.26
	c.bottom_radius = h * 0.26
	c.height = 0.02
	c.radial_segments = 24
	ombre.mesh = c
	var mo := StandardMaterial3D.new()
	mo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mo.albedo_color = Color(0, 0, 0, 0.45)
	ombre.material_override = mo
	ombre.position = pos + Vector3(0, 0.01, 0)
	_monde.add_child(ombre)
	var anneau := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = h * 0.25
	t.outer_radius = h * 0.28
	t.rings = 24
	anneau.mesh = t
	var ma := StandardMaterial3D.new()
	ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ma.albedo_color = Color(couleur_element, 0.9)
	ma.emission_enabled = true
	ma.emission = couleur_element
	ma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	anneau.material_override = ma
	anneau.scale = Vector3(1, 0.15, 1)
	anneau.position = pos + Vector3(0, 0.02, 0)
	_monde.add_child(anneau)
	_unites[idx] = {"sprite": s, "ombre": ombre, "anneau": anneau, "pos": pos, "hauteur": h, "base_scale": s.scale, "frac": frac}
	# Respiration
	var tw := create_tween().set_loops()
	tw.tween_interval(randf() * 1.2)
	tw.tween_property(s, "scale:y", 1.025, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "scale:y", 1.0, 1.3).set_trans(Tween.TRANS_SINE)


func a(idx: int) -> bool:
	return _unites.has(idx)


## Où apparaît une unité à l'écran : pieds et sommet de la tête (en pixels, dans ce conteneur).
func ecran(idx: int) -> Dictionary:
	var u: Dictionary = _unites[idx]
	var pieds: Vector3 = u["pos"]
	var tete: Vector3 = pieds + Vector3(0, u["hauteur"], 0)
	return {"pieds": _camera.unproject_position(pieds) * _echelle(), "tete": _camera.unproject_position(tete) * _echelle()}


## Position à l'écran d'un point quelconque du sol (pour les unités sans figurine).
func ecran_sol(frac: Vector2) -> Vector2:
	return _camera.unproject_position(position_sol(frac)) * _echelle()


func _echelle() -> Vector2:
	var t := Vector2(_vp.size)
	return Vector2(size.x / maxf(1.0, t.x), size.y / maxf(1.0, t.y))


# =====================================================================
# Animations
# =====================================================================

func elan(att: int, cible: int, duree_aller: float, duree_retour: float, geant := false) -> void:
	if not a(att):
		return
	var s: Sprite3D = _unites[att]["sprite"]
	var depart: Vector3 = _unites[att]["pos"]
	var arrivee: Vector3 = _unites[cible]["pos"] if a(cible) else depart
	var vers: Vector3 = depart.lerp(arrivee, 0.06 if geant else 0.42)
	var tw := create_tween()
	tw.tween_property(s, "position", vers + Vector3(0, 0.25, 0), duree_aller).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position", depart, duree_retour).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func touche(idx: int, critique: bool) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var s: Sprite3D = u["sprite"]
	s.modulate = Color(2.2, 1.3, 1.3)
	var tw := create_tween()
	tw.tween_property(s, "modulate", Color.WHITE, 0.25 / vitesse)
	var recul := 0.25 if s.flip_h else -0.25
	var tr := create_tween()
	tr.tween_property(s, "position:x", u["pos"].x - recul, 0.05 / vitesse)
	tr.tween_property(s, "position:x", u["pos"].x, 0.12 / vitesse)
	_eclats(u["pos"] + Vector3(0, u["hauteur"] * 0.55, 0.3), Color(1.0, 0.85, 0.4) if critique else Color(1.0, 0.45, 0.3), 26 if critique else 14)
	if critique:
		trembler(0.12)


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
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


## Sort : la figurine grandit, une lumière de couleur jaillit et la caméra se rapproche un instant.
func sort(idx: int, couleur: Color) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var s: Sprite3D = u["sprite"]
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector3(1.15, 1.15, 1.15), 0.12 / vitesse)
	tw.tween_property(s, "scale", Vector3.ONE, 0.18 / vitesse)
	var l := OmniLight3D.new()
	l.light_color = couleur
	l.light_energy = 0.0
	l.omni_range = 6.0
	l.position = u["pos"] + Vector3(0, u["hauteur"] * 0.6, 1.0)
	_monde.add_child(l)
	var tl := create_tween()
	tl.tween_property(l, "light_energy", 5.0, 0.12 / vitesse)
	tl.tween_property(l, "light_energy", 0.0, 0.5 / vitesse)
	tl.tween_callback(l.queue_free)
	_eclats(u["pos"] + Vector3(0, u["hauteur"] * 0.5, 0.2), couleur, 30, true)
	_approcher(u["pos"])


func _approcher(cible: Vector3) -> void:
	if _tw_cam:
		_tw_cam.kill()
	var proche := _cam_base
	proche.origin = _cam_base.origin.lerp(cible + Vector3(0, 2.5, 6.0), 0.22)
	_tw_cam = create_tween()
	_tw_cam.tween_property(_camera, "transform", proche, 0.25 / vitesse).set_trans(Tween.TRANS_SINE)
	_tw_cam.tween_interval(0.25 / vitesse)
	_tw_cam.tween_property(_camera, "transform", _cam_base, 0.45 / vitesse).set_trans(Tween.TRANS_SINE)


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
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func ko(idx: int) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var s: Sprite3D = u["sprite"]
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var cote := 1.0 if s.flip_h else -1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "rotation:z", cote * 1.35, 0.4 / vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "modulate", Color(0.45, 0.42, 0.45, 0.6), 0.4 / vitesse)
	tw.tween_property(u["anneau"], "scale", Vector3(0.01, 0.01, 0.01), 0.4 / vitesse)
	_eclats(u["pos"] + Vector3(0, 0.3, 0), Color(0.6, 0.55, 0.5), 18)


func revivre(idx: int) -> void:
	if not a(idx):
		return
	var u: Dictionary = _unites[idx]
	var s: Sprite3D = u["sprite"]
	s.rotation = Vector3.ZERO
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.modulate = Color.WHITE
	u["anneau"].scale = Vector3(1, 0.15, 1)
	soin(idx)


func trembler(force: float) -> void:
	if _tw_cam and _tw_cam.is_running():
		return
	var tw := create_tween()
	for k in 5:
		var t := _cam_base
		t.origin += Vector3(randf_range(-force, force), randf_range(-force, force), 0)
		tw.tween_property(_camera, "transform", t, 0.03 / vitesse)
	tw.tween_property(_camera, "transform", _cam_base, 0.05 / vitesse)


## Mise à jour immédiate (mode « Passer »).
func etat_ko(idx: int, oui: bool) -> void:
	if not a(idx):
		return
	var s: Sprite3D = _unites[idx]["sprite"]
	if oui:
		s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		s.rotation.z = 1.35 if s.flip_h else -1.35
		s.modulate = Color(0.45, 0.42, 0.45, 0.6)
	else:
		revivre(idx)
