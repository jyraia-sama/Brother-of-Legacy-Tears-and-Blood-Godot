class_name EcranEvolution
extends Control
## AUTEL D'ÉVOLUTION : transforme une unité niveau 30 en sa version évoluée.
##  - à gauche : tes unités (filtres : toutes, prêtes, déjà évoluées) ;
##  - à droite : la comparaison avant / après, les sorts nouveaux ou améliorés, le coût.
## Règles : voir evolution.gd.

const SCENE := "res://scenes/evolution.tscn"
const FOND := "res://assets/fonds/fusion.png"
const C_EVO := Color("7ae0ff")
const ORDRE_RARETE := {"LEG": 5, "UR": 4, "SSR": 3, "SR": 2, "R": 1, "N": 0}

static var scene_retour := ""
## Unité à afficher en ouvrant l'écran (depuis le Deck), -1 = aucune.
static var selection_initiale := -1

var _filtre := "toutes"
var _selection := -1
var _boutons_filtre := {}
var _grille: GridContainer
var _defil: ScrollContainer
var _fiche: VBoxContainer
var _lbl_compte: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("080b10")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, FOND, UiCommun.TEINTE_FOND):
		UiCommun.fond_degrade(self, Color("0a2030"), Color("050608"))
	UiCommun.particules(self, C_EVO, true, 36)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("✦ AUTEL D'ÉVOLUTION", 32, C_EVO))
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(20, 0)
	tete.add_child(esp)
	for f in [["toutes", "À faire évoluer"], ["pretes", "Prêtes"], ["evoluees", "Déjà évoluées"]]:
		var b := UiCommun.bouton(f[1], 16)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(170, 40)
		b.pressed.connect(func():
			_filtre = f[0]
			_selection = -1
			_rafraichir())
		tete.add_child(b)
		_boutons_filtre[f[0]] = b
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(pousse)
	var donjons := UiCommun.bouton("Donjons →", 16)
	donjons.pressed.connect(func():
		EcranDonjon.scene_retour = "res://scenes/aventure.tscn"
		get_tree().change_scene_to_file(EcranDonjon.SCENE))
	tete.add_child(donjons)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 14)
	col.add_child(corps)

	var gauche := PanelContainer.new()
	gauche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gauche.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_EVO.darkened(0.45), Color(0.03, 0.05, 0.08, 0.92)))
	corps.add_child(gauche)
	var vg := VBoxContainer.new()
	vg.add_theme_constant_override("separation", 8)
	gauche.add_child(vg)
	_lbl_compte = UiCommun.label("", 16, UiCommun.C_DOUX)
	vg.add_child(_lbl_compte)
	_defil = ScrollContainer.new()
	_defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vg.add_child(_defil)
	_grille = GridContainer.new()
	_grille.columns = 5
	_grille.add_theme_constant_override("h_separation", 10)
	_grille.add_theme_constant_override("v_separation", 10)
	_defil.add_child(_grille)

	var droite := PanelContainer.new()
	droite.custom_minimum_size = Vector2(760, 0)
	droite.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_EVO.darkened(0.45), Color(0.03, 0.05, 0.08, 0.94)))
	corps.add_child(droite)
	var d2 := ScrollContainer.new()
	d2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	droite.add_child(d2)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	d2.add_child(_fiche)

	if selection_initiale >= 0:
		_selection = selection_initiale
		selection_initiale = -1
		if UnitesData.est_evolue(Sauvegarde.get_heros(_selection).get("id", "")):
			_filtre = "evoluees"
	resized.connect(_ajuster_colonnes)
	_rafraichir()
	_ajuster_colonnes()


func _ajuster_colonnes() -> void:
	var largeur := size.x - 760 - 14 - 36 - 40
	_grille.columns = maxi(2, int(largeur / 160.0))


# =====================================================================
# Liste des unités
# =====================================================================

func _liste() -> Array:
	var l: Array = []
	for h in Sauvegarde.liste_heros():
		var id: String = h["id"]
		match _filtre:
			"evoluees":
				if UnitesData.est_evolue(id):
					l.append(h)
			"pretes":
				if Evolution.peut_evoluer(id) and Evolution.raison_impossible(int(h["uid"])) == "":
					l.append(h)
			_:
				if Evolution.peut_evoluer(id):
					l.append(h)
	l.sort_custom(func(a, b): return _cle(a) > _cle(b))
	return l


