class_name EcranCombat
extends Control
## ÉCRAN DE COMBAT : rejoue avec des animations le combat calculé par CombatMoteur.
##
## Ouvert par le plateau :
##   EcranCombat.demande = { "acte", "chapitre", "noeud", "type", "equipe": [...], "ennemis": [...] }
##   get_tree().change_scene_to_file(EcranCombat.SCENE)
## Au retour, le plateau lit EcranCombat.resultat.
##
## Autres modes (clé "mode" de la demande) :
##   "tour"       : Tours de l'Enfer / du Paradis   ("tour", "etage", "retour")
##   "boss_monde" : Boss de Monde, 20 unités contre un géant   ("boss_index", "retour")
##   "arene"      : Arène JcJ contre la défense d'un joueur   ("combat", "graine", "adversaire", "retour")
##   "donjon"     : un des 4 combats d'une expédition de Donjon   ("donjon", "niveau", "vague", "retour")
##   "marche"     : un combat de la Marche Maudite   ("type", "region", "retour")
##   "sanctuaire" : Sanctuaire du Bélier (secret), la famille du Bélier   ("epreuve", "retour")
##   "guerre"     : Guerre des Bannières, assaut d'un poste ennemi ("attaque", "graine", "adversaire", "poste", "retour")
##   "guerre_revoir" : rediffusion d'un assaut de guerre (même graine, mêmes équipes : combat identique)
##   "classee"    : Arène classée en temps réel, combat MANUEL à deux joueurs ("match", "mon_camp", "retour")
##                  -> le déroulement est géré par combat_classe.gd
##
## Boutons : vitesse x1 / x2 / x4, "Passer" (affiche directement le résultat).

const SCENE := "res://scenes/combat.tscn"
const SCENE_PLATEAU := "res://scenes/plateau.tscn"

static var demande: Dictionary = {}
static var resultat: Dictionary = {}

const C_OR := Color(0.85, 0.65, 0.3)
const C_TEXTE := Color(0.93, 0.88, 0.83)
const C_DOUX := Color(0.66, 0.59, 0.55)
const NOMS_TYPE := {"combat": "Combat", "elite": "Combat d'Élite", "gardien": "Gardien",
	"boss_chapitre": "Boss", "boss_acte": "Boss de l'Acte", "mimic": "MIMIC !"}
const NOMS_AFFL := {"brulure": "Brûlure", "gel": "Gel", "poison": "Poison", "saignement": "Saignement",
	"etourdi": "Étourdi", "silence": "Silence", "aveugle": "Aveuglé", "malediction": "Maudit"}

var _vitesse := 1.0
var _passer := false
var _fini := false
var _res: Dictionary = {}
var _infos: Array = []
var _cartes := {}             # idx -> {racine, portrait, barre, bouclier, nom, pv_max, base_pos}
var _arene: Control
var _lbl_tour: Label
var _calque: Control          # textes flottants
var _boutons_vitesse := {}
var _mode := "aventure"
var _barre_geant: ProgressBar
var _lbl_geant: Label
var _idx_geant := -1
var barre_haut: HBoxContainer   # barre du haut (le combat classé y ajoute « Abandonner »)


## Camp du joueur (Arène classée : le 2e joueur est le camp 1, affiché à gauche quand même).
func mon_camp() -> int:
	return _mon_camp


var _mon_camp := 0
var demande_combat: Dictionary = {}     # copie de la demande de CE combat


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if demande.is_empty():
		push_warning("EcranCombat ouvert sans demande : combat de test.")
		demande = _demande_test()
	_mode = str(demande.get("mode", "aventure"))
	demande_combat = demande
	_mon_camp = int(demande.get("mon_camp", 0)) if _mode == "classee" else 0
	Audio.musique(_musique_combat())
	_creer_fond()
	_creer_interface()

	CombatMoteur.ignorer_admin = _mode in ["arene", "classee", "guerre", "guerre_revoir"]
	var moteur := CombatMoteur.new(demande["equipe"], demande["ennemis"], int(demande.get("graine", 0)),
		int(demande.get("tours_max", CombatMoteur.TOURS_MAX)))
	CombatMoteur.ignorer_admin = false
	_infos = moteur.descriptif()
	if _mode == "classee":
		await get_tree().process_frame
		_placer_unites()
		var cc := CombatClasse.new()
		cc.ecran = self
		cc.moteur = moteur
		add_child(cc)
		return
	_res = moteur.combattre()
	await get_tree().process_frame
	_placer_unites()
	_rejouer()


# =====================================================================
# Construction
# =====================================================================

func _creer_fond() -> void:
	var noir := ColorRect.new()
	noir.color = Color("0e0a0b")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	var chemin := "res://assets/plateaux/fond_%02d.png" % int(demande.get("acte", 1))
	if _mode == "tour":
		chemin = "res://assets/tours/%s_combat.png" % str(demande.get("tour", "enfer"))
		noir.color = Color("1a0504") if demande.get("tour", "") == "enfer" else Color("2a2a3a")
	elif _mode == "boss_monde":
		chemin = "res://assets/boss_monde/%s.png" % str(demande["ennemis"][0]["id"])
		noir.color = Color("120608")
	elif _mode == "marche":
		chemin = "res://assets/plateaux/fond_%02d.png" % int(Marche.actes_du_jour()[int(demande.get("region", 0))])
	elif _mode == "sanctuaire" and ResourceLoader.exists(Sanctuaire.FOND):
		chemin = Sanctuaire.FOND
	elif _mode in ["guerre", "guerre_revoir"]:
		chemin = EcranGuerre.FOND_COMBAT if ResourceLoader.exists(EcranGuerre.FOND_COMBAT) else "res://assets/plateaux/fond_08.png"
		noir.color = Color("12060a")
	elif _mode == "donjon":
		chemin = "res://assets/donjons/%s.png" % str(demande.get("donjon", "feu"))
		noir.color = Color("#" + str(Donjons.DONJONS[demande.get("donjon", "feu")]["couleur"])).darkened(0.88)
	if ResourceLoader.exists(chemin):
		var img := TextureRect.new()
		img.texture = load(chemin)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.55, 0.5, 0.5)
		add_child(img)
	# Sol : ligne de séparation Avant / Arrière de chaque camp
	var sol := ColorRect.new()
	sol.color = Color(0, 0, 0, 0.35)
	sol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sol.anchor_top = 0.2
	sol.anchor_bottom = 0.92
	add_child(sol)


