class_name FenetreStatsJeu
extends CanvasLayer
## STATISTIQUES DU JEU (menu Admin) : réservé au compte du créateur.
## Le bouton n'apparaît que si le serveur confirme l'accès (EnLigne.est_admin_stats()), et le
## serveur refuse de toute façon d'envoyer les données à un autre compte (supabase/07_statistiques.sql).
##
## Onglets : Vue d'ensemble · Joueurs · Appareils · Téléchargements (GitHub Releases).
##
##   FenetreStatsJeu.ouvrir(parent)

const C_ROUGE := Color("ff5a4a")
const C_BLEU := Color("5fb0ff")
const C_VERT := Color("8aff9a")
const URL_RELEASES := "https://api.github.com/repos/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases?per_page=100"

const NOMS_PLATEFORMES := {
	"windows": "Windows (application)", "macos": "Mac (application)", "android": "Android (application)",
	"web-pc": "Web — ordinateur", "web-android": "Web — téléphone Android", "web-iphone": "Web — iPhone / iPad",
	"linux": "Linux", "autre": "Autre",
}
const ONGLETS := [["ensemble", "Vue d'ensemble"], ["joueurs", "Joueurs"], ["appareils", "Appareils"], ["telechargements", "Téléchargements"]]
const TRIS := [["vu_le", "Dernière connexion"], ["cree_le", "Inscription"], ["niveau", "Niveau"],
	["chapitres", "Chapitres"], ["puissance", "Puissance"], ["pseudo", "Pseudo"]]

var _stats: Dictionary = {}
var _releases: Array = []
var _erreur_releases := ""
var _onglet := "ensemble"
var _tri := "vu_le"
var _recherche := ""

var _contenu: VBoxContainer
var _etat: Label
var _boutons_onglets := {}


static func ouvrir(parent: Node) -> void:
	parent.add_child(FenetreStatsJeu.new())


func _ready() -> void:
	layer = 75
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.78)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1600.0, vp.x - 30.0), minf(900.0, vp.y - 30.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_ROUGE, Color(0.05, 0.02, 0.02, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 10)
	vb.add_child(tete)
	var t := UiCommun.label("📊  STATISTIQUES DU JEU", 28, C_ROUGE)
	tete.add_child(t)
	_etat = UiCommun.label("", 14, UiCommun.C_DOUX)
	_etat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_etat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tete.add_child(_etat)
	var maj := UiCommun.bouton("↻ Actualiser", 15)
	maj.pressed.connect(_charger)
	tete.add_child(maj)
	var fermer := UiCommun.bouton("Fermer", 15)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)

	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 6)
	vb.add_child(onglets)
	for o in ONGLETS:
		var b := UiCommun.bouton(o[1], 16)
		b.custom_minimum_size = Vector2(0, 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			_onglet = o[0]
			_afficher())
		onglets.add_child(b)
		_boutons_onglets[o[0]] = b

	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vb.add_child(defil)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 10)
	defil.add_child(_contenu)
	_charger()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()


# =====================================================================
# Chargement
# =====================================================================