func _cle(h: Dictionary) -> int:
	var prete := 1 if (Evolution.peut_evoluer(h["id"]) and Evolution.raison_impossible(int(h["uid"])) == "") else 0
	return prete * 1000000 + ORDRE_RARETE[Fusion.cle_rarete(h["id"])] * 10000 + int(h["niveau"]) * 100 + Fusion.etoiles(h)


func _rafraichir() -> void:
	for cle in _boutons_filtre:
		_boutons_filtre[cle].button_pressed = cle == _filtre
	for e in _grille.get_children():
		e.queue_free()
	var liste := _liste()
	_lbl_compte.text = {"toutes": "Unités qui peuvent évoluer (niveau %d requis)" % Evolution.NIVEAU_REQUIS,
		"pretes": "Unités prêtes : niveau %d et ressources suffisantes" % Evolution.NIVEAU_REQUIS,
		"evoluees": "Tes unités évoluées (niveau max %d)" % UnitesData.NIVEAU_MAX_EVOLUE}[_filtre] + "   —   %d" % liste.size()
	if liste.is_empty():
		var l := UiCommun.label({"toutes": "Aucune unité à faire évoluer pour l'instant.",
			"pretes": "Aucune unité prête. Monte une unité au niveau %d et récolte des ressources dans les Donjons." % Evolution.NIVEAU_REQUIS,
			"evoluees": "Aucune unité évoluée pour l'instant."}[_filtre], 16, UiCommun.C_DOUX)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(500, 0)
		_grille.add_child(l)
	for h in liste:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h, 150, 200)
		carte.pressed.connect(func():
			Audio.son("clic")
			_selection = uid
			_rafraichir())
		if uid == _selection:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(C_EVO, 0.08, 4))
		if not UnitesData.est_evolue(h["id"]):
			var r := Evolution.raison_impossible(uid)
			if r == "":
				UiCommun.badge(carte, "PRÊTE", C_EVO)
			elif int(h["niveau"]) < Evolution.NIVEAU_REQUIS:
				UiCommun.badge(carte, "Nv %d requis" % Evolution.NIVEAU_REQUIS, Color("8a8a8a"))
			else:
				UiCommun.badge(carte, "Ressources", Color("e0a040"))
		_grille.add_child(carte)
	_remplir_fiche()


# =====================================================================
# Fiche
# =====================================================================

