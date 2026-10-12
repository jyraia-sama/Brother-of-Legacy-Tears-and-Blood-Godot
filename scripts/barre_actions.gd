class_name BarreActions
extends PanelContainer
## BARRE D'ACTIONS des combats manuels (combat manuel contre l'ordinateur et Arène classée).
##
## Une rangée d'icônes en bas de l'écran : l'attaque normale puis les sorts de l'unité qui joue.
## Survol (ou 1er toucher sur téléphone) : une bulle détaille le sort. Clic : l'action est choisie ;
## si elle demande une cible, les cibles possibles s'entourent de rouge sur le champ de bataille.
##
##   var barre := BarreActions.new(ecran)          # ecran = EcranCombat
##   ecran.add_child(barre)
##   var choix: Dictionary = await barre.choisir(c, moteur.actions_possibles(c))
##     -> {"type": "attaque"|"skill"|"auto", "skill": nom, "cible": idx ou -1}  ({} si fermée de force)

var ecran: EcranCombat
var minuteur := 0.0                 # > 0 : temps pour choisir (Arène classée), sinon illimité

var _lbl_titre: Label
var _lbl_info: Label
var _barre_temps: ProgressBar
var _rangee: HBoxContainer
var _bulle: Control = null
var _boutons_cibles: Array = []
var _halo: Panel
var _choix := {}
var _ouvert := false
var _selection := ""                # tactile : icône touchée une 1re fois (détails affichés)
var _c := {}


func _init(e: EcranCombat) -> void:
	ecran = e
	mouse_filter = Control.MOUSE_FILTER_STOP
	var st := UiCommun.style_panneau(UiCommun.C_OR, Color(0.06, 0.02, 0.03, 0.92))
	st.set_content_margin_all(10)
	add_theme_stylebox_override("panel", st)
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -8
	visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 18)
	vb.add_child(tete)
	_lbl_titre = UiCommun.label("", 20, UiCommun.C_OR)
	_lbl_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(_lbl_titre)
	_lbl_info = UiCommun.label("", 16, Color("ffe0a0"))
	tete.add_child(_lbl_info)
	_barre_temps = UiCommun.barre(Color("ffb040"), 0, 6)
	_barre_temps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barre_temps.visible = false
	vb.add_child(_barre_temps)
	_rangee = HBoxContainer.new()
	_rangee.add_theme_constant_override("separation", 14)
	_rangee.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_rangee)


## Attend le choix du joueur pour l'unité c.
func choisir(c: Dictionary, actions: Array) -> Dictionary:
	_c = c
	_choix = {}
	_ouvert = true
	_selection = ""
	montrer_halo(int(c["idx"]))
	_lbl_titre.text = UiCommun.t("À toi : %s") % c["nom"]
	info("Choisis une action." if not SortsIcones.tactile() else "Touche une icône pour voir le sort, touche-la encore pour la lancer.")
	_vider()
	for a in actions:
		var sk := _sort(c, str(a.get("nom", ""))) if a["type"] == "skill" else {}
		var b := SortsIcones.bouton(a, sk, str(c.get("element", "neutre")))
		b.mouse_entered.connect(_montrer_bulle.bind(b, a, sk))
		b.mouse_exited.connect(func(): if not SortsIcones.tactile(): _cacher_bulle())
		b.gui_input.connect(_clic_icone.bind(b, a, sk))
		_rangee.add_child(b)
	visible = true
	_barre_temps.visible = minuteur > 0.0
	_barre_temps.max_value = maxf(minuteur, 0.01)
	var reste := minuteur
	while _choix.is_empty() and _ouvert:
		await get_tree().process_frame
		if minuteur > 0.0:
			reste -= get_process_delta_time()
			_barre_temps.value = maxf(0.0, reste)
			if reste <= 0.0:
				_choix = {"type": "auto"}
				info("Temps écoulé : action automatique.")
	var r := _choix
	fermer()
	return r


## Choix automatique immédiat (bouton « Auto » pendant que la barre attend).
func forcer_auto() -> void:
	if _ouvert:
		_choix = {"type": "auto"}


## Affichage sans choix (tour de l'adversaire en Arène classée).
func attente(titre: String, idx: int) -> void:
	montrer_halo(idx)
	_lbl_titre.text = titre
	_vider()
	_barre_temps.visible = false
	visible = true


