class_name EcranFusion
extends Control
## AUTEL DE FUSION
##
## Onglet ÉVEIL : le héros principal gagne une étoile en sacrifiant des doublons (même unité).
## Onglet ABSORPTION : le héros principal gagne de l'XP en sacrifiant d'autres unités.
## 1) Clique une unité de la collection pour en faire le héros principal.
## 2) Clique les unités à sacrifier (ou « Sélection auto »).
## 3) « Fusionner ».
## Les unités de l'équipe peuvent être principales mais jamais sacrifiées.

const SCENE := "res://scenes/fusion.tscn"
const FOND := "res://assets/ui/menu_bg.png"
const ORDRE_RARETE := {"LEG": 5, "UR": 4, "SSR": 3, "SR": 2, "R": 1, "N": 0}

static var scene_retour := ""

var _mode := "eveil"            # "eveil" ou "absorption"
var _principal := -1
var _sacrifices: Array = []     # uids
var _pierres := 0               # Pierres d'Éveil utilisées (Éveil)
var _ligne_pierres: HBoxContainer

var _lbl_or: Label
var _onglets := {}
var _boite_principal: Control
var _lbl_principal: Label
var _ligne_sacrifices: HFlowContainer
var _lbl_sacrifices: Label
var _apercu: VBoxContainer
var _btn_fusion: Button
var _btn_auto: Button
var _btn_vider: Button
var _lbl_grille: Label
var _grille: GridContainer
var _defil: ScrollContainer


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	# En-tête
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("AUTEL DE FUSION", 32, UiCommun.C_OR))
	var espace := Control.new()
	espace.custom_minimum_size = Vector2(20, 0)
	tete.add_child(espace)
	for o in [["eveil", "Éveil  (étoiles)"], ["absorption", "Absorption  (XP)"]]:
		var b := UiCommun.bouton(o[1], 17)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(190, 40)
		b.pressed.connect(_changer_mode.bind(o[0]))
		tete.add_child(b)
		_onglets[o[0]] = b
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(pousse)
	_lbl_or = UiCommun.label("", 20, Color("ffd060"))
	tete.add_child(_lbl_or)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 14)
	col.add_child(corps)
	corps.add_child(_creer_panneau_autel())
	corps.add_child(_creer_panneau_collection())

	resized.connect(_ajuster_colonnes)
	_tout_rafraichir()
	_ajuster_colonnes()


# =====================================================================
# Construction
# =====================================================================

func _creer_panneau_autel() -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(620, 0)
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(Color("b0402f")))
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(defil)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	defil.add_child(vb)

	vb.add_child(UiCommun.label("HÉROS PRINCIPAL", 18, UiCommun.C_OR))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	vb.add_child(h)
	_boite_principal = Control.new()
	_boite_principal.custom_minimum_size = Vector2(132, 168)
	h.add_child(_boite_principal)
	_lbl_principal = UiCommun.label("", 15, UiCommun.C_TEXTE)
	_lbl_principal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_lbl_principal)

	vb.add_child(HSeparator.new())
	_lbl_sacrifices = UiCommun.label("", 18, Color("ff8a7a"))
	vb.add_child(_lbl_sacrifices)
	_ligne_sacrifices = HFlowContainer.new()
	_ligne_sacrifices.add_theme_constant_override("h_separation", 6)
	_ligne_sacrifices.add_theme_constant_override("v_separation", 6)
	vb.add_child(_ligne_sacrifices)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	vb.add_child(actions)
	_btn_auto = UiCommun.bouton("Sélection auto", 15)
	_btn_auto.pressed.connect(_selection_auto)
	actions.add_child(_btn_auto)
	_ligne_pierres = HBoxContainer.new()
	_ligne_pierres.add_theme_constant_override("separation", 8)
	vb.add_child(_ligne_pierres)
	_btn_vider = UiCommun.bouton("Vider", 15)
	_btn_vider.pressed.connect(func():
		_sacrifices.clear()
		_pierres = 0
		_tout_rafraichir())
	actions.add_child(_btn_vider)

	vb.add_child(HSeparator.new())
	_apercu = VBoxContainer.new()
	_apercu.add_theme_constant_override("separation", 6)
	vb.add_child(_apercu)

	_btn_fusion = UiCommun.bouton("FUSIONNER", 22)
	_btn_fusion.custom_minimum_size = Vector2(0, 56)
	_btn_fusion.add_theme_color_override("font_color", Color("ffd060"))
	_btn_fusion.pressed.connect(_fusionner)
	vb.add_child(_btn_fusion)
	return p