func _remplir_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_selection)
	if h.is_empty():
		_fiche_ressources()
		return
	var id: String = h["id"]
	var deja := UnitesData.est_evolue(id)
	var id_base := UnitesData.lignee(id)
	var id_evo := id if deja else UnitesData.id_evolution(id)
	var ub := UnitesData.get_unite(id_base)
	var ue := UnitesData.get_unite(id_evo)
	var et := Fusion.etoiles(h)

	# Avant -> après
	var haut := HBoxContainer.new()
	haut.add_theme_constant_override("separation", 14)
	haut.alignment = BoxContainer.ALIGNMENT_CENTER
	_fiche.add_child(haut)
	haut.add_child(_bloc_unite(id_base, ub["nom"], "Forme de base"))
	var fleche := UiCommun.label("➜", 54, C_EVO)
	fleche.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	haut.add_child(fleche)
	haut.add_child(_bloc_unite(id_evo, ue["nom"], "Évolution  ·  jamais invocable"))
	var sous := UiCommun.label("%s  ·  %s  ·  %s  ·  étoiles et Échos conservés" % [UiCommun.texte_rarete(id_base),
		UnitesData.ELEMENTS[ub["element"]], UnitesData.ROLES[ub["role"]]], 14, UiCommun.C_DOUX)
	sous.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fiche.add_child(sous)
	if UiCommun.chemin_portrait(id_evo) == UiCommun.chemin_portrait(id_base):
		var s2 := UiCommun.label("(l'apparence évoluée arrivera plus tard)", 12, UiCommun.C_DOUX)
		s2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_fiche.add_child(s2)
	_fiche.add_child(HSeparator.new())

	# Stats
	_fiche.add_child(UiCommun.label("STATS  (%s)" % Fusion.texte_etoiles(et, false), 17, UiCommun.C_OR))
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 26)
	grille.add_theme_constant_override("v_separation", 2)
	_fiche.add_child(grille)
	var n_base := UnitesData.NIVEAU_MAX if deja else int(h["niveau"])
	var a := Fusion.appliquer_etoiles(UnitesData.stats(id_base, n_base), et)
	var b1 := Fusion.appliquer_etoiles(UnitesData.stats(id_evo, 1), et)
	var b40 := Fusion.appliquer_etoiles(UnitesData.stats(id_evo, UnitesData.NIVEAU_MAX_EVOLUE), et)
	for t in ["", "Base Nv %d" % n_base, "Évolution Nv 1", "Évolution Nv %d" % UnitesData.NIVEAU_MAX_EVOLUE]:
		grille.add_child(UiCommun.label(t, 14, UiCommun.C_DOUX))
	for p in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"], ["crit", "Crit %"], ["res", "RES"]]:
		grille.add_child(UiCommun.label(p[1], 15, UiCommun.C_TEXTE))
		grille.add_child(UiCommun.label(str(a[p[0]]), 15, UiCommun.C_TEXTE))
		grille.add_child(UiCommun.label(str(b1[p[0]]), 15, C_EVO if b1[p[0]] > a[p[0]] else UiCommun.C_TEXTE))
		grille.add_child(UiCommun.label(str(b40[p[0]]), 15, Color("8affa0")))
	var note := UiCommun.label("L'unité repart au niveau 1 (niveau max %d) : ses sorts des niveaux 10, 20 et 30 se redébloquent en la remontant." \
		% UnitesData.NIVEAU_MAX_EVOLUE, 13, UiCommun.C_DOUX)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(note)
	_fiche.add_child(HSeparator.new())

	# Sorts nouveaux ou améliorés
	_fiche.add_child(UiCommun.label("SORTS D'ÉVOLUTION", 17, UiCommun.C_OR))
	for sk in ue["skills"]:
		if not sk.get("evolue", false):
			continue
		var ancien := ""
		for s0 in ub["skills"]:
			if int(s0["niveau"]) == int(sk["niveau"]):
				ancien = s0["nom"]
		var titre := "✦ Niv. %d  ·  %s  (%s)" % [sk["niveau"], sk["nom"], sk["type"]]
		titre += ("   — remplace « %s »" % ancien) if ancien != "" else "   — NOUVEAU SORT"
		_fiche.add_child(UiCommun.label(titre, 16, C_EVO))
		var d := UiCommun.label(sk["description"], 14, UiCommun.C_TEXTE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(d)

	if deja:
		_fiche.add_child(HSeparator.new())
		_fiche.add_child(UiCommun.label("Cette unité a déjà évolué.", 16, Color("8affa0")))
		return

	# Coût et conditions
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("COÛT", 17, UiCommun.C_OR))
	var cout := Evolution.cout(id)
	for r in cout:
		var poss := Sauvegarde.get_objet(r)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 8)
		ligne.add_child(UiCommun.icone_objet(r, 30))
		ligne.add_child(UiCommun.label("%s :  %d / %d" % [Reliquaire.nom(r), poss, int(cout[r])], 16,
			Color("8affa0") if poss >= int(cout[r]) else Color("ff7a6a")))
		_fiche.add_child(ligne)
	var niv_ok := int(h["niveau"]) >= Evolution.NIVEAU_REQUIS
	_fiche.add_child(UiCommun.label(("✔ " if niv_ok else "✘ ") + "Niveau %d requis (actuellement Nv %d)" % [Evolution.NIVEAU_REQUIS, int(h["niveau"])], 16,
		Color("8affa0") if niv_ok else Color("ff7a6a")))
	var raison := Evolution.raison_impossible(_selection)
	var go := UiCommun.bouton("✦ FAIRE ÉVOLUER", 22)
	go.custom_minimum_size = Vector2(0, 58)
	go.disabled = raison != ""
	var sg := UiCommun.style_carte(C_EVO, 0.0, 2)
	sg.bg_color = C_EVO.darkened(0.72)
	go.add_theme_stylebox_override("normal", sg)
	var sgh := sg.duplicate() as StyleBoxFlat
	sgh.bg_color = C_EVO.darkened(0.55)
	go.add_theme_stylebox_override("hover", sgh)
	go.pressed.connect(_confirmer_evolution)
	_fiche.add_child(go)
	if raison != "":
		var lr := UiCommun.label(raison, 14, Color("ffb070"))
		lr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(lr)
		var ou := UiCommun.label("Les ressources se récoltent dans les Donjons (Aventure → Donjon).", 13, UiCommun.C_DOUX)
		_fiche.add_child(ou)


func _bloc_unite(id: String, nom: String, legende: String) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(280, 0)
	vb.add_theme_constant_override("separation", 4)
	var ill: Control
	if UiCommun.chemin_portrait(id) != "":
		ill = UiCommun.illustration(id, Vector2(220, 220), 12, UiCommun.couleur_rarete(id) if not UnitesData.est_evolue(id) else C_EVO, 3)
	else:
		ill = UiCommun.portrait(id, 180)
	ill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(ill)
	var l := UiCommun.label(nom, 19, C_EVO if UnitesData.est_evolue(id) else UiCommun.couleur_rarete(id))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(l)
	var s := UiCommun.label(legende, 13, UiCommun.C_DOUX)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	return vb


