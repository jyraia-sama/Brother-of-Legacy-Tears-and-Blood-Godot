class_name Tutoriel
extends RefCounted
## PREMIERS PAS : guide d'accueil d'un nouveau joueur.
##
##  1) Un GUIDE en 9 étapes, affiché sur le menu principal (au centre, sous l'emblème) : chaque étape
##     indique quoi faire, fait briller le bon bouton du menu et donne une petite récompense.
##     Les étapes se valident toutes seules d'après la partie (un joueur avancé les a déjà faites).
##  2) Des ASTUCES à la première visite des écrans importants (Deck, Invocation, Échos...),
##     affichées une seule fois.
## Le guide peut être masqué (et réaffiché dans les Paramètres).

## zone : bouton du menu principal à mettre en avant.
const ETAPES := [
	{"id": "deck", "titre": "Découvre ton équipe", "zone": "deck",
		"texte": "Ouvre le DECK : c'est ta collection et ton équipe de 5. Les 2 premières places sont à l'Avant.",
		"recompense": {"or": 500}},
	{"id": "combat", "titre": "Ton premier combat", "zone": "aventure",
		"texte": "AVENTURE → Histoire principale → Acte I → Chapitre 1. Avance sur le plateau et gagne un combat.",
		"recompense": {"or": 1000}},
	{"id": "chapitre", "titre": "Termine le chapitre 1", "zone": "aventure",
		"texte": "Avance jusqu'au boss du chapitre 1 et bats-le. Les boss donnent des Éclats de Pacte Supérieur.",
		"recompense": {"or": 1500, "elixir_petit": 1}},
	{"id": "invocation", "titre": "Ta première invocation", "zone": "invocation",
		"texte": "À l'AUTEL D'INVOCATION, invoque une unité avec le Pacte Doré (or) ou le Pacte Supérieur (Éclats).",
		"recompense": {"gemmes": 30}},
	{"id": "equipe", "titre": "Une équipe complète", "zone": "deck",
		"texte": "Dans le DECK, remplis les 5 places de ton équipe : clique une unité, puis une place.",
		"recompense": {"or": 2000, "tome_petit": 1}},
	{"id": "echo", "titre": "Équipe un Écho Sanguin", "zone": "echos",
		"texte": "Un Écho t'a été offert ! Dans ÉCHOS SANGUINS, choisis un héros puis équipe-le.",
		"recompense": {"poussiere_echo": 20}},
	{"id": "amelioration", "titre": "Améliore un Écho", "zone": "echos",
		"texte": "Dans ÉCHOS SANGUINS, choisis un Écho et appuie sur « Améliorer ». Chaque niveau renforce sa stat.",
		"recompense": {"or": 2000}},
	{"id": "quete", "titre": "Tes premières quêtes", "zone": "quetes",
		"texte": "Ouvre les QUÊTES (en bas à gauche) : réclame ta récompense de connexion et une quête terminée.",
		"recompense": {"gemmes": 50}},
	{"id": "acte1", "titre": "Termine l'Acte I", "zone": "aventure",
		"texte": "Termine les 6 chapitres de l'Acte I. Ensuite, tout le jeu s'offre à toi !",
		"recompense": {"gemmes": 100, "eclat_superieur": 3}},
]

## Astuces de première visite : écran -> [titre, texte]
const ASTUCES := {
	"deck": ["Le Deck", "Ta collection et ton équipe de 5.\n\n• Clique une unité puis une place pour la placer.\n• Places 1-2 = AVANT (Guerriers, Tanks, Assassins), places 3-5 = ARRIÈRE (Tireurs, Mages, Soutiens).\n• Clique une unité pour voir sa fiche : stats, sorts, vente, verrouillage."],
	"invocation": ["L'Autel d'Invocation", "• Pacte Doré : avec de l'or, pour des unités N, R et SR.\n• Pacte Supérieur : avec des Éclats (lâchés par les boss), pour des SR, SSR et UR, avec une garantie SSR.\n• Le x10 coûte un peu moins cher."],
	"echos": ["Les Échos Sanguins", "Chaque unité porte jusqu'à 6 Échos, un par emplacement.\n\n• Choisis un héros à gauche, puis un Écho dans l'inventaire à droite pour l'équiper.\n• « Améliorer » monte l'Écho de +1 à +15 (les chances baissent avec le niveau).\n• 2 ou 4 Échos du même set donnent un bonus en plus."],
	"fusion": ["L'Autel de Fusion", "• ÉVEIL : sacrifie des doublons (la même unité) pour gagner une étoile, jusqu'à ★6.\n• ABSORPTION : sacrifie n'importe quelles unités pour donner de l'XP.\nLes unités de l'équipe ne peuvent jamais être sacrifiées."],
	"plateau": ["Le plateau du chapitre", "Clique une case qui brille pour avancer.\n\n• ⚔ combats, élites, gardiens et boss coûtent de la stamina.\n• Coffres, soins et événements sont gratuits.\n• Les PV de l'équipe sont gardés d'une case à l'autre : pense aux cases de soin !"],
	"reliquaire": ["Le Reliquaire", "Tous tes objets : coffres à ouvrir, élixirs de stamina, tomes d'XP, ressources de forge et d'évolution.\n\n• La FORGE crée des héros exclusifs avec le butin des Tours et des Boss de Monde.\n• L'ATELIER fabrique des Échos avec de la Poussière d'Écho."],
	"menagerie": ["La Ménagerie", "Tes héros N et R ont enfin un rôle !\n\n• Une équipe de chasse = un héros N ou R (hors équipe de combat) + un familier.\n• Elle rapporte du butin même jeu fermé, jusqu'à 12 h : pense à venir RÉCOLTER.\n• Le héros favori de la zone (+20 %) et le terrain préféré du familier (+25 %) augmentent la récolte.\n• De nouveaux familiers s'obtiennent au Pacte Sauvage (Autel d'Invocation) avec des Sceaux Sauvages, trouvés dans les coffres de l'Aventure."],
	"aventure": ["L'Aventure", "Tous les modes de jeu :\n\n• HISTOIRE : l'aventure principale, à faire en premier.\n• TOURS, DONJONS, BOSS DE MONDE, EXPÉDITION : se débloquent et deviennent utiles au fil de ta progression.\n• ARÈNE : combats contre les autres joueurs (compte en ligne)."],
}


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("tutoriel") or not Sauvegarde.donnees["tutoriel"] is Dictionary:
		Sauvegarde.donnees["tutoriel"] = {}
	var t: Dictionary = Sauvegarde.donnees["tutoriel"]
	for cle in ["reclames", "vus"]:
		if not t.has(cle):
			t[cle] = []
	if not t.has("masque"):
		t["masque"] = false
	return t


