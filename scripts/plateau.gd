extends Node2D
## Plateau de jeu d'un chapitre : le pion avance de case en case (nœuds reliés).
##
## - Clique sur une case VOISINE (cercle qui pulse) pour y déplacer le pion.
## - Glisser avec la souris : regarder le plateau.  Molette : zoom.
## - Espace : recentrer sur le pion.  Échap : retour aux chapitres.
## - Les cases lointaines sont cachées (brouillard) jusqu'à ce qu'on s'en approche.
##
## Le plateau est créé par PlateauGenerateur (toujours le même pour un chapitre).
## Les combats s'ouvrent dans l'écran de combat (EcranCombat) : voir _lancer_combat().
## Les PV de l'équipe sont conservés d'un combat à l'autre pendant le chapitre
## (Autel de soin = PV pleins, Piège = -15 %).

const T := PlateauGenerateur.Type

const SCENE_CHAPITRES := "res://scenes/carte_monde.tscn"
const ECART := Vector2(190, 115)      # distance en pixels entre deux cases
const RAYON := 28.0                   # taille d'une case
const BROUILLARD := true              # false = tout le plateau visible
const VISION := 2                     # nombre de cases visibles autour du chemin parcouru

# Couleur d'ambiance de chaque Acte (chemins, bordures)
const ACCENTS := [
	Color("d8743a"), Color("8fa3c0"), Color("e0903a"), Color("5fc8b0"),
	Color("e05a2a"), Color("b4a8e8"), Color("8ad07a"), Color("ff4a3a"),
	Color("f0c070"), Color("c0a080"), Color("d060a0"), Color("ffb040"),
	Color("c870e0"),
]

const COULEURS := {
	T.DEPART: Color("6a6560"),
	T.COMBAT: Color("8a2a22"),
	T.ELITE: Color("c0601a"),
	T.GARDIEN: Color("3e5a8a"),
	T.BOSS: Color("5a0a0a"),
	T.COFFRE: Color("b8862a"),
	T.SOIN: Color("2f7a4a"),
	T.MYSTERE: Color("5a4a8a"),
	T.PIEGE: Color("5a4a3a"),
}

## Chance qu'un coffre (non Mimic) contienne aussi un Sceau Sauvage (familiers)
const CHANCE_SCEAU_COFFRE := 0.35

var acte := 1
var chapitre := 1
var plateau: Dictionary
var noeuds: Array

var courant := 0
var precedent := 0
var defaites_case := {}       # défaites sur chaque case (pour les conseils)
var termines := {}      # cases déjà résolues (combat gagné, coffre ouvert...)
var chemin: Array = []  # cases parcourues, dans l'ordre (pour rebrousser chemin d'un cul-de-sac)
var visites := {}       # cases où le pion est passé
var reveles := {}       # cases visibles
var or_gagne := 0
var pv_equipe := {}     # uid (texte) -> PV restants en % (1.0 = pleins)
var benediction := false
const RECUPERATION_APRES_VICTOIRE := 0.30
var boite_equipe: VBoxContainer

var pion_pos := Vector2.ZERO
const IMAGE_PION := "res://assets/plateaux/pion_aine.png"
const HAUTEUR_PION := 120.0    # hauteur de la figurine à l'écran
var _pion_tex: Texture2D = null
## CALQUES DE DESSIN (performances, surtout sur le web) : le décor (chemins, socles, cases) ne change
## que quand on avance ; il est dessiné UNE fois sur ce nœud et redessiné seulement s'il change.
## Ce qui bouge à chaque image est sur deux petits calques : _sous (halo de la Larme, lueur des boss)
## et _dessus (pénombre autour du grand frère, anneaux, survol, figurine, poussière).
var _sous: Node2D
var _dessus: Node2D
var _etat_decor := ""
var _ombre: GradientTexture2D
var _pion_charge := false
var _pion_gauche := false      # la figurine regarde vers la gauche
var _inclinaison := 0.0        # la figurine se penche pendant le saut
var _ecrase := 0.0             # petit tassement à l'atterrissage (1 -> 0)
var _poussiere: Array = []     # nuages de poussière : {pos, vel, vie, vie_max, taille}
const PORTEE_LUMIERE := 260.0  # rayon du halo bleu de la Larme
const COULEUR_LARME := Color(0.45, 0.65, 1.0)
var _halo: GradientTexture2D = null

# Miniatures des cases (planche 38) : assets/plateaux/cases/<nom>.png
const DOSSIER_MINIATURES := "res://assets/plateaux/cases/"
const MINIATURES := {
	T.DEPART: "depart", T.COMBAT: "combat", T.ELITE: "elite", T.GARDIEN: "gardien", T.BOSS: "boss",
	T.COFFRE: "coffre", T.SOIN: "soin", T.MYSTERE: "mystere", T.PIEGE: "piege",
}
const HAUTEUR_MINIATURE := 2.3     # hauteur de la miniature, en multiple du rayon de la case
var _miniatures := {}
var saut := 0.0
var en_mouvement := false
var bloque := false     # une fenêtre est ouverte
var survol := -1
var temps := 0.0

var camera: Camera2D
var camera_libre := false
var appui := false
var glisse := false
var appui_pos := Vector2.ZERO

var accent := Color.WHITE
var police: Font

# HUD
var hud: CanvasLayer
var lbl_titre: Label
var lbl_or: Label
var lbl_stamina: Label
var info: PanelContainer
var info_titre: Label
var info_sous: Label
var info_texte: Label


func _ready() -> void:
	Tutoriel.astuce("plateau", self)      # astuce à la première visite
	ActesData.charger()
	acte = ActesData.acte_courant
	chapitre = ActesData.chapitre_courant
	plateau = PlateauGenerateur.generer(acte, chapitre)
	noeuds = plateau["noeuds"]
	accent = ACCENTS[clampi(acte - 1, 0, ACCENTS.size() - 1)]
	police = ThemeDB.fallback_font

	courant = plateau["depart"]
	precedent = courant
	termines[courant] = true
	visites[courant] = true
	chemin.append(courant)
	var reprise := _restaurer_etat()
	var retour_combat: Dictionary = EcranCombat.resultat.duplicate()
	EcranCombat.resultat = {}
	var revient_de_combat: bool = not retour_combat.is_empty() and int(retour_combat.get("acte", 0)) == acte \
		and int(retour_combat.get("chapitre", 0)) == chapitre and int(retour_combat.get("noeud", -1)) == courant
	_maj_brouillard()

	_creer_fond()
	_creer_calques()
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	pion_pos = _pos(courant)
	camera.position = pion_pos + Vector2(250, 0)
	_creer_hud()
	if revient_de_combat:
		_apres_combat(retour_combat)
		return
	# Scène d'histoire du début du chapitre (première visite seulement)
	if DialoguesData.a_dialogue(acte, chapitre, "debut") and not DialoguesData.vu(acte, chapitre, "debut"):
		bloque = true
		await FenetreDialogue.jouer(self, acte, chapitre, "debut")
		bloque = false
	if reprise:
		_message("Reprise", "Tu reprends l'exploration là où tu l'avais laissée.", _reprendre_case)
	else:
		_enregistrer_etat()


