class_name CombatClasse
extends Node
## ARÈNE CLASSÉE : déroulement d'un combat MANUEL à deux joueurs (ajouté par l'écran de combat).
##
## Les deux appareils calculent le même combat (même graine, mêmes équipes, CombatMoteur en mode
## manuel). Chaque action a un numéro (0, 1, 2...) et le serveur garde la liste des actions :
##  - quand c'est au tour d'une de MES unités : je choisis (minuteur de 15 s, sinon l'IA choisit),
##    j'envoie l'action au serveur et je joue celle qu'il a retenue ;
##  - quand c'est au tour d'une unité ADVERSE : je lis les actions du serveur (toutes les secondes).
##    Si l'adversaire ne joue plus, l'IA joue à sa place au bout de 40 s, et s'il a quitté le jeu
##    depuis 60 s, la victoire par forfait est réclamée.
## À la fin, le résultat (le même des deux côtés) est envoyé au serveur, qui calcule les points.

const MINUTEUR := 15.0
const ATTENTE_ABSENCE := 42          # un peu plus que le délai du serveur (40 s)
const ATTENTE_FORFAIT := 62

var ecran: EcranCombat
var moteur: CombatMoteur
## Accès au serveur (remplaçable par un faux serveur pour les tests).
var reseau: Object = EnLigne
## Tests automatiques uniquement : faux serveur par camp (vide dans le jeu).
static var reseaux_test := {}
var _match: Dictionary
var _camp := 0
var _n := 0
var _cache := {}                     # n -> action déjà connue
var _fin := false
var _rattrapage := 0                 # reprise d'un combat : actions déjà jouées (rejouées sans animation)

# Interface : barre d'actions à icônes (partagée avec le combat manuel contre l'ordinateur)
var _barre: BarreActions


func _ready() -> void:
	_match = ecran.demande_combat["match"]
	_camp = ecran.mon_camp()
	if reseaux_test.has(_camp):
		reseau = reseaux_test[_camp]
	_barre = BarreActions.new(ecran)
	_barre.minuteur = MINUTEUR
	ecran.add_child(_barre)
	var ab := ecran._bouton(UiCommun.t("Abandonner"))
	ab.pressed.connect(func():
		FenetreSimple.confirmer(ecran, UiCommun.t("Abandonner le combat ?"), UiCommun.t("Le combat compte comme une défaite."), UiCommun.t("Abandonner"), _abandonner))
	ecran.barre_haut.add_child(ab)
	moteur.demarrer_manuel()
	# Reprise (jeu relancé pendant le combat) : on récupère les actions déjà jouées
	var r: Dictionary = await reseau.appeler("ac_actions", {"p_match": _match["id"], "p_depuis": 0})
	if r.ok and r.data is Dictionary:
		for a in r.data.get("actions", []):
			_cache[int(a["n"])] = a["action"]
		_rattrapage = _cache.size()
		if str(r.data.get("etat", "en_cours")) != "en_cours":
			await _verifier_fin_serveur()
			return
	_boucle()


# =====================================================================
# Boucle du combat
# =====================================================================

func _boucle() -> void:
	await _jouer_evenements()
	while not _fin:
		var c := moteur.prochain_acteur()
		await _jouer_evenements()
		if c.is_empty():
			break
		var action: Dictionary
		if int(c["camp"]) == _camp:
			action = await _mon_action(c)
		else:
			action = await _action_adverse(c)
		if _fin:
			return
		moteur.jouer_action(c, action)
		_n += 1
		await _jouer_evenements()
	if not _fin:
		_terminer(moteur.resultat_classe())


func _jouer_evenements() -> void:
	for ev in moteur.nouveaux_evenements():
		if _fin:
			return
		if _n < _rattrapage:
			ecran._appliquer_sans_animation(ev)
		else:
			await ecran._jouer(ev)


# ---------- Mes unités ----------

func _mon_action(c: Dictionary) -> Dictionary:
	var choix := {}
	if _cache.has(_n):
		choix = _cache[_n]
	else:
		choix = await _choisir(c)
	# Le serveur garde la première action reçue pour ce numéro
	while not _fin:
		var r: Dictionary = await reseau.appeler("ac_jouer", {"p_match": _match["id"], "p_n": _n, "p_camp": int(c["camp"]), "p_action": choix})
		if r.ok and r.data is Dictionary and r.data.get("ok", false):
			return r.data["action"]
		if r.ok and r.data is Dictionary and r.data.get("erreur", "") == "termine":
			await _verifier_fin_serveur()
			return {}
		_info(UiCommun.t("Connexion difficile… nouvel essai."))
		await get_tree().create_timer(1.5).timeout
	return {}


## Affiche les actions possibles (icônes) et attend le choix du joueur (ou la fin du minuteur).
func _choisir(c: Dictionary) -> Dictionary:
	return await _barre.choisir(c, moteur.actions_possibles(c))


## Description simplifiée d'un sort pour l'arène classée, en lignes courtes :
## sans « (30 % de chance par tour) » (ici on choisit soi-même), sans la petite phrase d'ambiance.
static func texte_court(desc: String) -> Array:
	var re := RegEx.new()
	re.compile("^\\(\\d+ ?% (de chance par tour|chance per turn)\\)\\s*")
	var t := re.sub(desc.strip_edges(), "")
	# « Tourne sur lui-même, lame tendue : inflige ... » -> « Inflige ... »
	var sep := " : " if t.contains(" : ") else ": "
	var i := t.find(sep)
	if i > 0 and not t.substr(0, i).contains("%"):
		t = t.substr(i + sep.length())
	t = t.replace(" de puissance de skill", " de puissance").replace("puissance de skill", "puissance")
	t = t.replace("de chance d'infliger", "de chance :").replace("toute l'équipe", "l'équipe")
	var l: Array = []
	t = t.replace(" skill power", "").replace("the whole team", "the team")
	for morceau in t.replace("; ", " ; ").replace(" ;  ; ", " ; ").split(" ; ", false):
		var m := morceau.strip_edges().trim_suffix(".")
		if m != "":
			l.append(m.substr(0, 1).to_upper() + m.substr(1))
	if l.is_empty():
		l.append(UiCommun.t("Attaque normale"))
	return l


