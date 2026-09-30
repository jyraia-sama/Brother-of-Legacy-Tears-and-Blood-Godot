class_name EcranSocial
extends Control
## SOCIAL : amis, demandes d'ami, ajout d'un ami par pseudo.
## Tout est sur le serveur (supabase/01_comptes_amis_guildes.sql) : il faut être connecté.
##
## Commandes : Échap = retour

const SCENE := "res://scenes/social.tscn"
const FOND := "res://assets/ui/menu_bg.png"

## Écran à rouvrir avec le bouton Retour (rempli par l'écran qui ouvre Social).
static var scene_retour := ""

const ONGLETS := [["amis", "Amis"], ["demandes", "Demandes"], ["ajouter", "Ajouter un ami"]]
const MESSAGES := {
	"envoyee": "Demande envoyée !",
	"acceptee": "Vous êtes maintenant amis !",
	"refusee": "Demande refusée.",
	"introuvable": "Aucun joueur ne porte ce pseudo.",
	"soi_meme": "C'est ton propre pseudo !",
	"deja_ami": "Vous êtes déjà amis.",
	"deja_envoyee": "Tu lui as déjà envoyé une demande.",
	"limite": "Liste d'amis pleine (100 maximum).",
	"non_connecte": "Tu n'es pas connecté.",
}