func _charger() -> void:
	_etat.text = "Chargement…"
	_vider()
	_contenu.add_child(UiCommun.label("Chargement des statistiques…", 18, UiCommun.C_DOUX))
	var r: Dictionary = await EnLigne.appeler("stats_jeu")
	if not is_instance_valid(self):
		return
	if not r.ok or not (r.data is Dictionary):
		_stats = {}
		_vider()
		var msg := str(r.get("erreur", ""))
		var l := UiCommun.label(UiCommun.t("Impossible de charger les statistiques.\n\n%s\n\nVérifie que tu es connecté avec ton compte et que le fichier supabase/07_statistiques.sql a bien été lancé dans Supabase (voir SUPABASE.md).") % msg, 17, C_ROUGE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_contenu.add_child(l)
		_etat.text = ""
		return
	_stats = r.data
	var h := Time.get_time_dict_from_system()
	_etat.text = UiCommun.t("à jour à %02d:%02d") % [h.hour, h.minute]
	_afficher()
	await _charger_releases()
	if is_instance_valid(self) and _onglet in ["ensemble", "telechargements"]:
		_afficher()


## Nombre de téléchargements des fichiers des Releases GitHub (Windows, Mac, Android).
func _charger_releases() -> void:
	var h := HTTPRequest.new()
	h.timeout = 20.0
	h.accept_gzip = not OS.has_feature("web")
	add_child(h)
	var entetes := PackedStringArray(["Accept: application/vnd.github+json"])
	if not OS.has_feature("web"):
		entetes.append("User-Agent: BrothersOfLegacy")     # demandé par GitHub (le navigateur le met tout seul)
	if h.request(URL_RELEASES, entetes) != OK:
		h.queue_free()
		_erreur_releases = "Requête impossible."
		return
	var res: Array = await h.request_completed
	h.queue_free()
	var data = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200 or not (data is Array):
		_erreur_releases = UiCommun.t("GitHub ne répond pas (code %s). Réessaie dans un moment.") % str(res[1])
		return
	_erreur_releases = ""
	_releases = data


# =====================================================================
# Affichage
# =====================================================================

func _vider() -> void:
	for c in _contenu.get_children():
		c.queue_free()


func _afficher() -> void:
	for k in _boutons_onglets:
		var actif: bool = k == _onglet
		var b: Button = _boutons_onglets[k]
		b.add_theme_stylebox_override("normal", UiCommun.style_carte(C_ROUGE if actif else Color(1, 1, 1, 0.15), 0.1 if actif else 0.0, 2))
		b.add_theme_color_override("font_color", UiCommun.C_LEGENDE if actif else UiCommun.C_DOUX)
	if _stats.is_empty():
		return
	_vider()
	match _onglet:
		"ensemble": _vue_ensemble()
		"joueurs": _vue_joueurs()
		"appareils": _vue_appareils()
		"telechargements": _vue_telechargements()


func _titre(t: String) -> void:
	_contenu.add_child(UiCommun.label(t, 19, UiCommun.C_OR))


func _note(t: String) -> void:
	var l := UiCommun.label(t, 13, UiCommun.C_DOUX)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(l)


## Rangée de tuiles « grand chiffre + légende ».
func _tuiles(liste: Array) -> void:
	var g := GridContainer.new()
	g.columns = mini(liste.size(), 6)
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	_contenu.add_child(g)
	for t in liste:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(230, 96)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", UiCommun.style_carte(t[2] if t.size() > 2 else UiCommun.C_OR, 0.04, 2))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(v)
		var n := UiCommun.label(str(t[0]), 34, t[2] if t.size() > 2 else UiCommun.C_LEGENDE)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var l := UiCommun.label(t[1], 14, UiCommun.C_TEXTE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		g.add_child(p)


func _vue_ensemble() -> void:
	var c: Dictionary = _stats.get("comptes", {})
	var a: Dictionary = _stats.get("appareils", {})
	var j: Dictionary = _stats.get("jeu", {})
	_titre("Joueurs")
	_tuiles([[int(c.get("total", 0)), "comptes créés"], [int(c.get("en_ligne", 0)), "en ligne maintenant", C_VERT],
		[int(c.get("actifs_jour", 0)), "joueurs actifs (24 h)"], [int(c.get("actifs_semaine", 0)), "joueurs actifs (7 jours)"],
		[int(c.get("actifs_mois", 0)), "joueurs actifs (30 jours)"],
		["+%d" % int(c.get("semaine", 0)), UiCommun.t("nouveaux comptes (7 jours)\n+%d aujourd'hui · +%d en 30 j") % [int(c.get("jour", 0)), int(c.get("mois", 0))]]])
	_titre("Appareils et téléchargements")
	var dl := _totaux_telechargements()
	_tuiles([[int(a.get("total", 0)), "appareils qui ont lancé le jeu", C_BLEU], [int(a.get("actifs_jour", 0)), "appareils actifs (24 h)", C_BLEU],
		[int(a.get("actifs_mois", 0)), "appareils actifs (30 jours)", C_BLEU], [int(a.get("sans_compte", 0)), "appareils sans compte", C_BLEU],
		[_n(int(a.get("lancements", 0))), "lancements du jeu", C_BLEU],
		[("…" if _releases.is_empty() and _erreur_releases == "" else str(dl["total"])), "téléchargements\n(Windows, Mac, Android)", C_BLEU]])
	_titre("Activité des 30 derniers jours")
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 18)
	_contenu.add_child(leg)
	leg.add_child(UiCommun.label("■ appareils actifs", 14, C_BLEU))
	leg.add_child(UiCommun.label("■ comptes actifs", 14, UiCommun.C_OR))
	leg.add_child(UiCommun.label("● nouveaux comptes", 14, C_VERT))
	var graph := Graphique.new()
	graph.jours = _stats.get("jours", []) if _stats.get("jours") is Array else []
	graph.custom_minimum_size = Vector2(0, 260)
	_contenu.add_child(graph)
	_note("Les appareils et comptes actifs sont comptés à partir de cette version (v0.53) : la courbe se remplit jour après jour.")
	_titre("Le jeu en ligne")
	_tuiles([[int(j.get("guildes", 0)), UiCommun.t("guildes\n%d membres") % int(j.get("membres_guilde", 0))],
		[int(j.get("arene_combats", 0)), UiCommun.t("combats d'Arène\n%d cette semaine · %d joueurs") % [int(j.get("arene_combats_semaine", 0)), int(j.get("arene_joueurs", 0))]],
		[int(j.get("classee_matchs", 0)), UiCommun.t("matchs d'Arène classée\n%d joueurs") % int(j.get("classee_joueurs", 0))],
		[int(j.get("marche_jour", 0)), UiCommun.t("Marches Maudites aujourd'hui\n%d au total") % int(j.get("marche_total", 0))],
		[int(j.get("sauvegardes", 0)), "parties sauvegardées en ligne"]])


func _vue_joueurs() -> void:
	var joueurs: Array = (_stats.get("joueurs", []) as Array).duplicate()
	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 10)
	_contenu.add_child(barre)
	var champ := LineEdit.new()
	champ.placeholder_text = "Chercher un pseudo…"
	champ.text = _recherche
	champ.custom_minimum_size = Vector2(300, 40)
	champ.text_changed.connect(func(t: String):
		_recherche = t
		_remplir_tableau(joueurs))
	barre.add_child(champ)
	var tri := OptionButton.new()
	for i in TRIS.size():
		tri.add_item("Tri : " + TRIS[i][1])
		if TRIS[i][0] == _tri:
			tri.select(i)
	tri.item_selected.connect(func(i: int):
		_tri = TRIS[i][0]
		_remplir_tableau(joueurs))
	barre.add_child(tri)
	var nb := UiCommun.label(UiCommun.t("%d comptes") % joueurs.size(), 16, UiCommun.C_OR)
	nb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barre.add_child(nb)
	var tableau := GridContainer.new()
	tableau.name = "Tableau"
	tableau.columns = 10
	tableau.add_theme_constant_override("h_separation", 22)
	tableau.add_theme_constant_override("v_separation", 6)
	_contenu.add_child(tableau)
	_remplir_tableau(joueurs)
	_note("Seuls les pseudos sont affichés (aucune adresse e-mail). « Chapitres », « Puissance » et « Unités » viennent de la fiche publique du joueur, mise à jour quand il joue connecté.")


