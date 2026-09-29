class_name EcranMenagerie
extends EcranBase
## LA MÉNAGERIE (Aventure) : terrains de chasse (héros N/R + familier) et collection de familiers.
## Règles et chiffres : menagerie.gd et familiers_data.gd.

const SCENE := "res://scenes/menagerie.tscn"
const C_VERT := Color("8ad05a")
const COULEURS_ELEMENT := {
	"feu": Color("e0743a"), "eau": Color("4f9fd6"), "nature": Color("62ad4f"),
	"tenebres": Color("a276d6"), "sacre": Color("e6c85a"), "neutre": Color("c8b8b0"),
}

var _onglet := "chasse"
var _boutons := {}
var _lbl_timers: Array = []        # [[Label, index équipe]]
var _lbl_sceaux: Label


func _titre_ecran() -> String:
	return "LA MÉNAGERIE"


func _couleur() -> Color:
	return C_VERT


func _preparer() -> void:
	Tutoriel.astuce("menagerie", self)
	for o in [["chasse", "Terrains de chasse"], ["familiers", "Mes familiers"]]:
		var b := UiCommun.bouton(o[1], 16)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(200, 40)
		b.pressed.connect(func():
			_onglet = o[0]
			rafraichir())
		_tete.add_child(b)
		_tete.move_child(b, 2 + _boutons.size())
		_boutons[o[0]] = b
	var cadeau := Menagerie.accueil()
	if not cadeau.is_empty():
		FenetreSimple.ouvrir.call_deferred(self, "Bienvenue à la Ménagerie !",
			"Un familier t'a suivi jusqu'ici, et des Sceaux Sauvages t'attendent :\n\n" + "\n".join(cadeau)
			+ "\n\nEnvoie un héros N ou R avec un familier sur un terrain de chasse : ils rapportent du butin même quand le jeu est fermé.")
	Menagerie.maj()
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_tic)
	add_child(t)


func _tic() -> void:
	if Menagerie.maj():
		rafraichir()
		return
	for x in _lbl_timers:
		var l: Label = x[0]
		if is_instance_valid(l) and x[1] < Menagerie.equipes().size():
			l.text = _texte_timer(Menagerie.equipes()[x[1]])


func _maj_ressources() -> void:
	_lbl_ressources.text = "Sceaux Sauvages %d   ·   Or %s" % [Sauvegarde.get_objet(Menagerie.SCEAU), _nombre(Sauvegarde.get_or())]


func _remplir() -> void:
	for k in _boutons:
		_boutons[k].button_pressed = k == _onglet
	_lbl_timers.clear()
	match _onglet:
		"chasse": _chasse()
		"familiers": _familiers()


# =====================================================================
# Terrains de chasse
# =====================================================================

func _chasse() -> void:
	var eq := Menagerie.equipes()
	_texte("Une équipe de chasse = un héros N ou R (hors équipe de combat) + un familier. Le butin s'accumule même jeu fermé, jusqu'à 12 h de chasse : viens le récolter ! Places : %d / %d (une de plus aux niveaux de compte 10, 20 et 30)." % [
		eq.size(), Menagerie.places()], 15, UiCommun.C_TEXTE)
	for i in eq.size():
		_carte_equipe(i, eq[i])
	for i in range(eq.size(), Menagerie.PLACES_DEPART + Menagerie.PALIERS_PLACES.size()):
		var h := _ligne(Color(0.35, 0.3, 0.3))
		if i < Menagerie.places():
			var t := UiCommun.label("Place libre", 18, UiCommun.C_DOUX)
			t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(t)
			var b := UiCommun.bouton("Nouvelle chasse", 17)
			b.custom_minimum_size = Vector2(220, 46)
			b.pressed.connect(_nouvelle_chasse)
			h.add_child(b)
		else:
			var palier: int = Menagerie.PALIERS_PLACES[i - Menagerie.PLACES_DEPART]
			h.add_child(UiCommun.label("Place verrouillée : niveau de compte %d" % palier, 17, UiCommun.C_DOUX))
	_contenu.add_child(HSeparator.new())
	_titre("LES TERRAINS DE CHASSE", C_VERT)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(g)
	for z in Menagerie.ORDRE_ZONES:
		g.add_child(_carte_zone(z))