func _creer_panneau_collection() -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	_lbl_grille = UiCommun.label("", 17, UiCommun.C_OR)
	_lbl_grille.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_lbl_grille)
	_defil = ScrollContainer.new()
	_defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(_defil)
	_grille = GridContainer.new()
	_grille.add_theme_constant_override("h_separation", 8)
	_grille.add_theme_constant_override("v_separation", 8)
	_defil.add_child(_grille)
	return p


func _ajuster_colonnes() -> void:
	if _grille:
		_grille.columns = maxi(2, int((size.x - 36 - 620 - 14 - 40) / 140.0))


# =====================================================================
# Rafraîchissement
# =====================================================================

func _tout_rafraichir() -> void:
	if Sauvegarde.get_heros(_principal).is_empty():
		_principal = -1
	_sacrifices = _sacrifices.filter(func(u): return not Sauvegarde.get_heros(int(u)).is_empty())
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	for cle in _onglets:
		_onglets[cle].button_pressed = (cle == _mode)
	_remplir_principal()
	_remplir_sacrifices()
	_remplir_apercu()
	_remplir_grille()


func _remplir_principal() -> void:
	for e in _boite_principal.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_principal)
	var carte: Button
	if h.is_empty():
		carte = _case_vide("?\nPrincipal", Vector2(132, 168))
		_lbl_principal.text = "Clique une unité de la collection (à droite) pour la placer sur l'autel.\n\n" \
			+ ("ÉVEIL : sacrifie des doublons (la même unité) pour gagner une étoile. ★6 = Éveillé.\nChaque étoile : +%d %% PV / ATK / DEF / AGI / MAG ; l'Éveil donne +%d %% en plus." \
				% [int(Fusion.BONUS_PAR_ETOILE * 100), int(Fusion.BONUS_EVEIL * 100)] if _mode == "eveil" else \
			"ABSORPTION : sacrifie n'importe quelles unités pour donner de l'XP au héros principal.\nPlus l'unité sacrifiée est rare, haut niveau ou étoilée, plus elle donne d'XP (x%.1f si c'est la même unité)." % Fusion.BONUS_MEME_UNITE)
	else:
		carte = UiCommun.carte_heros(h)
		carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE, 0.08, 3))
		carte.tooltip_text = "Clique pour retirer ce héros de l'autel"
		var u := UnitesData.get_unite(h["id"])
		var t := "%s\n%s · Nv %d / %d\n%s" % [u["nom"], UiCommun.texte_rarete(h["id"]), int(h["niveau"]), UnitesData.NIVEAU_MAX,
			Fusion.texte_etoiles(Fusion.etoiles(h)) + ("  ÉVEILLÉ" if Fusion.est_eveille(h) else "")]
		if Sauvegarde.place_de(_principal) >= 0:
			t += "\nDans l'équipe (place %d)" % (Sauvegarde.place_de(_principal) + 1)
		t += "\n\n(clique sa carte pour changer de héros principal)"
		_lbl_principal.text = t
	carte.pressed.connect(func():
		_principal = -1
		_sacrifices.clear()
		_pierres = 0
		_tout_rafraichir())
	_boite_principal.add_child(carte)