func _remplir_tableau(joueurs: Array) -> void:
	var tableau: GridContainer = _contenu.get_node_or_null("Tableau")
	if tableau == null:
		return
	for x in tableau.get_children():
		x.queue_free()
	var liste := joueurs.filter(func(j): return _recherche == "" or str(j.get("pseudo", "")).to_lower().contains(_recherche.to_lower()))
	liste.sort_custom(func(x, y):
		if _tri == "pseudo":
			return str(x["pseudo"]).to_lower() < str(y["pseudo"]).to_lower()
		if _tri in ["vu_le", "cree_le"]:
			return str(x.get(_tri, "")) > str(y.get(_tri, ""))
		return int(x.get(_tri, 0)) > int(y.get(_tri, 0)))
	for e in ["Pseudo", "Statut", "Inscrit le", "Niveau", "Chapitres", "Puissance", "Unités", "Guilde", "Version", "Joue sur"]:
		tableau.add_child(UiCommun.label(e, 16, UiCommun.C_OR))
	for j in liste:
		var vu := str(j.get("vu_le", ""))
		var en_ligne := EnLigne.est_en_ligne(vu)
		var plats: Array = (j.get("plateformes", []) as Array).map(func(p): return _plateforme_courte(str(p)))
		tableau.add_child(UiCommun.label(str(j.get("pseudo", "?")), 17, UiCommun.C_LEGENDE))
		tableau.add_child(UiCommun.label(EnLigne.texte_presence(vu), 16, C_VERT if en_ligne else UiCommun.C_DOUX))
		tableau.add_child(UiCommun.label(_date(str(j.get("cree_le", ""))), 16))
		tableau.add_child(UiCommun.label(str(int(j.get("niveau", 1))), 16))
		tableau.add_child(UiCommun.label(str(int(j.get("chapitres", 0))), 16))
		tableau.add_child(UiCommun.label(_n(int(j.get("puissance", 0))), 16))
		tableau.add_child(UiCommun.label(str(int(j.get("unites", 0))), 16))
		tableau.add_child(UiCommun.label(str(j.get("guilde", "")) if str(j.get("guilde", "")) != "" else "—", 16))
		var v := str(j.get("version", ""))
		tableau.add_child(UiCommun.label(v if v != "" else "—", 16, UiCommun.C_TEXTE if v == Version.NUMERO else Color("ffb070")))
		tableau.add_child(UiCommun.label(", ".join(plats) if not plats.is_empty() else "—", 16, UiCommun.C_DOUX))


