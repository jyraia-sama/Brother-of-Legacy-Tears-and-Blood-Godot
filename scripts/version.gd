class_name Version
extends RefCounted
## VERSION DU JEU ET JOURNAL DES MISES À JOUR (changelog).
##
## À CHAQUE NOUVELLE VERSION :
##   1. change NUMERO et DATE ci-dessous ;
##   2. ajoute une entrée EN HAUT de HISTORIQUE (même numéro) ;
##   3. recopie-la dans CHANGELOG.md (à la racine du projet) ;
##   4. dans GitHub Desktop : Commit « vX.Y.Z — titre », puis crée l'étiquette (tag) vX.Y.Z ;
##   5. dans Godot : onglet « Versions » -> « Sauvegarder cette version ».
##
## Numérotation  MAJEUR.MINEUR.CORRECTIF :
##   0.x.y  = jeu en développement (1.0.0 = première version complète)
##   MINEUR    +1 : nouvelle fonctionnalité (nouveau mode, nouvel écran...)
##   CORRECTIF +1 : corrections de bugs / équilibrage, sans nouveauté

const NUMERO := "0.22.0"
const DATE := "2026-09-29"
const NOM_JEU := "Brothers of Legacy : Tears and Blood"

const HISTORIQUE := [
	{"version": "0.22.0", "date": "2026-09-29", "titre": "Quêtes, Succès, Boutique, Mon héros et Aide",
	"changements": [
		"QUÊTES (icône en bas du menu) : récompense de connexion quotidienne (cycle de 7 jours, jusqu'à 100 gemmes et un Éclat), 5 quêtes du jour et 5 quêtes de la semaine (les mêmes pour tous) avec or, gemmes et objets, et un coffre bonus quand toutes sont terminées. La progression se note toute seule en jouant.",
		"SUCCÈS : 15 objectifs à long terme à 4 paliers (combats, chapitres, Bestiaire, invocations, Tours, Donjons, Boss de Monde, Marche, Échos +15…). Chaque palier donne des gemmes ; le dernier débloque un titre.",
		"BOUTIQUE : Marché du jour (6 offres en or qui changent chaque jour), Comptoir des gemmes (recharge de stamina, élixirs, Éclats, coffres, tomes, Cœurs de Sang, Pierre d'Éveil, avec limites par jour ou par semaine) et onglet des packs de gemmes (argent réel : bientôt).",
		"MON HÉROS (portrait du menu) : fiche complète du héros de départ, profil (niveau de compte, titre à afficher), statistiques de la partie et résumé de la collection.",
		"AIDE (bouton « ? ») : guide du jeu en 8 sections (premiers pas, ressources, combat, unités, Échos, modes, en ligne, téléphone).",
		"Pastilles sur les icônes Quêtes et Succès quand une récompense attend.",
	]},
	{"version": "0.21.2", "date": "2026-09-29", "titre": "Vitesse de combat, e-mail mémorisé, Arène",
	"changements": [
		"Combat : la vitesse choisie (x1, x2, x4) est gardée pour les combats suivants (le Boss de Monde garde la sienne).",
		"Compte : l'adresse e-mail de la dernière connexion reste remplie après une déconnexion ; il ne reste que le mot de passe à taper.",
		"Arène : un joueur sans équipe de défense n'apparaissait jamais comme adversaire. En ouvrant l'Arène, la défense est maintenant enregistrée automatiquement (défense préparée, sinon l'équipe du Deck).",
		"Arène : les unités évoluées (niveau jusqu'à 40) sont acceptées dans la défense (relancer supabase/02_arene.sql dans Supabase).",
	]},
	{"version": "0.21.1", "date": "2026-09-29", "titre": "Portraits évolués : planche 22",
	"changements": [
		"9 premiers portraits des unités évoluées : La Brute Primordiale, Barbe-Abysse, La Lance Solaire, La Dryade Éternelle, L'Archimage Cendré, La Dague Crépusculaire, Le Shogun Écarlate, Le Paladin Immaculé, Le Chevalier du Néant.",
	]},
	{"version": "0.21.0", "date": "2026-09-28", "titre": "Version mobile",
	"changements": [
		"Jeu jouable sur téléphone et tablette : l'interface est agrandie automatiquement sur mobile (+50 %). Nouveau réglage « Taille de l'interface » dans les Paramètres (Automatique, Normale, Grande, Très grande).",
		"Défilement au doigt dans toutes les listes (Deck, Bestiaire, Échos, Reliquaire…), avec de l'élan. Un glissement n'appuie plus sur la carte ou le bouton de départ.",
		"Les écrans trop larges pour la taille choisie se réduisent juste assez pour tenir entièrement (rien n'est coupé sur les bords).",
		"Le jeu s'installe comme une appli (Android et iPhone, écran d'accueil) : icône, plein écran et paysage. Sur navigateur mobile, plein écran automatique au premier appui (désactivable).",
		"En portrait, un message demande de tourner le téléphone. Clavier virtuel activé pour les champs de texte (compte, sauvegarde).",
		"Guide : MOBILE.md.",
	]},
	{"version": "0.20.4", "date": "2026-09-28", "titre": "Jeu en ligne réparé sur la version web",
	"changements": [
		"Correction : sur la version web, l'Arène, le Social, le Compte et la sauvegarde en ligne affichaient « Connexion au serveur impossible ». Le navigateur décompressait déjà les réponses du serveur et le jeu essayait de le refaire, ce qui faisait échouer les requêtes.",
		"Le message d'erreur réseau indique maintenant un numéro d'erreur, pour faciliter le diagnostic.",
	]},
	{"version": "0.20.3", "date": "2026-09-28", "titre": "Récapitulatif des améliorations d'Échos",
	"changements": [
		"Fenêtre d'amélioration des Échos : le bouton « +1 » affiche son coût en or.",
		"Récapitulatif après chaque amélioration : niveaux gagnés, tentatives et or dépensé, stat principale avant → après, stats secondaires nouvelles ou renforcées (avec le gain).",
		"Écran des Échos : le bouton s'appelle simplement « Améliorer ».",
	]},
	{"version": "0.20.2", "date": "2026-09-28", "titre": "Amélioration des Échos jusqu'au +9",
	"changements": [
		"Échos Sanguins : nouveau bouton « Jusqu'à +9 » dans la fenêtre d'amélioration (avec +3, +6, +12 et +15).",
	]},
	{"version": "0.20.1", "date": "2026-09-28", "titre": "Symboles corrigés et fenêtre d'amélioration des Échos",
	"changements": [
		"Correction : les symboles (★ ⚔ ☠ ✦ ← → ✔…) s'affichaient en petits carrés sur certains ordinateurs et sur la version web, dans beaucoup de menus. Le jeu embarque maintenant une police de symboles (DejaVu Sans).",
		"Échos Sanguins : le bouton « Améliorer » ouvre une fenêtre d'amélioration : stat principale actuelle → au niveau suivant, prochain palier, chance de réussite et coût.",
		"Bouton « +1 » pour une tentative, et « Jusqu'à +3 / +6 / +12 / +15 » pour enchaîner les tentatives jusqu'à réussir (arrêt possible à tout moment, ou quand l'or manque), avec le coût moyen estimé.",
		"Une barre de chargement se remplit avant chaque résultat (option « Rapide ») et l'historique des tentatives s'affiche dans la fenêtre.",
	]},
	{"version": "0.20.0", "date": "2026-09-28", "titre": "Expéditions : la Marche Maudite et la Compagnie",
	"changements": [
		"Nouveau menu Expéditions (Aventure → Expédition) avec deux modes et une boutique.",
		"La Marche Maudite : une expédition roguelike par jour, la même pour tous. On choisit jusqu'à 5 unités et on traverse 3 régions (tirées des Actes) sur une carte à embranchements : combats, élites, événements, feux de camp, marchands, trésors, autels de sang et boss.",
		"Les PV et les K.O. sont conservés toute la marche. Après chaque victoire, on choisit 1 Bénédiction parmi 3 (29 bénédictions communes, rares et épiques).",
		"Pactes de Sang : aux autels, accepter une malédiction contre une grosse récompense et +15 % de score. 12 événements écrits avec des choix, un marchand ambulant et des élites qui proposent parfois de rejoindre la marche.",
		"Score final → Sceaux de Marche, record personnel et classement du jour en ligne (fichier supabase/03_marche.sql à lancer une fois dans Supabase).",
		"La Compagnie : chaque jour, 6 missions de 1 h à 12 h (dont une épique). 3 escouades en même temps, conditions à remplir (rôle, élément, niveau, rareté) et objectif bonus (+50 % de butin). Le temps passe même jeu fermé.",
		"Les unités en mission sont occupées : elles quittent l'équipe et l'armée, et ne peuvent pas être vendues, sacrifiées ou évoluées avant leur retour (carte grisée « En mission »).",
		"Boutique des Expéditions : Poussière d'Écho, élixirs, tomes, ressources de Sang, coffres, Éclats et Pierre d'Éveil contre des Sceaux de Marche (limites par semaine).",
		"Menu Admin : missions de la Compagnie instantanées, Marche illimitée (non classée).",
		"Difficulté de la Marche réglée par simulation (outils/calibrer_marche.gd).",
	]},
	{"version": "0.19.0", "date": "2026-09-28", "titre": "Donjons et évolutions",
	"changements": [
		"Nouveau mode Donjon (Aventure → Donjon) : 6 donjons de 10 niveaux — le Brasier Éternel (Feu), la Sylve Putride (Nature), les Fosses Englouties (Eau), la Crypte sans Lune (Ténèbres), le Sanctuaire Profané (Sacré) et le Puits de Sang (neutre).",
		"Une expédition = 4 combats d'affilée sans soin entre deux : vague de 5 monstres, mini-boss et ses 2 gardes, vague de 5 monstres, puis le boss du donjon. Stamina payée au départ (4 à 10), abandon possible entre deux combats.",
		"12 nouveaux ennemis : un mini-boss et un boss (avec phase 2) par donjon. Nouvel élément Neutre pour le Puits de Sang.",
		"18 ressources d'évolution : Goutte, Larme et Cœur de Braise, de Sève, d'Abysse, d'Ombre, d'Aube et de Sang ; les Larmes arrivent au niveau 4, les Cœurs au niveau 8. Le niveau suivant s'ouvre en terminant le précédent.",
		"Nouvel Autel d'Évolution (depuis les Donjons, l'Autel de Fusion ou la fiche d'une unité du Deck) : les 64 unités invocables ont une version évoluée, jamais invocable.",
		"Évolution : unité niveau 30 + ressources de son élément + Sang (plus l'unité est rare, plus les ressources sont grosses). Elle garde ses étoiles et ses Échos, repart au niveau 1 et monte jusqu'au niveau 40.",
		"Chaque évolution : nouveau nom, stats +25 à +40 % selon la rareté, un sort amélioré et parfois un nouveau sort au niveau 40. L'apparence évoluée viendra plus tard (en attendant, le portrait de base est utilisé).",
		"Bestiaire : filtre « Évolutions ». Autel de Fusion : une unité et son évolution comptent comme doublons pour l'Éveil.",
		"Difficulté des donjons réglée par simulation (réussite ~70 % avec l'équipe conseillée, plus dur aux niveaux 9 et 10).",
	]},
	{"version": "0.18.2", "date": "2026-09-28", "titre": "Bestiaire illustré",
	"changements": [
		"Bestiaire : les unités découvertes qui ont un portrait s'affichent en cartes illustrées (comme dans le Deck), en 150×200.",
		"Bestiaire : grande illustration carrée en haut de la fiche de l'unité, calée en haut pour ne pas couper la tête.",
		"Les unités non découvertes restent cachées (« ? ») ; les unités sans portrait gardent l'ancienne carte.",
	]},
	{"version": "0.18.1", "date": "2026-09-28", "titre": "Illustrations sans têtes coupées",
	"changements": [
		"Correction : les illustrations restent calées en haut de l'image, la tête des unités n'est plus coupée (fiche du Deck et cartes).",
		"Fiche du Deck : l'illustration est maintenant carrée et montre l'image en entier.",
	]},
	{"version": "0.18.0", "date": "2026-09-28", "titre": "Cartes illustrées",
	"changements": [
		"Nouvelles cartes illustrées : l'image de l'unité remplit toute la carte, avec le nom, le niveau, les étoiles et l'XP sur un voile sombre en bas, et une pastille de couleur pour l'élément.",
		"Deck : cartes plus grandes (150×200) pour mieux voir les illustrations.",
		"Fiche d'une unité dans le Deck : grande illustration en haut de la fiche.",
		"Les cartes illustrées apparaissent aussi dans l'Autel de Fusion, l'Armée, l'Arène, le Reliquaire et la révélation des invocations.",
		"18 nouveaux portraits : Chevalier Noir, Elf Sylvestre, Sorcier Sombre, Clerc Sacré, Guerrier Squelette, Gardiens d'Ombre, Rat Géant, Gobelin Pillard, Loup Gris, Zombie Errant, Bandit des Routes, Araignée Venimeuse, Chauve-Souris Nocturne, Limace Acide, Corbeau Maudit, Sanglier Sauvage, Brigand Ivre, Slime Gélatineux.",
	]},
	{"version": "0.17.0", "date": "2026-09-28", "titre": "Portraits des unités",
	"changements": [
		"Les cartes affichent maintenant le portrait illustré de l'unité (découpé en cercle, contour de la couleur de l'élément), partout : Deck, combat, Bestiaire, choix du héros, invocation, Échos, Reliquaire, Tours, Boss de Monde.",
		"Premiers portraits : les 8 héros de légende et le Seigneur Démon.",
		"Les unités sans portrait gardent leur initiale en attendant leur image ; les unités non découvertes du Bestiaire restent cachées (« ? »).",
		"Nouvel outil outils/decouper_planche.py : découpe une planche ChatGPT 3×3 en un portrait par unité dans assets/unites/.",
	]},
	{"version": "0.16.2", "date": "2026-09-27", "titre": "Correction du son sur la version web",
	"changements": [
		"Correction : la musique et les bruitages fonctionnent maintenant sur la version web (navigateur).",
		"Sur navigateur, le son démarre au premier clic (règle des navigateurs).",
	]},
	{"version": "0.14.0", "date": "2026-09-27", "titre": "Musique et bruitages",
	"changements": [
		"Musique pour chaque écran avec fondu enchaîné : menus, Aventure, combats, boss, Autel d'Invocation, Tour de l'Enfer, Tour du Paradis, Boss de Monde, victoire et défaite.",
		"Bruitages en combat : coups, coups critiques, magie, soins, boucliers, K.O. et rugissement des boss (géants et changement de phase).",
		"Invocation sonore : cercle magique, cartes qui se retournent, et un son de plus en plus impressionnant selon la rareté (SR, SSR, UR, Légende).",
		"Sons du quotidien : clic des boutons, retour, erreur (pas assez d'or ou de stamina), or gagné, coffres, montée de niveau.",
		"Réglage du volume de la musique et des bruitages dans les Paramètres (enregistré avec la partie, conservé après une nouvelle partie).",
	]},
	{"version": "0.13.0", "date": "2026-09-26", "titre": "Menu Admin (tests)",
	"changements": [
		"Menu Admin dans les Paramètres (visible seulement quand le jeu est lancé depuis Godot).",
		"Options à cocher : or, gemmes, stamina, Éclats et objets du Reliquaire infinis ; Bestiaire complet ; tous les chapitres débloqués ; tous les étages des Tours ; Boss de Monde tous disponibles et illimités ; héros invincibles ; ennemis affaiblis ; XP x10 ; amélioration d'Échos garantie.",
		"Décocher une option remet exactement la situation d'avant : la vraie progression n'est jamais modifiée.",
		"« MODE ADMIN ACTIF » s'affiche sur le menu principal quand une option est cochée.",
	]},
	{"version": "0.12.0", "date": "2026-09-26", "titre": "Effets d'invocation et événements",
	"changements": [
		"Nouvel effet d'invocation : cercle magique, cartes face cachée qui se retournent une à une.",
		"Plus la carte est rare, plus l'effet est impressionnant : lueur (R), aura (SR), rayons dorés et tremblement (SSR), éclairs et onde de choc (UR), halo divin (Légende).",
		"Le cercle change de couleur avant la révélation quand une carte rare arrive ; bouton « Tout révéler » pour aller plus vite.",
		"Bandeau d'événement en bas de l'Autel d'Invocation : invocations spéciales à durée limitée avec unités vedettes et compte à rebours.",
		"Premier événement : « Lune de Sang » (Empereur Déchu, Dragon d'Ombre, Archange Noir), puis « Aube Céleste ».",
	]},
	{"version": "0.11.1", "date": "2026-09-26", "titre": "Équilibrage de la stamina",
	"changements": [
		"Stamina max : +2 par niveau de compte (30 au niveau 1, 88 au niveau 30).",
		"Coûts dans l'Aventure réduits : combat 1, élite ou gardien 2, boss 3. Coffres, soins, mystères et embuscades restent gratuits.",
	]},
	{"version": "0.11.0", "date": "2026-09-26", "titre": "Stamina, niveau de compte et versions",
	"changements": [
		"Niveau de compte : niveau maximum 30, XP gagnée à chaque combat gagné (Aventure, Tours, Boss de Monde) + bonus au premier passage d'un chapitre.",
		"Chaque niveau augmente la stamina max (+1,5 par niveau : 30 au niveau 1, 73 au niveau 30) et recharge entièrement la stamina.",
		"Stamina : 1 point toutes les 5 minutes, même jeu fermé. Les combats de l'Aventure coûtent de la stamina (combat 2, élite/gardien 3, boss 5).",
		"Affichage de la stamina (avec le temps avant le prochain point) et du niveau de compte sur le menu et les plateaux.",
		"Journal des mises à jour dans le jeu (ouvert automatiquement après une mise à jour) et numéro de version affiché.",
		"Outil « Versions » dans l'éditeur Godot : sauvegarde .zip de chaque version et restauration d'une ancienne version.",
	]},
	{"version": "0.10.0", "date": "2026-09-26", "titre": "Modes rejouables : Tours, Boss de Monde, Reliquaire",
	"changements": [
		"Tour de l'Enfer (on descend) et Tour du Paradis (on monte) : 100 étages, élite tous les 5 étages, boss tous les 10, super boss à l'étage 100.",
		"Butin spécial des tours (Braises, Plumes, Poussière d'Écho, coffres, élixirs, tomes, Pierres d'Éveil) ; réinitialisation chaque lundi avec compte à rebours.",
		"Boss de Monde : 7 boss géants, un par jour de la semaine ; armée de 20 unités en 4 escouades ; 3 essais par jour ; récompenses selon les dégâts.",
		"Le Reliquaire : coffres d'or, élixirs de stamina, tomes d'XP, Forge de 8 héros exclusifs, échanges, Atelier d'Échos (fabrication et démantèlement).",
		"Pierres d'Éveil utilisables à l'Autel de Fusion à la place d'un doublon.",
		"46 nouvelles unités (monstres et boss des tours, boss de monde, héros de forge) ; filtre « Boss de Monde » dans le Bestiaire.",
		"Correction : le retour de l'écran Aventure ramène bien au menu principal.",
	]},
	{"version": "0.9.0", "date": "2026-09-26", "titre": "Autel de Fusion",
	"changements": [
		"Éveil : sacrifier des doublons pour gagner des étoiles (★1 à ★6 « Éveillé »), +6 % de stats par étoile, +10 % à l'Éveil.",
		"Absorption : sacrifier des unités pour donner de l'XP au héros principal.",
		"Les unités de l'équipe, le héros de départ et les unités verrouillées ne peuvent pas être sacrifiés.",
		"Étoiles visibles sur les cartes, dans le Deck et prises en compte en combat.",
	]},
	{"version": "0.8.1", "date": "2026-09-26", "titre": "Équilibrage des Échos et du début de partie",
	"changements": [
		"Les monstres normaux peuvent donner des Échos (surtout de faible qualité) ; élites, gardiens et boss en donnent plus et de meilleurs.",
		"Début de l'aventure adouci (jusqu'à la fin de l'Acte II).",
		"Le set et l'emplacement d'Écho de chaque Acte et chapitre sont affichés (Histoire, écran d'Acte, plateau).",
	]},
	{"version": "0.8.0", "date": "2026-09-26", "titre": "Échos Sanguins",
	"changements": [
		"6 emplacements, 12 sets, 5 raretés, étoiles 1 à 6, amélioration jusqu'à +15 avec chances dégressives.",
		"Écran des Échos : équiper, retirer, améliorer, vendre, verrouiller, filtres et tri.",
		"Chaque Acte donne un set, le chapitre N donne l'emplacement N.",
	]},
	{"version": "0.7.0", "date": "2026-09-25", "titre": "Deck et Autel d'Invocation",
	"changements": [
		"Deck : équipe de 5 places (Avant / Arrière), doublons autorisés, fiche détaillée, vente simple et multiple, verrouillage.",
		"Autel d'Invocation : Pacte Doré (or, x1/x10, N/R/SR) et Pacte Supérieur (Éclats des boss, x1/x10, SR/SSR/UR) avec garantie.",
		"Niveaux des unités (max 30) et XP gagnée en combat.",
	]},
	{"version": "0.6.0", "date": "2026-09-25", "titre": "Système de combat",
	"changements": [
		"Combat automatique : ordre par AGI, Avant/Arrière, éléments, skills, passifs, afflictions, boss à 2 phases.",
		"Écran de combat animé (vitesse x1/x2/x4, Passer) et récompenses.",
		"Rencontres par Acte, élites et gardiens plus forts, difficulté croissante réglée par simulation.",
	]},
	{"version": "0.5.0", "date": "2026-09-25", "titre": "Héros, monstres et Bestiaire",
	"changements": [
		"123 unités : stats principales (PV, ATK, DEF, AGI, MAG) et secondaires, skills aux niveaux 1/10/20/30.",
		"8 héros de légende : choix du héros de départ (à nouveau après une nouvelle partie).",
		"Bestiaire (codex) accessible depuis le menu principal.",
	]},
	{"version": "0.4.0", "date": "2026-09-25", "titre": "Sauvegarde",
	"changements": [
		"Sauvegarde automatique avec copie de secours, ressources, stamina et compte.",
		"Fenêtre Paramètres : code de sauvegarde (copier / importer) et nouvelle partie.",
	]},
	{"version": "0.3.1", "date": "2026-09-25", "titre": "Progression",
	"changements": [
		"Pas de retour en arrière sur les plateaux.",
		"Chapitres et Actes débloqués un par un.",
		"Correction du bouton retour des écrans.",
	]},
	{"version": "0.3.0", "date": "2026-09-25", "titre": "Plateaux de jeu",
	"changements": [
		"72 plateaux case par case : combats, élites, gardiens, boss, coffres, soins, mystères, pièges.",
		"Embranchements qui se referment avant le boss, plateaux de plus en plus grands au fil des Actes.",
	]},
	{"version": "0.2.0", "date": "2026-09-25", "titre": "Histoire principale",
	"changements": [
		"12 Actes et 72 chapitres, un écran illustré par Acte avec ses 6 chapitres.",
		"Bulles d'information sur les Actes et les chapitres.",
	]},
	{"version": "0.1.0", "date": "2026-09-24", "titre": "Premiers pas sur Godot",
	"changements": [
		"Menu principal et écran Aventure (image de fond + zones cliquables).",
		"Publication web sur GitHub Pages.",
	]},
]


static func texte() -> String:
	return "v" + NUMERO


## Versions plus récentes que `vue` (toutes si vue est vide).
static func nouveautes_depuis(vue: String) -> Array:
	var l: Array = []
	for v in HISTORIQUE:
		if v["version"] == vue:
			break
		l.append(v)
	return l


## Le journal au format Markdown (identique à CHANGELOG.md).
static func en_markdown() -> String:
	var t := "# Journal des mises à jour — %s\n\nVersion actuelle : **%s** (%s)\n" % [NOM_JEU, NUMERO, DATE]
	for v in HISTORIQUE:
		t += "\n## v%s — %s  (%s)\n\n" % [v["version"], v["titre"], v["date"]]
		for c in v["changements"]:
			t += "- %s\n" % c
	return t
