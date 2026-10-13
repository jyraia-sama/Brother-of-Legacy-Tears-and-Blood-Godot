class_name SortsIcones
extends RefCounted
## ICÔNES DES SORTS (combats manuels : Aventure, Tours, Donjons, Marche, Sanctuaire, Arène classée).
##
## Chaque sort est rangé dans une « famille » selon ce qu'il fait (frappe, zone, soin, poison...).
## Une famille = une icône : assets/sorts/<famille>.png (carrée, fond transparent).
## Tant que l'image d'une famille n'existe pas, l'icône est dessinée : un carré arrondi coloré avec un symbole.
## Le contour du cadre prend la couleur de l'élément de l'unité.
##
##   SortsIcones.famille(sort)                     -> "poison", "zone", ...
##   SortsIcones.bouton(action, sort, element, taille) -> Control (icône cliquable, recharge affichée)
##   SortsIcones.detail(action, sort)              -> texte de la bulle d'aide (titre + lignes)

const DOSSIER := "res://assets/sorts/"

## Familles : nom affiché, symbole (secours), couleur du cadre (secours).
const FAMILLES := {
	"attaque": {"nom": "Attaque", "sym": "⚔", "coul": "b89a6a"},
	"frappe": {"nom": "Frappe", "sym": "✸", "coul": "d0603a"},
	"zone": {"nom": "Attaque de zone", "sym": "☄", "coul": "e08a2a"},
	"soin": {"nom": "Soin", "sym": "✚", "coul": "5cc06a"},
	"soin_groupe": {"nom": "Soin de groupe", "sym": "❂", "coul": "48b088"},
	"bouclier": {"nom": "Bouclier", "sym": "◉", "coul": "6aa8d8"},
	"provocation": {"nom": "Provocation", "sym": "⚑", "coul": "b04040"},
	"renfort": {"nom": "Renfort", "sym": "✦", "coul": "e0b040"},
	"protection": {"nom": "Protection", "sym": "✪", "coul": "8a9ab8"},
	"affaiblir": {"nom": "Affaiblissement", "sym": "↺", "coul": "8a6a9a"},
	"drain": {"nom": "Drain de vie", "sym": "♥", "coul": "b0304a"},
	"purification": {"nom": "Purification", "sym": "☀", "coul": "f0e0a0"},
	"regeneration": {"nom": "Régénération", "sym": "⟳", "coul": "70c070"},
	"resurrection": {"nom": "Résurrection", "sym": "✝", "coul": "f0d070"},
	"sacrifice": {"nom": "Sacrifice", "sym": "♦", "coul": "901a2a"},
	"brulure": {"nom": "Brûlure", "sym": "♨", "coul": "e05a20"},
	"gel": {"nom": "Gel", "sym": "❄", "coul": "70c8f0"},
	"poison": {"nom": "Poison", "sym": "☠", "coul": "6a9a30"},
	"saignement": {"nom": "Saignement", "sym": "†", "coul": "a01818"},
	"etourdi": {"nom": "Étourdissement", "sym": "✷", "coul": "e0c040"},
	"silence": {"nom": "Silence", "sym": "✖", "coul": "7a7aa0"},
	"aveugle": {"nom": "Aveuglement", "sym": "◎", "coul": "c0b090"},
	"malediction": {"nom": "Malédiction", "sym": "☯", "coul": "8040a0"},
}

const CIBLES := {"ennemis": "Touche tous les ennemis", "allies": "Sur toute l'équipe", "soi": "Sur lui-même",
	"avant": "Ennemis de l'Avant", "arriere": "Ennemis de l'Arrière", "aleatoire": "Ennemis au hasard",
	"allie_faible": "L'allié le plus blessé", "ennemi": "Un ennemi"}

static var _cache_tex := {}


## Famille d'un sort (dictionnaire du sort : "effets", "cible"). {} = attaque normale.
static func famille(sk: Dictionary) -> String:
	if sk.is_empty():
		return "attaque"
	var effets: Array = sk.get("effets", [])
	var types := effets.map(func(e): return str(e.get("effet", "")))
	var cible := str(sk.get("cible", ""))
	if "ressusciter" in types:
		return "resurrection"
	if "provocation" in types:
		return "provocation"
	if "soin" in types:
		return "soin_groupe" if cible == "allies" else "soin"
	if "drain" in types:
		return "drain"
	for e in effets:
		if str(e.get("effet", "")) == "affliction" and FAMILLES.has(str(e.get("nom", ""))):
			return str(e["nom"])
	if "degats" in types:
		return "frappe" if cible == "ennemi" else "zone"
	if "bouclier" in types:
		return "bouclier"
	for e in effets:
		if str(e.get("effet", "")) == "buff":
			return "protection" if str(e.get("stat", "")) in ["def", "res"] else "renfort"
	if "debuff" in types:
		return "affaiblir"
	if "purification" in types:
		return "purification"
	if "regen_temp" in types:
		return "regeneration"
	if "cout_pv" in types:
		return "sacrifice"
	return "frappe"


