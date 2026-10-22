class_name Plateau3D
extends SubViewportContainer
## PLATEAU D'UN CHAPITRE EN 3D (affichage seulement : les règles restent dans plateau.gd).
##
## - Le chapitre est un SENTIER qui serpente sur le sol peint de l'Acte, avec la toile de l'Acte au loin.
## - Chaque case est une dalle de pierre. Les combats montrent la figurine de l'ennemi qui attend
##   (le plus fort de la rencontre), les autres cases leur miniature (coffre, autel, mystère, piège…).
## - Le héros (pion du grand frère) MARCHE le long du sentier, à petits pas, comme une figurine qu'on avance.
## - Des FLÈCHES dorées au sol montrent où l'on peut aller ; à un embranchement, une flèche par route.
## - Brouillard : seules les cases proches du chemin parcouru sont visibles ; les autres sont des
##   silhouettes sombres ou restent cachées. Le boss est toujours visible au bout du chemin.
## - Vue « Carte » : la caméra monte au-dessus de tout le chapitre.
##
## Coordonnées : une case du générateur (pos x = pas, y = voie) devient (x * PAS_X, 0, y * PAS_Z).

const SHADER_FIGURINE := preload("res://scripts/figurine_3d.gdshader")
const PAS_X := 4.2          # mètres entre deux cases successives
const PAS_Z := 3.6          # mètres entre deux voies
const LARGEUR_SENTIER := 1.35
const R_DALLE := 0.95
const H_DALLE := 0.16
const H_PION := 2.1
const H_ENNEMI := 1.9
const H_BOSS := 2.9
const H_MINIATURE := 1.35
const COULEUR_LARME := Color(0.45, 0.65, 1.0)
const DOSSIER_MINIATURES := "res://assets/plateaux/cases/"
const IMAGE_PION := "res://assets/plateaux/pion_aine.png"
const T := PlateauGenerateur.Type
const MINIATURES := {
	T.DEPART: "depart", T.COMBAT: "combat", T.ELITE: "elite", T.GARDIEN: "gardien", T.BOSS: "boss",
	T.COFFRE: "coffre", T.SOIN: "soin", T.MYSTERE: "mystere", T.PIEGE: "piege",
}
## Lueur de chaque type de case (sous la dalle)
const COULEURS := {
	T.DEPART: Color("6a6560"), T.COMBAT: Color("b0362a"), T.ELITE: Color("e07020"), T.GARDIEN: Color("4a70b0"),
	T.BOSS: Color("c01010"), T.COFFRE: Color("e0a830"), T.SOIN: Color("3aa060"), T.MYSTERE: Color("8060d0"),
	T.PIEGE: Color("7a6040"),
}

var acte := 1
var _vp: SubViewport
var _monde: Node3D
var _camera: Camera3D
var _noeuds: Array = []
var _boss := -1
var _cases := {}              # id -> {racine, dalle, mat_dalle, fig, mat_fig, type}
var _sentiers := {}           # "a-b" -> {mesh, mat}
var _fleches: Array = []      # [{noeud, cible}]
var _pion: Node3D
var _mat_pion: ShaderMaterial
var _lumiere_pion: OmniLight3D
var _lumiere_boss: OmniLight3D
var _cible_cam := Vector3.ZERO
var _cible_voulue := Vector3.ZERO
var _zoom := 1.0
var _vue_carte := false
var camera_libre := false
var _temps := 0.0
var _plongee := false
var _bornes := Rect2()
var _bornes_vues := Rect2()     # partie découverte du chapitre (cadrage de la vue Carte)


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


## Position 3D d'une case.
func pos(id: int) -> Vector3:
	var p: Vector2 = _noeuds[id]["pos"]
	return Vector3(p.x * PAS_X, 0.0, p.y * PAS_Z)


