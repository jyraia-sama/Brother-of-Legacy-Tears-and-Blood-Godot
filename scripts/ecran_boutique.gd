class_name EcranBoutique
extends EcranBase
## BOUTIQUE : Marché du jour (or), Comptoir des gemmes, et packs de gemmes (argent réel, bientôt).
## Règles et prix : boutique.gd.

const SCENE := "res://scenes/boutique.tscn"
const C_GEMME := Color("7ae0ff")

var _onglet := "marche"
var _boutons := {}


func _titre_ecran() -> String:
	return "BOUTIQUE"


func _preparer() -> void:
	for o in [["marche", "Marché du jour (or)"], ["comptoir", "Comptoir des gemmes"], ["packs", "Gemmes"]]:
		var b := UiCommun.bouton(o[1], 16)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(210, 40)
		b.pressed.connect(func():
			_onglet = o[0]
			rafraichir())
		_tete.add_child(b)
		_tete.move_child(b, 2 + _boutons.size())
		_boutons[o[0]] = b


func _remplir() -> void:
	for k in _boutons:
		_boutons[k].button_pressed = k == _onglet
	match _onglet:
		"marche": _marche()
		"comptoir": _comptoir()
		"packs": _packs()


func _grille() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	_contenu.add_child(g)
	return g


func _case(g: GridContainer, id_objet: String, titre: String, desc: String, prix: String, info: String,
		actif: bool, action: Callable, couleur: Color) -> void:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(380, 170)
	var st := UiCommun.style_panneau(couleur.darkened(0.3 if actif else 0.65), Color(0.07, 0.03, 0.04, 0.92))
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	g.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	if id_objet != "":
		h.add_child(UiCommun.icone_objet(id_objet, 64))
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	h.add_child(vb)
	var t := UiCommun.label(titre, 17, UiCommun.C_TEXTE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(t)
	var d := UiCommun.label(desc, 12, UiCommun.C_DOUX)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	vb.add_child(UiCommun.label(info, 12, Color("ffb070")))
	var b := UiCommun.bouton(prix, 16)
	b.custom_minimum_size = Vector2(0, 40)
	b.disabled = not actif
	b.pressed.connect(action)
	vb.add_child(b)


func _marche() -> void:
	_texte("Six offres qui changent chaque jour à minuit (%s). Une seule fois chacune." % Calendrier.texte_duree(Calendrier.secondes_avant_demain()))
	var g := _grille()
	for o in Boutique.marche_du_jour():
		var deja := Boutique.deja_achete_marche(o)
		var desc: String = Reliquaire.OBJETS.get(o["id"], {}).get("desc", "")
		_case(g, o["id"], "%s x%d" % [Reliquaire.nom(o["id"]), int(o["quantite"])], desc,
			"Acheté" if deja else "%s or" % _nombre(int(o["prix"])), "",
			not deja and Sauvegarde.get_or() >= int(o["prix"]), func():
				var r := Boutique.acheter_marche(o)
				if r != "":
					_erreur(r)
				else:
					_annoncer(["%s x%d" % [Reliquaire.nom(o["id"]), int(o["quantite"])]])
				rafraichir(), UiCommun.C_OR)


func _comptoir() -> void:
	_texte("Les gemmes se gagnent avec les Quêtes, les Succès, la connexion quotidienne et les saisons d'Arène.")
	var g := _grille()
	for o in Boutique.COMPTOIR:
		var reste := Boutique.restants(o)
		var desc: String = o.get("desc", Reliquaire.OBJETS.get(o["id"], {}).get("desc", ""))
		_case(g, "" if o["id"] == "stamina_pleine" else o["id"], Boutique.nom_offre(o), desc,
			"%d gemmes" % int(o["prix"]),
			"Encore %d %s" % [reste, "aujourd'hui" if o["periode"] == "jour" else "cette semaine"],
			reste > 0 and Sauvegarde.get_gemmes() >= int(o["prix"]), func():
				var r := Boutique.acheter_comptoir(o)
				if r != "":
					_erreur(r)
				else:
					_annoncer([Boutique.nom_offre(o)])
				rafraichir(), C_GEMME)


func _packs() -> void:
	_titre("PACKS DE GEMMES", C_GEMME)
	_texte("L'achat de gemmes avec de l'argent réel arrivera dans une prochaine version. Les prix ci-dessous sont indicatifs.", 15, Color("ffb070"))
	var g := _grille()
	for pk in Boutique.PACKS:
		var titre := "%s gemmes" % _nombre(int(pk["gemmes"]))
		var desc := ("+ %s gemmes offertes" % _nombre(int(pk["bonus"]))) if int(pk["bonus"]) > 0 else "Le petit pack pour démarrer."
		_case(g, "", titre, desc, "Bientôt disponible" if not Boutique.PACKS_ACTIFS else str(pk["prix"]),
			"Prix prévu : %s" % pk["prix"], Boutique.PACKS_ACTIFS, func(): pass, C_GEMME)