# ---------------------------------------------------------------------
# Guide
# ---------------------------------------------------------------------

## L'étape est-elle accomplie ? (d'après l'état de la partie)
static func faite(id: String) -> bool:
	match id:
		"deck": return "deck" in _etat()["vus"]
		"combat": return Sauvegarde.get_stat("combats_gagnes") >= 1
		"chapitre": return Sauvegarde.nombre_chapitres_termines() >= 1
		"invocation": return Succes.valeur("invocations") >= 1
		"equipe": return Sauvegarde.get_equipe().size() >= Deblocages.places_equipe()
		"echo":
			for e in Sauvegarde.liste_echos():
				if int(e["porteur"]) >= 0:
					return true
			return false
		"amelioration":
			if Sauvegarde.get_stat("ameliorations_echo") >= 1:
				return true
			for e in Sauvegarde.liste_echos():
				if int(e["niveau"]) > 0:
					return true
			return false
		"quete": return Sauvegarde.get_stat("quetes_reclamees") >= 1
		"acte1": return Sauvegarde.est_termine(1, 6)
	return false


## Index de l'étape en cours (première non réclamée), ou -1 si le guide est fini.
static func etape_courante() -> int:
	var rec: Array = _etat()["reclames"]
	for i in ETAPES.size():
		if not ETAPES[i]["id"] in rec:
			return i
	return -1


static func termine() -> bool:
	return etape_courante() < 0


static func visible() -> bool:
	return not termine() and not bool(_etat()["masque"])


static func masquer(oui: bool) -> void:
	_etat()["masque"] = oui
	Sauvegarde.sauvegarder()


## Réclame la récompense de l'étape en cours (si elle est faite). Renvoie les lignes.
static func reclamer() -> Array:
	var i := etape_courante()
	if i < 0 or not faite(ETAPES[i]["id"]):
		return []
	_etat()["reclames"].append(ETAPES[i]["id"])
	var l := Quetes.donner(ETAPES[i]["recompense"])
	if termine():
		l.append("Guide des premiers pas terminé. Bonne route, héros !")
	Sauvegarde.sauvegarder()
	preparer_etape()
	return l


## Prépare ce dont l'étape a besoin (ex. : offre un Écho pour l'étape « Équipe un Écho »).
static func preparer_etape() -> void:
	var i := etape_courante()
	if i < 0:
		return
	var t := _etat()
	if ETAPES[i]["id"] == "echo" and not "echo_offert" in t["vus"]:
		t["vus"].append("echo_offert")
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var principales: Array = Echos.EMPLACEMENTS[1]["principales"]
		Sauvegarde.ajouter_echo(Echos.creer(Echos.SET_PAR_ACTE[1], 1, 2, 3, principales[0], rng))
		Sauvegarde.sauvegarder()


# ---------------------------------------------------------------------
# Astuces de première visite
# ---------------------------------------------------------------------

## À appeler dans _ready() d'un écran : affiche son astuce la première fois.
static func astuce(ecran: String, parent: Node) -> void:
	var t := _etat()
	if ecran in t["vus"] or not ASTUCES.has(ecran):
		if not ecran in t["vus"]:
			t["vus"].append(ecran)
			Sauvegarde.sauvegarder()
		return
	t["vus"].append(ecran)
	Sauvegarde.sauvegarder()
	if bool(t["masque"]):
		return
	var a: Array = ASTUCES[ecran]
	FenetreSimple.ouvrir.call_deferred(parent, "Astuce — " + str(a[0]), a[1], [["Compris !", null]])


## Guides complets ouverts tout seuls à la première visite (ex. guide des Échos).
const GUIDES_AUTO := ["guide_echos", "guide_guerre"]


## Vrai la première fois seulement (puis la clé est marquée comme vue).
static func premiere_fois(cle: String) -> bool:
	var t := _etat()
	if cle in t["vus"]:
		return false
	t["vus"].append(cle)
	Sauvegarde.sauvegarder()
	return true


## Réaffiche toutes les astuces (Paramètres).
static func reinitialiser_astuces() -> void:
	var t := _etat()
	t["vus"] = t["vus"].filter(func(v): return not ASTUCES.has(v) and not v in GUIDES_AUTO)
	t["masque"] = false
	Sauvegarde.sauvegarder()
