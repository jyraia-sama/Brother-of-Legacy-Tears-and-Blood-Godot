class_name EffetInvocation
extends Control
## EFFET D'INVOCATION : les cartes apparaissent face cachée, puis se retournent.
## Plus la carte est rare, plus l'effet est impressionnant :
##   N   : simple retournement
##   R   : lueur + étincelles
##   SR  : aura violette qui pulse
##   SSR : rayons de lumière dorés qui tournent, tremblement, flash
##   UR  : + éclairs qui frappent la carte, onde de choc, flash rouge
##   LÉGENDE : + halo divin, rayons blancs, bandeau « HÉROS DE LÉGENDE »
##
## Les images (facultatives) se mettent dans res://assets/invocation/ (voir PROMPTS_INVOCATION.md).
## Sans image, les effets sont dessinés par le code.
##
##   var e := EffetInvocation.new()
##   e.resultats = res          # retour de Invocation.invoquer()
##   parent.add_child(e)
##   await e.termine

signal termine
signal voir_fiche(id: String)

const DOSSIER := "res://assets/invocation/"
const TEX_DOS := DOSSIER + "dos_carte.png"
const TEX_CERCLE := DOSSIER + "cercle_invocation.png"
const TEX_RAYONS := DOSSIER + "rayons.png"
const TEX_HALO := DOSSIER + "halo.png"
const TEX_ECLAIR := DOSSIER + "eclair.png"
const TEX_ETINCELLE := DOSSIER + "etincelle.png"

const NIVEAU := {"N": 0, "R": 1, "SR": 2, "SSR": 3, "UR": 4, "LEG": 5}
const CRI := {"SSR": "SSR !", "UR": "ULTRA RARE !!", "LEG": "HÉROS DE LÉGENDE !!!"}
## Bruitage de révélation selon la rareté (voir audio.gd).
const SON_RARETE := {"SR": "rare_sr", "SSR": "rare_ssr", "UR": "rare_ur", "LEG": "legende"}
const GRANDE := Vector2(236, 360)
const PETITE := Vector2(140, 214)

var resultats: Array = []
var _passer := false
var _scene: Control           # tout ce qui tremble
var _fond: ColorRect
var _cercle: Control
var _btn_passer: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fond = ColorRect.new()
	_fond.color = Color(0.02, 0.0, 0.01, 0.0)
	_fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fond)
	_scene = Control.new()
	_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scene)
	_btn_passer = UiCommun.bouton("Tout révéler ▶▶", 16)
	_btn_passer.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_btn_passer.position = Vector2(-220, 20)
	_btn_passer.custom_minimum_size = Vector2(190, 42)
	_btn_passer.pressed.connect(func(): _passer = true)
	add_child(_btn_passer)
	await get_tree().process_frame
	_lancer()


# =====================================================================
# Déroulement
# =====================================================================