## Construit tout le plateau. figurines : id de case -> chemin de la figurine de l'ennemi à montrer.
func construire(acte_: int, noeuds: Array, depart: int, boss: int, figurines: Dictionary, accent: Color) -> void:
	acte = acte_
	_noeuds = noeuds
	_boss = boss
	var amb: Dictionary = Combat3D.AMBIANCES.get(acte, Combat3D.AMBIANCES[1])
	var mini_ := Vector2(INF, INF)
	var maxi_ := Vector2(-INF, -INF)
	for n in noeuds:
		var p := pos(n["id"])
		mini_ = mini_.min(Vector2(p.x, p.z))
		maxi_ = maxi_.max(Vector2(p.x, p.z))
	_bornes = Rect2(mini_, maxi_ - mini_)

	# Ambiance (mêmes réglages que les combats de l'Acte, un peu plus de brume au loin)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = (amb.get("c_brume", Color(0.08, 0.06, 0.07)) as Color).darkened(0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = amb["amb"]
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 1.1
	env.adjustment_enabled = true
	env.adjustment_saturation = float(amb["sat"])
	env.adjustment_contrast = float(amb["contraste"])
	env.fog_enabled = true
	env.fog_light_color = amb.get("c_brume", Color(0.08, 0.06, 0.07))
	env.fog_density = maxf(0.018, float(amb.get("brume", 0.0)) * 1.4)
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	_monde.add_child(we)

	_creer_sol(amb)
	_creer_toile()
	for n in noeuds:
		var a: int = n["id"]
		for b in n["voisins"]:
			if b > a:
				_creer_sentier(a, b, accent)
	for n in noeuds:
		_creer_case(n, figurines.get(n["id"], ""))
	_creer_pion()

	var lune := DirectionalLight3D.new()
	lune.light_color = Color(0.85, 0.82, 1.0)
	lune.light_energy = 0.55
	lune.shadow_enabled = true
	lune.shadow_opacity = 0.7
	lune.directional_shadow_max_distance = 45.0
	lune.rotation_degrees = Vector3(-55, -35, 0)
	_monde.add_child(lune)
	_lumiere_boss = OmniLight3D.new()
	_lumiere_boss.light_color = Color(1.0, 0.2, 0.1)
	_lumiere_boss.light_energy = 2.0
	_lumiere_boss.omni_range = 7.0
	_lumiere_boss.position = pos(boss) + Vector3(0, 2.5, 0)
	_monde.add_child(_lumiere_boss)

	_camera = Camera3D.new()
	_camera.fov = 42.0
	_camera.far = 400.0
	_monde.add_child(_camera)
	_cible_cam = pos(depart)
	_cible_voulue = _cible_cam
	placer_pion(depart)
	_maj_camera(1.0)


func _creer_sol(amb: Dictionary) -> void:
	var marge := 90.0
	var taille := _bornes.size + Vector2(marge * 2.0, marge * 2.0)
	var sol := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = taille
	sol.mesh = p
	sol.position = Vector3(_bornes.get_center().x, 0, _bornes.get_center().y)
	var ms := StandardMaterial3D.new()
	ms.roughness = 0.95
	var chemin_sol := "res://assets/combat3d/acte_%02d_sol.png" % acte
	if ResourceLoader.exists(chemin_sol):
		ms.albedo_texture = load(chemin_sol)
		ms.uv1_scale = Vector3(taille.x / 7.0, taille.y / 7.0, 1)
		ms.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		ms.albedo_color = Color(0.62, 0.58, 0.56) * (amb.get("sol", Color.WHITE) as Color)
	else:
		ms.albedo_color = Color(0.2, 0.17, 0.16)
	sol.material_override = ms
	_monde.add_child(sol)


## La toile peinte de l'Acte, dressée au bout du chemin, derrière le boss.
func _creer_toile() -> void:
	var chemin := "res://assets/combat3d/acte_%02d_fond.png" % acte
	if not ResourceLoader.exists(chemin):
		return
	var tex: Texture2D = load(chemin)
	var coupe := 0.72
	var largeur := 300.0
	var h := largeur * float(tex.get_height()) / float(tex.get_width()) * coupe
	var q := QuadMesh.new()
	q.size = Vector2(largeur, h)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.uv1_scale = Vector3(1, coupe, 1)
	m.albedo_color = Color(0.6, 0.56, 0.56)
	m.disable_fog = true
	mi.material_override = m
	# Face à la caméra (elle regarde vers +X et un peu vers -Z), loin derrière le boss
	var regard := Vector3(0.83, 0, -0.56).normalized()
	mi.position = Vector3(_bornes.end.x, 0, _bornes.get_center().y) + regard * 70.0 + Vector3(0, h / 2.0 - 6.0, 0)
	mi.rotation.y = atan2(-regard.x, -regard.z)
	_monde.add_child(mi)


