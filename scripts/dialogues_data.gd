class_name DialoguesData
extends RefCounted
## DIALOGUES DE L'HISTOIRE PRINCIPALE (scénario : HISTOIRE.md).
##
## Clé "acte-chapitre" -> {"debut": [...], "fin": [...]}. Chaque réplique : [personnage, texte].
##  - "debut" s'affiche en entrant pour la première fois dans le chapitre ;
##  - "fin" s'affiche après la victoire contre le boss du chapitre (première fois).
## Personnages : voir PERSONNAGES (nom affiché, couleur, image facultative dans
## res://assets/personnages/<id>.png, sinon le portrait de l'unité du même id, sinon un médaillon).
## "toi" = le joueur (son prénom + Valcendre quand il est connecté).
## Pour corriger un texte : modifie-le ici, c'est tout.

const PERSONNAGES := {
	"narr": {"nom": "", "couleur": "c8b8a8"},
	"toi": {"nom": "Toi", "couleur": "ffd27a"},
	"kael": {"nom": "Kaël", "couleur": "ff7a6a"},
	"kael_sombre": {"nom": "Kaël", "couleur": "b04aff"},
	"frere_masque": {"nom": "Le Frère Masqué", "couleur": "b04aff"},
	"aldric": {"nom": "Aldric Valcendre", "couleur": "e0c080"},
	"othmar": {"nom": "Othmar, le Premier Roi", "couleur": "9ab0d0"},
	"compagnon": {"nom": "Corvin, le mercenaire", "couleur": "d0a070"},
	"morvael": {"nom": "Morvaël", "couleur": "d02040"},
	"voix": {"nom": "Une voix", "couleur": "d02040"},
	"ermite": {"nom": "L'Ermite de Pierre", "couleur": "a0a8a0"},
	"moine": {"nom": "Le moine mourant", "couleur": "c0b090"},
	"veuve": {"nom": "La veuve", "couleur": "a0b0c0"},
	"commandant": {"nom": "Le commandant Hervald", "couleur": "c0c8d0"},
	"resistante": {"nom": "Une résistante", "couleur": "c0a890"},
	"seigneur_des_cendres": {"nom": "Le Seigneur des Cendres", "couleur": "ff6a3a"},
	"veuve_lanternes": {"nom": "La Veuve aux Lanternes", "couleur": "7ab0d0"},
	"capitaine_drapeau_noir": {"nom": "Le Capitaine au Drapeau Noir", "couleur": "e0703a"},
	"seigneur_donjon": {"nom": "Le Seigneur du Donjon", "couleur": "a080c0"},
	"inquisiteur_implacable": {"nom": "L'Inquisiteur", "couleur": "f0e0a0"},
	"reflet_ame": {"nom": "Ton reflet", "couleur": "a080ff"},
	"dame_ronciers": {"nom": "La Dame des Ronciers", "couleur": "7ad07a"},
	"avatar_eclipse": {"nom": "L'Avatar de l'Éclipse", "couleur": "d04060"},
	"maitre_supplices": {"nom": "Le Maître des Supplices", "couleur": "ff8040"},
	"empereur_dechu": {"nom": "L'Empereur Déchu", "couleur": "a0a0c0"},
	"heritier_maudit": {"nom": "L'Héritier Maudit", "couleur": "c02060"},
}

