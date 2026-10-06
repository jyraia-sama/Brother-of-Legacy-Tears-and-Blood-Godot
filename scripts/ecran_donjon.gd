class_name EcranDonjon
extends Control
## DONJONS : choix du donjon (6), du niveau (1 à 10) et lancement d'une expédition.
##  - à gauche : les 6 donjons ;
##  - au centre : les 10 niveaux du donjon choisi ;
##  - à droite : les 4 combats, le butin, les ressources possédées et le bouton de départ.

const SCENE := "res://scenes/donjon.tscn"

static var scene_retour := ""
static var donjon_courant := "feu"
static var niveau_courant := 0      # 0 = le prochain niveau à faire

var _lbl_stamina: CaseStamina
var _col_donjons: VBoxContainer
var _col_niveaux: VBoxContainer
var _fiche: VBoxContainer
var _particules: CPUParticles2D
var _fond: TextureRect
var _marge: MarginContainer


func _ready() -> void:
	Sauvegarde.charger()
	Donjons.terminer()        # une expédition abandonnée (retour) ne se reprend pas
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0b0708")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	_fond = UiCommun.fond_degrade(self, Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	UiCommun.fond_image(self, "res://assets/fonds/donjons.png", UiCommun.TEINTE_FOND)

	var marge := MarginContainer.new()
	_marge = marge
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marge.add_child(col)

	# En-tête
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Aventure")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("DONJONS", 32, UiCommun.C_OR))
	var info := UiCommun.label("4 combats d'affilée, sans soin entre deux : vague, mini-boss, vague, boss.", 15, UiCommun.C_DOUX)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tete.add_child(info)
	var evo := UiCommun.bouton("✦ Autel d'Évolution", 17)
	evo.pressed.connect(func():
		EcranEvolution.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranEvolution.SCENE))
	tete.add_child(evo)
	_lbl_stamina = CaseStamina.new()
	tete.add_child(_lbl_stamina)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 14)
	col.add_child(corps)

	_col_donjons = VBoxContainer.new()
	_col_donjons.custom_minimum_size = Vector2(430, 0)
	_col_donjons.add_theme_constant_override("separation", 8)
	corps.add_child(_col_donjons)

	var p_niv := PanelContainer.new()
	p_niv.custom_minimum_size = Vector2(300, 0)
	p_niv.add_theme_stylebox_override("panel", UiCommun.style_panneau(UiCommun.C_OR.darkened(0.3)))
	corps.add_child(p_niv)
	_col_niveaux = VBoxContainer.new()
	_col_niveaux.add_theme_constant_override("separation", 6)
	p_niv.add_child(_col_niveaux)

	var p_fiche := PanelContainer.new()
	p_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_fiche.add_theme_stylebox_override("panel", UiCommun.style_panneau(UiCommun.C_OR.darkened(0.3)))
	corps.add_child(p_fiche)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p_fiche.add_child(defil)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	defil.add_child(_fiche)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj_stamina)
	add_child(t)
	_maj_stamina()
	_rafraichir()


func _couleur(d: String) -> Color:
	return Color("#" + str(Donjons.DONJONS[d]["couleur"]))


func _niveau_choisi() -> int:
	var d := donjon_courant
	if niveau_courant < 1 or not Donjons.est_ouvert(d, niveau_courant):
		niveau_courant = mini(Donjons.NIVEAUX, Donjons.niveau_termine(d) + 1)
	return niveau_courant


func _rafraichir() -> void:
	var c := _couleur(donjon_courant)
	# Ambiance aux couleurs du donjon
	var g := (_fond.texture as GradientTexture2D).gradient
	g.set_color(0, c.darkened(0.7))
	g.set_color(1, Color("050303"))
	if _particules != null:
		_particules.queue_free()
	_particules = UiCommun.particules(self, c, donjon_courant in ["feu", "neutre", "tenebres"], 40)
	move_child(_particules, _marge.get_index())
	_remplir_donjons()
	_remplir_niveaux()
	_remplir_fiche()


# =====================================================================
# Colonne des donjons
# =====================================================================

func _remplir_donjons() -> void:
	for e in _col_donjons.get_children():
		e.queue_free()
	for d in Donjons.ORDRE:
		var infos: Dictionary = Donjons.DONJONS[d]
		var c := _couleur(d)
		var choisi: bool = d == donjon_courant
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(0, 134)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var st := UiCommun.style_carte(c if choisi else c.darkened(0.45), 0.02 if choisi else 0.0, 3 if choisi else 2)
		st.bg_color = c.darkened(0.82 if choisi else 0.9)
		if choisi:
			st.shadow_color = Color(c, 0.5)
			st.shadow_size = 10
		var st_h := st.duplicate() as StyleBoxFlat
		st_h.border_color = c
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st_h)
		b.add_theme_stylebox_override("pressed", st_h)
		b.pressed.connect(func():
			Audio.son("clic")
			donjon_courant = d
			niveau_courant = 0
			_rafraichir())
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 14
		h.offset_right = -12
		h.add_theme_constant_override("separation", 12)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var pt := UiCommun.portrait(infos["boss"], 86)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(pt)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(vb)
		vb.add_child(UiCommun.label(infos["nom"], 20, c.lightened(0.25)))
		vb.add_child(UiCommun.label("%s  ·  ressources %s" % [UnitesData.ELEMENTS[d], Evolution.ESSENCES[d]["nom"]], 14, UiCommun.C_DOUX))
		var fait := Donjons.niveau_termine(d)
		vb.add_child(UiCommun.label("Niveau %d / %d terminé%s" % [fait, Donjons.NIVEAUX, "  ✔" if fait >= Donjons.NIVEAUX else ""], 14,
			UiCommun.C_OR if fait > 0 else UiCommun.C_DOUX))
		_col_donjons.add_child(b)


