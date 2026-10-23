class_name Carte3D
extends SubViewportContainer
## LA CARTE DU MONDE EN 3D : la carte peinte des Terres des Valcendre posée comme un grand plateau,
## vue de biais. Chaque Acte est une dalle de pierre gravée de son numéro, gardée par la figurine
## de son boss ; la route pavée les relie, dorée là où le grand frère est déjà passé.
## Le pion du grand frère marche d'Acte en Acte le long de la route, et la caméra plonge vers
## l'Acte choisi avant d'ouvrir le plateau du chapitre.
##
## Ne dessine que la 3D : la fiche de l'Acte, la barre du haut et les fenêtres restent dans
## ecran_carte.gd (qui crée cette vue quand « Combats et plateaux en 3D » est coché).

const SHADER_FIGURINE := preload("res://scripts/figurine_3d.gdshader")
const IMAGE_CARTE := "res://assets/ui/carte_monde.png"
const IMAGE_SOL_AUTOUR := "res://assets/combat3d/table_carte.png"
const IMAGE_PION := "res://assets/plateaux/pion_aine.png"
const LARGEUR := 48.0              # largeur de la carte (mètres)
const LARGEUR_ROUTE := 0.34
const R_DALLE := 0.62
const H_DALLE := 0.14
const H_PION := 1.45
const H_BOSS := 1.7
const COULEUR_LARME := Color(0.45, 0.65, 1.0)
const ROMAINS := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]

## Le pion reste là où on l'a laissé d'une visite à l'autre (0 = sur l'Acte en cours).
static var acte_pion := 0

var _vp: SubViewport
var _monde: Node3D
var _camera: Camera3D
var _hauteur := 32.0
var _positions := {}            # acte -> Vector3
var _actes := {}                # acte -> {racine, mat_lis, fig, mat_fig, etiquette}
var _routes := {}               # acte a -> {mesh, mat} (route de a vers a+1)
var _brume: MeshInstance3D
var _mat_brume: ShaderMaterial
var _limite := -INF             # z au-delà duquel (vers le nord) la brume cache tout
var _pion: Node3D
var _mat_pion: ShaderMaterial
var _pion_acte := 1
var _cible_cam := Vector3.ZERO
var _cible_voulue := Vector3.ZERO
var _zoom := 1.0
var _temps := 0.0
var _plongee := false
var _marche := false
var _nb := 12
## Stèle du Sceau de l'Aube (Ruines Oubliées) : visible dès le premier fragment
const STELE := 99
var _stele: Node3D = null
var _stele_pos := Vector3.ZERO
var _mat_sceau: StandardMaterial3D = null
var _lumiere_stele: OmniLight3D = null
var _force_stele := 0
## Part de l'écran (à gauche) où l'Acte choisi doit apparaître : la fiche occupe la droite.
var centre_ecran := 0.36


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


## Position 3D d'un Acte, à partir de sa position sur la carte peinte (u, v de 0 à 1).
func pos(a: int) -> Vector3:
	return _positions.get(a, Vector3.ZERO)


## uv : acte -> Vector2 (0..1 sur l'image). etats : acte -> "fait" / "cours" / "ouvert" / "ferme".
## figurines : acte -> chemin de la figurine du boss. courant : Acte en cours (brume au-delà).
func construire(uv: Dictionary, etats: Dictionary, figurines: Dictionary, courant: int, nb: int, choisi: int) -> void:
	_nb = nb
	var tex_carte: Texture2D = load(IMAGE_CARTE) if ResourceLoader.exists(IMAGE_CARTE) else null
	var ratio := 1.5
	if tex_carte:
		ratio = float(tex_carte.get_width()) / float(tex_carte.get_height())
	_hauteur = LARGEUR / ratio
	for a in uv:
		var p: Vector2 = uv[a]
		_positions[a] = Vector3((p.x - 0.5) * LARGEUR, 0.0, (p.y - 0.5) * _hauteur)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.022, 0.025)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.55, 0.52)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.035, 0.04)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	_monde.add_child(we)

	_creer_table()
	_creer_carte(tex_carte)
	for a in range(1, nb):
		_creer_route(a, a + 1)
	for a in range(1, nb + 1):
		_creer_acte(a, str(etats.get(a, "ferme")), str(figurines.get(a, "")))
	_creer_brume(courant)
	_creer_pion()

	var lune := DirectionalLight3D.new()
	lune.light_color = Color(1.0, 0.9, 0.8)
	lune.light_energy = 0.75
	lune.shadow_enabled = true
	lune.shadow_opacity = 0.65
	lune.directional_shadow_max_distance = 60.0
	lune.rotation_degrees = Vector3(-50, -30, 0)
	_monde.add_child(lune)

	_camera = Camera3D.new()
	_camera.fov = 40.0
	_camera.far = 300.0
	_monde.add_child(_camera)
	maj_etats(etats)
	_pion_acte = acte_pion if (acte_pion >= 1 and acte_pion <= nb and etats.get(acte_pion, "ferme") != "ferme") else courant
	acte_pion = _pion_acte
	_placer_pion(_pion_acte)
	_cible_cam = pos(choisi)
	_cible_voulue = _cible_cam
	_maj_camera()


