class_name DonjonArnaud
extends Control
## EASTER EGG — « Le Donjon d'Arnaud ».
##
## Petit hommage (très simplifié) au jeu de mon ami Arnaud, « Éditeur de Donjon »
## (https://donjon.bkdaoc.com/), qui m'a donné l'envie et les infos pour créer ce jeu.
## Accès secret : toucher 5 fois de suite la lune rouge du menu principal
## (ou taper A-R-N-A-U-D au clavier sur le menu).
##
## Principe : 3 étages générés au hasard, vue du dessus, brouillard de guerre.
## Trouve la clé pour ouvrir l'escalier, bois à la fontaine, ouvre les coffres,
## et combats au tour par tour (Endurance : attaquer en coûte, encaisser en rend).
## Le Gardien du 3e étage vaincu : message de remerciement et adresse du jeu d'Arnaud.

const SCENE := "res://scenes/donjon_arnaud.tscn"
const URL_ARNAUD := "https://donjon.bkdaoc.com/"
## Héros hommage offert en fin de donjon (une seule fois).
const HEROS_OFFERT := "arnaud_riff"
const RECOMPENSE_GEMMES := 100

const L := 23          # largeur de la carte (cases)
const H := 15          # hauteur
const ETAGES := 3

enum { MUR, SOL }

const C_MUR := Color("1b1512")
const C_MUR_HAUT := Color("3a2c24")
const C_SOL := Color("5a4232")
const C_SOL2 := Color("4e392b")
const C_OR := Color("e8b54a")
const C_TEXTE := Color(0.95, 0.9, 0.82)

const MONSTRES := [
	{"nom": "Rat géant", "lettre": "r", "pv": 14, "atk": 4, "def": 0, "xp": 6, "couleur": Color("9a8a70")},
	{"nom": "Squelette", "lettre": "s", "pv": 20, "atk": 6, "def": 2, "xp": 10, "couleur": Color("e0dccc")},
	{"nom": "Gobelin", "lettre": "g", "pv": 18, "atk": 7, "def": 1, "xp": 10, "couleur": Color("7fbf4a")},
	{"nom": "Araignée des cryptes", "lettre": "a", "pv": 22, "atk": 8, "def": 1, "xp": 13, "couleur": Color("a070d0")},
	{"nom": "Goule", "lettre": "G", "pv": 30, "atk": 9, "def": 3, "xp": 18, "couleur": Color("60a090")},
]
const GARDIEN := {"nom": "Le Gardien du Donjon", "lettre": "GD", "pv": 170, "atk": 15, "def": 4, "xp": 0,
	"couleur": Color("ff4a3a"), "boss": true}

# --- état de la partie ---
var etage := 1
var carte: Array = []          # [y][x] MUR / SOL
var vu: Array = []             # [y][x] bool (brouillard)
var objets := {}               # Vector2i -> {"type": "monstre"/"coffre"/"cle"/"fontaine"/"escalier", ...}
var joueur := Vector2i.ZERO
var a_cle := false
var hero := {}
var rng := RandomNumberGenerator.new()
var torches: Array = []

# --- combat ---
var ennemi := {}
var pos_ennemi := Vector2i.ZERO
var recharge_sort := 0
var fin := false

# --- interface ---
var _vue: Control
var _stats: Label
var _journal: RichTextLabel
var _combat: PanelContainer
var _c_nom: Label
var _c_pv_e: ProgressBar
var _c_texte: Label
var _c_boutons := {}
var _temps := 0.0


func _ready() -> void:
	rng.randomize()
	var fond := ColorRect.new()
	fond.color = Color("0c0807")
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	_creer_heros()
	_construire_interface()
	_nouvel_etage()
	_log("[color=#e8b54a]Bienvenue dans le Donjon d'Arnaud ![/color]")
	_log("Flèches / ZQSD / clic sur une case voisine pour avancer. Trouve la [color=#ffd84a]clé[/color], puis l'[color=#c0c0c0]escalier[/color].")


# ---------------------------------------------------------------------
# Héros
# ---------------------------------------------------------------------

func _creer_heros() -> void:
	var nom := "Héros"
	var h := Sauvegarde.get_heros_depart()
	if not h.is_empty():
		nom = str(UnitesData.get_unite(h["id"])["nom"])
	hero = {"nom": nom, "niveau": 1, "xp": 0, "force": 12, "dex": 11, "con": 12, "int": 10,
		"pv": 0, "pv_max": 0, "end": 10, "end_max": 10, "potions": 2, "arme": 0, "armure": 0}
	_recalculer(true)