# ---------------------------------------------------------------
# Sentiers
# ---------------------------------------------------------------

## Point de contrôle de la courbe entre deux cases (le sentier ondule un peu, toujours pareil).
func _controle(a: int, b: int) -> Vector3:
	var pa := pos(a)
	var pb := pos(b)
	var milieu := (pa + pb) * 0.5
	var dir := (pb - pa).normalized()
	var perp := Vector3(-dir.z, 0, dir.x)
	var g := float(hash(a * 977 + b * 131) % 1000) / 1000.0
	return milieu + perp * (g - 0.5) * 1.6


## Point du sentier entre deux cases (t de 0 à 1), dans le sens a -> b.
func point_sentier(a: int, b: int, t: float) -> Vector3:
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var tt := t if a == lo else 1.0 - t
	var p0 := pos(lo)
	var c := _controle(lo, hi)
	var p2 := pos(hi)
	var u := 1.0 - tt
	return p0 * u * u + c * 2.0 * u * tt + p2 * tt * tt


func longueur_sentier(a: int, b: int) -> float:
	var l := 0.0
	var prec := point_sentier(a, b, 0.0)
	for i in range(1, 11):
		var p := point_sentier(a, b, i / 10.0)
		l += prec.distance_to(p)
		prec = p
	return l


func _creer_sentier(a: int, b: int, accent: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nb := 18
	var prec_g := Vector3.ZERO
	var prec_d := Vector3.ZERO
	var v_cumul := 0.0
	var prec_p := point_sentier(a, b, 0.0)
	for i in nb + 1:
		var t := float(i) / nb
		var p := point_sentier(a, b, t)
		var q := point_sentier(a, b, minf(1.0, t + 0.02))
		if t >= 1.0:
			q = p + (p - point_sentier(a, b, 0.98))
		var dir := (q - p).normalized()
		var perp := Vector3(-dir.z, 0, dir.x) * LARGEUR_SENTIER * 0.5
		v_cumul += p.distance_to(prec_p)
		prec_p = p
		var g := p + perp + Vector3(0, 0.025, 0)
		var d := p - perp + Vector3(0, 0.025, 0)
		if i > 0:
			var v0 := (v_cumul - 0.3) / 1.6
			var v1 := v_cumul / 1.6
			st.set_uv(Vector2(0, v0)); st.add_vertex(prec_g)
			st.set_uv(Vector2(1, v0)); st.add_vertex(prec_d)
			st.set_uv(Vector2(1, v1)); st.add_vertex(d)
			st.set_uv(Vector2(0, v0)); st.add_vertex(prec_g)
			st.set_uv(Vector2(1, v1)); st.add_vertex(d)
			st.set_uv(Vector2(0, v1)); st.add_vertex(g)
		prec_g = g
		prec_d = d
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_texture = _texture_paves()
	m.albedo_color = Color(0.5, 0.45, 0.42).lerp(accent, 0.1)
	m.roughness = 0.9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_monde.add_child(mi)
	_sentiers["%d-%d" % [a, b]] = {"mesh": mi, "mat": m}


static var _paves: Texture2D = null

## Texture de pavés (générée une fois) : dalles irrégulières, bords qui s'estompent.
static func _texture_paves() -> Texture2D:
	if _paves:
		return _paves
	var w := 64
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rangs := 6
	for y in h:
		var rang := int(y * rangs / float(h))
		var decal := 0.5 if rang % 2 == 1 else 0.0
		var fy := fmod(y * rangs / float(h), 1.0)
		for x in w:
			var fx := fmod(x / float(w) * 2.0 + decal, 1.0)
			var joint := fx < 0.06 or fy < 0.08
			var bord := absf(x / float(w) - 0.5) * 2.0
			var a := clampf((1.0 - bord) * 3.0, 0.0, 1.0)
			var v := 0.42 + 0.08 * sin(x * 0.7 + y * 0.31) + rng.randf_range(-0.04, 0.04)
			if joint:
				v = 0.18
			img.set_pixel(x, y, Color(v, v * 0.95, v * 0.9, a))
	img.generate_mipmaps()
	_paves = ImageTexture.create_from_image(img)
	return _paves


# ---------------------------------------------------------------
# Cases
# ---------------------------------------------------------------

func _creer_case(n: Dictionary, chemin_ennemi: String) -> void:
	var id: int = n["id"]
	var type: int = n["type"]
	var racine := Node3D.new()
	racine.position = pos(id)
	_monde.add_child(racine)
	var boss: bool = type == PlateauGenerateur.Type.BOSS
	var dalle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = R_DALLE * (1.35 if boss else 1.0)
	cyl.bottom_radius = cyl.top_radius * 1.08
	cyl.height = H_DALLE
	cyl.radial_segments = 28
	dalle.mesh = cyl
	var md := StandardMaterial3D.new()
	md.albedo_color = Color(0.2, 0.18, 0.17)
	md.roughness = 0.75
	md.metallic = 0.2
	dalle.material_override = md
	dalle.position.y = H_DALLE / 2.0
	racine.add_child(dalle)
	# Liseré gravé de la couleur de la case (rouge combat, or coffre, vert soin…)
	var lis := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = cyl.top_radius * 0.97
	tor.outer_radius = cyl.top_radius * 1.06
	tor.rings = 32
	tor.ring_segments = 6
	lis.mesh = tor
	var ml := StandardMaterial3D.new()
	ml.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ml.albedo_color = COULEURS.get(type, Color.GRAY)
	ml.emission_enabled = true
	ml.emission = COULEURS.get(type, Color.GRAY)
	ml.emission_energy_multiplier = 1.6
	lis.material_override = ml
	lis.scale = Vector3(1, 0.5, 1)
	lis.position.y = H_DALLE * 0.75
	lis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	racine.add_child(lis)

	var chemin := chemin_ennemi
	var h := H_BOSS if boss else H_ENNEMI
	if chemin == "" or not ResourceLoader.exists(chemin):
		chemin = DOSSIER_MINIATURES + str(MINIATURES.get(type, "combat")) + ".png"
		h = H_MINIATURE * (1.3 if boss else 1.0)
	var fig: MeshInstance3D = null
	var mat: ShaderMaterial = null
	if ResourceLoader.exists(chemin):
		var r := _figure(chemin, h)
		fig = r[0]
		mat = r[1]
		fig.position.y = H_DALLE * 0.9
		racine.add_child(fig)
	_cases[id] = {"racine": racine, "dalle": dalle, "mat_dalle": md, "mat_lis": ml, "fig": fig, "mat_fig": mat, "type": type}


## Une figurine peinte (même rendu en relief que les combats). Renvoie [mesh, matériau].
func _figure(chemin: String, h: float) -> Array:
	var tex: Texture2D = load(chemin)
	var ratio := float(tex.get_width()) / float(tex.get_height())
	var q := QuadMesh.new()
	q.size = Vector2(h * ratio, h)
	q.center_offset = Vector3(0, h / 2.0, 0)
	q.subdivide_depth = 8
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_FIGURINE
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("texel", Vector2(1.0 / tex.get_width(), 1.0 / tex.get_height()))
	mat.set_shader_parameter("hauteur", h)
	mat.set_shader_parameter("retourne", 1.0)
	mat.set_shader_parameter("phase", randf() * TAU)
	mat.set_shader_parameter("balance", 0.6)
	mat.set_shader_parameter("lisere", 0.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return [mi, mat]


func _creer_pion() -> void:
	_pion = Node3D.new()
	_monde.add_child(_pion)
	var chemin := IMAGE_PION
	if ResourceLoader.exists(chemin):
		var r := _figure(chemin, H_PION)
		_mat_pion = r[1]
		_mat_pion.set_shader_parameter("retourne", 0.0)
		_mat_pion.set_shader_parameter("balance", 0.4)
		_pion.add_child(r[0])
	_lumiere_pion = OmniLight3D.new()
	_lumiere_pion.light_color = COULEUR_LARME
	_lumiere_pion.light_energy = 2.4
	_lumiere_pion.omni_range = 9.0
	_lumiere_pion.shadow_enabled = true
	_lumiere_pion.position = Vector3(0.6, 2.6, 1.2)
	_pion.add_child(_lumiere_pion)
	var chaude := OmniLight3D.new()
	chaude.light_color = Color(1.0, 0.75, 0.5)
	chaude.light_energy = 0.9
	chaude.omni_range = 14.0
	chaude.position = Vector3(-2.0, 4.0, 3.0)
	_pion.add_child(chaude)


# ---------------------------------------------------------------
# État du plateau (brouillard, cases terminées, flèches)
# ---------------------------------------------------------------

## reveles / visites / termines : dictionnaires d'ids ; accessibles : cases où l'on peut aller.
func maj(courant: int, reveles: Dictionary, visites: Dictionary, termines: Dictionary, accessibles: Array) -> void:
	var premier := true
	for id in reveles:
		if id == _boss and not _voisin_de(id, visites):
			continue
		var p3 := pos(id)
		var p2 := Vector2(p3.x, p3.z)
		if premier:
			_bornes_vues = Rect2(p2, Vector2.ZERO)
			premier = false
		else:
			_bornes_vues = _bornes_vues.expand(p2)
	_bornes_vues = _bornes_vues.grow(3.0)
	for id in _cases:
		var c: Dictionary = _cases[id]
		var visible := reveles.has(id)
		var silhouette := not visible and _voisin_de(id, reveles)
		var racine: Node3D = c["racine"]
		racine.visible = visible or silhouette
		var mat: ShaderMaterial = c["mat_fig"]
		var fig: MeshInstance3D = c["fig"]
		var fini: bool = termines.has(id) and id != courant
		var combat := PlateauGenerateur.est_combat(int(_noeuds[id]["type"]))
		if fig:
			fig.visible = not (fini and combat) and id != courant
			if mat:
				mat.set_shader_parameter("sombre", 0.85 if silhouette else (0.45 if fini else 0.0))
				mat.set_shader_parameter("opacite", 0.55 if silhouette else 1.0)
		var md: StandardMaterial3D = c["mat_dalle"]
		md.albedo_color = Color(0.1, 0.09, 0.09) if silhouette else Color(0.2, 0.18, 0.17)
		var ml: StandardMaterial3D = c["mat_lis"]
		ml.emission_energy_multiplier = 0.0 if silhouette else (0.35 if fini else 1.6)
		ml.albedo_color = Color(0.12, 0.1, 0.1) if silhouette else (COULEURS.get(c["type"], Color.GRAY) as Color).darkened(0.5 if fini else 0.0)
	for cle in _sentiers:
		var ab: PackedStringArray = cle.split("-")
		var a := int(ab[0])
		var b := int(ab[1])
		var s: Dictionary = _sentiers[cle]
		var va := reveles.has(a)
		var vb := reveles.has(b)
		(s["mesh"] as MeshInstance3D).visible = va or vb
		var m: StandardMaterial3D = s["mat"]
		var parcouru := visites.has(a) and visites.has(b)
		var alpha := 1.0 if (va and vb) else 0.35
		var base := Color(0.62, 0.56, 0.5) if parcouru else Color(0.46, 0.42, 0.4)
		m.albedo_color = Color(base, alpha)
	_creer_fleches(courant, accessibles)


func _voisin_de(id: int, reveles: Dictionary) -> bool:
	for v in _noeuds[id]["voisins"]:
		if reveles.has(v):
			return true
	return false


func _creer_fleches(courant: int, accessibles: Array) -> void:
	for f in _fleches:
		(f["noeud"] as Node3D).queue_free()
	_fleches.clear()
	for cible in accessibles:
		var t := 0.42
		var p := point_sentier(courant, cible, t)
		var q := point_sentier(courant, cible, t + 0.05)
		var fl := MeshInstance3D.new()
		fl.mesh = _mesh_fleche()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.82, 0.35)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.75, 0.3)
		m.emission_energy_multiplier = 2.0
		m.disable_fog = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.no_depth_test = true
		m.render_priority = 2
		fl.material_override = m
		fl.scale = Vector3(1.4, 1.0, 1.4)
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fl.position = p + Vector3(0, 0.08, 0)
		_monde.add_child(fl)
		fl.look_at(q + Vector3(0, 0.08, 0), Vector3.UP)
		_fleches.append({"noeud": fl, "cible": cible, "mat": m, "base": fl.position, "dir": (q - p).normalized()})


