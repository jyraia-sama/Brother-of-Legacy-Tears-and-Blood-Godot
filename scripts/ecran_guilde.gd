class_name EcranGuilde
extends Control
## GUILDE
##  - Sans guilde : créer une guilde, ou en chercher une (rejoindre / postuler).
##  - Dans une guilde : Accueil (niveau, dons, annonce, journal), Discussion, Boss de guilde,
##    Bénédictions, Boutique, Membres, Candidatures (chef/officiers), Guerre (écran de guerre), Réglages.
##    Vie de guilde : supabase/05_guildes_vie.sql (+ scripts/guilde.gd pour les bonus en combat).
## Rôles : Chef (tous les droits), Officier (accepte les candidats, exclut les membres), Membre.
## Tout est vérifié par le serveur (supabase/01_comptes_amis_guildes.sql).

const SCENE := "res://scenes/guilde.tscn"
const FOND := "res://assets/fonds/guilde.png"

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
var _vie = null             # Dictionary renvoyé par guilde_vie() (niveau, dons, boss…), ou null
var _onglet := "accueil"
var _chat_dernier := 0
var _chat_liste: VBoxContainer
var _chat_defile: ScrollContainer
var _minuterie_chat: Timer
var _boutons_onglet := {}
var _corps: VBoxContainer
var _contenu: VBoxContainer
var _etat: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiCommun.fond_image(self, FOND, UiCommun.TEINTE_FOND)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + cote, 40)
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
	_vie = null
	if _guilde != null:
		var rv := await EnLigne.appeler("guilde_vie")
		if not is_inside_tree():
			return
		if rv.ok and rv.data is Dictionary:
			_vie = rv.data
			Guilde.memoriser(_vie.get("benedictions", {}))
		else:
			_etat.text = "La vie de guilde n'est pas encore installée sur le serveur (fichier supabase/05_guildes_vie.sql)."
	else:
		Guilde.memoriser({})
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
	var cout := UiCommun.label(UiCommun.t("Coût : %s or  (tu as %s or)") % [_nombre(COUT_CREATION), _nombre(Sauvegarde.get_or())], 17, UiCommun.C_LEGENDE)
	gauche.add_child(cout)
	var creer := UiCommun.bouton("Fonder la guilde")
	creer.custom_minimum_size = Vector2(0, 48)
	gauche.add_child(creer)
	creer.pressed.connect(func():
		if Sauvegarde.get_or() < COUT_CREATION:
			_etat.text = UiCommun.t("Il te faut %s or pour fonder une guilde.") % _nombre(COUT_CREATION)
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
			_etat.text = UiCommun.t("La guilde « %s » est fondée ! Tu en es le chef.") % nom.text.strip_edges()
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
	infos.add_child(UiCommun.label(UiCommun.t("%d/%d membres  ·  Chef : %s  ·  %s%s") % [int(g.membres), 30, str(g.chef),
		_nom_recrutement(str(g.recrutement)), (UiCommun.t("  ·  Niv. %d min.") % int(g.niveau_min)) if int(g.niveau_min) > 1 else ""], 15, UiCommun.C_DOUX))
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
	var niveau_g: int = int(_vie.niveau) if _vie != null else int(g.niveau)
	infos.add_child(UiCommun.label(UiCommun.t("Niveau %d  ·  %d/%d membres  ·  Recrutement : %s  ·  Ton rôle : %s") % [
		niveau_g, (g.membres as Array).size(), int(g.capacite), _nom_recrutement(str(g.recrutement)),
		EcranSocial._nom_role(role)], 16, UiCommun.C_DOUX))
	if _vie != null:
		var lx := HBoxContainer.new()
		lx.add_theme_constant_override("separation", 10)
		infos.add_child(lx)
		var debut := int(_vie.xp_niveau)
		var fin := int(_vie.xp_suivant)
		var barre := UiCommun.barre(UiCommun.C_OR, 320, 10)
		barre.max_value = maxi(1, fin - debut)
		barre.value = int(_vie.xp) - debut
		barre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lx.add_child(barre)
		lx.add_child(UiCommun.label(UiCommun.t("XP %s / %s   ·   Trésor : %s   ·   Mes Sceaux de guilde : %s") % [
			_nombre(int(_vie.xp)), _nombre(fin), _nombre(int(_vie.tresor)), _nombre(int(_vie.mes_sceaux))], 15, UiCommun.C_TEXTE))
	if str(g.description) != "":
		var d := UiCommun.label(str(g.description), 16)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		infos.add_child(d)

	# --- Onglets ---
	var onglets := HFlowContainer.new()
	onglets.add_theme_constant_override("h_separation", 8)
	onglets.add_theme_constant_override("v_separation", 6)
	_corps.add_child(onglets)
	_boutons_onglet.clear()
	var liste := []
	if _vie != null:
		var don := "" if bool(_vie.don_fait) else "  •"
		liste.append_array([["accueil", "Accueil" + don], ["discussion", "Discussion"], ["boss", "Boss de guilde"],
			["benedictions", "Bénédictions"], ["boutique", "Boutique"]])
	liste.append(["membres", "Membres"])
	if role in ["chef", "officier"]:
		var nb := (g.demandes as Array).size()
		liste.append(["candidatures", "Candidatures" + (" (%d)" % nb if nb > 0 else "")])
	liste.append(["guerre", "Guerre"])
	liste.append(["reglages", "Réglages"])
	for o in liste:
		var b := UiCommun.bouton(o[1], 17)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 42)
		b.pressed.connect(_changer_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglet[o[0]] = b
	if not _boutons_onglet.has(_onglet):
		_onglet = "accueil" if _vie != null else "membres"

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
	if is_instance_valid(_minuterie_chat):
		_minuterie_chat.queue_free()
	match id:
		"accueil": _afficher_accueil()
		"discussion": _afficher_discussion()
		"boss": _afficher_boss()
		"benedictions": _afficher_benedictions()
		"boutique": _afficher_boutique()
		"membres": _afficher_membres()
		"candidatures": _afficher_candidatures()
		"guerre": _afficher_guerre()
		"reglages": _afficher_reglages()


# ---------------------------------------------------------------
# VIE DE GUILDE
# ---------------------------------------------------------------

func _titre(texte: String) -> void:
	_contenu.add_child(UiCommun.label(texte, 22, UiCommun.C_OR))


func _texte(texte: String, taille := 16, couleur := UiCommun.C_TEXTE) -> Label:
	var l := UiCommun.label(texte, taille, couleur)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(l)
	return l


func _peut_gerer() -> bool:
	return str(_guilde.mon_role) in ["chef", "officier"]


## Résultat d'une action « vie de guilde » : message + rechargement.
const MESSAGES_VIE := {
	"ok": "C'est fait.", "deja_donne": "Tu as déjà fait ton don aujourd'hui.", "interdit": "Réservé au chef et aux officiers.",
	"rang_max": "Cette bénédiction est déjà au rang maximum.", "niveau_guilde": "La guilde n'a pas encore le niveau requis.",
	"tresor": "Le trésor de guilde ne suffit pas.", "limite": "Limite de la semaine atteinte pour cet objet.",
	"sceaux": "Pas assez de Sceaux de guilde.", "essais": "Plus d'assaut aujourd'hui : reviens demain !",
	"rien": "Aucun nouveau palier à réclamer.", "pas_participe": "Attaque le titan au moins une fois cette semaine pour toucher les paliers.",
	"trop_vite": "Doucement ! Attends un peu avant le prochain message.", "vide": "",
}


func _afficher_accueil() -> void:
	var v: Dictionary = _vie
	_titre("MOT DU CHEF")
	_texte(str(v.annonce) if str(v.annonce) != "" else "Le chef n'a encore rien écrit.", 17,
		UiCommun.C_TEXTE if str(v.annonce) != "" else UiCommun.C_DOUX)
	if _peut_gerer():
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		_contenu.add_child(ligne)
		var champ := LineEdit.new()
		champ.max_length = 200
		champ.text = str(v.annonce)
		champ.placeholder_text = "Écris un message pour toute la guilde (200 caractères)"
		champ.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		champ.custom_minimum_size = Vector2(0, 40)
		ligne.add_child(champ)
		var b := UiCommun.bouton("Publier", 16)
		b.pressed.connect(func(): _action_vie("guilde_annonce", {"p_texte": champ.text}))
		ligne.add_child(b)
	_contenu.add_child(HSeparator.new())

	_titre("DON DU JOUR")
	_texte("Un don par jour. Il fait grandir la guilde (XP et trésor) et te rapporte des Sceaux de guilde, à dépenser à la Boutique.", 15, UiCommun.C_DOUX)
	var dons := HBoxContainer.new()
	dons.add_theme_constant_override("separation", 12)
	_contenu.add_child(dons)
	var regl: Dictionary = (v.reglages as Dictionary).get("dons", {})
	for d in Guilde.DONS:
		var info: Dictionary = regl.get(d["id"], {})
		var b := UiCommun.bouton(UiCommun.t("%s\n%s  →  +%d XP · +%d Sceaux") % [d["nom"], d["texte"], int(info.get("xp", 0)), int(info.get("sceaux", 0))], 15)
		b.custom_minimum_size = Vector2(300, 64)
		b.disabled = bool(v.don_fait)
		b.pressed.connect(_donner.bind(d["id"], info))
		dons.add_child(b)
	if bool(v.don_fait):
		_texte("Merci pour ton don ! Reviens demain.", 15, Color("8fe07a"))
	_contenu.add_child(HSeparator.new())

	_titre("JOURNAL DE LA GUILDE")
	if (v.journal as Array).is_empty():
		_texte("Rien pour l'instant.", 15, UiCommun.C_DOUX)
	for j in v.journal:
		_texte("%s   %s" % [_date_courte(str(j.cree_le)), j.texte], 15)


func _donner(type: String, info: Dictionary) -> void:
	var cout_or := int(info.get("cout_or", 0))
	var cout_gemmes := int(info.get("cout_gemmes", 0))
	if Sauvegarde.get_or() < cout_or:
		_etat.text = UiCommun.t("Il te faut %s or pour ce don.") % _nombre(cout_or)
		return
	if Sauvegarde.get_gemmes() < cout_gemmes:
		_etat.text = UiCommun.t("Il te faut %d gemmes pour ce don.") % cout_gemmes
		return
	var r := await EnLigne.appeler("guilde_donner", {"p_type": type})
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		Sauvegarde.depenser_or(int(r.data.get("cout_or", 0)))
		Sauvegarde.depenser_gemmes(int(r.data.get("cout_gemmes", 0)))
		await _charger()
		_etat.text = UiCommun.t("Don envoyé : +%d XP de guilde, +%d Sceaux de guilde.") % [int(r.data.xp), int(r.data.sceaux)]
	else:
		_etat.text = _message_vie(r)


func _message_vie(r: Dictionary) -> String:
	if not r.ok:
		return r.erreur
	var code := str(r.data.get("code", "")) if r.data is Dictionary else str(r.data)
	return MESSAGES_VIE.get(code, MESSAGES.get(code, code))


func _action_vie(fonction: String, params: Dictionary) -> void:
	var r := await EnLigne.appeler(fonction, params)
	if not is_inside_tree():
		return
	var msg := _message_vie(r)
	await _charger()
	_etat.text = msg


func _date_courte(t: String) -> String:
	var u := EnLigne.date_vers_unix(t)
	if u <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(u + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d/%02d %02d:%02d" % [d.day, d.month, d.hour, d.minute]


# --- Discussion ---------------------------------------------------

func _afficher_discussion() -> void:
	_titre("DISCUSSION DE GUILDE")
	_chat_defile = ScrollContainer.new()
	_chat_defile.custom_minimum_size = Vector2(0, 330)
	_chat_defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chat_defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_contenu.add_child(_chat_defile)
	_chat_liste = VBoxContainer.new()
	_chat_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_liste.add_theme_constant_override("separation", 4)
	_chat_defile.add_child(_chat_liste)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	_contenu.add_child(ligne)
	var champ := LineEdit.new()
	champ.max_length = 200
	champ.placeholder_text = "Ton message (Entrée pour envoyer)"
	champ.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	champ.custom_minimum_size = Vector2(0, 42)
	ligne.add_child(champ)
	var envoyer := UiCommun.bouton("Envoyer", 16)
	ligne.add_child(envoyer)
	var envoi := func():
		var t := champ.text.strip_edges()
		if t == "":
			return
		champ.text = ""
		var r := await EnLigne.appeler("guilde_chat_envoyer", {"p_texte": t})
		if not is_inside_tree():
			return
		var code := str(r.data) if r.ok else ""
		if code != "ok":
			_etat.text = _message_vie(r) if r.ok else r.erreur
		_lire_chat()
	envoyer.pressed.connect(envoi)
	champ.text_submitted.connect(func(_t): envoi.call())
	_chat_dernier = 0
	_lire_chat()
	_minuterie_chat = Timer.new()
	_minuterie_chat.wait_time = 4.0
	_minuterie_chat.autostart = true
	_minuterie_chat.timeout.connect(_lire_chat)
	add_child(_minuterie_chat)


func _lire_chat() -> void:
	if not is_instance_valid(_chat_liste):
		return
	var r := await EnLigne.appeler("guilde_chat_lire", {"p_depuis": _chat_dernier})
	if not is_instance_valid(_chat_liste) or not r.ok or not r.data is Array:
		return
	if _chat_dernier == 0 and (r.data as Array).is_empty():
		_chat_liste.add_child(UiCommun.label("Aucun message. Lance la conversation !", 15, UiCommun.C_DOUX))
	for m in r.data:
		_chat_dernier = maxi(_chat_dernier, int(m.id))
		var moi := str(m.joueur) == EnLigne.id_joueur()
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_theme_font_size_override("normal_font_size", 16)
		l.add_theme_font_size_override("bold_font_size", 16)
		var nom := EnLigne.nom_complet(str(m.pseudo)).replace("[", "(").replace("]", ")")
		var texte := str(m.texte).replace("[", "(").replace("]", ")")
		l.text = "[color=#8e7f72]%s[/color]  [b][color=%s]%s[/color][/b] : %s" % [
			_date_courte(str(m.cree_le)), "#ffd27a" if moi else "#b58ce6", nom, texte]
		_chat_liste.add_child(l)
	if not (r.data as Array).is_empty():
		await get_tree().process_frame
		if is_instance_valid(_chat_defile):
			_chat_defile.scroll_vertical = int(_chat_defile.get_v_scroll_bar().max_value)


# --- Boss de guilde -----------------------------------------------

func _afficher_boss() -> void:
	var b: Dictionary = _vie.boss
	var info: Dictionary = BossMonde.BOSS[Guilde.index_boss()]
	var haut := HBoxContainer.new()
	haut.add_theme_constant_override("separation", 18)
	_contenu.add_child(haut)
	var chemin := "res://assets/boss_monde/%s.png" % info["id"]
	if ResourceLoader.exists(chemin):
		var img := TextureRect.new()
		img.texture = load(chemin)
		img.custom_minimum_size = Vector2(200, 250)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		haut.add_child(img)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	haut.add_child(col)
	col.add_child(UiCommun.label("TITAN DE LA SEMAINE : " + str(info["titre"]).to_upper(), 22, UiCommun.C_OR))
	var t := UiCommun.label("Toute la guilde affronte le même titan. Chaque assaut de ton armée (comme au Boss de Monde) "
		+ "ajoute ses dégâts à ceux des autres. Paliers à 25, 50, 75 et 100 % : chaque membre qui a frappé "
		+ "au moins une fois cette semaine reçoit les récompenses.", 15, UiCommun.C_DOUX)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)
	var pct := 100.0 * float(b.degats) / maxf(1.0, float(b.pv_max))
	var barre := UiCommun.barre(Color("c0392b"), 520, 18)
	barre.max_value = 100
	barre.value = pct
	col.add_child(barre)
	col.add_child(UiCommun.label(UiCommun.t("%s / %s PV arrachés  (%.1f %%)%s") % [_nombre(int(b.degats)), _nombre(int(b.pv_max)), pct,
		"   —   ABATTU !" if b.abattu else ""], 17, Color("ff8a6a")))
	col.add_child(UiCommun.label(UiCommun.t("Mes dégâts cette semaine : %s en %d assaut(s)   ·   Assauts restants aujourd'hui : %d") % [
		_nombre(int(b.mes_degats)), int(b.mes_coups), maxi(0, int(b.essais_restants))], 15, UiCommun.C_TEXTE))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 12)
	col.add_child(ligne)
	var go := UiCommun.bouton("⚔ LANCER L'ASSAUT", 18)
	go.custom_minimum_size = Vector2(240, 48)
	go.disabled = int(b.essais_restants) <= 0 or bool(b.abattu)
	go.pressed.connect(_assaut_boss)
	ligne.add_child(go)
	var prep := UiCommun.bouton("Préparer l'armée", 16)
	prep.pressed.connect(func():
		EcranArmee.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranArmee.SCENE))
	ligne.add_child(prep)
	var rec := UiCommun.bouton("Réclamer les paliers", 16)
	rec.pressed.connect(_reclamer_boss)
	ligne.add_child(rec)

	# Paliers
	var regl: Dictionary = _vie.reglages
	var paliers: Array = regl.get("boss_paliers", [])
	var lp := HBoxContainer.new()
	lp.add_theme_constant_override("separation", 10)
	_contenu.add_child(lp)
	for i in paliers.size():
		var atteint := pct >= float(paliers[i])
		var recu := i < int(b.paliers_reclames)
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(Color("8fe07a") if recu else (UiCommun.C_OR if atteint else Color("4a3638"))))
		var v := VBoxContainer.new()
		_marge(p, 8).add_child(v)
		v.add_child(UiCommun.label("%d %%%s" % [int(paliers[i]), "  ✔" if recu else ""], 18, UiCommun.C_OR if atteint else UiCommun.C_DOUX))
		var butin: Dictionary = (regl.get("boss_butin", []) as Array)[i]
		var l := UiCommun.label(UiCommun.t("+%d Sceaux\n%s") % [int((regl.get("boss_sceaux", []) as Array)[i]), Quetes.texte_recompense(butin)], 13, UiCommun.C_TEXTE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		lp.add_child(p)

	_titre("CLASSEMENT DE LA SEMAINE")
	if (b.classement as Array).is_empty():
		_texte("Personne n'a encore frappé le titan.", 15, UiCommun.C_DOUX)
	var rang := 1
	for c in b.classement:
		_texte(UiCommun.t("%d.  %s  —  %s dégâts (%d assauts)") % [rang, EnLigne.nom_complet(str(c.pseudo)), _nombre(int(c.degats)), int(c.coups)], 16)
		rang += 1


func _assaut_boss() -> void:
	var armee := BossMonde.armee()
	if armee.is_empty():
		_etat.text = "Ton armée est vide : prépare tes escouades (bouton « Préparer l'armée »)."
		return
	var i := Guilde.index_boss()
	EcranCombat.demande = {"mode": "boss_monde", "guilde": true, "boss_index": i, "type": "boss_monde",
		"tours_max": BossMonde.TOURS_COMBAT, "equipe": armee, "ennemis": BossMonde.generer(i), "retour": SCENE}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


func _reclamer_boss() -> void:
	var r := await EnLigne.appeler("guilde_boss_reclamer")
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		var lignes := Quetes.donner(r.data.get("recompense", {}))
		lignes.push_front(UiCommun.t("Sceaux de guilde : +%d") % int(r.data.sceaux))
		Sauvegarde.sauvegarder()
		await _charger()
		_etat.text = "Paliers réclamés !  " + "  ·  ".join(lignes)
	else:
		_etat.text = _message_vie(r)


# --- Bénédictions -------------------------------------------------

func _afficher_benedictions() -> void:
	_titre("BÉNÉDICTIONS DE LA GUILDE")
	_texte("Des bonus permanents pour TOUS les membres, achetés avec le trésor de guilde (alimenté par les dons). "
		+ UiCommun.t("Seuls le chef et les officiers peuvent les acheter. Rang n : coûte %d x n en trésor et demande le niveau de guilde 2n-1.") % int((_vie.reglages as Dictionary).get("benediction_cout", 300)), 15, UiCommun.C_DOUX)
	_texte(UiCommun.t("Trésor de guilde : %s") % _nombre(int(_vie.tresor)), 18, UiCommun.C_OR)
	var niveau_g := int(_vie.niveau)
	var cout_base := int((_vie.reglages as Dictionary).get("benediction_cout", 300))
	for id in Guilde.BENEDICTIONS:
		var info: Dictionary = Guilde.BENEDICTIONS[id]
		var rang := int((_vie.benedictions as Dictionary).get(id, 0))
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_OR.darkened(0.3) if rang > 0 else Color("4a3638")))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		_marge(p, 8).add_child(h)
		h.add_child(UiCommun.label(info["icone"], 30, UiCommun.C_OR))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UiCommun.label("%s   %s" % [info["nom"], "★".repeat(rang) + "☆".repeat(Guilde.RANG_MAX - rang)], 19))
		v.add_child(UiCommun.label((info["texte"] % (rang * int(info["par_rang"]))) + (UiCommun.t("   (prochain rang : +%d %%)") % ((rang + 1) * int(info["par_rang"])) if rang < Guilde.RANG_MAX else "   (maximum)"), 15, UiCommun.C_DOUX))
		if rang < Guilde.RANG_MAX:
			var suivant := rang + 1
			var b := UiCommun.bouton(UiCommun.t("Rang %d : %s trésor") % [suivant, _nombre(cout_base * suivant)], 15)
			b.custom_minimum_size = Vector2(230, 42)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var bloque := niveau_g < 2 * suivant - 1
			b.disabled = not _peut_gerer() or bloque
			b.tooltip_text = (UiCommun.t("Guilde niveau %d requis") % (2 * suivant - 1)) if bloque else ("" if _peut_gerer() else "Réservé au chef et aux officiers")
			b.pressed.connect(func(): _action_vie("guilde_benir", {"p_benediction": id}))
			h.add_child(b)
		_contenu.add_child(p)


