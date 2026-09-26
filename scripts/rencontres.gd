class_name Rencontres
extends RefCounted
## RENCONTRES : quels ennemis apparaissent sur chaque case de combat du plateau.
##
## Chaque Acte a ses propres monstres (POOLS). La force des ennemis est calculée
## par rapport à la force ATTENDUE du joueur à ce moment de l'aventure :
## la difficulté monte avec les Actes mais reste toujours "juste".
##
## Pour ajuster la difficulté : change RATIOS (force ennemie / force du joueur attendue).
## Une même case donne toujours les mêmes ennemis (on peut retenter le combat).

const T := PlateauGenerateur.Type

## DIFFICULTÉ GLOBALE : 1.0 = normal, 0.9 = plus facile, 1.1 = plus difficile.
const DIFFICULTE := 1.0

## Force des ennemis par rapport à l'équipe de référence du joueur (réglée par simulation).
const RATIOS := {
	"combat": 0.87,
	"elite": 0.92,
	"gardien": 0.90,
	"boss_chapitre": 0.94,
	"boss_acte": 0.73,
}
## Renfort des ennemis pour tenir compte des Échos Sanguins que le joueur est censé porter
## à chaque Acte (réglé par simulation : sans Échos ~10 points de victoire en moins que la cible,
## avec un équipement typique ~20 points de plus : bien s'équiper est un vrai avantage).
const ECHOS_ATTENDUS := [1.02, 1.03, 1.05, 1.06, 1.06, 1.07, 1.08, 1.09, 1.10, 1.11, 1.12, 1.12]

## Taux de victoire visés (équipe de référence, PV pleins) :
##   combat 93 %  ·  élite 78 %  ·  gardien 68 %  ·  boss de chapitre 60 %  ·  boss d'Acte 50 %
## Réglage fin par Acte et par type, calculé par simulation (1.0 = neutre).
const CALIBRAGE := {
	1: {"combat": 1.51, "elite": 1.52, "gardien": 1.68, "boss_chapitre": 1.58, "boss_acte": 0.78},
	2: {"combat": 1.27, "elite": 1.45, "gardien": 1.36, "boss_chapitre": 1.32, "boss_acte": 1.29},
	3: {"combat": 1.3, "elite": 1.24, "gardien": 1.39, "boss_chapitre": 1.31, "boss_acte": 1.26},
	4: {"combat": 1.22, "elite": 1.3, "gardien": 1.31, "boss_chapitre": 1.26, "boss_acte": 1.2},
	5: {"combat": 1.06, "elite": 1.13, "gardien": 0.95, "boss_chapitre": 0.99, "boss_acte": 1.16},
	6: {"combat": 1.18, "elite": 1.17, "gardien": 1.24, "boss_chapitre": 1.25, "boss_acte": 1.44},
	7: {"combat": 0.98, "elite": 1.28, "gardien": 1.13, "boss_chapitre": 1.09, "boss_acte": 1.03},
	8: {"combat": 0.87, "elite": 0.85, "gardien": 0.95, "boss_chapitre": 0.99, "boss_acte": 1.0},
	9: {"combat": 0.9, "elite": 1.03, "gardien": 1.09, "boss_chapitre": 1.13, "boss_acte": 1.64},
	10: {"combat": 1.04, "elite": 0.98, "gardien": 1.12, "boss_chapitre": 1.15, "boss_acte": 0.98},
	11: {"combat": 0.78, "elite": 0.89, "gardien": 0.91, "boss_chapitre": 1.01, "boss_acte": 1.22},
	12: {"combat": 0.73, "elite": 0.79, "gardien": 0.95, "boss_chapitre": 0.85, "boss_acte": 0.85},
}

## Force relative des unités spéciales dans leur groupe
const POIDS_ELITE := 1.4
const POIDS_GARDIEN := 1.6
const POIDS_BOSS_CHAPITRE := 2.1
const POIDS_BOSS_ACTE := 2.5
const BONUS_NIVEAU := {"combat": 0, "elite": 1, "gardien": 1, "boss_chapitre": 2, "boss_acte": 2}