func _remplir_sacrifices() -> void:
	for e in _ligne_sacrifices.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_principal)
	var nb_cases := Fusion.MAX_SACRIFICES
	if _mode == "eveil":
		nb_cases = maxi(0, Fusion.doublons_requis(h) - _pierres) if not h.is_empty() and not Fusion.est_eveille(h) else 1
		_lbl_sacrifices.text = "DOUBLONS À SACRIFIER  (%d / %d)" % [_sacrifices.size(), nb_cases] if not h.is_empty() and not Fusion.est_eveille(h) \
			else "DOUBLONS À SACRIFIER"
	else:
		_lbl_sacrifices.text = "UNITÉS À SACRIFIER  (%d / %d)" % [_sacrifices.size(), nb_cases]
	var taille := Vector2(100, 140) if _mode == "eveil" else Vector2(92, 124)
	for i in nb_cases:
		var carte: Button
		if i < _sacrifices.size():
			carte = UiCommun.carte_heros(Sauvegarde.get_heros(int(_sacrifices[i])), taille.x, taille.y)
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color("ff6a5a"), 0.1, 3))
			carte.tooltip_text = "Clique pour le retirer des sacrifices"
			carte.pressed.connect(_basculer_sacrifice.bind(int(_sacrifices[i])))
		else:
			carte = _case_vide("+", taille)
			carte.disabled = true
		_ligne_sacrifices.add_child(carte)
	_btn_auto.disabled = h.is_empty()
	_btn_vider.disabled = _sacrifices.is_empty()
	# Pierres d'Éveil (remplacent des doublons)
	for e in _ligne_pierres.get_children():
		e.queue_free()
	_ligne_pierres.visible = _mode == "eveil" and not h.is_empty() and not Fusion.est_eveille(h)
	if _ligne_pierres.visible:
		var possede := Sauvegarde.get_objet(Fusion.PIERRE)
		_pierres = clampi(_pierres, 0, mini(possede, Fusion.doublons_requis(h)))
		_ligne_pierres.add_child(UiCommun.icone_objet(Fusion.PIERRE, 30))
		_ligne_pierres.add_child(UiCommun.label("Pierres d'Éveil utilisées : %d  (possédées : %d)" % [_pierres, possede], 15, Color("ff9ad8")))
		var moins := UiCommun.bouton("−", 16)
		moins.custom_minimum_size = Vector2(36, 32)
		moins.disabled = _pierres <= 0
		moins.pressed.connect(func():
			_pierres -= 1
			_tout_rafraichir())
		_ligne_pierres.add_child(moins)
		var plus := UiCommun.bouton("+", 16)
		plus.custom_minimum_size = Vector2(36, 32)
		plus.disabled = _pierres >= mini(possede, Fusion.doublons_requis(h))
		plus.pressed.connect(func():
			_pierres += 1
			while _sacrifices.size() > Fusion.doublons_requis(h) - _pierres and not _sacrifices.is_empty():
				_sacrifices.pop_back()
			_tout_rafraichir())
		_ligne_pierres.add_child(plus)


