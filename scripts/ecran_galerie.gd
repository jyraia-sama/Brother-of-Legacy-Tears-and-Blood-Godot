class_name EcranGalerie
extends Control
## GALERIE D'ART : toutes les illustrations du jeu, rangées par onglets.
##  - Créatures : portraits de toutes les unités (touche = fiche : portrait, figurine, rareté,
##    élément, rôle, où la trouver, compétences). Les unités pas encore rencontrées restent cachées.
##  - Figurines, Familiers, Boss de Monde, Histoire (Actes + personnages), Décors, Plateau.
## Une image touchée s'ouvre en grand ; les flèches (ou ← →) passent à la suivante, Échap ferme.
## Les dossiers sont lus avec ResourceLoader.list_directory : ça marche aussi dans le jeu exporté.

const SCENE := "res://scenes/galerie.tscn"
const FOND := "res://assets/fonds/succes.png"
## true = tout est visible, même ce qui n'a pas encore été découvert (pour les tests).
const TOUT_REVELER := false

static var scene_retour := ""

const ONGLETS := [
	["creatures", "Créatures"], ["figurines", "Figurines"], ["familiers", "Familiers"],
	["boss_monde", "Boss de Monde"], ["histoire", "Histoire"], ["decors", "Décors"], ["plateau", "Plateau"],
]
const CATEGORIES := {"heros": "Héros", "ennemi": "Ennemi", "boss": "Boss", "boss_monde": "Boss de Monde"}
## Personnages de l'histoire cachés jusqu'à l'ouverture de leur Acte (pour ne rien dévoiler).
const SPOILERS := {"frere_masque": 11, "kael_sombre": 11, "kael_valcendre": 10, "empereur_dechu": 9,
	"heritier_maudit": 12, "othmar": 13, "morvael": 13, "commandant": 8, "ermite": 6, "moine": 4,
	"compagnon": 3, "resistante": 10, "veuve": 2, "seigneur_des_cendres": 1}
const ORDRE_RARETE := {"UR": 0, "SSR": 1, "SR": 2, "R": 3, "N": 4}

var _onglet := "creatures"
var _boutons_onglets := {}
var _grille: HFlowContainer
var _compteur: Label
var _elements: Array = []      # [{type, id, titre, chemin, ouvert}]
var _fenetre: Control = null
var _index_ouvert := -1


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	UiCommun.fond_image(self, FOND, UiCommun.TEINTE_FOND)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("GALERIE D'ART", 32, UiCommun.C_OR))
	_compteur = UiCommun.label("", 16, UiCommun.C_DOUX)
	_compteur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compteur.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_compteur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tete.add_child(_compteur)

	var onglets := HFlowContainer.new()
	onglets.add_theme_constant_override("h_separation", 8)
	onglets.add_theme_constant_override("v_separation", 6)
	col.add_child(onglets)
	for o in ONGLETS:
		var b := UiCommun.bouton(o[1], 16)
		b.toggle_mode = true
		b.pressed.connect(_choisir_onglet.bind(o[0]))
		onglets.add_child(b)
		_boutons_onglets[o[0]] = b

	var panneau := PanelContainer.new()
	panneau.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panneau.add_theme_stylebox_override("panel", UiCommun.style_panneau(UiCommun.C_OR.darkened(0.4)))
	col.add_child(panneau)
	var defile := ScrollContainer.new()
	defile.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panneau.add_child(defile)
	_grille = HFlowContainer.new()
	_grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grille.add_theme_constant_override("h_separation", 10)
	_grille.add_theme_constant_override("v_separation", 10)
	defile.add_child(_grille)

	_choisir_onglet(_onglet)


# =====================================================================
# Contenu des onglets
# =====================================================================

func _choisir_onglet(o: String) -> void:
	_onglet = o
	for k in _boutons_onglets:
		(_boutons_onglets[k] as Button).button_pressed = k == o
	_elements = _lister(o)
	for e in _grille.get_children():
		e.queue_free()
	var vus := 0
	for i in _elements.size():
		var el: Dictionary = _elements[i]
		if el["ouvert"]:
			vus += 1
		_grille.add_child(_vignette(el, i))
	_compteur.text = "%d / %d débloquées" % [vus, _elements.size()]


