class_name GuideDonjons
extends RefCounted
## GUIDE DES DONJONS (bouton « ? » de l'écran des Donjons) : expéditions, mécaniques des boss,
## et pour chaque Donjon les héros invocables qui contrent sa mécanique (ceux du joueur en vert).
## Tous les chiffres sont lus dans Donjons / Mecaniques : si l'équilibrage change, le guide suit.



static func ouvrir(parent: Node, donjon := "") -> void:
	var sections: Array = [["Pas à pas", _pas_a_pas()], ["Les mécaniques", _mecaniques()],
		["Composer son équipe", _equipe()]]
	var depart := 0
	for d in Donjons.ORDRE:
		if d == donjon:
			depart = sections.size()
		sections.append([str(Donjons.DONJONS[d]["nom"]), _donjon(d)])
	FenetreGuide.ouvrir(parent, "GUIDE DES DONJONS", Color("c8871e"), sections, depart)


## Exemples d'équipes (rôle + héros possibles, du plus accessible au plus rare).
const EXEMPLES := {
	"feu": ["Tank Eau à boucliers (Troll des Marais, Jeune Hydre, Titan des Abysses)",
		"Purificateur (Slime Gélatineux, Clerc Sacré, Axolotl des Sources)",
		"Un héros immunisé à la Brûlure (Orc Guerrier, Loup-Garou, Phénix Immortel)",
		"Dégâts Eau (Spectre Glacial, Banshee Pleureuse, Sirène Muette)", "Soigneur ou 2e purificateur (Nymphe, Sœur du Silence)"],
	"nature": ["Tank (Gardiens d'Ombre, Golem de Pierre)", "2 héros à Brûlure, idéalement Feu (Sanglier, Orc Guerrier, Démon de Flamme, Mage Gris)",
		"Un assassin à exécution (Dague Violette, Brute Noire)", "Sorts de zone pour les Racines (Mage Gris, Sorcier Sombre)", "Soigneur"],
	"eau": ["Tank", "2 héros à Poison, idéalement Nature (Rat Géant, Araignée Venimeuse, Elf Sylvestre, Reine Araignée)",
		"Coups multiples (Lance Dorée, Chimère Enragée, Lapin Pyromane)", "Le Brise-Carapace (DEF -25 %)", "Soigneur"],
	"tenebres": ["Tank immunisé à la Malédiction (Chevalier Blanc, Élu de la Lame, Chevalier Rouillé)",
		"2 purificateurs (Clerc Sacré, Slime, Exorciste Déchu, Sœur du Silence)", "Dégâts Sacré (Lance Dorée, Cheval Céleste)", "Dégâts au choix"],
	"sacre": ["Tank", "2 héros de contrôle : Silence, Étourdissement ou Gel (Sirène Muette, Sœur du Silence, Séraphin Déchu, Brute Noire, Spectre Glacial)",
		"Dégâts Ténèbres (Dague Violette, Sorcier Sombre, Dragon d'Ombre)", "Soigneur", "En mode manuel, garde le contrôle pour l'INCANTATION"],
	"neutre": ["Tank qui provoque avec Épines (Gardiens d'Ombre, Troll des Marais, Golem d'Obsidienne)", "Baisse d'ATK (Zombie Errant, Chevalier Rouillé, Princesse des Sceaux)",
		"Boucliers (Chevalier Blanc, Princesse des Sceaux)", "Gros dégâts pour finir vite", "Soigneur"],
	"savoir": ["Tank", "3 héros à sorts de zone (Mage Gris, Sorcier Sombre, Spectre Glacial, Sœur du Silence)",
		"Silence pour bloquer les résurrections (Sirène Muette, Sœur du Silence, Séraphin Déchu)", "Brûlure contre ses soins", "Soigneur"],
}