# ---------------------------------------------------------------
# Décor
# ---------------------------------------------------------------

## Grande table sombre sous la carte (image si elle existe, sinon un bois sombre uni).
func _creer_table() -> void:
	var t := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(LARGEUR * 3.0, _hauteur * 3.0)
	t.mesh = p
	t.position.y = -0.05
	var m := StandardMaterial3D.new()
	m.roughness = 0.85
	if ResourceLoader.exists(IMAGE_SOL_AUTOUR):
		m.albedo_texture = load(IMAGE_SOL_AUTOUR)
		m.uv1_scale = Vector3(16, 16 * _hauteur / LARGEUR, 1)
		m.albedo_color = Color(0.55, 0.5, 0.48)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		m.albedo_color = Color(0.09, 0.065, 0.055)
	t.material_override = m
	_monde.add_child(t)


## La carte peinte, bords assombris et légèrement rongés, avec un grain de parchemin.
func _creer_carte(tex: Texture2D) -> void:
	var mi := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(LARGEUR, _hauteur)
	mi.mesh = p
	var sh := Shader.new()
	sh.code = """shader_type spatial;
uniform sampler2D carte : source_color, filter_linear_mipmap_anisotropic;
float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void fragment() {
	vec3 c = texture(carte, UV).rgb;
	float grain = bruit(UV * 900.0) * 0.5 + bruit(UV * 260.0) * 0.5;
	c *= 0.9 + grain * 0.18;
	vec2 b = min(UV, 1.0 - UV);
	float bord = min(b.x * 1.5, b.y);
	float ronge = bruit(UV * 40.0) * 0.025;
	float vign = smoothstep(0.0, 0.07, bord - ronge);
	ALBEDO = c * mix(0.08, 1.0, vign);
	ROUGHNESS = 0.92;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	if tex:
		m.set_shader_parameter("carte", tex)
	mi.material_override = m
	_monde.add_child(mi)


## Brume sur les terres pas encore atteintes : un voile sombre qui ondule au-dessus de la carte,
## au nord de l'Acte en cours (la route se dévoile au fil de l'histoire).
func _creer_brume(courant: int) -> void:
	var limite := INF
	if courant <= 4:
		limite = _limite_brume(courant)
	elif courant <= 8:
		limite = _limite_brume(courant)
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float limite = -1000.0;
uniform float temps = 0.0;
varying vec3 monde;
float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
void vertex() { monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = monde.xz * 0.16 + vec2(temps * 0.05, temps * 0.02);
	float n = bruit(p) * 0.6 + bruit(p * 2.3 + 4.0) * 0.4;
	float d = (limite - monde.z) + (n - 0.5) * 3.0;
	float a = smoothstep(-1.0, 4.0, d);
	ALBEDO = mix(vec3(0.035, 0.028, 0.032), vec3(0.11, 0.09, 0.1), n);
	ALPHA = a * (0.82 + n * 0.16);
}
"""
	_limite = limite if limite != INF else -INF
	_mat_brume = ShaderMaterial.new()
	_mat_brume.shader = sh
	_mat_brume.set_shader_parameter("limite", limite if limite != INF else -1000.0)
	_brume = MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(LARGEUR * 1.2, _hauteur * 1.2)
	_brume.mesh = p
	_brume.position.y = 1.1
	_brume.material_override = _mat_brume
	_brume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_brume.visible = limite != INF
	_monde.add_child(_brume)