func _lister(o: String) -> Array:
	var l: Array = []
	match o:
		"creatures", "figurines":
			var ids: Array = UnitesData.UNITES.keys()
			ids.sort_custom(_tri_unites)
			for id in ids:
				var sid := str(id)
				var chemin := UiCommun.chemin_portrait(sid) if o == "creatures" else UiCommun.chemin_figurine(sid)
				if chemin == "":
					continue
				l.append({"type": "unite", "id": sid, "titre": str(UnitesData.get_unite(sid)["nom"]), "chemin": chemin,
					"ouvert": _unite_vue(sid), "figurine": o == "figurines"})
		"familiers":
			var possedes := {}
			for f in Menagerie.familiers():
				possedes[str(f["id"])] = true
			for fid in FamiliersData.ids():
				var ch := FamiliersData.chemin_image(fid)
				if ch == "":
					continue
				var f := FamiliersData.get_familier(fid)
				l.append({"type": "familier", "id": fid, "titre": str(f["nom"]), "chemin": ch,
					"ouvert": TOUT_REVELER or Sauvegarde.admin("bestiaire_complet") or possedes.has(fid)})
		"boss_monde":
			for i in BossMonde.BOSS.size():
				var b: Dictionary = BossMonde.BOSS[i]
				var ch := "res://assets/boss_monde/%s.png" % b["id"]
				if ResourceLoader.exists(ch):
					l.append({"type": "image", "id": str(b["id"]), "titre": str(b["titre"]), "chemin": ch, "ouvert": true,
						"texte": "%s — %s" % [Calendrier.JOURS[i], b["texte"]]})
		"histoire":
			for a in range(1, 14):
				var acte := ActesData.get_acte(a)
				var ch := str(acte.get("image", ""))
				if ResourceLoader.exists(ch):
					l.append({"type": "image", "id": "acte_%d" % a, "titre": "Acte %s — %s" % [acte.get("romain", str(a)), acte.get("titre", "")],
						"chemin": ch, "ouvert": TOUT_REVELER or ActesData.acte_debloque(a), "texte": str(acte.get("partie", ""))})
			for ch in _fichiers("res://assets/personnages"):
				# Les personnages qui dévoileraient la suite de l'histoire attendent leur Acte
				var a_req: int = SPOILERS.get(ch.get_file().get_basename(), 1)
				l.append({"type": "image", "id": ch, "titre": _joli_nom(ch), "chemin": ch, "texte": "Personnage de l'histoire",
					"ouvert": TOUT_REVELER or ActesData.acte_debloque(a_req)})
		"decors":
			var noms := {"menu_freres": "La Crypte des Valcendre (menu principal)", "carte_monde": "Les Terres des Valcendre (carte du monde)"}
			for n in noms:
				var ch := "res://assets/ui/%s.png" % n
				if ResourceLoader.exists(ch):
					l.append({"type": "image", "id": n, "titre": noms[n], "chemin": ch, "ouvert": true, "texte": "Décor"})
			for ch in _fichiers("res://assets/fonds"):
				l.append({"type": "image", "id": ch, "titre": _joli_nom(ch), "chemin": ch, "ouvert": true, "texte": "Fond de menu"})
			if ResourceLoader.exists(Sanctuaire.FOND) and (TOUT_REVELER or not (Sanctuaire._etat()["vaincus"] as Array).is_empty()):
				l.append({"type": "image", "id": "sanctuaire", "titre": "Le Sanctuaire du Bélier", "chemin": Sanctuaire.FOND, "ouvert": true, "texte": "Lieu secret"})
		"plateau":
			for ch in _fichiers("res://assets/plateaux"):
				l.append({"type": "image", "id": ch, "titre": _joli_nom(ch), "chemin": ch, "ouvert": true, "texte": "Champ de bataille"})
			for ch in _fichiers("res://assets/plateaux/cases"):
				l.append({"type": "image", "id": ch, "titre": "Case : " + _joli_nom(ch), "chemin": ch, "ouvert": true, "texte": "Miniature du plateau"})
			for ch in _fichiers("res://assets/invocation"):
				l.append({"type": "image", "id": ch, "titre": _joli_nom(ch), "chemin": ch, "ouvert": true, "texte": "Autel d'Invocation"})
	return l