const DIALOGUES := {
	# =================================================================
	# ACTE I — Les Cendres du Serment
	# =================================================================
	"1-1": {"debut": [
		["narr", "Domaine de Valcendre. Le soir de la fête des moissons."],
		["kael", "Encore raté, grand frère ! Si tu te bats comme ça contre un vrai ennemi, c'est moi qui devrai te protéger."],
		["toi", "Profite, Kaël. Demain, je te laisse gagner une seconde fois."],
		["aldric", "Assez, vous deux. Venez près du feu… Il y a des choses que je dois vous dire, cette nuit."],
		["narr", "Il n'en aura pas le temps. À l'horizon, les collines s'embrasent : une armée de cendres marche sur Valcendre."],
	], "fin": [
		["aldric", "Écoute-moi… Prends ton frère et fuyez par la crypte."],
		["aldric", "Protège ton frère. Toujours. Quoi qu'il arrive… quoi qu'il devienne."],
		["kael", "Père ! PÈRE !"],
		["narr", "Aldric Valcendre tombe en couvrant la fuite de ses fils. Derrière eux, le domaine brûle."],
	]},
	"1-2": {"debut": [
		["narr", "La crypte des ancêtres. Les tombeaux ont été ouverts, pillés, profanés."],
		["kael", "Qui peut faire ça à des morts ?"],
		["toi", "Ne t'éloigne pas. Père a parlé d'un médaillon, dans le tombeau du Premier Roi."],
	], "fin": [
		["narr", "Dans le dernier tombeau : un médaillon brisé en deux. Une pierre bleue, une pierre rouge."],
		["toi", "« Quand la Larme et le Sang se rejoindront, la Soif sera scellée. » Qu'est-ce que ça veut dire ?"],
		["kael", "Aucune idée. Je prends la rouge : elle me va mieux. Garde la Larme, toi, tu pleures plus souvent."],
		["voix", "…Kaël…"],
		["kael", "Tu as entendu ? …Non. Rien. Allons-y."],
	]},
	"1-3": {"debut": [
		["narr", "Les routes de l'exil. Des familles entières fuient vers le sud, avec ce qu'elles ont pu sauver."],
		["kael", "Tu dors encore, toi ? Moi, chaque nuit, je vois des yeux dans le feu."],
		["toi", "Ce sont des cauchemars. Ils passeront."],
		["narr", "Kaël cache ses mains. Sur ses poignets, les veines ont noirci."],
	]},
	"1-4": {"debut": [
		["narr", "Une clairière, à l'aube. Tes premiers compagnons se sont joints à vous."],
		["toi", "Kaël. Donne-moi ta main."],
		["narr", "Les deux frères mêlent leur sang sur les deux moitiés du médaillon."],
		["kael", "Ensemble, jusqu'à la fin."],
		["toi", "Ensemble, jusqu'à la fin."],
	]},
	"1-5": {"debut": [
		["narr", "Une patrouille de pillards vous barre la route."],
		["kael", "Laisse-les-moi, grand frère. Je sens… je sens que je peux les écraser."],
		["toi", "Kaël, attends !"],
	], "fin": [
		["narr", "Une flamme noire a jailli des mains de Kaël. Des pillards, il ne reste que des cendres."],
		["kael", "Tu as vu ça ? Ha… ha ha…"],
		["kael", "…Qu'est-ce que j'ai fait ? Qu'est-ce qui m'arrive ?"],
		["toi", "On va trouver. Je te le promets."],
	]},
	"1-6": {"debut": [
		["narr", "Les portes de la ville fortifiée. Le Seigneur des Cendres vous y attend."],
		["seigneur_des_cendres", "Les fils de Valcendre. Enfin. Ton père a caché son cadet bien longtemps."],
		["toi", "Tu as tué notre père. Tu ne toucheras pas à mon frère."],
	], "fin": [
		["seigneur_des_cendres", "Tu te bats pour lui… mais il est déjà à Elle."],
		["narr", "La nuit tombe sur la ville. Au matin, la paillasse de Kaël est vide. Sa moitié du médaillon a disparu."],
		["narr", "Un mot, griffonné à la hâte : « Ne me cherche pas. Je te ferais du mal. »"],
		["toi", "Je t'ai promis. Ensemble, jusqu'à la fin."],
	]},
	# =================================================================
	# ACTE II — L'Étreinte du Deuil
	# =================================================================
	"2-1": {"debut": [
		["narr", "Une cité drapée de noir. Chaque maison pleure quelqu'un."],
		["toi", "Tant de morts… Et je ne sais même pas si mon frère est parmi eux."],
		["narr", "Partout, la même rumeur : des fils emportés par une flamme noire."],
	]},
	"2-2": {"debut": [
		["narr", "Dans les rues vides, des fantômes rejouent la nuit de l'attaque."],
		["aldric", "Il fallait que tu saches… Le sang des Valcendre porte une dette…"],
		["toi", "Père ? Quelle dette ? PÈRE !"],
	]},
	"2-3": {"debut": [
		["narr", "Un refuge de pestiférés, oublié de tous."],
		["moine", "Valcendre… Je connais ce nom. On disait qu'à chaque génération, l'un de vos fils devenait « l'Héritier »."],
		["toi", "L'héritier de quoi ?"],
		["moine", "D'une soif qui ne s'éteint jamais…"],
	]},
	"2-4": {"debut": [
		["veuve", "Un jeune homme, oui. Les veines noires, les yeux rouges. Il pleurait en marchant vers le nord."],
		["veuve", "Il a dit : « Pardon, grand frère. » Qui êtes-vous pour lui ?"],
		["toi", "Celui qui va le ramener."],
	]},
	"2-5": {"debut": [
		["narr", "La nuit des lanternes noires. Les flammes montrent ce que les vivants ont perdu."],
		["narr", "Dans l'une d'elles : Kaël, vivant, entouré d'ombres qui lui murmurent à l'oreille."],
		["toi", "Il est vivant. Il est vivant !"],
	]},
	"2-6": {"debut": [
		["veuve_lanternes", "Reste avec nous. Ici, les morts ne partent jamais. Ton père, ton frère… tu pourrais les garder."],
		["toi", "Mon frère n'est pas mort. Et je ne vis pas dans le passé."],
	], "fin": [
		["narr", "Les lanternes s'éteignent une à une. Les morts de la cité trouvent enfin le repos."],
		["toi", "Le nord. Il est parti vers le nord. Nous aussi."],
	]},
	# =================================================================
	# ACTE III — Sous les Drapeaux Noirs
	# =================================================================
	"3-1": {"debut": [
		["narr", "Un camp de mercenaires. L'odeur de la bière et du sang."],
		["compagnon", "Des nobles en fuite, ici ? Vous cherchez des lames ? Corvin, à votre service. Je ne suis pas cher, et je ne trahis jamais."],
		["toi", "Ça, on verra."],
	]},
	"3-2": {"debut": [
		["compagnon", "Les lieutenants du Capitaine sont payés en or… par un chevalier masqué. Une flamme noire à la main, paraît-il."],
		["toi", "Une flamme noire ?"],
		["compagnon", "Tu connais quelqu'un comme ça ?"],
	]},
	"3-3": {"debut": [
		["narr", "Au marché noir, on vend des reliques pillées. Sur un étal : l'épée de cérémonie de Valcendre."],
		["toi", "Tout ce que ma famille possédait finit ici, vendu au plus offrant."],
	]},
	"3-4": {"debut": [
		["narr", "L'étendard de ta maison, repris aux pillards. Quelqu'un l'a souillé d'un symbole : un œil qui boit."],
		["compagnon", "Mauvais présage. Très mauvais. À ta place, je le brûlerais."],
		["toi", "Je le garde. Je veux savoir ce que ça veut dire."],
	]},
	"3-5": {"debut": [
		["narr", "Le siège du fortin. Sur les remparts ennemis, une silhouette en armure noire, le visage caché par un masque."],
		["narr", "Le Frère Masqué te regarde longtemps. Puis il se retire, sans combattre."],
		["toi", "Ce port de tête… Non. Impossible."],
	]},
	"3-6": {"debut": [
		["capitaine_drapeau_noir", "Le masqué m'a bien payé pour te ralentir, petit noble. Il tient à ce que tu restes loin du nord."],
	], "fin": [
		["narr", "Le Capitaine tombe. Un de tes mercenaires tire sa lame vers ton dos… Corvin l'abat d'une dague."],
		["compagnon", "Je t'avais dit que je ne trahissais jamais. Les autres, par contre…"],
		["toi", "Merci, Corvin. Je te dois la vie."],
		["compagnon", "Oh, je m'en souviendrai."],
	]},
	# =================================================================
	# ACTE IV — Le Sépulcre des Oubliés
	# =================================================================
	"4-1": {"debut": [
		["narr", "Les catacombes des premiers Valcendre. Personne n'y est descendu depuis des siècles."],
		["toi", "Si la réponse existe quelque part, c'est ici."],
	]},
	"4-2": {"debut": [
		["narr", "Des énigmes gravées dans la pierre, de la main même du Premier Roi."],
		["toi", "« Ce que j'ai pris, mon sang le rendra. » Qu'as-tu pris, Othmar ?"],
	]},
	"4-3": {"debut": [
		["narr", "Des gardiens d'os se dressent… puis s'inclinent en sentant ton sang."],
		["narr", "Ils te laissent passer. Mais seulement après t'avoir éprouvé."],
	]},
	"4-4": {"debut": [
		["narr", "Les fresques du Sépulcre racontent une guerre perdue d'avance… et un roi agenouillé devant une ombre."],
		["narr", "Othmar Valcendre a offert à la Soif le sang de sa lignée. À chaque génération, un fils."],
		["toi", "Un fils à chaque génération… Kaël. Père savait. Il a toujours su."],
	]},
	"4-5": {"debut": [
		["narr", "L'autel du culte de la Soif. Des noms gravés : les Héritiers de chaque génération."],
		["narr", "Le dernier nom est à moitié écrit, la pierre encore fraîche : « KAË… »"],
		["toi", "Non. Pas lui. Vous ne l'aurez pas."],
	]},
	"4-6": {"debut": [
		["seigneur_donjon", "Le Geôlier est venu. Enfin. Montre-moi si tu es digne de ton sang."],
	], "fin": [
		["seigneur_donjon", "Le Geôlier… Celui qui devra choisir… Pauvre enfant."],
		["toi", "Choisir quoi ? Réponds !"],
		["narr", "Le gardien millénaire se change en poussière. Sa question reste sans réponse."],
	]},
	# =================================================================
	# ACTE V — L'Aiguillon de la Souffrance
	# =================================================================
	"5-1": {"debut": [
		["narr", "Des terres brûlées à perte de vue. Les armées du Frère Masqué sont passées par ici."],
		["toi", "Si c'est toi qui as fait ça, Kaël… Non. Je refuse d'y croire."],
	]},
	"5-2": {"debut": [
		["narr", "La fièvre ronge le groupe. Corvin soigne les blessés, sans jamais se plaindre."],
		["compagnon", "Repose-toi. Je veille. Et je note tout, pour la route : où on va, qui on croise…"],
	]},
	"5-3": {"debut": [
		["narr", "Une vision, dans la chaleur : Kaël, enfant, assis au bord du chemin."],
		["kael", "Pourquoi tu ne m'as pas retenu, grand frère ? Tu dormais si bien, cette nuit-là…"],
		["toi", "Ce n'est pas réel. Ce n'est pas réel…"],
	]},
	"5-4": {"debut": [
		["inquisiteur_implacable", "Valcendre. La lignée maudite. Votre sang a nourri le Mal depuis des siècles."],
		["inquisiteur_implacable", "Le feu purifiera ce que vos ancêtres ont souillé."],
	]},
	"5-5": {"debut": [
		["narr", "Tes compagnons ont entendu l'Inquisiteur. Le doute s'installe autour du feu."],
		["compagnon", "Si ton sang est maudit… qu'est-ce qui nous dit que tu ne deviendras pas comme lui ?"],
		["toi", "Rien. Je ne vous retiens pas. Mais moi, je n'abandonnerai pas mon frère."],
		["narr", "Personne ne part."],
	]},
	"5-6": {"fin": [
		["narr", "L'Inquisiteur tombe. Ta compagnie s'est resserrée autour de toi, plus soudée d'avoir douté."],
		["toi", "Nous continuons. Ensemble."],
	]},
	# =================================================================
	# ACTE VI — Les Larmes de Pierre
	# =================================================================
	"6-1": {"debut": [
		["narr", "Une forêt pétrifiée. Les arbres ont gardé la forme des flammes qui les ont figés."],
		["toi", "Une flamme noire est passée ici. Il y a longtemps."],
	]},
	"6-2": {"debut": [
		["narr", "Parmi les statues, un jeune homme qui te ressemble trait pour trait."],
		["narr", "Sur le socle : « Edran Valcendre. Héritier. Pétrifié par la main de son frère, pour que le monde vive. »"],
		["toi", "Son propre frère…"],
	]},
	"6-3": {"debut": [
		["ermite", "Tu cherches à briser le pacte, fils de Valcendre ? Il a toujours été brisé par un frère."],
		["ermite", "Mais jamais sans perte. Jamais."],
		["toi", "Alors je serai le premier."],
	]},
	"6-4": {"debut": [
		["narr", "Le médaillon pèse soudain comme une pierre. La Larme est glacée."],
		["toi", "Il souffre. Quelque part, Kaël souffre."],
	]},
	"6-5": {"debut": [
		["narr", "Dans la faille de cristal, une voix résonne à travers ton médaillon."],
		["kael_sombre", "Va-t'en, grand frère. Chaque fois que tu t'approches, Elle se nourrit de ma peur pour toi."],
		["toi", "Kaël ! Où es-tu ? Kaël !"],
	]},
	"6-6": {"debut": [
		["narr", "Le lac de verre noir. Ton reflet te sourit… avec le visage de Kaël. Puis le tien, corrompu."],
		["reflet_ame", "Un jour, tu devras le tuer. Tu le sais. Alors deviens comme moi : ce sera plus facile."],
	], "fin": [
		["toi", "Je ne deviendrai pas ce qu'on attend de moi. Ni bourreau, ni Héritier."],
		["narr", "Le reflet se brise. Le lac redevient simple eau."],
	]},
	# =================================================================
	# ACTE VII — Le Pacte des Ronces
	# =================================================================
	"7-1": {"debut": [
		["narr", "Les marais. Les murmures t'appellent par ton nom… avec la voix de ton père."],
		["toi", "Avancez. Ne les écoutez pas."],
	]},
	"7-2": {"debut": [
		["dame_ronciers", "Je sais où se cache ton frère, petit Valcendre. Je sais tout ce qui pousse et tout ce qui pourrit."],
		["dame_ronciers", "Mon prix ? Un souvenir. Un seul. Celui que tu chéris le plus."],
	]},
	"7-3": {"debut": [
		["toi", "Prends-le. Prends ce que tu veux."],
		["narr", "La Dame cueille un souvenir comme on cueille une fleur : le rire de Kaël."],
		["toi", "…Il riait comment, déjà ? Je… je ne m'en souviens plus."],
	]},
	"7-4": {"debut": [
		["narr", "Les ronces se referment : la Dame ne tient ses promesses qu'à moitié."],
	]},
	"7-5": {"debut": [
		["dame_ronciers", "Le pacte est scellé. Ton frère est au nord, sur les Terres de l'Éclipse. Il t'attend… ou il te fuit."],
	]},
	"7-6": {"debut": [
		["narr", "Le pacte te ronge. Une soif étrange, qui ne vient pas de toi."],
		["toi", "C'est donc ça, ce qu'il ressent… chaque jour."],
	], "fin": [
		["narr", "Tu brises le lien en abattant la Dame. Mais le souvenir volé, lui, reste enfermé dans ses roses mortes."],
	]},
	# =================================================================
	# ACTE VIII — L'Éclipse du Sang
	# =================================================================
	"8-1": {"debut": [
		["narr", "Le soleil devient rouge, puis noir. Une éclipse de sang recouvre le monde."],
		["commandant", "Tu es le Valcendre dont on parle ? Alors bats-toi avec nous. Nous ne tiendrons pas seuls."],
	]},
	"8-2": {"debut": [
		["narr", "Les monstres déferlent. À leur tête, le Frère Masqué."],
	]},
	"8-3": {"debut": [
		["narr", "Le bastion tombe. Le Frère Masqué te fait face, lame levée."],
		["toi", "Kaël ?"],
		["narr", "Au dernier moment, la lame se détourne. Il disparaît dans la fumée."],
	]},
	"8-4": {"debut": [
		["commandant", "Pars, Valcendre. Quelqu'un doit survivre pour arrêter ça. Protège ce que tu aimes… comme moi."],
		["narr", "Le commandant Hervald tombe en couvrant votre retraite."],
	]},
	"8-5": {"debut": [
		["narr", "Un fragment d'étoile arraché à l'éclipse. Dans sa lumière, la vérité : le Frère Masqué porte la moitié rouge du médaillon."],
		["toi", "C'est lui. C'est vraiment lui."],
	]},
	"8-6": {"fin": [
		["narr", "La lumière revient sur un champ de morts. Une victoire qui a le goût du deuil."],
		["toi", "Je sais maintenant qui je devrai affronter. Et je sais que je ne pourrai pas le tuer."],
	]},
	# =================================================================
	# ACTE IX — Là où Meurent les Légendes
	# =================================================================
	"9-1": {"debut": [
		["narr", "Le cimetière des champions. Ici reposent les plus grands héros du passé."],
	]},
	"9-2": {"debut": [
		["othmar", "Un Valcendre. Encore un. Viens-tu me maudire, toi aussi ?"],
		["toi", "Othmar. Le Premier Roi. C'est toi qui as vendu notre sang."],
	]},
	"9-3": {"debut": [
		["narr", "Parmi les armes oubliées : la lame d'Aldric, forgée pour « le jour où il faudrait choisir »."],
		["toi", "Tu savais, père. Tu m'as préparé, sans jamais oser me le dire."],
	]},
	"9-4": {"debut": [
		["narr", "Les ancêtres te jugent. Une seule question : tuerais-tu ton frère pour sauver le monde ?"],
		["toi", "Non."],
		["narr", "Le silence dure longtemps. Puis les portes s'ouvrent quand même."],
	]},
	"9-5": {"debut": [
		["narr", "Des tombes ouvertes, vidées : Morvaël lève une armée avec les morts."],
		["toi", "Elle se prépare. Elle veut un corps. Elle veut Kaël, tout entier."],
	]},
	"9-6": {"debut": [
		["othmar", "Combats-moi, et je te dirai tout. C'est le seul prix que je puisse encore payer."],
	], "fin": [
		["othmar", "Pour sceller la Soif, la Larme et le Sang doivent se rejoindre…"],
		["othmar", "…et l'un des deux frères doit devenir sa prison. À jamais."],
		["toi", "Non. Il y a toujours un autre moyen."],
		["othmar", "Je l'ai cherché pendant mille ans, enfant."],
	]},
	# =================================================================
	# ACTE X — Les Chemins de la Désolation
	# =================================================================
	"10-1": {"debut": [
		["narr", "Les terres de la Soif. Plus rien ne pousse, plus rien ne chante."],
	]},
	"10-2": {"debut": [
		["resistante", "Un prisonnier aux veines noires, dans la Citadelle. La nuit, il crie un nom. Le tien, je crois."],
		["toi", "Kaël…"],
	]},
	"10-3": {"debut": [
		["narr", "La Citadelle des Supplices se dresse devant vous, hérissée de piques."],
	]},
	"10-4": {"debut": [
		["compagnon", "Je connais un passage. Fais-moi confiance, comme toujours."],
	]},
	"10-5": {"debut": [
		["narr", "Au fond des cachots : un jeune homme enchaîné, amaigri, couvert de cicatrices."],
		["narr", "À côté de lui, vide, l'armure du Frère Masqué."],
		["kael", "…Je t'avais dit de ne pas venir."],
		["toi", "Je t'avais promis de venir."],
		["narr", "Les deux frères se retrouvent enfin."],
	]},
	"10-6": {"debut": [
		["maitre_supplices", "Si touchant. Je l'ai tordu pendant des mois pour briser sa volonté… et tu la lui rends en une nuit."],
	], "fin": [
		["narr", "La nuit, au coin du feu. Les deux moitiés du médaillon reposent côte à côte."],
		["kael", "Tu te souviens de ton rire, quand père est tombé du cheval ? Tu riais si fort qu'il a fini par rire aussi."],
		["toi", "Et le tien ? Comment était ton rire, Kaël ? Je… je l'ai perdu."],
		["kael", "Idiot. Tu l'entendras quand tout ça sera fini."],
	]},
	# =================================================================
	# ACTE XI — Le Jugement des Frères
	# =================================================================
	"11-1": {"debut": [
		["narr", "À l'aube, Kaël est parti. Les deux moitiés du médaillon ont disparu avec lui."],
		["compagnon", "Tu cherches ton frère ? Il est parti ouvrir le Trône. C'est moi qui lui ai soufflé l'idée."],
		["compagnon", "« Ouvre le Trône, et Elle épargnera ton frère. » Il a dit oui sans hésiter. Touchant, non ?"],
		["toi", "Corvin… Depuis le début ?"],
		["compagnon", "Depuis le premier jour. Je t'avais dit que je m'en souviendrais."],
	]},
	"11-2": {"debut": [
		["kael_sombre", "Ne me déteste pas, grand frère. Elle t'aurait tué. J'ai choisi ta vie."],
		["kael_sombre", "Laisse-moi te protéger, pour une fois."],
		["toi", "Elle te ment, Kaël ! Elle veut nous avoir tous les deux !"],
	]},
	"11-3": {"debut": [
		["compagnon", "Rien de personnel. La Soif paie mieux que les Valcendre, voilà tout."],
	]},
	"11-4": {"debut": [
		["narr", "Kaël a remis le masque. Il mène l'armée de la Soif contre toi."],
		["frere_masque", "Recule. Je t'en supplie, recule."],
	]},
	"11-5": {"debut": [
		["toi", "Il croit se sacrifier pour moi. Et c'est exactement ce qu'Elle attendait."],
	]},
	"11-6": {"debut": [
		["frere_masque", "Tu ne comprends pas. Si tu passes cette porte, Elle te prendra aussi."],
		["toi", "Alors enlève ce masque et dis-le-moi en face."],
	], "fin": [
		["narr", "Le masque se brise. Dessous, le visage de Kaël, baigné de larmes."],
		["kael_sombre", "Ne me suis pas. Je t'en supplie… ne me suis pas."],
		["narr", "Il s'enfuit vers le Trône de Cendres."],
	]},
	# =================================================================
	# ACTE XII — L'Éternité en Héritage
	# =================================================================
	"12-1": {"debut": [
		["narr", "Le Trône de Cendres. Au pied des marches, Kaël t'attend, l'épée à la main, presque entièrement consumé."],
		["kael_sombre", "Elle est en moi, grand frère. Partout. Si tu ne me tues pas, c'est moi qui te tuerai."],
		["toi", "Alors bats-toi. Mais je ne te tuerai pas."],
	], "fin": [
		["narr", "Kaël est à terre. Tu lâches ton arme et lui tends la main."],
		["toi", "Ensemble, jusqu'à la fin. Tu te souviens ?"],
		["narr", "Tes larmes tombent sur la pierre rouge qu'il serre contre lui. La Larme et le Sang se rejoignent."],
		["kael", "…Grand frère ?"],
		["narr", "Dans un hurlement, la Soif est arrachée du corps de Kaël."],
	]},
	"12-2": {"debut": [
		["empereur_dechu", "Le vaisseau est perdu ? Alors la garde du Premier Roi se battra jusqu'à la dernière cendre."],
		["kael", "Comme à l'entraînement, grand frère ?"],
		["toi", "Comme à l'entraînement. Mais cette fois, c'est moi qui te protège."],
	]},
	"12-3": {"debut": [
		["morvael", "Sans corps, je prendrai TOUS ceux que j'ai bus. Mille Héritiers. Mille fils Valcendre."],
		["narr", "La Soif prend forme : l'Héritier Maudit."],
	]},
	"12-4": {"debut": [
		["kael", "Le médaillon brille… mais il réclame quelque chose. Une serrure. Une prison."],
		["toi", "On trouvera. Frappe d'abord."],
	]},
	"12-5": {"debut": [
		["toi", "Laisse-moi être la serrure. C'est mon rôle. Le Geôlier, c'est moi."],
		["kael", "Toute ma vie, Elle m'a choisi. Cette fois, c'est moi qui choisis."],
		["kael", "Et je te choisis, toi."],
	]},
	"12-6": {"debut": [
		["heritier_maudit", "Mille Héritiers… et le dernier sera le plus doux."],
		["kael", "Pas cette fois."],
	], "fin": [
		["kael", "Promets-moi de rire, grand frère. Pour nous deux."],
		["narr", "Kaël s'enferme avec la Soif dans le médaillon réuni, qui se fige en pierre rouge et bleue."],
		["toi", "KAËL !"],
	]},
	# =================================================================
	# ACTE XIII (caché) — Le Sang et la Larme
	# =================================================================
	"13-1": {"debut": [
		["narr", "Un an plus tard. La pierre bleue du médaillon pleure chaque matin."],
		["ermite", "Fils de Valcendre. Relis la dernière ligne du Sceau. Celle que le temps a effacée."],
		["toi", "« …et la serrure sera celui du sang qui la choisit. » Celui du sang… pas forcément un frère ?"],
		["ermite", "Pas forcément un frère. Quelqu'un qui porte cette dette depuis bien plus longtemps que vous."],
	]},
	"13-2": {"debut": [
		["narr", "Les marais. Dans les roses mortes de la Dame des Ronciers, un souvenir attend encore."],
		["toi", "Le rire de Kaël. Je viens le reprendre."],
	], "fin": [
		["narr", "Tu reprends le souvenir. Un rire d'enfant, clair, insolent, résonne dans ta tête."],
		["toi", "C'est comme ça qu'il riait… Je m'en souviens. Je m'en souviens !"],
	]},
	"13-3": {"debut": [
		["narr", "Tu poses la main sur le médaillon… et tu tombes à l'intérieur. Un monde de verre rouge et bleu."],
		["voix", "Tu n'as rien à faire ici, Geôlier. Ici, tout m'appartient."],
	]},
	"13-4": {"debut": [
		["narr", "Des silhouettes enchaînées : les Héritiers de chaque génération. Parmi eux, Edran, pétrifié par son frère."],
		["toi", "Vous avez assez souffert. Levez-vous."],
	], "fin": [
		["narr", "Libérés, les Héritiers deviennent des chaînes de lumière qui s'enroulent autour de la Soif."],
	]},
	"13-5": {"debut": [
		["narr", "Au cœur du Sceau, Kaël, enchaîné, presque éteint."],
		["kael", "…Tu n'aurais pas dû venir."],
		["toi", "Je t'ai apporté quelque chose. Écoute."],
		["narr", "Tu lui rends son rire. Il rit, faiblement… puis pour de vrai. Ses chaînes se brisent."],
		["kael", "Alors on la finit ensemble, grand frère ?"],
		["toi", "Ensemble, jusqu'à la fin."],
	]},
	"13-6": {"debut": [
		["morvael", "Vous ne pouvez pas me détruire. Il faudra toujours une serrure. L'un de vous restera ici, à jamais."],
	], "fin": [
		["othmar", "C'est ma dette. Elle n'aurait jamais dû être la vôtre."],
		["othmar", "Mille ans que j'attends que deux frères m'apprennent le courage. Partez. Vivez."],
		["narr", "Le Premier Roi prend la place de Kaël. Le Sceau se referme sur lui, et sur la Soif."],
		["kael", "Hé, grand frère. Tu te bats toujours aussi mal ?"],
		["toi", "Demain, je te laisse gagner. Une seconde fois."],
		["narr", "Et les deux frères rient ensemble, au lever du soleil."],
	]},
}


