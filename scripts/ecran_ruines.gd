class_name EcranRuines
extends Control
## LES RUINES OUBLIÉES (secret) : trois étages, trois Légendes cachées. Voir ruines.gd.
## On y entre par la stèle du Sceau de l'Aube, sur la carte du monde.

const SCENE := Ruines.SCENE
const C_OR := Color("e8c060")
const C_AUBE := Color("ffe9a8")


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0a0807")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	UiCommun.fond_image(self, Ruines.FOND, Color(0.32, 0.3, 0.3))

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 22)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Carte")
	retour.pressed.connect(func(): get_tree().change_scene_to_file(EcranCarte.SCENE))
	tete.add_child(retour)
	var titre := UiCommun.label("LES RUINES OUBLIÉES", 34, C_OR)
	tete.add_child(UiCommun.plaque_titre(titre))
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(pousse)

	var sous := UiCommun.label("Le Sceau de l'Aube a ouvert la stèle. Sous la terre, trois étages gardent trois Légendes oubliées.\nLeur force s'adapte à ton équipe · aucune stamina · une récompense d'évolution par jour une fois vaincus.", 16, UiCommun.C_DOUX)
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sous)

	var ligne := HBoxContainer.new()
	ligne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	ligne.add_theme_constant_override("separation", 22)
	col.add_child(ligne)
	for et in Ruines.ORDRE:
		ligne.add_child(_carte(et))

	# Retour d'un combat
	var r: Dictionary = EcranCombat.resultat
	if str(r.get("mode", "")) == "ruines":
		EcranCombat.resultat = {}
		var et: String = str(r.get("etage", ""))
		if r.get("victoire", false) and r.get("fini", false) and Ruines.ETAGES.has(et):
			var info: Dictionary = Ruines.ETAGES[et]
			FenetreSimple.ouvrir.call_deferred(self, info["titre"], info["victoire"])
		elif r.get("victoire", false) and not Ruines.en_cours().is_empty():
			_proposer_suite.call_deferred()


func _carte(et: String) -> Control:
	var info: Dictionary = Ruines.ETAGES[et]
	var ouvert := Ruines.est_ouvert(et)
	var vaincu := Ruines.est_vaincu(et)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(330, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.04, 0.035, 0.03, 0.9)
	st.border_color = C_OR if ouvert else Color(0.3, 0.27, 0.24)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	for c in ["left", "right", "top", "bottom"]:
		st.set("content_margin_" + c, 14)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)

	var ill := CenterContainer.new()
	ill.custom_minimum_size = Vector2(300, 260)
	v.add_child(ill)
	var id: String = info["heros"]
	if vaincu or ouvert:
		var img: Control = UiCommun.illustration(id, Vector2(290, 255), 10, C_OR, 2) \
			if UiCommun.chemin_portrait(id) != "" else UiCommun.portrait(id, 230)
		ill.add_child(img)
		if not vaincu:
			img.modulate = Color(0.1, 0.09, 0.09)     # silhouette tant qu'ils ne sont pas délivrés
	else:
		var ferme := UiCommun.label("?", 90, Color(0.4, 0.36, 0.32))
		ill.add_child(ferme)

	var n := Ruines.ORDRE.find(et) + 1
	var nom := UiCommun.label(UiCommun.t("Étage %d · %s") % [n, info["titre"]], 20, C_OR if ouvert else UiCommun.C_DOUX)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nom)
	var regle := UiCommun.label(info["regle"], 13, UiCommun.C_DOUX)
	regle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	regle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regle.custom_minimum_size = Vector2(300, 54)
	v.add_child(regle)
	var c := Ruines.en_cours()
	var etat := ""
	if str(c.get("etage", "")) == et:
		etat = UiCommun.t("En cours : vague %d / %d") % [int(c["vague"]) + 1, Ruines.nb_vagues(et)]
	elif vaincu:
		etat = "Délivrés ✓ · récompense du jour disponible" if Ruines.recompense_du_jour_dispo(et) else "Délivrés ✓ · récompense du jour prise"
	elif ouvert:
		etat = UiCommun.t("%d combats · à explorer") % Ruines.nb_vagues(et)
	else:
		etat = "Fermé : termine d'abord l'étage précédent"
	var le := UiCommun.label(etat, 14, Color("8affa0") if vaincu else C_AUBE)
	le.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(le)
	var autre_en_cours := not c.is_empty() and str(c.get("etage", "")) != et
	if str(c.get("etage", "")) == et:
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 10)
		v.add_child(h)
		var suite := UiCommun.bouton("Continuer", 18)
		suite.pressed.connect(_combattre.bind(et))
		h.add_child(suite)
		var ab := UiCommun.bouton("Abandonner", 15)
		ab.pressed.connect(func():
			Ruines.abandonner()
			get_tree().reload_current_scene())
		h.add_child(ab)
	else:
		var b := UiCommun.bouton("Rejouer" if vaincu else "Descendre", 18)
		b.disabled = not ouvert or autre_en_cours
		b.pressed.connect(_presenter.bind(et))
		v.add_child(b)
	return p


func _presenter(et: String) -> void:
	var info: Dictionary = Ruines.ETAGES[et]
	var txt: String = info["intro"] + "\n\n" + UiCommun.t("Règle de l'étage — %s") % info["regle"]
	FenetreSimple.ouvrir(self, info["titre"], txt, [["Descendre !", func():
		Ruines.commencer(et)
		_combattre(et)], ["Plus tard", null]])


func _proposer_suite() -> void:
	var c := Ruines.en_cours()
	var et: String = c["etage"]
	FenetreSimple.ouvrir(self, Ruines.ETAGES[et]["titre"],
		UiCommun.t("Vague %d / %d repoussée. Les PV de ton équipe ne remontent pas…\nLa suivante arrive !") % [int(c["vague"]), Ruines.nb_vagues(et)],
		[["Continuer !", _combattre.bind(et)], ["Souffler un peu", null]])


func _combattre(et: String) -> void:
	var eq := Ruines.equipe(et)
	if eq.is_empty():
		FenetreSimple.ouvrir(self, "Équipe vide", "Ajoute des héros à ton équipe dans le Deck avant de descendre.\n(Si tous tes héros sont tombés, abandonne l'étage pour recommencer.)")
		return
	var vague := int(Ruines.en_cours().get("vague", 0))
	EcranCombat.demande = {"mode": "ruines", "etage": et, "vague": vague, "acte": 6,
		"type": "boss_acte" if vague == Ruines.nb_vagues(et) - 1 else "elite",
		"equipe": eq, "ennemis": Ruines.generer(et, vague, eq), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)