func _lancer() -> void:
	var tw := create_tween()
	tw.tween_property(_fond, "color:a", 0.88, 0.35)
	var max_niveau := 0
	for r in resultats:
		max_niveau = maxi(max_niveau, int(NIVEAU[r["rarete"]]))
	var centre := size / 2.0
	Audio.son("cercle")

	# 1) Cercle d'invocation : il tourne, grandit, et « annonce » la meilleure rareté
	_cercle = _creer_cercle(centre + Vector2(0, 30), 520.0)
	_cercle.scale = Vector2.ZERO
	_scene.add_child(_cercle)
	var tc := create_tween()
	tc.tween_property(_cercle, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var rot := create_tween().set_loops()
	rot.tween_property(_cercle, "rotation", TAU, 8.0).as_relative()
	await _attendre(0.7)
	if max_niveau >= 2:
		# Suspense : le cercle change de couleur si quelque chose de rare arrive
		var ct := create_tween()
		ct.tween_property(_cercle, "modulate", _couleur(_rarete_de_niveau(max_niveau)).lightened(0.2), 0.5)
		if max_niveau >= 4:
			_flash(Color(1, 1, 1, 0.5), 0.4)
			_trembler(6.0, 0.3)
		await _attendre(0.6)

	# 2) Les cartes
	if resultats.size() == 1:
		var dos := _creer_dos(GRANDE, centre)
		_scene.add_child(dos)
		await _apparition(dos, centre)
		await _reveler(resultats[0], dos, centre, GRANDE, true)
	else:
		var positions := _grille(resultats.size())
		var dos_liste: Array = []
		for i in resultats.size():
			var d := _creer_dos(PETITE, centre)
			_scene.add_child(d)
			dos_liste.append(d)
			_distribuer(d, centre, positions[i], i)
		Audio.son("carte")
		Audio.son_apres("carte", 0.06 * resultats.size() * 0.5)
		await _attendre(0.25 + 0.06 * resultats.size())
		for i in resultats.size():
			await _reveler(resultats[i], dos_liste[i], positions[i], PETITE, false)

	# 3) Fin
	var ft := create_tween()
	ft.tween_property(_cercle, "modulate:a", 0.25, 0.5)
	_btn_passer.visible = false
	var bas := VBoxContainer.new()
	bas.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bas.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bas.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bas.position.y -= 30
	bas.add_theme_constant_override("separation", 8)
	add_child(bas)
	var aide := UiCommun.label("Clique une carte pour voir sa fiche", 15, UiCommun.C_DOUX)
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bas.add_child(aide)
	var ok := UiCommun.bouton("Continuer", 18)
	ok.custom_minimum_size = Vector2(240, 48)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func():
		termine.emit()
		queue_free())
	bas.add_child(ok)


func _grille(n: int) -> Array:
	var colonnes := mini(5, n)
	var lignes := int(ceil(n / float(colonnes)))
	var ecart := Vector2(24, 26)
	var total := Vector2(colonnes * PETITE.x + (colonnes - 1) * ecart.x, lignes * PETITE.y + (lignes - 1) * ecart.y)
	var origine := size / 2.0 - total / 2.0 + PETITE / 2.0 - Vector2(0, 20)
	var l: Array = []
	for i in n:
		l.append(origine + Vector2((i % colonnes) * (PETITE.x + ecart.x), int(i / float(colonnes)) * (PETITE.y + ecart.y)))
	return l


func _apparition(dos: Control, pos: Vector2) -> void:
	dos.scale = Vector2(0.1, 0.1)
	dos.modulate.a = 0.0
	dos.position = pos - dos.size / 2.0 + Vector2(0, -120)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dos, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(dos, "modulate:a", 1.0, 0.3)
	tw.tween_property(dos, "position", pos - dos.size / 2.0, 0.45).set_trans(Tween.TRANS_SINE)
	_eclats(pos, Color("ffe0a0"), 18, 1)
	await _attendre(0.5)


func _distribuer(dos: Control, depuis: Vector2, vers: Vector2, i: int) -> void:
	dos.position = depuis - dos.size / 2.0
	dos.scale = Vector2(0.2, 0.2)
	dos.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_interval(0.06 * i)
	tw.chain().set_parallel(true)
	tw.tween_property(dos, "position", vers - dos.size / 2.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dos, "scale", Vector2.ONE, 0.35)
	tw.tween_property(dos, "modulate:a", 1.0, 0.2)
	tw.tween_property(dos, "rotation", TAU * 0.0 + randf_range(-0.05, 0.05), 0.35)