func _tri_unites(a, b) -> bool:
	var ua := UnitesData.get_unite(str(a))
	var ub := UnitesData.get_unite(str(b))
	var ca: int = ["heros", "ennemi", "boss", "boss_monde"].find(str(ua.get("categorie", "")))
	var cb: int = ["heros", "ennemi", "boss", "boss_monde"].find(str(ub.get("categorie", "")))
	if ca != cb:
		return ca < cb
	var ra: int = ORDRE_RARETE.get(str(ua.get("rarete", "N")), 5)
	var rb: int = ORDRE_RARETE.get(str(ub.get("rarete", "N")), 5)
	if ra != rb:
		return ra < rb
	return str(ua.get("nom", "")) < str(ub.get("nom", ""))


func _unite_vue(id: String) -> bool:
	return TOUT_REVELER or Sauvegarde.est_decouvert(id)


## Images PNG d'un dossier (fonctionne aussi une fois le jeu exporté).
func _fichiers(dossier: String) -> Array:
	var l: Array = []
	for f in ResourceLoader.list_directory(dossier):
		var n := str(f)
		if n.ends_with(".png"):
			l.append(dossier + "/" + n)
	l.sort()
	return l


func _joli_nom(chemin: String) -> String:
	var n := chemin.get_file().get_basename().replace("_", " ")
	return n.substr(0, 1).to_upper() + n.substr(1)


func _vignette(el: Dictionary, i: int) -> Button:
	var b := Button.new()
	var large: bool = el["type"] == "image"
	b.custom_minimum_size = Vector2(250, 190) if large else Vector2(150, 190)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.clip_contents = true
	var bord := UiCommun.C_OR.darkened(0.3)
	if el["type"] == "unite":
		bord = UiCommun.couleur_rarete(el["id"])
	elif el["type"] == "familier":
		bord = UiCommun.COULEURS_RARETE.get(FamiliersData.get_familier(el["id"])["rarete"], bord)
	var st := UiCommun.style_carte(bord if el["ouvert"] else Color("3a3032"), 0.0, 2)
	b.add_theme_stylebox_override("normal", st)
	var survol := UiCommun.style_carte(Color("ffd27a"), 0.04, 2)
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", survol)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Héros, monstres et familiers découverts : cadre de leur rareté
	var avec_cadre: bool = el["ouvert"] and el["type"] in ["unite", "familier"] and not el.get("figurine", false)
	var marge_cadre := UiCommun.bord_cadre(str(el["id"]), b.custom_minimum_size.x) if avec_cadre else 0.0
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 4 + marge_cadre
	v.offset_right = -4 - marge_cadre
	v.offset_top = 4 + marge_cadre
	v.offset_bottom = -4 - (b.custom_minimum_size.x * 0.2 if avec_cadre else 0.0)   # le nom passe au-dessus des coins ornés du bas
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	if avec_cadre:
		UiCommun.encadrer(b, str(el["id"]), 2.0)
		b.clip_contents = false      # les coins ornés du cadre dépassent un peu de la vignette
	if el["ouvert"]:
		var img := TextureRect.new()
		img.texture = load(el["chemin"])
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if el.get("figurine", false) else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.size_flags_vertical = Control.SIZE_EXPAND_FILL
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(img)
		b.pressed.connect(_ouvrir.bind(i))
	else:
		var q := UiCommun.label("?", 54, Color("5a4e4a"))
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(q)
		b.tooltip_text = "Pas encore découvert"
	var nom := UiCommun.label(str(el["titre"]) if el["ouvert"] else "???", 12, Color.WHITE if el["ouvert"] else UiCommun.C_DOUX)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.clip_text = true
	nom.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nom)
	return b


# =====================================================================
# Fenêtre : une image en grand, ou la fiche d'une créature
# =====================================================================