func _carte_equipe(i: int, e: Dictionary) -> void:
	var f := Menagerie.get_fam(int(e["familier"]))
	var hs := Sauvegarde.get_heros(int(e["heros"]))
	var zone: Dictionary = Menagerie.ZONES[e["zone"]]
	var h := _ligne(C_VERT.darkened(0.2))
	if not f.is_empty():
		h.add_child(medaillon(f["id"], 76))
	if not hs.is_empty():
		h.add_child(UiCommun.portrait(hs["id"], 76))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	h.add_child(vb)
	var noms := "%s  +  %s" % [FamiliersData.get_familier(f["id"])["nom"] if not f.is_empty() else "?",
		UnitesData.get_unite(hs["id"])["nom"] if not hs.is_empty() else "?"]
	vb.add_child(UiCommun.label(noms, 18, UiCommun.C_TEXTE))
	vb.add_child(UiCommun.label("%s   ·   récolte x%s   ·   un butin toutes les %s" % [zone["nom"],
		_n(Menagerie.multiplicateur(int(e["heros"]), f, e["zone"])) if not f.is_empty() else "?",
		_duree(Menagerie.minutes(f, e["zone"])) if not f.is_empty() else "?"], 14, C_VERT))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	vb.add_child(ligne)
	var plafond := Menagerie.plafond(e)
	ligne.add_child(_barre(int(e["butins"]), plafond, C_VERT, 260))
	ligne.add_child(UiCommun.label("Butins : %d / %d" % [int(e["butins"]), plafond], 14, UiCommun.C_TEXTE))
	var tl := UiCommun.label(_texte_timer(e), 14, Color("ffb070"))
	ligne.add_child(tl)
	_lbl_timers.append([tl, i])
	var stock := Quetes.texte_recompense(e["stock"]) if not e["stock"].is_empty() else "Rien pour l'instant."
	var s := UiCommun.label("Stock : " + stock, 14, UiCommun.C_DOUX)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(s)
	var boutons := VBoxContainer.new()
	boutons.add_theme_constant_override("separation", 6)
	h.add_child(boutons)
	var r := UiCommun.bouton("Récolter", 17)
	r.custom_minimum_size = Vector2(160, 44)
	r.disabled = int(e["butins"]) <= 0
	r.pressed.connect(func():
		_annoncer(Menagerie.recolter(i))
		rafraichir())
	boutons.add_child(r)
	var rp := UiCommun.bouton("Rappeler", 15)
	rp.custom_minimum_size = Vector2(160, 36)
	rp.pressed.connect(func():
		FenetreSimple.confirmer(self, "Rappeler l'équipe ?", "Le butin déjà trouvé est récolté, puis le héros et le familier redeviennent libres.", "Rappeler", func():
			_annoncer(Menagerie.rappeler(i))
			rafraichir()))
	boutons.add_child(rp)


func _texte_timer(e: Dictionary) -> String:
	var s := Menagerie.secondes_avant_butin(e)
	if s < 0:
		return "STOCK PLEIN : récolte !"
	return "Prochain butin dans %s" % Calendrier.texte_duree(s)


func _carte_zone(z: String) -> PanelContainer:
	var d: Dictionary = Menagerie.ZONES[z]
	var ouverte := Menagerie.zone_ouverte(z)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(360, 0)
	var st := UiCommun.style_panneau(C_VERT.darkened(0.3 if ouverte else 0.7), Color(0.06, 0.04, 0.03, 0.92))
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	vb.add_child(UiCommun.label(d["nom"], 18, C_VERT if ouverte else UiCommun.C_DOUX))
	var desc := UiCommun.label(d["desc"], 13, UiCommun.C_DOUX)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)
	var b: Dictionary = d["butin"]
	var bt := UiCommun.label("Commun : %s\nRare : %s\nÉpique : %s" % [_nom_butin(b["commun"][0]), _nom_butin(b["rare"][0]), _nom_butin(b["epique"][0])], 13, UiCommun.C_TEXTE)
	bt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bt)
	var roles: Array = d["roles"].map(func(r): return UnitesData.ROLES[r])
	vb.add_child(UiCommun.label("Héros favoris (+20 %%) : %s" % ", ".join(roles), 13, Color("ffb070")))
	vb.add_child(UiCommun.label("Rythme : x%s" % _n(float(d["facteur"])) if ouverte else "Débloquée au niveau de compte %d" % int(d["niveau"]), 13, UiCommun.C_DOUX if ouverte else Color("ff7a6a")))
	return p