## Effets de rareté puis retournement de la carte.
func _reveler(r: Dictionary, dos: Control, pos: Vector2, taille: Vector2, solo: bool) -> void:
	var rarete: String = r["rarete"]
	var n: int = NIVEAU[rarete]
	var c := _couleur(rarete)
	var facteur := 1.0 if solo else 0.55
	var effets: Array = []        # nœuds à retirer ensuite
	if SON_RARETE.has(rarete) and (not _passer or n >= 3):
		Audio.son(SON_RARETE[rarete])

	if n >= 1:
		var lueur := _lueur(pos, taille.y * (0.9 + 0.2 * n), c)
		_scene.add_child(lueur)
		_scene.move_child(lueur, dos.get_index())
		lueur.modulate.a = 0.0
		create_tween().tween_property(lueur, "modulate:a", 0.55 + 0.08 * n, 0.3)
		effets.append(lueur)
	if n >= 2:
		var aura := _aura(pos, taille, c)
		_scene.add_child(aura)
		effets.append(aura)
		var pulse := create_tween().set_loops(3)
		dos.pivot_offset = dos.size / 2.0
		pulse.tween_property(dos, "scale", Vector2(1.06, 1.06), 0.12)
		pulse.tween_property(dos, "scale", Vector2.ONE, 0.12)
		await _attendre(0.35 * facteur)
	if n >= 3:
		var rayons := _rayons(pos, taille.y * 2.2, c.lightened(0.3) if n < 5 else Color(1, 0.97, 0.85), 14 + 2 * n)
		_scene.add_child(rayons)
		_scene.move_child(rayons, 0)
		rayons.scale = Vector2.ZERO
		var tr := create_tween().set_parallel(true)
		tr.tween_property(rayons, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
		var tr2 := create_tween().set_loops()
		tr2.tween_property(rayons, "rotation", TAU, 6.0 - n).as_relative()
		effets.append(rayons)
		_trembler(5.0 + 3.0 * (n - 3), 0.35)
		await _attendre(0.45 * facteur)
	if n >= 4:
		for k in (3 if solo else 2):
			_eclair(pos, Color("ffe8ff") if n >= 5 else Color("ff6a5a"))
			_trembler(10.0, 0.18)
			await _attendre(0.16)
		_onde(pos, c)
		_flash(Color(1, 0.3, 0.2, 0.45) if n == 4 else Color(1, 1, 0.9, 0.7), 0.5)
		await _attendre(0.3 * facteur)
	if n >= 5:
		var halo := _halo(pos + Vector2(0, -taille.y * 0.62), taille.x * 0.9)
		_scene.add_child(halo)
		halo.modulate.a = 0.0
		var th := create_tween()
		th.tween_property(halo, "modulate:a", 1.0, 0.5)
		effets.append(halo)
		await _attendre(0.5 * facteur)

	# Retournement
	Audio.son("carte")
	dos.pivot_offset = dos.size / 2.0
	var tf := create_tween()
	tf.tween_property(dos, "scale", Vector2(0.0, 1.05), 0.14 if not _passer else 0.05)
	await tf.finished
	var h := Sauvegarde.get_heros(int(r["uid"]))
	var face := UiCommun.carte_heros(h, taille.x, taille.y)
	face.add_theme_stylebox_override("normal", UiCommun.style_carte(c, 0.02, 4 if n >= 3 else 3))
	face.position = pos - taille / 2.0
	face.size = taille
	face.pivot_offset = taille / 2.0
	face.scale = Vector2(0.0, 1.05)
	if r.get("nouveau", false):
		UiCommun.badge(face, "NOUVEAU", Color("8aff9a"))
	face.pressed.connect(func(): voir_fiche.emit(r["id"]))
	_scene.add_child(face)
	dos.queue_free()
	var tf2 := create_tween()
	tf2.tween_property(face, "scale", Vector2.ONE, 0.18 if not _passer else 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_eclats(pos, c, 10 + 16 * n, 1.0 + 0.3 * n)
	if n >= 3:
		face.modulate = Color(2.0, 1.9, 1.6)
		create_tween().tween_property(face, "modulate", Color.WHITE, 0.6)
		_cri(CRI[rarete], pos + Vector2(0, -taille.y * 0.5 - (70 if n >= 5 else 30)), c, solo)
	if solo:
		var u := UnitesData.get_unite(r["id"])
		var nom := UiCommun.label(u["nom"], 30, c.lightened(0.25))
		nom.add_theme_color_override("font_outline_color", Color.BLACK)
		nom.add_theme_constant_override("outline_size", 8)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.custom_minimum_size = Vector2(700, 0)
		nom.position = pos + Vector2(-350, taille.y * 0.5 + 16)
		_scene.add_child(nom)
		var sous := UiCommun.label("%s · %s · %s" % [UiCommun.texte_rarete(r["id"]), UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]]], 17, UiCommun.C_TEXTE)
		sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sous.custom_minimum_size = Vector2(700, 0)
		sous.position = pos + Vector2(-350, taille.y * 0.5 + 56)
		_scene.add_child(sous)
	await _attendre((0.35 + 0.25 * n) * facteur)
	# Les effets s'estompent (sauf en invocation simple où ils restent derrière la carte)
	if not solo:
		for e in effets:
			if is_instance_valid(e):
				var fe := create_tween()
				fe.tween_property(e, "modulate:a", 0.0 if n < 3 else 0.35, 0.4)


