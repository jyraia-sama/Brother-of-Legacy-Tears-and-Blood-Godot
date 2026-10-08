class_name EcranEchos
extends Control
## ÉCHOS SANGUINS : équiper, améliorer et vendre les Échos de chaque héros.
##
## Gauche  : choix du héros.
## Centre  : ses 6 emplacements, les sets actifs et ses stats (base -> avec Échos).
## Droite  : l'inventaire (filtres emplacement / set / tri) et la fiche de l'Écho choisi.
## Cliquer un emplacement du héros filtre l'inventaire sur cet emplacement.
##
## Bouton « ? » (en haut, il brille) : le guide pas à pas des Échos (FenetreGuideEchos),
## ouvert tout seul à la première visite.
## MODE ESSAI : on place des Échos possédés « en essai » sur le héros (plusieurs à la fois) et on
## compare ses stats actuelles et en essai. Rien ne change tant qu'on n'appuie pas sur « Équiper l'essai ».

const SCENE := "res://scenes/echos.tscn"
const FOND := "res://assets/fonds/echos.png"

static var scene_retour := ""

var _heros := -1           # uid du héros sélectionné
var _echo := -1            # uid de l'Écho sélectionné
var _filtre_emplacement := 0
var _filtre_set := ""
var _tri := "etoiles"
var _rng := RandomNumberGenerator.new()

var _lbl_or: Label
var _liste_heros: VBoxContainer
var _centre: VBoxContainer
var _zone_inv: VBoxContainer       # contenu de l'inventaire (grille du sac, ou Échos portés par héros)
var _vue_inv := "sac"              # "sac" = Échos libres, "portes" = Échos équipés sur un héros
var _onglets_inv := {}             # vue -> bouton d'onglet
var _fiche: VBoxContainer
var _opt_emplacement: OptionButton
var _opt_set: OptionButton
var _opt_tri: OptionButton
var _lbl_inventaire: Label
var _btn_aide: Button

# Mode Essai : emplacement (1-6) -> uid de l'Écho essayé (-1 = vide)
var _essai_actif := false
var _essai := {}

const C_ESSAI := Color("5fd0ff")
const C_HAUSSE := Color("8aff9a")
const C_BAISSE := Color("ff7a6a")