## Bord de la brume : juste au-delà de l'Acte le plus au nord parmi ceux déjà ouverts (+ le suivant).
func _limite_brume(courant: int) -> float:
	var z := INF
	for a in range(1, mini(courant + 1, _nb) + 1):
		z = minf(z, pos(a).z)
	return z - 2.2


# ---------------------------------------------------------------
# Route
# ---------------------------------------------------------------

func _controle(a: int, b: int) -> Vector3:
	var pa := pos(a)
	var pb := pos(b)
	var dir := (pb - pa).normalized()
	var perp := Vector3(-dir.z, 0, dir.x)
	var g := float(hash(a * 977 + b * 131) % 1000) / 1000.0
	return (pa + pb) * 0.5 + perp * (g - 0.5) * pa.distance_to(pb) * 0.35


## Point de la route de a à b (b = a + 1 ou a - 1), t de 0 à 1.
func point_route(a: int, b: int, t: float) -> Vector3:
	var lo := mini(a, b)
	var hi := maxi(a, b)
	var tt := t if a == lo else 1.0 - t
	var c := _controle(lo, hi)
	var u := 1.0 - tt
	return pos(lo) * u * u + c * 2.0 * u * tt + pos(hi) * tt * tt


func longueur_route(a: int, b: int) -> float:
	var l := 0.0
	var prec := point_route(a, b, 0.0)
	for i in range(1, 13):
		var p := point_route(a, b, i / 12.0)
		l += prec.distance_to(p)
		prec = p
	return l