# ---------------------------------------------------------------
# Sauvegarde du plateau en cours (reprise si on quitte le jeu)
# ---------------------------------------------------------------

func _terminer(id: int) -> void:
	termines[id] = true
	_enregistrer_etat()


func _enregistrer_etat() -> void:
	var types_modifies := {}
	var mimics := {}          # coffres déjà tirés : id -> Mimic ou non
	for n in noeuds:
		if n.has("mimic"):
			mimics[str(n["id"])] = n["mimic"]
	var d_origine: Array = PlateauGenerateur.generer(acte, chapitre)["noeuds"]
	for n in noeuds:
		if n["type"] != d_origine[n["id"]]["type"]:
			types_modifies[str(n["id"])] = n["type"]
	Sauvegarde.enregistrer_plateau({
		"acte": acte,
		"chapitre": chapitre,
		"courant": courant,
		"precedent": precedent,
		"termines": termines.keys(),
		"visites": visites.keys(),
		"chemin": chemin,
		"or_gagne": or_gagne,
		"types_modifies": types_modifies,
		"mimics": mimics,
		"pv_equipe": pv_equipe,
		"benediction": benediction,
	})


## Renvoie true si un plateau en cours a été restauré.
func _restaurer_etat() -> bool:
	var e := Sauvegarde.get_plateau_en_cours(acte, chapitre)
	if e.is_empty():
		return false
	courant = int(e["courant"])
	precedent = int(e.get("precedent", courant))
	or_gagne = int(e.get("or_gagne", 0))
	for id in e.get("termines", []):
		termines[int(id)] = true
	for id in e.get("visites", []):
		visites[int(id)] = true
	chemin.clear()
	for id in e.get("chemin", []):
		chemin.append(int(id))
	pv_equipe = e.get("pv_equipe", {}).duplicate()
	benediction = bool(e.get("benediction", false))
	var tm: Dictionary = e.get("types_modifies", {})
	for cle in tm:
		noeuds[int(cle)]["type"] = int(tm[cle])
	var mi: Dictionary = e.get("mimics", {})
	for cle in mi:
		noeuds[int(cle)]["mimic"] = bool(mi[cle])
	return courant != plateau["depart"] or termines.size() > 1


## Si on avait quitté le jeu au milieu d'une case (combat pas fini...), on la rejoue.
func _reprendre_case() -> void:
	if not termines.has(courant):
		_evenement(courant)


# ---------------------------------------------------------------
# Boucle
# ---------------------------------------------------------------

func _process(delta: float) -> void:
	temps += delta
	_ecrase = maxf(0.0, _ecrase - delta * 5.0)
	for i in range(_poussiere.size() - 1, -1, -1):
		var d: Dictionary = _poussiere[i]
		d["vie"] -= delta
		if d["vie"] <= 0.0:
			_poussiere.remove_at(i)
			continue
		d["pos"] += d["vel"] * delta
		d["vel"] *= exp(-5.0 * delta)
	if not camera_libre and not glisse:
		var cible := pion_pos + Vector2(250, 0) / camera.zoom.x
		camera.position = camera.position.lerp(cible, 1.0 - exp(-4.0 * delta))
	_limiter_camera()
	# Le décor n'est redessiné que s'il a changé (case atteinte, brouillard levé, case terminée)
	var etat := "%d|%d|%d|%d" % [courant, reveles.size(), visites.size(), termines.size()]
	if etat != _etat_decor:
		_etat_decor = etat
		queue_redraw()
	_sous.queue_redraw()
	_dessus.queue_redraw()


func _limiter_camera() -> void:
	var mini_ := Vector2(INF, INF)
	var maxi_ := Vector2(-INF, -INF)
	for n in noeuds:
		var p := _pos(n["id"])
		mini_ = mini_.min(p)
		maxi_ = maxi_.max(p)
	camera.position = camera.position.clamp(mini_ - Vector2(200, 250), maxi_ + Vector2(200, 250))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_retour()
		elif event.keycode == KEY_SPACE:
			camera_libre = false
		return

	if bloque:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				appui = true
				glisse = false
				appui_pos = mb.position
			else:
				if appui and not glisse:
					_clic(get_global_mouse_position())
				appui = false
				glisse = false
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.1)

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if appui and (mm.position - appui_pos).length() > 12.0:
			glisse = true
			camera_libre = true
		if glisse:
			camera.position -= mm.relative / camera.zoom.x
		else:
			_maj_survol(get_global_mouse_position())


func _zoom(facteur: float) -> void:
	var z := clampf(camera.zoom.x * facteur, 0.45, 1.5)
	camera.zoom = Vector2(z, z)


# ---------------------------------------------------------------
# Déplacement
# ---------------------------------------------------------------

func _clic(p: Vector2) -> void:
	var id := _noeud_a(p)
	if id < 0 or en_mouvement:
		return
	if id == courant:
		camera_libre = false
		# Combat pas encore lancé sur la case actuelle (ex : stamina manquante) : on le relance
		if PlateauGenerateur.est_combat(int(noeuds[id]["type"])) and not termines.has(id) and id != plateau.get("depart", -1):
			_lancer_combat(id)
		return
	if _accessible(id):
		if PlateauGenerateur.est_combat(int(noeuds[id]["type"])) and not _assez_de_stamina(id):
			return
		_deplacer(id)


## Règle de déplacement : on avance seulement vers une case voisine NON terminée
## et qui ne se trouve pas en arrière (pas de retour en arrière).
func _accessible(id: int, depuis := -1) -> bool:
	if depuis < 0:
		depuis = courant
	if not id in noeuds[depuis]["voisins"] or not reveles.has(id):
		return false
	if termines.has(id):
		return false
	var x_depuis: float = noeuds[depuis]["pos"].x
	var x_cible: float = noeuds[id]["pos"].x
	return x_cible > x_depuis - 0.6


func _a_des_sorties(depuis: int) -> bool:
	for v in noeuds[depuis]["voisins"]:
		if _accessible(v, depuis):
			return true
	return false


