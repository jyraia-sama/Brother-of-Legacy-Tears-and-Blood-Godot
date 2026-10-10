class_name FenetreChat
extends CanvasLayer
## CHAT GLOBAL : discussion ouverte à tous les joueurs connectés (bouton « Chat » du menu principal).
## Serveur : supabase/09_chat_global.sql (fonctions chat_global_envoyer / _lire / _dernier / _supprimer).
## Les messages se rafraîchissent toutes les 4 secondes tant que la fenêtre est ouverte.
## Les modérateurs (compte « jyraia », table stats_admins) voient une croix pour supprimer un message.
##
##   FenetreChat.ouvrir(self, func(): ...)   -> la fonction est appelée à la fermeture (facultatif)

const RAFRAICHISSEMENT := 4.0
const LONGUEUR_MAX := 200

var _a_la_fermeture: Callable
var _liste: VBoxContainer
var _defile: ScrollContainer
var _champ: LineEdit
var _etat: Label
var _dernier := 0
var _moderateur := false
var _minuterie: Timer


static func ouvrir(parent: Node, a_la_fermeture := Callable()) -> FenetreChat:
	var f := FenetreChat.new()
	f._a_la_fermeture = a_la_fermeture
	parent.add_child(f)
	return f


## Numéro du dernier message lu (sert à la pastille du menu principal).
static func dernier_lu() -> int:
	Sauvegarde.charger()
	return int(Sauvegarde.donnees.get("chat_global_lu", 0))


static func noter_lu(id: int) -> void:
	if id > dernier_lu():
		Sauvegarde.donnees["chat_global_lu"] = id
		Sauvegarde.sauvegarder()


## Y a-t-il des messages non lus ? (false si hors ligne ou serveur sans le fichier 09)
static func a_lire() -> bool:
	if not EnLigne.est_connecte():
		return false
	var r: Dictionary = await EnLigne.appeler("chat_global_dernier")
	return r.ok and int(r.data if r.data != null else 0) > dernier_lu()


func _ready() -> void:
	layer = 55
	var voile := Button.new()
	voile.flat = true
	voile.focus_mode = Control.FOCUS_NONE
	var sv := StyleBoxFlat.new()
	sv.bg_color = Color(0, 0, 0, 0.65)
	for k in ["normal", "hover", "pressed"]:
		voile.add_theme_stylebox_override(k, sv)
	voile.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.pressed.connect(_fermer)
	add_child(voile)

	var panneau := PanelContainer.new()
	panneau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in [["offset_left", 160.0], ["offset_right", -160.0], ["offset_top", 40.0], ["offset_bottom", -40.0]]:
		panneau.set(c[0], c[1])
	panneau.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := UiCommun.style_panneau(UiCommun.C_OR, Color("120b0c"))
	style.set_content_margin_all(18)
	panneau.add_theme_stylebox_override("panel", style)
	add_child(panneau)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panneau.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("CHAT GLOBAL", 26, Color(1.0, 0.85, 0.55))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var x := UiCommun.bouton("✕", 18)
	x.custom_minimum_size = Vector2(44, 40)
	x.pressed.connect(_fermer)
	tete.add_child(x)

	_defile = ScrollContainer.new()
	_defile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_defile)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste.add_theme_constant_override("separation", 4)
	_defile.add_child(_liste)

	_etat = UiCommun.label("", 14, UiCommun.C_DOUX)
	vb.add_child(_etat)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	vb.add_child(ligne)
	_champ = LineEdit.new()
	_champ.max_length = LONGUEUR_MAX
	_champ.placeholder_text = "Ton message à tous les joueurs (Entrée pour envoyer)"
	_champ.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_champ.custom_minimum_size = Vector2(0, 44)
	_champ.text_submitted.connect(func(_t): _envoyer())
	ligne.add_child(_champ)
	var envoyer := UiCommun.bouton("Envoyer", 16)
	envoyer.pressed.connect(_envoyer)
	ligne.add_child(envoyer)

	if not EnLigne.est_connecte():
		_champ.editable = false
		envoyer.disabled = true
		_liste.add_child(_texte_info("Connecte-toi à ton compte (en haut à gauche du menu principal) pour lire et écrire dans le chat global."))
		return

	_moderateur = await EnLigne.est_admin_stats()
	if not is_inside_tree():
		return
	_lire()
	_minuterie = Timer.new()
	_minuterie.wait_time = RAFRAICHISSEMENT
	_minuterie.autostart = true
	_minuterie.timeout.connect(_lire)
	add_child(_minuterie)


