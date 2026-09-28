class_name Audio
extends Node
## MUSIQUE ET BRUITAGES — utilisable partout, sans rien configurer :
##   Audio.musique("combat")     -> change la musique (fondu enchaîné)
##   Audio.son("coup")           -> joue un bruitage
##   Audio.regler_volume("musique", 0.5)   (0 à 1, enregistré dans la sauvegarde)
##
## Les fichiers sont cherchés dans :
##   res://assets/audio/musique/<nom>.ogg   (ou .mp3 / .wav)
##   res://assets/audio/sons/<nom>.ogg      (ou .mp3 / .wav)
## Un fichier manquant est simplement ignoré (pas d'erreur) : tu peux ajouter
## ou remplacer un son à tout moment en déposant un fichier du même nom.
##
## Le lecteur démarre tout seul (au chargement de la sauvegarde) et reste actif
## d'un écran à l'autre. La musique de chaque écran est choisie automatiquement
## (MUSIQUE_PAR_SCENE) ; chaque bouton fait « clic » (ou « retour »).

const DOSSIER_MUSIQUE := "res://assets/audio/musique/"
const DOSSIER_SONS := "res://assets/audio/sons/"
const EXTENSIONS := ["ogg", "mp3", "wav"]
const BUS_MUSIQUE := "Musique"
const BUS_SONS := "Sons"
const FONDU := 1.2               # secondes de fondu enchaîné entre deux musiques
const SILENCE_DB := -40.0
const NB_LECTEURS_SONS := 12     # sons joués en même temps au maximum
const ESPACEMENT_MS := 60        # un même son ne se répète pas plus vite que ça

## Musique de chaque écran (nom du fichier .tscn). Écran absent = "menu".
## "" = l'écran choisit lui-même sa musique (combat, étage de tour).
const MUSIQUE_PAR_SCENE := {
	"aventure.tscn": "aventure", "histoire.tscn": "aventure", "ecran_acte.tscn": "aventure",
	"plateau.tscn": "aventure",
	"invocation.tscn": "invocation",
	"boss_monde.tscn": "boss_monde",
	"combat.tscn": "", "tour.tscn": "",
	"donjon.tscn": "aventure",
}
const MUSIQUE_PAR_DEFAUT := "menu"

## Si une musique n'existe pas encore, on joue celle-ci à la place.
const REMPLACEMENTS := {"boss": "boss_monde", "tour_enfer": "combat", "tour_paradis": "combat"}
## Musiques jouées une seule fois (pas en boucle).
const SANS_BOUCLE := ["victoire", "defaite"]

## Réglage fin du volume de certains sons (en dB, 0 = normal).
const VOLUME_SONS := {"clic": -4.0, "retour": -4.0, "carte": 2.0, "coup": -2.0, "magie": -3.0, "soin": -3.0}
## Sons dont la hauteur varie un peu à chaque fois (plus naturel quand ils se répètent).
const HAUTEUR_VARIABLE := ["coup", "coup_critique", "ko", "clic", "carte", "bouclier", "magie", "soin"]
## Sons à ne jamais couper même si beaucoup de sons jouent.
const SONS_PRIORITAIRES := ["rare_sr", "rare_ssr", "rare_ur", "legende", "boss_rugit", "niveau", "coffre", "cercle"]

static var _instance: Audio = null

var _lecteurs_musique: Array[AudioStreamPlayer] = []
var _actif := 0                        # index du lecteur de musique en cours
var _musique_actuelle := ""
var _lecteurs_sons: Array[AudioStreamPlayer] = []
var _cache := {}                       # chemin -> AudioStream (ou null si absent)
var _derniere_fois := {}               # nom du son -> ticks ms
var _tweens: Array[Tween] = [null, null]
var _musique_en_attente := "-"
var _web := OS.has_feature("web")
var _geste_recu := false               # web : le navigateur n'autorise le son qu'après un clic


# =====================================================================
# Fonctions à utiliser depuis les autres scripts
# =====================================================================

## Lance le lecteur (appelé automatiquement ; sans effet s'il tourne déjà).
static func demarrer() -> void:
	if _instance != null and is_instance_valid(_instance):
		return
	if Engine.is_editor_hint():
		return
	var arbre := Engine.get_main_loop() as SceneTree
	if arbre == null or arbre.root == null:
		return
	_instance = Audio.new()
	_instance.name = "AudioJeu"
	_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	arbre.root.add_child.call_deferred(_instance)