func _fermer_choix() -> void:
	if _barre != null:
		_barre.fermer()


# ---------- Unités adverses ----------

func _action_adverse(c: Dictionary) -> Dictionary:
	_barre.attente(UiCommun.t("Tour adverse : %s") % UiCommun.t(str(c["nom"])), int(c["idx"]))
	var debut := Time.get_ticks_msec()
	while not _fin:
		if _cache.has(_n):
			break
		var r: Dictionary = await reseau.appeler("ac_actions", {"p_match": _match["id"], "p_depuis": _n})
		if r.ok and r.data is Dictionary:
			var d: Dictionary = r.data
			for a in d.get("actions", []):
				_cache[int(a["n"])] = a["action"]
			if _cache.has(_n):
				break
			if str(d.get("etat", "")) != "en_cours":
				await _verifier_fin_serveur()
				return {}
			var absent := int(d.get("adversaire_absent", 0))
			var attente := int(d.get("depuis_derniere", 0))
			if absent >= ATTENTE_FORFAIT:
				_info(UiCommun.t("L'adversaire a quitté le combat…"))
				var f: Dictionary = await reseau.appeler("ac_forfait", {"p_match": _match["id"]})
				if f.ok and f.data is Dictionary and f.data.get("ok", false):
					_afficher_bilan(f.data)
					return {}
			elif attente >= ATTENTE_ABSENCE:
				# L'adversaire ne joue plus : l'IA joue à sa place
				var j: Dictionary = await reseau.appeler("ac_jouer", {"p_match": _match["id"], "p_n": _n, "p_camp": int(c["camp"]), "p_action": {"type": "auto"}})
				if j.ok and j.data is Dictionary and j.data.get("ok", false):
					_cache[_n] = j.data["action"]
					break
			var s := int((Time.get_ticks_msec() - debut) / 1000.0)
			_info(UiCommun.t("L'adversaire réfléchit… %d s") % s if absent < 10 else UiCommun.t("L'adversaire ne répond plus (%d s)…") % absent)
		else:
			_info(UiCommun.t("Connexion difficile…"))
		await get_tree().create_timer(1.0).timeout
	_fermer_choix()
	return _cache.get(_n, {"type": "auto"})


# =====================================================================
# Fin du combat
# =====================================================================

func _terminer(gagnant: int) -> void:
	_fin = true
	_fermer_choix()
	var r := {}
	for essai in 5:
		var rep: Dictionary = await reseau.appeler("ac_terminer", {"p_match": _match["id"], "p_gagnant": gagnant})
		if rep.ok and rep.data is Dictionary and rep.data.get("ok", false):
			r = rep.data
			break
		await get_tree().create_timer(2.0).timeout
	if r.is_empty():
		r = {"gagnant": gagnant, "delta": null, "erreur": UiCommun.t("Le résultat n'a pas pu être envoyé.")}
	_afficher_bilan(r)


func _verifier_fin_serveur() -> void:
	var r: Dictionary = await reseau.appeler("ac_terminer", {"p_match": _match["id"], "p_gagnant": -1})
	if r.ok and r.data is Dictionary:
		_afficher_bilan(r.data)


func _abandonner() -> void:
	if _fin:
		return
	_fin = true
	_fermer_choix()
	var r: Dictionary = await reseau.appeler("ac_abandonner", {"p_match": _match["id"]})
	_afficher_bilan(r.data if r.ok and r.data is Dictionary else {"gagnant": 1 - _camp})


func _afficher_bilan(d: Dictionary) -> void:
	_fin = true
	_fermer_choix()
	var g = d.get("gagnant")
	var gagnant := int(g) if g != null else -1
	var victoire := gagnant == _camp
	var lignes: Array = []
	if d.get("forfait", false):
		lignes.append(UiCommun.t("Victoire par forfait : l'adversaire a quitté le combat.") if victoire else UiCommun.t("Défaite par abandon."))
	if gagnant == -1:
		lignes.append(UiCommun.t("Égalité : le temps est écoulé avec autant de PV de chaque côté."))
	var delta = d.get("delta")
	if delta != null:
		lignes.append(UiCommun.t("Points de classement : %s%d  (total %s)") % ["+" if int(delta) >= 0 else "", int(delta), str(d.get("points", "?"))])
	if d.has("erreur"):
		lignes.append(str(d["erreur"]))
	Sauvegarde.ajouter_stat("combats_arene")
	Sauvegarde._stat("combats_classes")
	if victoire:
		Sauvegarde.ajouter_stat("combats_gagnes")
		Sauvegarde._stat("victoires_classees")
	EcranCombat.resultat = {"mode": "classee", "victoire": victoire}
	ecran._afficher_resultat(victoire, lignes, UiCommun.t("ÉGALITÉ") if gagnant == -1 else "")


# =====================================================================
# Interface
# =====================================================================

func _info(t: String) -> void:
	if _barre != null:
		_barre.info(t)