func _recalculer(soin := false) -> void:
	hero["pv_max"] = 30 + int(hero["con"]) * 3 + (int(hero["niveau"]) - 1) * 6
	hero["end_max"] = 10 + int(hero["niveau"]) - 1
	if soin:
		hero["pv"] = hero["pv_max"]
		hero["end"] = hero["end_max"]


func _xp_niveau() -> int:
	return 20 + int(hero["niveau"]) * 15


func _gagner_xp(n: int) -> void:
	hero["xp"] = int(hero["xp"]) + n
	while int(hero["xp"]) >= _xp_niveau():
		hero["xp"] = int(hero["xp"]) - _xp_niveau()
		hero["niveau"] = int(hero["niveau"]) + 1
		for s in ["force", "dex", "con", "int"]:
			hero[s] = int(hero[s]) + 1
		_recalculer()
		hero["pv"] = hero["pv_max"]
		_log(UiCommun.t("[color=#8affa0]Niveau %d ! Toutes tes caractéristiques augmentent.[/color]") % int(hero["niveau"]))


# ---------------------------------------------------------------------
# Génération d'un étage
# ---------------------------------------------------------------------

func _nouvel_etage() -> void:
	carte = []
	vu = []
	objets = {}
	torches = []
	a_cle = false
	for y in H:
		var ligne: Array = []
		var lv: Array = []
		for x in L:
			ligne.append(MUR)
			lv.append(false)
		carte.append(ligne)
		vu.append(lv)
	var salles: Array[Rect2i] = []
	var essais := 0
	while salles.size() < 7 and essais < 200:
		essais += 1
		var w := rng.randi_range(3, 6)
		var hh := rng.randi_range(3, 4)
		var r := Rect2i(rng.randi_range(1, L - w - 1), rng.randi_range(1, H - hh - 1), w, hh)
		var ok := true
		for s in salles:
			if s.grow(1).intersects(r):
				ok = false
				break
		if ok:
			salles.append(r)
	for s in salles:
		for y in range(s.position.y, s.end.y):
			for x in range(s.position.x, s.end.x):
				carte[y][x] = SOL
	for i in range(1, salles.size()):
		_couloir(_centre(salles[i - 1]), _centre(salles[i]))
	# Placement
	joueur = _centre(salles[0])
	var derniere := salles[salles.size() - 1]
	var escalier := _centre(derniere)
	if etage < ETAGES:
		objets[escalier] = {"type": "escalier"}
	else:
		objets[escalier] = {"type": "monstre", "m": _monstre(GARDIEN, 1.0)}
	if etage < ETAGES:
		objets[_case_libre(salles, 1)] = {"type": "cle"}
	objets[_case_libre(salles, 1)] = {"type": "fontaine", "pleine": true}
	for i in 2:
		objets[_case_libre(salles, 1)] = {"type": "coffre"}
	for i in 3 + etage * 2:
		var base: Dictionary = MONSTRES[mini(MONSTRES.size() - 1, rng.randi_range(0, 1 + etage))]
		objets[_case_libre(salles, 1)] = {"type": "monstre", "m": _monstre(base, 1.0 + (etage - 1) * 0.35)}
	# Torches sur les murs qui bordent le sol
	for y in range(1, H - 1):
		for x in range(1, L - 1):
			if carte[y][x] == MUR and carte[y + 1][x] == SOL and rng.randf() < 0.12:
				torches.append(Vector2i(x, y))
	_reveler()
	_maj()


