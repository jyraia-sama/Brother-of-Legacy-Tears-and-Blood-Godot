class_name FenetreAide
extends CanvasLayer
## AIDE (bouton « ? » du menu principal) : une synthèse du jeu pour un nouveau joueur,
## rangée par sections. Pour modifier un texte, change SECTIONS ci-dessous.

const SECTIONS := [
	["Premiers pas", """Bienvenue dans Brothers of Legacy : Tears and Blood !

• Ton HÉROS DE DÉPART (portrait en haut à gauche du menu) t'accompagne toute l'aventure. Il ne peut être ni vendu ni sacrifié.
• Commence par l'AVENTURE → Histoire principale : chaque chapitre est un plateau où tu avances case par case.
• Prépare ton ÉQUIPE dans le DECK : 5 places, les 2 premières sont à l'AVANT, les 3 autres à l'ARRIÈRE.
• Les combats sont automatiques. Tu choisis l'équipe, le placement et l'équipement : c'est là que tout se joue.
• Chaque jour : récupère ta récompense de connexion et tes QUÊTES (icône en bas à gauche)."""],
	["Ressources", """• STAMINA : se dépense pour combattre (Aventure, Tours, Donjons). 1 point toutes les 5 minutes, même jeu fermé. Monter de niveau de compte la recharge entièrement et augmente le maximum.
• OR : invocations du Pacte Doré, améliorations d'Échos, Autel de Fusion, Marché du jour.
• GEMMES : se gagnent avec les Quêtes, les Succès, la connexion quotidienne et l'Arène. Elles servent au Comptoir de la Boutique (stamina, Éclats, Pierres d'Éveil…).
• ÉCLATS DE PACTE SUPÉRIEUR : lâchés par les boss, pour invoquer des SR, SSR et UR.
• Les autres objets (Braises, Plumes, Fragments, ressources des Donjons, coffres, tomes, élixirs…) sont rangés au RELIQUAIRE."""],
	["Combat", """• Chaque unité a PV, ATK (dégâts physiques), DEF, AGI (qui agit en premier) et MAG (puissance des sorts).
• Les sorts actifs se déclenchent au hasard à chaque tour (leur % de chance est indiqué) ; les passifs sont toujours actifs. Ils se débloquent aux niveaux 1, 10, 20 et 30.
• AVANT / ARRIÈRE : les combattants au corps à corps (Guerrier, Tank, Assassin) frappent plus fort à l'Avant ; l'Avant reçoit aussi plus de coups. Tireurs, Mages et Soutiens sont mieux à l'Arrière.
• ÉLÉMENTS : Feu > Nature > Eau > Feu, et Ténèbres ↔ Sacré. +25 % de dégâts contre l'élément faible, −20 % contre le fort.
• Les boss ont souvent une PHASE 2 quand leurs PV baissent."""],
	["Unités", """• DECK : ta collection et ton équipe. Tri, vente, verrouillage, fiche complète de chaque unité.
• AUTEL D'INVOCATION : Pacte Doré (or : N, R, SR) et Pacte Supérieur (Éclats : SR, SSR, UR), avec une garantie SSR.
• AUTEL DE FUSION : ÉVEIL (sacrifie des doublons pour gagner des étoiles, jusqu'à ★6) et ABSORPTION (sacrifie des unités pour de l'XP).
• ÉVOLUTION : une unité niveau 30 peut devenir sa version évoluée (plus forte, sorts améliorés, niveau max 40) avec les ressources des Donjons.
• BESTIAIRE : toutes les unités rencontrées ou obtenues."""],
	["Échos Sanguins", """• Chaque unité porte jusqu'à 6 ÉCHOS (un par emplacement : Crâne, Artère, Plaie, Sacrifice, Âme, Serment).
• Chaque Écho a une stat principale, des stats secondaires, une rareté et des étoiles.
• AMÉLIORATION de +1 à +15 : les chances baissent avec le niveau ; en cas d'échec seul l'or est perdu. Aux paliers +3, +6, +9, +12 et +15, une stat secondaire apparaît ou se renforce.
• SETS : 2 ou 4 Échos du même set donnent un bonus en plus.
• Chaque Acte de l'histoire donne un set, et le chapitre N donne l'emplacement N."""],
	["Modes de jeu", """• HISTOIRE : 12 Actes de 6 chapitres.
• TOURS de l'Enfer et du Paradis : 100 étages chacune, remises à zéro chaque lundi, butin pour forger des héros exclusifs.
• DONJONS : 6 donjons de 10 niveaux ; 4 combats d'affilée sans soin ; ressources d'évolution.
• EXPÉDITIONS : la MARCHE MAUDITE (roguelike du jour avec classement) et la COMPAGNIE (missions en temps réel pour les unités hors équipe).
• BOSS DE MONDE : un géant par jour de la semaine, affronté avec 20 unités.
• ARÈNE : combats contre les défenses des autres joueurs, saisons et boutique d'Insignes."""],
	["En ligne", """• Crée un COMPTE (Paramètres → Gérer le compte) : ta partie est sauvegardée en ligne automatiquement.
• SOCIAL : ajoute des amis. GUILDE : crée ou rejoins une guilde.
• ARÈNE : ta défense est enregistrée automatiquement à ta première visite ; modifie-la dans l'onglet Défense.
• Tu peux aussi copier un CODE DE SAUVEGARDE (Paramètres) pour garder ta partie de côté."""],
	["Sur téléphone", """• Le jeu s'installe comme une appli : Android → menu ⋮ → Ajouter à l'écran d'accueil ; iPhone → Partager → Sur l'écran d'accueil.
• Glisse le doigt pour faire défiler les listes.
• La taille de l'interface se règle dans Paramètres → Affichage."""],
]

var _texte: RichTextLabel
var _boutons: Array[Button] = []


static func ouvrir(parent: Node) -> void:
	parent.add_child(FenetreAide.new())


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1300.0, vp.x - 40.0), minf(760.0, vp.y - 40.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(UiCommun.C_OR, Color(0.07, 0.02, 0.03, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("AIDE — COMMENT JOUER", 28, UiCommun.C_OR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton("Fermer", 16)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)
	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 16)
	vb.add_child(corps)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(260, 0)
	menu.add_theme_constant_override("separation", 6)
	corps.add_child(menu)
	for i in SECTIONS.size():
		var b := UiCommun.bouton(SECTIONS[i][0], 17)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 48)
		b.pressed.connect(_afficher.bind(i))
		menu.add_child(b)
		_boutons.append(b)
	_texte = RichTextLabel.new()
	_texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texte.add_theme_font_size_override("normal_font_size", 19)
	_texte.add_theme_color_override("default_color", UiCommun.C_TEXTE)
	_texte.scroll_active = true
	corps.add_child(_texte)
	_afficher(0)


func _afficher(i: int) -> void:
	for k in _boutons.size():
		_boutons[k].button_pressed = k == i
	_texte.text = SECTIONS[i][1]
	_texte.scroll_to_line(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
