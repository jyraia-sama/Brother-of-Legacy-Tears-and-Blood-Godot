class_name ProfilPublic
extends RefCounted
## PROFIL PUBLIC : ce que les autres joueurs voient quand ils ouvrent ton profil
## (Social, Guilde, classements...).
##
## Le jeu envoie une « vitrine » (titre, héros principal, équipe, statistiques, collection)
## dans la colonne profils.vitrine (voir supabase/06_profil_public.sql). Le serveur y ajoute
## les résultats d'Arène, d'Arène classée et de Marche Maudite.

const C_EN_LIGNE := Color("8fe07a")


## La vitrine de MON profil, envoyée par EnLigne avec le niveau et la présence.
static func vitrine() -> Dictionary:
	Sauvegarde.charger()
	var v := {"version": Version.NUMERO, "titre": Succes.titre_actuel()}
	var h := Sauvegarde.get_heros_depart()
	if not h.is_empty():
		var s := Sauvegarde.stats_heros(int(h["uid"]))
		v["heros"] = {"id": h["id"], "niveau": int(h["niveau"]), "etoiles": Fusion.etoiles(h),
			"echos": Sauvegarde.echos_de(int(h["uid"])).size(),
			"stats": {"pv": int(s["pv"]), "atk": int(s["atk"]), "def": int(s["def"]), "agi": int(s["agi"]), "mag": int(s["mag"])}}
	var equipe: Array = []
	for u in Arene.equipe_attaque():
		equipe.append({"id": u["id"], "niveau": int(u.get("niveau", 1)), "etoiles": int(u.get("etoiles", 0))})
	v["equipe"] = equipe
	v["puissance"] = Arene.puissance(Arene.equipe_attaque())
	var paliers := 0
	for sd in Succes.LISTE:
		paliers += Succes.reclames(sd["id"])
	v["stats"] = {
		"chapitres": Sauvegarde.nombre_chapitres_termines(),
		"combats_gagnes": Sauvegarde.get_stat("combats_gagnes"),
		"bestiaire": Sauvegarde.donnees["bestiaire"].size(),
		"invocations": Succes.valeur("invocations"),
		"tour_enfer": Tours.record("enfer"),
		"tour_paradis": Tours.record("paradis"),
		"donjons": Sauvegarde.get_stat("donjons_termines"),
		"boss_monde": Sauvegarde.get_stat("boss_monde_abattus"),
		"evolutions": Sauvegarde.get_stat("evolutions"),
		"succes": paliers,
	}
	var par := {}
	for hh in Sauvegarde.liste_heros():
		var r := Fusion.cle_rarete(hh["id"])
		par[r] = int(par.get(r, 0)) + 1
	v["collection"] = par
	v["nb_unites"] = Sauvegarde.liste_heros().size()
	return v


## Ouvre la fiche d'un autre joueur (fenêtre).
static func ouvrir(parent: Node, id_joueur: String) -> void:
	var r: Dictionary = await EnLigne.appeler("profil_joueur", {"p_joueur": id_joueur})
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	if not r.ok or not (r.data is Dictionary):
		FenetreSimple.ouvrir(parent, "Profil", r.erreur if not r.ok else "Joueur introuvable.")
		return
	afficher(parent, r.data)