func _ouvrir(i: int) -> void:
	_fermer()
	_index_ouvert = i
	var el: Dictionary = _elements[i]
	var voile := Button.new()
	voile.flat = true
	voile.focus_mode = Control.FOCUS_NONE
	var sv := StyleBoxFlat.new()
	sv.bg_color = Color(0, 0, 0, 0.88)
	for k in ["normal", "hover", "pressed"]:
		voile.add_theme_stylebox_override(k, sv)
	voile.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.pressed.connect(_fermer)
	add_child(voile)
	_fenetre = voile

	var cadre := PanelContainer.new()
	cadre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in [["offset_left", 70.0], ["offset_right", -70.0], ["offset_top", 30.0], ["offset_bottom", -30.0]]:
		cadre.set(c[0], c[1])
	cadre.mouse_filter = Control.MOUSE_FILTER_STOP
	var bord := UiCommun.C_OR
	if el["type"] == "unite":
		bord = UiCommun.couleur_rarete(el["id"])
	var sc := StyleBoxFlat.new()          # fenêtre opaque (style_panneau est volontairement transparent)
	sc.bg_color = Color("120b0c")
	sc.border_color = bord
	sc.set_border_width_all(2)
	sc.set_corner_radius_all(10)
	sc.set_content_margin_all(16)
	cadre.add_theme_stylebox_override("panel", sc)
	voile.add_child(cadre)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	cadre.add_child(col)

	var corps := Control.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(corps)
	match el["type"]:
		"unite":
			_fiche_unite(corps, el)
		"familier":
			_fiche_familier(corps, el)
		_:
			_fiche_image(corps, el)

	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(bas)
	var prec := UiCommun.bouton("‹  Précédent", 16)
	prec.pressed.connect(_suivant.bind(-1))
	bas.add_child(prec)
	var fermer := UiCommun.bouton("Fermer", 16)
	fermer.pressed.connect(_fermer)
	bas.add_child(fermer)
	var suiv := UiCommun.bouton("Suivant  ›", 16)
	suiv.pressed.connect(_suivant.bind(1))
	bas.add_child(suiv)


func _fermer() -> void:
	if is_instance_valid(_fenetre):
		_fenetre.queue_free()
	_fenetre = null
	_index_ouvert = -1


## Image suivante / précédente déjà découverte.
func _suivant(sens: int) -> void:
	if _index_ouvert < 0 or _elements.is_empty():
		return
	var i := _index_ouvert
	for k in _elements.size():
		i = posmod(i + sens, _elements.size())
		if _elements[i]["ouvert"]:
			_ouvrir(i)
			return


func _image_pleine(chemin: String, couvrir := false) -> TextureRect:
	var img := TextureRect.new()
	img.texture = load(chemin)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if couvrir else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return img


func _fiche_image(corps: Control, el: Dictionary) -> void:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 6)
	corps.add_child(v)
	var t := UiCommun.label(str(el["titre"]), 24, UiCommun.C_OR)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var img := _image_pleine(el["chemin"])
	img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(img)
	var s := UiCommun.label(str(el.get("texte", "")), 15, UiCommun.C_DOUX)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)


