class_name Donjons
extends RefCounted
## DONJONS : 6 donjons (un par élément + le Puits de Sang, neutre), 10 niveaux chacun.
##
## Une expédition = 4 combats d'affilée, SANS soin entre deux (les PV sont conservés,
## une unité K.O. le reste jusqu'à la fin) :
##   1) une vague de 5 monstres   2) le MINI-BOSS et ses 2 gardes
##   3) une vague de 5 monstres   4) le BOSS du donjon
## La stamina est payée une seule fois, au départ. Le butin est donné à la victoire finale.
##
## Chaque donjon donne la ressource de son élément (Gouttes, puis Larmes, puis Cœurs quand
## le niveau monte) ; le Puits de Sang donne le Sang, demandé par TOUTES les évolutions.
## Le niveau n+1 s'ouvre quand le niveau n a été terminé une fois.

const SCENE := "res://scenes/donjon.tscn"
const NIVEAUX := 10

const ORDRE := ["feu", "nature", "eau", "tenebres", "sacre", "neutre"]
const DONJONS := {
	"feu": {"nom": "Le Brasier Éternel", "sous_titre": "Une forge oubliée où la lave ne refroidit jamais",
		"couleur": "ff6a2a", "mini_boss": "gardien_brasier", "boss": "ignaar",
		"monstres": ["sanglier_sauvage", "hyene_des_sables", "pillard_incendiaire", "diablotin_soufre", "orc_guerrier",
			"loup_garou", "cyclope", "minotaure_jeune", "centaure_guerrier", "mercenaire_balafre", "molosse_enfers",
			"cyclope_furieux", "demon_flamme", "bourreau_cornu", "forgeron_abime", "demon_mineur", "vouivre_ecarlate"]},
	"nature": {"nom": "La Sylve Putride", "sous_titre": "Une forêt malade où chaque racine a faim",
		"couleur": "6ad04a", "mini_boss": "chasseuse_sylve", "boss": "mere_racine",
		"monstres": ["rat_geant", "gobelin", "loup_gris", "bandit", "araignee_venin", "brigand", "vautour_charognard",
			"gobelin_maraudeur", "loup_affame", "patrouilleur_vautour", "pestifere_errant", "harpie", "sorciere_bois",
			"brigand_cagoule", "araignee_geante", "receleur_ombre", "golem_fissure", "liane_venimeuse", "chimere",
			"wyverne", "reine_araignee"]},
	"eau": {"nom": "Les Fosses Englouties", "sous_titre": "Une cité noyée au fond de l'océan noir",
		"couleur": "4aa8ff", "mini_boss": "sentinelle_corail", "boss": "kraken_fosses",
		"monstres": ["limace_acide", "slime", "serpent_crache", "spectre_glacial", "troll_marais", "gargouille", "banshee",
			"souvenir_spectral", "passeur_styx", "nuee_vivante", "troll_cavernes", "aberration_cristal",
			"bete_tourbieres", "sangsue_abyssale", "hydre_jeune", "hydre_bicephale"]},
	"tenebres": {"nom": "La Crypte sans Lune", "sous_titre": "Des catacombes où aucune lumière n'est jamais entrée",
		"couleur": "a06ae0", "mini_boss": "geolier_crypte", "boss": "morvena",
		"monstres": ["squelette", "zombie", "chauve_souris_vampire", "corbeau_maudit", "moine_dechu", "esprit_frappeur",
			"rat_corrompu", "profanateur_tombes", "ame_damnee", "chevalier_rouille", "assassin_ombre", "porteur_lanterne",
			"arbaletrier_noir", "garde_os", "zombie_enrage", "ombre_rampante", "spectre_vengeur", "harpie_sanglante",
			"pretre_autel", "pilleur_royal", "golem_obsidienne", "liche_mineure"]},
	"sacre": {"nom": "Le Sanctuaire Profané", "sous_titre": "Un temple céleste souillé par un culte oublié",
		"couleur": "ffe070", "mini_boss": "templier_profane", "boss": "oracle_profane",
		"monstres": ["cherubin", "faucon_celeste", "golem_pierre", "gardien_albatre", "fanatique_zelote", "archer_cieux",
			"pretresse_aube", "mirage_vaincu", "statue_hurlante", "clerc", "gargouille_jade", "champion_dechu",
			"valkyrie_celeste", "trone_vivant"]},
	"neutre": {"nom": "Le Puits de Sang", "sous_titre": "Un gouffre sans fond où tout le sang du monde finit par couler",
		"couleur": "d02a2a", "mini_boss": "boucher_puits", "boss": "hemoragos",
		"monstres": ["rat_geant", "zombie", "slime", "sanglier_sauvage", "cherubin", "orc_guerrier", "harpie",
			"chevalier_rouille", "troll_marais", "golem_pierre", "zombie_enrage", "cyclope_furieux", "troll_cavernes",
			"statue_hurlante", "chimere", "golem_obsidienne", "hydre_bicephale", "demon_mineur", "gargouille_jade"]},
}

