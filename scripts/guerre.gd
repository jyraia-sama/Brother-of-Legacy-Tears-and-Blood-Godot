class_name Guerre
extends RefCounted
## GUERRE DES BANNIÈRES : outils partagés (défense de guerre, étoiles, textes).
## Tout le reste (appariement, forteresses, attaques, fatigue, butin) est géré par le serveur
## (supabase/08_guerre.sql). L'écran est dans ecran_guerre.gd.

const COUCHES := ["Remparts", "Tours", "Donjon"]
const COULEURS_COUCHE := [Color("b07a4a"), Color("c8d0d8"), Color("ffd060")]
const PHASES := {"preparation": "Préparation", "assaut": "Assauts", "bilan": "Bilan"}

const ERREURS := {
	"pas_de_guilde": "Tu n'es dans aucune guilde.",
	"pas_en_guerre": "Ta guilde n'est pas en guerre en ce moment.",
	"introuvable": "Ce poste n'existe plus.",
	"couche": "Perce d'abord la couche précédente : chaque poste doit avoir été pris au moins une étoile.",
	"attaques": "Plus d'attaque aujourd'hui. Reviens demain !",
	"fatigue": "Une de ces unités est épuisée : elle a déjà attaqué aujourd'hui.",
	"eclaireur": "Ton éclaireur est déjà parti aujourd'hui.",
	"invalide": "Équipe refusée par le serveur.",
	"droits": "Seuls le chef et les officiers peuvent faire ça.",
	"deja": "Ce combat a déjà été compté.",
	"finie": "La guerre est terminée : ce combat ne compte plus.",
	"rien": "Aucun butin à réclamer.",
	"non_connecte": "Tu n'es pas connecté.",
	"vide": "L'équipe de défense est vide.",
}


static func texte_erreur(code: String) -> String:
	return ERREURS.get(code, code)


## Étoiles d'une attaque : 1 = victoire, 2 = victoire avec 3 unités debout ou plus, 3 = sans perte.
static func etoiles(res: Dictionary) -> int:
	if not bool(res.get("victoire", false)):
		return 0
	var pv: Array = res.get("pv_final", [])
	var debout := pv.filter(func(x): return float(x) > 0.0).size()
	var e := 1
	if debout >= 3:
		e += 1
	if debout == pv.size():
		e += 1
	return mini(e, 3)


static func texte_etoiles(n: int, total := 3) -> String:
	return "★".repeat(clampi(n, 0, total)) + "☆".repeat(maxi(0, total - n))


## Éléments d'une équipe (montrés à l'adversaire sans révéler les unités).
static func elements(equipe: Array) -> Array:
	var r: Array = []
	for u in equipe:
		var d := UnitesData.get_unite(str(u.get("id", "")))
		if not d.is_empty():
			r.append(str(d["element"]))
	return r


# ------------------------------------------------------------------
# Défense de guerre (5 places, gardée dans la sauvegarde ; par défaut celle de l'Arène)
# ------------------------------------------------------------------

static func slots_defense() -> Array:
	Sauvegarde.charger()
	var g: Dictionary = Sauvegarde.donnees.get("guerre", {})
	var brut: Array = g.get("defense", [])
	if brut.is_empty():
		brut = Arene.slots_defense()
		if not brut.any(func(x): return int(x) >= 0):
			brut = Sauvegarde.get_slots()
	var s: Array = []
	for i in 5:
		var uid := int(brut[i]) if i < brut.size() else -1
		s.append(uid if uid >= 0 and not Sauvegarde.get_heros(uid).is_empty() and not uid in s else -1)
	return s


static func definir_slots_defense(slots: Array) -> void:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("guerre") or not Sauvegarde.donnees["guerre"] is Dictionary:
		Sauvegarde.donnees["guerre"] = {}
	Sauvegarde.donnees["guerre"]["defense"] = slots.duplicate()
	Sauvegarde.sauvegarder()


## Envoie la défense au serveur. Renvoie "" si tout va bien, sinon le message d'erreur.
static func envoyer_defense(slots: Array) -> String:
	var equipe := Arene.equipe_depuis_slots(slots)
	if equipe.is_empty():
		return texte_erreur("vide")
	var r: Dictionary = await EnLigne.appeler("guerre_definir_defense",
		{"p_equipe": equipe, "p_puissance": Arene.puissance(equipe), "p_elements": elements(equipe)})
	if not r.ok:
		return r.erreur
	if str(r.data) != "ok":
		return texte_erreur(str(r.data))
	definir_slots_defense(slots)
	return ""
