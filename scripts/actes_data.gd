class_name ActesData
extends RefCounted
## Données de l'Histoire principale : 12 Actes de 6 chapitres.
##
## POUR CHANGER L'IMAGE D'UN ACTE :
##   - Le plus simple : remplace le fichier dans res://assets/actes/
##     en gardant EXACTEMENT le même nom (ex : acte_05.png).
##     Godot le réimporte tout seul, rien d'autre à modifier.
##   - Ou : mets ta nouvelle image où tu veux et change le chemin
##     "image" de l'Acte ci-dessous.
##
## UTILISATION DANS UNE SCÈNE :
##   $TextureRect.texture = ActesData.get_image(3)        # image de l'Acte III
##   $Label.text = ActesData.get_acte(3)["titre"]          # "Sous les Drapeaux Noirs"
##   var chap = ActesData.get_chapitre(3, 2)               # Acte III, chapitre 2
##   $LabelChap.text = chap["titre"]

## Acte à afficher dans l'écran de sélection (voir ecran_acte.gd).
static var acte_courant: int = 1
## Scène à rouvrir quand on quitte l'écran d'un Acte (remplie automatiquement).
static var scene_precedente: String = ""
## Menu principal (mémorisé quand on ouvre l'Aventure) : le retour de l'Aventure y ramène.
static var scene_menu: String = ""
## Chapitre en cours (1 à 6), rempli par l'écran d'Acte avant d'ouvrir le plateau.
static var chapitre_courant: int = 1
## Pour tester : true = tous les Actes et chapitres sont ouverts.
const TOUT_DEBLOQUER := false

# La progression est enregistrée dans la sauvegarde (voir sauvegarde.gd).
static func charger() -> void:
	Sauvegarde.charger()

static func marquer_termine(acte: int, chapitre: int) -> void:
	Sauvegarde.marquer_termine(acte, chapitre)

static func est_termine(acte: int, chapitre: int) -> bool:
	return Sauvegarde.est_termine(acte, chapitre)

## Un chapitre s'ouvre quand le précédent est terminé (en partant de l'Acte I, chapitre 1).
## Le chapitre 1 d'un Acte s'ouvre quand le chapitre 6 de l'Acte précédent est terminé.
static func chapitre_debloque(acte: int, chapitre: int) -> bool:
	if TOUT_DEBLOQUER or (acte == 1 and chapitre == 1):
		return true
	if chapitre > 1:
		return est_termine(acte, chapitre - 1)
	return est_termine(acte - 1, 6)

static func acte_debloque(acte: int) -> bool:
	return chapitre_debloque(acte, 1)

