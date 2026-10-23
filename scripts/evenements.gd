class_name Evenements
extends RefCounted
## ÉVÉNEMENTS D'INVOCATION : invocations spéciales à durée limitée.
## Elles s'affichent dans le bandeau en bas de l'Autel d'Invocation.
##
## POUR AJOUTER UN ÉVÉNEMENT : copie un bloc de EVENEMENTS et change :
##   id          : nom unique (sert aussi pour l'image du bandeau)
##   debut / fin : dates au format "AAAA-MM-JJ" (inclus, heure locale du joueur)
##   vedettes    : unités mises en avant (invocables ou non !)
##   chance_vedette : quand la rareté tirée est celle d'une vedette, chance d'obtenir la vedette
##   taux, prix_x1, prix_x10 : comme les autres pactes (payés en Éclats de Pacte Supérieur)
## Image du bandeau (facultative) : res://assets/invocation/evenements/<id>.png  (1600 x 220 conseillé)

const EVENEMENTS := [
	{
		"id": "lune_de_sang",
		"titre": "LUNE DE SANG",
		"sous_titre": "Sous l'astre écarlate, les seigneurs des ténèbres répondent à ton appel.",
		"debut": "2026-09-26", "fin": "2026-10-10",
		"couleur": "d02030",
		"vedettes": ["empereur_dechu", "dragon_ombre", "archange_noir"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "aube_celeste",
		"titre": "AUBE CÉLESTE",
		"sous_titre": "Les créatures de lumière descendent des cieux pour quelques jours seulement.",
		"debut": "2026-10-11", "fin": "2026-10-25",
		"couleur": "e8c050",
		"vedettes": ["cheval_sacre", "phenix_immortel", "chien_sylvestre"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	# ---- Calendrier 2026-2027 : une invocation par saison ou fête, et quelques-unes pour une famille de monstres ----
	{
		"id": "nuit_lanternes",
		"titre": "LA NUIT DES LANTERNES NOIRES",
		"sous_titre": "Halloween : les morts sortent de leurs tombes, guidés par des lanternes de suie.",
		"debut": "2026-10-26", "fin": "2026-11-08",
		"couleur": "e07a20",
		"vedettes": ["reine_liches", "stephane_buteur", "archange_noir"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "chant_brumes",
		"titre": "LE CHANT DES BRUMES",
		"sous_titre": "Fin d'automne : dans les forêts noyées de brume, les esprits sylvestres s'éveillent.",
		"debut": "2026-11-16", "fin": "2026-11-29",
		"couleur": "8aa080",
		"vedettes": ["druidesse_ronces", "cerf_roi", "exorciste_dechu"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "nuit_givre",
		"titre": "LA NUIT DE GIVRE",
		"sous_titre": "Noël : la mer gèle sous la neige, et les géants des abysses remontent sous la glace.",
		"debut": "2026-12-14", "fin": "2026-12-31",
		"couleur": "8ad0ff",
		"vedettes": ["leviathan_abyssal", "titan_abysses", "chat_des_abysses"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "aube_an_neuf",
		"titre": "L'AUBE DE L'AN NEUF",
		"sous_titre": "Nouvel An : la première lumière de l'année bénit les héros au serment sacré.",
		"debut": "2027-01-01", "fin": "2027-01-10",
		"couleur": "ffe9a8",
		"vedettes": ["cheval_sacre", "princesse_sceaux", "elu_lame"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "coeurs_epines",
		"titre": "CŒURS D'ÉPINES",
		"sous_titre": "Saint-Valentin : des roses noires poussent partout où un cœur a été brisé.",
		"debut": "2027-02-06", "fin": "2027-02-19",
		"couleur": "e0407a",
		"vedettes": ["druidesse_ronces", "nymphe", "ondine_recifs"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "bal_masques",
		"titre": "LE BAL DES MASQUES",
		"sous_titre": "Carnaval : derrière chaque masque se cache une lame. Qui danse avec toi ce soir ?",
		"debut": "2027-02-20", "fin": "2027-03-05",
		"couleur": "b060e0",
		"vedettes": ["mercenaire_sans_nom", "dague_violette", "lapin_pyromane"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "eveil_seve",
		"titre": "L'ÉVEIL DE LA SÈVE",
		"sous_titre": "Printemps : les ruines refleurissent et les sources se remettent à chanter.",
		"debut": "2027-03-13", "fin": "2027-03-27",
		"couleur": "6ad04a",
		"vedettes": ["fleuriste_ruines", "axolotl_sources", "chien_sylvestre"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "oeufs_dragon",
		"titre": "LES ŒUFS DE DRAGON",
		"sous_titre": "Pâques : dans les nids de lave, d'étranges œufs écailleux commencent à éclore.",
		"debut": "2027-03-28", "fin": "2027-04-10",
		"couleur": "ff9a3a",
		"vedettes": ["phenix_immortel", "dragon_ombre", "wyverne"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "cour_insectes",
		"titre": "LA COUR DES INSECTES",
		"sous_titre": "Sous la terre, un royaume oublié de chitine et de soie ouvre ses portes.",
		"debut": "2027-04-11", "fin": "2027-04-23",
		"couleur": "a8a0c8",
		"vedettes": ["chasseresse_soie", "errant_silencieux", "reine_araignee"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "nuit_walpurgis",
		"titre": "LA NUIT DE WALPURGIS",
		"sous_titre": "La nuit des sorciers : grimoires ouverts, chaudrons en feu, liches au sabbat.",
		"debut": "2027-04-24", "fin": "2027-05-07",
		"couleur": "9a4ae0",
		"vedettes": ["mage_gris", "mage", "liche_mineure"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "legendes_valcendre",
		"titre": "LES LÉGENDES DES VALCENDRE",
		"sous_titre": "Les héros de légende répondent plus souvent à l'appel : chances de Légende augmentées.",
		"debut": "2027-05-22", "fin": "2027-06-04",
		"couleur": "f0d080",
		"vedettes": ["brute_noire", "samourai_rouge", "chevalier_blanc"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.76], ["SSR", 0.2], ["UR", 0.03], ["LEG", 0.01]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "brasier_solstice",
		"titre": "LE BRASIER DU SOLSTICE",
		"sous_titre": "Été : la nuit la plus courte de l'année brûle de mille feux de forge.",
		"debut": "2027-06-19", "fin": "2027-07-02",
		"couleur": "ff5a2a",
		"vedettes": ["combattante_ardente", "phenix_immortel", "forgeronne_ecarlate"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "maree_abysses",
		"titre": "LA MARÉE DES ABYSSES",
		"sous_titre": "Plein été : la mer se retire d'un coup et découvre des cités englouties.",
		"debut": "2027-07-17", "fin": "2027-07-30",
		"couleur": "3a8ae0",
		"vedettes": ["leviathan_abyssal", "barbe_bleue", "hydre_jeune"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "regne_dragons",
		"titre": "LE RÈGNE DES DRAGONS",
		"sous_titre": "Le ciel s'assombrit sous des ailes immenses : les dragons revendiquent leurs terres.",
		"debut": "2027-08-14", "fin": "2027-08-27",
		"couleur": "c0302a",
		"vedettes": ["dragon_ombre", "wyverne", "hydre_jeune"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "moisson_pourpre",
		"titre": "LA MOISSON POURPRE",
		"sous_titre": "Rentrée : les champs rougissent, et les chasseurs de primes reprennent la route.",
		"debut": "2027-09-04", "fin": "2027-09-17",
		"couleur": "b0202a",
		"vedettes": ["chasseur_primes", "seraphin_dechu", "golem_obsidienne"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.775], ["SSR", 0.195], ["UR", 0.027], ["LEG", 0.003]],
		"prix_x1": 1, "prix_x10": 10,
	},
	{
		"id": "lune_de_sang_an1",
		"titre": "LUNE DE SANG — UN AN DÉJÀ",
		"sous_titre": "Anniversaire du jeu : l'astre écarlate revient, avec les seigneurs de la première nuit.",
		"debut": "2027-09-26", "fin": "2027-10-10",
		"couleur": "d02030",
		"vedettes": ["empereur_dechu", "dragon_ombre", "archange_noir"],
		"chance_vedette": 0.5,
		"taux": [["SR", 0.76], ["SSR", 0.2], ["UR", 0.03], ["LEG", 0.01]],
		"prix_x1": 1, "prix_x10": 10,
	},
]


## Date du jour "AAAA-MM-JJ" (heure locale, suit Calendrier pour les tests).
static func aujourdhui() -> String:
	var d := Time.get_date_dict_from_unix_time(Calendrier.jour_absolu() * 86400)
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## L'événement en cours ({} s'il n'y en a pas).
static func actif() -> Dictionary:
	var j := aujourdhui()
	for e in EVENEMENTS:
		if j >= str(e["debut"]) and j <= str(e["fin"]):
			return e
	return {}


## Le prochain événement à venir ({} s'il n'y en a pas).
static func prochain() -> Dictionary:
	var j := aujourdhui()
	var meilleur: Dictionary = {}
	for e in EVENEMENTS:
		if str(e["debut"]) > j and (meilleur.is_empty() or str(e["debut"]) < str(meilleur["debut"])):
			meilleur = e
	return meilleur


## Secondes restantes avant la fin de l'événement (le jour de fin est inclus, jusqu'à minuit).
## (dates lues comme heure locale, comparées à Calendrier.maintenant_local)
static func secondes_restantes(e: Dictionary) -> int:
	var fin := int(Time.get_unix_time_from_datetime_string(str(e["fin"]) + "T00:00:00")) + 86400
	return maxi(0, fin - Calendrier.maintenant_local())


static func secondes_avant_debut(e: Dictionary) -> int:
	var debut := int(Time.get_unix_time_from_datetime_string(str(e["debut"]) + "T00:00:00"))
	return maxi(0, debut - Calendrier.maintenant_local())


## Vedettes d'une rareté donnée ("LEG" = légende).
static func vedettes_de(e: Dictionary, rarete: String) -> Array:
	var l: Array = []
	for id in e.get("vedettes", []):
		var u := UnitesData.get_unite(id)
		if u.is_empty():
			continue
		var r: String = "LEG" if u.get("legende", false) else str(u["rarete"])
		if r == rarete:
			l.append(id)
	return l
