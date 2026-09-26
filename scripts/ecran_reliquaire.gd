class_name EcranReliquaire
extends Control
## LE RELIQUAIRE : trois onglets.
##   INVENTAIRE : coffres d'or, élixirs de stamina, tomes d'XP, pierres, monnaies des modes.
##   FORGE      : créer des héros exclusifs (Braises, Plumes, Fragments) et faire des échanges.
##   ATELIER    : fabriquer un Écho Sanguin choisi, démanteler les Échos inutiles en Poussière.

const SCENE := "res://scenes/reliquaire.tscn"
const FOND := "res://assets/ui/reliquaire_bg.png"
const C_VIOLET := Color("b08aff")

static var scene_retour := ""

var _onglet := "inventaire"
var _onglets := {}
var _contenu: VBoxContainer
var _lbl_or: Label
var _lbl_stamina: Label
var _voile: Control             # choix d'un héros pour un tome

# Atelier : choix courants
var _set := "energy"
var _emplacement := 1
var _principale := "atk"


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, FOND, Color(0.4, 0.4, 0.4)):
		UiCommun.fond_degrade(self, Color("1a0f24"), Color("07040a"))
	UiCommun.particules(self, Color(C_VIOLET, 0.8), true, 25)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 14)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("LE RELIQUAIRE", 32, C_VIOLET))
	var esp := Control.new()
	esp.custom_minimum_size = Vector2(20, 0)
	tete.add_child(esp)
	for o in [["inventaire", "Inventaire"], ["forge", "Forge de héros"], ["atelier", "Atelier d'Échos"]]:
		var b := UiCommun.bouton(o[1], 17)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(170, 40)
		b.pressed.connect(func():
			_onglet = o[0]
			_rafraichir())
		tete.add_child(b)
		_onglets[o[0]] = b
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(pousse)
	_lbl_stamina = UiCommun.label("", 18, Color("7ad0ff"))
	tete.add_child(_lbl_stamina)
	_lbl_or = UiCommun.label("", 19, Color("ffd060"))
	tete.add_child(_lbl_or)

	var panneau := PanelContainer.new()
	panneau.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panneau.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_VIOLET))
	col.add_child(panneau)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panneau.add_child(defil)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 10)
	defil.add_child(_contenu)
	_rafraichir()


func _rafraichir() -> void:
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	_lbl_stamina.text = "Stamina %d/%d" % [Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max()]
	for cle in _onglets:
		_onglets[cle].button_pressed = (cle == _onglet)
	for e in _contenu.get_children():
		e.queue_free()
	match _onglet:
		"inventaire": _inventaire()
		"forge": _forge()
		"atelier": _atelier()


# =====================================================================
# Inventaire
# =====================================================================

func _inventaire() -> void:
	_contenu.add_child(UiCommun.label("Les objets gagnés dans les Tours, les Boss de Monde et l'Aventure.", 15, UiCommun.C_DOUX))
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 10)
	grille.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(grille)
	for o in Reliquaire.ORDRE:
		grille.add_child(_carte_objet(o))


func _carte_objet(o: String) -> PanelContainer:
	var infos: Dictionary = Reliquaire.OBJETS[o]
	var n := Sauvegarde.get_objet(o)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(530, 118)
	var st := UiCommun.style_panneau(Color("#" + str(infos["couleur"])).darkened(0.3 if n > 0 else 0.7), Color(0.07, 0.04, 0.09, 0.92))
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	h.add_child(UiCommun.icone_objet(o, 56))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vb)
	vb.add_child(UiCommun.label("%s   x%d" % [infos["nom"], n], 18, UiCommun.C_TEXTE if n > 0 else UiCommun.C_DOUX))
	var d := UiCommun.label(infos["desc"], 13, UiCommun.C_DOUX)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	vb.add_child(actions)
	match str(infos["cat"]):
		"coffre":
			actions.add_child(_petit_bouton("Ouvrir", n > 0, _ouvrir.bind(o, 1)))
			actions.add_child(_petit_bouton("Tout ouvrir", n > 1, _ouvrir.bind(o, n)))
		"elixir":
			actions.add_child(_petit_bouton("Boire", n > 0, _boire.bind(o)))
		"tome":
			actions.add_child(_petit_bouton("Utiliser sur un héros", n > 0, _choisir_heros.bind(o)))
		"forge":
			actions.add_child(_petit_bouton("Voir la Forge", true, func():
				_onglet = "forge"
				_rafraichir()))
		"atelier":
			actions.add_child(_petit_bouton("Voir l'Atelier", true, func():
				_onglet = "atelier"
				_rafraichir()))
		"pierre":
			if o == "pierre_eveil":
				actions.add_child(_petit_bouton("Autel de Fusion", true, func():
					EcranFusion.scene_retour = SCENE
					get_tree().change_scene_to_file(EcranFusion.SCENE)))
			else:
				actions.add_child(_petit_bouton("Autel d'Invocation", true, func():
					EcranInvocation.scene_retour = SCENE
					get_tree().change_scene_to_file(EcranInvocation.SCENE)))
	return p


