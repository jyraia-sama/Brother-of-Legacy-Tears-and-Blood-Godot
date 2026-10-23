class_name FenetreSignalement
extends CanvasLayer
## SIGNALER UN BUG / DONNER SON AVIS (bouton du Menu) : le joueur écrit un message au créateur.
## Le jeu y joint tout seul la version, l'appareil, l'écran où il se trouve et sa progression.
## Le message part sur le serveur (supabase/12_signalements.sql) ; seul le compte du créateur
## peut le lire (Menu > Espace créateur). Sans connexion, il attend et part au prochain lancement.
##
##   FenetreSignalement.ouvrir(parent)

const FICHIER_ATTENTE := "user://signalements_en_attente.json"
const CATEGORIES := [["bug", "🐞  Un bug"], ["difficulte", "⚔  La difficulté"], ["idee", "💡  Une idée"], ["autre", "✉  Autre chose"]]
const AIDES := {
	"bug": "Dis ce que tu faisais, ce qui s'est passé, et ce que tu attendais.\nExemple : « Dans l'Acte IV, en touchant Retour dans les Donjons, je suis revenu à un vieux menu. »",
	"difficulte": "Où exactement (Acte, chapitre, mode) ? C'était trop facile ou trop dur ? Combien d'essais ?",
	"idee": "Qu'est-ce que tu aimerais voir dans le jeu ? Un mode, un héros, une amélioration…",
	"autre": "Ce que tu aimes, ce qui te gêne, un menu où tu t'es perdu… Tout est bon à prendre !",
}

var _categorie := "bug"
var _boutons := {}
var _aide: Label
var _texte: TextEdit
var _etat: Label
var _envoyer: Button


static func ouvrir(parent: Node) -> void:
	parent.add_child(FenetreSignalement.new())


func _ready() -> void:
	layer = 60
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var st := UiCommun.style_panneau()
	st.set_content_margin_all(22)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(720, 0)
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)

	var t := UiCommun.label("Écrire au créateur du jeu", 26, Color(1.0, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var intro := UiCommun.label("Un bug, un passage trop dur, une idée ? Ton message arrive directement chez moi. Merci de m'aider à améliorer le jeu !", 15, UiCommun.C_DOUX)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(intro)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(ligne)
	for c in CATEGORIES:
		var b := UiCommun.bouton(c[1], 15)
		b.custom_minimum_size = Vector2(160, 42)
		b.pressed.connect(_choisir.bind(c[0]))
		ligne.add_child(b)
		_boutons[c[0]] = b

	_aide = UiCommun.label("", 14, UiCommun.C_DOUX)
	_aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_aide)
	_texte = TextEdit.new()
	_texte.custom_minimum_size = Vector2(0, 190)
	_texte.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_texte.placeholder_text = "Écris ton message ici…"
	_texte.add_theme_font_size_override("font_size", 16)
	_texte.text_changed.connect(_maj_compteur)
	vb.add_child(_texte)
	var joint := UiCommun.label(UiCommun.t("Joint automatiquement : version %s · %s · écran actuel · ta progression%s.") % [
		Version.NUMERO, EnLigne.plateforme(), " · ton pseudo" if EnLigne.est_connecte() else ""], 12, UiCommun.C_DOUX)
	joint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(joint)
	_etat = UiCommun.label("", 15, Color("8aff9a"))
	_etat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_etat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_etat)

	var bas := HBoxContainer.new()
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	bas.add_theme_constant_override("separation", 14)
	vb.add_child(bas)
	var annuler := UiCommun.bouton("Fermer", 17)
	annuler.custom_minimum_size = Vector2(170, 44)
	annuler.pressed.connect(queue_free)
	bas.add_child(annuler)
	_envoyer = UiCommun.bouton("Envoyer", 17)
	_envoyer.custom_minimum_size = Vector2(170, 44)
	UiCommun.bouton_vif(_envoyer)
	_envoyer.pressed.connect(_envoyer_message)
	bas.add_child(_envoyer)
	_choisir("bug")
	_texte.grab_focus.call_deferred()


func _choisir(c: String) -> void:
	_categorie = c
	_aide.text = AIDES[c]
	for k in _boutons:
		(_boutons[k] as Button).add_theme_color_override("font_color", Color("ffd27a") if k == c else UiCommun.C_DOUX)
	_maj_compteur()