func _creer_route(a: int, b: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nb := 24
	var tuile := 1.0
	var prec_g := Vector3.ZERO
	var prec_d := Vector3.ZERO
	var v_cumul := 0.0
	var v_prec := 0.0
	var prec_p := point_route(a, b, 0.0)
	for i in nb + 1:
		var t := float(i) / nb
		var p := point_route(a, b, t)
		var q := point_route(a, b, minf(1.0, t + 0.02))
		if t >= 1.0:
			q = p + (p - point_route(a, b, 0.98))
		var dir := (q - p).normalized()
		var perp := Vector3(-dir.z, 0, dir.x) * LARGEUR_ROUTE * 0.5
		v_prec = v_cumul
		v_cumul += p.distance_to(prec_p)
		prec_p = p
		var g := p + perp + Vector3(0, 0.03, 0)
		var d := p - perp + Vector3(0, 0.03, 0)
		if i > 0:
			st.set_uv(Vector2(0, v_prec / tuile)); st.add_vertex(prec_g)
			st.set_uv(Vector2(1, v_prec / tuile)); st.add_vertex(prec_d)
			st.set_uv(Vector2(1, v_cumul / tuile)); st.add_vertex(d)
			st.set_uv(Vector2(0, v_prec / tuile)); st.add_vertex(prec_g)
			st.set_uv(Vector2(1, v_cumul / tuile)); st.add_vertex(d)
			st.set_uv(Vector2(0, v_cumul / tuile)); st.add_vertex(g)
		prec_g = g
		prec_d = d
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := ShaderMaterial.new()
	m.shader = _shader_route()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_monde.add_child(mi)
	_routes[a] = {"mesh": mi, "mat": m}


static var _sh_route: Shader = null

## La route : un tracé de traits lumineux, comme à l'encre dorée sur la carte.
static func _shader_route() -> Shader:
	if _sh_route:
		return _sh_route
	_sh_route = Shader.new()
	_sh_route.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 teinte : source_color = vec4(1.0);
uniform float lueur = 1.0;
uniform float defile = 0.0;
void fragment() {
	float trait = fract(UV.y * 1.25 - defile);
	float a = smoothstep(0.0, 0.08, trait) * smoothstep(0.62, 0.52, trait);
	float bord = 1.0 - smoothstep(0.25, 0.5, abs(UV.x - 0.5));
	ALBEDO = teinte.rgb * lueur;
	ALPHA = a * bord * teinte.a;
}
"""
	return _sh_route


# ---------------------------------------------------------------
# Actes
# ---------------------------------------------------------------

func _creer_acte(a: int, etat: String, chemin_fig: String) -> void:
	var racine := Node3D.new()
	racine.position = pos(a)
	_monde.add_child(racine)
	var dalle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = R_DALLE
	cyl.bottom_radius = R_DALLE * 1.1
	cyl.height = H_DALLE
	cyl.radial_segments = 28
	dalle.mesh = cyl
	var md := StandardMaterial3D.new()
	md.albedo_color = Color(0.2, 0.17, 0.16)
	md.roughness = 0.7
	md.metallic = 0.25
	dalle.material_override = md
	dalle.position.y = H_DALLE / 2.0
	racine.add_child(dalle)
	var lis := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = R_DALLE * 0.96
	tor.outer_radius = R_DALLE * 1.07
	tor.rings = 32
	tor.ring_segments = 6
	lis.mesh = tor
	var ml := StandardMaterial3D.new()
	ml.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ml.emission_enabled = true
	ml.emission_energy_multiplier = 1.5
	lis.material_override = ml
	lis.scale = Vector3(1, 0.5, 1)
	lis.position.y = H_DALLE * 0.8
	lis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	racine.add_child(lis)
	# Numéro de l'Acte gravé au sol, devant la dalle
	var num := Label3D.new()
	num.text = ROMAINS[a]
	num.font_size = 64
	num.pixel_size = 0.0075
	num.outline_size = 14
	num.outline_modulate = Color(0.05, 0.03, 0.03, 0.9)
	num.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	num.no_depth_test = true
	num.render_priority = 3
	num.position = Vector3(0, 0.05, R_DALLE + 0.45)
	if ResourceLoader.exists("res://assets/polices/titres.ttf"):
		num.font = load("res://assets/polices/titres.ttf")
	racine.add_child(num)
	var fig: MeshInstance3D = null
	var mat: ShaderMaterial = null
	if chemin_fig != "" and ResourceLoader.exists(chemin_fig):
		var tex: Texture2D = load(chemin_fig)
		var h := H_BOSS * (1.15 if a >= 12 else 1.0)
		var q := QuadMesh.new()
		q.size = Vector2(h * float(tex.get_width()) / float(tex.get_height()), h)
		q.center_offset = Vector3(0, h / 2.0, 0)
		q.subdivide_depth = 8
		fig = MeshInstance3D.new()
		fig.mesh = q
		mat = ShaderMaterial.new()
		mat.shader = SHADER_FIGURINE
		mat.set_shader_parameter("tex", tex)
		mat.set_shader_parameter("texel", Vector2(1.0 / tex.get_width(), 1.0 / tex.get_height()))
		mat.set_shader_parameter("hauteur", h)
		mat.set_shader_parameter("retourne", 1.0)
		mat.set_shader_parameter("phase", float(a) * 1.7)
		mat.set_shader_parameter("balance", 0.5)
		mat.set_shader_parameter("lisere", 0.0)
		fig.material_override = mat
		fig.position = Vector3(0.0, H_DALLE * 0.9, -0.08)
		racine.add_child(fig)
	_actes[a] = {"racine": racine, "mat_dalle": md, "mat_lis": ml, "fig": fig, "mat_fig": mat, "num": num, "etat": etat}


## Couleurs des dalles, des boss et de la route selon l'avancée.
func maj_etats(etats: Dictionary) -> void:
	for a in _actes:
		var c: Dictionary = _actes[a]
		var etat := str(etats.get(a, "ferme"))
		c["etat"] = etat
		var couleur := Color(0.35, 0.3, 0.28)
		match etat:
			"fait": couleur = Color(0.85, 0.65, 0.3)
			"cours": couleur = Color(1.0, 0.25, 0.2)
			"ouvert": couleur = Color(0.75, 0.55, 0.4)
		if a == 13:
			couleur = Color(0.62, 0.48, 1.0)
		var ml: StandardMaterial3D = c["mat_lis"]
		ml.albedo_color = couleur
		ml.emission = couleur
		ml.emission_energy_multiplier = 0.2 if etat == "ferme" else (2.2 if etat == "cours" else 1.3)
		(c["racine"] as Node3D).visible = not (etat == "ferme" and pos(a).z < _limite + 0.8)
		var num: Label3D = c["num"]
		num.modulate = Color(0.55, 0.5, 0.48) if etat == "ferme" else Color(1.0, 0.92, 0.75)
		var mat: ShaderMaterial = c["mat_fig"]
		if mat:
			# Boss vaincu : il reste, assombri ; terres pas encore atteintes : simple silhouette
			mat.set_shader_parameter("sombre", 0.9 if etat == "ferme" else (0.5 if etat == "fait" else 0.0))
			mat.set_shader_parameter("opacite", 0.6 if etat == "ferme" else 1.0)
	for a in _routes:
		var m: ShaderMaterial = _routes[a]["mat"]
		var faite := str(etats.get(a + 1, "ferme")) != "ferme"
		m.set_shader_parameter("teinte", Color(1.0, 0.78, 0.4, 0.95) if faite else Color(0.75, 0.68, 0.62, 0.45))
		m.set_shader_parameter("lueur", 1.6 if faite else 0.8)


# ---------------------------------------------------------------
# Pion du grand frère
# ---------------------------------------------------------------

func _creer_pion() -> void:
	_pion = Node3D.new()
	_monde.add_child(_pion)
	if ResourceLoader.exists(IMAGE_PION):
		var tex: Texture2D = load(IMAGE_PION)
		var q := QuadMesh.new()
		q.size = Vector2(H_PION * float(tex.get_width()) / float(tex.get_height()), H_PION)
		q.center_offset = Vector3(0, H_PION / 2.0, 0)
		q.subdivide_depth = 8
		var mi := MeshInstance3D.new()
		mi.mesh = q
		_mat_pion = ShaderMaterial.new()
		_mat_pion.shader = SHADER_FIGURINE
		_mat_pion.set_shader_parameter("tex", tex)
		_mat_pion.set_shader_parameter("texel", Vector2(1.0 / tex.get_width(), 1.0 / tex.get_height()))
		_mat_pion.set_shader_parameter("hauteur", H_PION)
		_mat_pion.set_shader_parameter("balance", 0.4)
		_mat_pion.set_shader_parameter("lisere", 0.0)
		mi.material_override = _mat_pion
		_pion.add_child(mi)
	var larme := OmniLight3D.new()
	larme.light_color = COULEUR_LARME
	larme.light_energy = 2.0
	larme.omni_range = 5.5
	larme.position = Vector3(0.4, 1.8, 0.8)
	_pion.add_child(larme)
	var chaude := OmniLight3D.new()
	chaude.light_color = Color(1.0, 0.75, 0.5)
	chaude.light_energy = 0.8
	chaude.omni_range = 9.0
	chaude.position = Vector3(-1.2, 3.0, 2.0)
	_pion.add_child(chaude)


## À côté de la dalle (le boss est au centre), un peu devant.
func _place_pion(a: int) -> Vector3:
	return pos(a) + Vector3(-R_DALLE * 1.15, 0.0, R_DALLE * 0.55)


func _placer_pion(a: int) -> void:
	_pion.position = _place_pion(a)
	if _mat_pion:
		_mat_pion.set_shader_parameter("penche", 0.0)
		_mat_pion.set_shader_parameter("ecrase", 0.0)


func pion_acte() -> int:
	return _pion_acte


func en_marche() -> bool:
	return _marche


## Le pion marche jusqu'à l'Acte b, Acte après Acte le long de la route.
func marcher_vers(b: int) -> void:
	if _marche or b == _pion_acte:
		return
	_marche = true
	var sens := 1 if b > _pion_acte else -1
	var a := _pion_acte
	while a != b:
		var suivant := a + sens
		var depart := _pion.position
		var arrivee := _place_pion(suivant)
		var l := longueur_route(a, suivant)
		var duree := clampf(l / 9.0, 0.45, 1.1)
		var nb_pas := maxi(3, int(round(l / 1.1)))
		var tw := create_tween()
		var de := a
		tw.tween_method(func(t: float):
			var p := point_route(de, suivant, t)
			# Quitter sa place près de la dalle, suivre la route, puis se ranger près de la suivante
			var ecart := depart - pos(de)
			var ecart2 := arrivee - pos(suivant)
			p += ecart.lerp(ecart2, t) * (1.0 - sin(t * PI) * 0.8)
			var phase := t * nb_pas
			p.y = absf(sin(phase * PI)) * 0.22
			_pion.position = p
			if _mat_pion:
				var dir := point_route(de, suivant, minf(1.0, t + 0.03)) - point_route(de, suivant, maxf(0.0, t - 0.03))
				var ecran := _camera.unproject_position(p + dir) - _camera.unproject_position(p)
				if absf(ecran.x) > 1.0:
					_mat_pion.set_shader_parameter("retourne", 1.0 if ecran.x < 0.0 else 0.0)
				_mat_pion.set_shader_parameter("penche", sin(phase * TAU) * 0.06)
			_cible_voulue = p, 0.0, 1.0, duree)
		await tw.finished
		a = suivant
		_pion_acte = a
	acte_pion = _pion_acte
	_placer_pion(_pion_acte)
	_marche = false


# ---------------------------------------------------------------
# Caméra
# ---------------------------------------------------------------

func viser(a: int) -> void:
	if not _marche:
		_cible_voulue = pos(a)


func _process(delta: float) -> void:
	if _camera == null:
		return
	_temps += delta
	if _mat_sceau:
		var pulse := 0.5 + 0.5 * sin(_temps * (3.0 if _force_stele >= 3 else 1.6))
		_mat_sceau.emission_energy_multiplier = (0.6 + 0.5 * _force_stele) * (0.6 + 0.4 * pulse)
		if _lumiere_stele:
			_lumiere_stele.light_energy = (0.4 + 0.6 * _force_stele) * (0.7 + 0.3 * pulse)
	if _mat_brume:
		_mat_brume.set_shader_parameter("temps", _temps)
	for a in _routes:
		(_routes[a]["mat"] as ShaderMaterial).set_shader_parameter("defile", _temps * 0.35)
	if not _plongee:
		_cible_cam = _cible_cam.lerp(_cible_voulue, 1.0 - exp(-4.0 * delta))
		_maj_camera()
	var cam := _camera.global_position
	for a in _actes:
		var fig: MeshInstance3D = _actes[a]["fig"]
		if fig:
			_tourner_vers(fig, cam)
	if _pion:
		_tourner_vers(_pion, cam)


func _tourner_vers(n: Node3D, cam: Vector3) -> void:
	var d := cam - n.global_position
	n.rotation.y = atan2(d.x, d.z)


## Décalage (mètres) pour que le point visé tombe à centre_ecran de la largeur de l'écran.
func _decalage_x(distance: float) -> float:
	var aspect := size.x / maxf(1.0, size.y)
	var largeur_vue := 2.0 * distance * tan(deg_to_rad(_camera.fov) / 2.0) * aspect
	return (0.5 - centre_ecran) * largeur_vue


func _maj_camera() -> void:
	var d := Vector3(0, 15.0, 11.5) * _zoom
	var dx := _decalage_x(d.length())
	# Près du bord nord, on ne recule pas la vue au-delà de la carte (sinon on voit surtout la table)
	var c := _cible_cam
	c.z = clampf(c.z, -_hauteur * 0.5 + 4.5 * _zoom, _hauteur * 0.5 - 2.0)
	var vise := c + Vector3(dx, 0.4, -0.6)
	_camera.position = vise + d
	_camera.look_at(vise, Vector3.UP)


func zoomer(facteur: float) -> void:
	_zoom = clampf(_zoom / facteur, 0.55, 1.6)


func glisser(relatif: Vector2) -> void:
	_cible_voulue += Vector3(-relatif.x, 0, -relatif.y) * 0.028 * _zoom
	_cible_voulue.x = clampf(_cible_voulue.x, -LARGEUR * 0.5, LARGEUR * 0.5)
	_cible_voulue.z = clampf(_cible_voulue.z, -_hauteur * 0.5, _hauteur * 0.5)


## Avant d'ouvrir un plateau : la caméra plonge vers l'Acte.
func plongee(a: int) -> void:
	_plongee = true
	var cible := pos(a) + Vector3(0, 0.8, 0)
	var depart := _camera.position
	var fov0 := _camera.fov
	var tw := create_tween()
	tw.tween_method(func(t: float):
		_camera.position = depart.lerp(cible + Vector3(-1.2, 1.4, 2.6), t)
		_camera.look_at(cible, Vector3.UP)
		_camera.fov = lerpf(fov0, 28.0, t), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


# ---------------------------------------------------------------
# Toucher
# ---------------------------------------------------------------

func _ecran(p: Vector3) -> Vector2:
	if _camera.is_position_behind(p):
		return Vector2(-99999, -99999)
	var t := Vector2(_vp.size)
	return _camera.unproject_position(p) * Vector2(size.x / maxf(1.0, t.x), size.y / maxf(1.0, t.y))


## Acte sous le point de l'écran (dalle, boss ou numéro), -1 si aucun.
func acte_a_ecran(p: Vector2) -> int:
	var meilleur := -1
	var dmin := 58.0 * clampf(size.y / 720.0, 0.8, 2.0)
	if _stele:
		for h in [0.3, 1.0]:
			if p.distance_to(_ecran(_stele_pos + Vector3(0, h, 0))) < dmin:
				return STELE
	for a in _actes:
		for h in [0.1, 0.9, 1.5]:
			var d := p.distance_to(_ecran(pos(a) + Vector3(0, h, 0)))
			if d < dmin:
				dmin = d
				meilleur = a
	return meilleur


# ---------------------------------------------------------------
# Stèle du Sceau de l'Aube (Ruines Oubliées)
# ---------------------------------------------------------------

## uv : position sur la carte peinte (0..1) ; fragments : 1 à 3 (3 = Ruines ouvertes).
func creer_stele(uv: Vector2, fragments: int) -> void:
	_force_stele = fragments
	_stele_pos = Vector3((uv.x - 0.5) * LARGEUR, 0.0, (uv.y - 0.5) * _hauteur)
	_stele = Node3D.new()
	_stele.position = _stele_pos
	_monde.add_child(_stele)
	var pierre := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.7, 1.4, 0.22)
	pierre.mesh = b
	pierre.position.y = 0.7
	pierre.rotation.y = 0.35
	var mp := StandardMaterial3D.new()
	mp.albedo_color = Color(0.2, 0.19, 0.18)
	mp.roughness = 0.95
	pierre.material_override = mp
	_stele.add_child(pierre)
	var socle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.58
	cyl.height = 0.1
	socle.mesh = cyl
	socle.position.y = 0.05
	socle.material_override = mp
	_stele.add_child(socle)
	# Le Sceau gravé : un soleil levant derrière une cloche, qui luit selon le nombre de fragments
	var sceau := Label3D.new()
	sceau.text = "☀"
	sceau.font_size = 110
	sceau.pixel_size = 0.0055
	if ResourceLoader.exists("res://assets/polices/symboles.ttf"):
		sceau.font = load("res://assets/polices/symboles.ttf")
	sceau.outline_size = 0
	sceau.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sceau.position = Vector3(0, 0.95, 0.0) + Vector3(sin(0.35), 0, cos(0.35)) * 0.115
	sceau.rotation.y = 0.35
	sceau.shaded = false
	sceau.modulate = Color(1.0, 0.85, 0.45)
	_stele.add_child(sceau)
	var halo := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.6
	t.outer_radius = 0.7
	halo.mesh = t
	halo.scale = Vector3(1, 0.4, 1)
	halo.position.y = 0.04
	_mat_sceau = StandardMaterial3D.new()
	_mat_sceau.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_sceau.albedo_color = Color(1.0, 0.82, 0.4)
	_mat_sceau.emission_enabled = true
	_mat_sceau.emission = Color(1.0, 0.78, 0.35)
	halo.material_override = _mat_sceau
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stele.add_child(halo)
	_lumiere_stele = OmniLight3D.new()
	_lumiere_stele.light_color = Color(1.0, 0.8, 0.45)
	_lumiere_stele.omni_range = 3.5
	_lumiere_stele.position = Vector3(0.3, 1.3, 0.6)
	_stele.add_child(_lumiere_stele)


func viser_stele() -> void:
	if _stele and not _marche:
		_cible_voulue = _stele_pos