static func _pas_a_pas() -> String:
	var s := FenetreGuide.titre("Les Donjons, pas à pas")
	s += "Une [b]expédition[/b] enchaîne %d combats : [b]vague de monstres, mini-boss, vague, BOSS[/b].\n" % Donjons.VAGUES.size()
	s += FenetreGuide.couleur("Pas de soin entre les combats", FenetreGuide.C_ALERTE) + " : tes héros gardent les PV qui leur restent d'un combat à l'autre. Un héros K.O. reste K.O. jusqu'à la fin.\n\n"
	s += FenetreGuide.sous_titre("Les niveaux")
	s += "Chaque Donjon a %d niveaux. Gagne un niveau pour ouvrir le suivant.\n" % Donjons.NIVEAUX
	s += "Stamina payée au départ : %s.\n" % ", ".join(Donjons.COUT_STAMINA.map(func(x): return str(x)))
	s += "Les niveaux 8 à 10 sont la [b]fin de jeu[/b] : ils sont pensés pour des héros Éveillés (niveau 32, 40 puis 50).\n"
	s += FenetreGuide.sous_titre("Le butin")
	s += FenetreGuide.puce("Chaque Donjon d'élément donne ses [b]ressources[/b] (Gouttes, Larmes, Cœurs) : elles servent à faire [b]évoluer[/b] les unités de cet élément (Autel d'Évolution).")
	s += FenetreGuide.puce("Le Puits de Sang donne le Sang, demandé par toutes les évolutions.")
	s += FenetreGuide.puce("La Bibliothèque Interdite donne les [b]Pages de Grimoire[/b] et les [b]Grimoires Interdits[/b] : ils font monter le niveau des sorts (fiche du héros).")
	s += FenetreGuide.sous_titre("Avant de partir")
	s += FenetreGuide.puce("Regarde la section [b]MÉCANIQUES[/b] de l'écran : elle dit ce que fait le boss et quels héros de ta collection le contrent.")
	s += FenetreGuide.puce("« Puissance conseillée » : la force d'équipe pour réussir environ 7 fois sur 10 avec une équipe adaptée.")
	return s


static func _mecaniques() -> String:
	var s := FenetreGuide.titre("Les mécaniques des boss")
	s += "À partir du [b]niveau %d[/b], chaque mini-boss et chaque boss a une [b]mécanique[/b] : une règle spéciale qu'il faut contrer, sinon le combat devient presque impossible.\n" % Mecaniques.NIVEAU_DEBUT
	s += "À partir du [b]niveau %d[/b], la mécanique est [b]renforcée[/b].\n\n" % Mecaniques.NIVEAU_RENFORCE
	s += FenetreGuide.puce("Avec sa mécanique, le [b]boss arrive avec 2 gardes[/b] (le monstre typique du Donjon).")
	s += FenetreGuide.puce("Il est [b]beaucoup plus endurant[/b] mais frappe moins fort : le danger vient de la mécanique, pas des coups.")
	s += FenetreGuide.puce("Le [b]mini-boss annonce le boss[/b] : sa petite mécanique ressemble à celle du boss. S'il te pose problème, change ton équipe avant le boss !")
	s += FenetreGuide.puce("Les nouveaux monstres des Donjons ont aussi une petite mécanique (soins, carapace, marque...).")
	s += FenetreGuide.sous_titre("En combat")
	s += "Sous chaque unité, une ligne orange montre l'état de la mécanique : « Carapace 12/18 », « INCANTATION », « Marqué : 1 », « ATK +30 % »...\n"
	s += "Le nom de la mécanique est rappelé sous le boss et le mini-boss.\n"
	s += FenetreGuide.sous_titre("Les contres")
	s += FenetreGuide.tableau(["Contre", "Ce que ça fait", "Utile contre"], [
		["Purification", "retire les afflictions d'un allié (brûlures, marques, chaînes...)", "Fournaise, Marque, Chaînes"],
		["Brûlure", "dégâts chaque tour et [b]soins reçus divisés par 2[/b]", "Sève Éternelle, Remède, Phylactère"],
		["Poison", "% des PV max perdus chaque tour : ignore les carapaces", "Carapace des Abysses"],
		["Coups multiples / zone", "beaucoup de coups d'un coup : brise les carapaces, tue les gardes ensemble", "Carapace, Phylactère, Lien d'Âme"],
		["Contrôle", "étourdir, geler ou réduire au silence : [b]interrompt une incantation[/b]", "Jugement, Prière"],
		["Provocation, Épines", "attire les coups et blesse celui qui frappe", "Frénésie, Faim"],
		["Immunités", "Brûlure, Malédiction... : la mécanique ne prend pas", "Fournaise, Marque"],
	])
	s += FenetreGuide.sous_titre("En combat manuel")
	s += "Le mode manuel est un vrai avantage contre les incantations : garde ton étourdissement ou ton silence pour le moment où le boss commence à incanter.\n"
	return s


