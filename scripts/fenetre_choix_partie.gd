class_name FenetreChoixPartie
extends CanvasLayer
## À la connexion : la partie du compte et celle de cet appareil sont différentes.
## Le joueur choisit laquelle garder (l'autre est remplacée).
## Ouverte par EnLigne ; le résultat arrive par le signal « choisi ».

signal choisi(garder_compte: bool)

var _cloud: Dictionary
var _maj := ""
var _locale: Dictionary


static func creer(cloud: Dictionary, maj: String, locale: Dictionary) -> FenetreChoixPartie:
	var f := FenetreChoixPartie.new()
	f._cloud = cloud
	f._maj = maj
	f._locale = locale
	return f


func _ready() -> void:
	layer = 70
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.8)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := UiCommun.style_panneau()
	style.set_content_margin_all(24)
	panneau.add_theme_stylebox_override("panel", style)
	centre.add_child(panneau)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panneau.add_child(vb)

	var t := UiCommun.label("QUELLE PARTIE GARDER ?", 28, Color(1.0, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var info := UiCommun.label("Ton compte contient une partie différente de celle de cet appareil.\nCelle que tu ne gardes pas sera remplacée.", 17, UiCommun.C_DOUX)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info)

	var colonnes := HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", 20)
	vb.add_child(colonnes)
	var date_cloud := _date(EnLigne.date_vers_unix(_maj))
	var date_locale := _date(int(_locale.get("sauvegarde_le", 0)))
	colonnes.add_child(_colonne("PARTIE DU COMPTE", "Dernière sauvegarde : " + date_cloud, _cloud, "Garder la partie du compte", true))
	colonnes.add_child(_colonne("PARTIE DE CET APPAREIL", "Dernière sauvegarde : " + date_locale, _locale, "Garder celle de cet appareil", false))

	var astuce := UiCommun.label("Astuce : avant de choisir, tu peux copier le code de sauvegarde de cet appareil dans les Paramètres.", 14, UiCommun.C_DOUX)
	astuce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(astuce)


func _colonne(titre: String, date: String, d: Dictionary, texte_bouton: String, compte: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_carte(UiCommun.C_OR))
	p.custom_minimum_size = Vector2(340, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var marge := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 14)
	vb.add_child(marge)
	var interieur := VBoxContainer.new()
	interieur.add_theme_constant_override("separation", 10)
	marge.add_child(interieur)
	interieur.add_child(UiCommun.label(titre, 20, UiCommun.C_OR))
	interieur.add_child(UiCommun.label(Sauvegarde.resume_partie(d), 17))
	interieur.add_child(UiCommun.label(date, 14, UiCommun.C_DOUX))
	var b := UiCommun.bouton(texte_bouton)
	b.pressed.connect(_choisir.bind(compte))
	interieur.add_child(b)
	return p


func _choisir(compte: bool) -> void:
	choisi.emit(compte)
	queue_free()


func _date(unix: int) -> String:
	if unix <= 0:
		return "inconnue"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return Time.get_datetime_string_from_unix_time(unix + bias, true)