func _vue_appareils() -> void:
	var a: Dictionary = _stats.get("appareils", {})
	_titre("Par plateforme")
	_note("Chaque appareil qui lance le jeu est compté une fois, avec ou sans compte (identifiant anonyme tiré au hasard). « Actifs » = lancé dans les 30 derniers jours.")
	var tous: Dictionary = a.get("par_plateforme", {})
	var actifs: Dictionary = a.get("par_plateforme_actifs", {})
	var maxi_ := 1
	for k in tous:
		maxi_ = maxi(maxi_, int(tous[k]))
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 20)
	g.add_theme_constant_override("v_separation", 8)
	_contenu.add_child(g)
	for e in ["Plateforme", "Appareils", "Actifs (30 j)", ""]:
		g.add_child(UiCommun.label(e, 14, UiCommun.C_OR))
	var cles: Array = tous.keys()
	cles.sort_custom(func(x, y): return int(tous[x]) > int(tous[y]))
	for k in cles:
		g.add_child(UiCommun.label(NOMS_PLATEFORMES.get(k, str(k)), 16))
		g.add_child(UiCommun.label(str(int(tous[k])), 16, C_BLEU))
		g.add_child(UiCommun.label(str(int(actifs.get(k, 0))), 16, C_VERT))
		var b := UiCommun.barre(C_BLEU, 420.0 * int(tous[k]) / maxi_ + 4.0, 14)
		b.max_value = 1
		b.value = 1
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		g.add_child(b)
	if cles.is_empty():
		_note("Aucun appareil enregistré pour l'instant : le compteur démarre avec cette version.")
	_titre("Versions utilisées (appareils actifs sur 30 jours)")
	var gv := GridContainer.new()
	gv.columns = 2
	gv.add_theme_constant_override("h_separation", 30)
	_contenu.add_child(gv)
	for v in a.get("par_version", []):
		var num := str(v.get("version", ""))
		gv.add_child(UiCommun.label("v" + num + ("  (actuelle)" if num == Version.NUMERO else ""), 16, UiCommun.C_TEXTE if num == Version.NUMERO else Color("ffb070")))
		gv.add_child(UiCommun.label(UiCommun.t("%d appareil%s") % [int(v.get("n", 0)), "s" if int(v.get("n", 0)) > 1 else ""], 16))
	_note("En orange : les appareils qui n'ont pas encore la dernière version.")


func _vue_telechargements() -> void:
	_titre("Téléchargements des applications (GitHub Releases)")
	if _releases.is_empty():
		_note(_erreur_releases if _erreur_releases != "" else "Chargement…")
		return
	var d := _totaux_telechargements()
	_tuiles([[d["total"], "téléchargements au total", C_BLEU], [d["windows"], "Windows"], [d["mac"], "Mac"], [d["android"], "Android"]])
	_note("Le jeu web (ordinateur, Android, iPhone) ne se télécharge pas : ses joueurs sont comptés dans l'onglet Appareils.")
	_titre("Détail par version")
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 26)
	g.add_theme_constant_override("v_separation", 4)
	_contenu.add_child(g)
	for e in ["Version", "Publiée le", "Windows", "Mac", "Android"]:
		g.add_child(UiCommun.label(e, 14, UiCommun.C_OR))
	for r in _releases:
		var par := {"windows": 0, "mac": 0, "android": 0}
		for asset in r.get("assets", []):
			var k := _type_fichier(str(asset.get("name", "")))
			if k != "":
				par[k] += int(asset.get("download_count", 0))
		g.add_child(UiCommun.label(str(r.get("tag_name", "?")), 15, UiCommun.C_LEGENDE))
		g.add_child(UiCommun.label(_date(str(r.get("published_at", ""))), 14))
		for k in ["windows", "mac", "android"]:
			g.add_child(UiCommun.label(str(par[k]), 15))