func _remplir_apercu() -> void:
	for e in _apercu.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_principal)
	if h.is_empty():
		_btn_fusion.disabled = true
		return
	var raison := ""
	var base := Sauvegarde.stats_base_heros(_principal)
	var apres := {}
	if _mode == "eveil":
		raison = Fusion.raison_eveil_impossible(_principal, _sacrifices, _pierres)
		if Fusion.est_eveille(h):
			_apercu.add_child(UiCommun.label("Ce héros est Éveillé : il a atteint le rang maximum.", 16, Color("ff9a5a")))
		else:
			var et := Fusion.etoiles(h)
			_apercu.add_child(UiCommun.label("%s   →   %s%s" % [Fusion.texte_etoiles(et), Fusion.texte_etoiles(et + 1),
				"   ÉVEIL !" if et + 1 >= Fusion.ETOILES_MAX else ""], 20, Color("ffd060")))
			_apercu.add_child(_ligne_condition("Doublons + Pierres : %d / %d" % [mini(_sacrifices.size() + _pierres, Fusion.doublons_requis(h)), Fusion.doublons_requis(h)],
				_sacrifices.size() + _pierres >= Fusion.doublons_requis(h)))
			_apercu.add_child(_ligne_condition("Niveau requis : %d  (actuel : %d)" % [Fusion.niveau_requis(h), int(h["niveau"])],
				int(h["niveau"]) >= Fusion.niveau_requis(h)))
			_apercu.add_child(_ligne_condition("Coût : %d or" % Fusion.cout_eveil(h), Sauvegarde.get_or() >= Fusion.cout_eveil(h)))
			apres = Fusion.appliquer_etoiles(UnitesData.stats(h["id"], int(h["niveau"])), et + 1)
	else:
		raison = Fusion.raison_absorption_impossible(_principal, _sacrifices)
		if int(h["niveau"]) >= UnitesData.NIVEAU_MAX:
			_apercu.add_child(UiCommun.label("Niveau maximum atteint : l'absorption n'est plus utile.", 16, Color("ff9a5a")))
		else:
			var xp := Fusion.xp_totale(_principal, _sacrifices)
			var ap := Fusion.apercu_xp(_principal, xp)
			_apercu.add_child(UiCommun.label("XP gagnée : +%d" % xp, 20, Color("7ab8ff")))
			_apercu.add_child(UiCommun.label("Niveau %d   →   %d%s" % [int(h["niveau"]), int(ap["niveau"]),
				"" if int(ap["niveau"]) >= UnitesData.NIVEAU_MAX else "   (XP %d / %d)" % [int(ap["xp"]), Sauvegarde.xp_heros_pour_niveau(int(ap["niveau"]))]],
				18, UiCommun.C_TEXTE))
			if int(ap["perdue"]) > 0:
				_apercu.add_child(UiCommun.label("Attention : %d XP seront perdus (niveau max atteint)." % int(ap["perdue"]), 14, Color("ff8a7a")))
			var cout := Fusion.cout_absorption(_principal, _sacrifices)
			_apercu.add_child(_ligne_condition("Coût : %d or" % cout, Sauvegarde.get_or() >= cout))
			apres = Fusion.appliquer_etoiles(UnitesData.stats(h["id"], int(ap["niveau"])), Fusion.etoiles(h))
	if not apres.is_empty():
		_apercu.add_child(_tableau_stats(base, apres))
	_btn_fusion.disabled = raison != ""
	_btn_fusion.tooltip_text = raison
	if raison != "" and not _sacrifices.is_empty():
		var l := UiCommun.label(raison, 14, Color("ff8a7a"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apercu.add_child(l)


func _tableau_stats(avant: Dictionary, apres: Dictionary) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 6)
	for paire in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"]]:
		var c := VBoxContainer.new()
		c.custom_minimum_size = Vector2(108, 0)
		var n := UiCommun.label(paire[1], 12, UiCommun.C_DOUX)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(n)
		var gain := int(apres[paire[0]]) - int(avant[paire[0]])
		var v := UiCommun.label("%d → %d" % [int(avant[paire[0]]), int(apres[paire[0]])], 15,
			Color("8fe08a") if gain > 0 else UiCommun.C_TEXTE)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(v)
		g.add_child(c)
	return g


func _ligne_condition(texte: String, ok: bool) -> Label:
	return UiCommun.label(("✔  " if ok else "✘  ") + texte, 15, Color("8fe08a") if ok else Color("ff8a7a"))


func _candidats() -> Array:
	var h := Sauvegarde.get_heros(_principal)
	var liste: Array = []
	for x in Sauvegarde.liste_heros():
		var uid := int(x["uid"])
		if h.is_empty():
			liste.append(x)
		elif uid != _principal:
			if _mode == "eveil" and x["id"] != h["id"]:
				continue
			liste.append(x)
	return liste


func _remplir_grille() -> void:
	for e in _grille.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_principal)
	var liste := _candidats()
	if h.is_empty():
		# Choix du principal : les plus forts d'abord
		liste.sort_custom(func(a, b): return _cle_tri(a) > _cle_tri(b))
		_lbl_grille.text = "CHOISIS LE HÉROS PRINCIPAL  (%d unités)" % liste.size()
	else:
		# Choix des sacrifices : les plus faibles d'abord
		liste.sort_custom(func(a, b): return _cle_tri(a) < _cle_tri(b))
		var nom: String = UnitesData.get_unite(h["id"])["nom"]
		_lbl_grille.text = ("DOUBLONS DE %s  (%d)" % [nom.to_upper(), liste.size()] if _mode == "eveil" \
			else "CHOISIS LES UNITÉS À SACRIFIER  (%d)" % liste.size()) \
			+ "\nL'équipe, le héros de départ et les unités verrouillées ne peuvent pas être sacrifiés."
	if liste.is_empty():
		var l := UiCommun.label("Aucun doublon de ce héros pour l'instant.\nInvoque-en d'autres à l'Autel d'Invocation." if _mode == "eveil" and not h.is_empty() \
			else "Aucune unité disponible.", 16, UiCommun.C_DOUX)
		_grille.add_child(l)
		return
	for x in liste:
		var uid := int(x["uid"])
		var carte := UiCommun.carte_heros(x)
		if not h.is_empty():
			var raison := Fusion.raison_non_sacrifiable(uid, _principal)
			if uid in _sacrifices:
				carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color("ff6a5a"), 0.1, 3))
				UiCommun.badge(carte, "Sacrifice", Color("ff8a7a"), false)
			elif raison != "":
				carte.modulate = Color(1, 1, 1, 0.4)
				carte.tooltip_text = raison
			elif _mode == "absorption":
				carte.tooltip_text = "+%d XP" % Fusion.xp_sacrifice(uid, _principal)
		if Sauvegarde.place_de(uid) >= 0:
			UiCommun.badge(carte, "Équipe", UiCommun.C_OR)
		elif x.get("verrou", false) or x.get("depart", false):
			UiCommun.badge(carte, "Protégé" if x.get("depart", false) else "Verrouillé", Color("8ab0d0"))
		carte.pressed.connect(_clic_collection.bind(uid))
		_grille.add_child(carte)