const POOLS := {
	1: {"monstres": ["gobelin_maraudeur", "loup_affame", "rat_corrompu", "bandit", "vautour_charognard", "pillard_incendiaire", "patrouilleur_vautour", "profanateur_tombes", "rat_geant", "brigand"], "gardiens": ["pillard_incendiaire", "profanateur_tombes", "brigand"], "boss": "seigneur_des_cendres"},
	2: {"monstres": ["zombie", "esprit_frappeur", "moine_dechu", "chauve_souris_vampire", "corbeau_maudit", "pestifere_errant", "porteur_lanterne", "souvenir_spectral", "banshee"], "gardiens": ["porteur_lanterne", "banshee", "souvenir_spectral"], "boss": "veuve_lanternes"},
	3: {"monstres": ["brigand_cagoule", "bandit", "orc_guerrier", "assassin_ombre", "centaure_guerrier", "mercenaire_balafre", "arbaletrier_noir", "receleur_ombre", "hyene_des_sables"], "gardiens": ["cyclope", "mercenaire_balafre", "orc_guerrier"], "boss": "capitaine_drapeau_noir"},
	4: {"monstres": ["squelette", "golem_fissure", "ombre_rampante", "chevalier_rouille", "garde_os", "gargouille", "zombie_enrage", "araignee_geante"], "gardiens": ["liche_mineure", "pretre_autel", "golem_fissure"], "boss": "seigneur_donjon"},
	5: {"monstres": ["hyene_des_sables", "spectre_vengeur", "harpie_sanglante", "fanatique_zelote", "mirage_vaincu", "cyclope_furieux", "vautour_charognard"], "gardiens": ["demon_mineur", "mirage_vaincu", "cyclope_furieux"], "boss": "inquisiteur_implacable"},
	6: {"monstres": ["golem_pierre", "gargouille", "statue_hurlante", "aberration_cristal", "spectre_glacial", "gargouille_jade"], "gardiens": ["golem_obsidienne", "gargouille_jade", "statue_hurlante"], "boss": "reflet_ame"},
	7: {"monstres": ["araignee_geante", "troll_marais", "serpent_crache", "limace_acide", "liane_venimeuse", "bete_tourbieres", "sorciere_bois", "harpie"], "gardiens": ["reine_araignee", "gardien_foret", "bete_tourbieres"], "boss": "dame_ronciers"},
	8: {"monstres": ["loup_garou", "harpie_sanglante", "demon_flamme", "rodeur_eclipse", "demon_siege", "chimere", "vouivre_ecarlate"], "gardiens": ["vouivre_ecarlate", "demon_siege", "chimere"], "boss": "avatar_eclipse"},
	9: {"monstres": ["chevalier_dechu", "spectre_vengeur", "liche_novice", "champion_dechu", "pilleur_royal", "seraphin_dechu"], "gardiens": ["champion_dechu", "seraphin_dechu", "chevalier_dechu"], "boss": "ombre_premier_roi"},
	10: {"monstres": ["troll_cavernes", "hydre_bicephale", "demon_mineur", "tortionnaire", "abomination", "cyclope_furieux", "wyverne"], "gardiens": ["hydre_bicephale", "abomination", "tortionnaire"], "boss": "maitre_supplices"},
	11: {"monstres": ["chevalier_dechu", "garde_fratricide", "compagnon_traitre", "assassin_ombre", "archange_noir", "dragon_ombre"], "gardiens": ["archange_noir", "garde_fratricide", "dragon_ombre"], "boss": "frere_masque"},
	12: {"monstres": ["garde_cendres", "heraut_apocalypse", "reine_liches", "demon_mineur", "rodeur_eclipse", "tortionnaire"], "gardiens": ["boss", "empereur_dechu", "garde_cendres"], "boss": "heritier_maudit"},
}

## Équipe de référence du joueur à chaque Acte (raretés), utilisée pour doser la difficulté.
## Volontairement prudente : un joueur un peu malchanceux au gacha doit pouvoir avancer.
const EQUIPE_REFERENCE := {
	1: ["LEG", "R", "R", "SR"],
	2: ["LEG", "R", "SR", "SR"],
	3: ["LEG", "R", "SR", "SR", "R"],
	4: ["LEG", "SR", "SR", "SR", "R"],
	5: ["LEG", "SR", "SR", "SR", "SR"],
	6: ["LEG", "SSR", "SR", "SR", "SR"],
	7: ["LEG", "SSR", "SR", "SR", "SR"],
	8: ["LEG", "SSR", "SSR", "SR", "SR"],
	9: ["LEG", "SSR", "SSR", "SR", "SR"],
	10: ["LEG", "SSR", "SSR", "SSR", "SR"],
	11: ["LEG", "SSR", "SSR", "SSR", "SR"],
	12: ["LEG", "SSR", "SSR", "SSR", "SSR"],
}