## Les 4 combats d'une expédition, dans l'ordre.
const VAGUES := ["vague", "mini_boss", "vague", "boss"]
const NOMS_VAGUE := {"vague": "Vague de monstres", "mini_boss": "Mini-boss", "boss": "BOSS"}

## Stamina payée au départ de l'expédition, selon le niveau (1 à 10).
const COUT_STAMINA := [4, 4, 4, 6, 6, 6, 8, 8, 10, 10]
## Niveau du donjon -> point équivalent de l'Aventure (0 = Acte I ch.1, 71 = Acte XII ch.6).
const EQUIVALENT := [12, 20, 28, 36, 44, 52, 60, 66, 71, 71]
## Au-delà de l'Acte XII (niveaux 9 et 10) : ennemis encore plus forts.
const SURPLUS := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.12, 1.3]
## Rareté maximale des monstres des vagues selon le niveau (0 = N ... 4 = UR).
const RARETE_MAX := [1, 1, 2, 2, 2, 3, 3, 3, 4, 4]

## DIFFICULTÉ : force de chaque combat par rapport à l'équipe de référence (réglé par simulation).
const DIFFICULTE := 1.0
const RATIOS := {"vague": 0.8, "mini_boss": 0.55, "boss": 0.26}
const POIDS_MINI_BOSS := 1.8
const POIDS_BOSS := 2.6
## Réglage fin par niveau (index 0 = niveau 1) et par combat (vague, mini-boss, vague, boss),
## réglé par simulation. Réussite visée d'une expédition complète avec l'équipe de référence
## (sans Échos) : ~70 % aux niveaux 1 à 8, ~55 % au niveau 9, ~40 % au niveau 10.
const CALIBRAGE := [
	[1.38, 0.67, 0.54, 0.74],	# niveau 1
	[1.26, 0.94, 0.54, 0.74],	# niveau 2
	[1.02, 0.84, 0.54, 0.92],	# niveau 3
	[1.01, 0.77, 0.51, 0.92],	# niveau 4
	[1.17, 1.14, 0.6, 0.81],	# niveau 5
	[0.92, 1.0, 0.53, 1.04],	# niveau 6
	[1.02, 1.15, 0.5, 1.14],	# niveau 7
	[0.99, 1.02, 0.57, 1.18],	# niveau 8
	[0.7, 1.03, 0.47, 1.28],	# niveau 9
	[0.63, 0.88, 0.54, 1.27],	# niveau 10
]
static var calibrage_test := {}

const RARETES_IDX := {"N": 0, "R": 1, "SR": 2, "SSR": 3, "UR": 4}

## Expédition en cours : {"donjon", "niveau", "vague", "equipe": [uid...], "pv": [ratio...]}
static var expedition: Dictionary = {}


# ---------------------------------------------------------------------
# Progression
# ---------------------------------------------------------------------

static func _etat(donjon: String) -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("donjons"):
		Sauvegarde.donnees["donjons"] = {}
	var d: Dictionary = Sauvegarde.donnees["donjons"]
	if not d.has(donjon):
		d[donjon] = {"niveau_max": 0, "victoires": 0}
	return d[donjon]


## Plus haut niveau terminé (0 = aucun).
static func niveau_termine(donjon: String) -> int:
	return int(_etat(donjon)["niveau_max"])


static func est_ouvert(donjon: String, niveau: int) -> bool:
	return niveau <= niveau_termine(donjon) + 1 or Sauvegarde.admin("tout_debloque")


# ---------------------------------------------------------------------
# Ennemis
# ---------------------------------------------------------------------

