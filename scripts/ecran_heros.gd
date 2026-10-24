class_name EcranHeros
extends EcranBase
## MON HÉROS : le héros de départ (fiche complète) et le profil du joueur
## (niveau de compte, titre, statistiques, collection).

const SCENE := "res://scenes/heros.tscn"


func _titre_ecran() -> String:
	return UiCommun.t("MON HÉROS")


func _fond_ecran() -> String:
	return "res://assets/fonds/profil.png"


func _remplir() -> void:
	var corps := HBoxContainer.new()
	corps.add_theme_constant_override("separation", 18)
	_contenu.add_child(corps)
	var g := VBoxContainer.new()
	g.custom_minimum_size = Vector2(620, 0)
	g.add_theme_constant_override("separation", 8)
	corps.add_child(g)
	var d := VBoxContainer.new()
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.add_theme_constant_override("separation", 8)
	corps.add_child(d)
	_fiche_heros(g)
	_profil(d)


func _fiche_heros(g: VBoxContainer) -> void:
	var h := Sauvegarde.get_heros_depart()
	if h.is_empty():
		g.add_child(UiCommun.label(UiCommun.t("Aucun héros de départ."), 16))
		return
	var id: String = h["id"]
	var uid := int(h["uid"])
	var u := UnitesData.get_unite(id)
	var haut := HBoxContainer.new()
	haut.add_theme_constant_override("separation", 14)
	g.add_child(haut)
	var ill: Control = UiCommun.illustration(id, Vector2(240, 300), 12, UiCommun.couleur_rarete(id), 3) \
		if UiCommun.chemin_portrait(id) != "" else UiCommun.portrait(id, 220)
	haut.add_child(ill)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	haut.add_child(vb)
	var nom := UiCommun.label(UiCommun.t(str(u["nom"])), 26, UiCommun.couleur_rarete(id))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nom)
	vb.add_child(UiCommun.label("%s · %s · %s%s" % [UiCommun.texte_rarete(id), UnitesData.nom_element(u["element"]), UnitesData.nom_role(u["role"]),
		(" · " + str(u["race"])) if str(u.get("race", "")) != "" else ""], 14, UiCommun.C_DOUX))
	var niv := int(h["niveau"])
	var nmax := Fusion.niveau_max(h)
	vb.add_child(UiCommun.label(UiCommun.t("Niveau %d / %d   ·   %s") % [niv, nmax, Fusion.texte_etoiles(Fusion.etoiles(h))], 17, Color("ffd060")))
	if niv < nmax:
		vb.add_child(_barre(int(h["xp"]), Sauvegarde.xp_heros_pour_niveau(niv), Color("7ab8ff"), 300))
	if UiCommun.info_niveau_heros(h) != "":
		vb.add_child(UiCommun.label(UiCommun.info_niveau_heros(h), 13, Color("ffb070")))
	var s := Sauvegarde.stats_heros(uid)
	var grille := GridContainer.new()
	grille.columns = 2
	grille.add_theme_constant_override("h_separation", 26)
	vb.add_child(grille)
	for p in [["pv", UiCommun.t("PV")], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"], ["crit", "Crit %"], ["degats_crit", UiCommun.t("Dégâts crit %")], ["res", "RES"]]:
		var dom: bool = p[0] in u.get("dominantes", [])
		grille.add_child(UiCommun.label(UiCommun.t("%s : %s") % [p[1], str(int(s[p[0]]))], 16, UiCommun.C_LEGENDE if dom else UiCommun.C_TEXTE))
	vb.add_child(UiCommun.label(UiCommun.t("Échos Sanguins équipés : %d / 6   ·   Puissance %s") % [Sauvegarde.echos_de(uid).size(),
		_nombre(int(s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7))], 14, Color("d0453a")))
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 8)
	vb.add_child(boutons)
	for b in [["Deck", EcranDeck.SCENE, "deck"], [UiCommun.t("Échos Sanguins"), EcranEchos.SCENE, "echos"], [UiCommun.t("Évolution"), EcranEvolution.SCENE, "evo"]]:
		var bt := UiCommun.bouton(b[0], 15)
		bt.pressed.connect(_aller.bind(b[2], uid))
		boutons.add_child(bt)
	FicheSorts.remplir(g, uid, rafraichir)


func _aller(ou: String, uid: int) -> void:
	match ou:
		"deck":
			EcranDeck.scene_retour = SCENE
			get_tree().change_scene_to_file(EcranDeck.SCENE)
		"echos":
			EcranEchos.scene_retour = SCENE
			get_tree().change_scene_to_file(EcranEchos.SCENE)
		"evo":
			EcranEvolution.scene_retour = SCENE
			EcranEvolution.selection_initiale = uid
			get_tree().change_scene_to_file(EcranEvolution.SCENE)