func fermer() -> void:
	_ouvert = false
	_effacer_cibles()
	_cacher_bulle()
	visible = false
	if _halo != null:
		_halo.visible = false


func info(t: String) -> void:
	_lbl_info.text = t


# ---------------------------------------------------------------------

func _vider() -> void:
	_cacher_bulle()
	for b in _rangee.get_children():
		b.queue_free()


func _sort(c: Dictionary, nom: String) -> Dictionary:
	for sk in c.get("actifs", []):
		if sk["nom"] == nom:
			return sk
	return {}


func _clic_icone(ev: InputEvent, b: Control, a: Dictionary, sk: Dictionary) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _ouvert:
		return
	var cle := str(a.get("nom", ""))
	if SortsIcones.tactile() and _selection != cle:
		# 1er toucher : on montre seulement les détails
		_selection = cle
		_montrer_bulle(b, a, sk)
		return
	if not a.get("dispo", true):
		_montrer_bulle(b, a, sk)
		return
	_cacher_bulle()
	_choisir_action(a)


func _choisir_action(a: Dictionary) -> void:
	_effacer_cibles()
	var cibles: Array = a["cibles"]
	if cibles.size() <= 1:
		_choix = {"type": a["type"], "skill": a["nom"], "cible": int(cibles[0]) if cibles.size() == 1 else -1}
		return
	info(UiCommun.t("%s : choisis une cible.") % a["nom"])
	for idx in cibles:
		if not ecran._cartes.has(int(idx)):
			continue
		var racine: Control = ecran._cartes[int(idx)]["racine"]
		var bt := Button.new()
		bt.focus_mode = Control.FOCUS_NONE
		bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 0.2, 0.1, 0.12)
		st.border_color = Color("ff5a3a")
		st.set_border_width_all(3)
		st.set_corner_radius_all(12)
		bt.add_theme_stylebox_override("normal", st)
		var st2 := st.duplicate() as StyleBoxFlat
		st2.bg_color = Color(1, 0.3, 0.1, 0.3)
		bt.add_theme_stylebox_override("hover", st2)
		bt.add_theme_stylebox_override("pressed", st2)
		bt.position = racine.position - Vector2(6, 6)
		bt.size = racine.size + Vector2(12, 12)
		var i := int(idx)
		bt.pressed.connect(func(): _choix = {"type": a["type"], "skill": a["nom"], "cible": i})
		ecran._arene.add_child(bt)
		_boutons_cibles.append(bt)


func _effacer_cibles() -> void:
	for b in _boutons_cibles:
		if is_instance_valid(b):
			b.queue_free()
	_boutons_cibles.clear()


func _montrer_bulle(b: Control, a: Dictionary, sk: Dictionary) -> void:
	_cacher_bulle()
	_bulle = SortsIcones.bulle(SortsIcones.detail(a, sk))
	ecran.add_child(_bulle)
	_bulle.reset_size()
	await get_tree().process_frame
	if _bulle == null or not is_instance_valid(_bulle) or not is_instance_valid(b):
		return
	var taille := _bulle.get_combined_minimum_size()
	_bulle.size = taille
	var r := b.get_global_rect()
	var ecr := ecran.get_viewport_rect().size
	var x := clampf(r.get_center().x - taille.x / 2.0, 8.0, ecr.x - taille.x - 8.0)
	var y := maxf(8.0, global_position.y - taille.y - 8.0)
	_bulle.global_position = Vector2(x, y)


func _cacher_bulle() -> void:
	if _bulle != null and is_instance_valid(_bulle):
		_bulle.queue_free()
	_bulle = null


## Cercle doré autour de l'unité qui agit.
func montrer_halo(idx: int) -> void:
	if not ecran._cartes.has(idx):
		return
	if _halo == null:
		_halo = Panel.new()
		_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 0.8, 0.3, 0.08)
		st.border_color = Color("ffd060")
		st.set_border_width_all(3)
		st.set_corner_radius_all(14)
		_halo.add_theme_stylebox_override("panel", st)
		ecran._arene.add_child(_halo)
		var tw := _halo.create_tween().set_loops()
		tw.tween_property(_halo, "modulate:a", 0.35, 0.5)
		tw.tween_property(_halo, "modulate:a", 1.0, 0.5)
	var racine: Control = ecran._cartes[idx]["racine"]
	_halo.position = racine.position - Vector2(8, 8)
	_halo.size = racine.size + Vector2(16, 16)
	_halo.visible = true