## Construit la fenêtre à partir de la réponse du serveur (profil_joueur).
static func afficher(parent: Node, p: Dictionary) -> void:
	var vit: Dictionary = p.get("vitrine", {}) if p.get("vitrine", {}) is Dictionary else {}

	var defil := ScrollContainer.new()
	defil.custom_minimum_size = Vector2(980, 560)
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var corps := HBoxContainer.new()
	corps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 22)
	defil.add_child(corps)

	# ---------- Colonne gauche : identité et héros principal ----------
	var g := VBoxContainer.new()
	g.custom_minimum_size = Vector2(330, 0)
	g.add_theme_constant_override("separation", 6)
	corps.add_child(g)
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	g.add_child(tete)
	tete.add_child(UiCommun.avatar(str(p.get("heros_vitrine", "")), str(p.get("pseudo", "")), 84))
	var id_col := VBoxContainer.new()
	id_col.add_theme_constant_override("separation", 2)
	tete.add_child(id_col)
	id_col.add_child(UiCommun.label(EnLigne.nom_complet(str(p.get("pseudo", "?"))), 24, UiCommun.C_LEGENDE))
	if str(vit.get("titre", "")) != "":
		id_col.add_child(UiCommun.label("« %s »" % vit["titre"], 16, Color("ffb070")))
	id_col.add_child(UiCommun.label("Niveau de compte %d" % int(p.get("niveau", 1)), 17))
	var pres := EnLigne.texte_presence(str(p.get("vu_le", "")))
	id_col.add_child(UiCommun.label(pres, 15, C_EN_LIGNE if pres == "En ligne" else UiCommun.C_DOUX))
	var guilde := str(p.get("guilde", ""))
	g.add_child(UiCommun.label("Guilde : " + (guilde + " (" + EcranSocial._nom_role(str(p.get("role", ""))) + ")" if guilde != "" else "aucune"), 16, UiCommun.C_OR))
	g.add_child(UiCommun.label("Joueur depuis le " + _date(str(p.get("cree_le", ""))), 14, UiCommun.C_DOUX))

	var h: Dictionary = vit.get("heros", {}) if vit.get("heros", {}) is Dictionary else {}
	var id_h := str(h.get("id", p.get("heros_vitrine", "")))
	if id_h != "" and UnitesData.existe(id_h):
		g.add_child(HSeparator.new())
		g.add_child(UiCommun.label("HÉROS PRINCIPAL", 16, UiCommun.C_OR))
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 12)
		g.add_child(hh)
		var ill: Control = UiCommun.illustration(id_h, Vector2(130, 170), 10, UiCommun.couleur_rarete(id_h), 3) \
			if UiCommun.chemin_portrait(id_h) != "" else UiCommun.portrait(id_h, 120)
		hh.add_child(ill)
		var hv := VBoxContainer.new()
		hv.add_theme_constant_override("separation", 2)
		hh.add_child(hv)
		var u := UnitesData.get_unite(id_h)
		var nom := UiCommun.label(str(u["nom"]), 17, UiCommun.couleur_rarete(id_h))
		nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nom.custom_minimum_size = Vector2(180, 0)
		hv.add_child(nom)
		if not h.is_empty():
			hv.add_child(UiCommun.label("Niv. %d  ·  %s" % [int(h.get("niveau", 1)), Fusion.texte_etoiles(int(h.get("etoiles", 0)), false)], 14, Color("ffd060")))
			var st: Dictionary = h.get("stats", {}) if h.get("stats", {}) is Dictionary else {}
			for k in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"]]:
				if st.has(k[0]):
					hv.add_child(UiCommun.label("%s : %s" % [k[1], _nombre(int(st[k[0]]))], 14))
			hv.add_child(UiCommun.label("Échos : %d / 6" % int(h.get("echos", 0)), 14, Color("d0453a")))

	# ---------- Colonne droite : équipe, compétitions, statistiques, collection ----------
	var d := VBoxContainer.new()
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.add_theme_constant_override("separation", 8)
	corps.add_child(d)

	var equipe: Array = vit.get("equipe", []) if vit.get("equipe", []) is Array else []
	var arene: Dictionary = p.get("arene", {}) if p.get("arene", {}) is Dictionary else {}
	if equipe.is_empty() and arene.get("equipe", []) is Array:
		equipe = arene.get("equipe", [])
	if not equipe.is_empty():
		var puiss := int(vit.get("puissance", arene.get("puissance", 0)))
		d.add_child(UiCommun.label("ÉQUIPE" + ("   ·   Puissance %s" % _nombre(puiss) if puiss > 0 else ""), 16, UiCommun.C_OR))
		var le := HBoxContainer.new()
		le.add_theme_constant_override("separation", 10)
		d.add_child(le)
		for x in equipe:
			if x is Dictionary and UnitesData.existe(str(x.get("id", ""))):
				le.add_child(UiCommun.carte_heros({"uid": -1, "id": str(x["id"]), "niveau": int(x.get("niveau", 1)),
					"xp": 0, "etoiles": maxi(1, int(x.get("etoiles", 1)))}, 104, 136))

	# Compétitions
	var classee: Dictionary = p.get("classee", {}) if p.get("classee", {}) is Dictionary else {}
	var lignes_comp: Array = []
	if not arene.is_empty():
		lignes_comp.append(["Arène", "%d pts  ·  %d V / %d D" % [int(arene.get("points", 0)), int(arene.get("victoires", 0)), int(arene.get("defaites", 0))]])
	if not classee.is_empty():
		lignes_comp.append(["Arène classée", "%d pts  ·  %d V / %d D / %d N" % [int(classee.get("points", 0)), int(classee.get("victoires", 0)),
			int(classee.get("defaites", 0)), int(classee.get("egalites", 0))]])
	if int(p.get("marche_record", 0)) > 0:
		lignes_comp.append(["Marche Maudite", "record %s pts" % _nombre(int(p["marche_record"]))])
	if not lignes_comp.is_empty():
		d.add_child(HSeparator.new())
		d.add_child(UiCommun.label("COMPÉTITIONS", 16, UiCommun.C_OR))
		d.add_child(_grille(lignes_comp))

	var st2: Dictionary = vit.get("stats", {}) if vit.get("stats", {}) is Dictionary else {}
	if not st2.is_empty():
		d.add_child(HSeparator.new())
		d.add_child(UiCommun.label("STATISTIQUES", 16, UiCommun.C_OR))
		d.add_child(_grille([
			["Chapitres terminés", _nombre(int(st2.get("chapitres", 0)))],
			["Combats gagnés", _nombre(int(st2.get("combats_gagnes", 0)))],
			["Bestiaire", "%d unités découvertes" % int(st2.get("bestiaire", 0))],
			["Invocations", _nombre(int(st2.get("invocations", 0)))],
			["Tour de l'Enfer", "étage %d" % int(st2.get("tour_enfer", 0))],
			["Tour du Paradis", "étage %d" % int(st2.get("tour_paradis", 0))],
			["Donjons terminés", _nombre(int(st2.get("donjons", 0)))],
			["Boss de Monde abattus", _nombre(int(st2.get("boss_monde", 0)))],
			["Évolutions", _nombre(int(st2.get("evolutions", 0)))],
			["Succès", "%d paliers" % int(st2.get("succes", 0))],
		], 2))

	var col: Dictionary = vit.get("collection", {}) if vit.get("collection", {}) is Dictionary else {}
	if not col.is_empty():
		d.add_child(HSeparator.new())
		d.add_child(UiCommun.label("COLLECTION  (%d unités)" % int(vit.get("nb_unites", 0)), 16, UiCommun.C_OR))
		var lc := HBoxContainer.new()
		lc.add_theme_constant_override("separation", 18)
		d.add_child(lc)
		for rr in ["N", "R", "SR", "SSR", "UR", "LEG"]:
			lc.add_child(UiCommun.label("%s : %d" % ["Légende" if rr == "LEG" else rr, int(col.get(rr, 0))], 15, UiCommun.COULEURS_RARETE[rr]))

	if vit.is_empty():
		d.add_child(UiCommun.label("Ce joueur n'a pas encore partagé sa fiche détaillée\n(elle apparaîtra à sa prochaine connexion avec une version récente du jeu).", 14, UiCommun.C_DOUX))

	var f := FenetreSimple.new()
	f.largeur = 1040.0
	f.titre = "PROFIL"
	f.boutons = [["Fermer", null]]
	f.contenu = defil
	parent.add_child(f)


## Grille de lignes [libellé, valeur] sur 1 ou 2 paires de colonnes.
static func _grille(lignes: Array, paires := 1) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2 * paires
	g.add_theme_constant_override("h_separation", 22)
	g.add_theme_constant_override("v_separation", 3)
	for l in lignes:
		g.add_child(UiCommun.label(str(l[0]), 14, UiCommun.C_DOUX))
		g.add_child(UiCommun.label(str(l[1]), 14, UiCommun.C_TEXTE))
	return g


static func _date(iso: String) -> String:
	var j := iso.left(10).split("-")
	return "%s/%s/%s" % [j[2], j[1], j[0]] if j.size() == 3 else iso.left(10)


static func _nombre(n: int) -> String:
	var t := str(absi(n))
	var res := ""
	while t.length() > 3:
		res = " " + t.right(3) + res
		t = t.left(t.length() - 3)
	return ("-" if n < 0 else "") + t + res