func _nom_butin(o: String) -> String:
	if o.contains("{e}"):
		return {"goutte_{e}": "Gouttes", "larme_{e}": "Larmes", "coeur_{e}": "Cœurs"}.get(o, o) + " (élément du familier)"
	return "or" if o == "or" else Reliquaire.nom(o)


# ---------- Nouvelle chasse ----------

func _nouvelle_chasse() -> void:
	var zones: Array = Menagerie.ORDRE_ZONES.filter(func(z): return Menagerie.zone_ouverte(z))
	var heros: Array = Sauvegarde.liste_heros().filter(func(h): return Menagerie.raison_heros(int(h["uid"])) == "")
	var fams: Array = Menagerie.familiers().filter(func(f): return not Menagerie.occupe_fam(int(f["uid"])))
	if heros.is_empty():
		FenetreSimple.ouvrir(self, "Aucun héros disponible", "Il faut un héros de rareté N ou R, hors de l'équipe de combat et libre (pas en mission).\n\nInvoque-en au Pacte Doré de l'Autel d'Invocation !")
		return
	if fams.is_empty():
		FenetreSimple.ouvrir(self, "Aucun familier disponible", "Tous tes familiers sont déjà en chasse.\n\nObtiens-en d'autres au Pacte Sauvage de l'Autel d'Invocation, avec des Sceaux Sauvages.")
		return
	fams.sort_custom(func(a, b): return Menagerie.recolte(a) > Menagerie.recolte(b))
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", 8)
	var oz := _option(c, "Zone de chasse")
	for z in zones:
		oz.add_item(Menagerie.ZONES[z]["nom"])
	var oh := _option(c, "Héros (N ou R)")
	var of := _option(c, "Familier")
	for f in fams:
		var d := FamiliersData.get_familier(f["id"])
		of.add_item("%s (%s, niv. %d%s) · terrain : %s" % [d["nom"], d["rarete"], int(f["niveau"]),
			"" if int(f["etoiles"]) <= 1 else ", " + "★".repeat(int(f["etoiles"])), Menagerie.ZONES[d["terrain"]]["nom"]])
	var est := UiCommun.label("", 15, C_VERT)
	est.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	est.custom_minimum_size = Vector2(640, 0)
	c.add_child(est)
	var remplir_heros := func():
		var z: String = zones[oz.selected]
		heros.sort_custom(func(a, b): return Menagerie.bonus_heros(int(a["uid"]), z) > Menagerie.bonus_heros(int(b["uid"]), z))
		oh.clear()
		for h in heros:
			var u := UnitesData.get_unite(h["id"])
			oh.add_item("%s (%s, %s, niv. %d)%s" % [u["nom"], u["rarete"], UnitesData.ROLES[u["role"]], int(h["niveau"]),
				"  ★ favori" if u["role"] in Menagerie.ZONES[z]["roles"] else ""])
		oh.select(0)
	var maj_estimation := func():
		var z: String = zones[oz.selected]
		var f: Dictionary = fams[of.selected]
		var h_uid := int(heros[oh.selected]["uid"])
		var e := Menagerie.estimation(h_uid, f, z)
		var t: Array = []
		for o in e:
			t.append("%s %s" % [_n(e[o]), "or" if o == "or" else Reliquaire.nom(o)])
		est.text = "Récolte x%s  ·  un butin toutes les %s  ·  Fortune %s\nEn 12 h (moyenne) : %s" % [
			_n(Menagerie.multiplicateur(h_uid, f, z)), _duree(Menagerie.minutes(f, z)), _n(Menagerie.fortune(f)), ", ".join(t)]
	remplir_heros.call()
	oz.item_selected.connect(func(_i):
		remplir_heros.call()
		maj_estimation.call())
	oh.item_selected.connect(func(_i): maj_estimation.call())
	of.item_selected.connect(func(_i): maj_estimation.call())
	maj_estimation.call()
	var f := FenetreSimple.new()
	f.largeur = 720.0
	f.titre = "Nouvelle chasse"
	f.contenu = c
	f.boutons = [["Annuler", null], ["Partir en chasse", func():
		var r := Menagerie.partir(int(heros[oh.selected]["uid"]), int(fams[of.selected]["uid"]), zones[oz.selected])
		if r != "":
			_erreur(r)
		else:
			_annoncer(["L'équipe part en chasse !"])
		rafraichir()]]
	add_child(f)