## Appelée quand une case est résolue : si c'est une impasse (cul-de-sac),
## l'équipe revient automatiquement sur le sentier principal.
func _verifier_impasse() -> void:
	if courant == plateau["boss"] or _a_des_sorties(courant):
		return
	var retour: Array = []
	var i := chemin.size() - 2
	while i >= 0:
		retour.append(chemin[i])
		if _a_des_sorties(chemin[i]):
			break
		i -= 1
	if retour.is_empty():
		return
	_message("Cul-de-sac", "Le chemin s'arrête ici.
L'équipe rebrousse chemin jusqu'au sentier.", _rebrousser.bind(retour))


func _rebrousser(etapes: Array) -> void:
	en_mouvement = true
	camera_libre = false
	var tw := create_tween()
	var a := pion_pos
	for id in etapes:
		var b := _pos(id)
		tw.tween_method(_anim_pion.bind(a, b), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		a = b
	var fin: int = etapes[-1]
	tw.finished.connect(func():
		courant = fin
		precedent = fin
		chemin.resize(chemin.find(fin) + 1)
		saut = 0.0
		en_mouvement = false
		_enregistrer_etat())


func _deplacer(id: int, apres_defaite := false) -> void:
	en_mouvement = true
	camera_libre = false
	if not apres_defaite:
		precedent = courant
	var a := pion_pos
	var b := _pos(id)
	var tw := create_tween()
	tw.tween_method(_anim_pion.bind(a, b), 0.0, 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(_arrivee.bind(id, apres_defaite))


func _anim_pion(t: float, a: Vector2, b: Vector2) -> void:
	if absf(b.x - a.x) > 1.0:
		_pion_gauche = b.x < a.x
	pion_pos = a.lerp(b, t)
	saut = sin(t * PI) * 28.0
	# Penché en avant au départ, en arrière à la réception
	_inclinaison = sin(t * TAU) * 0.12 * (-1.0 if _pion_gauche else 1.0)
	if t >= 1.0:
		_inclinaison = 0.0
		_atterrissage(b)


## Petit nuage de poussière et tassement quand la figurine se pose.
func _atterrissage(p: Vector2) -> void:
	_ecrase = 1.0
	for i in 12:
		var cote := -1.0 if i % 2 == 0 else 1.0
		var vie := randf_range(0.35, 0.6)
		_poussiere.append({
			"pos": p + Vector2(cote * randf_range(4, 16), randf_range(-2, 3)),
			"vel": Vector2(cote * randf_range(35, 95), -randf_range(4, 22)),
			"vie": vie, "vie_max": vie, "taille": randf_range(3.0, 5.5)})


func _arrivee(id: int, apres_defaite: bool) -> void:
	courant = id
	saut = 0.0
	en_mouvement = false
	visites[id] = true
	if apres_defaite:
		chemin.pop_back()           # on quitte la case du combat perdu
	else:
		chemin.append(id)
	_maj_brouillard()
	_enregistrer_etat()
	if not apres_defaite and not termines.has(id):
		_evenement(id)


func _maj_brouillard() -> void:
	reveles.clear()
	var file: Array = []
	var dist := {}
	for id in visites:
		dist[id] = 0
		file.append(id)
	while not file.is_empty():
		var id: int = file.pop_front()
		reveles[id] = true
		if dist[id] >= VISION:
			continue
		for v in noeuds[id]["voisins"]:
			if not dist.has(v):
				dist[v] = dist[id] + 1
				file.append(v)
	# Le boss est toujours visible : on sait où l'on va
	reveles[plateau["boss"]] = true
	if not BROUILLARD:
		for n in noeuds:
			reveles[n["id"]] = true


# ---------------------------------------------------------------
# Événements des cases
# ---------------------------------------------------------------

func _evenement(id: int) -> void:
	var n: Dictionary = noeuds[id]
	var type: int = n["type"]
	if PlateauGenerateur.est_combat(type):
		_lancer_combat(id)
		return
	match type:
		T.COFFRE:
			# 25 % des coffres sont des MIMICS (le tirage est gardé : un Mimic reste un Mimic)
			if not n.has("mimic"):
				n["mimic"] = randf() < Rencontres.CHANCE_MIMIC
				_enregistrer_etat()
			if n["mimic"]:
				Audio.son("coffre")
				_message("C'est un MIMIC !", "Le coffre s'ouvre... sur une gueule pleine de crocs !\nUn Mimic, bien plus coriace qu'un monstre ordinaire, t'attaque.\n\nBats-le pour récupérer son trésor. (Ce combat ne coûte pas de stamina.)",
					_lancer_combat.bind(id, true))
				return
			var gain := _or_coffre(n)
			Audio.son("coffre")
			_gagner_or(gain)
			Sauvegarde.ajouter_stat("coffres_ouverts")
			_terminer(id)
			var txt := "Tu ouvres le coffre : +%d or." % gain
			if randf() < CHANCE_SCEAU_COFFRE:
				Sauvegarde.ajouter_objet(Menagerie.SCEAU, 1)
				txt += "\nTu trouves aussi un Sceau Sauvage !"
			_message("Coffre d'or", txt, _verifier_impasse)
		T.SOIN:
			Audio.son("soin")
			pv_equipe.clear()
			_terminer(id)
			_maj_equipe_hud()
			_message("Autel de soin", "Une lumière chaude enveloppe l'équipe.\nToute l'équipe récupère tous ses PV.", _verifier_impasse)
		T.PIEGE:
			for uid in Sauvegarde.get_equipe():
				pv_equipe[str(uid)] = maxf(0.05, _pv_ratio(uid) - 0.15)
			_terminer(id)
			_maj_equipe_hud()
			_message("Piège !", "Des lames jaillissent du sol !\nToute l'équipe perd 15 % de ses PV.", _verifier_impasse)
		T.MYSTERE:
			_mystere(id)


func _mystere(id: int) -> void:
	var r := randf()
	if r < 0.35:
		var gain := 60 + int(noeuds[id]["niveau"]) * 20
		_gagner_or(gain)
		_terminer(id)
		_message("Mystère : trésor caché", "Sous une dalle, une bourse oubliée : +%d or." % gain, _verifier_impasse)
	elif r < 0.6:
		benediction = true
		_terminer(id)
		_message("Mystère : bénédiction", "Un esprit bienveillant bénit l'équipe.\n+10 % d'ATK pendant le prochain combat.", _verifier_impasse)
	else:
		noeuds[id]["type"] = T.COMBAT
		_enregistrer_etat()
		_message("Mystère : embuscade !", "C'était un piège ! Des ennemis surgissent de l'ombre.\n(Ce combat ne coûte pas de stamina.)", _lancer_combat.bind(id, true))


func _cout_stamina(id: int) -> int:
	return int(Sauvegarde.COUT_STAMINA_AVENTURE[Rencontres.type_rencontre(noeuds[id], chapitre)])


## Vérifie la stamina avant d'aller sur une case de combat (message sinon).
func _assez_de_stamina(id: int) -> bool:
	var cout := _cout_stamina(id)
	if Sauvegarde.get_stamina() >= cout:
		return true
	_message("Stamina insuffisante", "Ce combat coûte %d stamina, tu en as %d.\n\n+1 stamina toutes les 5 minutes (prochain point dans %s).\nTu peux aussi boire un Élixir au Reliquaire." % [
		cout, Sauvegarde.get_stamina(), Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())])
	return false


## Ouvre l'écran de combat avec l'équipe du joueur et les ennemis de cette case.
## `gratuit` : embuscade d'une case Mystère (pas de stamina).
func _lancer_combat(id: int, gratuit := false) -> void:
	var n: Dictionary = noeuds[id]
	var equipe: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		if h.is_empty():
			continue
		equipe.append({"id": h["id"], "niveau": int(h["niveau"]), "uid": uid, "place": Sauvegarde.place_de(uid),
			"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid),
			"pv_ratio": _pv_ratio(uid), "bonus_atk": 0.10 if benediction else 0.0})
	if equipe.is_empty():
		_message("Aucune équipe", "Ton équipe est vide : ajoute des héros dans le Deck avant de combattre.")
		return
	# Kaël combat à tes côtés dans certains chapitres de l'histoire (unité invitée, 6e place)
	var invite := FinHistoire.invite(acte, chapitre)
	if not invite.is_empty():
		equipe.append(invite)
	if not gratuit:
		if not _assez_de_stamina(id):
			return
		Sauvegarde.depenser_stamina(_cout_stamina(id))
		_maj_stamina()
	benediction = false
	_enregistrer_etat()
	EcranCombat.demande = {
		"acte": acte, "chapitre": chapitre, "noeud": id,
		"type": Rencontres.type_rencontre(n, chapitre),
		"equipe": equipe,
		"ennemis": Rencontres.generer(acte, chapitre, n),
	}
	get_tree().change_scene_to_file(EcranCombat.SCENE)


## Retour de l'écran de combat : on applique le résultat sur le plateau.
func _apres_combat(r: Dictionary) -> void:
	var equipe := Sauvegarde.get_equipe()
	var pv_final: Array = r.get("pv_final", [])
	if r["victoire"]:
		or_gagne += int(r.get("or", 0))
		# Les survivants récupèrent un peu, les K.O. se relèvent avec quelques PV
		for i in mini(equipe.size(), pv_final.size()):
			var ratio: float = pv_final[i]
			pv_equipe[str(equipe[i])] = clampf(maxf(ratio, 0.0) + RECUPERATION_APRES_VICTOIRE, 0.0, 1.0)
		_victoire(courant)
	else:
		_defaite(courant)


func _pv_ratio(uid: int) -> float:
	return float(pv_equipe.get(str(uid), 1.0))


func _victoire(id: int) -> void:
	var n: Dictionary = noeuds[id]
	_terminer(id)
	_maj_equipe_hud()
	lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	if n["type"] == T.BOSS:
		var premiere_fois := not ActesData.est_termine(acte, chapitre)
		ActesData.marquer_termine(acte, chapitre)
		Sauvegarde.effacer_plateau()
		# Scène d'histoire de fin de chapitre (première victoire seulement)
		if not DialoguesData.vu(acte, chapitre, "fin"):
			bloque = true
			await FenetreDialogue.jouer(self, acte, chapitre, "fin")
			bloque = false
		# Bonus d'XP de compte au premier passage (en plus de l'XP de chaque combat)
		var p := (acte - 1) * 6 + chapitre
		var xp := (20 + p * 3) if premiere_fois and not Sauvegarde.niveau_compte_max_atteint() else 0
		var niveaux := Sauvegarde.ajouter_xp_compte(xp) if xp > 0 else 0
		var texte := "Le boss est vaincu.\n\nOr gagné dans ce chapitre : %d" % or_gagne
		# Fins de l'histoire (Acte XII : fin douce-amère ; Acte XIII caché : vraie fin)
		var fin_lignes: Array = []
		if chapitre == 6 and acte == 12:
			fin_lignes = FinHistoire.fin_acte_12()
			if premiere_fois:
				texte = FinHistoire.EPILOGUE_12 + "\n\n" + texte
		elif chapitre == 6 and acte == 13:
			fin_lignes = FinHistoire.fin_acte_13()
			if premiere_fois or not fin_lignes.is_empty():
				texte = FinHistoire.EPILOGUE_13 + "\n\n" + texte
		if not fin_lignes.is_empty():
			texte += "\n\n" + "\n".join(fin_lignes)
		if xp > 0:
			texte += "\nBonus de premier passage : +%d XP de compte" % xp
		if niveaux > 0:
			texte += "\n\nNIVEAU DE COMPTE %d ! Stamina max : %d — stamina rechargée !" % [Sauvegarde.get_niveau_compte(), Sauvegarde.get_stamina_max()]
		_message("Chapitre terminé !", texte, _retour)
	elif n.get("mimic", false):
		# Le trésor du Mimic : le double d'un coffre normal
		var gain := _or_coffre(n) * 2
		_gagner_or(gain)
		Sauvegarde.ajouter_stat("coffres_ouverts")
		Sauvegarde.ajouter_stat("mimics_vaincus")
		Sauvegarde.ajouter_objet(Menagerie.SCEAU, 2)
		_message("Mimic vaincu !", "Dans la carcasse du Mimic, tu trouves son trésor : +%d or et 2 Sceaux Sauvages." % gain, _verifier_impasse)
	else:
		_verifier_impasse()


func _or_coffre(n: Dictionary) -> int:
	var gain := 40 + int(n["niveau"]) * 15 + randi_range(0, 30)
	if n["cul_de_sac"]:
		gain = int(gain * 1.8)
	return gain


func _defaite(id: int) -> void:
	# L'équipe se replie d'une case et récupère toutes ses forces : on peut retenter.
	pv_equipe.clear()
	_maj_equipe_hud()
	defaites_case[id] = int(defaites_case.get(id, 0)) + 1
	var texte := "L'équipe est repoussée et recule d'une case.\nElle reprend des forces : tu peux retenter ce combat."
	var astuce := _astuce_defaite(int(defaites_case[id]))
	if astuce != "":
		texte += "\n\n" + astuce
	_message("Défaite", texte, _deplacer.bind(precedent, true))


## Conseil après des défaites répétées : les Échos Sanguins font une grosse différence
## (réglage de la difficulté : une équipe sans Échos gagne 20 à 30 % de combats en moins).
func _astuce_defaite(nb: int) -> String:
	if nb < 2:
		return ""
	var portes := 0
	var equipe := Sauvegarde.get_equipe()
	for uid in equipe:
		portes += Sauvegarde.echos_de(int(uid)).size()
	if portes < equipe.size() * 3:
		return "Astuce : ton équipe porte peu d'Échos Sanguins (%d sur %d emplacements). Équipe ceux que tu as gagnés (menu Échos Sanguins) : c'est le moyen le plus rapide de devenir plus fort." % [portes, equipe.size() * 6]
	if nb >= 3:
		return "Astuce : améliore tes meilleurs Échos (+3, +6…), monte le niveau de tes nouvelles unités à l'Autel de Fusion (Absorption), ou retente : chaque combat a sa part de hasard."
	return ""


func _gagner_or(montant: int) -> void:
	or_gagne += montant
	Sauvegarde.ajouter_or(montant)
	lbl_or.text = "Or : %d" % Sauvegarde.get_or()


func _maj_stamina() -> void:
	if lbl_stamina == null:
		return
	var st := Sauvegarde.get_stamina()
	var mx := Sauvegarde.get_stamina_max()
	lbl_stamina.text = "Stamina %d/%d" % [st, mx] + ("" if st >= mx else "  (+1 dans %s)" % Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina()))


func _message(titre: String, texte: String, ensuite := Callable()) -> void:
	bloque = true
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	var fermer := func():
		d.hide()
		d.queue_free()
		bloque = false
		if ensuite.is_valid():
			ensuite.call()
	d.confirmed.connect(fermer)
	d.canceled.connect(fermer)
	hud.add_child(d)
	if texte.length() > 300:          # textes longs (épilogues) : retour à la ligne automatique
		d.dialog_autowrap = true
		d.popup_centered(Vector2i(760, 0))
	else:
		d.popup_centered(Vector2i(420, 0))


func _retour() -> void:
	get_tree().change_scene_to_file(SCENE_CHAPITRES)


# ---------------------------------------------------------------
# Outils
# ---------------------------------------------------------------

func _pos(id: int) -> Vector2:
	var p: Vector2 = noeuds[id]["pos"]
	return Vector2(p.x * ECART.x, p.y * ECART.y)


func _noeud_a(p: Vector2) -> int:
	var meilleur := -1
	var dmin := RAYON * 1.5
	for n in noeuds:
		if not reveles.has(n["id"]):
			continue
		var d := p.distance_to(_pos(n["id"]))
		if d < dmin:
			dmin = d
			meilleur = n["id"]
	return meilleur


func _maj_survol(p: Vector2) -> void:
	var id := _noeud_a(p)
	if id == survol:
		return
	survol = id
	if id < 0:
		info.visible = false
		return
	var n: Dictionary = noeuds[id]
	var type: int = n["type"]
	info_titre.text = PlateauGenerateur.NOMS[type]
	var sous := ""
	if PlateauGenerateur.est_combat(type):
		sous = "Niveau %d" % Rencontres.niveau_ennemis(acte, chapitre, n)
	if n["voie_risquee"]:
		sous += ("  ·  " if sous != "" else "") + "Voie risquée"
	if n["cul_de_sac"]:
		sous += ("  ·  " if sous != "" else "") + "Cul-de-sac"
	if n.get("mimic", false) and not termines.has(id):
		sous += ("  ·  " if sous != "" else "") + "MIMIC ! (niveau %d)" % Rencontres.niveau_ennemis(acte, chapitre, n)
	if termines.has(id) and type != T.DEPART:
		sous += ("  ·  " if sous != "" else "") + "Terminé"
	info_sous.text = sous
	info_sous.visible = sous != ""
	info_texte.text = PlateauGenerateur.DESCRIPTIONS[type]
	info.visible = true


# ---------------------------------------------------------------
# Dessin du plateau
# ---------------------------------------------------------------

func _draw() -> void:
	# DÉCOR FIXE : chemins pavés et cases (redessiné seulement quand il change, voir _process)
	for n in noeuds:
		var a: int = n["id"]
		for b in n["voisins"]:
			if b <= a:
				continue
			var va := reveles.has(a)
			var vb := reveles.has(b)
			if not va and not vb:
				continue
			var etat := 2
			if va and vb:
				etat = 0 if (visites.has(a) and visites.has(b)) else 1
			_dessiner_chemin(_pos(a), _pos(b), a * 131 + b, etat)

	for n in noeuds:
		var id: int = n["id"]
		var p := _pos(id)
		if reveles.has(id):
			_dessiner_case(n, p)
		elif _voisin_revele(id):
			_dessiner_case_cachee(id, p)


func _creer_calques() -> void:
	_sous = Node2D.new()
	_sous.z_index = -1
	_sous.draw.connect(_dessiner_sous)
	add_child(_sous)
	_dessus = Node2D.new()
	_dessus.z_index = 1
	_dessus.draw.connect(_dessiner_dessus)
	add_child(_dessus)
	# Pénombre : transparente près du grand frère, sombre au loin (remplace l'ancien éclairage case par case)
	var g := Gradient.new()
	var noir := Color(0.01, 0.01, 0.02)
	g.set_color(0, Color(noir, 0.0))
	g.set_color(1, Color(noir, OMBRE_MAX))
	g.add_point(0.4, Color(noir, 0.0))
	_ombre = GradientTexture2D.new()
	_ombre.gradient = g
	_ombre.fill = GradientTexture2D.FILL_RADIAL
	_ombre.fill_from = Vector2(0.5, 0.5)
	_ombre.fill_to = Vector2(1.0, 0.5)
	_ombre.width = 256
	_ombre.height = 256


const OMBRE_MAX := 0.36
const PORTEE_OMBRE := 1020.0


## Sous le décor : halo bleu de la Larme et lueur rouge qui pulse sous le boss.
func _dessiner_sous() -> void:
	if _halo == null:
		_halo = _texture_halo()
	var rayon := PORTEE_LUMIERE * (0.92 + 0.08 * sin(temps * 1.6))
	_sous.draw_texture_rect(_halo, Rect2(pion_pos - Vector2(rayon, rayon), Vector2(rayon, rayon) * 2.0), false, Color(COULEUR_LARME, 0.42))
	var boss: int = plateau["boss"]
	if reveles.has(boss):
		var lueur := 0.5 + 0.5 * sin(temps * 2.0)
		var rb := RAYON * 1.45 + 16.0 + lueur * 6.0
		_sous.draw_texture_rect(_halo, Rect2(_pos(boss) - Vector2(rb, rb) * 1.6, Vector2(rb, rb) * 3.2), false, Color(1, 0.1, 0.05, 0.35))


## Au-dessus du décor : pénombre, anneaux des cases accessibles, survol, figurine, poussière.
func _dessiner_dessus() -> void:
	var c := _dessus
	var R := PORTEE_OMBRE
	c.draw_texture_rect(_ombre, Rect2(pion_pos - Vector2(R, R), Vector2(R, R) * 2.0), false)
	var loin := 6000.0
	var noir := Color(0.01, 0.01, 0.02, OMBRE_MAX)
	c.draw_rect(Rect2(pion_pos.x - loin, pion_pos.y - loin, loin * 2.0, loin - R), noir)
	c.draw_rect(Rect2(pion_pos.x - loin, pion_pos.y + R, loin * 2.0, loin - R), noir)
	c.draw_rect(Rect2(pion_pos.x - loin, pion_pos.y - R, loin - R, R * 2.0), noir)
	c.draw_rect(Rect2(pion_pos.x + R, pion_pos.y - R, loin - R, R * 2.0), noir)

	if not en_mouvement and not bloque:
		var pulse := 0.5 + 0.5 * sin(temps * 5.0)
		for v in noeuds[courant]["voisins"]:
			if _accessible(v):
				var r := RAYON + 9.0 + pulse * 5.0
				c.draw_arc(_pos(v), r, 0, TAU, 40, Color(1.0, 0.85, 0.45, 0.5 + 0.5 * pulse), 3.0, true)
	if survol >= 0:
		c.draw_arc(_pos(survol), RAYON + 7.0, 0, TAU, 40, Color.WHITE, 2.0, true)

	_dessiner_pion(pion_pos + Vector2(0, -saut))
	_dessiner_poussiere()


func _voisin_revele(id: int) -> bool:
	for v in noeuds[id]["voisins"]:
		if reveles.has(v):
			return true
	return false


## Dégradé radial doux (blanc au centre -> transparent) pour les lueurs.
func _texture_halo() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


## Nombre pseudo-aléatoire stable (0..1) : les pavés ne bougent pas d'une image à l'autre.
func _h(a: int, b: int) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)