static var _cache_puissance := {}
## Réservé aux tests d'équilibrage (laisser vide).
static var calibrage_test := {}


## Récompenses d'une victoire : or pour le joueur, XP de base pour chaque héros.
const MULT_RECOMPENSE := {"combat": 1.0, "elite": 1.8, "gardien": 2.5, "boss_chapitre": 4.0, "boss_acte": 6.0}
const MULT_OR := {"combat": 1.0, "elite": 2.2, "gardien": 3.0, "boss_chapitre": 5.0, "boss_acte": 7.0}

static func or_victoire(type: String, niveau_ennemi: int) -> int:
	return int((20 + niveau_ennemi * 6) * MULT_OR[type])


## XP gagnée par un héros. Rattrapage : un héros en retard sur le niveau prévu
## pour ce chapitre gagne plus, un héros en avance gagne beaucoup moins.
static func xp_victoire(type: String, niveau_heros: int, acte: int, chapitre: int) -> int:
	var p := (acte - 1) * 6 + (chapitre - 1)
	var attendu := niveau_attendu(acte, chapitre)
	var base := Sauvegarde.xp_heros_pour_niveau(attendu) / (XP_DIVISEUR + p * XP_PENTE)
	var rattrapage := clampf(1.0 + 0.35 * (attendu - niveau_heros), 0.15, 2.5)
	return maxi(1, int(round(base * MULT_RECOMPENSE[type] * rattrapage)))

const XP_DIVISEUR := 16.0
const XP_PENTE := 0.35


## Accueil : les premiers chapitres sont nettement plus doux (x0,72 au tout début),
## puis la difficulté rejoint la courbe normale à la fin de l'Acte II.
static func accueil(acte: int, chapitre: int) -> float:
	var p := (acte - 1) * 6 + (chapitre - 1)
	return 0.72 + 0.28 * minf(1.0, p / 12.0)


## Pente de difficulté : l'Acte I est plus clément (x0,88), l'Acte XII plus exigeant (x1,02).
static func pente(acte: int, chapitre: int) -> float:
	var p := (acte - 1) * 6 + (chapitre - 1)
	return 0.88 + 0.14 * p / 71.0


## Niveau attendu des héros du joueur au début d'un chapitre.
static func niveau_attendu(acte: int, chapitre: int) -> int:
	var p := (acte - 1) * 6 + (chapitre - 1)
	return clampi(1 + int(round(p * 28.0 / 71.0)), 1, UnitesData.NIVEAU_MAX)


## Niveau réel des ennemis d'une case (affiché sur le plateau).
static func niveau_ennemis(acte: int, chapitre: int, noeud: Dictionary) -> int:
	return clampi(niveau_attendu(acte, chapitre) + BONUS_NIVEAU[type_rencontre(noeud, chapitre)], 1, UnitesData.NIVEAU_MAX)


## Type de rencontre d'une case du plateau.
static func type_rencontre(noeud: Dictionary, chapitre: int) -> String:
	match int(noeud["type"]):
		T.ELITE: return "elite"
		T.GARDIEN: return "gardien"
		T.BOSS: return "boss_acte" if chapitre == 6 else "boss_chapitre"
	return "combat"