func _ready() -> void:
	Sauvegarde.charger()
	_rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
		img.modulate = UiCommun.TEINTE_FOND
		add_child(img)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 16)
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
	var titre := UiCommun.label("ÉCHOS SANGUINS", 30, Color("d0453a"))
	tete.add_child(titre)
	# Bouton d'aide « ? » bien en vue : doré, lumineux et qui pulse
	_btn_aide = UiCommun.bouton("?", 26)
	_btn_aide.custom_minimum_size = Vector2(52, 46)
	_btn_aide.tooltip_text = "Guide des Échos Sanguins : sets, optimisation, où les trouver, Mode Essai."
	UiCommun.bouton_vif(_btn_aide, Color("c8871e"))
	_btn_aide.pressed.connect(_ouvrir_guide)
	tete.add_child(_btn_aide)
	var lbl_aide := UiCommun.label("← Comment ça marche ?", 15, UiCommun.C_LEGENDE)
	lbl_aide.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl_aide.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(lbl_aide)
	_lbl_or = UiCommun.label("", 20, Color("ffd060"))
	tete.add_child(_lbl_or)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 12)
	col.add_child(corps)

	# --- Héros ---
	var ph := _panneau(250)
	corps.add_child(ph)
	var vh := VBoxContainer.new()
	ph.add_child(vh)
	vh.add_child(UiCommun.label("HÉROS", 17, UiCommun.C_OR))
	var dh := ScrollContainer.new()
	dh.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dh.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vh.add_child(dh)
	_liste_heros = VBoxContainer.new()
	_liste_heros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste_heros.add_theme_constant_override("separation", 4)
	dh.add_child(_liste_heros)

	# --- Héros choisi ---
	var pc := _panneau(0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corps.add_child(pc)
	var dc := ScrollContainer.new()
	dc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(dc)
	_centre = VBoxContainer.new()
	_centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_centre.add_theme_constant_override("separation", 10)
	dc.add_child(_centre)

	# --- Inventaire ---
	var pi := _panneau(560)
	corps.add_child(pi)
	var vi := VBoxContainer.new()
	vi.add_theme_constant_override("separation", 8)
	pi.add_child(vi)
	var hi := HBoxContainer.new()
	hi.add_theme_constant_override("separation", 6)
	vi.add_child(hi)
	_lbl_inventaire = UiCommun.label("INVENTAIRE", 17, UiCommun.C_OR)
	_lbl_inventaire.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hi.add_child(_lbl_inventaire)
	var rapide := UiCommun.bouton("Vente rapide", 13)
	rapide.custom_minimum_size = Vector2(0, 30)
	rapide.tooltip_text = "Vend tous les Échos Normaux et Magiques non équipés et non verrouillés."
	rapide.pressed.connect(_vente_rapide)
	hi.add_child(rapide)

	# Onglets : les Échos libres (sac) et ceux déjà portés par un héros, rangés à part
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 6)
	vi.add_child(onglets)
	for o in [["sac", "Sac"], ["portes", "Équipés sur les héros"]]:
		var bo := UiCommun.bouton(o[1], 15)
		bo.custom_minimum_size = Vector2(0, 36)
		bo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bo.pressed.connect(func():
			_vue_inv = o[0]
			_remplir_inventaire())
		onglets.add_child(bo)
		_onglets_inv[o[0]] = bo

	var filtres := HBoxContainer.new()
	filtres.add_theme_constant_override("separation", 6)
	vi.add_child(filtres)
	_opt_emplacement = OptionButton.new()
	_opt_emplacement.add_item("Tous les emplacements", 0)
	for i in range(1, 7):
		_opt_emplacement.add_item("%d · %s" % [i, Echos.EMPLACEMENTS[i]["nom"].trim_prefix("Écho ")], i)
	_opt_emplacement.item_selected.connect(func(idx):
		_filtre_emplacement = _opt_emplacement.get_item_id(idx)
		_remplir_inventaire())
	filtres.add_child(_opt_emplacement)
	_opt_set = OptionButton.new()
	_opt_set.add_item("Tous les sets")
	for sid in Echos.SETS:
		_opt_set.add_item(Echos.SETS[sid]["nom"])
		_opt_set.set_item_metadata(_opt_set.item_count - 1, sid)
	_opt_set.item_selected.connect(func(idx):
		_filtre_set = "" if idx == 0 else str(_opt_set.get_item_metadata(idx))
		_remplir_inventaire())
	filtres.add_child(_opt_set)
	_opt_tri = OptionButton.new()
	for t in [["etoiles", "Tri : étoiles"], ["niveau", "Tri : niveau"], ["rarete", "Tri : rareté"]]:
		_opt_tri.add_item(t[1])
		_opt_tri.set_item_metadata(_opt_tri.item_count - 1, t[0])
	_opt_tri.item_selected.connect(func(idx):
		_tri = str(_opt_tri.get_item_metadata(idx))
		_remplir_inventaire())
	filtres.add_child(_opt_tri)

	var di := ScrollContainer.new()
	di.size_flags_vertical = Control.SIZE_EXPAND_FILL
	di.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vi.add_child(di)
	_zone_inv = VBoxContainer.new()
	_zone_inv.add_theme_constant_override("separation", 8)
	di.add_child(_zone_inv)

	var pf := PanelContainer.new()
	pf.add_theme_stylebox_override("panel", UiCommun.style_panneau(Color(0.5, 0.35, 0.25), Color(0.05, 0.02, 0.02, 0.9)))
	pf.custom_minimum_size = Vector2(0, 270)
	vi.add_child(pf)
	_fiche = VBoxContainer.new()
	_fiche.add_theme_constant_override("separation", 5)
	pf.add_child(_fiche)

	var equipe := Sauvegarde.get_equipe()
	_heros = equipe[0] if not equipe.is_empty() else -1
	_tout()
	_animer_aide()
	# Première visite : le guide s'ouvre tout seul
	if Tutoriel.premiere_fois("guide_echos"):
		Tutoriel.premiere_fois("echos")      # l'ancienne astuce est remplacée par le guide
		_ouvrir_guide.call_deferred()


func _ouvrir_guide() -> void:
	FenetreGuideEchos.ouvrir(self, _heros)


## Le « ? » grossit légèrement en rythme pour attirer l'œil.
func _animer_aide() -> void:
	_btn_aide.resized.connect(func(): _btn_aide.pivot_offset = _btn_aide.size / 2.0)
	var tw := _btn_aide.create_tween().set_loops()
	tw.tween_property(_btn_aide, "scale", Vector2(1.12, 1.12), 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_btn_aide, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)