## Change la musique (fondu enchaîné). "" = arrêter la musique.
static func musique(nom: String) -> void:
	demarrer()
	if _instance == null:
		return
	if not _instance.is_inside_tree():
		_instance._musique_en_attente = nom
		return
	_instance._jouer_musique(nom)


## Joue un bruitage. volume_db : plus fort (+) ou moins fort (-).
static func son(nom: String, volume_db := 0.0) -> void:
	demarrer()
	if _instance == null or not _instance.is_inside_tree():
		return
	_instance._jouer_son(nom, volume_db)


## Joue un bruitage après un délai (en secondes).
static func son_apres(nom: String, delai: float, volume_db := 0.0) -> void:
	demarrer()
	if _instance == null or not _instance.is_inside_tree():
		return
	_instance.get_tree().create_timer(delai).timeout.connect(func(): son(nom, volume_db))


## type : "musique" ou "sons" ; valeur de 0.0 (muet) à 1.0.
static func regler_volume(type: String, valeur: float) -> void:
	Sauvegarde.definir_parametre("volume_" + type, clampf(valeur, 0.0, 1.0))
	_appliquer_volumes()


static func get_volume(type: String) -> float:
	return float(Sauvegarde.get_parametre("volume_" + type, 0.8))


## Nom de la musique en cours ("" si aucune).
static func musique_actuelle() -> String:
	if _instance == null or not is_instance_valid(_instance):
		return ""
	return _instance._musique_actuelle


## Le fichier existe-t-il ? (type : "musique" ou "sons")
static func existe(type: String, nom: String) -> bool:
	return _trouver(DOSSIER_MUSIQUE if type == "musique" else DOSSIER_SONS, nom) != ""


# =====================================================================
# Fonctionnement interne
# =====================================================================

func _ready() -> void:
	_creer_bus()
	_appliquer_volumes()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_MUSIQUE
		p.volume_db = SILENCE_DB
		add_child(p)
		_lecteurs_musique.append(p)
	for i in NB_LECTEURS_SONS:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SONS
		add_child(p)
		_lecteurs_sons.append(p)
	var arbre := get_tree()
	arbre.scene_changed.connect(_scene_changee)
	arbre.node_added.connect(_noeud_ajoute)
	# Boutons déjà présents (premier écran)
	_brancher_boutons(arbre.root)
	if _musique_en_attente != "-":
		_jouer_musique(_musique_en_attente)
	else:
		_scene_changee()


## Les bus viennent normalement de res://default_bus_layout.tres (chargé par Godot au démarrage).
## Secours s'il manque : on agrandit la liste avec bus_count (AudioServer.add_bus() casse
## le son sur la version web : bug connu de Godot).
static func _creer_bus() -> void:
	for nom in [BUS_MUSIQUE, BUS_SONS]:
		if AudioServer.get_bus_index(nom) == -1:
			AudioServer.bus_count = AudioServer.bus_count + 1
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nom)
			AudioServer.set_bus_send(i, "Master")


static func _appliquer_volumes() -> void:
	_creer_bus()
	for type in ["musique", "sons"]:
		var i := AudioServer.get_bus_index(BUS_MUSIQUE if type == "musique" else BUS_SONS)
		var v := get_volume(type)
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.001)))


## Chemin du fichier (ogg, mp3 ou wav), "" s'il n'existe pas.
static func _trouver(dossier: String, nom: String) -> String:
	for ext in EXTENSIONS:
		var chemin: String = dossier + nom + "." + ext
		if ResourceLoader.exists(chemin):
			return chemin
	return ""


func _flux(dossier: String, nom: String) -> AudioStream:
	var cle := dossier + nom
	if not _cache.has(cle):
		var chemin := _trouver(dossier, nom)
		_cache[cle] = load(chemin) as AudioStream if chemin != "" else null
	return _cache[cle]


# ---------------------------------------------------------------- Musique

func _scene_changee() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var fichier := scene.scene_file_path.get_file()
	var nom: String = MUSIQUE_PAR_SCENE.get(fichier, MUSIQUE_PAR_DEFAUT)
	if nom == "":
		return            # l'écran choisit lui-même
	_jouer_musique(nom)


