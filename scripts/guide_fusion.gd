class_name GuideFusion
extends RefCounted
## GUIDE DE L'AUTEL DE FUSION (bouton « ? » de l'écran de Fusion) : Éveil, niveau maximum,
## retour au niveau 1 et XP de mémoire, Absorption, Pierres d'Éveil, liens avec l'Évolution
## et les niveaux de sorts. Les chiffres sont lus dans Fusion / SortsNiveaux / Evolution.



static func ouvrir(parent: Node, section := 0) -> void:
	FenetreGuide.ouvrir(parent, "GUIDE DE L'AUTEL DE FUSION", Color("c8871e"), [
		["Pas à pas", _pas_a_pas()],
		["Les étoiles", _etoiles()],
		["Retour au niveau 1", _memoire()],
		["L'Absorption (XP)", _absorption()],
		["Doublons et Pierres", _pierres()],
		["Évolution et sorts", _evolution()],
		["Conseils", _conseils()],
	], section)


static func _pas_a_pas() -> String:
	var s := FenetreGuide.titre("L'Autel de Fusion, pas à pas")
	s += "L'Autel a deux usages :\n\n"
	s += FenetreGuide.puce("[b]ÉVEIL (étoiles)[/b] : sacrifie des [b]doublons[/b] du même héros (ou des Pierres d'Éveil) pour lui faire gagner une étoile, de ★1 à ★6. Chaque étoile augmente ses stats, son [b]niveau maximum[/b] et le niveau max de ses sorts.")
	s += FenetreGuide.puce("[b]ABSORPTION (XP)[/b] : sacrifie n'importe quelles unités pour donner de l'XP à un héros.")
	s += FenetreGuide.sous_titre("Comment faire")
	s += "1. Clique sur la carte du [b]héros principal[/b] (celui qui reçoit).\n"
	s += "2. Choisis l'onglet Éveil ou Absorption.\n"
	s += "3. Sélectionne les unités à sacrifier (« Sélection auto » le fait pour toi).\n"
	s += "4. Vérifie l'aperçu (conditions en vert, stats avant/après), puis « Fusionner ».\n"
	s += FenetreGuide.sous_titre("Ce qui ne peut jamais être sacrifié")
	s += FenetreGuide.puce("une unité de l'équipe, ton héros de départ, une unité verrouillée, une unité partie en mission.")
	s += FenetreGuide.puce("Les Échos Sanguins portés par un sacrifice retournent dans ton inventaire : rien n'est perdu.")
	return s


static func _etoiles() -> String:
	var s := FenetreGuide.titre("Les étoiles")
	s += "Chaque étoile donne +%d %% de PV, ATK, DEF, AGI et MAG ; l'Éveil ★%d donne +%d %% de plus.\n\n" % [
		int(Fusion.BONUS_PAR_ETOILE * 100), Fusion.ETOILES_MAX, int(Fusion.BONUS_EVEIL * 100)]
	var lignes: Array = []
	for e in range(1, Fusion.ETOILES_MAX + 1):
		var doublons := "-" if e == 1 else str(int(Fusion.DOUBLONS_REQUIS.get(e - 1, 0)))
		lignes.append([Fusion.texte_etoiles(e, false), "+%d %%" % int(round((Fusion.multiplicateur(e) - 1.0) * 100)),
			str(Fusion.niveau_max_etoiles(e)), str(SortsNiveaux.max_pour_etoiles(e)), doublons])
	s += FenetreGuide.tableau(["Étoiles", "Bonus de stats", "Niveau max", "Sorts max", "Doublons pour l'obtenir"], lignes)
	s += FenetreGuide.sous_titre("Le coût en or")
	var cout: Array = []
	for r in ["N", "R", "SR", "SSR", "UR", "LEG"]:
		cout.append("%s %d" % ["Légende" if r == "LEG" else r, int(Fusion.OR_EVEIL[r])])
	s += "Prix de base selon la rareté × les étoiles actuelles : %s.\n" % ", ".join(cout)
	s += "Exemple : passer un SSR de ★3 à ★4 coûte %d × 3 = %d or.\n" % [int(Fusion.OR_EVEIL["SSR"]), int(Fusion.OR_EVEIL["SSR"]) * 3]
	s += FenetreGuide.sous_titre("La condition")
	s += "Pour gagner une étoile, le héros doit être à son [b]niveau maximum[/b] (30 à ★1, 34 à ★2...).\n"
	return s


static func _memoire() -> String:
	var s := FenetreGuide.titre("Retour au niveau 1 et XP de mémoire")
	s += FenetreGuide.couleur("À chaque étoile gagnée, le héros REPART AU NIVEAU 1.", FenetreGuide.C_ALERTE) + "\n\n"
	s += "Ce n'est pas une punition : avec sa nouvelle étoile, il pourra monter [b]plus haut qu'avant[/b] et sera plus fort une fois remonté.\n"
	s += FenetreGuide.sous_titre("Ce qu'il garde")
	s += FenetreGuide.puce("ses [b]étoiles[/b] (et leur bonus de stats) ;")
	s += FenetreGuide.puce("tous les [b]sorts déjà appris[/b], même ceux des niveaux 10, 20 et 30 ;")
	s += FenetreGuide.puce("les [b]niveaux de ses sorts[/b] et ses [b]Échos Sanguins[/b].")
	s += FenetreGuide.sous_titre("L'XP de mémoire")
	s += "Tant qu'il n'a pas retrouvé le plus haut niveau qu'il avait atteint, il gagne [b]+%d %% d'XP[/b]. La fiche du héros (Deck) l'affiche en orange.\n" % int(Fusion.BONUS_MEMOIRE * 100)
	s += FenetreGuide.sous_titre("Bon à savoir")
	s += FenetreGuide.puce("Juste après un Éveil, ton héros est plus faible : remonte-le avec des combats faciles, des Tomes (Reliquaire) ou l'Absorption avant de l'emmener en Donjon ou en Arène.")
	s += FenetreGuide.puce("Éveille un héros à la fois pour garder une équipe solide.")
	return s