func _centre(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2


func _couloir(a: Vector2i, b: Vector2i) -> void:
	var p := a
	var horizontal_d_abord := rng.randf() < 0.5
	while p != b:
		if (horizontal_d_abord and p.x != b.x) or p.y == b.y:
			p.x += signi(b.x - p.x)
		else:
			p.y += signi(b.y - p.y)
		carte[p.y][p.x] = SOL


func _case_libre(salles: Array[Rect2i], depuis: int) -> Vector2i:
	for i in 100:
		var s: Rect2i = salles[rng.randi_range(depuis, salles.size() - 1)]
		var c := Vector2i(rng.randi_range(s.position.x, s.end.x - 1), rng.randi_range(s.position.y, s.end.y - 1))
		if c != joueur and not objets.has(c):
			return c
	return Vector2i(1, 1)


func _monstre(base: Dictionary, mult: float) -> Dictionary:
	var m := base.duplicate()
	m["pv_max"] = int(round(int(base["pv"]) * mult))
	m["pv"] = m["pv_max"]
	m["atk"] = int(round(int(base["atk"]) * mult))
	m["xp"] = int(round(int(base["xp"]) * mult))
	return m


func _reveler() -> void:
	for y in range(joueur.y - 3, joueur.y + 4):
		for x in range(joueur.x - 3, joueur.x + 4):
			if x >= 0 and y >= 0 and x < L and y < H and Vector2(x - joueur.x, y - joueur.y).length() <= 3.3:
				vu[y][x] = true


# ---------------------------------------------------------------------
# Déplacement
# ---------------------------------------------------------------------

func _bouger(d: Vector2i) -> void:
	if fin or _combat.visible:
		return
	var c := joueur + d
	if c.x < 0 or c.y < 0 or c.x >= L or c.y >= H or carte[c.y][c.x] == MUR:
		return
	if objets.has(c):
		var o: Dictionary = objets[c]
		match o["type"]:
			"monstre":
				_debut_combat(c)
				return
			"escalier":
				if not a_cle:
					_log("L'escalier est scellé. Il te faut la [color=#ffd84a]clé[/color] de l'étage.")
					return
				etage += 1
				_log(UiCommun.t("[color=#e8b54a]Tu descends à l'étage %d...[/color]") % etage)
				if etage == ETAGES:
					_log("[color=#ff6a5a]Un grondement résonne : le Gardien t'attend.[/color]")
				_nouvel_etage()
				return
			"cle":
				a_cle = true
				objets.erase(c)
				_log("Tu ramasses la [color=#ffd84a]clé de l'étage[/color].")
			"coffre":
				objets.erase(c)
				_ouvrir_coffre()
			"fontaine":
				if o["pleine"]:
					o["pleine"] = false
					hero["pv"] = hero["pv_max"]
					hero["end"] = hero["end_max"]
					_log("[color=#6ac8ff]L'eau de la fontaine te rend toutes tes forces.[/color]")
				else:
					_log("La fontaine est tarie.")
				_maj()
				return
	joueur = c
	# Marcher redonne un peu d'endurance
	hero["end"] = mini(int(hero["end_max"]), int(hero["end"]) + 1)
	_reveler()
	_maj()


func _ouvrir_coffre() -> void:
	var t := rng.randi_range(0, 2)
	match t:
		0:
			hero["potions"] = int(hero["potions"]) + 1
			_log("Coffre : une [color=#ff7a9a]potion de soin[/color].")
		1:
			hero["arme"] = int(hero["arme"]) + 2
			_log("Coffre : une meilleure arme (+2 dégâts).")
		2:
			hero["armure"] = int(hero["armure"]) + 1
			_log("Coffre : une pièce d'armure (+1 défense).")


# ---------------------------------------------------------------------
# Combat au tour par tour
# ---------------------------------------------------------------------

func _debut_combat(c: Vector2i) -> void:
	pos_ennemi = c
	ennemi = objets[c]["m"]
	recharge_sort = 0
	_combat.visible = true
	_c_nom.text = ennemi["nom"] + ("  (Boss)" if ennemi.get("boss", false) else "")
	_c_nom.add_theme_color_override("font_color", ennemi["couleur"])
	_c_texte.text = UiCommun.t("%s te barre la route !") % ennemi["nom"]
	_log(UiCommun.t("[color=#ff9a7a]Combat : %s ![/color]") % ennemi["nom"])
	_maj()


func _d20() -> int:
	return rng.randi_range(1, 20)


func _action(quoi: String) -> void:
	if not _combat.visible or fin:
		return
	var txt := ""
	match quoi:
		"attaque":
			if int(hero["end"]) < 2:
				_c_texte.text = "Trop épuisé pour attaquer (2 d'Endurance). Encaisser des coups te redonne de l'endurance."
				return
			hero["end"] = int(hero["end"]) - 2
			var de := _d20()
			if de + int(hero["dex"]) / 2 < 8:
				txt = UiCommun.t("d20 = %d : ton attaque manque sa cible !") % de
			else:
				var dg := maxi(1, rng.randi_range(4, 9) + int(hero["force"]) / 2 + int(hero["arme"]) - int(ennemi["def"]))
				if de == 20:
					dg *= 2
					txt = UiCommun.t("d20 = 20, CRITIQUE ! %d dégâts.") % dg
				else:
					txt = UiCommun.t("d20 = %d : tu frappes pour %d dégâts.") % [de, dg]
				ennemi["pv"] = int(ennemi["pv"]) - dg
		"sort":
			if recharge_sort > 0 or int(hero["end"]) < 4:
				_c_texte.text = "Boule de feu : 4 d'Endurance, recharge 3 tours."
				return
			hero["end"] = int(hero["end"]) - 4
			recharge_sort = 4
			var dg := rng.randi_range(10, 16) + int(hero["int"])
			ennemi["pv"] = int(ennemi["pv"]) - dg
			txt = UiCommun.t("Boule de feu ! %d dégâts (ignore l'armure).") % dg
		"potion":
			if int(hero["potions"]) <= 0:
				_c_texte.text = "Plus de potions."
				return
			hero["potions"] = int(hero["potions"]) - 1
			var soin := 25 + int(hero["con"])
			hero["pv"] = mini(int(hero["pv_max"]), int(hero["pv"]) + soin)
			txt = UiCommun.t("Potion : +%d PV.") % soin
		"fuite":
			if ennemi.get("boss", false):
				_c_texte.text = "On ne fuit pas le Gardien !"
				return
			if _d20() + int(hero["dex"]) / 3 >= 11:
				_combat.visible = false
				_log("Tu prends la fuite.")
				_maj()
				return
			txt = "La fuite échoue !"
	if int(ennemi["pv"]) <= 0:
		_victoire(txt)
		return
	# Riposte du monstre (rage sous 30 % de PV)
	var enrage: bool = int(ennemi["pv"]) <= int(ennemi["pv_max"]) * 0.3
	var de_m := _d20()
	if de_m + 4 < 8 + int(hero["dex"]) / 3 + int(hero["armure"]):
		txt += UiCommun.t("\n%s rate son attaque.") % ennemi["nom"]
	else:
		var dm := maxi(1, rng.randi_range(int(ennemi["atk"]) - 2, int(ennemi["atk"]) + 2) - int(hero["armure"]))
		if enrage:
			dm = int(dm * 1.5)
		hero["pv"] = int(hero["pv"]) - dm
		# Encaisser redonne de l'endurance
		hero["end"] = mini(int(hero["end_max"]), int(hero["end"]) + 2)
		txt += UiCommun.t("\n%s %s %d dégâts.") % [ennemi["nom"], "EN RAGE t'inflige" if enrage else "t'inflige", dm]
	recharge_sort = maxi(0, recharge_sort - 1)
	hero["end"] = mini(int(hero["end_max"]), int(hero["end"]) + 1)
	_c_texte.text = txt
	if int(hero["pv"]) <= 0:
		_defaite()
	_maj()


func _victoire(txt: String) -> void:
	objets.erase(pos_ennemi)
	_combat.visible = false
	_log(txt)
	if ennemi.get("boss", false):
		_log("[color=#e8b54a]Le Gardien du Donjon s'effondre ![/color]")
		_fin_du_jeu()
		return
	_log(UiCommun.t("[color=#8affa0]%s est vaincu ! +%d XP[/color]") % [ennemi["nom"], int(ennemi["xp"])])
	_gagner_xp(int(ennemi["xp"]))
	if rng.randf() < 0.25:
		hero["potions"] = int(hero["potions"]) + 1
		_log("Il lâche une [color=#ff7a9a]potion[/color].")
	_maj()


func _defaite() -> void:
	fin = true
	_combat.visible = false
	_log("[color=#ff5a4a]Tu tombes au combat...[/color]")
	FenetreSimple.ouvrir(self, "Tu es tombé...", "Le donjon d'Arnaud ne pardonne pas ! Veux-tu retenter ta chance ?",
		[["Quitter", _quitter], ["Recommencer", get_tree().reload_current_scene]])


func _fin_du_jeu() -> void:
	fin = true
	_maj()
	var t := _etat_oeuf()
	var bonus := ""
	if not bool(t.get("recompense", false)):
		t["recompense"] = true
		Sauvegarde.ajouter_gemmes(RECOMPENSE_GEMMES)
		Sauvegarde.sauvegarder()
		bonus = UiCommun.t("\n\nPour avoir trouvé ce secret : +%d gemmes !") % RECOMPENSE_GEMMES
	# Le héros hommage, Arnaud Riff-de-Sang, offert une seule fois (aussi à ceux qui avaient déjà fini le donjon)
	if not bool(t.get("heros", false)) and UnitesData.existe(HEROS_OFFERT):
		t["heros"] = true
		Sauvegarde.ajouter_heros(HEROS_OFFERT)
		Sauvegarde.sauvegarder()
		bonus += UiCommun.t("\n\n%s rejoint ta collection : retrouve-le dans ton Deck !") % UnitesData.get_unite(HEROS_OFFERT)["nom"]
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 10)
	var lien := UiCommun.bouton("Jouer au jeu d'Arnaud : donjon.bkdaoc.com", 18)
	lien.custom_minimum_size = Vector2(0, 50)
	lien.pressed.connect(func(): OS.shell_open(URL_ARNAUD))
	contenu.add_child(lien)
	var f := FenetreSimple.new()
	f.largeur = 660.0
	f.titre = "Merci Arnaud !"
	f.boutons = [["Retour au menu", _quitter]]
	f.contenu = contenu
	f.texte = ("Tu as vaincu le Donjon d'Arnaud.\n\nMerci Arnaud de m'avoir permis de créer ce jeu ! C'est grâce à toi et à ton « Éditeur de Donjon » que j'ai eu l'envie et les infos pour me lancer dans Brothers of Legacy.\n\nCe petit donjon est un hommage (très simplifié) à son jeu, que tu peux découvrir ici :" + bonus)
	add_child(f)