func _cle_tri(x: Dictionary) -> int:
	return ORDRE_RARETE[Fusion.cle_rarete(x["id"])] * 10000 + Fusion.etoiles(x) * 1000 + int(x["niveau"]) * 10


# =====================================================================
# Actions
# =====================================================================

func _changer_mode(mode: String) -> void:
	_mode = mode
	_sacrifices.clear()
	_pierres = 0
	_tout_rafraichir()


func _clic_collection(uid: int) -> void:
	if _principal < 0:
		_principal = uid
		_sacrifices.clear()
		_pierres = 0
		_tout_rafraichir()
		return
	_basculer_sacrifice(uid)


func _basculer_sacrifice(uid: int) -> void:
	if uid in _sacrifices:
		_sacrifices.erase(uid)
		_tout_rafraichir()
		return
	var raison := Fusion.raison_non_sacrifiable(uid, _principal)
	if raison != "":
		_message("Impossible", raison)
		return
	var limite := Fusion.MAX_SACRIFICES
	if _mode == "eveil":
		limite = Fusion.doublons_requis(Sauvegarde.get_heros(_principal)) - _pierres
	if _sacrifices.size() >= limite:
		_message("Autel plein", "Tu as déjà choisi %d unité(s). Retire-en une pour en ajouter une autre." % limite)
		return
	_sacrifices.append(uid)
	_tout_rafraichir()


## Remplit les sacrifices avec les unités les plus faibles disponibles.
func _selection_auto() -> void:
	var h := Sauvegarde.get_heros(_principal)
	if h.is_empty():
		return
	var limite := Fusion.doublons_requis(h) - _pierres if _mode == "eveil" else Fusion.MAX_SACRIFICES
	var liste := _candidats()
	liste.sort_custom(func(a, b): return _cle_tri(a) < _cle_tri(b))
	for x in liste:
		if _sacrifices.size() >= limite:
			break
		var uid := int(x["uid"])
		if uid in _sacrifices or Fusion.raison_non_sacrifiable(uid, _principal) != "":
			continue
		# En absorption, on évite par défaut de sacrifier les SSR, UR et Légendes
		if _mode == "absorption" and ORDRE_RARETE[Fusion.cle_rarete(x["id"])] >= 3:
			continue
		_sacrifices.append(uid)
	if _sacrifices.is_empty():
		_message("Sélection auto", "Aucune unité à sacrifier n'est disponible." if _mode == "eveil" \
			else "Aucune unité N, R ou SR disponible (les SSR, UR et Légendes se choisissent à la main).")
	_tout_rafraichir()


