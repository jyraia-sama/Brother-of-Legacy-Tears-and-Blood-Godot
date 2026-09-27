class_name FenetreCompte
extends CanvasLayer
## Fenêtre COMPTE : connexion / création de compte (pseudo + mot de passe),
## ou, si on est déjà connecté : pseudo, synchronisation, déconnexion.
##
##   FenetreCompte.ouvrir(self)                          -> depuis n'importe quel écran
##   FenetreCompte.ouvrir(self, true, func(): ...)       -> au lancement (bouton « Jouer hors ligne »)

var au_demarrage := false
var quand_fermee: Callable

var _mode_creation := false
var _vb: VBoxContainer
var _pseudo: LineEdit
var _mdp: LineEdit
var _mdp2: LineEdit
var _etat: Label
var _boutons: Array[Button] = []
var _onglet_connexion: Button
var _onglet_creation: Button
var _occupe := false


static func ouvrir(parent: Node, p_au_demarrage := false, p_quand_fermee: Callable = Callable()) -> FenetreCompte:
	var f := FenetreCompte.new()
	f.au_demarrage = p_au_demarrage
	f.quand_fermee = p_quand_fermee
	parent.add_child(f)
	return f


func _ready() -> void:
	layer = 52
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := UiCommun.style_panneau()
	style.set_content_margin_all(26)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(560, 0)
	centre.add_child(panneau)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 12)
	panneau.add_child(_vb)
	_construire()
	EnLigne.etat_change.connect(_sur_etat_change)


func _construire() -> void:
	for c in _vb.get_children():
		c.queue_free()
	_boutons.clear()
	_titre("COMPTE")
	if not EnLigne.configure():
		_texte("Le jeu en ligne n'est pas encore configuré.\nRemplis URL et CLE dans scripts/config_en_ligne.gd (voir SUPABASE.md).", UiCommun.C_DOUX)
		_ligne_boutons([["Fermer", _fermer]])
	elif EnLigne.est_connecte():
		_construire_connecte()
	else:
		_construire_formulaire()


# ---------- Pas connecté : connexion / création ----------

func _construire_formulaire() -> void:
	_texte("Ton compte garde ta partie en ligne et te permet d'ajouter des amis, de rejoindre une guilde et de combattre dans l'Arène.", UiCommun.C_DOUX)

	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	_vb.add_child(onglets)
	_onglet_connexion = _bouton("Se connecter", func(): _changer_mode(false))
	_onglet_creation = _bouton("Créer un compte", func(): _changer_mode(true))
	for b in [_onglet_connexion, _onglet_creation]:
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		onglets.add_child(b)

	_vb.add_child(UiCommun.label("Pseudo", 16, UiCommun.C_OR))
	_pseudo = LineEdit.new()
	_pseudo.max_length = 16
	_pseudo.placeholder_text = "3 à 16 caractères (lettres, chiffres, _ ou -)"
	_pseudo.custom_minimum_size = Vector2(0, 42)
	_pseudo.text_submitted.connect(func(_t): _mdp.grab_focus())
	_vb.add_child(_pseudo)

	_vb.add_child(UiCommun.label("Mot de passe", 16, UiCommun.C_OR))
	_mdp = LineEdit.new()
	_mdp.secret = true
	_mdp.placeholder_text = "Au moins 6 caractères"
	_mdp.custom_minimum_size = Vector2(0, 42)
	_mdp.text_submitted.connect(func(_t): _valider())
	_vb.add_child(_mdp)

	var l2 := UiCommun.label("Confirme le mot de passe", 16, UiCommun.C_OR)
	l2.name = "LabelConfirmation"
	_vb.add_child(l2)
	_mdp2 = LineEdit.new()
	_mdp2.secret = true
	_mdp2.custom_minimum_size = Vector2(0, 42)
	_mdp2.text_submitted.connect(func(_t): _valider())
	_vb.add_child(_mdp2)

	var avertissement := UiCommun.label("Note bien ton mot de passe : pour l'instant, il ne peut pas être récupéré.", 14, UiCommun.C_DOUX)
	avertissement.name = "Avertissement"
	_vb.add_child(avertissement)

	_etat = UiCommun.label("", 16, Color(1.0, 0.75, 0.5))
	_etat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_etat.custom_minimum_size = Vector2(500, 0)
	_vb.add_child(_etat)

	var valider := _bouton("Valider", _valider)
	valider.name = "Valider"
	valider.custom_minimum_size = Vector2(0, 48)
	_vb.add_child(valider)
	_boutons.append(valider)

	_ligne_boutons([["Jouer hors ligne" if au_demarrage else "Fermer", _hors_ligne if au_demarrage else _fermer]])
	_changer_mode(_mode_creation)
	_pseudo.grab_focus.call_deferred()


