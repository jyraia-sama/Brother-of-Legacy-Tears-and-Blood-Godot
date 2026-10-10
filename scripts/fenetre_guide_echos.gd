class_name FenetreGuideEchos
extends CanvasLayer
## GUIDE DES ÉCHOS SANGUINS (bouton « ? » de l'écran des Échos, ouvert tout seul à la première visite).
## Explication pas à pas du système, rangée par sections. Tous les chiffres (sets, chances,
## valeurs, drops, Atelier) sont lus dans Echos / Reliquaire : si l'équilibrage change, le guide suit.
##
##   FenetreGuideEchos.ouvrir(parent, uid_heros, section)
## uid_heros (facultatif) : le héros choisi, pour des conseils chiffrés à son sujet.

const C_TITRE := "#ffd27a"
const C_BON := "#8aff9a"
const C_SET := "#ffb08a"
const C_DOUX := "#a8968c"

const NOMS_SECTIONS := ["Pas à pas", "Emplacements et raretés", "Améliorer", "Les Sets",
	"Optimiser ses Échos", "Où trouver des Échos", "Le Mode Essai"]

var _uid_heros := -1
var _section := 0
var _texte: RichTextLabel
var _boutons: Array[Button] = []


static func ouvrir(parent: Node, uid_heros := -1, section := 0) -> FenetreGuideEchos:
	var f := FenetreGuideEchos.new()
	f._uid_heros = uid_heros
	f._section = section
	parent.add_child(f)
	return f


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.72)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1400.0, vp.x - 40.0), minf(800.0, vp.y - 40.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(Color("d0453a"), Color(0.07, 0.02, 0.03, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("GUIDE DES ÉCHOS SANGUINS", 28, Color("d0453a"))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton("Fermer", 16)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 16)
	vb.add_child(corps)
	var dm := ScrollContainer.new()
	dm.custom_minimum_size = Vector2(270, 0)
	dm.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(dm)
	var menu := VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 6)
	dm.add_child(menu)
	for i in NOMS_SECTIONS.size():
		var b := UiCommun.bouton("%d. %s" % [i + 1, NOMS_SECTIONS[i]], 16)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(_afficher.bind(i))
		menu.add_child(b)
		_boutons.append(b)

	var droite := VBoxContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_theme_constant_override("separation", 8)
	corps.add_child(droite)
	_texte = RichTextLabel.new()
	_texte.bbcode_enabled = true
	_texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texte.add_theme_font_size_override("normal_font_size", 18)
	_texte.add_theme_font_size_override("bold_font_size", 18)
	_texte.add_theme_color_override("default_color", UiCommun.C_TEXTE)
	_texte.add_theme_constant_override("table_h_separation", 18)
	_texte.add_theme_constant_override("table_v_separation", 4)
	_texte.scroll_active = true
	droite.add_child(_texte)

	# Navigation : précédent / suivant (pratique sur téléphone)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	droite.add_child(nav)
	var prec := UiCommun.bouton("← Précédent", 15)
	prec.pressed.connect(func(): _afficher(maxi(_section - 1, 0)))
	nav.add_child(prec)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(esp)
	var suiv := UiCommun.bouton("Suivant →", 15)
	suiv.pressed.connect(func(): _afficher(mini(_section + 1, NOMS_SECTIONS.size() - 1)))
	nav.add_child(suiv)
	_afficher(clampi(_section, 0, NOMS_SECTIONS.size() - 1))


func _afficher(i: int) -> void:
	_section = i
	for k in _boutons.size():
		_boutons[k].button_pressed = k == i
		_boutons[k].add_theme_color_override("font_color", Color(C_TITRE) if k == i else UiCommun.C_TEXTE)
		_boutons[k].add_theme_stylebox_override("normal", UiCommun.style_carte(Color(C_TITRE) if k == i else Color(1, 1, 1, 0.12), 0.08 if k == i else 0.0, 2))
	_texte.text = texte_section(i, _uid_heros)
	_texte.scroll_to_line(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()


# =====================================================================
# Textes (BBCode). Construits à partir des vraies valeurs du jeu.
# =====================================================================

static func texte_section(i: int, uid_heros := -1) -> String:
	match i:
		0: return _pas_a_pas()
		1: return _emplacements()
		2: return _ameliorer()
		3: return _sets()
		4: return _optimiser(uid_heros)
		5: return _ou_trouver()
		6: return _mode_essai()
	return ""


static func _titre(t: String) -> String:
	return "[font_size=24][color=%s][b]%s[/b][/color][/font_size]\n\n" % [C_TITRE, t]


static func _sous_titre(t: String) -> String:
	return "\n[color=%s][b]%s[/b][/color]\n" % [C_TITRE, t]


static func _cellule(t: String, couleur := "") -> String:
	if couleur != "":
		t = "[color=%s]%s[/color]" % [couleur, t]
	return "[cell padding=4,2,4,2]%s[/cell]" % t


static func _ligne_tableau(cellules: Array, entete := false) -> String:
	var s := ""
	for c in cellules:
		s += _cellule("[b]%s[/b]" % c if entete else str(c), C_TITRE if entete else "")
	return s


static func _pas_a_pas() -> String:
	var s := _titre("Les Échos Sanguins, pas à pas")
	s += "Les Échos sont l'équipement de tes héros. Bien choisis, ils peuvent presque doubler la puissance d'une unité. Voici comment s'y prendre, dans l'ordre.\n"
	s += _sous_titre("1. Récupère des Échos")
	s += "Ils tombent surtout dans l'[b]Aventure[/b]. Chaque Acte donne toujours le même set, et le chapitre N donne toujours l'emplacement N (chapitre 1 = Crâne, chapitre 3 = Plaie…). Les boss en donnent plus souvent et de meilleure qualité. (Détails : section 6.)\n"
	s += _sous_titre("2. Choisis un héros")
	s += "Dans la colonne de gauche. Commence par les héros de ton équipe : ce sont eux qui combattent.\n"
	s += _sous_titre("3. Remplis les 6 emplacements")
	s += "Clique un emplacement du héros : l'inventaire n'affiche plus que les Échos qui vont à cette place. Choisis-en un puis « Équiper ». Regarde d'abord la [b]stat principale[/b] : c'est elle qui pèse le plus.\n"
	s += _sous_titre("4. Vise un set")
	s += "2 ou 4 Échos du même set donnent un bonus en plus. Les combinaisons possibles sur 6 emplacements : [b]2 + 2 + 2[/b] (trois petits sets, éventuellement le même trois fois) ou [b]4 + 2[/b] (un grand set et un petit). (Détails : section 4.)\n"
	s += _sous_titre("5. Améliore tes meilleurs Échos")
	s += UiCommun.t("« Améliorer » monte un Écho de +1 à +%d avec de l'or. Garde ton or pour les Échos qui vont rester : bonne rareté, beaucoup d'étoiles, bonne stat principale. (Détails : section 3.)\n") % Echos.NIVEAU_MAX
	s += _sous_titre("6. Fixe ou pourcentage ?")
	s += "En début de partie, les stats [b]fixes[/b] (ATK +, PV +…) rapportent le plus. Dès que les stats de tes héros grandissent (niveau, étoiles, raretés SSR/UR), les [b]%[/b] prennent le dessus. (Détails et chiffres : section 5.)\n"
	s += _sous_titre("7. Teste avant d'équiper")
	s += "Le bouton [b]Mode Essai[/b] permet d'essayer plusieurs Échos sur un héros et de comparer ses stats avant et après, sans rien changer tant que tu ne valides pas. (Section 7.)\n"
	s += _sous_titre("8. Fais le ménage")
	s += "« Vente rapide » vend d'un coup les Échos Normaux et Magiques libres. Au [b]Reliquaire[/b], l'Atelier démantèle les Échos en Poussière d'Écho pour en fabriquer de meilleurs. Verrouille les Échos que tu veux garder : ils ne seront jamais vendus par erreur.\n"
	return s


static func _emplacements() -> String:
	var s := _titre("Emplacements, raretés et étoiles")
	s += "Chaque héros a [b]6 emplacements[/b]. Certains ont toujours la même stat principale, d'autres peuvent en avoir plusieurs (on dit « variables »).\n\n"
	s += "[table=3]" + _ligne_tableau(["Emplacement", "Type", "Stats principales possibles"], true)
	for i in range(1, 7):
		var em: Dictionary = Echos.EMPLACEMENTS[i]
		var noms: Array = (em["principales"] as Array).map(func(st): return Echos.NOMS_STATS[st])
		var fixe := "fixe" if (em["principales"] as Array).size() <= 2 else "variable"
		s += _ligne_tableau(["%d · %s" % [i, em["nom"]], fixe, ", ".join(noms)])
	s += "[/table]\n"
	s += UiCommun.t("\n[color=%s]La MAG n'existe qu'en stat secondaire. La Vitesse principale n'existe que sur l'Artère, les critiques sur le Sacrifice, la Précision et la Résistance sur le Serment.[/color]\n") % C_DOUX

	s += _sous_titre("La rareté (la couleur)")
	s += "Elle donne le nombre de [b]stats secondaires[/b] au départ. Les autres apparaissent en améliorant l'Écho (jusqu'à 4).\n\n"
	s += "[table=2]" + _ligne_tableau(["Rareté", "Stats secondaires au départ"], true)
	for r in Echos.RARETES:
		s += _cellule(r["nom"], "#" + (r["couleur"] as Color).to_html(false)) + _cellule(str(r["secondaires"]))
	s += "[/table]\n"

	s += _sous_titre("Les étoiles (★1 à ★6)")
	s += "Elles fixent la [b]force[/b] de l'Écho : sa stat principale et ses tirages de stats secondaires. Exemple avec un Écho du Crâne à ATK fixe :\n\n"
	s += "[table=3]" + _ligne_tableau(["Étoiles", "ATK à +0", UiCommun.t("ATK à +%d") % Echos.NIVEAU_MAX], true)
	for et in range(1, 7):
		var e0 := {"principale": "atk", "etoiles": et, "niveau": 0}
		var e15 := {"principale": "atk", "etoiles": et, "niveau": Echos.NIVEAU_MAX}
		s += _ligne_tableau(["★".repeat(et), "+%d" % int(Echos.valeur_principale(e0)), "+%d" % int(Echos.valeur_principale(e15))])
	s += "[/table]\n"
	s += "\n[b]À retenir :[/b] un ★5 Héroïque bien amélioré vaut bien mieux qu'un ★2 Légendaire. Les étoiles comptent plus que la couleur pour la stat principale ; la couleur, elle, apporte les stats secondaires.\n"
	return s


static func _ameliorer() -> String:
	var s := _titre(UiCommun.t("Améliorer un Écho (+1 à +%d)") % Echos.NIVEAU_MAX)
	s += "Chaque niveau renforce la stat principale. Chaque tentative coûte de l'or. [b]En cas d'échec, seul l'or est perdu[/b] : l'Écho reste intact, il ne perd jamais de niveau.\n"
	s += _sous_titre("Les paliers")
	s += UiCommun.t("Aux niveaux [b]%s[/b], l'Écho gagne une nouvelle stat secondaire. S'il en a déjà 4, l'une d'elles est renforcée au hasard. C'est pour ça qu'un Écho Légendaire (4 stats dès le départ) gagne 5 renforcements en montant à +%d.\n") % [", ".join(Echos.PALIERS.map(func(x): return "+%d" % x)), Echos.NIVEAU_MAX]
	s += _sous_titre("Chances de réussite et coût")
	s += "Le coût dépend des étoiles et du niveau actuel. Exemple pour un Écho ★4 :\n\n"
	s += "[table=3]" + _ligne_tableau(["Passage", "Chance", "Coût (★4)"], true)
	for n in range(1, Echos.NIVEAU_MAX + 1):
		var c: float = Echos.CHANCES_AMELIORATION[mini(n, Echos.CHANCES_AMELIORATION.size() - 1)]
		var cout := Echos.cout_amelioration({"etoiles": 4, "niveau": n - 1})
		var couleur := C_BON if c >= 0.8 else ("#ffd27a" if c >= 0.4 else "#ff7a6a")
		var pal := "  ◆" if n in Echos.PALIERS else ""
		s += _cellule("+%d → +%d%s" % [n - 1, n, pal]) + _cellule("%d %%" % int(round(c * 100)), couleur) + _cellule(UiCommun.t("%d or") % cout)
	s += "[/table]\n"
	s += UiCommun.t("\n[color=%s]◆ = palier (nouvelle stat secondaire ou renforcement).[/color]\n") % C_DOUX
	s += _sous_titre("Conseils")
	s += "• Les premiers niveaux sont garantis : monte tous tes Échos équipés à +3 sans hésiter.\n"
	s += "• Au-delà de +9, chaque tentative est un pari : réserve-les aux Échos ★5-★6 de bonne rareté que tu garderas longtemps.\n"
	s += "• Dans la fenêtre d'amélioration, « Jusqu'à +X » enchaîne les tentatives à ta place, et « Arrêter » la coupe à tout moment.\n"
	s += "• Un Écho amélioré se revend et se démantèle un peu mieux, mais jamais au prix de l'or investi.\n"
	return s


static func _sets() -> String:
	var s := _titre("Les Sets")
	s += "Équipe plusieurs Échos du même set pour activer son bonus.\n"
	s += "• Set à [b]2 pièces[/b] : le bonus compte [b]une fois par paire[/b]. 4 pièces = 2 fois, 6 pièces = 3 fois.\n"
	s += "• Set à [b]4 pièces[/b] : le bonus ne compte qu'une fois. Il reste 2 places pour un set à 2 pièces.\n\n"
	var acte_du_set := {}
	for a in Echos.SET_PAR_ACTE:
		var sid: String = Echos.SET_PAR_ACTE[a]
		if not acte_du_set.has(sid):
			acte_du_set[sid] = []
		acte_du_set[sid].append(_romain(int(a)))
	s += "[table=4]" + _ligne_tableau(["Set", "Pièces", "Bonus (par activation)", "Où le trouver"], true)
	for sid in Echos.SETS:
		var desc := Echos.description_set(sid)
		desc = desc.substr(desc.find(":") + 2)
		var ou := "Vraie fin de l'histoire (unique)" if sid in Echos.SETS_UNIQUES else \
			("Acte " + ", ".join(acte_du_set.get(sid, ["?"])))
		s += _cellule(Echos.SETS[sid]["nom"], C_SET) + _cellule(str(Echos.SETS[sid]["pieces"])) + _cellule(desc) + _cellule(ou)
	s += "[/table]\n"
	s += UiCommun.t("\n[color=%s]Tous les sets (sauf le set unique des Frères) peuvent aussi être fabriqués à l'Atelier du Reliquaire.[/color]\n") % C_DOUX
	s += _sous_titre("Quel set pour quel héros ?")
	s += "• [b]Avant qui encaisse[/b] (Tank, Guerrier) : Guard ou Energy, à cumuler (2 + 2 + 2), avec Endure ou Will contre les afflictions.\n"
	s += "• [b]Frappeur physique[/b] (Assassin, Guerrier, Tireur) : Fatal (4) + Blade, ou Rage (4) + Blade quand son taux critique est déjà élevé.\n"
	s += "• [b]Lanceur de sorts[/b] (Mage) : les dégâts des sorts = 0,6 × ATK + MAG ; Fatal reste bon, Despair (4) ajoute des étourdissements.\n"
	s += "• [b]Soutien[/b] : Swift (4) pour agir en premier, + Focus ou Endure.\n"
	s += "• [b]Durée de vie[/b] : Vampire (4) soigne à chaque coup, très fort sur un frappeur de l'Avant. Revenge punit ceux qui tapent le porteur.\n"
	s += "\n[b]Astuce :[/b] un set complet ne sauve pas de mauvaises stats principales. Mieux vaut une bonne stat principale sans set qu'un set avec des stats inutiles pour le héros.\n"
	return s


static func _optimiser(uid_heros: int) -> String:
	var s := _titre("Optimiser ses Échos : fixe ou % ?")
	s += UiCommun.t("Une stat [b]fixe[/b] ajoute toujours la même valeur (ATK +%d sur un ★6 +%d). Un [b]%%[/b] ajoute un pourcentage des stats de base du héros (niveau et étoiles compris, sans les Échos). Plus le héros est fort, plus le %% rapporte.\n") % [int(Echos.valeur_principale({"principale": "atk", "etoiles": 6, "niveau": Echos.NIVEAU_MAX})), Echos.NIVEAU_MAX]
	s += _sous_titre("Le point de bascule")
	s += "Avec deux Échos de mêmes étoiles et même niveau, le % devient meilleur que le fixe quand la stat de base du héros dépasse :\n\n"
	s += "[table=4]" + _ligne_tableau(["Stat", UiCommun.t("Fixe (★6 +%d)") % Echos.NIVEAU_MAX, "%% (★6 +%d)" % Echos.NIVEAU_MAX, "Le % gagne au-delà de"], true)
	for st in ["atk", "def", "pv"]:
		var fixe := Echos.valeur_principale({"principale": st, "etoiles": 6, "niveau": Echos.NIVEAU_MAX})
		var pct := Echos.valeur_principale({"principale": st + "%", "etoiles": 6, "niveau": Echos.NIVEAU_MAX})
		s += _ligne_tableau([Echos.NOMS_STATS[st], "+%d" % int(fixe), "+%s %%" % _n(pct), UiCommun.t("[b]%d[/b] %s de base") % [seuil(st), Echos.NOMS_STATS[st]]])
	s += "[/table]\n"
	s += UiCommun.t("\n[color=%s]Le seuil ne dépend ni des étoiles ni du niveau de l'Écho : il est le même pour un ★2 +0 que pour un ★6 +15. Pour les stats secondaires, la logique est la même (seuils proches).[/color]\n") % C_DOUX

	if uid_heros >= 0:
		var h := Sauvegarde.get_heros(uid_heros)
		if not h.is_empty():
			var base := Sauvegarde.stats_base_heros(uid_heros)
			var nom: String = UnitesData.get_unite(h["id"])["nom"]
			s += _sous_titre(UiCommun.t("Et pour %s (Nv %d) ?") % [nom, int(h["niveau"])])
			for st in ["atk", "def", "pv"]:
				var b := int(base[st])
				var mieux := b >= seuil(st)
				s += UiCommun.t("• %s de base [b]%d[/b] → %s\n") % [Echos.NOMS_STATS[st], b,
					(UiCommun.t("[color=%s]le %% est meilleur (%s %%)[/color]") % [C_BON, Echos.NOMS_STATS[st]]) if mieux else \
					(UiCommun.t("le [b]fixe[/b] est meilleur (le %% gagnera vers %d)") % seuil(st))]

	s += _sous_titre("Selon ton avancée")
	s += "• [b]Début de partie[/b] (héros N et R, bas niveau) : les stats de base sont faibles, prends les [b]fixes[/b] (ATK, DEF, PV). Ne dépense pas trop d'or en améliorations : tes Échos seront vite remplacés.\n"
	s += "• [b]Milieu de partie[/b] (SR/SSR, niveau 10 à 20, premières étoiles) : passe à [b]ATK %[/b] et [b]DEF %[/b] sur les emplacements variables. Les PV % ne battent les PV fixes que sur les héros très costauds.\n"
	s += "• [b]Fin de partie[/b] (SSR/UR niveau 30, ★5-★6, évolutions) : [b]%[/b] partout, puis [b]Taux crit / Dégâts crit[/b] sur le Sacrifice pour les frappeurs.\n"
	s += UiCommun.t("\n[color=%s]Les SSR et UR ont de grosses stats dès le niveau 1 : pour eux, le %% d'ATK gagne souvent tout de suite. Le Mode Essai te le montre en chiffres.[/color]\n") % C_DOUX

	s += _sous_titre("Les stats secondaires utiles")
	s += "• [b]Taux crit[/b] : au-delà de 100, il ne sert plus à rien. Associe-le aux [b]Dégâts crit[/b].\n"
	s += "• [b]Précision[/b] : les attaques ne ratent plus à 100. Les héros en ont déjà 90 à 100 : inutile d'en empiler.\n"
	s += "• [b]Résistance[/b] : réduit les dégâts des sorts reçus et la chance de subir une affliction. Excellente pour l'Avant.\n"
	s += "• [b]Vitesse[/b] : décide qui agit en premier. Précieuse pour les soutiens et les assassins.\n"
	s += "• [b]MAG[/b] : seulement en stat secondaire, utile pour les héros qui comptent sur leurs sorts.\n"
	s += _sous_titre("La méthode en 4 étapes")
	s += "1. Choisis le rôle du héros (encaisser, frapper, soigner…).\n2. Mets la bonne stat principale sur les emplacements variables (Artère, Sacrifice, Serment).\n3. Complète un set adapté.\n4. Améliore d'abord les Échos qui apportent le plus, et vérifie dans le Mode Essai.\n"
	return s


static func _ou_trouver() -> String:
	var s := _titre("Où trouver des Échos (et des rares)")
	s += _sous_titre("Dans l'Aventure")
	s += "Après chaque victoire, un Écho peut tomber. Son [b]set dépend de l'Acte[/b], son [b]emplacement du numéro du chapitre[/b]. Pour un emplacement précis, rejoue le bon chapitre !\n\n"
	var noms_types := {"combat": "Combat", "elite": "Élite", "gardien": "Gardien", "mimic": "Mimic",
		"boss_chapitre": "Boss de chapitre", "boss_acte": "Boss d'Acte"}
	s += "[table=8]" + _ligne_tableau(["Combat", "Chance"] + Echos.RARETES.map(func(r): return r["nom"]) + ["Bonus ★"], true)
	for type in ["combat", "elite", "gardien", "mimic", "boss_chapitre", "boss_acte"]:
		var poids: Array = Echos.POIDS_RARETE[type]
		var total := 0
		for w in poids:
			total += int(w)
		var cellules := [noms_types[type], "%d %%" % int(round(float(Echos.CHANCE_DROP[type]) * 100))]
		for w in poids:
			cellules.append(("%d %%" % int(round(100.0 * w / total))) if w > 0 else "—")
		var be := int(Echos.BONUS_ETOILES[type])
		cellules.append("+1" if be > 0 else ("-1" if be < 0 else "0"))
		s += _ligne_tableau(cellules)
	s += "[/table]\n"
	s += "\n[b]Les étoiles augmentent au fil de l'histoire[/b] : plus l'Acte est avancé, plus les Échos sont forts. Les boss ajoutent une étoile, les combats simples en retirent une.\n\n"
	s += "[table=2]" + _ligne_tableau(["Actes", "Étoiles des Échos (combat simple → boss)"], true)
	var groupes := [[1, 3], [4, 5], [6, 7], [8, 10], [11, 13]]
	for g in groupes:
		var mini_ := 99
		var maxi_ := 0
		for a in range(g[0], g[1] + 1):
			for ch in range(1, 7):
				var base := 1 + int(((a - 1) * 6 + (ch - 1)) / 14.0)
				mini_ = mini(mini_, clampi(base - 1, 1, 6))
				maxi_ = maxi(maxi_, clampi(base + 2, 1, 6))
		s += _ligne_tableau(["%s à %s" % [_romain(g[0]), _romain(g[1])], "★%d à ★%d" % [mini_, maxi_]])
	s += "[/table]\n"
	s += _sous_titre("À l'Atelier du Reliquaire")
	s += "Tu choisis le [b]set[/b] et l'[b]emplacement[/b] (et même la stat principale) : c'est le meilleur moyen de compléter un set.\n\n"
	s += "[table=4]" + _ligne_tableau(["Fabrication", "Coût", "Étoiles", "Raretés possibles"], true)
	for type in Reliquaire.ATELIER:
		var a: Dictionary = Reliquaire.ATELIER[type]
		var r: Array = []
		var poids: Array = a["raretes"]
		var total := 0
		for w in poids:
			total += int(w)
		for i in poids.size():
			if int(poids[i]) > 0:
				r.append("%s %d %%" % [Echos.RARETES[i]["nom"], int(round(100.0 * int(poids[i]) / total))])
		s += _ligne_tableau([a["nom"], "%d Poussière + %d or" % [int(a["poussiere"]), int(a["or"])],
			"★%d à ★%d" % [int(a["etoiles"][0]), int(a["etoiles"][1])], ", ".join(r)])
	s += "[/table]\n"
	s += "\n[b]Poussière d'Écho[/b] : en démantelant tes Échos inutiles à l'Atelier, et dans les Tours, le Boss de Monde, la Compagnie, la Ménagerie, les Quêtes, la Boutique et le Marché du jour.\n"
	s += _sous_titre("Pour obtenir des Échos plus rares")
	s += "• Farme les [b]boss de chapitre et d'Acte[/b] : drop garanti et rareté bien meilleure.\n"
	s += "• Les [b]Mimics[/b] sont aussi généreux : ne les laisse pas filer.\n"
	s += "• Avance dans l'histoire : les Actes lointains donnent plus d'étoiles.\n"
	s += "• Démantèle tout ce qui ne sert pas, et utilise la [b]Fabrication supérieure[/b] pour viser Héroïque et Légendaire en ★4 à ★6.\n"
	s += "• Le [b]set des Frères[/b], unique, ne s'obtient qu'à la vraie fin de l'histoire.\n"
	return s


static func _mode_essai() -> String:
	var s := _titre("Le Mode Essai")
	s += "Pour comparer avant d'équiper, sans rien risquer.\n"
	s += _sous_titre("Comment l'utiliser")
	s += "1. Choisis un héros, puis appuie sur [b]Mode Essai[/b] (au-dessus de ses emplacements).\n"
	s += "2. Clique des Échos dans l'inventaire : chacun se place [b]en essai[/b] sur son emplacement. Tu peux en essayer plusieurs à la fois, jusqu'à un set complet.\n"
	s += "3. Les emplacements modifiés sont entourés en bleu. Clique un emplacement pour filtrer l'inventaire ; « Retirer de l'essai » vide un emplacement.\n"
	s += "4. Le tableau compare les stats [b]actuelles[/b] et [b]en essai[/b] : en vert ce qui monte, en rouge ce qui baisse. Les sets gagnés ou perdus sont indiqués aussi.\n"
	s += "5. [b]Équiper l'essai[/b] applique tout d'un coup. « Annuler l'essai » remet comme avant.\n"
	s += _sous_titre("Bon à savoir")
	s += "• Seuls les Échos que tu possèdes peuvent être essayés, y compris ceux portés par un autre héros : si tu valides, ils lui seront retirés (le jeu te prévient).\n"
	s += "• Rien n'est modifié tant que tu ne valides pas : quitte le Mode Essai et tout reste comme avant.\n"
	s += "• Les bénédictions de guilde sont comptées, comme en combat.\n"
	return s


# ---------------------------------------------------------------------
# Outils
# ---------------------------------------------------------------------

## Stat de base à partir de laquelle la version % d'une stat principale bat la version fixe.
static func seuil(st: String) -> int:
	var maxi_: Dictionary = Echos.PRINCIPALE_MAX
	return int(round(float(maxi_[st]) / float(maxi_[st + "%"]) * 100.0))


static func _n(x: float) -> String:
	return str(int(x)) if is_equal_approx(x, round(x)) else str(snappedf(x, 0.1))


static func _romain(n: int) -> String:
	const R := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]
	return R[n] if n < R.size() else str(n)
