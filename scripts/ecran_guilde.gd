class_name EcranGuilde
extends Control
## GUILDE
##  - Sans guilde : créer une guilde, ou en chercher une (rejoindre / postuler).
##  - Dans une guilde : membres, candidatures (chef/officiers), Guerre de guildes (bientôt), réglages.
## Rôles : Chef (tous les droits), Officier (accepte les candidats, exclut les membres), Membre.
## Tout est vérifié par le serveur (supabase/01_comptes_amis_guildes.sql).

const SCENE := "res://scenes/guilde.tscn"
const FOND := "res://assets/ui/menu_bg.png"

## Coût de création d'une guilde (en or).
const COUT_CREATION := 10000

static var scene_retour := ""

const RECRUTEMENTS := [["ouvert", "Ouvert à tous"], ["demande", "Sur demande"], ["ferme", "Fermé"]]
const COULEURS_ROLE := {"chef": Color("ffd27a"), "officier": Color("b58ce6"), "membre": Color("a89f99")}
const MESSAGES := {
	"ok": "C'est fait.",
	"rejoint": "Bienvenue dans ta nouvelle guilde !",
	"demande_envoyee": "Candidature envoyée. Le chef ou un officier doit l'accepter.",
	"deja_demande": "Tu as déjà postulé dans cette guilde.",
	"deja_membre": "Ce joueur fait déjà partie d'une guilde.",
	"fermee": "Cette guilde ne recrute pas.",
	"niveau": "Ton niveau de compte est trop bas pour cette guilde.",
	"pleine": "La guilde est pleine.",
	"introuvable": "Introuvable (la situation a peut-être changé).",
	"interdit": "Tu n'as pas le droit de faire ça.",
	"nom_invalide": "Nom : 3 à 20 caractères (lettres, chiffres, espaces, ' _ -).",
	"nom_pris": "Ce nom de guilde est déjà pris.",
	"acceptee": "Candidat accepté !",
	"refusee": "Candidature refusée.",
	"dissoute": "Tu étais le dernier membre : la guilde est dissoute.",
	"pas_de_guilde": "Tu n'es dans aucune guilde.",
	"non_connecte": "Tu n'es pas connecté.",
}

