class_name EcranBossMonde
extends Control
## BOSS DE MONDE : les 7 boss de la semaine. Seul celui du jour peut être affronté,
## les autres sont grisés. Avant l'assaut : préparer l'armée (4 escouades de 5).

const SCENE := "res://scenes/boss_monde.tscn"
const FOND := "res://assets/boss_monde/boss_monde_bg.png"
const C_SANG := Color("d0453a")

static var scene_retour := ""

var _selection := 0
var _lbl_essais: Label
var _lbl_decompte: Label
var _cartes: HBoxContainer
var _fiche: VBoxContainer


func _ready() -> void:
	Sauvegarde.charger()
	_selection = BossMonde.boss_du_jour()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0a0506")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, FOND, Color(0.45, 0.45, 0.45)):
		UiCommun.fond_degrade(self, Color("1a0608"), Color("050203"))
	UiCommun.particules(self, Color("b02020"), true, 35)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("BOSS DE MONDE", 34, C_SANG))
	_lbl_decompte = UiCommun.label("", 17, Color("ffb070"))
	_lbl_decompte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_decompte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tete.add_child(_lbl_decompte)
	_lbl_essais = UiCommun.label("", 19, UiCommun.C_OR)
	tete.add_child(_lbl_essais)

	_cartes = HBoxContainer.new()
	_cartes.add_theme_constant_override("separation", 10)
	_cartes.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_cartes)

	var bas := PanelContainer.new()
	bas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bas.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_SANG))
	col.add_child(bas)
	var d := ScrollContainer.new()
	d.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bas.add_child(d)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	d.add_child(_fiche)

	_remplir_cartes()
	_maj_fiche()
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj_haut)
	add_child(t)
	_maj_haut()


func _remplir_cartes() -> void:
	for e in _cartes.get_children():
		e.queue_free()
	var aujourdhui := BossMonde.boss_du_jour()
	for i in BossMonde.BOSS.size():
		var b: Dictionary = BossMonde.BOSS[i]
		var u := UnitesData.get_unite(b["id"])
		var dispo := i == aujourdhui
		var carte := Button.new()
		carte.custom_minimum_size = Vector2(222, 300)
		carte.focus_mode = Control.FOCUS_NONE
		carte.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bord: Color = UiCommun.COULEURS_ELEMENT[u["element"]]
		var st := UiCommun.style_carte(bord if dispo else bord.darkened(0.5), 0.0, 4 if dispo else 2)
		if dispo:
			st.shadow_color = Color(C_SANG, 0.8)
			st.shadow_size = 16
		if i == _selection:
			st.border_color = Color.WHITE
		carte.add_theme_stylebox_override("normal", st)
		carte.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.05, 3))
		carte.add_theme_stylebox_override("pressed", UiCommun.style_carte(UiCommun.C_OR, 0.1, 3))
		var vb := VBoxContainer.new()
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vb.offset_top = 10
		vb.offset_bottom = -10
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 6)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		carte.add_child(vb)
		var jour := UiCommun.label(Calendrier.JOURS[i].to_upper(), 18, UiCommun.C_OR if dispo else UiCommun.C_DOUX)
		jour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(jour)
		var chemin := "res://assets/boss_monde/%s.png" % b["id"]
		if ResourceLoader.exists(chemin):
			var img := TextureRect.new()
			img.texture = load(chemin)
			img.custom_minimum_size = Vector2(190, 140)
			img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(img)
		else:
			vb.add_child(UiCommun.portrait(b["id"], 120))
		var nom := UiCommun.label(b["titre"], 15, Color.WHITE if dispo else UiCommun.C_DOUX)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nom.custom_minimum_size = Vector2(200, 0)
		vb.add_child(nom)
		var etat := UiCommun.label("AUJOURD'HUI" if dispo else "Disponible le " + Calendrier.JOURS[i].to_lower(), 14,
			C_SANG if dispo else UiCommun.C_DOUX)
		etat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(etat)
		if BossMonde.record(b["id"]) > 0.0:
			var rec := UiCommun.label("Record : %.1f %%" % BossMonde.record(b["id"]), 13, UiCommun.C_OR)
			rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vb.add_child(rec)
		if not dispo:
			carte.modulate = Color(0.55, 0.55, 0.55)
		carte.pressed.connect(func():
			_selection = i
			_remplir_cartes()
			_maj_fiche())
		_cartes.add_child(carte)