static func _etat_oeuf() -> Dictionary:
	if not Sauvegarde.donnees.has("oeuf_arnaud") or not Sauvegarde.donnees["oeuf_arnaud"] is Dictionary:
		Sauvegarde.donnees["oeuf_arnaud"] = {}
	return Sauvegarde.donnees["oeuf_arnaud"]


func _quitter() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------------
# Interface
# ---------------------------------------------------------------------

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 14)
	add_child(marge)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	marge.add_child(h)
	_vue = Control.new()
	_vue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vue.clip_contents = true
	_vue.draw.connect(_dessiner)
	_vue.gui_input.connect(_clic_carte)
	h.add_child(_vue)

	var cote := PanelContainer.new()
	cote.custom_minimum_size = Vector2(360, 0)
	var st := UiCommun.style_panneau(Color("8a6a3a"), Color(0.09, 0.06, 0.05, 0.96))
	st.set_content_margin_all(12)
	cote.add_theme_stylebox_override("panel", st)
	h.add_child(cote)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	cote.add_child(vb)
	vb.add_child(UiCommun.label("LE DONJON D'ARNAUD", 22, C_OR))
	vb.add_child(UiCommun.label("Hommage à « Éditeur de Donjon »", 13, Color(0.7, 0.62, 0.55)))
	_stats = UiCommun.label("", 15, C_TEXTE)
	vb.add_child(_stats)
	# Croix directionnelle (téléphone)
	var croix := GridContainer.new()
	croix.columns = 3
	croix.add_theme_constant_override("h_separation", 4)
	croix.add_theme_constant_override("v_separation", 4)
	for d in [null, Vector2i.UP, null, Vector2i.LEFT, null, Vector2i.RIGHT, null, Vector2i.DOWN, null]:
		if d == null:
			var vide := Control.new()
			vide.custom_minimum_size = Vector2(54, 44)
			croix.add_child(vide)
		else:
			var fl := {Vector2i.UP: "↑", Vector2i.LEFT: "←", Vector2i.RIGHT: "→", Vector2i.DOWN: "↓"}
			var b := UiCommun.bouton(fl[d], 20)
			b.custom_minimum_size = Vector2(54, 44)
			b.pressed.connect(_bouger.bind(d))
			croix.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(croix)
	vb.add_child(centre)
	_journal = RichTextLabel.new()
	_journal.bbcode_enabled = true
	_journal.scroll_following = true
	_journal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_journal.add_theme_font_size_override("normal_font_size", 14)
	_journal.add_theme_color_override("default_color", C_TEXTE)
	vb.add_child(_journal)
	var q := UiCommun.bouton("Quitter le donjon", 16)
	q.pressed.connect(_quitter)
	vb.add_child(q)

	# Fenêtre de combat (au centre de la carte)
	_combat = PanelContainer.new()
	var sc := UiCommun.style_panneau(Color("c04030"), Color(0.08, 0.03, 0.03, 0.97))
	sc.set_content_margin_all(16)
	_combat.add_theme_stylebox_override("panel", sc)
	_combat.custom_minimum_size = Vector2(560, 0)
	_combat.visible = false
	_combat.set_anchors_preset(Control.PRESET_CENTER)
	_combat.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_combat.grow_vertical = Control.GROW_DIRECTION_BOTH
	_vue.add_child(_combat)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	_combat.add_child(cv)
	_c_nom = UiCommun.label("", 24, Color.WHITE)
	_c_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(_c_nom)
	_c_pv_e = UiCommun.barre(Color("d04030"), 520, 18)
	cv.add_child(_c_pv_e)
	_c_texte = UiCommun.label("", 16, C_TEXTE)
	_c_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_c_texte.custom_minimum_size = Vector2(520, 70)
	cv.add_child(_c_texte)
	var lb := HBoxContainer.new()
	lb.add_theme_constant_override("separation", 8)
	lb.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_child(lb)
	for a in [["attaque", "Attaquer (2 End)"], ["sort", "Boule de feu"], ["potion", "Potion"], ["fuite", "Fuir"]]:
		var b := UiCommun.bouton(a[1], 15)
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_action.bind(a[0]))
		lb.add_child(b)
		_c_boutons[a[0]] = b