static func _equipe() -> String:
	var s := FenetreGuide.titre("Composer son équipe")
	s += "Une bonne équipe de Donjon, c'est [b]2 héros qui contrent la mécanique[/b] + des héros solides pour le reste.\n\n"
	s += FenetreGuide.sous_titre("1. L'élément")
	var lignes: Array = []
	for el in CombatMoteur.FORT_CONTRE:
		lignes.append([UnitesData.ELEMENTS[el], UnitesData.ELEMENTS[CombatMoteur.FORT_CONTRE[el]]])
	s += FenetreGuide.tableau(["Élément", "est fort contre"], lignes)
	s += "Fort contre : +%d %% de dégâts ; faible : -%d %%. Le Puits de Sang est neutre.\n" % [int(CombatMoteur.BONUS_ELEMENT * 100), int(CombatMoteur.MALUS_ELEMENT * 100)]
	s += FenetreGuide.sous_titre("2. Les rôles")
	s += FenetreGuide.puce("[b]Avant (places 1-2)[/b] : Tank, Guerrier, Assassin. Un tank qui provoque protège tout le monde.")
	s += FenetreGuide.puce("[b]Arrière (places 3-5)[/b] : Mage, Tireur, Soutien. Un soutien qui soigne ou purifie est presque toujours utile.")
	s += FenetreGuide.sous_titre("3. La mécanique")
	s += "Ouvre la page du Donjon dans ce guide : elle liste [b]tous les héros invocables[/b] qui contrent son boss. " + FenetreGuide.couleur("En vert", FenetreGuide.C_BON) + " : ceux que tu possèdes déjà.\n"
	s += FenetreGuide.sous_titre("4. L'endurance")
	s += "4 combats sans soin : un soigneur et un tank tiennent l'expédition jusqu'au boss. Les niveaux de sorts (Bibliothèque Interdite) font aussi une grosse différence.\n"
	return s


## Page d'un Donjon : boss, mini-boss, monstre, et les héros invocables qui contrent.
static func _donjon(d: String) -> String:
	var infos: Dictionary = Donjons.DONJONS[d]
	var ub := UnitesData.get_unite(infos["boss"])
	var element := str(ub.get("element", ""))
	var s := FenetreGuide.titre(str(infos["nom"]))
	s += FenetreGuide.couleur(str(infos["sous_titre"]), FenetreGuide.C_DOUX) + "\n"
	var fort := ""
	for el in CombatMoteur.FORT_CONTRE:
		if CombatMoteur.FORT_CONTRE[el] == element:
			fort = el
	s += "Boss : [b]%s[/b] (%s)" % [ub["nom"], UnitesData.ELEMENTS.get(element, element)]
	if fort != "":
		s += "  ·  élément fort contre lui : " + FenetreGuide.couleur(UnitesData.ELEMENTS[fort], FenetreGuide.C_BON)
	s += "\n"
	for paire in [["BOSS", Mecaniques.boss(d), infos["boss"]], ["MINI-BOSS", Mecaniques.mini(d), infos["mini_boss"]],
			["MONSTRE DU DONJON", str(UnitesData.get_unite(Mecaniques.garde(d)).get("meca", "")), Mecaniques.garde(d)]]:
		var inf := Mecaniques.infos(str(paire[1]))
		if inf.is_empty():
			continue
		s += FenetreGuide.sous_titre("%s — %s : %s" % [paire[0], UnitesData.get_unite(paire[2])["nom"], inf["nom"]])
		s += str(inf["texte"]) + "\n"
		s += FenetreGuide.couleur("Conseil : " + str(inf["conseil"]), FenetreGuide.C_BON) + "\n"
	# Exemple d'équipe
	s += FenetreGuide.sous_titre("Exemple d'équipe")
	for l in EXEMPLES.get(d, []):
		s += FenetreGuide.puce(l)
	# Héros qui contrent le boss
	s += FenetreGuide.sous_titre("Tous les héros qui contrent le boss")
	var possedes := {}
	for h in Sauvegarde.liste_heros():
		possedes[UnitesData.lignee(str(h["id"]))] = true
	for c in Mecaniques.infos(Mecaniques.boss(d)).get("contres", []):
		var noms: Array = []
		for id in UnitesData.liste_invocables():
			if Mecaniques.tags(id).has(c):
				var u := UnitesData.get_unite(id)
				var n := "%s (%s)" % [u["nom"], "Légende" if u.get("legende", false) else u["rarete"]]
				noms.append(FenetreGuide.couleur(n, FenetreGuide.C_BON) if possedes.has(id) else n)
		if noms.is_empty():
			continue
		s += "[b]%s[/b] : %s\n" % [Mecaniques.NOMS_CONTRES.get(c, c), ", ".join(noms)]
	s += "\n" + FenetreGuide.couleur("En vert : les héros que tu possèdes. Certains contres ne s'obtiennent qu'avec les sorts des niveaux 10, 20 ou 30.", FenetreGuide.C_DOUX) + "\n"
	return s
