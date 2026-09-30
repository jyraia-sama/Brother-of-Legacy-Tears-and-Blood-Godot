class_name FinHistoire
extends RefCounted
## FINS DE L'HISTOIRE PRINCIPALE (voir HISTOIRE.md)
##  - Fin de l'Acte XII (fin douce-amère) : titre « Gardien du Sceau » et ouverture de l'Acte XIII caché.
##  - Fin de l'Acte XIII (vraie fin) : Kaël Valcendre (Héros de Légende), titre « Les Frères Réunis »,
##    les deux Échos uniques du Sceau des Frères, 1 000 gemmes et 3 Coffres Royaux.
## Chaque récompense n'est donnée qu'une fois (drapeaux dans la sauvegarde).

const TITRE_ACTE_12 := "Gardien du Sceau"
const TITRE_ACTE_13 := "Les Frères Réunis"
const HEROS_KAEL := "kael_valcendre"
const GEMMES_VRAIE_FIN := 1000
const COFFRES_VRAIE_FIN := 3

const EPILOGUE_12 := """Kaël s'est enfermé avec la Soif dans le Sceau réuni, qui s'est figé en pierre rouge et bleue.
Le domaine Valcendre est reconstruit. Sur la tombe, deux noms, et le médaillon posé entre eux.

…Un an plus tard, tu poses la main sur le médaillon. Très loin, la voix de Kaël : « Il fait froid, ici. »
La pierre rouge se fend d'un fil de lumière.

UN ACTE CACHÉ EST APPARU : Acte XIII — Le Sang et la Larme."""

const EPILOGUE_13 := """« C'est ma dette. Elle n'aurait jamais dû être la vôtre. »
L'ombre d'Othmar a pris la place de Kaël : le Premier Roi est devenu la serrure, enfin en paix.

Les deux frères sortent du Sceau au lever du soleil. Les pierres rouge et bleue sont redevenues claires.
Le domaine Valcendre renaît, avec deux seigneurs.

Dernière image : Kaël qui te nargue à l'entraînement, comme au tout premier jour… et cette fois, tu ris avec lui.

VRAIE FIN — LES FRÈRES RÉUNIS"""


static func _drapeaux() -> Dictionary:
	if not Sauvegarde.donnees.get("fins") is Dictionary:
		Sauvegarde.donnees["fins"] = {}
	return Sauvegarde.donnees["fins"]


## Récompenses de la fin de l'Acte XII (une seule fois). Renvoie les lignes à afficher.
static func fin_acte_12() -> Array:
	var f := _drapeaux()
	var l: Array = []
	if not f.get("acte12", false):
		f["acte12"] = true
		Succes.ajouter_titre(TITRE_ACTE_12)
		l.append("Nouveau titre : « %s »" % TITRE_ACTE_12)
		Sauvegarde.sauvegarder()
	return l


## Récompenses de la vraie fin (une seule fois). Renvoie les lignes à afficher.
static func fin_acte_13() -> Array:
	var f := _drapeaux()
	if f.get("acte13", false):
		return []
	f["acte13"] = true
	var l: Array = []
	# Kaël rejoint la collection
	Sauvegarde.ajouter_heros(HEROS_KAEL)
	Sauvegarde.decouvrir(HEROS_KAEL)
	l.append("Kaël Valcendre rejoint ta collection (Héros de Légende) !")
	# Titre
	Succes.ajouter_titre(TITRE_ACTE_13)
	l.append("Nouveau titre : « %s »" % TITRE_ACTE_13)
	# Les deux Échos uniques du Sceau des Frères (Légendaires, 6 étoiles)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var larme := Echos.creer("freres", 5, 4, 6, "pv%", rng)
	larme["unique"] = "La Larme"
	var sang := Echos.creer("freres", 1, 4, 6, "atk%", rng)
	sang["unique"] = "Le Sang"
	Sauvegarde.ajouter_echo(larme)
	Sauvegarde.ajouter_echo(sang)
	l.append("Échos uniques : la Larme et le Sang (set des Frères, Légendaires 6★)")
	# Gemmes et coffres
	Sauvegarde.ajouter_gemmes(GEMMES_VRAIE_FIN)
	Sauvegarde.ajouter_objet("coffre_royal", COFFRES_VRAIE_FIN)
	l.append("Gemmes : +%d · Coffre Royal x%d" % [GEMMES_VRAIE_FIN, COFFRES_VRAIE_FIN])
	Sauvegarde.sauvegarder()
	return l


## Rattrapage : un joueur qui avait déjà fini l'Acte XII avant cette version reçoit son titre.
static func verifier_rattrapage() -> void:
	if ActesData.est_termine(12, 6) and not _drapeaux().get("acte12", false):
		fin_acte_12()