func _creer_interface() -> void:
	_arene = Control.new()
	_arene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arene)

	for camp in ([] if _mode == "boss_monde" else [0, 1]):
		for ligne in [["AVANT", 0.36 if camp == 0 else 0.64], ["ARRIÈRE", 0.14 if camp == 0 else 0.86]]:
			var l := _label(ligne[0], 14, Color(1, 1, 1, 0.35))
			l.anchor_left = ligne[1]
			l.anchor_right = ligne[1]
			l.anchor_top = 0.21
			l.anchor_bottom = 0.21
			l.grow_horizontal = Control.GROW_DIRECTION_BOTH
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_arene.add_child(l)

	if _mode == "boss_monde":
		for k in 4:
			var le := _label("ESCOUADE %d" % (k + 1), 13, Color(1, 1, 1, 0.4))
			le.anchor_left = 0.005
			le.anchor_right = 0.005
			le.anchor_top = 0.235 + k * 0.185
			le.anchor_bottom = le.anchor_top
			_arene.add_child(le)
		for ligne in [["ARRIÈRE", 0.13], ["AVANT", 0.36]]:
			var la := _label(ligne[0], 13, Color(1, 1, 1, 0.35))
			la.anchor_left = ligne[1]
			la.anchor_right = ligne[1]
			la.anchor_top = 0.2
			la.anchor_bottom = 0.2
			la.grow_horizontal = Control.GROW_DIRECTION_BOTH
			_arene.add_child(la)

	# Barre du haut
	var barre := PanelContainer.new()
	barre.add_theme_stylebox_override("panel", _style_panneau())
	barre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	barre.offset_left = 10
	barre.offset_right = -10
	barre.offset_top = 10
	add_child(barre)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	barre.add_child(h)
	var type: String = demande.get("type", "combat")
	var texte_titre := "ACTE %s · CHAPITRE %d — %s" % [
		ActesData.get_acte(int(demande.get("acte", 1))).get("romain", ""), int(demande.get("chapitre", 1)),
		NOMS_TYPE.get(type, "Combat")]
	if _mode == "tour":
		var n := int(demande.get("etage", 1))
		texte_titre = "%s · ÉTAGE %d — %s" % [str(Tours.TOURS[demande["tour"]]["nom"]).to_upper(), n,
			{"combat": "Combat", "elite": "Élite", "boss": "BOSS", "super": "SUPER BOSS"}[Tours.type_etage(n)]]
	elif _mode == "boss_monde":
		texte_titre = "BOSS DE MONDE — " + str(BossMonde.BOSS[int(demande.get("boss_index", 0))]["titre"]).to_upper()
	elif _mode == "marche":
		texte_titre = "LA MARCHE MAUDITE · %s — %s" % [Marche.nom_region(int(demande.get("region", 0))).to_upper(),
			Marche.TYPES[demande.get("type", "combat")]["nom"].to_upper()]
	elif _mode == "classee":
		var m: Dictionary = demande["match"]
		var moi: Dictionary = m["j1"] if mon_camp() == 0 else m["j2"]
		var lui: Dictionary = m["j2"] if mon_camp() == 0 else m["j1"]
		texte_titre = "ARÈNE CLASSÉE — %s (%d)  contre  %s (%d)" % [EnLigne.nom_complet(str(moi.get("pseudo", "?"))), int(moi.get("points", 0)),
			EnLigne.nom_complet(str(lui.get("pseudo", "?"))), int(lui.get("points", 0))]
	elif _mode in ["guerre", "guerre_revoir"]:
		texte_titre = "%sGUERRE DES BANNIÈRES — %s : %s" % ["REDIFFUSION · " if _mode == "guerre_revoir" else "",
			str(Guerre.COUCHES[int(demande.get("couche", 0))]).to_upper(), str(demande.get("adversaire", "?"))]
	elif _mode == "sanctuaire":
		texte_titre = "LE SANCTUAIRE DU BÉLIER — " + str(Sanctuaire.EPREUVES[demande["epreuve"]]["titre"]).to_upper()
	elif _mode == "donjon":
		var v := int(demande.get("vague", 0))
		texte_titre = "%s · NIVEAU %d — COMBAT %d / %d : %s" % [str(Donjons.DONJONS[demande["donjon"]]["nom"]).to_upper(),
			int(demande.get("niveau", 1)), v + 1, Donjons.VAGUES.size(), Donjons.NOMS_VAGUE[Donjons.VAGUES[v]]]
	var titre := _label(texte_titre, 22, C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(titre)
	_lbl_tour = _label("Tour 1", 20, C_TEXTE)
	h.add_child(_lbl_tour)
	for v in [1.0, 2.0, 4.0]:
		var b := _bouton("x%d" % int(v))
		b.toggle_mode = true
		b.pressed.connect(_changer_vitesse.bind(v))
		h.add_child(b)
		_boutons_vitesse[v] = b
	var passer := _bouton("Passer ▶▶")
	passer.pressed.connect(func(): _passer = true)
	h.add_child(passer)
	passer.visible = _mode != "classee"      # combat manuel : on ne saute pas le combat
	barre_haut = h
	# Vitesse mémorisée d'un combat à l'autre (le Boss de Monde garde la sienne, x2 par défaut)
	_changer_vitesse(float(Sauvegarde.get_parametre(_cle_vitesse(), 2.0 if _mode == "boss_monde" else 1.0)), false)

	_calque = Control.new()
	_calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calque)


func _cle_vitesse() -> String:
	return "vitesse_boss_monde" if _mode == "boss_monde" else "vitesse_combat"


func _changer_vitesse(v: float, memoriser := true) -> void:
	if not v in _boutons_vitesse:
		v = 1.0
	_vitesse = v
	if memoriser:
		Sauvegarde.definir_parametre(_cle_vitesse(), v)
	for cle in _boutons_vitesse:
		_boutons_vitesse[cle].button_pressed = (cle == v)


## Position (en fraction de l'écran) d'une unité selon son camp et sa place.
func _position(camp: int, place: int) -> Vector2:
	if _mode == "boss_monde":
		if camp == 1:
			return Vector2(0.73, 0.57)
		var esc := int(place / 5.0)
		var slot := place % 5
		var xs := [0.32, 0.40, 0.05, 0.13, 0.21]
		return Vector2(xs[slot] + 0.02, 0.29 + esc * 0.185)
	if mon_camp() == 1:
		camp = 1 - camp          # chaque joueur voit son équipe à gauche
	if place == 5:
		# 6e place : unité invitée de l'histoire (Kaël), entre l'Avant et l'Arrière
		return Vector2(0.25 if camp == 0 else 0.75, 0.47)
	var avant := place < 2
	var x := 0.36 if avant else 0.14
	var ys := [0.40, 0.66] if avant else [0.33, 0.56, 0.79]
	var i := place if avant else place - 2
	var y: float = ys[clampi(i, 0, ys.size() - 1)]
	if camp == 1:
		x = 1.0 - x
	return Vector2(x, y)