func _option(parent: Control, titre: String) -> OptionButton:
	parent.add_child(UiCommun.label(titre, 15, UiCommun.C_OR))
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.custom_minimum_size = Vector2(640, 40)
	o.add_theme_font_size_override("font_size", 16)
	parent.add_child(o)
	return o


# =====================================================================
# Collection de familiers
# =====================================================================

func _familiers() -> void:
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	_contenu.add_child(tete)
	var t := UiCommun.label("%d familier(s) · %d / %d découverts au Bestiaire" % [Menagerie.familiers().size(),
		_nb_decouverts(), FamiliersData.LISTE.size()], 16, UiCommun.C_TEXTE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var inv := UiCommun.bouton("Pacte Sauvage (Autel d'Invocation)", 16)
	inv.pressed.connect(func():
		EcranInvocation.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranInvocation.SCENE))
	tete.add_child(inv)
	var l := Menagerie.familiers().duplicate()
	l.sort_custom(func(a, b):
		var ra := FamiliersData.ORDRE_RARETE.find(FamiliersData.get_familier(a["id"])["rarete"])
		var rb := FamiliersData.ORDRE_RARETE.find(FamiliersData.get_familier(b["id"])["rarete"])
		return ra > rb if ra != rb else int(a["niveau"]) > int(b["niveau"]))
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(g)
	for f in l:
		g.add_child(_carte_familier(f))


func _nb_decouverts() -> int:
	var n := 0
	for id in FamiliersData.ids():
		if Menagerie.est_decouvert(id):
			n += 1
	return n


func _carte_familier(f: Dictionary) -> Button:
	var d := FamiliersData.get_familier(f["id"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(190, 210)
	b.focus_mode = Control.FOCUS_NONE
	var coul: Color = UiCommun.COULEURS_RARETE[d["rarete"]]
	b.add_theme_stylebox_override("normal", UiCommun.style_carte(coul))
	b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
	b.add_theme_stylebox_override("pressed", UiCommun.style_carte(UiCommun.C_OR, 0.1))
	b.pressed.connect(_fiche.bind(int(f["uid"])))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_top = 10
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 3)
	b.add_child(vb)
	vb.add_child(medaillon(f["id"], 84))
	var n := UiCommun.label(d["nom"], 14, UiCommun.C_TEXTE)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(176, 0)
	vb.add_child(n)
	var s := UiCommun.label("%s · Niv. %d%s" % [d["rarete"], int(f["niveau"]), "  " + "★".repeat(int(f["etoiles"])) if int(f["etoiles"]) > 1 else ""], 13, coul)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(s)
	if Menagerie.occupe_fam(int(f["uid"])):
		var o := UiCommun.label("EN CHASSE", 12, C_VERT)
		o.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(o)
	return b


func _fiche(uid: int) -> void:
	var f := Menagerie.get_fam(uid)
	if f.is_empty():
		return
	var d := FamiliersData.get_familier(f["id"])
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", 16)
	c.add_child(medaillon(f["id"], 130))
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(470, 0)
	vb.add_theme_constant_override("separation", 4)
	c.add_child(vb)
	var coul: Color = UiCommun.COULEURS_RARETE[d["rarete"]]
	vb.add_child(UiCommun.label("%s · %s · Niveau %d / %d · %s" % [d["rarete"], UnitesData.ELEMENTS[d["element"]], int(f["niveau"]),
		int(d["niveau_max"]), "★".repeat(int(f["etoiles"]))], 16, coul))
	if int(f["niveau"]) < int(d["niveau_max"]):
		vb.add_child(UiCommun.label("XP %d / %d (1 XP par butin)" % [int(f["xp"]), Menagerie.xp_niveau(int(f["niveau"]))], 13, UiCommun.C_DOUX))
	for l in _lignes_stats(f):
		vb.add_child(UiCommun.label(l, 15, UiCommun.C_TEXTE))
	var desc := UiCommun.label(d["description"], 14, UiCommun.C_DOUX)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)
	var doublons: Array = Menagerie.familiers().filter(func(x): return x["id"] == f["id"] and int(x["uid"]) != uid \
		and not Menagerie.occupe_fam(int(x["uid"])))
	var boutons: Array = [["Fermer", null]]
	if not doublons.is_empty() and int(f["etoiles"]) < FamiliersData.ETOILES_MAX:
		doublons.sort_custom(func(a, b): return int(a["niveau"]) < int(b["niveau"]))
		boutons.append(["Éveiller (+1 ★)", func():
			var r := Menagerie.eveiller(uid, int(doublons[0]["uid"]))
			if r != "":
				_erreur(r)
			else:
				_annoncer(["%s : %d étoiles !" % [d["nom"], int(Menagerie.get_fam(uid)["etoiles"])]])
			rafraichir()])
	if not Menagerie.occupe_fam(uid):
		var gain: int = Menagerie.OR_LIBERATION[d["rarete"]] * int(f["etoiles"])
		boutons.append(["Libérer (+%d or)" % gain, func():
			FenetreSimple.confirmer(self, "Libérer %s ?" % d["nom"], "Il retournera à la vie sauvage. Tu reçois %d or." % gain, "Libérer", func():
				var g := Menagerie.liberer(uid)
				if g > 0:
					_annoncer(["Or : +%d" % g])
				rafraichir())])
	var fen := FenetreSimple.new()
	fen.largeur = 700.0
	fen.titre = d["nom"]
	fen.contenu = c
	fen.boutons = boutons
	add_child(fen)


