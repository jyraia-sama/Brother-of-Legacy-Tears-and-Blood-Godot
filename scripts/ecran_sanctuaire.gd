class_name EcranSanctuaire
extends Control
## LE SANCTUAIRE DU BÉLIER (secret) : les quatre épreuves de la famille du Bélier. Voir sanctuaire.gd.

const SCENE := Sanctuaire.SCENE
const C_OR := Color("e8b54a")
const PORTRAITS := {"alysse": "alysse_etoile", "loucas": "loucas_belier", "anais": "anais_toison", "famille": ""}


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("120a06")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, Sanctuaire.FOND, Color(0.5, 0.45, 0.42)):
		var g := Gradient.new()
		g.set_color(0, Color("3a2208"))
		g.set_color(1, Color("0c0604"))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.35)
		tex.fill_to = Vector2(1.1, 0.9)
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(r)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 22)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	tete.add_child(retour)
	var titre := UiCommun.label("LE SANCTUAIRE DU BÉLIER", 34, C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)

	var sous := UiCommun.label("Trois Béliers veillent sur ce foyer caché. Bats-les un par un, puis réunis : chacun vaincu rejoint ton équipe.\nLeur force s'adapte à ton équipe · aucune stamina · rejouable.", 16, UiCommun.C_DOUX)
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sous)

	var ligne := HBoxContainer.new()
	ligne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 22)
	col.add_child(ligne)
	for ep in Sanctuaire.ORDRE:
		ligne.add_child(_carte(ep))

	# Retour d'un combat gagné : la scène de victoire
	var r: Dictionary = EcranCombat.resultat
	if str(r.get("mode", "")) == "sanctuaire":
		EcranCombat.resultat = {}
		if r.get("victoire", false):
			var info: Dictionary = Sanctuaire.EPREUVES[str(r["epreuve"])]
			FenetreSimple.ouvrir.call_deferred(self, info["titre"], info["victoire"])


func _carte(ep: String) -> Control:
	var info: Dictionary = Sanctuaire.EPREUVES[ep]
	var ouverte := Sanctuaire.est_ouverte(ep)
	var vaincue := Sanctuaire.est_vaincue(ep)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.035, 0.02, 0.88)
	st.border_color = C_OR if ouverte else Color(0.35, 0.3, 0.25)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 14
	st.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)

	var ill := CenterContainer.new()
	ill.custom_minimum_size = Vector2(270, 300)
	v.add_child(ill)
	if ep == "famille":
		# Les trois portraits côte à côte
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", -10)
		ill.add_child(h)
		for id in ["alysse_etoile", "anais_toison", "loucas_belier"]:
			var c := CenterContainer.new()
			c.add_child(UiCommun.illustration(id, Vector2(96, 150), 8, C_OR, 2) if UiCommun.chemin_portrait(id) != "" else UiCommun.portrait(id, 96))
			h.add_child(c)
	else:
		var id: String = PORTRAITS[ep]
		var img: Control = UiCommun.illustration(id, Vector2(270, 300), 10, C_OR, 2) \
			if UiCommun.chemin_portrait(id) != "" else UiCommun.portrait(id, 230)
		ill.add_child(img)
	if not ouverte:
		ill.modulate = Color(0.25, 0.22, 0.22)

	var nom := UiCommun.label(info["titre"], 20, C_OR if ouverte else UiCommun.C_DOUX)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(0, 58)
	nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(nom)
	var etat := "Vaincue ✓  (rejouable)" if vaincue else ("À affronter" if ouverte else "Verrouillée : bats d'abord l'épreuve précédente")
	var le := UiCommun.label(etat, 14, Color("8affa0") if vaincue else UiCommun.C_DOUX)
	le.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	le.custom_minimum_size = Vector2(0, 44)
	v.add_child(le)
	var b := UiCommun.bouton("Affronter" if not vaincue else "Rejouer", 18)
	b.disabled = not ouverte
	b.pressed.connect(_presenter.bind(ep))
	v.add_child(b)
	return p


func _presenter(ep: String) -> void:
	var info: Dictionary = Sanctuaire.EPREUVES[ep]
	FenetreSimple.ouvrir(self, info["titre"], info["intro"], [["Combattre !", _combattre.bind(ep)], ["Plus tard", null]])


func _combattre(ep: String) -> void:
	var equipe := Sanctuaire.equipe_joueur()
	if equipe.is_empty():
		FenetreSimple.ouvrir(self, "Équipe vide", "Ajoute des héros à ton équipe dans le Deck avant de combattre.")
		return
	EcranCombat.demande = {"mode": "sanctuaire", "epreuve": ep, "acte": 13, "type": "boss_acte",
		"equipe": equipe, "ennemis": Sanctuaire.generer(ep, equipe), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)