## Éclairage : 1 près du grand frère, de plus en plus sombre en s'éloignant.
func _lumiere(p: Vector2) -> float:
	var d := p.distance_to(pion_pos)
	return clampf(1.0 - (d - 320.0) / 700.0, 0.42, 1.0)


## Teinte bleue de la Larme sur ce qui est tout près du grand frère (0..1).
func _reflet(p: Vector2) -> float:
	return clampf(1.0 - p.distance_to(pion_pos) / PORTEE_LUMIERE, 0.0, 1.0)


## (L'éclairage est maintenant fait par la pénombre du calque _dessus : le décor reste fixe.)
func _eclairer(c: Color, _p: Vector2) -> Color:
	return c


## Chemin de pavés entre deux cases. etat : 0 = parcouru, 1 = visible, 2 = entrevu.
func _dessiner_chemin(pa: Vector2, pb: Vector2, graine: int, etat: int) -> void:
	var d := pa.distance_to(pb)
	var dir := (pb - pa) / d
	var perp := dir.orthogonal()
	var angle := dir.angle()
	if etat < 2:
		# Sentier de terre sous les pavés
		draw_line(pa, pb, Color(0.05, 0.035, 0.025, 0.55), 18.0, true)
	var longueur := d - 2.0 * (RAYON + 6.0)
	var pas := 16.0
	var nb := int(longueur / pas)
	if nb < 1:
		return
	var marge := RAYON + 6.0 + (longueur - nb * pas) / 2.0
	var pierre := Color("5c544c")
	if etat == 0:
		pierre = Color("b8a88e").lerp(accent, 0.3)
	for i in nb + 1:
		if etat == 2 and i % 2 == 1:
			continue
		var q := pa + dir * (marge + i * pas)
		var k := graine * 37 + i
		q += perp * (_h(k, 1) - 0.5) * 5.0
		var rr := 4.2 + _h(k, 2) * 2.2
		var col := pierre.darkened(_h(k, 3) * 0.25)
		if etat == 2:
			col = Color(accent, 0.18)
			rr *= 0.7
		else:
			col = _eclairer(col, q)
		draw_set_transform(q, angle + (_h(k, 4) - 0.5) * 0.8, Vector2(1.35, 0.85))
		if etat < 2:
			draw_circle(Vector2(0.8, 1.8), rr, Color(0, 0, 0, 0.5))
		draw_circle(Vector2.ZERO, rr, col)
		if etat < 2:
			draw_circle(Vector2(-rr * 0.3, -rr * 0.3), rr * 0.45, Color(1, 1, 1, 0.12 if etat == 0 else 0.05))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Socle de pierre en relief (épaisseur, biseau, fissures).