func _panneau(largeur: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	if largeur > 0:
		p.custom_minimum_size = Vector2(largeur, 0)
	return p


# =====================================================================
# Rafraîchissement
# =====================================================================

func _tout() -> void:
	if _essai_actif:
		_nettoyer_essai()
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	_remplir_heros()
	_remplir_centre()
	_remplir_inventaire()
	_remplir_fiche()


func _remplir_heros() -> void:
	for e in _liste_heros.get_children():
		e.queue_free()
	var equipe := Sauvegarde.get_equipe()
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(func(a, b):
		var ea: bool = int(a["uid"]) in equipe
		var eb: bool = int(b["uid"]) in equipe
		if ea != eb:
			return ea
		return int(a["niveau"]) > int(b["niveau"]))
	for h in liste:
		var uid := int(h["uid"])
		var u := UnitesData.get_unite(h["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 52)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bord: Color = Color.WHITE if uid == _heros else UiCommun.couleur_rarete(h["id"]).darkened(0.3)
		b.add_theme_stylebox_override("normal", UiCommun.style_carte(bord, 0.05 if uid == _heros else 0.0, 2))
		b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 6
		hb.add_theme_constant_override("separation", 8)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hb)
		var por := UiCommun.portrait(h["id"], 38)
		por.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(por)
		var t := UiCommun.label("%s\nNv %d  ·  %d/6 Échos%s" % [u["nom"], int(h["niveau"]), Sauvegarde.echos_de(uid).size(),
			"  ·  Équipe" if uid in equipe else ""], 13)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(t)
		b.pressed.connect(func():
			_heros = uid
			if _essai_actif:
				_essai = _equipement_actuel()     # l'essai repart de l'équipement du nouveau héros
			_tout())
		_liste_heros.add_child(b)


func _remplir_centre() -> void:
	for e in _centre.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_heros)
	if h.is_empty():
		_centre.add_child(UiCommun.label("Choisis un héros.", 16, UiCommun.C_DOUX))
		return
	var u := UnitesData.get_unite(h["id"])
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	tete.add_child(UiCommun.portrait(h["id"], 64))
	var t := UiCommun.label("%s\nNv %d  ·  %s  ·  %s" % [u["nom"], int(h["niveau"]), UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]]], 20, UiCommun.couleur_rarete(h["id"]))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	_centre.add_child(tete)

	# Barre du Mode Essai
	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 6)
	_centre.add_child(barre)
	if not _essai_actif:
		var be := UiCommun.bouton("🧪 Mode Essai", 15)
		be.tooltip_text = "Essaie des Échos sur ce héros et compare ses stats avant d'équiper."
		be.pressed.connect(_entrer_essai)
		barre.add_child(be)
		var aide := UiCommun.label("Compare plusieurs Échos avant de les équiper.", 13, UiCommun.C_DOUX)
		aide.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barre.add_child(aide)
	else:
		var lbl := UiCommun.label("MODE ESSAI", 16, C_ESSAI)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barre.add_child(lbl)
		var nb := _nb_changements()
		var ok := UiCommun.bouton("Équiper l'essai%s" % ((" (%d)" % nb) if nb > 0 else ""), 14)
		ok.disabled = nb == 0
		if nb > 0:
			UiCommun.bouton_vif(ok)
		ok.pressed.connect(_valider_essai)
		barre.add_child(ok)
		var annuler := UiCommun.bouton("Annuler l'essai", 14)
		annuler.disabled = nb == 0
		annuler.pressed.connect(func():
			_essai = _equipement_actuel()
			_tout())
		barre.add_child(annuler)
		var quitter := UiCommun.bouton("Quitter", 14)
		quitter.pressed.connect(_quitter_essai)
		barre.add_child(quitter)
		var info := UiCommun.label("Clique des Échos dans l'inventaire pour les essayer (plusieurs à la fois). Rien ne change tant que tu ne valides pas.", 13, UiCommun.C_DOUX)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_centre.add_child(info)

	# Les 6 emplacements (ceux de l'essai en Mode Essai)
	var actuels := _equipement_actuel()
	var affiches := _essai if _essai_actif else actuels
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	_centre.add_child(grille)
	for i in range(1, 7):
		var uid_e := int(affiches.get(i, -1))
		var e := Sauvegarde.get_echo(uid_e) if uid_e >= 0 else {}
		var change: bool = _essai_actif and uid_e != int(actuels.get(i, -1))
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 96)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		var vb := VBoxContainer.new()
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 8
		vb.offset_top = 6
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(vb)
		vb.add_child(UiCommun.label("%d · %s%s" % [i, Echos.EMPLACEMENTS[i]["nom"], "  · ESSAI" if change else ""], 13,
			C_ESSAI if change else UiCommun.C_DOUX))
		if not e.is_empty():
			var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
			var bord := C_ESSAI if change else coul
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(bord, 0.1 if (int(e["uid"]) == _echo or change) else 0.02, 3 if change else 2))
			vb.add_child(UiCommun.label("%s  %s  +%d" % [Echos.SETS[e["set"]]["nom"], _etoiles(e), int(e["niveau"])], 15, coul))
			vb.add_child(UiCommun.label(Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 14))
		else:
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(C_ESSAI if change else Color(1, 1, 1, 0.15), 0.06 if change else 0.0, 3 if change else 2))
			vb.add_child(UiCommun.label("Vide" + (" (retiré)" if change else ""), 15, C_ESSAI if change else UiCommun.C_DOUX))
		b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
		b.pressed.connect(_clic_emplacement.bind(i, uid_e))
		grille.add_child(b)

	var liste_actuelle := Sauvegarde.echos_de(_heros)
	var bonus_actuel := Sauvegarde.bonus_echos(_heros)
	if not _essai_actif:
		# Sets actifs
		_centre.add_child(UiCommun.label("SETS ACTIFS", 15, UiCommun.C_OR))
		if bonus_actuel["sets"].is_empty():
			_centre.add_child(UiCommun.label("Aucun (2 ou 4 Échos du même set sont nécessaires).", 14, UiCommun.C_DOUX))
		var vus := _compter_sets(bonus_actuel)
		for sid in vus:
			var l := UiCommun.label(("x%d  " % vus[sid] if vus[sid] > 1 else "") + Echos.description_set(sid), 14, Color("ffb08a"))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_centre.add_child(l)
		# Stats base -> avec Échos
		_centre.add_child(UiCommun.label("STATS  (base → avec Échos)", 15, UiCommun.C_OR))
		var base := Sauvegarde.stats_base_heros(_heros)
		var fin := Sauvegarde.stats_heros(_heros)
		var gs := GridContainer.new()
		gs.columns = 3
		gs.add_theme_constant_override("h_separation", 26)
		_centre.add_child(gs)
		for p in STATS_AFFICHEES:
			var diff: int = int(fin[p[0]]) - int(base[p[0]])
			var l := UiCommun.label("%s : %d%s" % [p[1], int(fin[p[0]]), ("  (+%d)" % diff) if diff > 0 else ""], 14,
				Color("8aff9a") if diff > 0 else UiCommun.C_TEXTE)
			gs.add_child(l)
		return

	# ----- Mode Essai : comparaison actuel / essai -----
	var liste_essai := _echos_essai()
	var bonus_essai := Guilde.appliquer_aux_stats(Echos.bonus(liste_essai))
	_centre.add_child(UiCommun.label("SETS  (actuels → en essai)", 15, UiCommun.C_OR))
	var sa := _compter_sets(bonus_actuel)
	var se := _compter_sets(bonus_essai)
	if sa.is_empty() and se.is_empty():
		_centre.add_child(UiCommun.label("Aucun set actif, ni maintenant ni avec l'essai.", 14, UiCommun.C_DOUX))
	var tous_sets: Array = sa.keys()
	for k in se:
		if not k in tous_sets:
			tous_sets.append(k)
	for sid in tous_sets:
		var na := int(sa.get(sid, 0))
		var ne := int(se.get(sid, 0))
		var etat := "" if na == ne else ("  ▲ gagné" if ne > na else "  ▼ perdu")
		var coul := Color("ffb08a") if na == ne else (C_HAUSSE if ne > na else C_BAISSE)
		var txt := ("x%d → x%d  " % [na, ne]) if na != ne else (("x%d  " % ne) if ne > 1 else "")
		var l := UiCommun.label(txt + Echos.description_set(sid) + etat, 14, coul)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_centre.add_child(l)
	# Effets spéciaux des sets
	for eff in [["vol_vie", "Vol de vie", true], ["contre_chance", "Contre-attaque", true], ["etourdir_skill", "Étourdir (sorts)", true]]:
		var va := float(bonus_actuel[eff[0]]) * 100.0
		var ve := float(bonus_essai[eff[0]]) * 100.0
		if va > 0.0 or ve > 0.0:
			_centre.add_child(_ligne_effet(eff[1], "%s %%" % _n(va), "%s %%" % _n(ve), ve - va))
	if bool(bonus_actuel["immunite_debut"]) or bool(bonus_essai["immunite_debut"]):
		var ia := bool(bonus_actuel["immunite_debut"])
		var ie := bool(bonus_essai["immunite_debut"])
		_centre.add_child(_ligne_effet("Immunité 1er tour", "oui" if ia else "non", "oui" if ie else "non", float(int(ie) - int(ia))))

	_centre.add_child(UiCommun.label("STATS  (actuelles → en essai)", 15, UiCommun.C_OR))
	var base_h := Sauvegarde.stats_base_heros(_heros)
	var avant := Echos.appliquer(base_h, bonus_actuel)
	var apres := Echos.appliquer(base_h, bonus_essai)
	avant["puissance"] = int(round(UnitesData.puissance_skill(avant)))
	apres["puissance"] = int(round(UnitesData.puissance_skill(apres)))
	var gt := GridContainer.new()
	gt.columns = 4
	gt.add_theme_constant_override("h_separation", 28)
	gt.add_theme_constant_override("v_separation", 2)
	_centre.add_child(gt)
	for x in ["Stat", "Actuel", "Essai", "Écart"]:
		gt.add_child(UiCommun.label(x, 13, UiCommun.C_DOUX))
	for p in STATS_AFFICHEES + [["puissance", "Puissance des sorts"]]:
		var a := int(avant[p[0]])
		var e := int(apres[p[0]])
		var d := e - a
		var coul := C_HAUSSE if d > 0 else (C_BAISSE if d < 0 else UiCommun.C_TEXTE)
		gt.add_child(UiCommun.label(p[1], 14))
		gt.add_child(UiCommun.label(str(a), 14))
		gt.add_child(UiCommun.label(str(e), 14, coul))
		gt.add_child(UiCommun.label(("+%d" % d) if d > 0 else (str(d) if d < 0 else "="), 14, coul))
	if liste_actuelle.size() != liste_essai.size() or _nb_changements() > 0:
		var pris := _pris_a_d_autres()
		if not pris.is_empty():
			var l := UiCommun.label("⚠ Pris à un autre héros si tu valides : " + ", ".join(pris), 13, Color("ffd060"))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_centre.add_child(l)


