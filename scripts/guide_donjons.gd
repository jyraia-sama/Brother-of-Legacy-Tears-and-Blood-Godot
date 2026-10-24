class_name GuideDonjons
extends RefCounted
## GUIDE DES DONJONS (bouton « ? » de l'écran des Donjons) : expéditions, mécaniques des boss,
## et pour chaque Donjon les héros invocables qui contrent sa mécanique (ceux du joueur en vert).
## Tous les chiffres sont lus dans Donjons / Mecaniques : si l'équilibrage change, le guide suit.



static func ouvrir(parent: Node, donjon := "") -> void:
	var sections: Array = [[UiCommun.t("Pas à pas"), _pas_a_pas()], ["Les mécaniques", _mecaniques()],
		[UiCommun.t("Composer son équipe"), _equipe()]]
	var depart := 0
	for d in Donjons.ORDRE:
		if d == donjon:
			depart = sections.size()
		sections.append([str(UiCommun.t(str(Donjons.DONJONS[d]["nom"]))), _donjon(d)])
	FenetreGuide.ouvrir(parent, UiCommun.t("GUIDE DES DONJONS"), Color("c8871e"), sections, depart)


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
	var s := FenetreGuide.titre(UiCommun.t("Les Donjons, pas à pas"))
	s += UiCommun.t("Une [b]expédition[/b] enchaîne %d combats : [b]vague de monstres, mini-boss, vague, BOSS[/b].\n") % Donjons.VAGUES.size()
	s += FenetreGuide.couleur(UiCommun.t("Pas de soin entre les combats"), FenetreGuide.C_ALERTE) + UiCommun.t(" : tes héros gardent les PV qui leur restent d'un combat à l'autre. Un héros K.O. reste K.O. jusqu'à la fin.\n\n")
	s += FenetreGuide.sous_titre(UiCommun.t("Les niveaux"))
	s += UiCommun.t("Chaque Donjon a %d niveaux. Gagne un niveau pour ouvrir le suivant.\n") % Donjons.NIVEAUX
	s += UiCommun.t("Stamina payée au départ : %s.\n") % ", ".join(Donjons.COUT_STAMINA.map(func(x): return str(x)))
	s += UiCommun.t("Les niveaux 8 à 10 sont la [b]fin de jeu[/b] : ils sont pensés pour des héros Éveillés (niveau 32, 40 puis 50).\n")
	s += FenetreGuide.sous_titre(UiCommun.t("Le butin"))
	s += FenetreGuide.puce(UiCommun.t("Chaque Donjon d'élément donne ses [b]ressources[/b] (Gouttes, Larmes, Cœurs) : elles servent à faire [b]évoluer[/b] les unités de cet élément (Autel d'Évolution)."))
	s += FenetreGuide.puce(UiCommun.t("Le Puits de Sang donne le Sang, demandé par toutes les évolutions."))
	s += FenetreGuide.puce(UiCommun.t("La Bibliothèque Interdite donne les [b]Pages de Grimoire[/b] et les [b]Grimoires Interdits[/b] : ils font monter le niveau des sorts (fiche du héros)."))
	s += FenetreGuide.sous_titre(UiCommun.t("Avant de partir"))
	s += FenetreGuide.puce(UiCommun.t("Regarde la section [b]MÉCANIQUES[/b] de l'écran : elle dit ce que fait le boss et quels héros de ta collection le contrent."))
	s += FenetreGuide.puce(UiCommun.t("« Puissance conseillée » : la force d'équipe pour réussir environ 7 fois sur 10 avec une équipe adaptée."))
	return s