func _dessiner_socle(p: Vector2, r: float, pierre: Color, graine: int) -> void:
	draw_circle(p + Vector2(3, 11), r + 4.0, Color(0, 0, 0, 0.45))       # ombre au sol
	draw_circle(p + Vector2(0, 7), r + 3.0, pierre.darkened(0.55))        # tranche du socle
	draw_arc(p + Vector2(0, 7), r + 3.0, 0.1, PI - 0.1, 32, pierre.darkened(0.75), 2.0, true)
	draw_circle(p, r + 3.0, pierre)                                       # dessus
	draw_circle(p + Vector2(-r * 0.2, -r * 0.25), r * 0.75, Color(1, 1, 1, 0.04))
	draw_arc(p, r + 1.8, PI * 1.0, PI * 1.75, 24, Color(pierre.lightened(0.45), 0.8), 2.5, true)
	draw_arc(p, r + 1.8, 0.0, PI * 0.75, 24, pierre.darkened(0.45), 2.5, true)
	# Deux fissures
	for f in 2:
		var ang := _h(graine, 10 + f) * TAU
		var a := p + Vector2.from_angle(ang) * (r + 2.5)
		var m := p + Vector2.from_angle(ang + 0.25) * (r * 0.82)
		var b := p + Vector2.from_angle(ang - 0.05) * (r * 0.7)
		draw_polyline(PackedVector2Array([a, m, b]), pierre.darkened(0.6), 1.3, true)