const STATS_AFFICHEES := [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"], ["crit", "Crit %"],
	["degats_crit", "Dégâts crit %"], ["res", "RES"], ["preci", "Précision %"]]


func _ligne_effet(nom: String, avant: String, apres: String, diff: float) -> Label:
	var coul := C_HAUSSE if diff > 0.0 else (C_BAISSE if diff < 0.0 else UiCommun.C_TEXTE)
	return UiCommun.label("%s : %s → %s" % [nom, avant, apres], 14, coul)


## Set -> nombre d'activations, d'après bonus["sets"] (liste de noms).
func _compter_sets(b: Dictionary) -> Dictionary:
	var r := {}
	for nom in b["sets"]:
		for k in Echos.SETS:
			if Echos.SETS[k]["nom"] == nom:
				r[k] = int(r.get(k, 0)) + 1
	return r


func _n(x: float) -> String:
	return str(int(round(x))) if is_equal_approx(x, round(x)) else str(snappedf(x, 0.1))


# =====================================================================
# Mode Essai
# =====================================================================

## Emplacement -> uid de l'Écho porté actuellement par le héros choisi.
func _equipement_actuel() -> Dictionary:
	var r := {}
	for e in Sauvegarde.echos_de(_heros):
		r[int(e["emplacement"])] = int(e["uid"])
	return r