func _petit_bouton(texte: String, actif: bool, action: Callable) -> Button:
	var b := UiCommun.bouton(texte, 14)
	b.custom_minimum_size = Vector2(0, 30)
	b.disabled = not actif
	b.pressed.connect(action)
	return b


func _ouvrir(coffre: String, combien: int) -> void:
	var total := {}
	for i in combien:
		var butin := Reliquaire.ouvrir_coffre(coffre)
		for k in butin:
			total[k] = int(total.get(k, 0)) + int(butin[k])
	var lignes: Array = []
	for k in total:
		lignes.append(("Or : +%d" % int(total[k])) if k == "or" else "%s : +%d" % [Reliquaire.nom(k), int(total[k])])
	_rafraichir()
	_message("%s x%d ouvert(s) !" % [Reliquaire.nom(coffre), combien], "\n".join(lignes))


func _boire(elixir: String) -> void:
	var gain := Reliquaire.utiliser_elixir(elixir)
	_rafraichir()
	if gain > 0:
		_message("Élixir", "+%d stamina (%d / %d)" % [gain, Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max()])


## Fenêtre de choix du héros qui recevra le tome.
func _choisir_heros(tome: String) -> void:
	if _voile != null:
		_voile.queue_free()
	_voile = ColorRect.new()
	(_voile as ColorRect).color = Color(0, 0, 0, 0.7)
	_voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_voile.add_child(centre)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(1180, 700)
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_VIOLET))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	var h := HBoxContainer.new()
	vb.add_child(h)
	var t := UiCommun.label("%s (+%d XP) : choisis un héros" % [Reliquaire.nom(tome), int(Reliquaire.XP_TOME[tome])], 22, C_VIOLET)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var fermer := UiCommun.bouton("Fermer", 15)
	fermer.pressed.connect(func():
		_voile.queue_free()
		_voile = null)
	h.add_child(fermer)
	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	var g := GridContainer.new()
	g.columns = 8
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	defil.add_child(g)
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(func(a, b): return int(a["niveau"]) > int(b["niveau"]))
	for hh in liste:
		var carte := UiCommun.carte_heros(hh)
		if int(hh["niveau"]) >= UnitesData.NIVEAU_MAX:
			carte.disabled = true
			carte.modulate = Color(1, 1, 1, 0.35)
		elif Sauvegarde.place_de(int(hh["uid"])) >= 0:
			UiCommun.badge(carte, "Équipe", UiCommun.C_OR)
		carte.pressed.connect(_appliquer_tome.bind(tome, int(hh["uid"])))
		g.add_child(carte)


func _appliquer_tome(tome: String, uid: int) -> void:
	var h := Sauvegarde.get_heros(uid)
	var avant := int(h["niveau"])
	var gagnes := Reliquaire.utiliser_tome(tome, uid)
	if _voile != null:
		_voile.queue_free()
		_voile = null
	_rafraichir()
	if gagnes >= 0:
		_message("Tome utilisé", "%s gagne %d XP.%s" % [UnitesData.get_unite(h["id"])["nom"], int(Reliquaire.XP_TOME[tome]),
			"\nNiveau %d → %d !" % [avant, avant + gagnes] if gagnes > 0 else ""])


# =====================================================================
# Forge
# =====================================================================