func _dessiner_case(n: Dictionary, p: Vector2) -> void:
	var type: int = n["type"]
	var r := RAYON * (1.45 if type == T.BOSS else (1.15 if type == T.GARDIEN else 1.0))
	var fait := termines.has(n["id"]) and type != T.DEPART
	var fond: Color = COULEURS[type]
	if fait:
		fond = fond.darkened(0.55)
	var pierre := Color("4a443e") if not fait else Color("35312d")
	_dessiner_socle(p, r, pierre, n["id"] * 7 + 3)

	# Médaillon coloré incrusté dans la pierre
	var ri := r * 0.8
	draw_circle(p, ri, fond)
	draw_circle(p + Vector2(-ri * 0.25, -ri * 0.3), ri * 0.55, Color(1, 1, 1, 0.07))
	draw_arc(p, ri, 0, TAU, 48, Color("c9a060") if not fait else Color("6a5a40"), 2.5, true)
	draw_arc(p, ri - 3.5, 0, TAU, 48, Color(0, 0, 0, 0.35), 2.0, true)
	# Miniature posée sur le socle (assets/plateaux/cases/<type>.png), sinon icône.
	# Sur la case du grand frère, on garde l'icône : la figurine est déjà dessus.
	var mini := _miniature(type)
	var avec_mini: bool = mini != null and n["id"] != courant
	if not avec_mini:
		var ic := Color(1, 0.93, 0.8) if not fait else Color(1, 1, 1, 0.35)
		_dessiner_icone(type, p, ri * 0.62, ic)


	if avec_mini:
		var ts := mini.get_size()
		var h := r * HAUTEUR_MINIATURE
		var w := h * ts.x / ts.y
		if w > r * 3.2:          # miniature très large (porte, coffre) : on limite la largeur
			w = r * 3.2
			h = w * ts.y / ts.x
		var teinte := Color.WHITE
		if fait:
			teinte = teinte.darkened(0.5)
			teinte.a = 0.8
		draw_texture_rect(mini, Rect2(p + Vector2(-w / 2.0, r * 0.35 - h), Vector2(w, h)), false, teinte)

	if PlateauGenerateur.est_combat(type) and not fait:
		_texte(p + Vector2(0, r + 26.0), "Nv %d" % Rencontres.niveau_ennemis(acte, chapitre, n), 14, Color(1, 0.9, 0.75, 0.85))


## Image de la miniature d'un type de case (chargée une seule fois), ou null.
func _miniature(type: int) -> Texture2D:
	if not _miniatures.has(type):
		var chemin := DOSSIER_MINIATURES + str(MINIATURES.get(type, "")) + ".png"
		_miniatures[type] = load(chemin) if MINIATURES.has(type) and ResourceLoader.exists(chemin) else null
	return _miniatures[type]