## Échos de l'essai (ceux qui existent encore).
func _echos_essai() -> Array:
	var l: Array = []
	for i in range(1, 7):
		var e := Sauvegarde.get_echo(int(_essai.get(i, -1)))
		if not e.is_empty():
			l.append(e)
	return l


func _nettoyer_essai() -> void:
	for i in _essai.keys():
		if Sauvegarde.get_echo(int(_essai[i])).is_empty():
			_essai.erase(i)


func _nb_changements() -> int:
	var actuels := _equipement_actuel()
	var n := 0
	for i in range(1, 7):
		if int(_essai.get(i, -1)) != int(actuels.get(i, -1)):
			n += 1
	return n


## Noms des Échos de l'essai actuellement portés par un autre héros (« Écho … (Héros) »).
func _pris_a_d_autres() -> Array:
	var r: Array = []
	for e in _echos_essai():
		var p := int(e["porteur"])
		if p >= 0 and p != _heros:
			var h := Sauvegarde.get_heros(p)
			r.append("%s (%s)" % [Echos.nom(e), UnitesData.get_unite(h["id"])["nom"] if not h.is_empty() else "?"])
	return r


func _entrer_essai() -> void:
	if _heros < 0:
		return
	_essai_actif = true
	_essai = _equipement_actuel()
	_tout()


