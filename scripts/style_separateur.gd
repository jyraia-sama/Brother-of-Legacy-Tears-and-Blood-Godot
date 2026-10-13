class_name StyleSeparateur
extends StyleBox
## SÉPARATEUR ORNÉ : filet doré étiré sur toute la largeur, ornement central à sa taille réelle
## (assets/ui/kit/separateur.png : le motif central occupe la bande « largeur_centre » au milieu).

@export var texture: Texture2D
@export var largeur_centre := 40.0
@export var teinte := Color.WHITE


func _draw(ci: RID, rect: Rect2) -> void:
	if texture == null:
		return
	var ts := texture.get_size()
	var h := minf(ts.y, rect.size.y)
	var y := rect.position.y + (rect.size.y - h) / 2.0
	var g := minf(largeur_centre, ts.x) / 2.0
	var cx := ts.x / 2.0
	var mid := rect.position.x + rect.size.x / 2.0
	var rid := texture.get_rid()
	var gauche := maxf(0.0, mid - g - rect.position.x)
	RenderingServer.canvas_item_add_texture_rect_region(ci, Rect2(rect.position.x, y, gauche, h), rid, Rect2(0, 0, cx - g, ts.y), teinte)
	RenderingServer.canvas_item_add_texture_rect_region(ci, Rect2(mid - g, y, 2.0 * g, h), rid, Rect2(cx - g, 0, 2.0 * g, ts.y), teinte)
	RenderingServer.canvas_item_add_texture_rect_region(ci, Rect2(mid + g, y, gauche, h), rid, Rect2(cx + g, 0, ts.x - cx - g, ts.y), teinte)