static func _mecaniques() -> String:
	var s := FenetreGuide.titre(UiCommun.t("Les mécaniques des boss"))
	s += UiCommun.t("À partir du [b]niveau %d[/b], chaque mini-boss et chaque boss a une [b]mécanique[/b] : une règle spéciale qu'il faut contrer, sinon le combat devient presque impossible.\n") % Mecaniques.NIVEAU_DEBUT
	s += UiCommun.t("À partir du [b]niveau %d[/b], la mécanique est [b]renforcée[/b].\n\n") % Mecaniques.NIVEAU_RENFORCE
	s += FenetreGuide.puce(UiCommun.t("Avec sa mécanique, le [b]boss arrive avec 2 gardes[/b] (le monstre typique du Donjon)."))
	s += FenetreGuide.puce(UiCommun.t("Il est [b]beaucoup plus endurant[/b] mais frappe moins fort : le danger vient de la mécanique, pas des coups."))
	s += FenetreGuide.puce(UiCommun.t("Le [b]mini-boss annonce le boss[/b] : sa petite mécanique ressemble à celle du boss. S'il te pose problème, change ton équipe avant le boss !"))
	s += FenetreGuide.puce(UiCommun.t("Les nouveaux monstres des Donjons ont aussi une petite mécanique (soins, carapace, marque...)."))
	s += FenetreGuide.sous_titre(UiCommun.t("En combat"))
	s += UiCommun.t("Sous chaque unité, une ligne orange montre l'état de la mécanique : « Carapace 12/18 », « INCANTATION », « Marqué : 1 », « ATK +30 % »...\n")
	s += UiCommun.t("Le nom de la mécanique est rappelé sous le boss et le mini-boss.\n")
	s += FenetreGuide.sous_titre(UiCommun.t("Les contres"))
	s += FenetreGuide.tableau(["Contre", UiCommun.t("Ce que ça fait"), UiCommun.t("Utile contre")], [
		["Purification", UiCommun.t("retire les afflictions d'un allié (brûlures, marques, chaînes...)"), UiCommun.t("Fournaise, Marque, Chaînes")],
		[UiCommun.t("Brûlure"), UiCommun.t("dégâts chaque tour et [b]soins reçus divisés par 2[/b]"), UiCommun.t("Sève Éternelle, Remède, Phylactère")],
		["Poison", UiCommun.t("% des PV max perdus chaque tour : ignore les carapaces"), UiCommun.t("Carapace des Abysses")],
		["Coups multiples / zone", UiCommun.t("beaucoup de coups d'un coup : brise les carapaces, tue les gardes ensemble"), UiCommun.t("Carapace, Phylactère, Lien d'Âme")],
		[UiCommun.t("Contrôle"), UiCommun.t("étourdir, geler ou réduire au silence : [b]interrompt une incantation[/b]"), UiCommun.t("Jugement, Prière")],
		["Provocation, Épines", UiCommun.t("attire les coups et blesse celui qui frappe"), UiCommun.t("Frénésie, Faim")],
		["Immunités", UiCommun.t("Brûlure, Malédiction... : la mécanique ne prend pas"), UiCommun.t("Fournaise, Marque")],
	])
	s += FenetreGuide.sous_titre(UiCommun.t("En combat manuel"))
	s += UiCommun.t("Le mode manuel est un vrai avantage contre les incantations : garde ton étourdissement ou ton silence pour le moment où le boss commence à incanter.\n")
	return s


static func _equipe() -> String:
	var s := FenetreGuide.titre(UiCommun.t("Composer son équipe"))
	s += UiCommun.t("Une bonne équipe de Donjon, c'est [b]2 héros qui contrent la mécanique[/b] + des héros solides pour le reste.\n\n")
	s += FenetreGuide.sous_titre(UiCommun.t("1. L'élément"))
	var lignes: Array = []
	for el in CombatMoteur.FORT_CONTRE:
		lignes.append([UnitesData.nom_element(el), UnitesData.nom_element(CombatMoteur.FORT_CONTRE[el])])
	s += FenetreGuide.tableau([UiCommun.t("Élément"), UiCommun.t("est fort contre")], lignes)
	s += UiCommun.t("Fort contre : +%d %% de dégâts ; faible : -%d %%. Le Puits de Sang est neutre.\n") % [int(CombatMoteur.BONUS_ELEMENT * 100), int(CombatMoteur.MALUS_ELEMENT * 100)]
	s += FenetreGuide.sous_titre(UiCommun.t("2. Les rôles"))
	s += FenetreGuide.puce(UiCommun.t("[b]Avant (places 1-2)[/b] : Tank, Guerrier, Assassin. Un tank qui provoque protège tout le monde."))
	s += FenetreGuide.puce(UiCommun.t("[b]Arrière (places 3-5)[/b] : Mage, Tireur, Soutien. Un soutien qui soigne ou purifie est presque toujours utile."))
	s += FenetreGuide.sous_titre(UiCommun.t("3. La mécanique"))
	s += UiCommun.t("Ouvre la page du Donjon dans ce guide : elle liste [b]tous les héros invocables[/b] qui contrent son boss. ") + FenetreGuide.couleur(UiCommun.t("En vert"), FenetreGuide.C_BON) + UiCommun.t(" : ceux que tu possèdes déjà.\n")
	s += FenetreGuide.sous_titre(UiCommun.t("4. L'endurance"))
	s += UiCommun.t("4 combats sans soin : un soigneur et un tank tiennent l'expédition jusqu'au boss. Les niveaux de sorts (Bibliothèque Interdite) font aussi une grosse différence.\n")
	return s