static var _fleche_mesh: Mesh = null

## Flèche plate posée au sol (pointe vers -Z, comme look_at).
static func _mesh_fleche() -> Mesh:
	if _fleche_mesh:
		return _fleche_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [Vector3(-0.22, 0, 0.55), Vector3(0.22, 0, 0.55), Vector3(0.22, 0, -0.05), Vector3(-0.22, 0, -0.05),
		Vector3(-0.55, 0, -0.05), Vector3(0.55, 0, -0.05), Vector3(0, 0, -0.75)]
	for i in [0, 1, 2, 0, 2, 3, 4, 5, 6]:
		st.set_normal(Vector3.UP)
		st.add_vertex(pts[i])
	_fleche_mesh = st.commit()
	return _fleche_mesh


# ---------------------------------------------------------------
# Pion
# ---------------------------------------------------------------

func placer_pion(id: int) -> void:
	_pion.position = pos(id) + Vector3(0, H_DALLE, 0)
	if _mat_pion:
		_mat_pion.set_shader_parameter("penche", 0.0)
		_mat_pion.set_shader_parameter("ecrase", 0.0)


## Le pion marche de a vers b (t de 0 à 1) : petits pas sautillés le long du sentier.
func marcher(t: float, a: int, b: int) -> void:
	var p := point_sentier(a, b, t)
	var nb_pas := maxi(3, int(round(longueur_sentier(a, b) / 0.9)))
	var phase := t * nb_pas
	var saut := absf(sin(phase * PI)) * 0.28
	_pion.position = p + Vector3(0, H_DALLE * (1.0 if t < 0.12 or t > 0.88 else 0.2) + saut, 0)
	if _mat_pion:
		var dir := point_sentier(a, b, minf(1.0, t + 0.03)) - point_sentier(a, b, maxf(0.0, t - 0.03))
		var ecran := _camera.unproject_position(_pion.position + dir) - _camera.unproject_position(_pion.position)
		if absf(ecran.x) > 2.0:
			_mat_pion.set_shader_parameter("retourne", 1.0 if ecran.x < 0.0 else 0.0)
		_mat_pion.set_shader_parameter("penche", sin(phase * TAU) * 0.08)
		_mat_pion.set_shader_parameter("ecrase", -0.05 * absf(sin(phase * PI)) if t < 1.0 else 0.0)
	if not camera_libre and not _vue_carte:
		_cible_voulue = _pion.position