func _fusionner() -> void:
	var h := Sauvegarde.get_heros(_principal)
	if h.is_empty():
		return
	var nom: String = UnitesData.get_unite(h["id"])["nom"]
	var noms_sac: Array = []
	var rares := false
	for uid in _sacrifices:
		var s := Sauvegarde.get_heros(int(uid))
		noms_sac.append("%s Nv %d" % [UnitesData.get_unite(s["id"])["nom"], int(s["niveau"])])
		if ORDRE_RARETE[Fusion.cle_rarete(s["id"])] >= 3 or int(s["niveau"]) >= 10:
			rares = true
	var texte := ""
	if _mode == "eveil":
		texte = "Éveiller %s (★%d → ★%d) pour %d or ?\n\nSacrifiés : %s%s" % [nom, Fusion.etoiles(h), Fusion.etoiles(h) + 1,
			Fusion.cout_eveil(h), ", ".join(noms_sac) if not noms_sac.is_empty() else "aucun",
			"\nPierres d'Éveil utilisées : %d" % _pierres if _pierres > 0 else ""]
	else:
		texte = "Donner %d XP à %s pour %d or ?\n\nSacrifiés (%d) : %s" % [Fusion.xp_totale(_principal, _sacrifices), nom,
			Fusion.cout_absorption(_principal, _sacrifices), _sacrifices.size(), ", ".join(noms_sac)]
	if rares:
		texte += "\n\nAttention : certaines unités sacrifiées sont rares ou de haut niveau."
	texte += "\nLes unités sacrifiées disparaissent définitivement."
	_confirmer(texte, _executer)


func _executer() -> void:
	var h := Sauvegarde.get_heros(_principal)
	var nom: String = UnitesData.get_unite(h["id"])["nom"]
	if _mode == "eveil":
		var avant := Fusion.etoiles(h)
		if Fusion.eveiller(_principal, _sacrifices, _pierres):
			_sacrifices.clear()
			_pierres = 0
			_tout_rafraichir()
			_effet_reussite()
			var apres := avant + 1
			_message("Éveil réussi !" if apres >= Fusion.ETOILES_MAX else "Étoile gagnée !",
				"%s passe %s !\nBonus de stats : +%d %%.%s" % [nom, Fusion.texte_etoiles(apres, false),
				int(round((Fusion.multiplicateur(apres) - 1.0) * 100)),
				"\n\nIl est désormais ÉVEILLÉ." if apres >= Fusion.ETOILES_MAX else ""])
	else:
		var niv_avant := int(h["niveau"])
		var xp := Fusion.xp_totale(_principal, _sacrifices)
		var gagnes := Fusion.absorber(_principal, _sacrifices)
		if gagnes >= 0:
			_sacrifices.clear()
			_pierres = 0
			_tout_rafraichir()
			_effet_reussite()
			_message("Absorption réussie", "%s gagne %d XP.%s" % [nom, xp,
				"\nNiveau %d → %d !" % [niv_avant, niv_avant + gagnes] if gagnes > 0 else ""])


## Petit éclat lumineux sur la carte du héros principal.
func _effet_reussite() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.4, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.45, 0.12)
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	tw.tween_callback(flash.queue_free)


# =====================================================================
# Outils
# =====================================================================

func _case_vide(texte: String, taille: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = taille
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiCommun.style_carte(Color(1, 1, 1, 0.15)))
	b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.05))
	b.add_theme_stylebox_override("disabled", UiCommun.style_carte(Color(1, 1, 1, 0.12)))
	b.text = texte
	b.add_theme_color_override("font_color", UiCommun.C_DOUX)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	return b


func _creer_fond() -> void:
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.22, 0.12, 0.12)
		add_child(img)


func _message(titre: String, texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(460, 0))


func _confirmer(texte: String, action: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.title = "Autel de Fusion"
	d.dialog_text = texte
	d.ok_button_text = "Fusionner"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		action.call())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(480, 0))


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