func _placer_unites() -> void:
	for info in _infos:
		var carte := _creer_carte(info)
		_arene.add_child(carte["racine"])
		var p := _position(info["camp"], info["place"])
		var taille: Vector2 = carte["racine"].custom_minimum_size
		carte["racine"].position = Vector2(size.x * p.x, size.y * p.y) - taille / 2.0
		carte["base_pos"] = carte["racine"].position
		_cartes[info["idx"]] = carte
		if not info["vivant"]:
			carte["racine"].modulate = Color(0.4, 0.4, 0.4, 0.5)


func _creer_carte(info: Dictionary) -> Dictionary:
	var u := UnitesData.get_unite(info["id"])
	var grand: bool = info["boss"]
	var geant: bool = info.get("geant", false)
	var petit: bool = _mode == "boss_monde" and info["camp"] == 0
	var diam := 118.0 if grand else 84.0
	var largeur := 190.0
	if geant:
		diam = 320.0
		largeur = 420.0
		_idx_geant = int(info["idx"])
	elif petit:
		diam = 40.0
		largeur = 104.0
	var racine := VBoxContainer.new()
	racine.custom_minimum_size = Vector2(largeur, diam + (40 if petit else 64))
	racine.size = racine.custom_minimum_size
	racine.alignment = BoxContainer.ALIGNMENT_CENTER
	racine.add_theme_constant_override("separation", 3)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var couleur_nom := Color("ff8a6a") if info["boss"] else (Color("ffd27a") if info["elite"] else C_TEXTE)
	var nom := _label(("%s" % info["nom"]) if petit else "%s  Nv %d" % [info["nom"], info["niveau"]], 11 if petit else (26 if geant else 14), couleur_nom)
	if petit:
		nom.clip_text = true
		nom.custom_minimum_size = Vector2(largeur, 0)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.add_theme_color_override("font_outline_color", Color.BLACK)
	nom.add_theme_constant_override("outline_size", 5)
	racine.add_child(nom)

	# Figurine (pion) de l'unité si elle existe : elle remplace le portrait rond
	var fig := "" if petit else UiCommun.chemin_figurine(info["id"])
	if fig != "":
		var h_fig := HAUTEUR_FIGURINE_BOSS if grand else HAUTEUR_FIGURINE
		if geant:
			h_fig = HAUTEUR_FIGURINE_GEANT
			largeur = h_fig * 1.05
		racine.custom_minimum_size = Vector2(largeur, h_fig + 64)
		racine.size = racine.custom_minimum_size
		var socle_fig := _creer_figurine(fig, u, h_fig, largeur, info["camp"] != mon_camp())
		racine.add_child(socle_fig["zone"])
		var barre_f := _barre(Color("c0392b") if info["camp"] != mon_camp() else Color("3fae5a"), 150.0, 12.0)
		barre_f.max_value = info["pv_max"]
		barre_f.value = info["pv"]
		barre_f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		racine.add_child(barre_f)
		var bouclier_f := _barre(Color("6ab0ff"), 150.0, 5.0)
		bouclier_f.max_value = info["pv_max"]
		bouclier_f.value = 0
		bouclier_f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		racine.add_child(bouclier_f)
		var pv_f := _label("%d / %d" % [info["pv"], info["pv_max"]], 12, C_DOUX)
		pv_f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		racine.add_child(pv_f)
		if geant:
			# Boss de Monde : sa grande barre de vie est en haut de l'écran
			barre_f.visible = false
			bouclier_f.visible = false
			pv_f.visible = false
			_creer_barre_geant(info)
		return {"racine": racine, "portrait": socle_fig["zone"], "figurine": socle_fig["image"], "barre": barre_f,
			"bouclier": bouclier_f, "pv_label": pv_f, "pv_max": info["pv_max"], "base_pos": Vector2.ZERO}

	var portrait := Panel.new()
	portrait.custom_minimum_size = Vector2(diam, diam)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.set_corner_radius_all(int(diam / 2))
	sp.bg_color = Color("#" + u["couleur"]).lerp(Color.BLACK, 0.15)
	sp.border_color = EcranBestiaire.COULEURS_ELEMENT[u["element"]]
	sp.set_border_width_all(4 if grand else 3)
	portrait.add_theme_stylebox_override("panel", sp)
	racine.add_child(portrait)
	var nom_court: String = u["nom"].trim_prefix("La ").trim_prefix("Le ").trim_prefix("L'")
	var ini := _label(nom_court.substr(0, 1), 150 if geant else (18 if petit else (40 if grand else 30)), Color.WHITE)
	ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_color_override("font_outline_color", Color.BLACK)
	ini.add_theme_constant_override("outline_size", 6)
	portrait.add_child(ini)
	UiCommun.habiller_portrait(portrait, info["id"], ini)

	var barre := _barre(Color("c0392b") if info["camp"] != mon_camp() else Color("3fae5a"), 88.0 if petit else (300.0 if geant else 150.0), 7.0 if petit else 12.0)
	barre.max_value = info["pv_max"]
	barre.value = info["pv"]
	barre.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	racine.add_child(barre)
	var bouclier := _barre(Color("6ab0ff"), 88.0 if petit else (300.0 if geant else 150.0), 3.0 if petit else 5.0)
	bouclier.max_value = info["pv_max"]
	bouclier.value = 0
	bouclier.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	racine.add_child(bouclier)
	var pv := _label("%d / %d" % [info["pv"], info["pv_max"]], 12, C_DOUX)
	pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	racine.add_child(pv)
	if petit:
		pv.visible = false
	if geant:
		barre.visible = false
		bouclier.visible = false
		pv.visible = false
		_creer_barre_geant(info)
		# Halo pulsant derrière le géant
		var tw := create_tween().set_loops()
		portrait.pivot_offset = Vector2(diam, diam) / 2.0
		tw.tween_property(portrait, "scale", Vector2(1.03, 1.03), 1.2)
		tw.tween_property(portrait, "scale", Vector2.ONE, 1.2)
	return {"racine": racine, "portrait": portrait, "barre": barre, "bouclier": bouclier,
		"pv_label": pv, "pv_max": info["pv_max"], "base_pos": Vector2.ZERO}


const HAUTEUR_FIGURINE := 165.0
const HAUTEUR_FIGURINE_BOSS := 200.0
## Figurine d'un Boss de Monde : immense face aux 20 petites unités.
const HAUTEUR_FIGURINE_GEANT := 560.0