static func _absorption() -> String:
	var s := FenetreGuide.titre("L'Absorption (XP)")
	s += "Chaque unité sacrifiée donne de l'XP au héros principal ; tu payes %s or par point d'XP.\n" % str(Fusion.OR_PAR_XP)
	s += "%d sacrifices maximum à la fois.\n\n" % Fusion.MAX_SACRIFICES
	var lignes: Array = []
	for r in ["N", "R", "SR", "SSR", "UR", "LEG"]:
		lignes.append(["Légende" if r == "LEG" else r, str(int(Fusion.XP_SACRIFICE[r]))])
	s += FenetreGuide.tableau(["Rareté du sacrifice", "XP (niveau 1, ★1)"], lignes)
	s += FenetreGuide.sous_titre("Ce qui augmente l'XP")
	s += FenetreGuide.puce("+10 % par niveau du sacrifice ;")
	s += FenetreGuide.puce("+25 % par étoile du sacrifice au-dessus de ★1 ;")
	s += FenetreGuide.puce("×%s si le sacrifice est [b]le même héros[/b] que le principal ;" % str(Fusion.BONUS_MEME_UNITE))
	s += FenetreGuide.puce("+%d %% d'XP de mémoire si le héros remonte après un Éveil." % int(Fusion.BONUS_MEMOIRE * 100))
	s += FenetreGuide.sous_titre("Attention")
	s += "Au niveau maximum, l'XP en trop est [b]perdue[/b] : l'aperçu te prévient. Au niveau max, pense plutôt à l'Éveil.\n"
	return s


static func _pierres() -> String:
	var s := FenetreGuide.titre("Doublons et Pierres d'Éveil")
	s += "Un [b]doublon[/b], c'est un autre exemplaire du même héros (ou de son évolution) : on l'obtient à l'Autel d'Invocation.\n\n"
	s += "Une [b]Pierre d'Éveil[/b] remplace un doublon. On en gagne :\n"
	s += FenetreGuide.puce("en Boss de Monde (selon les dégâts infligés) ;")
	s += FenetreGuide.puce("dans les quêtes (récompenses de la semaine) ;")
	s += FenetreGuide.puce("à la Boutique (1 par semaine) et au marché de la Marche Maudite.")
	s += "\nSur l'écran d'Éveil, les boutons + et - choisissent combien de Pierres utiliser.\n"
	s += FenetreGuide.sous_titre("Conseil")
	s += "Garde les Pierres pour les héros rares (SSR, UR, Légende) : leurs doublons sont difficiles à obtenir.\n"
	return s


static func _evolution() -> String:
	var s := FenetreGuide.titre("Évolution et niveaux de sorts")
	s += FenetreGuide.sous_titre("L'Évolution (Autel d'Évolution)")
	s += "Un héros au [b]niveau %d[/b] peut évoluer avec les ressources des Donjons. Il [b]garde son niveau[/b], ses étoiles et ses Échos, change d'apparence, gagne des stats et un sort renforcé.\n" % Evolution.NIVEAU_REQUIS
	s += "L'Évolution [b]n'augmente pas le niveau maximum[/b] : seules les étoiles le font. Certaines évolutions ont un sort bonus au niveau 40 : il faut donc ★4 (niveau max 42) pour l'apprendre.\n"
	s += FenetreGuide.sous_titre("Les niveaux de sorts")
	s += "Chaque sort monte du niveau 1 au niveau 10 (fiche du héros, bouton « Améliorer ») avec les Pages de Grimoire de la Bibliothèque Interdite.\n"
	s += "Le niveau max des sorts dépend aussi des étoiles : 3 + étoiles, et 10 à ★6 Éveillé.\n"
	s += FenetreGuide.sous_titre("L'ordre conseillé")
	s += "1. Monte ton héros au niveau 30.\n2. Fais-le évoluer (il garde son niveau).\n3. Éveille-le (★2), remonte-le avec l'XP de mémoire, et recommence.\n4. Monte ses sorts au fur et à mesure que les étoiles le permettent.\n"
	return s


static func _conseils() -> String:
	var s := FenetreGuide.titre("Conseils")
	s += FenetreGuide.puce("Ne sacrifie pas un héros rare pour de l'XP : un doublon d'un SSR vaut bien plus en Éveil.")
	s += FenetreGuide.puce("Les unités N et R en trop font d'excellentes Absorptions ; un doublon du même héros donne ×%s d'XP." % str(Fusion.BONUS_MEME_UNITE))
	s += FenetreGuide.puce("Verrouille (Deck) les héros que tu veux garder : ils ne pourront jamais être sacrifiés par erreur.")
	s += FenetreGuide.puce("Avant un Éveil, vérifie que ton équipe tient sans ce héros pendant qu'il remonte.")
	s += FenetreGuide.puce("Les niveaux 8 à 10 des Donjons et les étages 81 à 100 des Tours sont pensés pour des héros Éveillés : c'est là que les étoiles comptent.")
	return s