func _quitter_essai() -> void:
	_essai_actif = false
	_essai = {}
	_tout()


## Place un Écho en essai sur son emplacement (ou l'en retire s'il y est déjà).
func _essayer(uid_echo: int) -> void:
	var e := Sauvegarde.get_echo(uid_echo)
	if e.is_empty():
		return
	var emp := int(e["emplacement"])
	if int(_essai.get(emp, -1)) == uid_echo:
		_essai.erase(emp)
	else:
		_essai[emp] = uid_echo


func _valider_essai() -> void:
	if _nb_changements() == 0:
		return
	var pris := _pris_a_d_autres()
	if pris.is_empty():
		_appliquer_essai()
		return
	var d := ConfirmationDialog.new()
	d.title = "Équiper l'essai"
	d.dialog_text = "Ces Échos sont portés par un autre héros et lui seront retirés :\n\n• %s\n\nContinuer ?" % "\n• ".join(pris)
	d.ok_button_text = "Équiper"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		_appliquer_essai())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(560, 0))


func _appliquer_essai() -> void:
	var actuels := _equipement_actuel()
	for i in range(1, 7):
		var cible := int(_essai.get(i, -1))
		var actuel := int(actuels.get(i, -1))
		if cible == actuel:
			continue
		if cible >= 0:
			Sauvegarde.equiper_echo(cible, _heros)     # remplace l'Écho du même emplacement
		elif actuel >= 0:
			Sauvegarde.retirer_echo(actuel)
	_essai_actif = false
	_essai = {}
	_tout()
	_flash("Essai équipé !", C_HAUSSE)


func _remplir_inventaire() -> void:
	for e in _zone_inv.get_children():
		e.queue_free()
	var tous: Array = Sauvegarde.liste_echos()
	var nb_sac := tous.filter(func(e): return int(e["porteur"]) < 0).size()
	var nb_portes := tous.size() - nb_sac
	# Onglets : l'actif est doré
	for v in _onglets_inv:
		var actif: bool = v == _vue_inv
		var bo: Button = _onglets_inv[v]
		bo.text = ("Sac (%d)" % nb_sac) if v == "sac" else ("Équipés sur les héros (%d)" % nb_portes)
		bo.add_theme_stylebox_override("normal", UiCommun.style_carte(UiCommun.C_OR if actif else Color(1, 1, 1, 0.15), 0.1 if actif else 0.0, 2))
		bo.add_theme_color_override("font_color", UiCommun.C_LEGENDE if actif else UiCommun.C_DOUX)
	var liste: Array = tous.filter(func(e):
		return ((int(e["porteur"]) < 0) == (_vue_inv == "sac")) \
			and (_filtre_emplacement == 0 or int(e["emplacement"]) == _filtre_emplacement) \
			and (_filtre_set == "" or e["set"] == _filtre_set))
	liste.sort_custom(func(a, b):
		var ka: Array = [int(a["etoiles"]), int(a["niveau"]), int(a["rarete"])]
		var kb: Array = [int(b["etoiles"]), int(b["niveau"]), int(b["rarete"])]
		if _tri == "niveau":
			ka = [ka[1], ka[0], ka[2]]
			kb = [kb[1], kb[0], kb[2]]
		elif _tri == "rarete":
			ka = [ka[2], ka[0], ka[1]]
			kb = [kb[2], kb[0], kb[1]]
		return ka > kb)
	_lbl_inventaire.text = "INVENTAIRE  (%d Échos)" % tous.size()
	if _vue_inv == "sac":
		var g := _nouvelle_grille()
		for e in liste:
			g.add_child(_carte_echo(e))
		if liste.is_empty():
			var vide := UiCommun.label("Aucun Écho libre ici.\nLes Échos tombent en combat : le set dépend\nde l'Acte, l'emplacement du numéro de chapitre.", 14, UiCommun.C_DOUX)
			_zone_inv.add_child(vide)
		return
	# Échos portés : un bloc par héros (le héros choisi en premier, puis l'équipe)
	var par_heros := {}
	for e in liste:
		var p := int(e["porteur"])
		if not par_heros.has(p):
			par_heros[p] = []
		par_heros[p].append(e)
	var equipe := Sauvegarde.get_equipe()
	var ordre: Array = par_heros.keys()
	ordre.sort_custom(func(x, y):
		var kx := [1 if int(x) == _heros else 0, 1 if int(x) in equipe else 0, -int(x)]
		var ky := [1 if int(y) == _heros else 0, 1 if int(y) in equipe else 0, -int(y)]
		return kx > ky)
	for p in ordre:
		var h := Sauvegarde.get_heros(int(p))
		var tete := HBoxContainer.new()
		tete.add_theme_constant_override("separation", 8)
		_zone_inv.add_child(tete)
		if not h.is_empty():
			tete.add_child(UiCommun.portrait(h["id"], 30))
		var nom: String = UnitesData.get_unite(h["id"])["nom"] if not h.is_empty() else "?"
		var lt := UiCommun.label("%s  ·  %d / 6" % [nom, Sauvegarde.echos_de(int(p)).size()], 15,
			UiCommun.C_LEGENDE if int(p) == _heros else UiCommun.C_OR)
		lt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tete.add_child(lt)
		var g := _nouvelle_grille()
		for e in par_heros[p]:
			g.add_child(_carte_echo(e))
	if liste.is_empty():
		_zone_inv.add_child(UiCommun.label("Aucun Écho équipé ici.", 14, UiCommun.C_DOUX))