var _guilde = null          # Dictionary renvoyé par ma_guilde(), ou null
var _onglet := "membres"
var _boutons_onglet := {}
var _corps: VBoxContainer
var _contenu: VBoxContainer
var _etat: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiCommun.fond_image(self, FOND, Color(0.35, 0.3, 0.3))

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + cote, 110)
	for cote in ["top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 30)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var retour := UiCommun.bouton("← Retour")
	retour.custom_minimum_size = Vector2(140, 44)
	retour.pressed.connect(_retour)
	entete.add_child(retour)
	var titre := UiCommun.label("GUILDE", 36, UiCommun.C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titre)
	if EnLigne.est_connecte():
		var rafraichir := UiCommun.bouton("↻ Actualiser")
		rafraichir.pressed.connect(_charger)
		entete.add_child(rafraichir)

	_etat = UiCommun.label("", 18, Color(1.0, 0.8, 0.5))
	_etat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(_etat)

	_corps = VBoxContainer.new()
	_corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_corps.add_theme_constant_override("separation", 12)
	colonne.add_child(_corps)

	if not EnLigne.est_connecte():
		_ecran_non_connecte()
		return
	_charger()


func _ecran_non_connecte() -> void:
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_corps.add_child(centre)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	vb.add_child(UiCommun.label("Connecte-toi à ton compte pour créer ou rejoindre une guilde." if EnLigne.configure()
		else "Le jeu en ligne n'est pas encore configuré (voir SUPABASE.md).", 20))
	if EnLigne.configure():
		var b := UiCommun.bouton("Se connecter")
		b.pressed.connect(func(): FenetreCompte.ouvrir(self, false, func(): get_tree().reload_current_scene()))
		vb.add_child(b)


# ---------------------------------------------------------------
# Chargement
# ---------------------------------------------------------------

func _charger() -> void:
	_etat.text = "Chargement…"
	var r := await EnLigne.appeler("ma_guilde")
	if not is_inside_tree():
		return
	if not r.ok:
		_etat.text = r.erreur
		return
	_etat.text = ""
	_guilde = r.data if r.data is Dictionary else null
	_vider(_corps)
	if _guilde == null:
		_construire_sans_guilde()
	else:
		_construire_avec_guilde()


func _message(r: Dictionary) -> String:
	if not r.ok:
		return r.erreur
	return MESSAGES.get(str(r.data), str(r.data))


## Lance une action serveur, affiche le résultat et recharge l'écran.
func _action(fonction: String, params: Dictionary) -> void:
	var r := await EnLigne.appeler(fonction, params)
	if not is_inside_tree():
		return
	var msg := _message(r)
	await _charger()
	_etat.text = msg


# ---------------------------------------------------------------
# SANS GUILDE : créer / rechercher
# ---------------------------------------------------------------

func _construire_sans_guilde() -> void:
	var colonnes := HBoxContainer.new()
	colonnes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonnes.add_theme_constant_override("separation", 18)
	_corps.add_child(colonnes)

	# --- Créer ---
	var gauche := _panneau(colonnes, 480)
	gauche.add_child(UiCommun.label("CRÉER UNE GUILDE", 24, UiCommun.C_OR))
	gauche.add_child(UiCommun.label("Nom", 16, UiCommun.C_DOUX))
	var nom := LineEdit.new()
	nom.max_length = 20
	nom.placeholder_text = "3 à 20 caractères"
	nom.custom_minimum_size = Vector2(0, 42)
	gauche.add_child(nom)
	gauche.add_child(UiCommun.label("Description", 16, UiCommun.C_DOUX))
	var desc := TextEdit.new()
	desc.custom_minimum_size = Vector2(0, 110)
	desc.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	desc.placeholder_text = "Présente ta guilde (200 caractères max)"
	gauche.add_child(desc)
	gauche.add_child(UiCommun.label("Recrutement", 16, UiCommun.C_DOUX))
	var recrut := _choix_recrutement("ouvert")
	gauche.add_child(recrut)
	var cout := UiCommun.label("Coût : %s or  (tu as %s or)" % [_nombre(COUT_CREATION), _nombre(Sauvegarde.get_or())], 17, UiCommun.C_LEGENDE)
	gauche.add_child(cout)
	var creer := UiCommun.bouton("Fonder la guilde")
	creer.custom_minimum_size = Vector2(0, 48)
	gauche.add_child(creer)
	creer.pressed.connect(func():
		if Sauvegarde.get_or() < COUT_CREATION:
			_etat.text = "Il te faut %s or pour fonder une guilde." % _nombre(COUT_CREATION)
			return
		creer.disabled = true
		var r := await EnLigne.appeler("creer_guilde", {"p_nom": nom.text,
			"p_description": desc.text.left(200), "p_recrutement": RECRUTEMENTS[recrut.selected][0]})
		if not is_inside_tree():
			return
		creer.disabled = false
		if r.ok and str(r.data) == "ok":
			Sauvegarde.depenser_or(COUT_CREATION)
			await _charger()
			_etat.text = "La guilde « %s » est fondée ! Tu en es le chef." % nom.text.strip_edges()
		else:
			_etat.text = _message(r))

	# --- Rechercher ---
	var droite := _panneau(colonnes, 0)
	droite.get_parent().get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_child(UiCommun.label("REJOINDRE UNE GUILDE", 24, UiCommun.C_OR))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	droite.add_child(ligne)
	var recherche := LineEdit.new()
	recherche.placeholder_text = "Nom de guilde (vide = les plus peuplées)"
	recherche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recherche.custom_minimum_size = Vector2(0, 42)
	ligne.add_child(recherche)
	var chercher := UiCommun.bouton("Rechercher")
	ligne.add_child(chercher)
	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	droite.add_child(defil)
	var resultats := VBoxContainer.new()
	resultats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resultats.add_theme_constant_override("separation", 8)
	defil.add_child(resultats)
	var lancer := func(): _rechercher(recherche.text, resultats)
	chercher.pressed.connect(lancer)
	recherche.text_submitted.connect(func(_t): lancer.call())
	lancer.call()


func _rechercher(texte: String, resultats: VBoxContainer) -> void:
	_vider(resultats)
	resultats.add_child(UiCommun.label("Recherche…", 16, UiCommun.C_DOUX))
	var r := await EnLigne.appeler("chercher_guildes", {"p_texte": texte})
	if not is_instance_valid(resultats):
		return
	_vider(resultats)
	if not r.ok:
		resultats.add_child(UiCommun.label(r.erreur, 16, Color(1.0, 0.7, 0.5)))
		return
	if (r.data as Array).is_empty():
		resultats.add_child(UiCommun.label("Aucune guilde trouvée. Fonde la première !", 17, UiCommun.C_DOUX))
	for g in r.data:
		resultats.add_child(_carte_guilde(g))


func _carte_guilde(g: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_OR.darkened(0.3)))
	var marge := _marge(p, 10)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	marge.add_child(ligne)
	var infos := VBoxContainer.new()
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(infos)
	infos.add_child(UiCommun.label(str(g.nom), 22, UiCommun.C_TEXTE))
	infos.add_child(UiCommun.label("%d/%d membres  ·  Chef : %s  ·  %s%s" % [int(g.membres), 30, str(g.chef),
		_nom_recrutement(str(g.recrutement)), ("  ·  Niv. %d min." % int(g.niveau_min)) if int(g.niveau_min) > 1 else ""], 15, UiCommun.C_DOUX))
	if str(g.description) != "":
		var d := UiCommun.label(str(g.description), 15, UiCommun.C_TEXTE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		infos.add_child(d)

	var b := UiCommun.bouton("")
	b.custom_minimum_size = Vector2(170, 44)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ligne.add_child(b)
	if bool(g.demande_envoyee):
		b.text = "Annuler ma demande"
		b.pressed.connect(func(): _action("annuler_demande_guilde", {"p_guilde": g.id}))
	elif str(g.recrutement) == "ferme":
		b.text = "Fermée"
		b.disabled = true
	elif int(g.membres) >= 30:
		b.text = "Pleine"
		b.disabled = true
	else:
		b.text = "Rejoindre" if str(g.recrutement) == "ouvert" else "Postuler"
		b.pressed.connect(func(): _action("postuler_guilde", {"p_guilde": g.id}))
	return p


# ---------------------------------------------------------------
# DANS UNE GUILDE
# ---------------------------------------------------------------

func _construire_avec_guilde() -> void:
	var g: Dictionary = _guilde
	var role := str(g.mon_role)

	# --- Bandeau ---
	var bandeau := PanelContainer.new()
	bandeau.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	_corps.add_child(bandeau)
	var bl := HBoxContainer.new()
	bl.add_theme_constant_override("separation", 18)
	bandeau.add_child(bl)
	bl.add_child(UiCommun.avatar("", str(g.nom), 72))
	var infos := VBoxContainer.new()
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl.add_child(infos)
	infos.add_child(UiCommun.label(str(g.nom), 30, UiCommun.C_LEGENDE))
	infos.add_child(UiCommun.label("Niveau %d  ·  %d/%d membres  ·  Recrutement : %s  ·  Ton rôle : %s" % [
		int(g.niveau), (g.membres as Array).size(), int(g.capacite), _nom_recrutement(str(g.recrutement)),
		EcranSocial._nom_role(role)], 16, UiCommun.C_DOUX))
	if str(g.description) != "":
		var d := UiCommun.label(str(g.description), 16)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		infos.add_child(d)

	# --- Onglets ---
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	_corps.add_child(onglets)
	_boutons_onglet.clear()
	var liste := [["membres", "Membres"]]
	if role in ["chef", "officier"]:
		var nb := (g.demandes as Array).size()
		liste.append(["candidatures", "Candidatures" + (" (%d)" % nb if nb > 0 else "")])
	liste.append(["guerre", "Guerre de guildes"])
	liste.append(["reglages", "Réglages"])
	for o in liste:
		var b := UiCommun.bouton(o[1], 19)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(210, 46)
		b.pressed.connect(_changer_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglet[o[0]] = b
	if not _boutons_onglet.has(_onglet):
		_onglet = "membres"

	var cadre := PanelContainer.new()
	cadre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cadre.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	_corps.add_child(cadre)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cadre.add_child(defil)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 8)
	defil.add_child(_contenu)
	_changer_onglet(_onglet)


func _changer_onglet(id: String) -> void:
	_onglet = id
	for k in _boutons_onglet:
		_boutons_onglet[k].button_pressed = (k == id)
	_vider(_contenu)
	match id:
		"membres": _afficher_membres()
		"candidatures": _afficher_candidatures()
		"guerre": _afficher_guerre()
		"reglages": _afficher_reglages()


func _afficher_membres() -> void:
	var mon_role := str(_guilde.mon_role)
	for m in _guilde.membres:
		var role := str(m.role)
		var actions := [["Profil", func(): EcranSocial.ouvrir_profil(self, str(m.id))]]
		if str(m.id) != EnLigne.id_joueur():
			if mon_role == "chef":
				if role == "membre":
					actions.append(["Promouvoir", func(): _action("gerer_membre", {"p_joueur": m.id, "p_action": "promouvoir"})])
				elif role == "officier":
					actions.append(["Rétrograder", func(): _action("gerer_membre", {"p_joueur": m.id, "p_action": "retrograder"})])
				actions.append(["Nommer chef", func(): FenetreSimple.confirmer(self, "Nommer chef",
					"Donner la direction de la guilde à %s ?\nTu deviendras officier." % m.pseudo, "Nommer chef",
					func(): _action("gerer_membre", {"p_joueur": m.id, "p_action": "nommer_chef"}))])
			if mon_role == "chef" or (mon_role == "officier" and role == "membre"):
				actions.append(["Exclure", func(): FenetreSimple.confirmer(self, "Exclure",
					"Exclure %s de la guilde ?" % m.pseudo, "Exclure",
					func(): _action("gerer_membre", {"p_joueur": m.id, "p_action": "exclure"}))])
		_contenu.add_child(_ligne_membre(m, EcranSocial._nom_role(role), COULEURS_ROLE.get(role, UiCommun.C_DOUX), actions))


func _afficher_candidatures() -> void:
	if (_guilde.demandes as Array).is_empty():
		_contenu.add_child(UiCommun.label("Aucune candidature en attente.", 17, UiCommun.C_DOUX))
	for d in _guilde.demandes:
		_contenu.add_child(_ligne_membre(d, "Candidat", UiCommun.C_DOUX, [
			["Profil", func(): EcranSocial.ouvrir_profil(self, str(d.id))],
			["Accepter", func(): _action("repondre_demande_guilde", {"p_joueur": d.id, "p_accepter": true})],
			["Refuser", func(): _action("repondre_demande_guilde", {"p_joueur": d.id, "p_accepter": false})],
		]))


## Guerre de guildes : menu prêt, combats codés plus tard.
func _afficher_guerre() -> void:
	_contenu.add_child(UiCommun.label("GUERRE DE GUILDES", 26, UiCommun.C_OR))
	_contenu.add_child(UiCommun.label("Bientôt disponible", 20, UiCommun.C_LEGENDE))
	var texte := UiCommun.label("Deux guildes s'affrontent pendant une saison de guerre :\n"
		+ "  • chaque membre prépare une équipe de défense pour sa guilde ;\n"
		+ "  • pendant la guerre, chacun attaque les défenses de la guilde adverse ;\n"
		+ "  • chaque victoire rapporte des points à la guilde ; la guilde qui en a le plus gagne ;\n"
		+ "  • récompenses pour tous les membres et classement des guildes.", 17)
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(texte)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	_contenu.add_child(ligne)
	for t in ["Préparer ma défense", "Inscrire la guilde", "Classement des guildes"]:
		var b := UiCommun.bouton(t)
		b.disabled = true
		b.tooltip_text = "Bientôt disponible"
		b.custom_minimum_size = Vector2(240, 46)
		ligne.add_child(b)


func _afficher_reglages() -> void:
	var g: Dictionary = _guilde
	var peut_modifier := str(g.mon_role) in ["chef", "officier"]
	if peut_modifier:
		_contenu.add_child(UiCommun.label("RÉGLAGES DE LA GUILDE", 22, UiCommun.C_OR))
		_contenu.add_child(UiCommun.label("Description", 16, UiCommun.C_DOUX))
		var desc := TextEdit.new()
		desc.text = str(g.description)
		desc.custom_minimum_size = Vector2(0, 100)
		desc.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		_contenu.add_child(desc)
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 14)
		_contenu.add_child(ligne)
		ligne.add_child(UiCommun.label("Recrutement", 16, UiCommun.C_DOUX))
		var recrut := _choix_recrutement(str(g.recrutement))
		ligne.add_child(recrut)
		ligne.add_child(UiCommun.label("Niveau de compte minimum", 16, UiCommun.C_DOUX))
		var niv := SpinBox.new()
		niv.min_value = 1
		niv.max_value = Sauvegarde.NIVEAU_COMPTE_MAX
		niv.value = int(g.niveau_min)
		ligne.add_child(niv)
		var enregistrer := UiCommun.bouton("Enregistrer")
		enregistrer.custom_minimum_size = Vector2(200, 44)
		enregistrer.pressed.connect(func(): _action("modifier_guilde", {"p_description": desc.text.left(200),
			"p_recrutement": RECRUTEMENTS[recrut.selected][0], "p_niveau_min": int(niv.value)}))
		_contenu.add_child(enregistrer)
		_contenu.add_child(HSeparator.new())

	var seul := (g.membres as Array).size() <= 1
	var texte := "Tu es le dernier membre : quitter dissoudra la guilde." if seul else \
		("Tu es le chef : si tu pars, le plus ancien officier (sinon le plus ancien membre) deviendra chef." if str(g.mon_role) == "chef" else "")
	if texte != "":
		_contenu.add_child(UiCommun.label(texte, 16, UiCommun.C_DOUX))
	var quitter := UiCommun.bouton("Quitter la guilde")
	quitter.custom_minimum_size = Vector2(220, 44)
	quitter.add_theme_color_override("font_color", Color("ff7a6a"))
	quitter.pressed.connect(func(): FenetreSimple.confirmer(self, "Quitter la guilde",
		"Quitter « %s » ?%s" % [g.nom, "\nLa guilde sera dissoute." if seul else ""], "Quitter",
		func(): _action("quitter_guilde", {})))
	_contenu.add_child(quitter)