func _log(t: String) -> void:
	_journal.append_text(t + "\n")


func _maj() -> void:
	_stats.text = UiCommun.t("%s  ·  Niveau %d  (XP %d/%d)\nPV %d / %d     Endurance %d / %d\nFOR %d  DEX %d  CON %d  INT %d\nArme +%d · Armure +%d · Potions %d\nÉtage %d / %d     Clé : %s") % [
		hero["nom"], hero["niveau"], hero["xp"], _xp_niveau(), maxi(0, int(hero["pv"])), hero["pv_max"],
		hero["end"], hero["end_max"], hero["force"], hero["dex"], hero["con"], hero["int"],
		hero["arme"], hero["armure"], hero["potions"], etage, ETAGES,
		("—" if etage == ETAGES else ("oui" if a_cle else "non"))]
	if _combat.visible and not ennemi.is_empty():
		_c_pv_e.max_value = int(ennemi["pv_max"])
		_c_pv_e.value = maxi(0, int(ennemi["pv"]))
		_c_boutons["sort"].text = "Boule de feu (4 End)" if recharge_sort == 0 else UiCommun.t("Boule de feu (%d)") % recharge_sort
		_c_boutons["potion"].text = UiCommun.t("Potion (%d)") % int(hero["potions"])
	_vue.queue_redraw()