func _fiche_unite(corps: Control, el: Dictionary) -> void:
	var id: String = el["id"]
	var u := UnitesData.get_unite(id)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 18)
	corps.add_child(h)

	# Portrait et figurine côte à côte
	var images := HBoxContainer.new()
	images.add_theme_constant_override("separation", 8)
	images.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	images.size_flags_stretch_ratio = 1.25
	h.add_child(images)
	var por := UiCommun.chemin_portrait(id)
	if por != "":
		var p := _image_pleine(por)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		images.add_child(p)
	var fig := UiCommun.chemin_figurine(id)
	if fig != "":
		var f := _image_pleine(fig)
		f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f.size_flags_stretch_ratio = 0.8
		images.add_child(f)

	# Descriptif
	var d := ScrollContainer.new()
	d.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(d)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	d.add_child(v)
	v.add_child(UiCommun.label(str(u["nom"]).to_upper(), 28, UiCommun.couleur_rarete(id)))
	var infos := "%s  ·  %s  ·  %s" % [UiCommun.texte_rarete(id), UnitesData.ELEMENTS.get(u["element"], ""), UnitesData.ROLES.get(u["role"], "")]
	if str(u.get("race", "")) != "":
		infos += "  ·  " + str(u["race"])
	v.add_child(UiCommun.label(infos, 16, UiCommun.COULEURS_ELEMENT.get(u["element"], UiCommun.C_TEXTE)))
	var cat: String = CATEGORIES.get(str(u.get("categorie", "")), "")
	v.add_child(UiCommun.label("%s  ·  ligne %s" % [cat, "Avant" if str(u.get("position", "")) == "avant" else "Arrière"], 14, UiCommun.C_DOUX))
	v.add_child(HSeparator.new())
	v.add_child(UiCommun.label("OÙ LA TROUVER", 13, UiCommun.C_OR))
	for ligne in _ou_trouver(id, u):
		var l := UiCommun.label("•  " + ligne, 15, UiCommun.C_TEXTE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	v.add_child(HSeparator.new())
	v.add_child(UiCommun.label("COMPÉTENCES", 13, UiCommun.C_OR))
	for sk in u.get("skills", []):
		var t := UiCommun.label("%s  (%s, niv. %d)" % [sk["nom"], "actif" if sk["type"] == "actif" else "passif", int(sk.get("niveau", 1))], 16, Color("ffd27a"))
		v.add_child(t)
		var ds := UiCommun.label(str(sk.get("description", "")), 14, UiCommun.C_DOUX)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(ds)


## Où rencontrer ou obtenir une unité (Invocation, Forge, Actes, Donjons, Tours, Boss de Monde).
func _ou_trouver(id: String, u: Dictionary) -> Array:
	var l: Array = []
	if u.get("invocable", false):
		l.append("Autel d'Invocation")
	if u.get("forge", false):
		l.append("Forge du Reliquaire")
	var actes: Array = []
	for a in Rencontres.POOLS:
		var p: Dictionary = Rencontres.POOLS[a]
		if id == str(p.get("boss", "")):
			l.append("Boss de l'Acte %s" % ActesData.get_acte(int(a)).get("romain", str(a)))
		elif id in p.get("monstres", []) or id in p.get("gardiens", []):
			actes.append(str(ActesData.get_acte(int(a)).get("romain", str(a))))
	if not actes.is_empty():
		l.append("Aventure : Acte " + ", ".join(actes))
	for dk in Donjons.DONJONS:
		var dj: Dictionary = Donjons.DONJONS[dk]
		if id == str(dj["boss"]):
			l.append("Boss du donjon « %s »" % dj["nom"])
		elif id == str(dj["mini_boss"]):
			l.append("Mini-boss du donjon « %s »" % dj["nom"])
		elif id in dj["monstres"]:
			l.append("Donjon « %s »" % dj["nom"])
	for tk in Tours.TOURS:
		var t: Dictionary = Tours.TOURS[tk]
		for etage in t["boss"]:
			if id == str(t["boss"][etage]):
				l.append("%s, étage %d" % [t["nom"], int(etage)])
		for pal in t["paliers"]:
			if id in pal["monstres"]:
				l.append("%s : %s" % [t["nom"], pal["nom"]])
	for i in BossMonde.BOSS.size():
		if id == str(BossMonde.BOSS[i]["id"]):
			l.append("Boss de Monde du %s" % Calendrier.JOURS[i].to_lower())
	if l.is_empty():
		l.append("Rencontre spéciale")
	return l


func _fiche_familier(corps: Control, el: Dictionary) -> void:
	var f := FamiliersData.get_familier(el["id"])
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 18)
	corps.add_child(h)
	var img := _image_pleine(el["chemin"])
	img.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(img)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	h.add_child(v)
	v.add_child(UiCommun.label(str(f["nom"]).to_upper(), 28, UiCommun.COULEURS_RARETE.get(f["rarete"], UiCommun.C_OR)))
	v.add_child(UiCommun.label("Familier %s  ·  %s" % [f["rarete"], UnitesData.ELEMENTS.get(f["element"], "")], 16, UiCommun.C_DOUX))
	var ds := UiCommun.label(str(f["description"]), 16, UiCommun.C_TEXTE)
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ds)
	var tl := UiCommun.label(FamiliersData.texte_talent(el["id"]), 15, Color("ffd27a"))
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(tl)
	v.add_child(UiCommun.label("Se trouve au Pacte Sauvage (Autel d'Invocation).", 14, UiCommun.C_DOUX))


# =====================================================================

func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if k == KEY_ESCAPE:
		if is_instance_valid(_fenetre):
			_fermer()
		else:
			_retour()
	elif is_instance_valid(_fenetre) and (k == KEY_LEFT or k == KEY_RIGHT):
		_suivant(-1 if k == KEY_LEFT else 1)
	else:
		return
	get_viewport().set_input_as_handled()