func _changer_mode(creation: bool) -> void:
	_mode_creation = creation
	_onglet_connexion.button_pressed = not creation
	_onglet_creation.button_pressed = creation
	_mdp2.visible = creation
	_vb.get_node("LabelConfirmation").visible = creation
	_vb.get_node("Avertissement").visible = creation
	(_vb.get_node("Valider") as Button).text = "Créer mon compte" if creation else "Se connecter"
	_etat.text = ""


func _valider() -> void:
	if _occupe:
		return
	if _mode_creation and _mdp.text != _mdp2.text:
		_etat.text = "Les deux mots de passe ne sont pas identiques."
		return
	_occuper(true, "Création du compte…" if _mode_creation else "Connexion…")
	var r: Dictionary
	if _mode_creation:
		r = await EnLigne.inscrire(_pseudo.text, _mdp.text)
	else:
		r = await EnLigne.connecter(_pseudo.text, _mdp.text)
	if not is_instance_valid(self):
		return
	_occuper(false, "")
	if r.ok:
		_fermer()
	else:
		_etat.text = r.erreur


# ---------- Connecté ----------

func _construire_connecte() -> void:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 14)
	_vb.add_child(ligne)
	var h := Sauvegarde.get_heros_depart()
	ligne.add_child(UiCommun.avatar(str(h.get("id", "")), EnLigne.pseudo(), 64))
	var infos := VBoxContainer.new()
	ligne.add_child(infos)
	infos.add_child(UiCommun.label(EnLigne.pseudo(), 26, UiCommun.C_LEGENDE))
	infos.add_child(UiCommun.label("Niveau de compte %d" % Sauvegarde.get_niveau_compte(), 16, UiCommun.C_DOUX))

	var synchro := "jamais"
	if EnLigne.derniere_synchro > 0:
		synchro = "il y a " + Calendrier.texte_duree(maxi(0, int(Time.get_unix_time_from_system()) - EnLigne.derniere_synchro))
	_texte("Sauvegarde en ligne : automatique.\nDernier envoi : %s%s" % [synchro,
		"" if EnLigne.reseau_ok else "\n⚠ Le serveur ne répond pas : ta partie sera envoyée dès le retour de la connexion."], UiCommun.C_TEXTE)

	_etat = UiCommun.label("", 16, Color(1.0, 0.75, 0.5))
	_vb.add_child(_etat)
	_ligne_boutons([["Envoyer ma partie maintenant", _synchroniser], ["Se déconnecter", _deconnecter], ["Fermer", _fermer]])


func _synchroniser() -> void:
	_occuper(true, "Envoi…")
	var ok: bool = await EnLigne.envoyer_sauvegarde(true)
	if not is_instance_valid(self):
		return
	_occuper(false, "Partie envoyée sur ton compte." if ok else "Envoi impossible pour l'instant.")


func _deconnecter() -> void:
	FenetreSimple.confirmer(self, "Se déconnecter",
		"Ta partie reste sur cet appareil et sur ton compte.\nTu pourras te reconnecter avec ton pseudo et ton mot de passe.",
		"Se déconnecter", func():
			_occuper(true, "Déconnexion…")
			await EnLigne.deconnecter()
			if is_instance_valid(self):
				_occuper(false, "")
				_construire())


# ---------- Outils ----------

func _sur_etat_change() -> void:
	if not _occupe:
		_construire()


func _occuper(oui: bool, texte: String) -> void:
	_occupe = oui
	for b in _boutons:
		if is_instance_valid(b):
			b.disabled = oui
	if _etat != null and is_instance_valid(_etat):
		_etat.text = texte


func _hors_ligne() -> void:
	EnLigne.hors_ligne_choisi = true
	_fermer()


func _fermer() -> void:
	if EnLigne.etat_change.is_connected(_sur_etat_change):
		EnLigne.etat_change.disconnect(_sur_etat_change)
	queue_free()
	if quand_fermee.is_valid():
		quand_fermee.call()


func _titre(texte: String) -> void:
	var t := UiCommun.label(texte, 30, Color(1.0, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(t)


func _texte(texte: String, couleur: Color) -> void:
	var l := UiCommun.label(texte, 17, couleur)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(500, 0)
	_vb.add_child(l)


func _bouton(texte: String, action: Callable) -> Button:
	var b := UiCommun.bouton(texte)
	b.pressed.connect(action)
	return b


func _ligne_boutons(liste: Array) -> void:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	_vb.add_child(ligne)
	for b in liste:
		var bouton := _bouton(b[0], b[1])
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(bouton)
		_boutons.append(bouton)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not au_demarrage:
		get_viewport().set_input_as_handled()
		_fermer()