func _jouer_musique(nom: String) -> void:
	_musique_en_attente = "-"
	var flux: AudioStream = null
	if nom != "":
		flux = _flux(DOSSIER_MUSIQUE, nom)
		if flux == null and REMPLACEMENTS.has(nom):
			nom = REMPLACEMENTS[nom]
			flux = _flux(DOSSIER_MUSIQUE, nom)
		if flux == null:
			nom = ""
	var ancien := _lecteurs_musique[_actif]
	if nom == _musique_actuelle and (nom == "" or ancien.playing):
		return            # déjà en cours : on ne recommence pas
	_musique_actuelle = nom
	_fondu(_actif, SILENCE_DB, true)
	if flux == null:
		return
	if "loop" in flux:
		flux.set("loop", not SANS_BOUCLE.has(nom))
	_actif = 1 - _actif
	var p := _lecteurs_musique[_actif]
	p.stream = flux
	p.volume_db = 0.0 if _web else SILENCE_DB
	p.play()
	_fondu(_actif, 0.0, false)


func _fondu(index: int, cible_db: float, arreter: bool) -> void:
	if _tweens[index] != null and _tweens[index].is_valid():
		_tweens[index].kill()
	var p := _lecteurs_musique[index]
	if not p.playing:
		return
	if _web:
		# Version web : pas de fondu (le volume d'un son déjà lancé ne suit pas toujours)
		if arreter:
			p.stop()
		p.volume_db = cible_db
		return
	var tw := create_tween()
	# fondu plus rapide à la sortie, plus doux à l'entrée
	tw.tween_property(p, "volume_db", cible_db, FONDU * (0.7 if arreter else 1.0)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN if arreter else Tween.EASE_OUT)
	if arreter:
		tw.tween_callback(p.stop)
	_tweens[index] = tw


# ---------------------------------------------------------------- Bruitages

func _jouer_son(nom: String, volume_db: float) -> void:
	var flux := _flux(DOSSIER_SONS, nom)
	if flux == null:
		return
	var maintenant := Time.get_ticks_msec()
	if maintenant - int(_derniere_fois.get(nom, -100000)) < ESPACEMENT_MS:
		return
	_derniere_fois[nom] = maintenant
	var p := _lecteur_libre(SONS_PRIORITAIRES.has(nom))
	if p == null:
		return
	p.stream = flux
	p.volume_db = volume_db + float(VOLUME_SONS.get(nom, 0.0))
	p.pitch_scale = randf_range(0.94, 1.06) if HAUTEUR_VARIABLE.has(nom) else 1.0
	p.set_meta("prioritaire", SONS_PRIORITAIRES.has(nom))
	p.play()


func _lecteur_libre(prioritaire: bool) -> AudioStreamPlayer:
	for p in _lecteurs_sons:
		if not p.playing:
			return p
	if not prioritaire:
		return null       # trop de sons : on saute celui-ci
	# on coupe un son ordinaire pour laisser la place
	for p in _lecteurs_sons:
		if not p.get_meta("prioritaire", false):
			p.stop()
			return p
	return null


# ---------------------------------------------------------------- Web

## Version web : le navigateur bloque le son tant que le joueur n'a pas cliqué.
## Au premier clic ou touche, on relance la musique en cours pour être sûr qu'on l'entende.
func _input(event: InputEvent) -> void:
	if not _web or _geste_recu:
		return
	if (event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch) and event.is_pressed():
		_geste_recu = true
		set_process_input(false)
		var p := _lecteurs_musique[_actif]
		if _musique_actuelle != "" and p.stream != null:
			p.volume_db = 0.0
			p.play(p.get_playback_position() if p.playing else 0.0)


# ---------------------------------------------------------------- Boutons

func _noeud_ajoute(n: Node) -> void:
	if n is BaseButton:
		_brancher(n)


func _brancher_boutons(n: Node) -> void:
	if n is BaseButton:
		_brancher(n)
	for e in n.get_children():
		_brancher_boutons(e)


func _brancher(b: BaseButton) -> void:
	if b.has_meta("audio_branche") or b.has_meta("sans_clic"):
		return
	b.set_meta("audio_branche", true)
	b.pressed.connect(_clic.bind(b))


func _clic(b: BaseButton) -> void:
	if not is_instance_valid(b) or b.has_meta("sans_clic"):
		return
	var texte := ""
	if b is Button:
		texte = (b as Button).text.to_lower()
	if texte.contains("retour") or texte.contains("fermer") or texte.begins_with("←") or texte.begins_with("<"):
		_jouer_son("retour", 0.0)
	else:
		_jouer_son("clic", 0.0)