## Case encore cachée par le brouillard, à côté d'une case connue.
func _dessiner_case_cachee(_id: int, p: Vector2) -> void:
	var r := RAYON * 0.72
	draw_circle(p + Vector2(0, 6), r + 3.0, Color(0.03, 0.025, 0.03, 0.8))
	draw_circle(p, r + 3.0, Color(0.08, 0.07, 0.07, 0.85))
	draw_arc(p, r + 3.0, 0, TAU, 24, Color(accent, 0.22), 2.0, true)
	_texte(p + Vector2(0, 7), "?", 20, Color(1, 1, 1, 0.3))


func _dessiner_poussiere() -> void:
	for d in _poussiere:
		var t: float = d["vie"] / d["vie_max"]
		var taille: float = d["taille"] * (1.0 + (1.0 - t) * 1.2)
		_dessus.draw_set_transform(d["pos"], 0, Vector2(1.4, 0.8))
		_dessus.draw_circle(Vector2.ZERO, taille, Color(0.78, 0.7, 0.6, 0.6 * t))
	_dessus.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _dessiner_icone(type: int, c: Vector2, s: float, col: Color) -> void:
	match type:
		T.DEPART:
			draw_line(c + Vector2(-s * 0.4, s), c + Vector2(-s * 0.4, -s), col, 3.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s), c + Vector2(s * 0.8, -s * 0.55), c + Vector2(-s * 0.4, -s * 0.1)]), col)
		T.COMBAT, T.ELITE:
			_epee(c, s, 1.0, col)
			_epee(c, s, -1.0, col)
			if type == T.ELITE:
				var h := c + Vector2(0, -s * 1.05)
				draw_colored_polygon(PackedVector2Array([
					h + Vector2(-s * 0.55, 0), h + Vector2(-s * 0.55, -s * 0.45), h + Vector2(-s * 0.25, -s * 0.2),
					h + Vector2(0, -s * 0.55), h + Vector2(s * 0.25, -s * 0.2), h + Vector2(s * 0.55, -s * 0.45),
					h + Vector2(s * 0.55, 0)]), Color("ffd060"))
		T.GARDIEN:
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s, -s * 0.9), c + Vector2(s, -s * 0.9), c + Vector2(s * 0.9, s * 0.1),
				c + Vector2(0, s * 1.05), c + Vector2(-s * 0.9, s * 0.1)]), col)
			draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.6), COULEURS[T.GARDIEN], 3.0)
			draw_line(c + Vector2(-s * 0.5, -s * 0.15), c + Vector2(s * 0.5, -s * 0.15), COULEURS[T.GARDIEN], 3.0)
		T.BOSS:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.7, -s * 0.5), c + Vector2(-s * 1.1, -s * 1.2), c + Vector2(-s * 0.3, -s * 0.8)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.7, -s * 0.5), c + Vector2(s * 1.1, -s * 1.2), c + Vector2(s * 0.3, -s * 0.8)]), col)
			draw_circle(c + Vector2(0, -s * 0.1), s * 0.8, col)
			draw_rect(Rect2(c + Vector2(-s * 0.45, s * 0.4), Vector2(s * 0.9, s * 0.45)), col)
			draw_circle(c + Vector2(-s * 0.32, -s * 0.15), s * 0.2, Color(0.9, 0.1, 0.05))
			draw_circle(c + Vector2(s * 0.32, -s * 0.15), s * 0.2, Color(0.9, 0.1, 0.05))
		T.COFFRE:
			draw_rect(Rect2(c + Vector2(-s, -s * 0.2), Vector2(s * 2, s * 1.0)), col)
			draw_rect(Rect2(c + Vector2(-s, -s * 0.75), Vector2(s * 2, s * 0.5)), col.darkened(0.15))
			draw_rect(Rect2(c + Vector2(-s * 0.15, -s * 0.35), Vector2(s * 0.3, s * 0.45)), COULEURS[T.COFFRE].darkened(0.5))
		T.SOIN:
			draw_rect(Rect2(c + Vector2(-s * 0.28, -s), Vector2(s * 0.56, s * 2)), col)
			draw_rect(Rect2(c + Vector2(-s, -s * 0.28), Vector2(s * 2, s * 0.56)), col)
		T.MYSTERE:
			_texte(c + Vector2(0, s * 0.75), "?", int(s * 2.4), col)
		T.PIEGE:
			for i in 3:
				var x := c.x + (i - 1) * s * 0.7
				draw_colored_polygon(PackedVector2Array([Vector2(x - s * 0.33, c.y + s * 0.7), Vector2(x + s * 0.33, c.y + s * 0.7), Vector2(x, c.y - s * 0.9)]), col)


func _epee(c: Vector2, s: float, sens: float, col: Color) -> void:
	var a := c + Vector2(-s * sens, s)
	var b := c + Vector2(s * sens, -s)
	draw_line(a, b, col, 3.5, true)
	var g := a.lerp(b, 0.25)
	var perp := (b - a).orthogonal().normalized() * s * 0.35
	draw_line(g - perp, g + perp, col, 3.0, true)


func _dessiner_pion(p: Vector2) -> void:
	# Pion d'échecs (secours si pion_aine.png est absent)
	var ombre := 1.0 - saut / 60.0
	_dessus.draw_set_transform(pion_pos + Vector2(0, 4), 0, Vector2(1.0, 0.35))
	_dessus.draw_circle(Vector2.ZERO, 26.0 * ombre, Color(0, 0, 0, 0.45))
	_dessus.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Figurine du grand frère (assets/plateaux/pion_aine.png) si elle existe
	if not _pion_charge:
		_pion_charge = true
		if ResourceLoader.exists(IMAGE_PION):
			_pion_tex = load(IMAGE_PION)
	if _pion_tex:
		var ts := _pion_tex.get_size()
		var h := HAUTEUR_PION
		var w := h * ts.x / ts.y
		# Les pieds (bas de l'image) sont posés sur la case
		var r := Rect2(-w / 2.0, -h + 6.0, w, h)
		# Lueur bleue de la Larme sous les pieds
		_dessus.draw_set_transform(pion_pos + Vector2(0, 4), 0, Vector2(1.0, 0.4))
		for i in 4:
			_dessus.draw_circle(Vector2.ZERO, 34.0 - i * 7.0, Color(COULEUR_LARME, 0.07 * ombre))
		# Penché pendant le saut (pivot aux pieds), tassé à l'atterrissage
		var ech := Vector2(1.0 + 0.07 * _ecrase, 1.0 - 0.09 * _ecrase)
		_dessus.draw_set_transform(p, _inclinaison, Vector2(-ech.x if _pion_gauche else ech.x, ech.y))
		_dessus.draw_texture_rect(_pion_tex, r, false)
		_dessus.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return

	var corps := Color("f2e6cc")
	var bord := Color("3a2a1a")
	var base := PackedVector2Array([
		p + Vector2(-22, 0), p + Vector2(22, 0), p + Vector2(20, -9), p + Vector2(-20, -9)])
	var tronc := PackedVector2Array([
		p + Vector2(-16, -9), p + Vector2(16, -9), p + Vector2(8, -36), p + Vector2(-8, -36)])
	var col := PackedVector2Array([
		p + Vector2(-13, -36), p + Vector2(13, -36), p + Vector2(13, -41), p + Vector2(-13, -41)])
	for poly in [base, tronc, col]:
		_dessus.draw_colored_polygon(poly, corps)
		var ferme: PackedVector2Array = poly.duplicate()
		ferme.append(poly[0])
		_dessus.draw_polyline(ferme, bord, 2.0, true)
	_dessus.draw_circle(p + Vector2(0, -52), 13.0, corps)
	_dessus.draw_arc(p + Vector2(0, -52), 13.0, 0, TAU, 32, bord, 2.0, true)
	_dessus.draw_circle(p + Vector2(-4, -56), 4.0, Color(1, 1, 1, 0.8))