func _process(delta: float) -> void:
	_temps += delta
	if not torches.is_empty():
		_vue.queue_redraw()


func _taille_case() -> float:
	return floorf(minf(_vue.size.x / L, _vue.size.y / H))


func _origine() -> Vector2:
	var t := _taille_case()
	return ((_vue.size - Vector2(L, H) * t) / 2.0).floor()


func _dessiner() -> void:
	var t := _taille_case()
	if t <= 0:
		return
	var o := _origine()
	var police := ThemeDB.fallback_font
	for y in H:
		for x in L:
			var r := Rect2(o + Vector2(x, y) * t, Vector2(t, t))
			if not vu[y][x]:
				_vue.draw_rect(r, Color.BLACK)
				continue
			if carte[y][x] == MUR:
				_vue.draw_rect(r, C_MUR)
				if y + 1 < H and carte[y + 1][x] == SOL:
					_vue.draw_rect(Rect2(r.position + Vector2(0, t * 0.7), Vector2(t, t * 0.3)), C_MUR_HAUT)
			else:
				_vue.draw_rect(r, C_SOL if (x + y) % 2 == 0 else C_SOL2)
				_vue.draw_rect(r, Color(0, 0, 0, 0.15), false, 1.0)
	# Torches (lueur vacillante)
	for c in torches:
		if not vu[c.y][c.x]:
			continue
		var p := o + (Vector2(c) + Vector2(0.5, 0.55)) * t
		var f := 0.8 + 0.2 * sin(_temps * 9.0 + c.x * 1.7)
		_vue.draw_circle(p, t * 1.1 * f, Color(1.0, 0.55, 0.15, 0.10))
		_vue.draw_circle(p, t * 0.18 * f, Color(1.0, 0.7, 0.25))
	# Objets
	for c in objets:
		if not vu[c.y][c.x]:
			continue
		var ob: Dictionary = objets[c]
		var r := Rect2(o + Vector2(c) * t, Vector2(t, t))
		var m := r.get_center()
		match ob["type"]:
			"escalier":
				for i in 4:
					_vue.draw_rect(Rect2(r.position + Vector2(t * 0.15, t * (0.15 + i * 0.18)), Vector2(t * (0.7 - i * 0.12), t * 0.12)), Color(0.75, 0.75, 0.78))
			"cle":
				_vue.draw_circle(m + Vector2(-t * 0.15, 0), t * 0.16, Color("ffd84a"))
				_vue.draw_rect(Rect2(m + Vector2(-t * 0.05, -t * 0.05), Vector2(t * 0.35, t * 0.1)), Color("ffd84a"))
			"coffre":
				_vue.draw_rect(Rect2(r.position + Vector2(t * 0.15, t * 0.3), Vector2(t * 0.7, t * 0.5)), Color("8a5a2a"))
				_vue.draw_rect(Rect2(r.position + Vector2(t * 0.15, t * 0.3), Vector2(t * 0.7, t * 0.5)), C_OR, false, 2.0)
			"fontaine":
				_vue.draw_circle(m, t * 0.38, Color(0.55, 0.55, 0.6))
				_vue.draw_circle(m, t * 0.28, Color("3aa0ff") if ob["pleine"] else Color(0.25, 0.25, 0.28))
			"monstre":
				var mo: Dictionary = ob["m"]
				_vue.draw_circle(m, t * (0.45 if mo.get("boss", false) else 0.36), Color(0.1, 0.02, 0.02))
				_vue.draw_arc(m, t * (0.45 if mo.get("boss", false) else 0.36), 0, TAU, 24, mo["couleur"], 2.0)
				var fs := int(t * 0.5)
				_vue.draw_string(police, m + Vector2(-t * 0.5, fs * 0.35), mo["lettre"], HORIZONTAL_ALIGNMENT_CENTER, t, fs, mo["couleur"])
	# Joueur
	var rj := Rect2(o + Vector2(joueur) * t, Vector2(t, t)).grow(-t * 0.08)
	_vue.draw_circle(rj.get_center(), t * 0.4, Color(0.25, 0.16, 0.05))
	_vue.draw_arc(rj.get_center(), t * 0.4, 0, TAU, 24, C_OR, 3.0)
	var fj := int(t * 0.5)
	_vue.draw_string(police, rj.get_center() + Vector2(-t * 0.5, fj * 0.35), str(hero["nom"]).substr(0, 1).to_upper() if not str(hero["nom"]).begins_with("La ") and not str(hero["nom"]).begins_with("Le ") else str(hero["nom"]).substr(3, 1).to_upper(),
		HORIZONTAL_ALIGNMENT_CENTER, t, fj, C_OR)


func _clic_carte(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var t := _taille_case()
	var c := Vector2i(((e.position - _origine()) / t).floor())
	var d := c - joueur
	if d == Vector2i.ZERO:
		return
	if absi(d.x) >= absi(d.y):
		_bouger(Vector2i(signi(d.x), 0))
	else:
		_bouger(Vector2i(0, signi(d.y)))


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed):
		return
	var dirs := {KEY_UP: Vector2i.UP, KEY_Z: Vector2i.UP, KEY_W: Vector2i.UP,
		KEY_DOWN: Vector2i.DOWN, KEY_S: Vector2i.DOWN,
		KEY_LEFT: Vector2i.LEFT, KEY_Q: Vector2i.LEFT, KEY_A: Vector2i.LEFT,
		KEY_RIGHT: Vector2i.RIGHT, KEY_D: Vector2i.RIGHT}
	if dirs.has(e.keycode):
		_bouger(dirs[e.keycode])
		get_viewport().set_input_as_handled()
	elif e.keycode == KEY_ESCAPE and not e.echo:
		_quitter()