func _forge() -> void:
	var monnaies := HBoxContainer.new()
	monnaies.add_theme_constant_override("separation", 26)
	_contenu.add_child(monnaies)
	for o in ["braise_infernale", "plume_celeste", "fragment_colossal"]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		h.add_child(UiCommun.icone_objet(o, 30))
		h.add_child(UiCommun.label("%s : %d" % [Reliquaire.nom(o), Sauvegarde.get_objet(o)], 17, UiCommun.C_TEXTE))
		monnaies.add_child(h)
	_contenu.add_child(UiCommun.label("HÉROS EXCLUSIFS  —  impossibles à invoquer, ils ne s'obtiennent qu'ici.", 17, C_VIOLET))
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 10)
	grille.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(grille)
	for r in Reliquaire.FORGE:
		grille.add_child(_carte_recette(r))

	_contenu.add_child(HSeparator.new())
	_contenu.add_child(UiCommun.label("ÉCHANGES", 17, C_VIOLET))
	for ech in Reliquaire.ECHANGES:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var donne: Array = []
		for o in ech["donne"]:
			donne.append("%d %s" % [int(ech["donne"][o]), Reliquaire.nom(o)])
		var l := UiCommun.label("%s   →   %s" % [Reliquaire.texte_cout(ech["cout"]), ", ".join(donne)], 16, UiCommun.C_TEXTE)
		l.custom_minimum_size = Vector2(700, 0)
		h.add_child(l)
		h.add_child(_petit_bouton("Échanger", Reliquaire.peut_payer(ech["cout"]), func():
			if Reliquaire.echanger(ech):
				_rafraichir()
				_message("Échange", "Échange réussi : " + ", ".join(donne))))
		_contenu.add_child(h)


func _carte_recette(r: Dictionary) -> PanelContainer:
	var id: String = r["id"]
	var u := UnitesData.get_unite(id)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(395, 0)
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(UiCommun.couleur_rarete(id), Color(0.07, 0.04, 0.09, 0.94)))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	p.add_child(vb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	vb.add_child(h)
	h.add_child(UiCommun.portrait(id, 64))
	var v2 := VBoxContainer.new()
	v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v2)
	var nom := UiCommun.label(u["nom"], 17, UiCommun.couleur_rarete(id))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v2.add_child(nom)
	v2.add_child(UiCommun.label("%s · %s · %s" % [u["rarete"], UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]]], 13, UiCommun.C_DOUX))
	v2.add_child(UiCommun.label(r["origine"], 13, C_VIOLET))
	var s := UnitesData.stats(id, 1)
	vb.add_child(UiCommun.label("PV %d  ATK %d  DEF %d  AGI %d  MAG %d" % [s["pv"], s["atk"], s["def"], s["agi"], s["mag"]], 13, UiCommun.C_TEXTE))
	var ult: Dictionary = u["skills"][3]
	var d := UiCommun.label("Niv. 30 · %s : %s" % [ult["nom"], ult["description"]], 12, UiCommun.C_DOUX)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	var ok := Reliquaire.peut_payer(r["cout"], int(r["or"]))
	var cout := UiCommun.label("Coût : " + Reliquaire.texte_cout(r["cout"], int(r["or"])), 14, Color("8fe08a") if ok else Color("ff8a7a"))
	cout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(cout)
	var possede := 0
	for hh in Sauvegarde.liste_heros():
		if hh["id"] == id:
			possede += 1
	var b := UiCommun.bouton("FORGER" + ("  (possédé x%d)" % possede if possede > 0 else ""), 16)
	b.disabled = not ok
	b.pressed.connect(func():
		_confirmer("Forger %s pour %s ?" % [u["nom"], Reliquaire.texte_cout(r["cout"], int(r["or"]))], func():
			if Reliquaire.forger(r) >= 0:
				_rafraichir()
				_message("Forge", "%s rejoint ta collection !\nTu le trouveras dans le Deck." % u["nom"])))
	vb.add_child(b)
	return p


# =====================================================================
# Atelier d'Échos
# =====================================================================

