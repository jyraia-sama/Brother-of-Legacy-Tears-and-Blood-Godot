class_name EcranCourrier
extends EcranBase
## COURRIER : lettres reçues, avec pièces jointes à récupérer. Règles : courrier.gd.

const SCENE := "res://scenes/courrier.tscn"
const C_NEUF := Color("ffd27a")
const C_LU := Color(0.55, 0.47, 0.45)
const C_CADEAU := Color("8affa0")

var _ouverte := -1


func _fond_ecran() -> String:
	return "res://assets/fonds/courrier.png"


func _titre_ecran() -> String:
	return "COURRIER"


func _preparer() -> void:
	var tout := UiCommun.bouton("Tout récupérer", 16)
	tout.pressed.connect(func():
		var l := Courrier.tout_reclamer()
		if l.is_empty():
			_erreur("Rien à récupérer")
		else:
			_annoncer(l)
		rafraichir())
	_tete.add_child(tout)
	_tete.move_child(tout, 3)
	var vider := UiCommun.bouton("Supprimer les lues", 16)
	vider.pressed.connect(func():
		var n := Courrier.supprimer_lues()
		_ouverte = -1
		if n > 0:
			_annoncer(["%d lettre%s supprimée%s" % [n, "s" if n > 1 else "", "s" if n > 1 else ""]], UiCommun.C_DOUX)
		rafraichir())
	_tete.add_child(vider)
	_tete.move_child(vider, 4)


func _remplir() -> void:
	var l := Courrier.lettres()
	if l.is_empty():
		_titre("Aucune lettre pour l'instant.")
		_texte("Les cadeaux, les compensations et les récompenses spéciales arrivent ici.")
		return
	_titre("%d lettre%s  ·  %d à lire ou à récupérer" % [l.size(), "s" if l.size() > 1 else "", Courrier.a_lire()])
	for i in l.size():
		_lettre(i, l[i])


func _lettre(i: int, l: Dictionary) -> void:
	var neuve := not bool(l["lue"])
	var cadeau := not bool(l["reclamee"])
	var h := _ligne(C_CADEAU if cadeau else (C_NEUF if neuve else UiCommun.C_OR.darkened(0.55)))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	h.add_child(vb)
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	vb.add_child(tete)
	if neuve:
		tete.add_child(UiCommun.label("NOUVEAU", 13, Color("ff7a6a")))
	var t := UiCommun.label(str(l["titre"]), 19, C_NEUF if neuve else UiCommun.C_TEXTE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	tete.add_child(UiCommun.label("%s  ·  %s" % [str(l["de"]), _date(int(l["date"]))], 13, UiCommun.C_DOUX))
	if i == _ouverte:
		var corps := UiCommun.label(str(l["texte"]), 15, UiCommun.C_TEXTE)
		corps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(corps)
	if not (l["recompense"] as Dictionary).is_empty():
		vb.add_child(UiCommun.label(("Pièce jointe : " if cadeau else "Récupéré : ") + Quetes.texte_recompense(l["recompense"]),
			14, C_CADEAU if cadeau else C_LU))
	var boutons := VBoxContainer.new()
	boutons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boutons.add_theme_constant_override("separation", 6)
	h.add_child(boutons)
	var lire := UiCommun.bouton("Fermer" if i == _ouverte else "Lire", 15)
	lire.custom_minimum_size = Vector2(130, 40)
	lire.pressed.connect(func():
		_ouverte = -1 if _ouverte == i else i
		Courrier.marquer_lue(i)
		rafraichir())
	boutons.add_child(lire)
	if cadeau:
		var r := UiCommun.bouton("Récupérer", 15)
		r.custom_minimum_size = Vector2(130, 40)
		r.pressed.connect(func():
			_annoncer(Courrier.reclamer(i))
			rafraichir())
		boutons.add_child(r)


func _date(t: int) -> String:
	if t <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "%02d/%02d/%d" % [d["day"], d["month"], d["year"]]
