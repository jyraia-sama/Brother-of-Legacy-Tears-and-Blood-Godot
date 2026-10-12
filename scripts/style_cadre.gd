class_name StyleCadre
extends StyleBox
## PANNEAU ORNÉ : remplace le StyleBoxFlat des panneaux du jeu (UiCommun.style_panneau).
## Dessine le fond et la bordure comme un StyleBoxFlat, puis un double filet doré intérieur
## et des ornements dans les quatre coins (assets/ui/kit/coin.png, ou le coin du kit peint).
## Il garde les mêmes propriétés qu'un StyleBoxFlat (bg_color, border_color, set_border_width_all,
## set_corner_radius_all, shadow_*...) : le code existant qui les modifie continue de marcher.

const COIN := "res://assets/ui/kit/coin.png"
const CADRE_PEINT := "res://assets/ui/kit/cadre.png"     # kit peint (9-slice), prioritaire s'il existe

static var _coins: Array = []          # 4 textures : haut-gauche, haut-droit, bas-gauche, bas-droit
static var _tex_cadre: Texture2D = null
static var _charge := false

@export var bg_color := Color(0.08, 0.02, 0.03, 0.9)
@export var border_color := Color(0.85, 0.65, 0.3)
@export var border_width_left := 2
@export var border_width_top := 2
@export var border_width_right := 2
@export var border_width_bottom := 2
@export var corner_radius_top_left := 8
@export var corner_radius_top_right := 8
@export var corner_radius_bottom_right := 8
@export var corner_radius_bottom_left := 8
@export var shadow_color := Color(0, 0, 0, 0.55)
@export var shadow_size := 10
@export var shadow_offset := Vector2(0, 3)
@export var expand_margin_left := 0.0
@export var expand_margin_top := 0.0
@export var expand_margin_right := 0.0
@export var expand_margin_bottom := 0.0
@export var draw_center := true
@export var anti_aliasing := true
@export var border_blend := false
@export var skew := Vector2.ZERO
## Ornements (coins + filet intérieur). false = simple panneau arrondi.
@export var orne := true

var _flat := StyleBoxFlat.new()
var _filet := StyleBoxFlat.new()


func set_border_width_all(w: int) -> void:
	border_width_left = w
	border_width_top = w
	border_width_right = w
	border_width_bottom = w


func get_border_width_min() -> int:
	return mini(mini(border_width_left, border_width_right), mini(border_width_top, border_width_bottom))


func set_corner_radius_all(r: int) -> void:
	corner_radius_top_left = r
	corner_radius_top_right = r
	corner_radius_bottom_right = r
	corner_radius_bottom_left = r


func set_expand_margin_all(m: float) -> void:
	expand_margin_left = m
	expand_margin_top = m
	expand_margin_right = m
	expand_margin_bottom = m


static func _charger() -> void:
	if _charge:
		return
	_charge = true
	if ResourceLoader.exists(COIN):
		var img := (load(COIN) as Texture2D).get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			for k in 4:
				var c := img.duplicate() as Image
				if k == 1 or k == 3:
					c.flip_x()
				if k >= 2:
					c.flip_y()
				_coins.append(ImageTexture.create_from_image(c))
	if ResourceLoader.exists(CADRE_PEINT):
		_tex_cadre = load(CADRE_PEINT)


func _draw(ci: RID, rect: Rect2) -> void:
	_charger()
	var r := Rect2(rect.position - Vector2(expand_margin_left, expand_margin_top),
		rect.size + Vector2(expand_margin_left + expand_margin_right, expand_margin_top + expand_margin_bottom))
	_flat.bg_color = bg_color
	_flat.border_color = border_color
	_flat.border_width_left = border_width_left
	_flat.border_width_top = border_width_top
	_flat.border_width_right = border_width_right
	_flat.border_width_bottom = border_width_bottom
	_flat.corner_radius_top_left = corner_radius_top_left
	_flat.corner_radius_top_right = corner_radius_top_right
	_flat.corner_radius_bottom_right = corner_radius_bottom_right
	_flat.corner_radius_bottom_left = corner_radius_bottom_left
	_flat.shadow_color = shadow_color
	_flat.shadow_size = shadow_size
	_flat.shadow_offset = shadow_offset
	_flat.draw_center = draw_center
	_flat.anti_aliasing = anti_aliasing
	_flat.border_blend = border_blend
	_flat.skew = skew
	var petit := r.size.x < 120.0 or r.size.y < 72.0
	if _tex_cadre != null and orne and not petit:
		# Kit peint : fond du StyleBoxFlat (sans bordure) puis le cadre peint en 9-slice par-dessus
		_flat.set_border_width_all(0)
		_flat.draw(ci, r)
		var m := 32.0
		RenderingServer.canvas_item_add_nine_patch(ci, r.grow(4), Rect2(Vector2.ZERO, _tex_cadre.get_size()), _tex_cadre.get_rid(),
			Vector2(m, m), Vector2(m, m), RenderingServer.NINE_PATCH_STRETCH, RenderingServer.NINE_PATCH_STRETCH, true,
			Color(border_color.lerp(Color.WHITE, 0.55), 1.0))
		return
	_flat.draw(ci, r)
	if not orne or petit or border_color.a < 0.05:
		return
	# Filet intérieur (fin, doré, discret)
	var bw := float(get_border_width_min())
	var retrait := bw + 4.0
	_filet.draw_center = false
	_filet.bg_color = Color(0, 0, 0, 0)
	_filet.border_color = Color(border_color.lightened(0.15), border_color.a * 0.45)
	_filet.set_border_width_all(1)
	_filet.set_corner_radius_all(maxi(0, corner_radius_top_left - int(retrait)))
	_filet.anti_aliasing = true
	_filet.draw(ci, r.grow(-retrait))
	# Coins ornementaux (teintés de la couleur de la bordure)
	if _coins.size() < 4:
		return
	var t := clampf(minf(r.size.x, r.size.y) * 0.2, 24.0, 42.0)
	var teinte := Color(border_color.lightened(0.35), clampf(border_color.a * 1.2, 0.0, 1.0))
	var o := -3.0
	var pos := [r.position + Vector2(o, o), r.position + Vector2(r.size.x - t - o, o),
		r.position + Vector2(o, r.size.y - t - o), r.position + r.size - Vector2(t + o, t + o)]
	for k in 4:
		RenderingServer.canvas_item_add_texture_rect(ci, Rect2(pos[k], Vector2(t, t)), (_coins[k] as Texture2D).get_rid(), false, teinte)