func _texte(p: Vector2, texte: String, taille: int, col: Color) -> void:
	var largeur := 200.0
	draw_string(police, p - Vector2(largeur / 2.0, 0), texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille, col)


# ---------------------------------------------------------------
# Fond et interface
# ---------------------------------------------------------------

func _creer_fond() -> void:
	var couche := CanvasLayer.new()
	couche.layer = -10
	add_child(couche)
	var noir := ColorRect.new()
	noir.color = Color(0.03, 0.02, 0.03)
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	couche.add_child(noir)
	# Fond du plateau : res://assets/plateaux/fond_01.png ... fond_12.png
	# (remplace le fichier en gardant le même nom pour le changer)
	var chemin := "res://assets/plateaux/fond_%02d.png" % acte
	if ResourceLoader.exists(chemin):
		var tex: Texture2D = load(chemin)
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.6, 0.56, 0.56)
		couche.add_child(img)


func _style_panneau() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.02, 0.03, 0.92)
	s.border_color = Color(0.85, 0.65, 0.3)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(12)
	return s


func _creer_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	# Barre du haut
	var barre := PanelContainer.new()
	barre.add_theme_stylebox_override("panel", _style_panneau())
	barre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	barre.offset_left = 10
	barre.offset_right = -10
	barre.offset_top = 10
	hud.add_child(barre)
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	barre.add_child(ligne)

	var btn := Button.new()
	btn.text = "← Chapitres"
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(_retour)
	ligne.add_child(btn)

	var a := ActesData.get_acte(acte)
	var chap := ActesData.get_chapitre(acte, chapitre)
	lbl_titre = Label.new()
	lbl_titre.text = "ACTE %s · CHAPITRE %d — %s" % [a.get("romain", ""), chapitre, chap.get("titre", "")]
	lbl_titre.tooltip_text = Echos.texte_loot(acte, chapitre)
	lbl_titre.mouse_filter = Control.MOUSE_FILTER_PASS
	lbl_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titre.add_theme_font_size_override("font_size", 22)
	lbl_titre.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 0)
	centre.add_child(lbl_titre)
	# Ce qu'on peut trouver ici : set de l'Acte et emplacement du chapitre
	var loot := Label.new()
	loot.text = Echos.texte_loot(acte, chapitre)
	loot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loot.add_theme_font_size_override("font_size", 15)
	loot.add_theme_color_override("font_color", Color("ff8a7a"))
	centre.add_child(loot)
	ligne.add_child(centre)

	lbl_stamina = Label.new()
	lbl_stamina.add_theme_font_size_override("font_size", 18)
	lbl_stamina.add_theme_color_override("font_color", Color("7ad0ff"))
	ligne.add_child(lbl_stamina)
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_stamina)
	add_child(minuterie)
	_maj_stamina()

	lbl_or = Label.new()
	lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	lbl_or.add_theme_font_size_override("font_size", 20)
	lbl_or.add_theme_color_override("font_color", Color("ffd060"))
	ligne.add_child(lbl_or)

	var centrer := Button.new()
	centrer.text = "Recentrer"
	centrer.focus_mode = Control.FOCUS_NONE
	centrer.pressed.connect(func(): camera_libre = false)
	ligne.add_child(centrer)

	# Aide en bas
	var aide := Label.new()
	aide.text = "Clique sur une case qui brille pour avancer  ·  Glisse pour regarder  ·  Molette : zoom  ·  Espace : recentrer"
	aide.add_theme_color_override("font_color", Color(1, 0.9, 0.8, 0.7))
	aide.add_theme_color_override("font_outline_color", Color.BLACK)
	aide.add_theme_constant_override("outline_size", 5)
	aide.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	aide.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aide.offset_top = -36
	aide.offset_bottom = -12
	aide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(aide)

	# Bulle d'info au survol d'une case
	info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _style_panneau())
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	info.offset_left = 16
	info.offset_bottom = -50
	info.offset_top = -190
	info.offset_right = 380
	info.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(info)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(vb)
	info_titre = _label(22, Color(1.0, 0.85, 0.55))
	info_sous = _label(15, Color(0.85, 0.6, 0.55))
	info_texte = _label(17, Color(0.92, 0.88, 0.85))
	vb.add_child(info_titre)
	vb.add_child(info_sous)
	vb.add_child(info_texte)
	info.visible = false

	# Équipe et PV restants (en bas à droite)
	var pe := PanelContainer.new()
	pe.add_theme_stylebox_override("panel", _style_panneau())
	pe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pe.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	pe.offset_right = -16
	pe.offset_bottom = -50
	pe.offset_left = -300
	pe.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	pe.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(pe)
	boite_equipe = VBoxContainer.new()
	boite_equipe.add_theme_constant_override("separation", 4)
	boite_equipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pe.add_child(boite_equipe)
	_maj_equipe_hud()


func _maj_equipe_hud() -> void:
	if boite_equipe == null:
		return
	for enfant in boite_equipe.get_children():
		enfant.queue_free()
	var titre := _label(15, Color(1.0, 0.85, 0.55))
	titre.text = "ÉQUIPE" + ("   (bénie : ATK +10 %)" if benediction else "")
	boite_equipe.add_child(titre)
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		if h.is_empty():
			continue
		var ligne := HBoxContainer.new()
		ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nom := _label(14, Color(0.92, 0.88, 0.85))
		nom.autowrap_mode = TextServer.AUTOWRAP_OFF
		nom.text = "%s Nv %d" % [UnitesData.get_unite(h["id"])["nom"], int(h["niveau"])]
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nom.clip_text = true
		ligne.add_child(nom)
		var ratio := _pv_ratio(uid)
		var pv := _label(14, Color("6aff8a") if ratio > 0.6 else (Color("ffd060") if ratio > 0.3 else Color("ff6a5a")))
		pv.autowrap_mode = TextServer.AUTOWRAP_OFF
		pv.text = "%d %%" % int(round(ratio * 100))
		ligne.add_child(pv)
		boite_equipe.add_child(ligne)


func _label(taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l