# =====================================================================
# Éléments visuels (image si fournie, sinon dessin)
# =====================================================================

func _creer_dos(taille: Vector2, pos: Vector2) -> Control:
	var d: Control
	if ResourceLoader.exists(TEX_DOS):
		var t := TextureRect.new()
		t.texture = load(TEX_DOS)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		d = t
	else:
		var p := Panel.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color("2a0a10")
		st.border_color = UiCommun.C_OR
		st.set_border_width_all(4)
		st.set_corner_radius_all(12)
		p.add_theme_stylebox_override("panel", st)
		var motif := UiCommun.label("✦", int(taille.y * 0.35), Color(UiCommun.C_OR, 0.8))
		motif.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		motif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		motif.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(motif)
		var cadre := Panel.new()
		var st2 := StyleBoxFlat.new()
		st2.bg_color = Color(0, 0, 0, 0)
		st2.border_color = Color("8a1a20")
		st2.set_border_width_all(2)
		st2.set_corner_radius_all(8)
		cadre.add_theme_stylebox_override("panel", st2)
		cadre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for c in ["left", "top"]:
			cadre.set("offset_" + c, 10)
		for c in ["right", "bottom"]:
			cadre.set("offset_" + c, -10)
		cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(cadre)
		d = p
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.size = taille
	d.custom_minimum_size = taille
	d.position = pos - taille / 2.0
	d.pivot_offset = taille / 2.0
	return d


func _creer_cercle(pos: Vector2, diametre: float) -> Control:
	var c: Control
	if ResourceLoader.exists(TEX_CERCLE):
		var t := TextureRect.new()
		t.texture = load(TEX_CERCLE)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c = t
	else:
		var a := Anneau.new()
		a.couleur = Color(1.0, 0.85, 0.6, 0.55)
		c = a
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size = Vector2(diametre, diametre)
	c.position = pos - c.size / 2.0
	c.pivot_offset = c.size / 2.0
	return c


func _lueur(pos: Vector2, diametre: float, couleur: Color) -> Control:
	var l := Lueur.new()
	l.couleur = couleur
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(diametre, diametre)
	l.position = pos - l.size / 2.0
	return l


func _rayons(pos: Vector2, diametre: float, couleur: Color, nombre: int) -> Control:
	var r: Control
	if ResourceLoader.exists(TEX_RAYONS):
		var t := TextureRect.new()
		t.texture = load(TEX_RAYONS)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.modulate = couleur
		r = t
	else:
		var d := Rayons.new()
		d.couleur = couleur
		d.nombre = nombre
		r = d
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = Vector2(diametre, diametre)
	r.position = pos - r.size / 2.0
	r.pivot_offset = r.size / 2.0
	return r