## Figurine debout sur un petit socle (ombre + liseré de la couleur de l'élément).
## `vers_gauche` : les ennemis regardent vers la gauche (les figurines sont dessinées tournées vers la droite).
func _creer_figurine(chemin: String, u: Dictionary, h: float, largeur: float, vers_gauche: bool) -> Dictionary:
	var zone := Control.new()
	zone.custom_minimum_size = Vector2(largeur, h)
	zone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var socle := Panel.new()
	socle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0, 0, 0, 0.5)
	ss.border_color = Color(EcranBestiaire.COULEURS_ELEMENT[u["element"]], 0.85)
	ss.set_border_width_all(2)
	ss.set_corner_radius_all(40)
	socle.add_theme_stylebox_override("panel", ss)
	var sw := largeur * 0.62
	socle.size = Vector2(sw, 20)
	socle.position = Vector2((largeur - sw) / 2.0, h - 16)
	zone.add_child(socle)
	var tex: Texture2D = load(chemin)
	var ts := tex.get_size()
	var hi := h - 6.0
	var wi := minf(largeur, hi * ts.x / maxf(1.0, ts.y))
	hi = wi * ts.y / maxf(1.0, ts.x)
	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.flip_h = vers_gauche
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.size = Vector2(wi, hi)
	img.position = Vector2((largeur - wi) / 2.0, h - 8.0 - hi)       # les pieds posés sur le socle
	img.pivot_offset = Vector2(wi / 2.0, hi)
	zone.add_child(img)
	# Respiration : la figurine se dresse doucement (décalage au hasard pour ne pas bouger en rythme)
	var tw := create_tween().set_loops()
	tw.tween_interval(randf() * 1.2)
	tw.tween_property(img, "scale", Vector2(1.0, 1.025), 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(img, "scale", Vector2.ONE, 1.3).set_trans(Tween.TRANS_SINE)
	return {"zone": zone, "image": img}


## Grande barre de vie du Boss de Monde, en haut de l'écran.
func _creer_barre_geant(info: Dictionary) -> void:
	var boite := VBoxContainer.new()
	boite.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boite.anchor_left = 0.47
	boite.anchor_right = 0.99
	boite.offset_top = 78
	boite.add_theme_constant_override("separation", 2)
	boite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(boite)
	_barre_geant = _barre(Color("b0141a"), 0, 26)
	_barre_geant.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barre_geant.max_value = info["pv_max"]
	_barre_geant.value = info["pv"]
	boite.add_child(_barre_geant)
	_lbl_geant = _label("", 16, Color("ffd0c0"))
	_lbl_geant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_geant.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_geant.add_theme_constant_override("outline_size", 5)
	boite.add_child(_lbl_geant)
	_maj_texte_geant(int(info["pv"]))


func _maj_texte_geant(pv: int) -> void:
	if _lbl_geant == null:
		return
	var maxi_pv: float = _barre_geant.max_value
	_lbl_geant.text = "%s / %s PV   —   dégâts infligés : %.1f %%" % [_milliers(pv), _milliers(int(maxi_pv)),
		100.0 * (maxi_pv - pv) / maxi_pv]


func _milliers(n: int) -> String:
	var t := str(n)
	var r := ""
	while t.length() > 3:
		r = " " + t.substr(t.length() - 3) + r
		t = t.substr(0, t.length() - 3)
	return t + r


## Tremblement de tout le champ de bataille (coups du géant).
func _trembler(force: float) -> void:
	if _passer:
		return
	var tw := create_tween()
	for k in 5:
		tw.tween_property(_arene, "position", Vector2(randf_range(-force, force), randf_range(-force, force)), 0.03 / _vitesse)
	tw.tween_property(_arene, "position", Vector2.ZERO, 0.04 / _vitesse)


# =====================================================================
# Relecture du journal
# =====================================================================

func _rejouer() -> void:
	for ev in _res["journal"]:
		if _passer:
			_appliquer_sans_animation(ev)
			continue
		await _jouer(ev)
	_fin()


func _attendre(s: float) -> void:
	if _passer or s <= 0.0:
		return
	await get_tree().create_timer(s / _vitesse).timeout


## Musique selon le combat : boss de monde, boss (Aventure / Tours) ou combat normal.
func _musique_combat() -> String:
	if _mode == "boss_monde":
		return "boss_monde"
	if _mode == "sanctuaire":
		return "boss"
	var type: String = demande.get("type", "combat")
	if _mode == "tour":
		type = Tours.type_etage(int(demande.get("etage", 1)))
	if type in ["boss_chapitre", "boss_acte", "boss", "super", "mini_boss"]:
		return "boss"
	if _mode == "tour":
		return "tour_" + str(demande.get("tour", "enfer"))   # la musique de la tour continue
	return "combat"


func _jouer(ev: Dictionary) -> void:
	_bruitage(ev)
	match ev["t"]:
		"tour":
			_lbl_tour.text = "Tour %d" % ev["n"]
			await _attendre(0.25)
		"attaque":
			await _elan(ev["a"], ev["c"])
		"skill":
			if ev["a"] == _idx_geant:
				_texte_centre(ev["nom"], Color("ff7a5a"))
				_trembler(14.0)
			_texte_flottant(ev["a"], ev["nom"], Color("ffd27a"), 22, -70)
			_pulser(ev["a"])
			await _attendre(0.45)
		"degats":
			_maj_pv(ev["c"], ev["pv"], ev.get("bouclier", 0))
			var txt := str(ev["v"]) + (" !" if ev["crit"] else "")
			_texte_flottant(ev["c"], txt, Color("ffdd55") if ev["crit"] else Color("ff6a5a"), 30 if ev["crit"] else 24, -40)
			_secouer(ev["c"])
			await _attendre(0.28)
		"perte":
			_maj_pv(ev["c"], ev["pv"], -1)
			_texte_flottant(ev["c"], "-%d" % ev["v"], Color("c080ff"), 20, -30)
			await _attendre(0.2)
		"soin":
			_maj_pv(ev["c"], ev["pv"], -1)
			_texte_flottant(ev["c"], "+%d" % ev["v"], Color("6aff8a"), 22, -40)
			await _attendre(0.2)
		"rate":
			_texte_flottant(ev["c"], "Raté", Color(0.8, 0.8, 0.8), 20, -40)
			await _attendre(0.2)
		"bouclier":
			_cartes[ev["c"]]["bouclier"].value = ev["v"]
			_texte_flottant(ev["c"], "Bouclier", Color("6ab0ff"), 18, -55)
			await _attendre(0.15)
		"affliction":
			_texte_flottant(ev["c"], NOMS_AFFL.get(ev["nom"], ev["nom"]), Color("ffa040"), 18, -60)
			await _attendre(0.15)
		"buff":
			var nom_stat: String = {"atk": "ATK", "def": "DEF", "agi": "AGI", "mag": "MAG", "res": "RES"}.get(ev["stat"], ev["stat"])
			var signe := "+" if ev["valeur"] > 0 else ""
			_texte_flottant(ev["c"], "%s %s%d %%" % [nom_stat, signe, int(ev["valeur"] * 100)],
				Color("8ad0ff") if ev["valeur"] > 0 else Color("ff9a7a"), 16, -75)
			await _attendre(0.1)
		"passe":
			_texte_flottant(ev["a"], ev["raison"], Color("a0c8ff"), 18, -60)
			await _attendre(0.3)
		"info":
			_texte_flottant(ev["a"], ev["texte"], Color("ffe6a0"), 17, -80)
			await _attendre(0.2)
		"purification":
			_texte_flottant(ev["c"], "Purifié", Color("ffffff"), 16, -60)
		"ko":
			_ko(ev["c"])
			await _attendre(0.35)
		"reanimation", "renaissance":
			_revivre(ev["c"], ev["pv"])
			_texte_flottant(ev["c"], "Renaissance !" if ev["t"] == "renaissance" else "Ranimé !", Color("fff0a0"), 22, -60)
			await _attendre(0.5)
		"survie":
			_texte_flottant(ev["c"], "Tient bon !", Color("fff0a0"), 20, -60)
			_maj_pv(ev["c"], 1, -1)
			await _attendre(0.3)
		"phase":
			await _banniere_phase(ev)
		"temps_ecoule":
			_texte_centre("Le temps est écoulé…", Color("ffb070"))
			await _attendre(1.0)


## Bruitage de chaque action du combat (voir audio.gd).
func _bruitage(ev: Dictionary) -> void:
	match ev["t"]:
		"degats":
			Audio.son("coup_critique" if ev["crit"] else "coup")
		"skill":
			if ev["a"] == _idx_geant:
				Audio.son("boss_rugit")
			else:
				Audio.son("magie")
		"soin", "reanimation", "renaissance":
			Audio.son("soin")
		"bouclier":
			Audio.son("bouclier")
		"ko":
			Audio.son("ko")
		"phase":
			Audio.son("boss_rugit")


func _appliquer_sans_animation(ev: Dictionary) -> void:
	match ev["t"]:
		"tour": _lbl_tour.text = "Tour %d" % ev["n"]
		"degats": _maj_pv(ev["c"], ev["pv"], ev.get("bouclier", 0))
		"perte", "soin": _maj_pv(ev["c"], ev["pv"], -1)
		"bouclier": _cartes[ev["c"]]["bouclier"].value = ev["v"]
		"ko": _ko(ev["c"])
		"reanimation", "renaissance": _revivre(ev["c"], ev["pv"])
		"survie": _maj_pv(ev["c"], 1, -1)


# =====================================================================
# Effets visuels
# =====================================================================

func _maj_pv(idx: int, pv: int, bouclier: int) -> void:
	var c: Dictionary = _cartes[idx]
	if idx == _idx_geant and _barre_geant != null:
		_barre_geant.value = pv
		_maj_texte_geant(pv)
	var tw := create_tween()
	tw.tween_property(c["barre"], "value", pv, 0.2 / _vitesse)
	c["pv_label"].text = "%d / %d" % [pv, c["pv_max"]]
	if bouclier >= 0:
		c["bouclier"].value = bouclier


func _elan(a: int, cible: int) -> void:
	if _passer:
		return
	var ca: Dictionary = _cartes[a]
	var cc: Dictionary = _cartes[cible]
	var dir: Vector2 = (cc["base_pos"] - ca["base_pos"]) * 0.25
	if a == _idx_geant:
		dir = (cc["base_pos"] - ca["base_pos"]) * 0.06
		_trembler(8.0)
	var tw := create_tween()
	tw.tween_property(ca["racine"], "position", ca["base_pos"] + dir, 0.12 / _vitesse)
	tw.tween_property(ca["racine"], "position", ca["base_pos"], 0.14 / _vitesse)
	await _attendre(0.14)


func _secouer(idx: int) -> void:
	if _passer:
		return
	var c: Dictionary = _cartes[idx]
	var tw := create_tween()
	for k in 3:
		tw.tween_property(c["racine"], "position", c["base_pos"] + Vector2(randf_range(-7, 7), 0), 0.03 / _vitesse)
	tw.tween_property(c["racine"], "position", c["base_pos"], 0.03 / _vitesse)
	var flash := create_tween()
	c["portrait"].modulate = Color(2, 1.2, 1.2)
	flash.tween_property(c["portrait"], "modulate", Color.WHITE, 0.2 / _vitesse)


func _pulser(idx: int) -> void:
	var c: Dictionary = _cartes[idx]
	c["portrait"].pivot_offset = c["portrait"].size / 2.0
	var tw := create_tween()
	tw.tween_property(c["portrait"], "scale", Vector2(1.18, 1.18), 0.12 / _vitesse)
	tw.tween_property(c["portrait"], "scale", Vector2.ONE, 0.15 / _vitesse)


func _ko(idx: int) -> void:
	var c: Dictionary = _cartes[idx]
	c["barre"].value = 0
	c["bouclier"].value = 0
	c["pv_label"].text = "K.O."
	var tw := create_tween()
	tw.tween_property(c["racine"], "modulate", Color(0.4, 0.4, 0.4, 0.45), 0.3 / _vitesse)
	# Une figurine K.O. bascule en arrière
	if c.has("figurine"):
		var img: TextureRect = c["figurine"]
		var tf := create_tween()
		tf.tween_property(img, "rotation", (1.25 if img.flip_h else -1.25), 0.35 / _vitesse).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _revivre(idx: int, pv: int) -> void:
	var c: Dictionary = _cartes[idx]
	c["racine"].modulate = Color.WHITE
	if c.has("figurine"):
		c["figurine"].rotation = 0.0
	_maj_pv(idx, pv, 0)


func _texte_flottant(idx: int, texte: String, couleur: Color, taille: int, decalage: float) -> void:
	if _passer or not _cartes.has(idx):
		return
	var c: Dictionary = _cartes[idx]
	var l := _label(texte, taille, couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 7)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(260, 0)
	var centre: Vector2 = c["base_pos"] + c["racine"].size / 2.0
	l.position = centre + Vector2(-130 + randf_range(-12, 12), decalage)
	_calque.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 45, 0.8 / _vitesse)
	tw.tween_property(l, "modulate:a", 0.0, 0.8 / _vitesse).set_delay(0.35 / _vitesse)
	tw.chain().tween_callback(l.queue_free)