## Crée l'équipe ennemie d'une case. Renvoie un tableau prêt pour CombatMoteur.
static func generer(acte: int, chapitre: int, noeud: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-rencontre-%d-%d-%d" % [acte, chapitre, int(noeud["id"])])
	var pool: Dictionary = POOLS[acte]
	var type := type_rencontre(noeud, chapitre)
	# Niveau des ennemis : celui attendu pour le joueur à ce chapitre (+1/+2 pour élites, gardiens, boss)
	var niveau := clampi(niveau_attendu(acte, chapitre) + BONUS_NIVEAU[type], 1, UnitesData.NIVEAU_MAX)
	var p := (acte - 1) * 6 + (chapitre - 1)

	# Nombre de monstres ordinaires
	var nb := 3
	if p < 3:
		nb = 2
	elif acte >= 7:
		nb = 4
	var membres: Array = []   # [id, poids, nom, boss, elite]
	match type:
		"combat":
			for i in nb:
				membres.append([_tirer(rng, pool["monstres"]), 1.0, "", false, false])
		"elite":
			var chef := _tirer(rng, pool["monstres"])
			membres.append([chef, POIDS_ELITE, "Élite : " + UnitesData.get_unite(chef)["nom"], false, true])
			for i in maxi(2, nb - 1):
				membres.append([_tirer(rng, pool["monstres"]), 1.0, "", false, false])
		"gardien":
			var g := _tirer(rng, pool["gardiens"])
			membres.append([g, POIDS_GARDIEN, "Gardien : " + UnitesData.get_unite(g)["nom"], false, true])
			for i in 2:
				membres.append([_tirer(rng, pool["monstres"]), 1.0, "", false, false])
		"boss_chapitre":
			var b: String = pool["gardiens"][(chapitre - 1) % pool["gardiens"].size()]
			membres.append([b, POIDS_BOSS_CHAPITRE, "Chef : " + UnitesData.get_unite(b)["nom"], true, false])
			for i in 2:
				membres.append([_tirer(rng, pool["monstres"]), 1.0, "", false, false])
		"boss_acte":
			membres.append([pool["boss"], POIDS_BOSS_ACTE, "", true, false])
			for i in 2:
				membres.append([_tirer(rng, pool["gardiens"] if i == 0 else pool["monstres"]), 1.0, "", false, false])

	# Force visée = équipe de référence x ratio du type de case
	var calib: float = calibrage_test.get("%d-%s" % [acte, type], (CALIBRAGE.get(acte, {}) as Dictionary).get(type, 1.0))
	var cible: float = puissance_reference(acte, chapitre) * RATIOS[type] * calib * DIFFICULTE * pente(acte, chapitre) \
		* ECHOS_ATTENDUS[acte - 1] * accueil(acte, chapitre)
	var brut := 0.0
	for m in membres:
		brut += UnitesData.puissance(m[0], niveau) * m[1]
	var facteur: float = cible / maxf(1.0, brut)

	# Placement : corps à corps devant, distance derrière
	membres.sort_custom(func(a, b): return _ordre_place(a[0]) < _ordre_place(b[0]))
	var equipe: Array = []
	for m in membres:
		var e := {"id": m[0], "niveau": niveau, "mult": facteur * m[1], "boss": m[3], "elite": m[4]}
		if m[2] != "":
			e["nom"] = m[2]
		equipe.append(e)
	return equipe


static func _tirer(rng: RandomNumberGenerator, liste: Array) -> String:
	return liste[rng.randi_range(0, liste.size() - 1)]


static func _ordre_place(id: String) -> int:
	var role: String = UnitesData.get_unite(id)["role"]
	return {"tank": 0, "guerrier": 1, "assassin": 2, "tireur": 3, "mage": 4, "soutien": 5}.get(role, 3)


## Puissance totale de l'équipe de référence du joueur à ce chapitre.
static func puissance_reference(acte: int, chapitre: int) -> float:
	var niveau := niveau_attendu(acte, chapitre)
	var total := 0.0
	for r in EQUIPE_REFERENCE[acte]:
		total += _puissance_moyenne(r, niveau)
	return total


static func _puissance_moyenne(rarete: String, niveau: int) -> float:
	var cle := "%s-%d" % [rarete, niveau]
	if _cache_puissance.has(cle):
		return _cache_puissance[cle]
	var total := 0.0
	var n := 0
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if not u["invocable"]:
			continue
		var ok: bool = u.get("legende", false) if rarete == "LEG" else (u["rarete"] == rarete and not u.get("legende", false))
		if ok:
			total += UnitesData.puissance(id, niveau)
			n += 1
	var moy := total / maxf(1.0, n)
	_cache_puissance[cle] = moy
	return moy