func _halo(pos: Vector2, largeur: float) -> Control:
	var h: Control
	if ResourceLoader.exists(TEX_HALO):
		var t := TextureRect.new()
		t.texture = load(TEX_HALO)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h = t
		h.size = Vector2(largeur * 1.4, largeur * 0.6)
	else:
		var d := Halo.new()
		h = d
		h.size = Vector2(largeur, largeur * 0.35)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.position = pos - h.size / 2.0
	var tw := create_tween().set_loops()
	tw.tween_property(h, "position:y", h.position.y - 6, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(h, "position:y", h.position.y, 1.0).set_trans(Tween.TRANS_SINE)
	return h


## Particules qui tournent autour de la carte (SR et plus).
func _aura(pos: Vector2, taille: Vector2, couleur: Color) -> CPUParticles2D:
	var p := _particules(couleur, 40)
	p.position = pos
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = taille / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 30.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 40.0
	p.lifetime = 1.4
	return p


## Explosion de particules.
func _eclats(pos: Vector2, couleur: Color, nombre: int, force: float) -> void:
	if nombre <= 0:
		return
	var p := _particules(couleur, nombre)
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 30.0
	p.spread = 180.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 140.0 * force
	p.initial_velocity_max = 360.0 * force
	p.lifetime = 1.2
	_scene.add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _particules(couleur: Color, nombre: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = nombre
	if ResourceLoader.exists(TEX_ETINCELLE):
		p.texture = load(TEX_ETINCELLE)
		p.scale_amount_min = 0.04
		p.scale_amount_max = 0.1
	else:
		p.scale_amount_min = 3.0
		p.scale_amount_max = 7.0
	var fondu := Gradient.new()
	fondu.set_color(0, couleur.lightened(0.4))
	fondu.set_color(1, Color(couleur, 0.0))
	p.color_ramp = fondu
	return p


## Éclair qui s'abat sur la carte (UR et plus).
func _eclair(cible: Vector2, couleur: Color) -> void:
	if ResourceLoader.exists(TEX_ECLAIR):
		var t := TextureRect.new()
		t.texture = load(TEX_ECLAIR)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_SCALE
		t.size = Vector2(160, cible.y)
		t.position = Vector2(cible.x - 80 + randf_range(-60, 60), 0)
		t.modulate = couleur
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_scene.add_child(t)
		var tw := create_tween()
		tw.tween_property(t, "modulate:a", 0.0, 0.35)
		tw.tween_callback(t.queue_free)
		return
	var depart := Vector2(cible.x + randf_range(-260, 260), -20)
	var pts := PackedVector2Array([depart])
	var etapes := 9
	for i in range(1, etapes):
		var t2 := i / float(etapes)
		pts.append(depart.lerp(cible, t2) + Vector2(randf_range(-40, 40), randf_range(-10, 10)))
	pts.append(cible)
	for couche in [[14.0, Color(couleur, 0.45)], [5.0, Color(1, 1, 1, 0.95)]]:
		var l := Line2D.new()
		l.points = pts
		l.width = couche[0]
		l.default_color = couche[1]
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		_scene.add_child(l)
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 0.35)
		tw.tween_callback(l.queue_free)


## Onde de choc qui s'élargit.
func _onde(pos: Vector2, couleur: Color) -> void:
	var a := Anneau.new()
	a.couleur = couleur.lightened(0.3)
	a.epaisseur = 10.0
	a.simple = true
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.size = Vector2(120, 120)
	a.position = pos - a.size / 2.0
	a.pivot_offset = a.size / 2.0
	_scene.add_child(a)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(a, "scale", Vector2(9, 9), 0.6).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(a.queue_free)


func _flash(couleur: Color, duree: float) -> void:
	if _passer:
		return
	var f := ColorRect.new()
	f.color = couleur
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	var tw := create_tween()
	tw.tween_property(f, "color:a", 0.0, duree)
	tw.tween_callback(f.queue_free)


func _trembler(force: float, duree: float) -> void:
	if _passer:
		return
	var tw := create_tween()
	var n := int(duree / 0.03)
	for k in n:
		tw.tween_property(_scene, "position", Vector2(randf_range(-force, force), randf_range(-force, force)), 0.03)
	tw.tween_property(_scene, "position", Vector2.ZERO, 0.03)


func _cri(texte: String, pos: Vector2, couleur: Color, grand: bool) -> void:
	var l := UiCommun.label(texte, 40 if grand else 24, couleur.lightened(0.3))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(600, 0)
	l.position = pos - Vector2(300, 30)
	l.pivot_offset = Vector2(300, 30)
	l.scale = Vector2(0.3, 0.3)
	_scene.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(l, "scale", Vector2.ONE, 0.15)
	if not grand:
		tw.tween_interval(0.8)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)
		tw.tween_callback(l.queue_free)