## Sans unité choisie : explication et toutes les ressources possédées.
func _fiche_ressources() -> void:
	_fiche.add_child(UiCommun.label("COMMENT ÇA MARCHE", 18, UiCommun.C_OR))
	for t in ["Choisis une unité à gauche pour voir son évolution.",
		"Une unité doit être au niveau %d. Elle garde ses étoiles et ses Échos, repart au niveau 1 et peut monter jusqu'au niveau %d." % [Evolution.NIVEAU_REQUIS, UnitesData.NIVEAU_MAX_EVOLUE],
		"Chaque évolution coûte des ressources de l'élément de l'unité et du Sang (Puits de Sang).",
		"Plus l'unité est rare, plus il faut de grosses ressources : Gouttes (N, R), Larmes (R, SR, SSR), Cœurs (SR à Légende)."]:
		var l := UiCommun.label("•  " + t, 14, UiCommun.C_TEXTE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(l)
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("COÛT PAR RARETÉ", 16, UiCommun.C_OR))
	for r in ["N", "R", "SR", "SSR", "UR", "LEG"]:
		var c: Dictionary = Evolution.COUTS[r]
		var morceaux: Array = []
		for i in 3:
			if int(c["element"][i]) > 0:
				morceaux.append("%d %s" % [int(c["element"][i]), Evolution.NOMS_TAILLE[Evolution.TAILLES[i]] + "s"])
		var sang: Array = []
		for i in 3:
			if int(c["sang"][i]) > 0:
				sang.append("%d %s de Sang" % [int(c["sang"][i]), Evolution.NOMS_TAILLE[Evolution.TAILLES[i]] + "s"])
		_fiche.add_child(UiCommun.label("%s :  %s de l'élément  +  %s" % ["Légende" if r == "LEG" else r, ", ".join(morceaux), ", ".join(sang)], 14, UiCommun.C_TEXTE))
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("TES RESSOURCES", 16, UiCommun.C_OR))
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 20)
	grille.add_theme_constant_override("v_separation", 6)
	_fiche.add_child(grille)
	for el in Evolution.ESSENCES:
		for t in Evolution.TAILLES:
			var r := Evolution.ressource(el, t)
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 6)
			h.add_child(UiCommun.icone_objet(r, 28))
			h.add_child(UiCommun.label("%s  %d" % [Reliquaire.nom(r), Sauvegarde.get_objet(r)], 14,
				UiCommun.C_TEXTE if Sauvegarde.get_objet(r) > 0 else UiCommun.C_DOUX))
			grille.add_child(h)


func _confirmer_evolution() -> void:
	var h := Sauvegarde.get_heros(_selection)
	if h.is_empty():
		return
	var d := ConfirmationDialog.new()
	d.title = "Évolution"
	d.dialog_text = "Faire évoluer %s en %s ?\n\nL'unité repart au NIVEAU 1 (niveau max %d).\nElle garde ses étoiles, ses Échos et sa place dans l'équipe.\nLes ressources seront dépensées." % [
		UnitesData.get_unite(h["id"])["nom"], UnitesData.get_unite(UnitesData.id_evolution(h["id"]))["nom"], UnitesData.NIVEAU_MAX_EVOLUE]
	d.ok_button_text = "Évoluer"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		_evoluer())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(520, 0))


func _evoluer() -> void:
	var evo := Evolution.evoluer(_selection)
	if evo == "":
		Audio.son("erreur")
		return
	Audio.son("legende")
	_effet(UnitesData.get_unite(evo)["nom"])
	_filtre = "evoluees"
	_rafraichir()


## Petit éclat lumineux + nom de l'évolution au centre de l'écran.
func _effet(nom: String) -> void:
	var voile := ColorRect.new()
	voile.color = Color(C_EVO, 0.0)
	voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	var l := UiCommun.label("✦ %s ✦" % nom, 52, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", C_EVO.darkened(0.5))
	l.add_theme_constant_override("outline_size", 12)
	l.modulate.a = 0.0
	add_child(l)
	var t := create_tween()
	t.tween_property(voile, "color:a", 0.55, 0.25)
	t.parallel().tween_property(l, "modulate:a", 1.0, 0.25)
	t.tween_interval(1.4)
	t.tween_property(voile, "color:a", 0.0, 0.5)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(func():
		voile.queue_free()
		l.queue_free())


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