static func texture(fam: String) -> Texture2D:
	if not _cache_tex.has(fam):
		var ch := DOSSIER + fam + ".png"
		_cache_tex[fam] = load(ch) if ResourceLoader.exists(ch) else null
	return _cache_tex[fam]


## Icône cliquable d'une action (attaque ou sort). « action » vient de CombatMoteur.actions_possibles.
## Recharge en cours ou silence : icône grisée avec le nombre de tours restants par-dessus.
static func bouton(action: Dictionary, sk: Dictionary, element: String, taille := 76.0) -> Control:
	var fam := famille(sk if action.get("type") == "skill" else {})
	var info: Dictionary = FAMILLES[fam]
	var dispo: bool = action.get("dispo", true)
	var b := Control.new()
	b.custom_minimum_size = Vector2(taille, taille)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if dispo else Control.CURSOR_ARROW
	b.set_meta("famille", fam)
	var anneau := UiCommun.COULEURS_ELEMENT.get(element, Color("c8b8b0")) as Color
	# Cadre carré arrondi (fond + contour couleur de l'élément)
	var fond := Panel.new()
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(info["coul"]).darkened(0.55)
	st.border_color = anneau if action.get("type") == "skill" else Color("c8b48a")
	st.set_border_width_all(4)
	st.set_corner_radius_all(int(taille * 0.2))      # carré aux angles arrondis
	st.shadow_color = Color(0, 0, 0, 0.6)
	st.shadow_size = 6
	fond.add_theme_stylebox_override("panel", st)
	b.add_child(fond)
	var tex := texture(fam)
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var m := int(taille * 0.07)
		img.offset_left = m
		img.offset_top = m
		img.offset_right = -m
		img.offset_bottom = -m
		b.add_child(img)
	else:
		var s := UiCommun.label(str(info["sym"]), int(taille * 0.5), Color(info["coul"]).lightened(0.45))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(s)
	if not dispo:
		b.modulate = Color(0.45, 0.42, 0.42)
		var rec := int(action.get("recharge", 0))
		var txt := str(rec) if rec > 0 else ("✖" if action.get("silence", false) else "")
		if txt != "":
			var n := UiCommun.label(txt, int(taille * 0.46), Color("ffd060"))
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			n.add_theme_constant_override("outline_size", 10)
			n.add_theme_color_override("font_outline_color", Color.BLACK)
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(n)
	return b


## Contenu de la bulle d'aide : {titre, sous_titre, lignes: [...], pied}.
static func detail(action: Dictionary, sk: Dictionary) -> Dictionary:
	var est_sort: bool = action.get("type") == "skill"
	var fam := famille(sk if est_sort else {})
	var lignes := CombatClasse.texte_court(str(action.get("description", "")))
	var pied := ""
	var cibles: Array = action.get("cibles", [])
	if cibles.size() > 1:
		pied = "🎯 Tu choisis la cible"
	elif est_sort:
		pied = CIBLES.get(str(sk.get("cible", "")), "Cible automatique")
	else:
		pied = "Cible automatique"
	if est_sort:
		if action.get("silence", false):
			pied = "Réduit au silence : sort impossible"
		elif int(action.get("recharge", 0)) > 0:
			var r := int(action["recharge"])
			pied = UiCommun.t("Prêt dans %d tour%s") % [r, "s" if r > 1 else ""]
		elif not action.get("dispo", true):
			pied = "Inutile pour l'instant"
		else:
			var r := CombatMoteur.recharge_sort(sk)
			pied += UiCommun.t("  ·  recharge %d tour%s") % [r, "s" if r > 1 else ""]
	var sous: String = FAMILLES[fam]["nom"]
	if est_sort and int(sk.get("niveau_sort", 1)) > 1:
		sous += UiCommun.t("  ·  niveau %d (effets +%d %%)") % [int(sk["niveau_sort"]),
			int(round((SortsNiveaux.multiplicateur(int(sk["niveau_sort"])) - 1.0) * 100))]
	return {"titre": str(action.get("nom", "")), "sous_titre": sous, "lignes": lignes, "pied": pied,
		"dispo": action.get("dispo", true)}


## Bulle d'aide (panneau) construite à partir de detail().
static func bulle(d: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiCommun.style_panneau(UiCommun.C_OR, Color(0.06, 0.02, 0.03, 0.97))
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(320, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(vb)
	var t := UiCommun.label(d["titre"], 21, UiCommun.C_OR)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(t)
	vb.add_child(UiCommun.label(d["sous_titre"], 14, Color(0.75, 0.68, 0.6)))
	var eff := UiCommun.label("\n".join(d["lignes"].map(func(l): return "• " + l)), 16, Color(0.95, 0.92, 0.88))
	eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(eff)
	vb.add_child(UiCommun.label(d["pied"], 15, Color("ffd060") if d["dispo"] else Color("ff8a6a")))
	for c in vb.get_children():
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Appareil tactile (téléphone, tablette) : pas de survol -> 1er toucher = détails, 2e = valider.
static func tactile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