const ACTES: Array = [
	{
		"numero": 1,
		"romain": "I",
		"titre": "Les Cendres du Serment",
		"partie": "L'Aube et les Cendres",
		"image": "res://assets/actes/acte_01.png",
		"chapitres": [
			{ "titre": "Le Dernier Feu du Foyer", "description": "L'introduction de l'univers, la paix fragile qui vole en éclats et la destruction du domaine familial." },
			{ "titre": "La Tombe des Ancêtres", "description": "La fuite à travers le sanctuaire ancestral profané et la découverte du premier artefact brisé." },
			{ "titre": "Sur les Chemins de l'Exil", "description": "Les premiers pas hors des frontières connues, confrontés à la misère et aux réfugiés." },
			{ "titre": "Le Serment Sanglant", "description": "Le choix des premiers compagnons et la formulation du vœu de vengeance ou de rédemption." },
			{ "titre": "La Patrouille des Vautours", "description": "Une embuscade tendue par les forces ennemies qui contrôlent désormais les routes." },
			{ "titre": "L'Aube des Damnés", "description": "L'arrivée dans une première grande ville fortifiée, rongée par la corruption et la peur." },
		],
	},
	{
		"numero": 2,
		"romain": "II",
		"titre": "L'Étreinte du Deuil",
		"partie": "L'Aube et les Cendres",
		"image": "res://assets/actes/acte_02.png",
		"chapitres": [
			{ "titre": "Les Salles Silencieuses", "description": "L'enquête au cœur d'une cité endeuillée pour comprendre l'ampleur de la tragédie." },
			{ "titre": "Le Poids du Souvenir", "description": "Confrontation avec des fantômes du passé et des souvenirs douloureux matérialisés." },
			{ "titre": "L'Hôpital des Oubliés", "description": "La découverte d'un refuge de pestiférés et de blessés de guerre abandonnés de tous." },
			{ "titre": "Les Larmes de la Veuve", "description": "Une quête secondaire poignante auprès de civils brisés par le conflit." },
			{ "titre": "La Nuit des Lanternes Noires", "description": "Un rituel funéraire clandestin perturbé par des créatures de l'ombre." },
			{ "titre": "Le Visage du Désespoir", "description": "La prise de conscience que le deuil ne fait que commencer et qu'il faut quitter les zones habitées." },
		],
	},
	{
		"numero": 3,
		"romain": "III",
		"titre": "Sous les Drapeaux Noirs",
		"partie": "L'Aube et les Cendres",
		"image": "res://assets/actes/acte_03.png",
		"chapitres": [
			{ "titre": "Le Nid des Mercenaires", "description": "L'infiltration d'un campement de soudards sans foi ni loi qui terrorisent la région." },
			{ "titre": "La Loi du Plus Fort", "description": "Affrontement contre un capitaine de guerre corrompu et ses lieutenants brutaux." },
			{ "titre": "Marchés d'Ombre et de Fer", "description": "La traversée d'un marché noir contrôlé par les pires éléments de la pègre." },
			{ "titre": "La Bannière Souillée", "description": "La récupération d'étendards volés ou l'exposition de la corruption au grand jour." },
			{ "titre": "Le Siège du Fortin", "description": "Une bataille tactique pour libérer un poste frontalier stratégique." },
			{ "titre": "Le Prix du Sang Versé", "description": "Le bilan des alliances de circonstance et la trahison d'un mercenaire en qui les héros avaient confiance." },
		],
	},
	{
		"numero": 4,
		"romain": "IV",
		"titre": "Le Sépulcre des Oubliés",
		"partie": "L'Aube et les Cendres",
		"image": "res://assets/actes/acte_04.png",
		"chapitres": [
			{ "titre": "La Descente aux Abysses", "description": "L'entrée dans un réseau de catacombes ou de ruines ensevelies depuis des siècles." },
			{ "titre": "Les Échos du Labyrinthe", "description": "Résolution d'énigmes mortelles et survie face à des pièges ancestraux." },
			{ "titre": "La Garde d'Os", "description": "Affrontement contre les premiers gardiens squelettiques et spectres liés au lieu." },
			{ "titre": "Le Secret des Premiers Rois", "description": "La découverte d'inscriptions révélant la véritable origine de la malédiction." },
			{ "titre": "L'Autel des Sacrifices", "description": "Un lieu de culte interdit où des forces obscures pratiquent de sombres rituels." },
			{ "titre": "Le Réveil du Gardien", "description": "Un combat de boss mémorable contre une entité millénaire protégeant le cœur du sépulcre." },
		],
	},
	{
		"numero": 5,
		"romain": "V",
		"titre": "L'Aiguillon de la Souffrance",
		"partie": "La Descente et le Sang",
		"image": "res://assets/actes/acte_05.png",
		"chapitres": [
			{ "titre": "La Terre Brûlée", "description": "Une traversée exténuante à travers des paysages totalement dévastés par la guerre totale." },
			{ "titre": "La Fièvre et la Boue", "description": "La gestion de l'épuisement physique, des blessures et des doutes au sein du groupe." },
			{ "titre": "Le Mirage des Vaincus", "description": "Des visions et des hallucinations provoquées par la fatigue et la magie noire ambiante." },
			{ "titre": "L'Inquisiteur Implacable", "description": "La confrontation avec un zélote fanatique qui voit les héros comme des hérétiques." },
			{ "titre": "Le Point de Rupture", "description": "Une dispute interne critique ou un choix difficile menaçant de séparer les compagnons." },
			{ "titre": "La Cicatrice et la Lame", "description": "Le sursaut d'orgueil du groupe qui transforme sa souffrance en une volonté de fer." },
		],
	},
	{
		"numero": 6,
		"romain": "VI",
		"titre": "Les Larmes de Pierre",
		"partie": "La Descente et le Sang",
		"image": "res://assets/actes/acte_06.png",
		"chapitres": [
			{ "titre": "La Forêt Pétrifiée", "description": "L'entrée dans un bois maudit où la vie végétale elle-même s'est transformée en roc." },
			{ "titre": "Les Statues Hurlantes", "description": "La découverte de voyageurs et de créatures figés dans la terreur par une ancienne malédiction." },
			{ "titre": "Le Cœur de Minéral", "description": "La rencontre avec un ermite ou une créature de pierre détentrice d'un savoir unique." },
			{ "titre": "L'Épreuve du Poids", "description": "Des affrontements où l'environnement pèse lourdement sur les mouvements et la stratégie." },
			{ "titre": "La Faille de Cristal", "description": "Une crevasse souterraine scintillante mais mortelle, gardée par des aberrations cristallines." },
			{ "titre": "Le Reflet de l'Âme", "description": "La traversée d'un lac de verre noir où les héros doivent affronter une part d'eux-mêmes." },
		],
	},
	{
		"numero": 7,
		"romain": "VII",
		"titre": "Le Pacte des Ronces",
		"partie": "La Descente et le Sang",
		"image": "res://assets/actes/acte_07.png",
		"chapitres": [
			{ "titre": "Les Marais aux Murmures", "description": "L'exploration d'une zone marécageuse brumeuse où rôdent des créatures des tourbières." },
			{ "titre": "La Dame des Ronciers", "description": "La négociation délicate avec une sorcière ou une reine des fées corrompue par les ténèbres." },
			{ "titre": "Le Prix du Sureau", "description": "L'accomplissement d'une tâche sombre ou immorale pour obtenir un passage ou une information." },
			{ "titre": "Le Piège des Épines", "description": "Une embuscade tendue par des bêtes sauvages et des invocations végétales vénéneuses." },
			{ "titre": "L'Alliance Contre-Nature", "description": "La formalisation du pacte, scellant des liens avec des forces que les héros répugnent à côtoyer." },
			{ "titre": "La Sève et le Poison", "description": "Les conséquences immédiates du pacte sur la moralité et la santé des personnages." },
		],
	},
	{
		"numero": 8,
		"romain": "VIII",
		"titre": "L'Éclipse du Sang",
		"partie": "La Descente et le Sang",
		"image": "res://assets/actes/acte_08.png",
		"chapitres": [
			{ "titre": "Les Cieux de Sang", "description": "Le début d'un phénomène céleste obscurcissant le soleil et amplifiant les énergies ténébreuses." },
			{ "titre": "La Ruée des Monstres", "description": "Une invasion massive de créatures profitant de l'éclipse pour attaquer les colonies humaines." },
			{ "titre": "La Chute de la Garnison", "description": "La tentative désespérée de défendre un bastion stratégique face à un siège écrasant." },
			{ "titre": "Le Sacrifice du Commandant", "description": "La mort tragique ou le sacrifice héroïque d'un allié important au combat." },
			{ "titre": "L'Artéfact Stellaire", "description": "La découverte d'une source de pouvoir liée à l'éclipse qu'il faut s'approprier ou détruire." },
			{ "titre": "La Victoire en Deuil", "description": "La fin de l'éclipse sur un champ de bataille jonché de corps, marquant une trêve amère." },
		],
	},
	{
		"numero": 9,
		"romain": "IX",
		"titre": "Là où Meurent les Légendes",
		"partie": "Le Crépuscule et l'Héritage",
		"image": "res://assets/actes/acte_09.png",
		"chapitres": [
			{ "titre": "Le Val des Héros Déchus", "description": "Le pèlerinage dans un cimetière légendaire où reposent les plus grands champions du passé." },
			{ "titre": "L'Écho des Hauteurs", "description": "La confrontation avec l'esprit ou l'ombre d'une figure historique corrompue par le mal." },
			{ "titre": "Les Armes Oubliées", "description": "La quête pour récupérer des reliques légendaires dispersées dans les tombes." },
			{ "titre": "Le Jugement des Ancêtres", "description": "Une épreuve spirituelle où les héros doivent prouver qu'ils sont dignes de leur héritage." },
			{ "titre": "La Profanation Suprême", "description": "La découverte que l'ennemi principal pille les tombes pour alimenter sa propre armée." },
			{ "titre": "Le Crépuscule des Mythes", "description": "Le choix de laisser le passé derrière soi pour écrire une nouvelle ère de sang." },
		],
	},
	{
		"numero": 10,
		"romain": "X",
		"titre": "Les Chemins de la Désolation",
		"partie": "Le Crépuscule et l'Héritage",
		"image": "res://assets/actes/acte_10.png",
		"chapitres": [
			{ "titre": "La Marche dans les Cendres", "description": "La traversée des terres frontalières du domaine final, totalement ravagées par la guerre." },
			{ "titre": "Les Derniers Survivants", "description": "La rencontre poignante avec des poches de résistance civile sur le point de succomber." },
			{ "titre": "La Citadelle des Supplices", "description": "L'approche des lignes ennemies fortifiées, hérissées de piques et de machines de siège." },
			{ "titre": "La Brèche dans le Mur", "description": "L'infiltration audacieuse ou l'assaut frontal pour pénétrer dans le bastion adverse." },
			{ "titre": "Les Salles de Tourment", "description": "La progression à travers les cachots et les laboratoires où le mal orchestre ses expériences." },
			{ "titre": "Au Seuil du Sanctum", "description": "La préparation finale avant d'affronter le maître des lieux, le cœur lourd de tout ce qui a été sacrifié." },
		],
	},
	{
		"numero": 11,
		"romain": "XI",
		"titre": "Le Jugement des Frères",
		"partie": "Le Crépuscule et l'Héritage",
		"image": "res://assets/actes/acte_11.png",
		"chapitres": [
			{ "titre": "Le Masque Tombé", "description": "La révélation de l'identité du véritable instigateur de la tragédie (un ancien allié, un frère d'armes ou un membre de la lignée)." },
			{ "titre": "Les Arguments du Sang", "description": "Un débat déchirant ou une confrontation verbale remettant en cause les motivations des héros." },
			{ "titre": "La Trahison Interne", "description": "Un retournement de situation critique où un membre du groupe ou un proche choisit son camp." },
			{ "titre": "Les Frères Ennemis", "description": "Le début du duel tragique entre les forces opposées de la même lignée." },
			{ "titre": "Le Poids du Trône", "description": "La destruction des illusions de pouvoir et de gloire au profit de la survie pure." },
			{ "titre": "Le Dernier Regard", "description": "Le point de non-retour où le destin des frères se scelle définitivement dans le sang." },
		],
	},
	{
		"numero": 12,
		"romain": "XII",
		"titre": "L'Éternité en Héritage",
		"partie": "Le Crépuscule et l'Héritage",
		"image": "res://assets/actes/acte_12.png",
		"chapitres": [
			{ "titre": "Le Trône de Cendres et de Larmes", "description": "L'ascension vers la salle du trône finale, baignée d'une lueur apocalyptique." },
			{ "titre": "L'Ultime Rempart", "description": "Le combat contre la garde rapprochée du grand antagoniste." },
			{ "titre": "La Métamorphose du Mal", "description": "La transformation de l'ennemi juré en une monstruosité cauchemardesque alimentée par l'héritage maudit." },
			{ "titre": "Le Crépuscule des Frères", "description": "L'affrontement final en plusieurs phases, combinant stratégie tactique et intensité dramatique." },
			{ "titre": "Le Sacrifice Final", "description": "Le choix ultime du joueur : qui survit, qui se sacrifie, et comment le pouvoir est scellé ou détruit." },
			{ "titre": "Les Larmes et le Nouveau Monde", "description": "L'épilogue montrant les conséquences de la victoire, le nouveau visage des terres et le legs laissé aux générations futures." },
		],
	},
]

## Renvoie le dictionnaire d'un Acte (numéro de 1 à 12).
static func get_acte(numero: int) -> Dictionary:
	if numero < 1 or numero > ACTES.size():
		push_warning("Acte inexistant : %d" % numero)
		return {}
	return ACTES[numero - 1]

## Renvoie le chapitre (1 à 6) d'un Acte (1 à 12).
static func get_chapitre(acte: int, chapitre: int) -> Dictionary:
	var a := get_acte(acte)
	if a.is_empty() or chapitre < 1 or chapitre > a["chapitres"].size():
		return {}
	return a["chapitres"][chapitre - 1]

## Charge l'image d'un Acte. Renvoie null si le fichier est absent
## (le jeu ne plante pas : il n'y aura juste pas d'image).
static func get_image(numero: int) -> Texture2D:
	var a := get_acte(numero)
	if a.is_empty():
		return null
	var chemin: String = a["image"]
	if not ResourceLoader.exists(chemin):
		push_warning("Image introuvable pour l'Acte %d : %s" % [numero, chemin])
		return null
	return load(chemin)