static func a_dialogue(acte: int, chapitre: int, moment: String) -> bool:
	return not (DIALOGUES.get("%d-%d" % [acte, chapitre], {}) as Dictionary).get(moment, []).is_empty()


static func lignes(acte: int, chapitre: int, moment: String) -> Array:
	return (DIALOGUES.get("%d-%d" % [acte, chapitre], {}) as Dictionary).get(moment, [])


## Déjà vu ? (le dialogue ne s'affiche automatiquement qu'une fois)
static func vu(acte: int, chapitre: int, moment: String) -> bool:
	return "%d-%d-%s" % [acte, chapitre, moment] in Sauvegarde.donnees.get("dialogues_vus", [])


static func marquer_vu(acte: int, chapitre: int, moment: String) -> void:
	if not Sauvegarde.donnees.get("dialogues_vus") is Array:
		Sauvegarde.donnees["dialogues_vus"] = []
	var cle := "%d-%d-%s" % [acte, chapitre, moment]
	if not cle in Sauvegarde.donnees["dialogues_vus"]:
		Sauvegarde.donnees["dialogues_vus"].append(cle)
		Sauvegarde.sauvegarder()


## Nom affiché d'un personnage ("toi" = prénom du joueur + Valcendre s'il est connecté).
static func nom(perso: String) -> String:
	if perso == "toi":
		return EnLigne.nom_complet() if EnLigne.est_connecte() else "Toi"
	return str(PERSONNAGES.get(perso, {}).get("nom", perso))