func _profil(d: VBoxContainer) -> void:
	var pseudo := EnLigne.nom_complet() if EnLigne.est_connecte() else UiCommun.t("L'aîné des Valcendre (hors ligne)")
	var titre := Succes.titre_actuel()
	d.add_child(UiCommun.label(pseudo, 28, UiCommun.C_LEGENDE))
	if titre != "":
		d.add_child(UiCommun.label("« %s »" % titre, 18, Color("ffb070")))
	var niv := Sauvegarde.get_niveau_compte()
	d.add_child(UiCommun.label(UiCommun.t("Niveau de compte %d / %d   ·   Stamina max %d") % [niv, Sauvegarde.NIVEAU_COMPTE_MAX, Sauvegarde.get_stamina_max()], 17, UiCommun.C_TEXTE))
	if not Sauvegarde.niveau_compte_max_atteint():
		var l := HBoxContainer.new()
		l.add_theme_constant_override("separation", 10)
		l.add_child(_barre(Sauvegarde.get_xp_compte(), Sauvegarde.xp_pour_niveau(niv), UiCommun.C_OR, 320))
		l.add_child(UiCommun.label("XP %d / %d" % [Sauvegarde.get_xp_compte(), Sauvegarde.xp_pour_niveau(niv)], 14, UiCommun.C_DOUX))
		d.add_child(l)

	# Titre
	var lt := HBoxContainer.new()
	lt.add_theme_constant_override("separation", 10)
	d.add_child(lt)
	lt.add_child(UiCommun.label(UiCommun.t("Titre affiché :"), 16, UiCommun.C_OR))
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	opt.custom_minimum_size = Vector2(280, 38)
	opt.add_item(UiCommun.t("Aucun"))
	var titres := Succes.titres()
	for t in titres:
		opt.add_item(t)
	opt.select(titres.find(titre) + 1)
	opt.item_selected.connect(func(i: int):
		Succes.choisir_titre("" if i == 0 else titres[i - 1])
		rafraichir())
	lt.add_child(opt)
	if titres.is_empty():
		lt.add_child(UiCommun.label(UiCommun.t("(termine un Succès pour gagner un titre)"), 13, UiCommun.C_DOUX))
	d.add_child(HSeparator.new())

	# Statistiques
	d.add_child(UiCommun.label(UiCommun.t("STATISTIQUES"), 18, UiCommun.C_OR))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 30)
	g.add_theme_constant_override("v_separation", 4)
	d.add_child(g)
	var total_bestiaire := UnitesData.toutes().size()
	var lignes := [
		[UiCommun.t("Chapitres terminés"), "%d / %d" % [Sauvegarde.nombre_chapitres_termines(), ActesData.nb_chapitres_visibles()]],
		[UiCommun.t("Combats gagnés / perdus"), "%s / %s" % [_nombre(Sauvegarde.get_stat("combats_gagnes")), _nombre(Sauvegarde.get_stat("combats_perdus"))]],
		[UiCommun.t("Bestiaire"), "%d / %d" % [Sauvegarde.donnees["bestiaire"].size(), total_bestiaire]],
		[UiCommun.t("Invocations"), _nombre(Succes.valeur("invocations"))],
		[UiCommun.t("Record Tour de l'Enfer"), UiCommun.t("étage %d") % Tours.record("enfer")],
		[UiCommun.t("Record Tour du Paradis"), UiCommun.t("étage %d") % Tours.record("paradis")],
		[UiCommun.t("Donjons terminés"), _nombre(Sauvegarde.get_stat("donjons_termines"))],
		[UiCommun.t("Boss de Monde abattus"), _nombre(Sauvegarde.get_stat("boss_monde_abattus"))],
		[UiCommun.t("Marches Maudites (record)"), "%d  (%d pts)" % [Sauvegarde.get_stat("marches"), Marche.record()]],
		[UiCommun.t("Missions de la Compagnie"), _nombre(Sauvegarde.get_stat("missions_compagnie"))],
		[UiCommun.t("Évolutions"), _nombre(Sauvegarde.get_stat("evolutions"))],
		[UiCommun.t("Or gagné (total)"), _nombre(Sauvegarde.get_stat("or_total_gagne"))],
		[UiCommun.t("Stamina dépensée"), _nombre(Sauvegarde.get_stat("stamina_depensee"))],
		[UiCommun.t("Succès obtenus"), UiCommun.t("%d paliers") % _paliers()],
	]
	for l in lignes:
		g.add_child(UiCommun.label(l[0], 15, UiCommun.C_DOUX))
		g.add_child(UiCommun.label(l[1], 15, UiCommun.C_TEXTE))
	d.add_child(HSeparator.new())

	# Collection
	d.add_child(UiCommun.label(UiCommun.t("COLLECTION  (%d unités)") % Sauvegarde.liste_heros().size(), 18, UiCommun.C_OR))
	var par := {}
	for h in Sauvegarde.liste_heros():
		var r := Fusion.cle_rarete(h["id"])
		par[r] = int(par.get(r, 0)) + 1
	var lc := HBoxContainer.new()
	lc.add_theme_constant_override("separation", 18)
	d.add_child(lc)
	for r in ["N", "R", "SR", "SSR", "UR", "LEG"]:
		lc.add_child(UiCommun.label("%s : %d" % [UiCommun.t("Légende") if r == "LEG" else r, int(par.get(r, 0))], 16, UiCommun.COULEURS_RARETE[r]))


func _paliers() -> int:
	var n := 0
	for s in Succes.LISTE:
		n += Succes.reclames(s["id"])
	return n