## Durée de marche entre deux cases (secondes).
func duree_marche(a: int, b: int) -> float:
	return clampf(longueur_sentier(a, b) / 3.6, 0.7, 1.6)


# ---------------------------------------------------------------
# Caméra
# ---------------------------------------------------------------

func _process(delta: float) -> void:
	if _camera == null:
		return
	_temps += delta
	if not _plongee:
		if not camera_libre and not _vue_carte:
			_cible_voulue = _pion.position
		_cible_cam = _cible_cam.lerp(_cible_voulue, 1.0 - exp(-4.0 * delta))
		_maj_camera(delta)
	# Les figurines se tournent vers la caméra (seulement autour de l'axe vertical)
	var cam := _camera.global_position
	for id in _cases:
		var fig: MeshInstance3D = _cases[id]["fig"]
		if fig and fig.is_visible_in_tree():
			_tourner_vers(fig, cam)
	if _pion:
		_tourner_vers(_pion, cam)
	var pulse := 0.5 + 0.5 * sin(_temps * 5.0)
	for f in _fleches:
		var m: StandardMaterial3D = f["mat"]
		m.emission_energy_multiplier = 1.4 + pulse * 1.6
		var n: Node3D = f["noeud"]
		n.position = f["base"] + (f["dir"] as Vector3) * pulse * 0.25
	if _lumiere_boss:
		_lumiere_boss.light_energy = 1.6 + 0.8 * sin(_temps * 2.0)