func _maj_compteur() -> void:
	_envoyer.disabled = _texte.text.strip_edges().length() < 3
	if _texte.text.length() > 2000:
		_texte.text = _texte.text.left(2000)
		_texte.set_caret_column(_texte.get_line(_texte.get_line_count() - 1).length())


## Où en est le joueur : écran, Acte et chapitre, niveau de compte, langue, taille d'écran.
static func contexte() -> Dictionary:
	var arbre := Engine.get_main_loop() as SceneTree
	var ecran := ""
	if arbre and arbre.current_scene:
		ecran = arbre.current_scene.scene_file_path.get_file().get_basename()
	var avancee := 0
	for a in range(1, 14):
		for c in range(1, 7):
			if ActesData.est_termine(a, c):
				avancee = a
	var taille := DisplayServer.window_get_size() if not OS.has_feature("web") else Vector2i.ZERO
	var details := UiCommun.t("Plus loin : Acte %d · niveau de compte %d · langue %s · écran %dx%d") % [
		avancee, Sauvegarde.get_niveau_compte(), Ecran.langue(), taille.x, taille.y]
	return {"ecran": ecran, "details": details}


func _envoyer_message() -> void:
	var c := contexte()
	var params := {"p_appareil": EnLigne.id_appareil(), "p_categorie": _categorie, "p_message": _texte.text.strip_edges(),
		"p_version": Version.NUMERO, "p_plateforme": EnLigne.plateforme(), "p_ecran": c["ecran"], "p_details": c["details"]}
	_envoyer.disabled = true
	_etat.add_theme_color_override("font_color", UiCommun.C_DOUX)
	_etat.text = "Envoi…"
	var r := await FenetreSignalement.envoyer(params)
	if not is_instance_valid(self):
		return
	if r.get("ok", false):
		_etat.add_theme_color_override("font_color", Color("8aff9a"))
		_etat.text = "Merci ! Ton message est bien arrivé."
		_texte.text = ""
		get_tree().create_timer(1.6).timeout.connect(func():
			if is_instance_valid(self):
				queue_free())
	elif r.get("attente", false):
		_etat.add_theme_color_override("font_color", Color("ffd27a"))
		_etat.text = "Pas de connexion pour l'instant : ton message est gardé et partira tout seul au prochain lancement du jeu."
		_texte.text = ""
	else:
		_etat.add_theme_color_override("font_color", Color("ff7a6a"))
		_etat.text = str(r.get("erreur", "Le message n'a pas pu partir."))
		_envoyer.disabled = false


## Envoie un signalement. Sans réseau, il est mis de côté (renvoyé par envoyer_en_attente()).
## Renvoie {ok} ou {ok: false, attente: true} ou {ok: false, erreur}.
static func envoyer(params: Dictionary) -> Dictionary:
	if not EnLigne.configure():
		_mettre_de_cote(params)
		return {"ok": false, "attente": true}
	var r: Dictionary
	if EnLigne.est_connecte():
		r = await EnLigne.appeler("envoyer_signalement", params)
	else:
		r = await EnLigne._http(HTTPClient.METHOD_POST, "/rest/v1/rpc/envoyer_signalement", params, false)
	if r.get("ok", false) and r.get("data") is Dictionary:
		return r["data"]
	if int(r.get("code", 0)) == 0:
		_mettre_de_cote(params)
		return {"ok": false, "attente": true}
	return {"ok": false, "erreur": "Le serveur n'a pas accepté le message. Réessaie plus tard."}


static func _mettre_de_cote(params: Dictionary) -> void:
	var l := _attente()
	if l.size() >= 20:
		return
	l.append(params)
	var f := FileAccess.open(FICHIER_ATTENTE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(l))


static func _attente() -> Array:
	if not FileAccess.file_exists(FICHIER_ATTENTE):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(FICHIER_ATTENTE))
	return d if d is Array else []


## Au lancement : renvoie les messages restés en attente (silencieux).
static func envoyer_en_attente() -> void:
	var l := _attente()
	if l.is_empty() or not EnLigne.configure():
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(FICHIER_ATTENTE))
	for p in l:
		if p is Dictionary:
			var r := await envoyer(p)
			if r.get("attente", false):
				return       # toujours pas de réseau : les suivants restent aussi de côté