func _maj_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	var b: Dictionary = BossMonde.BOSS[_selection]
	var u := UnitesData.get_unite(b["id"])
	var dispo := _selection == BossMonde.boss_du_jour()
	var s := UnitesData.stats(b["id"], BossMonde.NIVEAU_BOSS)
	var m: Dictionary = b["mult"]

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	_fiche.add_child(h)
	var gauche := VBoxContainer.new()
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.add_theme_constant_override("separation", 6)
	h.add_child(gauche)
	gauche.add_child(UiCommun.label(str(b["titre"]).to_upper(), 26, C_SANG))
	gauche.add_child(UiCommun.label("%s  ·  %s  ·  Niveau %d  ·  agit %d fois par tour" % [UnitesData.ELEMENTS[u["element"]],
		UnitesData.ROLES[u["role"]], BossMonde.NIVEAU_BOSS, int(b["actions"])], 15, UiCommun.C_DOUX))
	var t := UiCommun.label(b["texte"], 16, UiCommun.C_TEXTE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gauche.add_child(t)
	var cons := UiCommun.label("Conseil : " + str(b["conseil"]) + "   Faiblesse : " + UnitesData.ELEMENTS[b["faiblesse"]], 15, UiCommun.C_OR)
	cons.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gauche.add_child(cons)
	var comp: Array = []
	for sk in u["skills"]:
		comp.append(sk["nom"])
	var l_comp := UiCommun.label("Compétences : " + ", ".join(comp), 14, UiCommun.C_DOUX)
	l_comp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gauche.add_child(l_comp)

	var droite := VBoxContainer.new()
	droite.custom_minimum_size = Vector2(430, 0)
	droite.add_theme_constant_override("separation", 6)
	h.add_child(droite)
	droite.add_child(UiCommun.label("PV : %s" % _milliers(int(s["pv"] * float(m["pv"]))), 26, Color("ff7a6a")))
	droite.add_child(UiCommun.label("ATK %d   ·   DEF %d   ·   MAG %d   ·   AGI %d" % [int(s["atk"] * float(m["atk"])),
		int(s["def"] * float(m["def"])), int(s["mag"] * float(m["mag"])), int(s["agi"] * float(m["agi"]))], 16, UiCommun.C_TEXTE))
	droite.add_child(UiCommun.label("Durée de l'assaut : %d tours maximum" % BossMonde.TOURS_COMBAT, 15, UiCommun.C_DOUX))
	droite.add_child(UiCommun.label("Record : %.1f %%   ·   Aujourd'hui : %.1f %%" % [BossMonde.record(b["id"]),
		BossMonde.record_du_jour(b["id"])], 16, UiCommun.C_OR))
	droite.add_child(UiCommun.label("Récompenses selon les dégâts : or, Fragments Colossaux,\nPoussière d'Écho, coffre (Royal si le boss est abattu).", 14, UiCommun.C_DOUX))

	_fiche.add_child(HSeparator.new())
	var armee := BossMonde.armee()
	var puissance := 0.0
	var niveau_moyen := 0.0
	var avec_echos := 0
	for e in armee:
		var st := Sauvegarde.stats_heros(int(e["uid"]))
		puissance += st["pv"] * 0.25 + st["atk"] + st["def"] * 0.8 + st["agi"] * 0.5 + st["mag"] * 0.7
		niveau_moyen += int(e["niveau"])
		if not Sauvegarde.echos_de(int(e["uid"])).is_empty():
			avec_echos += 1
	if not armee.is_empty():
		niveau_moyen /= armee.size()
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	_fiche.add_child(ligne)
	var info := UiCommun.label("ARMÉE : %d / 20 unités   ·   niveau moyen %.1f   ·   %d avec des Échos   ·   puissance %d" % [
		armee.size(), niveau_moyen, avec_echos, int(puissance)], 17, UiCommun.C_TEXTE)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(info)
	var prep := UiCommun.bouton("Préparer l'armée (4 escouades)", 17)
	prep.pressed.connect(func():
		EcranArmee.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranArmee.SCENE))
	ligne.add_child(prep)
	var go := UiCommun.bouton("LANCER L'ASSAUT", 22)
	go.custom_minimum_size = Vector2(280, 56)
	go.add_theme_color_override("font_color", Color("ff8a6a"))
	var raison := ""
	if not BossMonde.est_debloque():
		raison = "Termine l'Acte %s pour débloquer les Boss de Monde." % ActesData.get_acte(BossMonde.DEBLOCAGE.x).get("romain", str(BossMonde.DEBLOCAGE.x))
	elif not dispo:
		raison = "Ce boss n'apparaît que le " + Calendrier.JOURS[_selection].to_lower() + "."
	elif BossMonde.essais_restants() <= 0:
		raison = "Plus d'essais aujourd'hui. Reviens demain !"
	elif armee.is_empty():
		raison = "Ton armée est vide : prépare tes escouades."
	go.disabled = raison != ""
	go.tooltip_text = raison
	go.pressed.connect(_lancer)
	ligne.add_child(go)
	if raison != "":
		_fiche.add_child(UiCommun.label(raison, 15, Color("ff8a7a")))
	elif niveau_moyen < 20 or avec_echos < 10:
		_fiche.add_child(UiCommun.label("Attention : il faut des unités de haut niveau (20+) équipées d'Échos Sanguins pour infliger de gros dégâts.", 15, Color("ffb070")))


func _lancer() -> void:
	if not BossMonde.consommer_essai():
		return
	EcranCombat.demande = {"mode": "boss_monde", "boss_index": _selection, "type": "boss_monde",
		"tours_max": BossMonde.TOURS_COMBAT, "equipe": BossMonde.armee(), "ennemis": BossMonde.generer(_selection),
		"retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _maj_haut() -> void:
	_lbl_essais.text = "Essais aujourd'hui : %d / %d" % [BossMonde.essais_restants(), BossMonde.ESSAIS_PAR_JOUR]
	_lbl_decompte.text = "Prochain boss dans %s" % Calendrier.texte_duree(Calendrier.secondes_avant_demain())


func _milliers(n: int) -> String:
	var t := str(n)
	var r := ""
	while t.length() > 3:
		r = " " + t.substr(t.length() - 3) + r
		t = t.substr(0, t.length() - 3)
	return t + r


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