static func point(niveau: int) -> Vector2i:
	var p: int = EQUIVALENT[clampi(niveau, 1, NIVEAUX) - 1]
	return Vector2i(int(p / 6.0) + 1, p % 6 + 1)


static func niveau_ennemis(niveau: int, type: String) -> int:
	var eq := point(niveau)
	var bonus: int = {"vague": 0, "mini_boss": 1, "boss": 2}[type]
	return clampi(Rencontres.niveau_attendu(eq.x, eq.y) + bonus + (1 if niveau >= 9 else 0), 1, UnitesData.NIVEAU_MAX)


static func _pool(donjon: String, niveau: int) -> Array:
	var tous: Array = DONJONS[donjon]["monstres"]
	var max_r: int = RARETE_MAX[niveau - 1]
	var min_r := maxi(0, max_r - 2)
	var l := tous.filter(func(id): return RARETES_IDX[UnitesData.get_unite(id)["rarete"]] <= max_r \
		and RARETES_IDX[UnitesData.get_unite(id)["rarete"]] >= min_r)
	return l if l.size() >= 3 else tous


## Ennemis d'un combat de l'expédition (index 0 à 3). Mêmes ennemis toute la journée.
static func generer(donjon: String, niveau: int, index_vague: int) -> Array:
	var d: Dictionary = DONJONS[donjon]
	var type: String = VAGUES[index_vague]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("BoL-donjon-%s-%d-%d-%d" % [donjon, niveau, index_vague, Calendrier.jour_absolu()])
	var pool := _pool(donjon, niveau)
	var niv := niveau_ennemis(niveau, type)
	var membres: Array = []      # [id, poids, nom, boss, elite]
	match type:
		"vague":
			for i in 5:
				membres.append([pool[rng.randi_range(0, pool.size() - 1)], 1.0, "", false, false])
		"mini_boss":
			membres.append([d["mini_boss"], POIDS_MINI_BOSS, "", false, true])
			for i in 2:
				var g: String = pool[rng.randi_range(0, pool.size() - 1)]
				membres.append([g, 1.0, "Garde : " + UnitesData.get_unite(g)["nom"], false, false])
		"boss":
			membres.append([d["boss"], POIDS_BOSS, "", true, false])
	var eq := point(niveau)
	var calib: float = calibrage_test.get("%d-%d" % [niveau, index_vague], CALIBRAGE[niveau - 1][index_vague])
	var cible: float = Rencontres.puissance_reference(eq.x, eq.y) * RATIOS[type] * DIFFICULTE * calib \
		* Rencontres.pente(eq.x, eq.y) * Rencontres.ECHOS_ATTENDUS[eq.x - 1] * SURPLUS[niveau - 1]
	var brut := 0.0
	for m in membres:
		brut += UnitesData.puissance(m[0], niv) * m[1]
	var facteur: float = cible / maxf(1.0, brut)
	membres.sort_custom(func(a, b): return Rencontres._ordre_place(a[0]) < Rencontres._ordre_place(b[0]))
	var equipe: Array = []
	for m in membres:
		var e := {"id": m[0], "niveau": niv, "mult": facteur * m[1], "boss": m[3], "elite": m[4]}
		if m[2] != "":
			e["nom"] = m[2]
		equipe.append(e)
	return equipe


## Puissance d'équipe conseillée : celle de l'équipe de référence (réussite ~70 %).
static func puissance_conseillee(niveau: int) -> float:
	var eq := point(niveau)
	return Rencontres.puissance_reference(eq.x, eq.y) * Rencontres.ECHOS_ATTENDUS[eq.x - 1] * SURPLUS[niveau - 1]


# ---------------------------------------------------------------------
# Butin (donné à la victoire contre le boss)
# ---------------------------------------------------------------------

## [goutte, larme, cœur] gagnés par niveau (1 à 10).
const BUTIN := [
	[6, 0, 0], [8, 0, 0], [10, 0, 0],
	[10, 2, 0], [10, 3, 0], [8, 4, 0], [6, 6, 0],
	[0, 6, 1], [0, 6, 2], [0, 5, 3],
]
## Chance d'une ressource bonus de la plus grosse taille du niveau.
const CHANCE_BONUS := 0.3


static func or_victoire(niveau: int) -> int:
	return 300 + 150 * niveau