func _totaux_telechargements() -> Dictionary:
	var d := {"total": 0, "windows": 0, "mac": 0, "android": 0}
	for r in _releases:
		for asset in r.get("assets", []):
			var k := _type_fichier(str(asset.get("name", "")))
			if k != "":
				d[k] += int(asset.get("download_count", 0))
				d["total"] += int(asset.get("download_count", 0))
	return d


func _type_fichier(nom: String) -> String:
	var n := nom.to_lower()
	if n.ends_with(".apk"):
		return "android"
	if n.contains("windows"):
		return "windows"
	if n.contains("mac"):
		return "mac"
	return ""


# =====================================================================
# Outils
# =====================================================================

func _plateforme_courte(p: String) -> String:
	return {"windows": "Windows", "macos": "Mac", "android": "Android", "web-pc": "Web PC",
		"web-android": "Web Android", "web-iphone": "iPhone", "linux": "Linux"}.get(p, p)


## « 2026-10-08T17:03:00+00:00 » -> « 08/10/2026 » (heure locale).
func _date(iso: String) -> String:
	if iso.length() < 19:
		return "—"
	var t := int(Time.get_unix_time_from_datetime_string(iso.left(19))) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "%02d/%02d/%d" % [d.day, d.month, d.year]


func _n(x: int) -> String:
	var s := str(absi(x))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return ("-" if x < 0 else "") + s + r


## Petit graphique en barres : appareils et comptes actifs par jour, nouveaux comptes en points.
class Graphique extends Control:
	var jours: Array = []

	func _draw() -> void:
		const HAUT := 22.0          # place pour les étiquettes au-dessus des barres
		const GAUCHE := 34.0        # place pour l'échelle
		var w := size.x - GAUCHE
		var h := size.y - 24.0 - HAUT
		draw_set_transform(Vector2(GAUCHE, HAUT))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.03))
		if jours.is_empty():
			return
		var maxi_ := 1
		for j in jours:
			maxi_ = maxi(maxi_, maxi(int(j.get("appareils", 0)), int(j.get("comptes", 0))))
		var police := ThemeDB.fallback_font
		for k in 4:
			var y := h - h * k / 3.0
			draw_line(Vector2(0, y), Vector2(w, y), Color(1, 1, 1, 0.08))
			draw_string(police, Vector2(-GAUCHE + 2, y + 4), str(int(round(maxi_ * k / 3.0))), HORIZONTAL_ALIGNMENT_RIGHT, GAUCHE - 8, 12, Color(1, 1, 1, 0.45))
		var pas := w / jours.size()
		var larg := maxf(pas * 0.36, 2.0)
		for i in jours.size():
			var j: Dictionary = jours[i]
			var x := i * pas + pas * 0.12
			var ha := h * int(j.get("appareils", 0)) / maxi_
			var hc := h * int(j.get("comptes", 0)) / maxi_
			draw_rect(Rect2(x, h - ha, larg, ha), FenetreStatsJeu.C_BLEU)
			draw_rect(Rect2(x + larg, h - hc, larg, hc), UiCommun.C_OR)
			var nouveaux := int(j.get("nouveaux_comptes", 0))
			if nouveaux > 0:
				draw_circle(Vector2(x + larg, h - maxf(ha, hc) - 10), 5, FenetreStatsJeu.C_VERT)
				draw_string(police, Vector2(x + larg + 7, h - maxf(ha, hc) - 5), "+%d" % nouveaux, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, FenetreStatsJeu.C_VERT)
			if i % 5 == 0 or i == jours.size() - 1:
				var d := str(j.get("jour", ""))
				draw_string(police, Vector2(x, h + 18), d.substr(8, 2) + "/" + d.substr(5, 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.55))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