## Page d'un Donjon : boss, mini-boss, monstre, et les héros invocables qui contrent.
static func _donjon(d: String) -> String:
	var infos: Dictionary = Donjons.DONJONS[d]
	var ub := UnitesData.get_unite(infos["boss"])
	var element := str(ub.get("element", ""))
	var s := FenetreGuide.titre(str(UiCommun.t(str(infos["nom"]))))
	s += FenetreGuide.couleur(str(UiCommun.t(str(infos["sous_titre"]))), FenetreGuide.C_DOUX) + "\n"
	var fort := ""
	for el in CombatMoteur.FORT_CONTRE:
		if CombatMoteur.FORT_CONTRE[el] == element:
			fort = el
	s += UiCommun.t("Boss : [b]%s[/b] (%s)") % [UiCommun.t(str(ub["nom"])), UnitesData.nom_element(element)]
	if fort != "":
		s += UiCommun.t("  ·  élément fort contre lui : ") + FenetreGuide.couleur(UnitesData.nom_element(fort), FenetreGuide.C_BON)
	s += "\n"
	for paire in [["BOSS", Mecaniques.boss(d), infos["boss"]], ["MINI-BOSS", Mecaniques.mini(d), infos["mini_boss"]],
			["MONSTRE DU DONJON", str(UnitesData.get_unite(Mecaniques.garde(d)).get("meca", "")), Mecaniques.garde(d)]]:
		var inf := Mecaniques.infos(str(paire[1]))
		if inf.is_empty():
			continue
		s += FenetreGuide.sous_titre("%s — %s : %s" % [paire[0], UiCommun.t(str(UnitesData.get_unite(paire[2])["nom"])), UiCommun.t(str(inf["nom"]))])
		s += str(inf["texte"]) + "\n"
		s += FenetreGuide.couleur(UiCommun.t("Conseil : ") + str(UiCommun.t(str(inf["conseil"]))), FenetreGuide.C_BON) + "\n"
	# Exemple d'équipe
	s += FenetreGuide.sous_titre(UiCommun.t("Exemple d'équipe"))
	for l in EXEMPLES.get(d, []):
		s += FenetreGuide.puce(l)
	# Héros qui contrent le boss
	s += FenetreGuide.sous_titre(UiCommun.t("Tous les héros qui contrent le boss"))
	var possedes := {}
	for h in Sauvegarde.liste_heros():
		possedes[UnitesData.lignee(str(h["id"]))] = true
	for c in Mecaniques.infos(Mecaniques.boss(d)).get("contres", []):
		var noms: Array = []
		for id in UnitesData.liste_invocables():
			if Mecaniques.tags(id).has(c):
				var u := UnitesData.get_unite(id)
				var n := "%s (%s)" % [UiCommun.t(str(u["nom"])), UiCommun.t("Légende") if u.get("legende", false) else u["rarete"]]
				noms.append(FenetreGuide.couleur(n, FenetreGuide.C_BON) if possedes.has(id) else n)
		if noms.is_empty():
			continue
		s += "[b]%s[/b] : %s\n" % [UiCommun.t(str(Mecaniques.NOMS_CONTRES.get(c, c))), ", ".join(noms)]
	s += "\n" + FenetreGuide.couleur(UiCommun.t("En vert : les héros que tu possèdes. Certains contres ne s'obtiennent qu'avec les sorts des niveaux 10, 20 ou 30."), FenetreGuide.C_DOUX) + "\n"
	return s