## Butin garanti d'une victoire : {id_ressource: quantité}.
static func butin(donjon: String, niveau: int) -> Dictionary:
	var b := {}
	var q: Array = BUTIN[niveau - 1]
	for i in 3:
		if int(q[i]) > 0:
			b[Evolution.ressource(donjon, Evolution.TAILLES[i])] = int(q[i])
	return b


## Plus grosse ressource que ce niveau peut donner.
static func ressource_principale(donjon: String, niveau: int) -> String:
	var q: Array = BUTIN[niveau - 1]
	for i in [2, 1, 0]:
		if int(q[i]) > 0:
			return Evolution.ressource(donjon, Evolution.TAILLES[i])
	return ""


## Enregistre la victoire finale. Renvoie les lignes de récompense.
static func valider_victoire(donjon: String, niveau: int) -> Array:
	var lignes: Array = []
	var e := _etat(donjon)
	var b := butin(donjon, niveau)
	if randf() < CHANCE_BONUS:
		var r := ressource_principale(donjon, niveau)
		b[r] = int(b.get(r, 0)) + 1
	b["or"] = or_victoire(niveau)
	lignes.append_array(Reliquaire.donner(b))
	e["victoires"] = int(e["victoires"]) + 1
	if niveau > int(e["niveau_max"]):
		e["niveau_max"] = niveau
		if niveau < NIVEAUX:
			lignes.append(UiCommun.t("Niveau %d du donjon débloqué !") % (niveau + 1))
	Sauvegarde.ajouter_stat("donjons_termines")
	Sauvegarde.sauvegarder()
	return lignes


## XP gagnée par un héros à la fin d'une expédition réussie.
static func xp(niveau: int, niveau_heros: int) -> int:
	var eq := point(niveau)
	return Rencontres.xp_victoire("boss_chapitre", niveau_heros, eq.x, eq.y) * 2


# ---------------------------------------------------------------------
# Expédition (enchaînement des 4 combats)
# ---------------------------------------------------------------------

## Démarre une expédition avec l'équipe actuelle. Renvoie "" si c'est bon, sinon la raison.
static func demarrer(donjon: String, niveau: int) -> String:
	var equipe := Sauvegarde.get_equipe()
	if equipe.is_empty():
		return "Ton équipe est vide : ajoute des héros dans le Deck."
	if not est_ouvert(donjon, niveau):
		return UiCommun.t("Termine d'abord le niveau %d.") % (niveau - 1)
	var cout: int = COUT_STAMINA[niveau - 1]
	if not Sauvegarde.depenser_stamina(cout):
		return UiCommun.t("Pas assez de stamina (%d requis, tu en as %d).\nProchain point dans %s.\nTu peux utiliser un Élixir au Reliquaire.") % [
			cout, Sauvegarde.get_stamina(), Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())]
	var pv: Array = []
	for uid in equipe:
		pv.append(1.0)
	expedition = {"donjon": donjon, "niveau": niveau, "vague": 0, "equipe": equipe, "pv": pv}
	return ""


## Demande de combat (pour EcranCombat) du combat en cours de l'expédition.
static func demande_combat() -> Dictionary:
	var equipe: Array = []
	var uids: Array = expedition["equipe"]
	for i in uids.size():
		var uid := int(uids[i])
		var h := Sauvegarde.get_heros(uid)
		if h.is_empty():
			continue
		equipe.append({"id": h["id"], "niveau": int(h["niveau"]), "uid": uid, "place": Sauvegarde.place_de(uid),
			"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid), "pv_ratio": float(expedition["pv"][i])})
	var v := int(expedition["vague"])
	return {"mode": "donjon", "donjon": expedition["donjon"], "niveau": expedition["niveau"], "vague": v,
		"type": VAGUES[v], "equipe": equipe, "ennemis": generer(expedition["donjon"], int(expedition["niveau"]), v),
		"retour": SCENE}


## Après une victoire (pas la dernière) : on garde les PV restants et on passe au combat suivant.
static func vague_suivante(pv_final: Array) -> void:
	expedition["pv"] = pv_final.duplicate()
	expedition["vague"] = int(expedition["vague"]) + 1


static func derniere_vague() -> bool:
	return int(expedition.get("vague", 0)) >= VAGUES.size() - 1


static func terminer() -> void:
	expedition = {}