func _attendre(s: float) -> void:
	if _passer or s <= 0.0:
		await get_tree().process_frame
		return
	await get_tree().create_timer(s).timeout


func _couleur(rarete: String) -> Color:
	return UiCommun.COULEURS_RARETE.get(rarete, Color.WHITE)


func _rarete_de_niveau(n: int) -> String:
	for r in NIVEAU:
		if int(NIVEAU[r]) == n:
			return r
	return "N"


# =====================================================================
# Dessins (utilisés quand aucune image n'est fournie)
# =====================================================================

class Anneau extends Control:
	var couleur := Color.WHITE
	var epaisseur := 3.0
	var simple := false

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - epaisseur
		draw_arc(c, r, 0.0, TAU, 96, couleur, epaisseur, true)
		if simple:
			return
		draw_arc(c, r * 0.82, 0.0, TAU, 96, Color(couleur, couleur.a * 0.7), epaisseur * 0.7, true)
		draw_arc(c, r * 0.45, 0.0, TAU, 64, Color(couleur, couleur.a * 0.6), epaisseur * 0.6, true)
		# Étoile à 6 branches et runes
		var pts: Array = []
		for i in 6:
			var a := TAU * i / 6.0 - PI / 2.0
			pts.append(c + Vector2(cos(a), sin(a)) * r * 0.82)
		for i in 6:
			draw_line(pts[i], pts[(i + 2) % 6], Color(couleur, couleur.a * 0.8), epaisseur * 0.6, true)
		for i in 24:
			var a := TAU * i / 24.0
			var p1: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.86
			var p2: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.96
			draw_line(p1, p2, couleur, epaisseur * 0.5, true)


class Lueur extends Control:
	var couleur := Color.WHITE

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		for i in 12:
			var k := 1.0 - i / 12.0
			draw_circle(c, r * k, Color(couleur, 0.05 + 0.02 * i))


class Rayons extends Control:
	var couleur := Color.WHITE
	var nombre := 16

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		for i in nombre:
			var a := TAU * i / nombre
			var l := 0.06 if i % 2 == 0 else 0.035
			var p1 := c + Vector2(cos(a - l), sin(a - l)) * r
			var p2 := c + Vector2(cos(a + l), sin(a + l)) * r
			draw_polygon(PackedVector2Array([c, p1, p2]),
				PackedColorArray([Color(couleur, 0.75), Color(couleur, 0.0), Color(couleur, 0.0)]))


class Halo extends Control:
	func _draw() -> void:
		var c := size / 2.0
		for i in 8:
			var k := 1.0 + i * 0.06
			var pts := PackedVector2Array()
			for j in 65:
				var a := TAU * j / 64.0
				pts.append(c + Vector2(cos(a) * size.x * 0.45 * k, sin(a) * size.y * 0.4 * k))
			draw_polyline(pts, Color(1.0, 0.95, 0.7, 0.9 - i * 0.11), 6.0 - i * 0.6, true)