# =====================================================================
# Colonne des niveaux
# =====================================================================

func _remplir_niveaux() -> void:
	for e in _col_niveaux.get_children():
		e.queue_free()
	var d := donjon_courant
	var c := _couleur(d)
	var choisi := _niveau_choisi()
	var titre := UiCommun.label("NIVEAUX", 18, UiCommun.C_OR)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col_niveaux.add_child(titre)
	var fait := Donjons.niveau_termine(d)
	for n in range(1, Donjons.NIVEAUX + 1):
		var ouvert := Donjons.est_ouvert(d, n)
		var b := UiCommun.bouton("", 17)
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var taille: String = Evolution.TAILLES[[0, 0, 0, 1, 1, 1, 1, 2, 2, 2][n - 1]]
		var texte := "Niveau %d   ·   %s" % [n, Evolution.NOMS_TAILLE[taille] + "s"]
		if n <= fait:
			texte = "✔  " + texte
		elif not ouvert:
			texte = "Niveau %d  —  verrouillé" % n
		b.text = texte
		b.disabled = not ouvert
		var st := StyleBoxFlat.new()
		st.bg_color = c.darkened(0.75) if n == choisi else Color(0.1, 0.06, 0.07, 0.9)
		st.border_color = c if n == choisi else c.darkened(0.6)
		st.set_border_width_all(3 if n == choisi else 1)
		st.set_corner_radius_all(8)
		for etat in ["normal", "hover", "pressed", "disabled"]:
			var s2 := st.duplicate() as StyleBoxFlat
			if etat == "hover":
				s2.border_color = c
			elif etat == "disabled":
				s2.bg_color = Color(0.06, 0.05, 0.05, 0.8)
				s2.border_color = Color(0.25, 0.22, 0.22)
			b.add_theme_stylebox_override(etat, s2)
		b.add_theme_color_override("font_color", UiCommun.C_TEXTE if n != choisi else c.lightened(0.5))
		b.pressed.connect(func():
			Audio.son("clic")
			niveau_courant = n
			_remplir_niveaux()
			_remplir_fiche())
		_col_niveaux.add_child(b)


# =====================================================================
# Fiche du niveau choisi
# =====================================================================