static func _lignes_stats(f: Dictionary) -> Array:
	var d := FamiliersData.get_familier(f["id"])
	return [
		"Récolte : x%s" % _n(Menagerie.recolte(f)),
		"Célérité : un butin toutes les %s (x rythme de la zone)" % _duree(float(d["celerite"])),
		"Fortune : %s" % _n(Menagerie.fortune(f)),
		"Terrain préféré : %s (+25 %% de récolte)" % Menagerie.ZONES[d["terrain"]]["nom"],
		"Talent — " + FamiliersData.texte_talent(f["id"], int(f["etoiles"])),
	]


# =====================================================================
# Outils (utilisés aussi par l'Invocation et le Bestiaire)
# =====================================================================

## Médaillon d'un familier : illustration si elle existe, sinon cercle coloré avec l'initiale.
static func medaillon(id: String, taille: float, connu := true) -> Panel:
	var d := FamiliersData.get_familier(id)
	var p := Panel.new()
	p.custom_minimum_size = Vector2(taille, taille)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.set_corner_radius_all(int(taille / 2))
	st.bg_color = Color("#" + str(d["couleur"])).lerp(Color.BLACK, 0.2) if connu else Color(0.1, 0.08, 0.08)
	st.border_color = UiCommun.COULEURS_RARETE[d["rarete"]] if connu else Color(0.25, 0.2, 0.2)
	st.set_border_width_all(maxi(2, int(taille / 28)))
	p.add_theme_stylebox_override("panel", st)
	var chemin := FamiliersData.chemin_image(id)
	if connu and chemin != "":
		p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		var img := TextureRect.new()
		img.texture = load(chemin)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(img)
		return p
	var nom: String = str(d["nom"])
	var l := UiCommun.label(nom.substr(0, 1) if connu else "?", int(taille * 0.42), Color.WHITE if connu else UiCommun.C_DOUX)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	p.add_child(l)
	if connu:
		# Petit point de couleur de l'élément
		var pt := Panel.new()
		var s2 := StyleBoxFlat.new()
		s2.bg_color = COULEURS_ELEMENT.get(d["element"], Color.GRAY)
		s2.set_corner_radius_all(int(taille / 10))
		pt.add_theme_stylebox_override("panel", s2)
		pt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pt.size = Vector2(taille / 5, taille / 5)
		pt.position = Vector2(taille * 0.72, taille * 0.72)
		p.add_child(pt)
	return p


static func _duree(minutes: float) -> String:
	if minutes >= 60.0:
		var h := int(minutes / 60.0)
		var m := int(round(minutes - h * 60))
		return "%d h %02d" % [h, m] if m > 0 else "%d h" % h
	return "%d min" % int(round(minutes))


static func _n(x: float) -> String:
	return str(int(x)) if is_equal_approx(x, round(x)) else str(snappedf(x, 0.01 if x < 10.0 else 0.1))