func _atelier() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(UiCommun.icone_objet("poussiere_echo", 30))
	h.add_child(UiCommun.label("Poussière d'Écho : %d" % Sauvegarde.get_objet("poussiere_echo"), 18, UiCommun.C_TEXTE))
	_contenu.add_child(h)

	_contenu.add_child(UiCommun.label("FABRIQUER UN ÉCHO SANGUIN", 18, C_VIOLET))
	var choix := HBoxContainer.new()
	choix.add_theme_constant_override("separation", 12)
	_contenu.add_child(choix)
	choix.add_child(UiCommun.label("Set :", 16, UiCommun.C_TEXTE))
	var o_set := OptionButton.new()
	var ids_sets: Array = Echos.SETS.keys()
	for i in ids_sets.size():
		o_set.add_item("%s (%d pièces)" % [Echos.SETS[ids_sets[i]]["nom"], int(Echos.SETS[ids_sets[i]]["pieces"])], i)
	o_set.selected = ids_sets.find(_set)
	o_set.item_selected.connect(func(i: int):
		_set = ids_sets[i]
		_rafraichir())
	choix.add_child(o_set)
	choix.add_child(UiCommun.label("Emplacement :", 16, UiCommun.C_TEXTE))
	var o_emp := OptionButton.new()
	for e in range(1, 7):
		o_emp.add_item("%d · %s" % [e, Echos.EMPLACEMENTS[e]["nom"]], e)
	o_emp.selected = _emplacement - 1
	o_emp.item_selected.connect(func(i: int):
		_emplacement = i + 1
		_principale = Echos.EMPLACEMENTS[_emplacement]["principales"][0]
		_rafraichir())
	choix.add_child(o_emp)
	choix.add_child(UiCommun.label("Stat principale :", 16, UiCommun.C_TEXTE))
	var o_pr := OptionButton.new()
	var principales: Array = Echos.EMPLACEMENTS[_emplacement]["principales"]
	if not _principale in principales:
		_principale = principales[0]
	for i in principales.size():
		o_pr.add_item(Echos.NOMS_STATS.get(principales[i], principales[i]), i)
	o_pr.selected = principales.find(_principale)
	o_pr.item_selected.connect(func(i: int): _principale = principales[i])
	choix.add_child(o_pr)
	var desc := UiCommun.label(Echos.description_set(_set), 14, UiCommun.C_DOUX)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(desc)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	_contenu.add_child(ligne)
	for type in ["simple", "superieure"]:
		var a: Dictionary = Reliquaire.ATELIER[type]
		var box := VBoxContainer.new()
		var noms_r: Array = []
		for i in 5:
			if int(a["raretes"][i]) > 0:
				noms_r.append("%s %d %%" % [Echos.RARETES[i]["nom"], int(a["raretes"][i])])
		box.add_child(UiCommun.label("%s : %d Poussière + %d or" % [a["nom"], int(a["poussiere"]), int(a["or"])], 16, UiCommun.C_TEXTE))
		box.add_child(UiCommun.label("%s  ·  %d à %d étoiles" % [", ".join(noms_r), int(a["etoiles"][0]), int(a["etoiles"][1])], 13, UiCommun.C_DOUX))
		var b := UiCommun.bouton("Fabriquer", 16)
		b.disabled = not Reliquaire.peut_payer({"poussiere_echo": int(a["poussiere"])}, int(a["or"]))
		b.pressed.connect(func():
			var e := Reliquaire.fabriquer_echo(type, _set, _emplacement, _principale)
			_rafraichir()
			if not e.is_empty():
				_message("Atelier d'Échos", "Écho fabriqué :\n%s  %s\n%s  ·  %s" % [Echos.nom(e), "★".repeat(int(e["etoiles"])),
					Echos.RARETES[int(e["rarete"])]["nom"], Echos.texte_stat(e["principale"], Echos.valeur_principale(e))]))
		box.add_child(b)
		ligne.add_child(box)

	_contenu.add_child(HSeparator.new())
	_contenu.add_child(UiCommun.label("DÉMANTELER  (Échos ni équipés ni verrouillés)", 18, C_VIOLET))
	for r in 3:
		var uids: Array = []
		var gain := 0
		for e in Sauvegarde.liste_echos():
			if int(e["rarete"]) == r and int(e["porteur"]) < 0 and not e.get("verrou", false):
				uids.append(int(e["uid"]))
				gain += Reliquaire.poussiere_demantelement(e)
		var hh := HBoxContainer.new()
		hh.add_theme_constant_override("separation", 12)
		var l := UiCommun.label("Échos %s : %d   →   +%d Poussière" % [Echos.RARETES[r]["nom"], uids.size(), gain], 16, Echos.RARETES[r]["couleur"])
		l.custom_minimum_size = Vector2(520, 0)
		hh.add_child(l)
		hh.add_child(_petit_bouton("Tout démanteler", not uids.is_empty(), func():
			_confirmer("Démanteler %d Échos %s pour %d Poussière d'Écho ?" % [uids.size(), Echos.RARETES[r]["nom"], gain], func():
				var g := Reliquaire.demanteler(uids)
				_rafraichir()
				_message("Démantèlement", "+%d Poussière d'Écho" % g))))
		_contenu.add_child(hh)
	_contenu.add_child(UiCommun.label("Pour démanteler un Écho Rare ou mieux, vends-le ou verrouille ceux à garder dans le menu Échos Sanguins.", 13, UiCommun.C_DOUX))


# =====================================================================
# Outils
# =====================================================================

func _message(titre: String, texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(440, 0))


func _confirmer(texte: String, action: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.title = "Le Reliquaire"
	d.dialog_text = texte
	d.ok_button_text = "Oui"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		action.call())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(440, 0))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _voile != null:
			_voile.queue_free()
			_voile = null
		else:
			_retour()