func _remplir_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	var d := donjon_courant
	var n := _niveau_choisi()
	var infos: Dictionary = Donjons.DONJONS[d]
	var c := _couleur(d)
	_fiche.add_child(UiCommun.label("%s  —  NIVEAU %d" % [str(infos["nom"]).to_upper(), n], 26, c.lightened(0.3)))
	var st := UiCommun.label(infos["sous_titre"], 15, UiCommun.C_DOUX)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(st)
	_fiche.add_child(HSeparator.new())

	# Les 4 combats
	_fiche.add_child(UiCommun.label("L'EXPÉDITION", 17, UiCommun.C_OR))
	for v in Donjons.VAGUES.size():
		var type: String = Donjons.VAGUES[v]
		var ennemis := Donjons.generer(d, n, v)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		_fiche.add_child(ligne)
		var chef: String = ennemis[0]["id"]
		for e in ennemis:
			if e.get("boss", false) or e.get("elite", false):
				chef = e["id"]
		ligne.add_child(UiCommun.portrait(chef if type != "vague" else ennemis[0]["id"], 54))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(vb)
		vb.add_child(UiCommun.label("%d.  %s   (niveau %d)" % [v + 1, Donjons.NOMS_VAGUE[type], int(ennemis[0]["niveau"])], 16,
			Color("ff9a7a") if type == "boss" else (Color("ffd060") if type == "mini_boss" else UiCommun.C_TEXTE)))
		var noms: Array = []
		for e in ennemis:
			var u := UnitesData.get_unite(e["id"])
			var nom: String = e.get("nom", u["nom"]) if Sauvegarde.est_decouvert(e["id"]) or type != "vague" else "???"
			noms.append(nom)
		var l := UiCommun.label(", ".join(noms), 13, UiCommun.C_DOUX)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(l)
		var ub := UnitesData.get_unite(chef)
		if type == "boss" and not ub["phase2"].is_empty():
			vb.add_child(UiCommun.label("Phase 2 : " + str(ub["phase2"]["nom"]), 13, Color("ff9a7a")))

	# Estimation : ta puissance comparée à celle de l'équipe conseillée pour ce niveau
	var equipe := _puissance_equipe()
	var rapport := equipe / maxf(1.0, Donjons.puissance_conseillee(n))
	var diff := "Très difficile" if rapport < 0.85 else ("Difficile" if rapport < 1.05 else ("Équilibré" if rapport < 1.3 else "Facile"))
	var coul := Color("ff5a4a") if rapport < 0.85 else (Color("ffa040") if rapport < 1.05 else (Color("e0d060") if rapport < 1.3 else Color("6ad06a")))
	_fiche.add_child(UiCommun.label("Puissance conseillée : %d   ·   Ton équipe : %d" % [int(Donjons.puissance_conseillee(n)), int(equipe)], 15, UiCommun.C_TEXTE))
	_fiche.add_child(UiCommun.label("Estimation : " + diff, 17, coul))

	# Butin
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("BUTIN À LA VICTOIRE FINALE", 17, UiCommun.C_OR))
	var grille := HFlowContainer.new()
	grille.add_theme_constant_override("h_separation", 22)
	grille.add_theme_constant_override("v_separation", 6)
	_fiche.add_child(grille)
	var b := Donjons.butin(d, n)
	for o in b:
		grille.add_child(_ligne_objet(o, "x%d" % int(b[o])))
	grille.add_child(UiCommun.label("+ %d or" % Donjons.or_victoire(n), 15, Color("ffd060")))
	_fiche.add_child(UiCommun.label("%d %% de chance d'une %s en bonus." % [int(Donjons.CHANCE_BONUS * 100),
		Reliquaire.nom(Donjons.ressource_principale(d, n))], 13, UiCommun.C_DOUX))

	# Ressources possédées
	_fiche.add_child(UiCommun.label("TES RESSOURCES " + str(Evolution.ESSENCES[d]["nom"]).to_upper(), 15, UiCommun.C_OR))
	var poss := HBoxContainer.new()
	poss.add_theme_constant_override("separation", 22)
	_fiche.add_child(poss)
	for t in Evolution.TAILLES:
		var r := Evolution.ressource(d, t)
		poss.add_child(_ligne_objet(r, "%d" % Sauvegarde.get_objet(r)))
	var usage := "toutes les évolutions (en plus de la ressource de l'élément)" if d == "neutre" \
		else "faire évoluer les unités %s" % ("de " + UnitesData.ELEMENTS[d] if d != "eau" else "d'Eau")
	_fiche.add_child(UiCommun.label("Sert à " + usage + ".", 13, UiCommun.C_DOUX))

	# Équipe et départ
	_fiche.add_child(HSeparator.new())
	var noms: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		noms.append("%s Nv %d" % [UnitesData.get_unite(h["id"])["nom"], int(h["niveau"])])
	var eq := UiCommun.label("Équipe : " + (", ".join(noms) if not noms.is_empty() else "aucune unité"), 14, UiCommun.C_TEXTE)
	eq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(eq)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_fiche.add_child(actions)
	var deck := UiCommun.bouton("Modifier l'équipe", 15)
	deck.pressed.connect(func():
		EcranDeck.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranDeck.SCENE))
	actions.add_child(deck)
	var go := UiCommun.bouton("LANCER L'EXPÉDITION  (%d stamina)" % Donjons.COUT_STAMINA[n - 1], 20)
	go.custom_minimum_size = Vector2(0, 56)
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sg := UiCommun.style_carte(c, 0.02, 2)
	sg.bg_color = c.darkened(0.7)
	go.add_theme_stylebox_override("normal", sg)
	var sgh := sg.duplicate() as StyleBoxFlat
	sgh.bg_color = c.darkened(0.55)
	go.add_theme_stylebox_override("hover", sgh)
	go.pressed.connect(_lancer)
	actions.add_child(go)


func _ligne_objet(o: String, quantite: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UiCommun.icone_objet(o, 30))
	h.add_child(UiCommun.label("%s  %s" % [Reliquaire.nom(o), quantite], 15, UiCommun.C_TEXTE))
	return h


func _puissance_equipe() -> float:
	var t := 0.0
	for uid in Sauvegarde.get_equipe():
		var s := Sauvegarde.stats_heros(uid)
		t += s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7
	return t


func _lancer() -> void:
	var raison := Donjons.demarrer(donjon_courant, _niveau_choisi())
	if raison != "":
		Audio.son("erreur")
		_message(raison)
		_maj_stamina()
		return
	EcranCombat.demande = Donjons.demande_combat()
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _maj_stamina() -> void:
	_lbl_stamina.maj()


func _message(texte: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Donjons"
	dlg.dialog_text = texte
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered(Vector2i(460, 0))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else "res://scenes/aventure.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