# --- Boutique ------------------------------------------------------

func _afficher_boutique() -> void:
	_titre("BOUTIQUE DE GUILDE")
	_texte(UiCommun.t("Mes Sceaux de guilde : %s   ·   Les limites se réinitialisent chaque lundi.") % _nombre(int(_vie.mes_sceaux)), 17, UiCommun.C_OR)
	var grille := HFlowContainer.new()
	grille.add_theme_constant_override("h_separation", 10)
	grille.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(grille)
	for a in _vie.boutique:
		var deja := int((_vie.achats as Dictionary).get(str(a.id), 0))
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(230, 0)
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_OR.darkened(0.35)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		_marge(p, 10).add_child(v)
		v.add_child(UiCommun.label("%s  x%d" % [Reliquaire.nom(str(a.id)), int(a.quantite)], 17))
		v.add_child(UiCommun.label(UiCommun.t("Cette semaine : %d / %d") % [deja, int(a.limite)], 14, UiCommun.C_DOUX))
		var b := UiCommun.bouton(UiCommun.t("%d Sceaux") % int(a.prix), 16)
		b.disabled = deja >= int(a.limite) or int(_vie.mes_sceaux) < int(a.prix)
		b.pressed.connect(_acheter.bind(str(a.id)))
		v.add_child(b)
		grille.add_child(p)


