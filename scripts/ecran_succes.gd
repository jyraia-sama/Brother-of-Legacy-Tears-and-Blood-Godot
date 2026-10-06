class_name EcranSucces
extends EcranBase
## SUCCÈS : objectifs à long terme par paliers (gemmes) et titres. Règles : succes.gd.

const SCENE := "res://scenes/succes.tscn"
const C_OK := Color("8affa0")
const C_TITRE := Color("ffd27a")


func _fond_ecran() -> String:
	return "res://assets/fonds/succes.png"


func _titre_ecran() -> String:
	return "SUCCÈS"


func _remplir() -> void:
	var total := 0
	var faits := 0
	for d in Succes.LISTE:
		total += d["paliers"].size()
		faits += Succes.reclames(d["id"])
	_titre("Paliers obtenus : %d / %d   ·   Titres : %d / %d" % [faits, total, Succes.titres().size(), Succes.LISTE.size()])
	_texte("Chaque palier atteint se réclame pour des gemmes. Le dernier palier d'un succès débloque un titre, à afficher dans « Mon héros ».")
	# Ceux qu'on peut réclamer d'abord, puis les plus avancés
	var l: Array = Succes.LISTE.duplicate()
	l.sort_custom(func(a, b): return _cle(a) > _cle(b))
	for d in l:
		_carte(d)


func _cle(d: Dictionary) -> float:
	var id: String = d["id"]
	var n: int = d["paliers"].size()
	if Succes.peut_reclamer(id):
		return 1000.0
	if Succes.reclames(id) >= n:
		return -1.0
	var i := Succes.reclames(id)
	return float(Succes.valeur(id)) / float(d["paliers"][i][0])


func _carte(d: Dictionary) -> void:
	var id: String = d["id"]
	var n: int = d["paliers"].size()
	var rec := Succes.reclames(id)
	var fini := rec >= n
	var dispo := Succes.peut_reclamer(id)
	var h := _ligne(C_OK if dispo else (C_TITRE if fini else UiCommun.C_OR.darkened(0.5)))
	var etoiles := UiCommun.label("★".repeat(rec) + "☆".repeat(n - rec), 24, C_TITRE)
	etoiles.custom_minimum_size = Vector2(120, 0)
	etoiles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(etoiles)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vb)
	vb.add_child(UiCommun.label(d["nom"], 18, C_TITRE if fini else UiCommun.C_TEXTE))
	vb.add_child(UiCommun.label(str(d["desc"]) + "   Titre : « %s »" % d["titre"], 13, UiCommun.C_DOUX))
	var v := Succes.valeur(id)
	var cible: int = d["paliers"][mini(rec, n - 1)][0]
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	vb.add_child(ligne)
	ligne.add_child(_barre(v, cible, C_OK if (dispo or fini) else UiCommun.C_OR, 300))
	ligne.add_child(UiCommun.label("%s / %s" % [_nombre(mini(v, cible) if not fini else v), _nombre(cible)], 14, UiCommun.C_TEXTE))
	if not fini:
		ligne.add_child(UiCommun.label("Palier %d : %s" % [rec + 1, Quetes.texte_recompense(d["paliers"][rec][1])], 14, UiCommun.C_OR))
	var b := UiCommun.bouton("Réclamer" if not fini else "Terminé", 16)
	b.custom_minimum_size = Vector2(150, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not dispo
	b.pressed.connect(func():
		_annoncer(Succes.reclamer(id))
		rafraichir())
	h.add_child(b)
