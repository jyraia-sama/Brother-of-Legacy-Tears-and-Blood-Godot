class_name RecapCombat
extends VBoxContainer
## RÉCAPITULATIF DE FIN DE COMBAT (affiché par EcranCombat._afficher_resultat).
##   - bandeau MVP (meilleur héros du combat, avec la raison : dégâts, soins ou encaissement) ;
##   - une carte par héros : portrait, niveau, barre d'XP qui se remplit (passages de niveau animés),
##     XP gagnée, dégâts infligés, soins donnés, dégâts encaissés, ennemis vaincus, K.O. ;
##   - le butin (or, Échos, objets…) : les lignes de récompense du mode de combat.
## Les statistiques sont calculées à partir du journal du moteur de combat.

const C_OR := Color("ffd27a")
const C_XP := Color("7ab8ff")
const C_DOUX := Color("a8968c")
const C_TEXTE := Color("f0e6dc")
const LARGEUR_CARTE := 168.0

var _cartes_xp: Array = []      # [{barre, lbl_niv, lbl_xp, etapes}]


## equipe : les héros du joueur ; journal : journal du moteur ;
## decalage : index du premier héros du joueur dans le journal (0, ou la taille du camp adverse en classée côté 2) ;
## xp_avant : uid -> {niveau, xp} relevés au début du combat ; butin : lignes de récompense à afficher.
func preparer(equipe: Array, journal: Array, pv_final: Array, decalage: int, xp_avant: Dictionary,
		butin: Array, tours: int) -> void:
	add_theme_constant_override("separation", 10)
	var stats := _calculer_stats(journal, equipe.size(), decalage)

	# --- MVP ---
	var mvp := _choisir_mvp(stats, equipe)
	if mvp >= 0:
		add_child(_bandeau_mvp(equipe[mvp], stats[mvp]))

	# --- Héros ---
	var titre := HBoxContainer.new()
	var t := _label(UiCommun.t("TON ÉQUIPE"), 18, C_OR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titre.add_child(t)
	if tours > 0:
		titre.add_child(_label(UiCommun.t("Combat en %d tours") % tours, 15, C_DOUX))
	add_child(titre)
	# Grande armée (Boss de Monde : 20 héros) : cartes compactes sur 5 colonnes, sans ascenseur interne.
	var compact := equipe.size() > 5
	var grille := GridContainer.new()
	grille.columns = clampi(equipe.size(), 1, 5)
	grille.add_theme_constant_override("h_separation", 8 if compact else 10)
	grille.add_theme_constant_override("v_separation", 6 if compact else 10)
	grille.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(grille)
	for i in equipe.size():
		var ko: bool = i < pv_final.size() and float(pv_final[i]) <= 0.0
		if compact:
			grille.add_child(_carte_compacte(equipe[i], stats[i], xp_avant, i == mvp, ko))
		else:
			grille.add_child(_carte_heros(equipe[i], stats[i], xp_avant, i == mvp, ko))

	# --- Butin ---
	if not butin.is_empty():
		add_child(HSeparator.new())
		var resultats: Array = []
		var objets: Array = []
		for l in butin:
			if _est_resultat(str(l)):
				resultats.append(l)
			else:
				objets.append(l)
		# Beaucoup de lignes : deux colonnes (à gauche les résultats, à droite le butin)
		if butin.size() > 4 and not resultats.is_empty() and not objets.is_empty():
			var cols := HBoxContainer.new()
			cols.add_theme_constant_override("separation", 24)
			add_child(cols)
			cols.add_child(_colonne(UiCommun.t("RÉSULTATS"), resultats))
			cols.add_child(VSeparator.new())
			cols.add_child(_colonne(UiCommun.t("BUTIN"), objets))
		else:
			add_child(_colonne(UiCommun.t("BUTIN ET RÉSULTATS"), butin))

	_lancer_animations.call_deferred()


## Une colonne de lignes de butin / résultats avec son titre.
func _colonne(titre: String, lignes: Array) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_stretch_ratio = 1.0
	vb.add_theme_constant_override("separation", 4)
	vb.add_child(_label(titre, 18, C_OR))
	for l in lignes:
		var lab := _label(_icone_ligne(str(l)) + str(l), 16, C_TEXTE)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(200, 0)
		vb.add_child(lab)
	return vb


## Ligne de « résultat » (dégâts, XP, record, classement…) plutôt que d'objet gagné ?
func _est_resultat(l: String) -> bool:
	var b := l.to_lower()
	for objet in ["tome", UiCommun.t("élixir"), "elixir", "coffre", "pierre", UiCommun.t("écho obtenu")]:
		if objet in b:
			return false
	for mot in ["dégâts", "degats", "xp", "record", "points", "rang", UiCommun.t("étage"), "etage", "vaincu", "abattu",
			"classement", "victoire", UiCommun.t("défaite"), "repli", "repouss", UiCommun.t("étoile"), "score", "niveau", "%"]:
		if mot in b:
			return true
	return false


# =====================================================================
# Statistiques tirées du journal
# =====================================================================

## Pour chaque héros (index 0..n-1 dans l'équipe) : degats, soins, subis, kills.
func _calculer_stats(journal: Array, n: int, decalage: int) -> Array:
	var s: Array = []
	for i in n:
		s.append({"degats": 0, "soins": 0, "subis": 0, "kills": 0})
	var dernier_attaquant := {}     # idx cible -> idx attaquant
	for ev in journal:
		match str(ev.get("t", "")):
			"degats":
				var a := int(ev.get("a", -1)) - decalage
				var c := int(ev.get("c", -1)) - decalage
				if a >= 0 and a < n:
					s[a]["degats"] += int(ev.get("v", 0))
				if c >= 0 and c < n:
					s[c]["subis"] += int(ev.get("v", 0))
				dernier_attaquant[int(ev.get("c", -1))] = int(ev.get("a", -1))
			"perte":
				var c := int(ev.get("c", -1)) - decalage
				if c >= 0 and c < n:
					s[c]["subis"] += int(ev.get("v", 0))
			"soin":
				var a := int(ev.get("a", -1)) - decalage
				if a >= 0 and a < n:
					s[a]["soins"] += int(ev.get("v", 0))
			"ko":
				var c := int(ev.get("c", -1))
				var tueur := int(dernier_attaquant.get(c, -1)) - decalage
				var victime := c - decalage
				if tueur >= 0 and tueur < n and (victime < 0 or victime >= n):
					s[tueur]["kills"] += 1
	return s


## Score du MVP : dégâts + soins (comptés un peu plus) + une part des dégâts encaissés + ennemis vaincus.
func _choisir_mvp(stats: Array, equipe: Array) -> int:
	var meilleur := -1
	var score_max := 0.0
	for i in stats.size():
		var st: Dictionary = stats[i]
		var score := float(st["degats"]) + float(st["soins"]) * 1.3 + float(st["subis"]) * 0.35 + float(st["kills"]) * 150.0
		if score > score_max:
			score_max = score
			meilleur = i
	return meilleur if equipe.size() > 1 else (0 if score_max > 0.0 else -1)


func _raison_mvp(st: Dictionary) -> String:
	var d := float(st["degats"])
	var so := float(st["soins"]) * 1.3
	var su := float(st["subis"]) * 0.35
	if so >= d and so >= su:
		return UiCommun.t("Meilleur soigneur : %d PV rendus") % int(st["soins"])
	if su > d:
		return UiCommun.t("Rempart de l'équipe : %d dégâts encaissés") % int(st["subis"])
	var t := UiCommun.t("Plus gros dégâts : %d") % int(st["degats"])
	if int(st["kills"]) > 0:
		t += UiCommun.t("  ·  %d ennemi(s) vaincu(s)") % int(st["kills"])
	return t


# =====================================================================
# Construction
# =====================================================================

func _bandeau_mvp(e: Dictionary, st: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.17, 0.04, 0.85)
	style.border_color = C_OR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", style)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(h)
	h.add_child(UiCommun.portrait(str(e.get("id", "")), 70))
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(vb)
	vb.add_child(_label(UiCommun.t("★ MVP DU COMBAT ★"), 16, C_OR))
	vb.add_child(_label(_nom(e), 24, UiCommun.couleur_rarete(str(e.get("id", "")))))
	vb.add_child(_label(_raison_mvp(st), 15, C_TEXTE))
	p.pivot_offset = Vector2(300, 45)
	p.modulate = Color(1, 1, 1, 0)
	p.ready.connect(func():
		p.pivot_offset = p.size / 2.0
		p.scale = Vector2(0.85, 0.85)
		var tw := p.create_tween().set_parallel()
		tw.tween_property(p, "modulate", Color.WHITE, 0.35)
		tw.tween_property(p, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	return p


func _carte_heros(e: Dictionary, st: Dictionary, xp_avant: Dictionary, est_mvp: bool, ko: bool) -> PanelContainer:
	var id := str(e.get("id", ""))
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(LARGEUR_CARTE, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.04, 0.05, 0.9)
	style.border_color = C_OR if est_mvp else Color(1, 1, 1, 0.15)
	style.set_border_width_all(3 if est_mvp else 1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", style)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)

	var por := UiCommun.portrait(id, 64)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ko:
		por.modulate = Color(0.5, 0.45, 0.45)
	vb.add_child(por)
	var nom := _label(_nom(e), 14, UiCommun.couleur_rarete(id))
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.clip_text = true
	nom.custom_minimum_size = Vector2(LARGEUR_CARTE - 16, 0)
	vb.add_child(nom)
	if ko:
		var lk := _label("K.O.  (XP ÷ 2)", 12, Color("ff7a6a"))
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lk)

	# XP (seulement pour les héros de la collection)
	var uid := int(e.get("uid", -1))
	var h := Sauvegarde.get_heros(uid) if uid >= 0 else {}
	if not h.is_empty() and xp_avant.has(uid):
		var av: Dictionary = xp_avant[uid]
		var etapes := _etapes_xp(int(av["niveau"]), int(av["xp"]), int(h["niveau"]), int(h["xp"]), Fusion.niveau_max(h))
		var lbl_niv := _label(UiCommun.t("Niveau %d") % int(av["niveau"]), 15, C_TEXTE)
		lbl_niv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl_niv)
		var barre := _barre(LARGEUR_CARTE - 16)
		var besoin0 := Sauvegarde.xp_heros_pour_niveau(int(av["niveau"]))
		barre.max_value = maxi(1, besoin0)
		barre.value = besoin0 if int(av["niveau"]) >= Fusion.niveau_max(h) else int(av["xp"])
		vb.add_child(barre)
		var total := 0
		for et in etapes:
			total += int(et["gain"])
		var lbl_xp := _label(UiCommun.t("+%d XP") % total if total > 0 else (UiCommun.t("Niveau max") if int(h["niveau"]) >= Fusion.niveau_max(h) else "+0 XP"), 14, C_XP)
		lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl_xp)
		_cartes_xp.append({"barre": barre, "niv": lbl_niv, "etapes": etapes, "carte": p})
	else:
		var niv := _label(UiCommun.t("Niveau %d") % int(e.get("niveau", 1)), 15, C_DOUX)
		niv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(niv)

	vb.add_child(HSeparator.new())
	vb.add_child(_ligne_stat("⚔ Dégâts", int(st["degats"]), Color("ff9a7a")))
	if int(st["soins"]) > 0:
		vb.add_child(_ligne_stat("✚ Soins", int(st["soins"]), Color("8aff9a")))
	vb.add_child(_ligne_stat("🛡 Encaissés", int(st["subis"]), Color("9ac0ff")))
	if int(st["kills"]) > 0:
		vb.add_child(_ligne_stat("☠ Vaincus", int(st["kills"]), Color("e0c0ff")))
	return p


## Carte compacte (grandes armées) : portrait à gauche ; nom, niveau, barre d'XP et stats à droite.
func _carte_compacte(e: Dictionary, st: Dictionary, xp_avant: Dictionary, est_mvp: bool, ko: bool) -> PanelContainer:
	var id := str(e.get("id", ""))
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(178, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.04, 0.05, 0.9)
	style.border_color = C_OR if est_mvp else Color(1, 1, 1, 0.12)
	style.set_border_width_all(2 if est_mvp else 1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(5)
	p.add_theme_stylebox_override("panel", style)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	var por := UiCommun.portrait(id, 40)
	por.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if ko:
		por.modulate = Color(0.5, 0.45, 0.45)
	h.add_child(por)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 1)
	h.add_child(vb)
	var nom := _label(_nom(e) + ("  K.O." if ko else ""), 12, Color("ff7a6a") if ko else UiCommun.couleur_rarete(id))
	nom.clip_text = true
	nom.custom_minimum_size = Vector2(118, 0)
	vb.add_child(nom)
	var uid := int(e.get("uid", -1))
	var hh := Sauvegarde.get_heros(uid) if uid >= 0 else {}
	if not hh.is_empty() and xp_avant.has(uid):
		var av: Dictionary = xp_avant[uid]
		var etapes := _etapes_xp(int(av["niveau"]), int(av["xp"]), int(hh["niveau"]), int(hh["xp"]), Fusion.niveau_max(hh))
		var total := 0
		for et in etapes:
			total += int(et["gain"])
		var lbl_niv := _label(UiCommun.t("Niveau %d") % int(av["niveau"]), 11, C_TEXTE)
		vb.add_child(lbl_niv)
		var barre := _barre(118)
		barre.custom_minimum_size.y = 7
		var besoin0 := Sauvegarde.xp_heros_pour_niveau(int(av["niveau"]))
		barre.max_value = maxi(1, besoin0)
		barre.value = besoin0 if int(av["niveau"]) >= Fusion.niveau_max(hh) else int(av["xp"])
		vb.add_child(barre)
		_cartes_xp.append({"barre": barre, "niv": lbl_niv, "etapes": etapes, "carte": p})
		if total > 0:
			lbl_niv.tooltip_text = UiCommun.t("+%d XP") % total
	var ligne := "⚔ %s" % _court(int(st["degats"]))
	if int(st["soins"]) > 0:
		ligne += "  ✚ %s" % _court(int(st["soins"]))
	vb.add_child(_label(ligne, 11, C_DOUX))
	return p


## 12345 -> « 12,3 k », 2500000 -> « 2,5 M »
func _court(n: int) -> String:
	if n >= 1000000:
		return ("%.1f M" % (n / 1000000.0)).replace(".", ",")
	if n >= 10000:
		return "%d k" % int(n / 1000.0)
	if n >= 1000:
		return ("%.1f k" % (n / 1000.0)).replace(".", ",")
	return str(n)


## Découpe l'XP gagnée en étapes : [{niveau, de, a, max, gain}] (une par niveau traversé).
func _etapes_xp(niv0: int, xp0: int, niv1: int, xp1: int, niv_max: int) -> Array:
	var r: Array = []
	var niv := niv0
	var xp := xp0
	var garde := 0
	while niv < niv1 and garde < 60:
		var besoin := Sauvegarde.xp_heros_pour_niveau(niv)
		r.append({"niveau": niv, "de": xp, "a": besoin, "max": besoin, "gain": maxi(0, besoin - xp)})
		niv += 1
		xp = 0
		garde += 1
	var besoin_fin := Sauvegarde.xp_heros_pour_niveau(niv)
	if niv >= niv_max:
		if r.is_empty():
			return r
		r.append({"niveau": niv, "de": besoin_fin, "a": besoin_fin, "max": besoin_fin, "gain": 0})
	elif xp1 != xp or r.is_empty():
		r.append({"niveau": niv, "de": xp, "a": xp1, "max": besoin_fin, "gain": maxi(0, xp1 - xp)})
	return r


func _lancer_animations() -> void:
	var delai := 0.5
	for c in _cartes_xp:
		_animer(c, delai)
		delai += 0.15


func _animer(c: Dictionary, delai: float) -> void:
	var barre: ProgressBar = c["barre"]
	var lbl: Label = c["niv"]
	var etapes: Array = c["etapes"]
	if etapes.is_empty() or not is_instance_valid(barre):
		return
	var tw := barre.create_tween()
	tw.tween_interval(delai)
	for k in etapes.size():
		var et: Dictionary = etapes[k]
		tw.tween_callback(func():
			barre.max_value = maxi(1, int(et["max"]))
			barre.value = int(et["de"])
			lbl.text = UiCommun.t("Niveau %d") % int(et["niveau"]))
		var duree := clampf(0.25 + 0.9 * float(int(et["a"]) - int(et["de"])) / maxf(1.0, float(et["max"])), 0.2, 1.1)
		tw.tween_property(barre, "value", float(et["a"]), duree).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if k < etapes.size() - 1:
			var niv_suivant := int(et["niveau"]) + 1
			tw.tween_callback(func():
				lbl.text = UiCommun.t("NIVEAU %d !") % niv_suivant
				lbl.add_theme_color_override("font_color", C_OR)
				Audio.son("niveau")
				_eclat(c["carte"]))
			tw.tween_interval(0.25)


func _eclat(carte: Control) -> void:
	if not is_instance_valid(carte):
		return
	carte.pivot_offset = carte.size / 2.0
	var tw := carte.create_tween()
	tw.tween_property(carte, "scale", Vector2(1.06, 1.06), 0.1)
	tw.tween_property(carte, "scale", Vector2.ONE, 0.15)


# =====================================================================
# Outils
# =====================================================================

func _nom(e: Dictionary) -> String:
	var u := UnitesData.get_unite(str(e.get("id", "")))
	return str(u.get("nom", e.get("nom", "?")))


func _icone_ligne(l: String) -> String:
	var b := l.to_lower()
	if b.begins_with(UiCommun.t("or ")) or b.begins_with("or:") or b.begins_with("gold"):
		return "💰 "
	if "écho" in b or "echo" in b:
		return "🩸 "
	if "éclat" in b or "gemme" in b:
		return "💎 "
	if "xp" in b:
		return "✦ "
	if "bestiaire" in b:
		return "📖 "
	return "•  "


func _ligne_stat(nom: String, v: int, couleur: Color) -> HBoxContainer:
	var h := HBoxContainer.new()
	var n := _label(nom, 13, C_DOUX)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(_label(_milliers(v), 13, couleur))
	return h


func _milliers(n: int) -> String:
	var s := str(absi(n))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + r


func _barre(largeur: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(largeur, 12)
	b.show_percentage = false
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0, 0, 0, 0.6)
	fond.set_corner_radius_all(4)
	var plein := StyleBoxFlat.new()
	plein.bg_color = C_XP
	plein.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", fond)
	b.add_theme_stylebox_override("fill", plein)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _label(texte: String, taille: int, couleur: Color) -> Label:
	var l := UiCommun.label(texte, taille, couleur)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