func _acheter(id: String) -> void:
	var r := await EnLigne.appeler("guilde_acheter", {"p_article": id})
	if not is_inside_tree():
		return
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		var lignes := Quetes.donner(r.data.get("recompense", {}))
		Sauvegarde.sauvegarder()
		await _charger()
		_etat.text = "Acheté : " + "  ·  ".join(lignes)
	else:
		_etat.text = _message_vie(r)


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
					UiCommun.t("Donner la direction de la guilde à %s ?\nTu deviendras officier.") % EnLigne.nom_complet(str(m.pseudo)), "Nommer chef",
					func(): _action("gerer_membre", {"p_joueur": m.id, "p_action": "nommer_chef"}))])
			if mon_role == "chef" or (mon_role == "officier" and role == "membre"):
				actions.append(["Exclure", func(): FenetreSimple.confirmer(self, "Exclure",
					UiCommun.t("Exclure %s de la guilde ?") % EnLigne.nom_complet(str(m.pseudo)), "Exclure",
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


## Guerre des Bannières : résumé et accès à l'écran de guerre (ecran_guerre.gd).
func _afficher_guerre() -> void:
	_contenu.add_child(UiCommun.label("LA GUERRE DES BANNIÈRES", 26, UiCommun.C_OR))
	var texte := UiCommun.label("Une guerre de guildes chaque semaine, chacun joue quand il veut :\n"
		+ "  • lundi-mardi : préparation (inscription de la guilde, défenses de guerre) ;\n"
		+ "  • mercredi-samedi : 2 assauts par jour contre la forteresse ennemie (Remparts, Tours, Donjon) ;\n"
		+ "  • dimanche : bilan, la guilde qui a pris le plus d'étoiles gagne, et chacun réclame son butin.\n"
		+ "Fatigue des unités, éclaireur, rediffusions… et s'il n'y a pas d'autre guilde à votre mesure,\n"
		+ "c'est la Légion de la Soif qui vous attaque.", 17)
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(texte)
	var b := UiCommun.bouton("⚔ Ouvrir la Guerre des Bannières", 20)
	b.custom_minimum_size = Vector2(420, 54)
	UiCommun.bouton_vif(b, Color("b8402f"))
	b.pressed.connect(func(): get_tree().change_scene_to_file(EcranGuerre.SCENE))
	_contenu.add_child(b)


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
		UiCommun.t("Quitter « %s » ?%s") % [g.nom, "\nLa guilde sera dissoute." if seul else ""], "Quitter",
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
	var nom := EnLigne.nom_complet(str(m.pseudo)) + ("  (toi)" if str(m.id) == EnLigne.id_joueur() else "")
	infos.add_child(UiCommun.label(nom, 20))
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	infos.add_child(bas)
	bas.add_child(UiCommun.label(texte_role, 15, couleur_role))
	bas.add_child(UiCommun.label(UiCommun.t("Niv. %d") % int(m.niveau), 15, UiCommun.C_DOUX))
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