func _texte_centre(texte: String, couleur: Color) -> void:
	var l := _label(texte, 34, couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_calque.add_child(l)
	var tw := create_tween()
	tw.tween_interval(1.2 / _vitesse)
	tw.tween_property(l, "modulate:a", 0.0, 0.4 / _vitesse)
	tw.tween_callback(l.queue_free)


func _banniere_phase(ev: Dictionary) -> void:
	var flash := ColorRect.new()
	flash.color = Color(0.8, 0.05, 0.05, 0.35)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_calque.add_child(flash)
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", _style_panneau())
	panneau.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panneau.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panneau.grow_vertical = Control.GROW_DIRECTION_BOTH
	var vb := VBoxContainer.new()
	panneau.add_child(vb)
	var t1 := _label("PHASE 2 — " + str(ev["nom"]).to_upper(), 30, Color("ff6a4a"))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	var t2 := _label(ev["texte"], 18, C_TEXTE)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	_calque.add_child(panneau)
	_pulser(ev["c"])
	await _attendre(2.0)
	flash.queue_free()
	panneau.queue_free()


# =====================================================================
# Fin du combat : récompenses
# =====================================================================

func _fin() -> void:
	if _fini:
		return
	_fini = true
	if _mode == "tour":
		_fin_tour()
		return
	if _mode == "boss_monde":
		_fin_boss_monde()
		return
	if _mode == "arene":
		_fin_arene()
		return
	if _mode == "guerre":
		_fin_guerre()
		return
	if _mode == "guerre_revoir":
		var e := Guerre.etoiles(_res)
		_afficher_resultat(e > 0, ["Rediffusion de l'assaut de %s contre %s : %s" % [str(demande.get("attaquant", "?")),
			str(demande.get("adversaire", "?")), Guerre.texte_etoiles(e)]], "REDIFFUSION")
		return
	if _mode == "sanctuaire":
		_fin_sanctuaire()
		return
	if _mode == "donjon":
		_fin_donjon()
		return
	if _mode == "marche":
		_fin_marche()
		return
	var victoire: bool = _res["victoire"]
	var lignes: Array = []
	var equipe: Array = demande["equipe"]
	var type: String = demande.get("type", "combat")
	var acte := int(demande.get("acte", 1))
	var chapitre := int(demande.get("chapitre", 1))
	var or_gagne := 0
	var nouveaux: Array = []

	if victoire:
		var niveau_ennemi := int(demande["ennemis"][0]["niveau"]) if not demande["ennemis"].is_empty() else 1
		or_gagne = Rencontres.or_victoire(type, niveau_ennemi)
		or_gagne = int(round(or_gagne * (1.0 + Guilde.bonus("fortune") / 100.0)))   # bénédiction de guilde
		Sauvegarde.ajouter_or(or_gagne)
		Sauvegarde.ajouter_stat("combats_gagnes")
		lignes.append("Or : +%d" % or_gagne)
		_xp_compte(lignes, type)
		# Écho Sanguin : set de l'Acte, emplacement = numéro du chapitre
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var echo := Echos.tirer_drop(acte, chapitre, type, rng)
		if not echo.is_empty():
			Sauvegarde.ajouter_echo(echo)
			lignes.append("Écho obtenu : %s  %s  (%s)" % [Echos.nom(echo), "★".repeat(int(echo["etoiles"])),
				Echos.RARETES[int(echo["rarete"])]["nom"]])
		# Éclats de Pacte Supérieur : lâchés par les boss (garantis la première fois)
		var eclats := _eclats_boss(type, acte, chapitre)
		if eclats > 0:
			Sauvegarde.ajouter_objet(Sauvegarde.ECLAT, eclats)
			lignes.append("Éclat de Pacte Supérieur : +%d" % eclats)
		for i in equipe.size():
			var e: Dictionary = equipe[i]
			if not e.has("uid"):
				continue
			var h := Sauvegarde.get_heros(int(e["uid"]))
			if h.is_empty():
				continue
			var xp := Rencontres.xp_victoire(type, int(h["niveau"]), acte, chapitre)
			xp = int(round(xp * (1.0 + Guilde.bonus("savoir") / 100.0)))            # bénédiction de guilde
			if _res["pv_final"][i] <= 0.0:
				xp = int(xp * 0.5)       # un héros K.O. gagne moitié moins
			var niveaux := Sauvegarde.ajouter_xp_heros(int(e["uid"]), xp)
			var txt := "%s : +%d XP" % [UnitesData.get_unite(h["id"])["nom"], xp]
			if niveaux > 0:
				txt += "   NIVEAU %d !" % int(h["niveau"])
			lignes.append(txt)
	else:
		Sauvegarde.ajouter_stat("combats_perdus")
		lignes.append("L'équipe se replie pour reprendre des forces.")

	# Bestiaire : les ennemis affrontés sont découverts
	for e in demande["ennemis"]:
		if Sauvegarde.decouvrir(e["id"]):
			nouveaux.append(UnitesData.get_unite(e["id"])["nom"])
	if not nouveaux.is_empty():
		lignes.append("Nouveau dans le Bestiaire : " + ", ".join(nouveaux))

	resultat = {
		"acte": acte, "chapitre": chapitre, "noeud": demande.get("noeud", -1),
		"victoire": victoire, "pv_final": _res["pv_final"], "or": or_gagne,
	}
	_afficher_resultat(victoire, lignes)


func _fin_tour() -> void:
	var victoire: bool = _res["victoire"]
	var tour: String = demande["tour"]
	var n := int(demande["etage"])
	var lignes: Array = []
	if victoire:
		lignes.append("Étage %d vaincu !" % n)
		lignes.append_array(Tours.valider_victoire(tour, n))
		_xp_compte(lignes, Tours.type_etage(n))
		_donner_xp(lignes, func(niv: int) -> int: return Tours.xp(n, niv))
		Sauvegarde.ajouter_stat("etages_%s" % tour)
	else:
		lignes.append("L'équipe est repoussée. Renforce-toi et retente l'étage %d." % n)
	_decouvrir(lignes)
	resultat = {"mode": "tour", "victoire": victoire}
	_afficher_resultat(victoire, lignes)


func _fin_sanctuaire() -> void:
	var victoire: bool = _res["victoire"]
	var ep: String = demande["epreuve"]
	var lignes: Array = []
	if victoire:
		lignes.append_array(Sanctuaire.valider_victoire(ep))
		_xp_compte(lignes, "boss_acte")
		_donner_xp(lignes, Sanctuaire.xp)
	else:
		lignes.append(Sanctuaire.EPREUVES[ep]["defaite"])
	_decouvrir(lignes)
	resultat = {"mode": "sanctuaire", "victoire": victoire, "epreuve": ep}
	_afficher_resultat(victoire, lignes, Sanctuaire.EPREUVES[ep]["titre_victoire"] if victoire else "")


func _fin_boss_monde() -> void:
	if demande.get("guilde", false):
		_fin_boss_guilde()
		return
	var index := int(demande.get("boss_index", 0))
	var pct := 100.0 * float(_res["degats_ennemis"]) / maxf(1.0, float(_res["pv_max_ennemis"]))
	var tue: bool = _res["victoire"]
	var lignes := BossMonde.valider(index, pct, tue)
	var xp_armee := int(150 + pct * 6)
	for e in demande["equipe"]:
		if e.has("uid"):
			Sauvegarde.ajouter_xp_heros(int(e["uid"]), xp_armee)
	lignes.append("Toute l'armée : +%d XP" % xp_armee)
	_xp_compte(lignes, "boss_monde")
	_decouvrir(lignes)
	resultat = {"mode": "boss_monde", "victoire": tue, "pct": pct}
	_afficher_resultat(true, lignes, "BOSS ABATTU !" if tue else "FIN DE L'ASSAUT")


## Boss de guilde : les dégâts infligés sont ajoutés à ceux de toute la guilde (serveur).
func _fin_boss_guilde() -> void:
	var degats := int(_res["degats_ennemis"])
	var lignes: Array = ["Dégâts infligés : %d" % degats]
	var r := await EnLigne.appeler("guilde_boss_frapper", {"p_degats": degats})
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		var d: Dictionary = r.data
		lignes.append("Dégâts comptés pour la guilde : %d" % int(d["coup"]))
		lignes.append("Le titan de la guilde : %.1f %% de ses PV perdus%s" % [
			100.0 * float(d["degats"]) / maxf(1.0, float(d["pv_max"])), "  —  ABATTU !" if d["abattu"] else ""])
	elif r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "essais":
		lignes.append("Plus d'assaut disponible aujourd'hui : ces dégâts ne comptent pas.")
	else:
		lignes.append("Le serveur n'a pas pu enregistrer les dégâts : " + (str(r.erreur) if not r.ok else str(r.data)))
	var xp_armee := int(150 + 100.0 * degats / maxf(1.0, float(_res["pv_max_ennemis"])) * 6)
	for e in demande["equipe"]:
		if e.has("uid"):
			Sauvegarde.ajouter_xp_heros(int(e["uid"]), xp_armee)
	lignes.append("Toute l'armée : +%d XP" % xp_armee)
	lignes.append("Va dans l'onglet Boss de guilde pour réclamer les paliers atteints.")
	_xp_compte(lignes, "boss_monde")
	_decouvrir(lignes)
	resultat = {"mode": "boss_guilde", "degats": degats}
	_afficher_resultat(true, lignes, "FIN DE L'ASSAUT")


## Arène : le résultat est envoyé au serveur, qui calcule les points et les Insignes.
func _fin_arene() -> void:
	var victoire: bool = _res["victoire"]
	var lignes: Array = ["Envoi du résultat…"]
	var r := await EnLigne.appeler("arene_terminer", {"p_combat": demande["combat"], "p_victoire": victoire})
	lignes.clear()
	var adv: String = demande.get("adversaire", "")
	if adv != "":
		lignes.append(("Tu as vaincu la défense de %s." if victoire else "La défense de %s t'a repoussé.") % adv)
	if r.ok and r.data is Dictionary and r.data.get("ok", false):
		var d: Dictionary = r.data
		var pts := int(d["points"])
		lignes.append("Points d'Arène : %s%d  (total %d, rang %d)" % ["+" if pts >= 0 else "", pts, int(d["points_total"]), int(d["rang"])])
		lignes.append("Insignes d'Arène : +%d" % int(d["insignes"]))
		if victoire:
			Sauvegarde.ajouter_stat("combats_gagnes")
			_xp_compte(lignes, "arene")
		Sauvegarde.ajouter_stat("combats_arene")
	else:
		lignes.append("Le résultat n'a pas pu être envoyé : %s" % (r.erreur if not r.ok else str(r.data.get("erreur", "?"))))
	resultat = {"mode": "arene", "victoire": victoire}
	_afficher_resultat(victoire, lignes)


## Guerre des Bannières : les étoiles sont envoyées au serveur, qui garde le meilleur résultat du poste.
func _fin_guerre() -> void:
	var victoire: bool = _res["victoire"]
	var e := Guerre.etoiles(_res)
	var lignes: Array = ["Envoi du résultat…"]
	var r := await EnLigne.appeler("guerre_terminer", {"p_attaque": demande["attaque"], "p_etoiles": e})
	lignes.clear()
	var adv: String = str(demande.get("adversaire", "?"))
	lignes.append(("Tu as pris le poste de %s : %s" % [adv, Guerre.texte_etoiles(e)]) if victoire
		else ("%s a repoussé ton assaut." % adv))
	if victoire:
		lignes.append("★ victoire   ★★ 3 unités debout ou plus   ★★★ aucune perte")
	if r.ok and r.data is Dictionary and str(r.data.get("code", "")) == "ok":
		var gain := int(r.data["gain"])
		if gain > 0:
			lignes.append("+%d étoile%s pour ta guilde (total %d)." % [gain, "s" if gain > 1 else "", int(r.data["total"])])
		else:
			lignes.append("Pas d'étoile nouvelle : ce poste avait déjà été pris aussi bien.")
		if victoire:
			Sauvegarde.ajouter_stat("combats_gagnes")
			_xp_compte(lignes, "arene")
	else:
		lignes.append("Le résultat n'a pas pu être envoyé : %s" % (r.erreur if not r.ok else Guerre.texte_erreur(str(r.data.get("code", "?")))))
	lignes.append("Les unités de cet assaut sont épuisées jusqu'à demain.")
	resultat = {"mode": "guerre", "victoire": victoire, "etoiles": e}
	_afficher_resultat(victoire, lignes, ("VICTOIRE  " + Guerre.texte_etoiles(e)) if victoire else "")


## Marche Maudite : le résultat est appliqué à la marche, puis retour à la carte.
func _fin_marche() -> void:
	var victoire: bool = _res["victoire"]
	var lignes: Array = []
	_decouvrir(lignes)
	var l2 := Marche.apres_combat(_res)
	lignes = l2 + lignes
	Sauvegarde.ajouter_stat("combats_gagnes" if victoire else "combats_perdus")
	if victoire:
		_xp_compte(lignes, "combat" if demande.get("type", "combat") == "combat" else "elite")
	resultat = {"mode": "marche", "victoire": victoire}
	var fin := not Marche.en_cours()
	_afficher_resultat(victoire, lignes, ("MARCHE ACCOMPLIE !" if victoire else "LA MARCHE S'ACHÈVE") if fin else "")


## Donjon : 4 combats d'affilée, les PV restants passent au combat suivant.
func _fin_donjon() -> void:
	var victoire: bool = _res["victoire"]
	var d: String = demande["donjon"]
	var n := int(demande["niveau"])
	var lignes: Array = []
	_decouvrir(lignes)
	if not victoire:
		Sauvegarde.ajouter_stat("combats_perdus")
		lignes.push_front("L'expédition échoue au combat %d / %d. Renforce-toi et retente ta chance." % [
			int(demande.get("vague", 0)) + 1, Donjons.VAGUES.size()])
		Donjons.terminer()
		resultat = {"mode": "donjon", "victoire": false}
		_afficher_resultat(false, lignes, "EXPÉDITION ÉCHOUÉE")
		return
	Sauvegarde.ajouter_stat("combats_gagnes")
	if not Donjons.derniere_vague():
		Donjons.vague_suivante(_res["pv_final"])
		# Enchaînement automatique : pas de fenêtre entre les vagues, le combat suivant démarre seul
		var suivant: String = Donjons.NOMS_VAGUE[Donjons.VAGUES[int(Donjons.expedition["vague"])]]
		resultat = {"mode": "donjon", "victoire": true}
		Audio.son("or")
		_texte_centre("Combat %d / %d gagné !  Prochain : %s" % [int(demande["vague"]) + 1, Donjons.VAGUES.size(), suivant], Color("ffd27a"))
		await get_tree().create_timer(1.6).timeout
		EcranCombat.demande = Donjons.demande_combat()
		get_tree().change_scene_to_file(SCENE)
		return
	lignes.push_front("%s — niveau %d terminé !" % [Donjons.DONJONS[d]["nom"], n])
	lignes.append_array(Donjons.valider_victoire(d, n))
	_xp_compte(lignes, "donjon")
	_donner_xp(lignes, func(niv: int) -> int: return Donjons.xp(n, niv))
	Donjons.terminer()
	resultat = {"mode": "donjon", "victoire": true}
	_afficher_resultat(true, lignes, "DONJON TERMINÉ !")


## XP de compte d'un combat gagné (+ message si le niveau monte).
func _xp_compte(lignes: Array, cle: String) -> void:
	if Sauvegarde.niveau_compte_max_atteint():
		return
	var xp := int(Sauvegarde.XP_COMPTE_VICTOIRE.get(cle, 10))
	var niveaux := Sauvegarde.ajouter_xp_compte(xp)
	lignes.append("XP de compte : +%d" % xp)
	if niveaux > 0:
		lignes.append("NIVEAU DE COMPTE %d ! Stamina max %d — stamina rechargée !" % [
			Sauvegarde.get_niveau_compte(), Sauvegarde.get_stamina_max()])


## XP pour chaque héros de l'équipe (moitié pour les K.O.).
func _donner_xp(lignes: Array, calcul: Callable) -> void:
	var equipe: Array = demande["equipe"]
	for i in equipe.size():
		var e: Dictionary = equipe[i]
		if not e.has("uid"):
			continue
		var h := Sauvegarde.get_heros(int(e["uid"]))
		if h.is_empty():
			continue
		var xp: int = calcul.call(int(h["niveau"]))
		if _res["pv_final"][i] <= 0.0:
			xp = int(xp * 0.5)
		var niveaux := Sauvegarde.ajouter_xp_heros(int(e["uid"]), xp)
		var txt := "%s : +%d XP" % [UnitesData.get_unite(h["id"])["nom"], xp]
		if niveaux > 0:
			txt += "   NIVEAU %d !" % int(h["niveau"])
		lignes.append(txt)


func _decouvrir(lignes: Array) -> void:
	var nouveaux: Array = []
	for e in demande["ennemis"]:
		if Sauvegarde.decouvrir(e["id"]):
			nouveaux.append(UnitesData.get_unite(e["id"])["nom"])
	if not nouveaux.is_empty():
		lignes.append("Nouveau dans le Bestiaire : " + ", ".join(nouveaux))


## Éclats lâchés par un boss. Premier passage : garanti ; ensuite : chance.
const ECLATS_BOSS := {
	"boss_chapitre": {"premiere": 1, "chance": 0.30, "rejoue": 1},
	"boss_acte": {"premiere": 3, "chance": 0.60, "rejoue": 1},
}

func _eclats_boss(type: String, acte: int, chapitre: int) -> int:
	if not ECLATS_BOSS.has(type):
		return 0
	var r: Dictionary = ECLATS_BOSS[type]
	if not ActesData.est_termine(acte, chapitre):
		return int(r["premiere"])
	return int(r["rejoue"]) if randf() < float(r["chance"]) else 0


func _afficher_resultat(victoire: bool, lignes: Array, titre_force := "", texte_bouton := "Continuer", action := Callable()) -> void:
	if action.is_valid():
		Audio.son("or")
	else:
		Audio.musique("victoire" if victoire else "defaite")
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.55)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", _style_panneau())
	panneau.custom_minimum_size = Vector2(520, 0)
	centre.add_child(panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panneau.add_child(vb)
	var t := _label(titre_force if titre_force != "" else ("VICTOIRE" if victoire else "DÉFAITE"), 44, C_OR if victoire else Color("d0453a"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(HSeparator.new())
	for l in lignes:
		var lab := _label(l, 18, C_TEXTE)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(lab)
	var b := _bouton(texte_bouton)
	b.custom_minimum_size = Vector2(200, 44)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var retour: String = demande.get("retour", SCENE_PLATEAU)
	if action.is_valid():
		b.pressed.connect(action)
	else:
		b.pressed.connect(func(): get_tree().change_scene_to_file(retour))
	vb.add_child(b)
	# Donjon : on peut abandonner l'expédition entre deux combats (la stamina est perdue)
	if action.is_valid() and _mode == "donjon":
		var abandon := _bouton("Abandonner l'expédition")
		abandon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		abandon.pressed.connect(func():
			Donjons.terminer()
			get_tree().change_scene_to_file(retour))
		vb.add_child(abandon)


# =====================================================================
# Outils
# =====================================================================

func _demande_test() -> Dictionary:
	var plat := PlateauGenerateur.generer(1, 1)
	return {"acte": 1, "chapitre": 1, "noeud": plat["boss"], "type": "boss_chapitre",
		"equipe": [{"id": "samourai_rouge", "niveau": 3}, {"id": "chevalier", "niveau": 3},
			{"id": "archer", "niveau": 3}, {"id": "clerc", "niveau": 3}],
		"ennemis": Rencontres.generer(1, 1, plat["noeuds"][plat["boss"]])}


func _style_panneau() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.02, 0.03, 0.94)
	s.border_color = C_OR
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(14)
	return s


func _barre(couleur: Color, largeur: float, hauteur: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(largeur, hauteur)
	b.show_percentage = false
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0, 0, 0, 0.6)
	fond.set_corner_radius_all(3)
	var plein := StyleBoxFlat.new()
	plein.bg_color = couleur
	plein.set_corner_radius_all(3)
	b.add_theme_stylebox_override("background", fond)
	b.add_theme_stylebox_override("fill", plein)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _label(texte: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = texte
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _bouton(texte: String) -> Button:
	var b := Button.new()
	b.text = texte
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(56, 36)
	b.add_theme_font_size_override("font_size", 17)
	return b