func _texte_info(s: String) -> Label:
	var l := UiCommun.label(s, 15, UiCommun.C_DOUX)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _envoyer() -> void:
	var t := _champ.text.strip_edges()
	if t == "" or not EnLigne.est_connecte():
		return
	_champ.text = ""
	var r: Dictionary = await EnLigne.appeler("chat_global_envoyer", {"p_texte": t})
	if not is_inside_tree():
		return
	var code := str(r.data) if r.ok else ""
	match code:
		"ok":
			_etat.text = ""
		"trop_vite":
			_etat.text = "Doucement ! Attends quelques secondes entre deux messages."
			_champ.text = t
		"":
			_etat.text = UiCommun.t("Message non envoyé : %s") % str(r.get("erreur", "serveur injoignable"))
			_champ.text = t
		_:
			_etat.text = UiCommun.t("Message non envoyé (%s).") % code
	_lire()


func _lire() -> void:
	if not is_instance_valid(_liste):
		return
	var r: Dictionary = await EnLigne.appeler("chat_global_lire", {"p_depuis": _dernier})
	if not is_instance_valid(_liste):
		return
	if not r.ok or not r.data is Array:
		if _dernier == 0 and _liste.get_child_count() == 0:
			_liste.add_child(_texte_info("Le chat global n'est pas encore installé sur le serveur (fichier supabase/09_chat_global.sql)."))
		return
	if _dernier == 0 and (r.data as Array).is_empty() and _liste.get_child_count() == 0:
		_liste.add_child(_texte_info("Aucun message pour l'instant. Lance la conversation !"))
	for m in r.data:
		_dernier = maxi(_dernier, int(m.id))
		_liste.add_child(_ligne(m))
	if not (r.data as Array).is_empty():
		FenetreChat.noter_lu(_dernier)
		await get_tree().process_frame
		if is_instance_valid(_defile):
			_defile.scroll_vertical = int(_defile.get_v_scroll_bar().max_value)


func _ligne(m: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
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
	var couleur := "#ffd27a" if moi else ("#ff7a6a" if m.get("admin", false) else "#9fc4e8")
	var couronne := "♛ " if m.get("admin", false) else ""
	l.text = "[color=#8e7f72]%s[/color]  [b][color=%s]%s%s[/color][/b] : %s" % [
		_date_courte(str(m.cree_le)), couleur, couronne, nom, texte]
	h.add_child(l)
	if _moderateur:
		var sup := UiCommun.bouton("✕", 12)
		sup.custom_minimum_size = Vector2(30, 26)
		sup.tooltip_text = "Supprimer ce message (modération)"
		var id := int(m.id)
		sup.pressed.connect(func():
			var r: Dictionary = await EnLigne.appeler("chat_global_supprimer", {"p_id": id})
			if r.ok and str(r.data) == "ok" and is_instance_valid(h):
				h.queue_free())
		h.add_child(sup)
	return h


func _date_courte(t: String) -> String:
	var u := EnLigne.date_vers_unix(t)
	if u <= 0:
		return ""
	var d := Time.get_datetime_dict_from_unix_time(u + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d/%02d %02d:%02d" % [d.day, d.month, d.hour, d.minute]


func _fermer() -> void:
	queue_free()
	if _a_la_fermeture.is_valid():
		_a_la_fermeture.call()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_fermer()
