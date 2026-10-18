class_name GuideSorts
extends RefCounted
## GUIDE DES NIVEAUX DE SORTS (bouton « ? » de la section SORTS de la fiche d'un héros, Deck et
## Mon héros ; ouvert tout seul la première fois qu'on appuie sur « ✦ Améliorer les sorts »).
## Les chiffres sont lus dans SortsNiveaux, Fusion et Donjons : le guide suit l'équilibrage.


static func ouvrir(parent: Node, section := 0) -> void:
	FenetreGuide.ouvrir(parent, "GUIDE DES SORTS", Color("c89a4a"), [
		["Pas à pas", _pas_a_pas()],
		["Apprendre un sort", _apprendre()],
		["Ce que donne un niveau", _gains()],
		["Le coût", _cout()],
		["Niveau max et étoiles", _etoiles()],
		["Où trouver les ressources", _ressources()],
		["Conseils", _conseils()],
	], section)


static func _pas_a_pas() -> String:
	var s := FenetreGuide.titre("Les sorts, pas à pas")
	s += "Chaque héros a jusqu'à 4 sorts (actifs ou passifs). Chaque sort a son [b]propre niveau[/b], de 1 à %d.\n\n" % SortsNiveaux.NIVEAU_MAX
	s += "1. Ouvre le [b]Deck[/b] et touche un héros : sa fiche s'affiche à droite.\n"
	s += "2. Touche [b]« ✦ Améliorer les sorts »[/b] : la fiche descend jusqu'à la section SORTS.\n"
	s += "3. Sous chaque sort, tu vois son niveau, le coût du niveau suivant et, s'il est bloqué, [b]la raison[/b] en orange.\n"
	s += "4. Touche [b]« Améliorer »[/b] : les ressources sont dépensées et le sort monte d'un niveau.\n"
	s += FenetreGuide.sous_titre("Les 3 choses qui peuvent bloquer un sort")
	s += FenetreGuide.puce("[b]Pas encore appris[/b] : le héros doit atteindre le niveau où il apprend ce sort.")
	s += FenetreGuide.puce("[b]Étoile requise[/b] : le sort a atteint le niveau maximum permis par les étoiles du héros.")
	s += FenetreGuide.puce("[b]Ressources manquantes[/b] : pas assez de Pages de Grimoire, de Grimoires Interdits ou d'or.")
	s += "\nChaque sort se monte [b]séparément[/b] : améliorer le premier sort ne bloque pas les autres.\n"
	return s


static func _apprendre() -> String:
	var s := FenetreGuide.titre("Apprendre un sort")
	s += "Un héros [b]apprend ses sorts en montant de niveau[/b] (niveau du héros, pas du sort) :\n\n"
	s += FenetreGuide.tableau(["Sort", "Appris au niveau du héros (en général)"], [
		["1er sort", "1"], ["2e sort", "10"], ["3e sort", "20"], ["4e sort", "30"]])
	s += "Certaines évolutions ont un sort bonus au niveau 40 (il faut alors ★4 pour atteindre ce niveau). La fiche du héros indique, pour chaque sort pas encore appris, le niveau exact où il l'apprendra.\n"
	s += FenetreGuide.sous_titre("Et après un Éveil ?")
	s += "Quand un héros gagne une étoile, il repart au niveau 1 [b]mais garde tous les sorts déjà appris[/b], et leurs niveaux.\n"
	s += FenetreGuide.sous_titre("Et après une Évolution ?")
	s += "Le sort peut changer de nom ou être renforcé : il [b]garde son niveau[/b].\n"
	return s


static func _gains() -> String:
	var s := FenetreGuide.titre("Ce que donne un niveau de sort")
	s += "Chaque niveau donne [b]+%d %%[/b] à toutes les valeurs du sort : dégâts, soins, boucliers, bonus de stats, chances d'altération...\n\n" % int(SortsNiveaux.BONUS_PAR_NIVEAU * 100)
	var lignes: Array = []
	for n in [1, 2, 4, 6, 8, 10]:
		lignes.append(["Niveau %d" % n, "+%d %%" % int(round((SortsNiveaux.multiplicateur(n) - 1.0) * 100)),
			"%d %%" % int(round(200 * SortsNiveaux.multiplicateur(n)))])
	s += FenetreGuide.tableau(["Niveau du sort", "Bonus", "Un sort à 200 % devient"], lignes)
	s += FenetreGuide.sous_titre("La recharge des sorts actifs")
	s += "En montant, un sort actif revient [b]plus souvent[/b] (1 tour de recharge en moins) :\n"
	s += FenetreGuide.puce("recharge de 2 tours : -1 tour au niveau 10 ;")
	s += FenetreGuide.puce("recharge de 3 tours : -1 tour au niveau 7 ;")
	s += FenetreGuide.puce("recharge de 4 tours ou plus : -1 tour au niveau 5, et encore -1 au niveau 10.")
	s += "En combat automatique, la chance de lancer le sort augmente d'autant.\n"
	s += FenetreGuide.sous_titre("Arène et Guerre des Bannières")
	s += "Pour rester équitable entre joueurs, les sorts y comptent au plus pour le [b]niveau %d[/b].\n" % SortsNiveaux.PLAFOND_JCJ
	return s