func _nouvelle_grille() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	_zone_inv.add_child(g)
	return g


func _carte_echo(e: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(172, 84)
	b.focus_mode = Control.FOCUS_NONE
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	var choisi := int(e["uid"]) == _echo
	b.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE if choisi else coul, 0.1 if choisi else 0.0, 3 if choisi else 2))
	b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 7
	vb.offset_top = 4
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	vb.add_child(UiCommun.label("%d · %s" % [int(e["emplacement"]), Echos.SETS[e["set"]]["nom"]], 14, coul))
	vb.add_child(UiCommun.label("%s  +%d" % [_etoiles(e), int(e["niveau"])], 13, Color("ffd060")))
	vb.add_child(UiCommun.label(Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 13))
	var porteur := int(e["porteur"])
	if porteur >= 0 and _vue_inv != "portes":      # dans l'onglet Équipés, le porteur est déjà en titre
		var h := Sauvegarde.get_heros(porteur)
		var nom_p: String = UnitesData.get_unite(h["id"])["nom"] if not h.is_empty() else "?"
		vb.add_child(UiCommun.label("Porté : " + nom_p, 11, UiCommun.C_DOUX))
	elif e.get("verrou", false):
		vb.add_child(UiCommun.label("Verrouillé", 11, Color("8ab0d0")))
	var en_essai: bool = _essai_actif and int(_essai.get(int(e["emplacement"]), -1)) == int(e["uid"])
	if en_essai:
		b.add_theme_stylebox_override("normal", UiCommun.style_carte(C_ESSAI, 0.12, 3))
		vb.add_child(UiCommun.label("▶ EN ESSAI", 11, C_ESSAI))
	b.pressed.connect(func():
		_echo = int(e["uid"])
		if _essai_actif:
			_essayer(_echo)            # Mode Essai : un clic place (ou retire) l'Écho en essai
		_remplir_centre()
		_remplir_inventaire()
		_remplir_fiche())
	return b