func _tourner_vers(n: Node3D, cam: Vector3) -> void:
	var d := cam - n.global_position
	n.rotation.y = atan2(d.x, d.z)


func _maj_camera(_delta: float) -> void:
	if _vue_carte:
		var c := _bornes_vues.get_center()
		# Assez haut pour voir tout le chapitre (longueur et largeur), légèrement incliné
		var aspect := size.x / maxf(1.0, size.y)
		var h := maxf(maxf(_bornes_vues.size.x * 0.95 / aspect, _bornes_vues.size.y * 1.25), 18.0)
		var but := Vector3(c.x, 0, c.y)
		_camera.position = _camera.position.lerp(but + Vector3(0, h, h * 0.42), 0.12)
		_camera.look_at(but, Vector3.UP)
		return
	var d := Vector3(-6.2, 4.6, 6.4) * _zoom
	_camera.position = _cible_cam + d
	_camera.look_at(_cible_cam + Vector3(3.6, 1.0, -0.6), Vector3.UP)


func zoomer(facteur: float) -> void:
	_zoom = clampf(_zoom / facteur, 0.6, 1.8)


## Glisser le doigt : déplace le regard sur le plateau.
func glisser(relatif: Vector2) -> void:
	camera_libre = true
	var avant := Vector3(1, 0, -0.6).normalized()
	var droite := Vector3(0.6, 0, 1).normalized()
	_cible_voulue += (-droite * relatif.x + avant * relatif.y) * 0.03 * _zoom
	_cible_voulue.x = clampf(_cible_voulue.x, _bornes.position.x - 6.0, _bornes.end.x + 6.0)
	_cible_voulue.z = clampf(_cible_voulue.z, _bornes.position.y - 8.0, _bornes.end.y + 8.0)