# ---------------------------------------------------------------
# Outils
# ---------------------------------------------------------------

func _ligne_membre(m: Dictionary, texte_role: String, couleur_role: Color, actions: Array) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_carte(couleur_role.darkened(0.35)))
	var marge := _marge(p, 8)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	marge.add_child(ligne)
	ligne.add_child(UiCommun.avatar(str(m.heros_vitrine), str(m.pseudo), 52))
	var infos := VBoxContainer.new()
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(infos)
	var nom := str(m.pseudo) + ("  (toi)" if str(m.id) == EnLigne.id_joueur() else "")
	infos.add_child(UiCommun.label(nom, 20))
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	infos.add_child(bas)
	bas.add_child(UiCommun.label(texte_role, 15, couleur_role))
	bas.add_child(UiCommun.label("Niv. %d" % int(m.niveau), 15, UiCommun.C_DOUX))
	if m.has("vu_le"):
		var pres := EnLigne.texte_presence(str(m.vu_le))
		bas.add_child(UiCommun.label(pres, 15, Color("8fe07a") if pres == "En ligne" else UiCommun.C_DOUX))
	for a in actions:
		var b := UiCommun.bouton(a[0], 15)
		b.custom_minimum_size = Vector2(120, 40)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(a[1])
		ligne.add_child(b)
	return p


func _panneau(parent: Control, largeur: float) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	if largeur > 0:
		p.custom_minimum_size = Vector2(largeur, 0)
	parent.add_child(p)
	var marge := _marge(p, 6)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	marge.add_child(vb)
	return vb


func _marge(parent: Control, valeur: int) -> MarginContainer:
	var m := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + cote, valeur)
	parent.add_child(m)
	return m


func _choix_recrutement(actuel: String) -> OptionButton:
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(200, 40)
	for i in RECRUTEMENTS.size():
		o.add_item(RECRUTEMENTS[i][1], i)
		if RECRUTEMENTS[i][0] == actuel:
			o.select(i)
	return o


func _nom_recrutement(id: String) -> String:
	for r in RECRUTEMENTS:
		if r[0] == id:
			return r[1]
	return id


func _nombre(n: int) -> String:
	var s := str(n)
	var res := ""
	while s.length() > 3:
		res = " " + s.right(3) + res
		s = s.left(s.length() - 3)
	return s + res


func _vider(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_retour()