func _remplir_fiche() -> void:
	for x in _fiche.get_children():
		x.queue_free()
	var e := Sauvegarde.get_echo(_echo)
	if e.is_empty():
		var l := UiCommun.label("Choisis un Écho dans l'inventaire (ou un emplacement du héros).\n\nChaque chapitre donne l'emplacement de même numéro ; chaque Acte a son set. Les boss en lâchent plus souvent et de meilleure qualité.", 14, UiCommun.C_DOUX)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(l)
		return
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	_fiche.add_child(UiCommun.label("%s  +%d" % [Echos.nom(e), int(e["niveau"])], 18, coul))
	_fiche.add_child(UiCommun.label("%s   ·   %s" % [_etoiles(e), Echos.RARETES[int(e["rarete"])]["nom"]], 14, Color("ffd060")))
	_fiche.add_child(UiCommun.label("Principale : " + Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 15))
	for s in e["secondaires"]:
		_fiche.add_child(UiCommun.label("   " + Echos.texte_stat(s["stat"], s["valeur"]), 14, Color("b8d8ff")))
	var d := UiCommun.label(Echos.description_set(e["set"]), 13, Color("ffb08a"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(d)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 6)
	_fiche.add_child(boutons)
	var porteur := int(e["porteur"])
	if _essai_actif:
		var emp := int(e["emplacement"])
		var dedans: bool = int(_essai.get(emp, -1)) == _echo
		var be := UiCommun.bouton("Retirer de l'essai" if dedans else "Essayer", 14)
		be.add_theme_color_override("font_color", C_ESSAI)
		be.pressed.connect(func():
			_essayer(_echo)
			_tout())
		boutons.add_child(be)
	elif porteur == _heros:
		var r := UiCommun.bouton("Retirer", 14)
		r.pressed.connect(func():
			Sauvegarde.retirer_echo(_echo)
			_tout())
		boutons.add_child(r)
	elif _heros >= 0:
		var h := Sauvegarde.get_heros(_heros)
		var eq := UiCommun.bouton("Équiper sur " + UnitesData.get_unite(h["id"])["nom"].trim_prefix("Le ").trim_prefix("La "), 14)
		eq.pressed.connect(func():
			Sauvegarde.equiper_echo(_echo, _heros)
			_tout())
		boutons.add_child(eq)
	if int(e["niveau"]) < Echos.NIVEAU_MAX:
		var am := UiCommun.bouton("Améliorer", 14)
		am.pressed.connect(_ameliorer)
		boutons.add_child(am)
	var b2 := HBoxContainer.new()
	b2.add_theme_constant_override("separation", 6)
	_fiche.add_child(b2)
	var v := UiCommun.bouton("Vendre (%d or)" % Echos.prix_vente(e), 14)
	v.disabled = porteur >= 0 or e.get("verrou", false)
	v.tooltip_text = "Retire-le d'abord du héros." if porteur >= 0 else ("Écho verrouillé." if e.get("verrou", false) else "")
	v.pressed.connect(func():
		Sauvegarde.vendre_echos([_echo])
		_echo = -1
		_tout())
	b2.add_child(v)
	var ver := UiCommun.bouton("Déverrouiller" if e.get("verrou", false) else "Verrouiller", 14)
	ver.pressed.connect(func():
		Sauvegarde.basculer_verrou_echo(_echo)
		_tout())
	b2.add_child(ver)


func _clic_emplacement(i: int, uid_echo: int) -> void:
	_vue_inv = "sac"          # on montre les Échos libres qui vont dans cet emplacement
	_filtre_emplacement = i
	_opt_emplacement.select(i)
	if uid_echo >= 0:
		_echo = uid_echo
	_tout()


## Ouvre la fenêtre d'amélioration (+1, ou en boucle jusqu'à +3 / +6 / +12 / +15).
func _ameliorer() -> void:
	if Sauvegarde.get_echo(_echo).is_empty():
		return
	FenetreAmeliorationEcho.ouvrir(self, _echo, _rng, _tout)


func _vente_rapide() -> void:
	var cibles: Array = []
	var total := 0
	for e in Sauvegarde.liste_echos():
		if int(e["rarete"]) <= 1 and int(e["porteur"]) < 0 and not e.get("verrou", false):
			cibles.append(int(e["uid"]))
			total += Echos.prix_vente(e)
	if cibles.is_empty():
		_flash("Rien à vendre (Normaux/Magiques non équipés).", UiCommun.C_DOUX)
		return
	var d := ConfirmationDialog.new()
	d.title = "Vente rapide"
	d.dialog_text = "Vendre %d Échos Normaux et Magiques non équipés pour %d or ?" % [cibles.size(), total]
	d.ok_button_text = "Vendre"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		Sauvegarde.vendre_echos(cibles)
		_echo = -1
		_tout())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(440, 0))


func _flash(texte: String, couleur: Color) -> void:
	var l := UiCommun.label(texte, 22, couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, 1.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.6)
	tw.tween_callback(l.queue_free)


func _etoiles(e: Dictionary) -> String:
	return "★".repeat(int(e["etoiles"]))


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