static func _cout() -> String:
	var s := FenetreGuide.titre("Le coût")
	s += "Chaque niveau coûte des [b]Pages de Grimoire[/b], de l'[b]or[/b], et à partir du niveau 3 → 4 des [b]Grimoires Interdits[/b].\n\n"
	var lignes: Array = []
	var total_p := 0
	var total_g := 0
	var total_o := 0
	for n in range(1, SortsNiveaux.NIVEAU_MAX):
		var c := SortsNiveaux.cout(n)
		var p := int(c.get(SortsNiveaux.PAGE, 0))
		var g := int(c.get(SortsNiveaux.GRIMOIRE, 0))
		var o := SortsNiveaux.cout_or(n)
		total_p += p
		total_g += g
		total_o += o
		lignes.append(["%d → %d" % [n, n + 1], str(p), str(g) if g > 0 else "-", "%d" % o])
	lignes.append(["[b]Total 1 → 10[/b]", "[b]%d[/b]" % total_p, "[b]%d[/b]" % total_g, "[b]%d[/b]" % total_o])
	s += FenetreGuide.tableau(["Niveau", "Pages de Grimoire", "Grimoires Interdits", "Or"], lignes)
	s += FenetreGuide.sous_titre("Deux ressources à gérer")
	s += "Les [b]Pages[/b] servent à chaque niveau ; les [b]Grimoires Interdits[/b], plus rares, à partir du niveau 3 → 4. Les niveaux 1 → 3 ne coûtent que des Pages : idéal pour monter tous les sorts d'un héros un peu. Ensuite, chaque Grimoire compte : choisis bien les sorts à pousser plus haut.\n"
	return s


static func _etoiles() -> String:
	var s := FenetreGuide.titre("Niveau max et étoiles")
	s += "Le niveau maximum d'un sort dépend des [b]étoiles du héros[/b] : 3 + étoiles, et %d à ★%d Éveillé.\n\n" % [SortsNiveaux.NIVEAU_MAX, Fusion.ETOILES_MAX]
	var lignes: Array = []
	for e in range(1, Fusion.ETOILES_MAX + 1):
		var m := SortsNiveaux.max_pour_etoiles(e)
		lignes.append([Fusion.texte_etoiles(e, false), "Niveau %d" % m, "%d" % _grimoires_jusqua(m)])
	s += FenetreGuide.tableau(["Étoiles du héros", "Niveau max des sorts", "Grimoires pour monter un sort au max"], lignes)
	s += FenetreGuide.sous_titre("Comment gagner une étoile ?")
	s += "À l'[b]Autel de Fusion[/b] (Éveil) : le héros doit être à son niveau maximum, puis tu sacrifies des doublons ou des Pierres d'Éveil. Le bouton « ? » de l'Autel de Fusion explique tout.\n"
	s += FenetreGuide.sous_titre("Quand la fiche affiche « Étoile requise »")
	s += "Le sort est au maximum pour l'instant. Améliore les [b]autres sorts[/b] du héros, ou fais-lui gagner une étoile.\n"
	return s


static func _ressources() -> String:
	var s := FenetreGuide.titre("Où trouver les ressources")
	s += FenetreGuide.sous_titre("La Bibliothèque Interdite (Donjons)")
	s += "C'est le donjon des sorts, dans le menu [b]Donjons[/b] (il s'ouvre à la fin de l'Acte II). Chaque victoire finale donne :\n\n"
	var lignes: Array = []
	for niv in range(1, Donjons.NIVEAUX + 1):
		var q: Array = Donjons.BUTIN_SPECIAL[niv - 1]
		lignes.append(["Niveau %d" % niv, str(int(q[0])), str(int(q[1])) if int(q[1]) > 0 else "-",
			str(int(Donjons.COUT_STAMINA[niv - 1])), str(Donjons.or_victoire(niv))])
	s += FenetreGuide.tableau(["Niveau", "Pages", "Grimoires", "Stamina", "Or gagné"], lignes)
	s += "\n%s de chance d'un [b]butin bonus[/b] : +3 Pages, ou +1 Grimoire Interdit aux niveaux qui en donnent.\n" % (str(int(Donjons.CHANCE_BONUS * 100)) + " %")
	s += "Les Grimoires Interdits tombent à partir du [b]niveau 3[/b] de la Bibliothèque.\n"
	s += FenetreGuide.sous_titre("L'or")
	s += "L'Aventure, les Tours, les Donjons (y compris la Bibliothèque), les coffres d'or du Reliquaire et les quêtes.\n"
	s += FenetreGuide.sous_titre("Voir ce que tu possèdes")
	s += "Le haut de la section SORTS de la fiche du héros affiche tes Pages et tes Grimoires ; le [b]Reliquaire[/b] (Inventaire) aussi.\n"
	return s


## Grimoires Interdits nécessaires pour monter un sort du niveau 1 au niveau m.
static func _grimoires_jusqua(m: int) -> int:
	var t := 0
	for n in range(1, m):
		t += int(SortsNiveaux.cout(n).get(SortsNiveaux.GRIMOIRE, 0))
	return t


static func _conseils() -> String:
	var s := FenetreGuide.titre("Conseils")
	s += FenetreGuide.puce("Monte d'abord le [b]sort actif principal[/b] de tes meilleurs héros : c'est lui qui fait le plus de dégâts ou de soins.")
	s += FenetreGuide.puce("Les niveaux 1 → 3 ne coûtent que des Pages (3 puis 5) : monte tous les sorts de tes héros au niveau 3, c'est très rentable.")
	s += FenetreGuide.puce("Les sorts à longue recharge (4 tours ou plus) gagnent beaucoup au [b]niveau 5[/b] : un tour de recharge en moins.")
	s += FenetreGuide.puce("Ne garde pas tes Pages pour plus tard : un sort amélioré profite à tous les combats dès maintenant.")
	s += FenetreGuide.puce("Prépare la Bibliothèque avec [b]un tank et des héros à sorts de zone[/b] : le guide des Donjons (bouton « ? ») donne une équipe conseillée.")
	s += FenetreGuide.puce("Les Grimoires Interdits sont la ressource rare : réserve-les aux sorts de tes héros principaux.")
	return s