func recentrer() -> void:
	camera_libre = false
	_vue_carte = false


func basculer_carte() -> bool:
	_vue_carte = not _vue_carte
	camera_libre = false
	return _vue_carte


func vue_carte() -> bool:
	return _vue_carte


## Avant un combat : la caméra plonge vers la case (puis l'écran de combat s'ouvre).
func plongee(id: int) -> void:
	_plongee = true
	_vue_carte = false
	var cible := pos(id) + Vector3(0, 1.2, 0)
	var depart := _camera.position
	var tw := create_tween()
	tw.tween_method(func(t: float):
		_camera.position = depart.lerp(cible + Vector3(-2.2, 1.0, 2.0), t)
		_camera.look_at(cible, Vector3.UP)
		_camera.fov = lerpf(42.0, 30.0, t), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


# ---------------------------------------------------------------
# Toucher : quelle case (ou quelle flèche) est sous le doigt
# ---------------------------------------------------------------

func _echelle() -> Vector2:
	var t := Vector2(_vp.size)
	return Vector2(size.x / maxf(1.0, t.x), size.y / maxf(1.0, t.y))


func _ecran(p: Vector3) -> Vector2:
	if _camera.is_position_behind(p):
		return Vector2(-99999, -99999)
	return _camera.unproject_position(p) * _echelle()


## Case sous le point de l'écran (les flèches comptent pour leur case cible), -1 si aucune.
func noeud_a_ecran(p: Vector2, reveles: Dictionary) -> int:
	var meilleur := -1
	var dmin := 64.0 * clampf(size.y / 720.0, 0.8, 2.0)
	for f in _fleches:
		var d := p.distance_to(_ecran((f["noeud"] as Node3D).global_position))
		if d < dmin:
			dmin = d
			meilleur = f["cible"]
	if meilleur >= 0:
		return meilleur
	for id in _cases:
		if not reveles.has(id):
			continue
		for hauteur in [0.2, 1.0]:
			var d := p.distance_to(_ecran(pos(id) + Vector3(0, hauteur, 0)))
			if d < dmin:
				dmin = d
				meilleur = id
	return meilleur


## Position à l'écran d'une case (pour placer une bulle).
func ecran_case(id: int) -> Vector2:
	return _ecran(pos(id) + Vector3(0, 1.5, 0))