var _onglet := "amis"
var _boutons_onglet := {}
var _liste: VBoxContainer
var _etat: Label
var _donnees: Array = []   # lignes renvoyées par mes_amis()
var _charge := false


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UiCommun.fond_image(self, FOND, Color(0.35, 0.3, 0.3))

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right"]:
		marge.add_theme_constant_override("margin_" + cote, 140)
	for cote in ["top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 30)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	# --- En-tête ---
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var retour := UiCommun.bouton("← Retour")
	retour.custom_minimum_size = Vector2(140, 44)
	retour.pressed.connect(_retour)
	entete.add_child(retour)
	var titre := UiCommun.label("SOCIAL", 36, UiCommun.C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titre)
	if EnLigne.est_connecte():
		entete.add_child(UiCommun.label("%s  (pseudo : %s)" % [EnLigne.nom_complet(), EnLigne.pseudo()], 20, UiCommun.C_LEGENDE))
		var rafraichir := UiCommun.bouton("↻ Actualiser")
		rafraichir.pressed.connect(_charger)
		entete.add_child(rafraichir)

	if not EnLigne.est_connecte():
		_ecran_non_connecte(colonne)
		return

	# --- Onglets ---
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for o in ONGLETS:
		var b := UiCommun.bouton(o[1], 19)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(220, 46)
		b.pressed.connect(_changer_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglet[o[0]] = b

	_etat = UiCommun.label("", 18, Color(1.0, 0.8, 0.5))
	colonne.add_child(_etat)

	# --- Contenu ---
	var cadre := PanelContainer.new()
	cadre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cadre.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	colonne.add_child(cadre)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cadre.add_child(defil)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste.add_theme_constant_override("separation", 8)
	defil.add_child(_liste)

	_changer_onglet("amis")
	_charger()


func _ecran_non_connecte(colonne: VBoxContainer) -> void:
	var centre := CenterContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(centre)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	var texte := "Connecte-toi à ton compte pour ajouter des amis." if EnLigne.configure() \
		else "Le jeu en ligne n'est pas encore configuré (voir SUPABASE.md)."
	vb.add_child(UiCommun.label(texte, 20))
	if EnLigne.configure():
		var b := UiCommun.bouton("Se connecter")
		b.pressed.connect(func(): FenetreCompte.ouvrir(self, false, func(): get_tree().reload_current_scene()))
		vb.add_child(b)


# ---------------------------------------------------------------
# Données
# ---------------------------------------------------------------

func _charger() -> void:
	_etat.text = "Chargement…"
	var r := await EnLigne.appeler("mes_amis")
	if not is_inside_tree():
		return
	if not r.ok:
		_etat.text = r.erreur
		return
	_etat.text = ""
	_donnees = r.data if r.data is Array else []
	_charge = true
	_maj_titres_onglets()
	_afficher()


func _lignes(relation: String) -> Array:
	return _donnees.filter(func(d): return d.get("relation", "") == relation)


func _maj_titres_onglets() -> void:
	var nb_amis := _lignes("ami").size()
	var nb_recues := _lignes("recue").size()
	_boutons_onglet["amis"].text = "Amis (%d/100)" % nb_amis
	_boutons_onglet["demandes"].text = "Demandes" + (" (%d)" % nb_recues if nb_recues > 0 else "")


func _changer_onglet(id: String) -> void:
	_onglet = id
	for k in _boutons_onglet:
		_boutons_onglet[k].button_pressed = (k == id)
	_afficher()


func _afficher() -> void:
	for c in _liste.get_children():
		c.queue_free()
	match _onglet:
		"amis":
			if not _charge:
				return
			var amis := _lignes("ami")
			# Ceux qui sont en ligne d'abord
			amis.sort_custom(func(a, b): return EnLigne.date_vers_unix(str(a.vu_le)) > EnLigne.date_vers_unix(str(b.vu_le)))
			if amis.is_empty():
				_vide("Pas encore d'amis. Va dans « Ajouter un ami » et entre le pseudo d'un joueur.")
			for d in amis:
				_liste.add_child(_ligne_joueur(d, [["Profil", _voir_profil.bind(d)], ["Retirer", _retirer.bind(d)]]))
		"demandes":
			if not _charge:
				return
			var recues := _lignes("recue")
			var envoyees := _lignes("envoyee")
			_sous_titre("Demandes reçues")
			if recues.is_empty():
				_vide("Aucune demande reçue.")
			for d in recues:
				_liste.add_child(_ligne_joueur(d, [["Accepter", _repondre.bind(d, true)], ["Refuser", _repondre.bind(d, false)]]))
			_sous_titre("Demandes envoyées")
			if envoyees.is_empty():
				_vide("Aucune demande en attente.")
			for d in envoyees:
				_liste.add_child(_ligne_joueur(d, [["Annuler", _annuler.bind(d)]]))
		"ajouter":
			_afficher_ajout()


func _afficher_ajout() -> void:
	_sous_titre("Ajouter un ami")
	_vide("Entre le pseudo exact du joueur (majuscules sans importance). Donne aussi ton pseudo à tes amis : %s" % EnLigne.pseudo())
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	_liste.add_child(ligne)
	var champ := LineEdit.new()
	champ.placeholder_text = "Pseudo du joueur"
	champ.max_length = 16
	champ.custom_minimum_size = Vector2(360, 46)
	ligne.add_child(champ)
	var envoyer := UiCommun.bouton("Envoyer la demande")
	envoyer.custom_minimum_size = Vector2(240, 46)
	ligne.add_child(envoyer)
	var action := func():
		if champ.text.strip_edges() == "":
			return
		envoyer.disabled = true
		var r := await EnLigne.appeler("envoyer_demande_ami", {"p_pseudo": champ.text.strip_edges()})
		if not is_inside_tree():
			return
		envoyer.disabled = false
		_etat.text = _message(r)
		if r.ok and str(r.data) in ["envoyee", "acceptee"]:
			champ.text = ""
			_charger()
	envoyer.pressed.connect(action)
	champ.text_submitted.connect(func(_t): action.call())
	champ.grab_focus.call_deferred()


# ---------------------------------------------------------------
# Actions
# ---------------------------------------------------------------

func _repondre(d: Dictionary, accepter: bool) -> void:
	var r := await EnLigne.appeler("repondre_demande_ami", {"p_joueur": d.id, "p_accepter": accepter})
	if is_inside_tree():
		_etat.text = _message(r)
		_charger()


func _annuler(d: Dictionary) -> void:
	var r := await EnLigne.appeler("retirer_ami", {"p_joueur": d.id})
	if is_inside_tree():
		_etat.text = "Demande annulée." if r.ok else r.erreur
		_charger()


func _retirer(d: Dictionary) -> void:
	FenetreSimple.confirmer(self, "Retirer un ami", "Retirer %s de ta liste d'amis ?" % EnLigne.nom_complet(str(d.pseudo)), "Retirer", func():
		var r := await EnLigne.appeler("retirer_ami", {"p_joueur": d.id})
		if is_inside_tree():
			_etat.text = "%s a été retiré de tes amis." % EnLigne.nom_complet(str(d.pseudo)) if r.ok else r.erreur
			_charger())


func _voir_profil(d: Dictionary) -> void:
	EcranSocial.ouvrir_profil(self, str(d.id))


## Fiche d'un joueur (utilisée aussi par l'écran Guilde).
static func ouvrir_profil(parent: Node, id_joueur: String) -> void:
	var r := await EnLigne.appeler("profil_joueur", {"p_joueur": id_joueur})
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	if not r.ok or not (r.data is Dictionary):
		FenetreSimple.ouvrir(parent, "Profil", r.erreur if not r.ok else "Joueur introuvable.")
		return
	var p: Dictionary = r.data
	var contenu := HBoxContainer.new()
	contenu.add_theme_constant_override("separation", 18)
	contenu.add_child(UiCommun.avatar(str(p.heros_vitrine), str(p.pseudo), 90))
	var infos := VBoxContainer.new()
	contenu.add_child(infos)
	infos.add_child(UiCommun.label("Niveau de compte %d" % int(p.niveau), 19))
	var heros := str(p.heros_vitrine)
	if heros != "" and UnitesData.existe(heros):
		infos.add_child(UiCommun.label("Héros : " + str(UnitesData.get_unite(heros)["nom"]), 17, UiCommun.C_DOUX))
	var guilde := str(p.guilde)
	infos.add_child(UiCommun.label("Guilde : " + (guilde + " (" + _nom_role(str(p.role)) + ")" if guilde != "" else "aucune"), 17, UiCommun.C_DOUX))
	var pres := EnLigne.texte_presence(str(p.vu_le))
	infos.add_child(UiCommun.label(pres, 17, Color("8fe07a") if pres == "En ligne" else UiCommun.C_DOUX))
	infos.add_child(UiCommun.label("Joueur depuis le " + str(p.cree_le).left(10), 15, UiCommun.C_DOUX))
	FenetreSimple.ouvrir(parent, EnLigne.nom_complet(str(p.pseudo)), "", [], contenu)


static func _nom_role(role: String) -> String:
	return {"chef": "Chef", "officier": "Officier", "membre": "Membre"}.get(role, role)


# ---------------------------------------------------------------
# Construction des lignes
# ---------------------------------------------------------------

func _ligne_joueur(d: Dictionary, actions: Array) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_OR.darkened(0.3)))
	var marge := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 10)
	p.add_child(marge)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	marge.add_child(ligne)
	ligne.add_child(UiCommun.avatar(str(d.heros_vitrine), str(d.pseudo), 58))
	var infos := VBoxContainer.new()
	infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(infos)
	infos.add_child(UiCommun.label(EnLigne.nom_complet(str(d.pseudo)), 22, UiCommun.C_TEXTE))
	var details := "Niv. %d" % int(d.niveau)
	if str(d.get("guilde", "")) != "":
		details += "  ·  Guilde : " + str(d.guilde)
	infos.add_child(UiCommun.label(details, 16, UiCommun.C_DOUX))
	var pres := EnLigne.texte_presence(str(d.vu_le))
	infos.add_child(UiCommun.label(pres, 15, Color("8fe07a") if pres == "En ligne" else UiCommun.C_DOUX))
	for a in actions:
		var b := UiCommun.bouton(a[0])
		b.custom_minimum_size = Vector2(130, 42)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(a[1])
		ligne.add_child(b)
	return p


func _sous_titre(texte: String) -> void:
	_liste.add_child(UiCommun.label(texte, 22, UiCommun.C_OR))


func _vide(texte: String) -> void:
	var l := UiCommun.label(texte, 17, UiCommun.C_DOUX)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_liste.add_child(l)


func _message(r: Dictionary) -> String:
	if not r.ok:
		return r.erreur
	return MESSAGES.get(str(r.data), str(r.data))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_retour()
