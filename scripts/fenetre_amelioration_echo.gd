class_name FenetreAmeliorationEcho
extends Control
## FENÊTRE D'AMÉLIORATION D'UN ÉCHO SANGUIN (ouverte par « Améliorer » dans l'écran des Échos).
##  - infos : niveau, stat principale actuelle -> au prochain niveau, stats secondaires,
##    prochain palier (+3, +6, +9, +12, +15), chance de réussite et coût de la tentative ;
##  - bouton « +1 » : une seule tentative ;
##  - boutons « Jusqu'à +3 / +6 / +9 / +12 / +15 » : tentatives en boucle (l'or est payé à chaque
##    tentative) jusqu'à atteindre le niveau visé, manquer d'or, ou appuyer sur « Arrêter » ;
##  - une barre de chargement se remplit à chaque tentative avant d'annoncer le résultat.
##
##   FenetreAmeliorationEcho.ouvrir(parent, uid_echo, rng, quand_fermee)

const CIBLES := [3, 6, 9, 12, 15]
const DUREE_NORMALE := 0.9      # secondes de chargement par tentative
const DUREE_RAPIDE := 0.25
const C_OK := Color("8aff9a")
const C_ECHEC := Color("ff7a6a")

var _uid := -1
var _rng: RandomNumberGenerator
var _quand_fermee: Callable
var _en_cours := false
var _arret := false
var _rapide := false

var _titre: Label
var _infos: VBoxContainer
var _barre: ProgressBar
var _lbl_barre: Label
var _resultat: Label
var _journal: VBoxContainer
var _recap: VBoxContainer
var _btn_plus1: Button
var _boutons: Array[Button] = []
var _btn_arret: Button
var _btn_fermer: Button
var _panneau: PanelContainer


static func ouvrir(parent: Node, uid_echo: int, rng: RandomNumberGenerator, quand_fermee: Callable) -> FenetreAmeliorationEcho:
	var f := FenetreAmeliorationEcho.new()
	f._uid = uid_echo
	f._rng = rng
	f._quand_fermee = quand_fermee
	parent.add_child(f)
	return f


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.65)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	_panneau = PanelContainer.new()
	_panneau.custom_minimum_size = Vector2(860, 0)
	centre.add_child(_panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_panneau.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	_titre = UiCommun.label("", 24, UiCommun.C_OR)
	_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(_titre)
	var rapide := CheckBox.new()
	UiCommun.habiller_case(rapide)
	rapide.text = "Rapide"
	rapide.focus_mode = Control.FOCUS_NONE
	rapide.tooltip_text = "Barre de chargement plus courte."
	rapide.toggled.connect(func(v: bool): _rapide = v)
	tete.add_child(rapide)

	_infos = VBoxContainer.new()
	_infos.add_theme_constant_override("separation", 4)
	vb.add_child(_infos)

	vb.add_child(HSeparator.new())
	_lbl_barre = UiCommun.label("Prêt.", 16, UiCommun.C_DOUX)
	_lbl_barre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_lbl_barre)
	_barre = UiCommun.barre(Color("d0453a"), 800, 22)
	_barre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barre.max_value = 100
	vb.add_child(_barre)
	_resultat = UiCommun.label(" ", 26, UiCommun.C_TEXTE)
	_resultat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resultat.add_theme_color_override("font_outline_color", Color.BLACK)
	_resultat.add_theme_constant_override("outline_size", 6)
	vb.add_child(_resultat)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	vb.add_child(ligne)
	var plus1 := UiCommun.bouton("+1", 20)
	plus1.custom_minimum_size = Vector2(120, 52)
	plus1.pressed.connect(_lancer.bind(-1))
	ligne.add_child(plus1)
	_boutons.append(plus1)
	_btn_plus1 = plus1
	for c in CIBLES:
		var b := UiCommun.bouton("Jusqu'à +%d" % c, 17)
		b.custom_minimum_size = Vector2(0, 52)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("cible", c)
		b.pressed.connect(_lancer.bind(c))
		ligne.add_child(b)
		_boutons.append(b)

	# Récapitulatif des stats gagnées (affiché après une amélioration)
	_recap = VBoxContainer.new()
	_recap.add_theme_constant_override("separation", 2)
	vb.add_child(_recap)

	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 8)
	vb.add_child(bas)
	_btn_arret = UiCommun.bouton("Arrêter", 16)
	_btn_arret.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_arret.disabled = true
	_btn_arret.pressed.connect(func(): _arret = true)
	bas.add_child(_btn_arret)
	_btn_fermer = UiCommun.bouton("Fermer", 16)
	_btn_fermer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_fermer.pressed.connect(_fermer)
	bas.add_child(_btn_fermer)

	vb.add_child(UiCommun.label("Tentatives", 14, UiCommun.C_DOUX))
	var defil := ScrollContainer.new()
	defil.custom_minimum_size = Vector2(0, 130)
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	_journal = VBoxContainer.new()
	_journal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defil.add_child(_journal)
	_maj()


func _echo() -> Dictionary:
	return Sauvegarde.get_echo(_uid)


## Coût moyen estimé pour aller du niveau actuel jusqu'à `cible` (échecs compris).
static func cout_moyen(e: Dictionary, cible: int) -> int:
	var total := 0.0
	var copie := e.duplicate()
	for n in range(int(e["niveau"]), mini(cible, Echos.NIVEAU_MAX)):
		copie["niveau"] = n
		total += Echos.cout_amelioration(copie) / maxf(0.01, Echos.chance_amelioration(copie))
	return int(round(total))


func _maj() -> void:
	var e := _echo()
	if e.is_empty():
		_fermer()
		return
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	_panneau.add_theme_stylebox_override("panel", UiCommun.style_panneau(coul, Color(0.07, 0.02, 0.03, 0.97)))
	var niv := int(e["niveau"])
	_titre.text = "AMÉLIORER : %s  +%d" % [Echos.nom(e), niv]
	_titre.add_theme_color_override("font_color", coul)
	for x in _infos.get_children():
		x.queue_free()
	_infos.add_child(UiCommun.label("%s   ·   %s   ·   Or : %d" % ["★".repeat(int(e["etoiles"])), Echos.RARETES[int(e["rarete"])]["nom"], Sauvegarde.get_or()], 15, Color("ffd060")))
	if niv >= Echos.NIVEAU_MAX:
		_infos.add_child(UiCommun.label("Principale : " + Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 17))
		_infos.add_child(UiCommun.label("Niveau maximum atteint (+%d)." % Echos.NIVEAU_MAX, 17, C_OK))
	else:
		var suivant := e.duplicate()
		suivant["niveau"] = niv + 1
		_infos.add_child(UiCommun.label("Principale : %s   →   %s  (au +%d)" % [Echos.texte_stat(e["principale"], Echos.valeur_principale(e)),
			Echos.texte_stat(e["principale"], Echos.valeur_principale(suivant)), niv + 1], 17))
	for s in e["secondaires"]:
		_infos.add_child(UiCommun.label("      " + Echos.texte_stat(s["stat"], s["valeur"]), 14, Color("b8d8ff")))
	var palier := -1
	for p in Echos.PALIERS:
		if p > niv:
			palier = p
			break
	if palier > 0:
		var quoi := "nouvelle stat secondaire" if e["secondaires"].size() < 4 else "une stat secondaire renforcée"
		_infos.add_child(UiCommun.label("Prochain palier : +%d → %s" % [palier, quoi], 14, Color("ffb08a")))
	if niv < Echos.NIVEAU_MAX:
		var cout := Echos.cout_amelioration(e)
		_infos.add_child(UiCommun.label("Tentative vers +%d :  %d %% de réussite   ·   %d or   (en cas d'échec, l'or est perdu mais l'Écho reste intact)" % [
			niv + 1, int(round(Echos.chance_amelioration(e) * 100)), cout], 15, UiCommun.C_TEXTE))
	# Boutons
	if niv < Echos.NIVEAU_MAX:
		_btn_plus1.text = "+1\n%d or" % Echos.cout_amelioration(e)
		_btn_plus1.tooltip_text = "Une tentative vers +%d : %d %% de réussite, %d or." % [niv + 1,
			int(round(Echos.chance_amelioration(e) * 100)), Echos.cout_amelioration(e)]
	else:
		_btn_plus1.text = "+1"
	for b in _boutons:
		if b.has_meta("cible"):
			var c: int = b.get_meta("cible")
			b.visible = c > niv
			b.text = "Jusqu'à +%d\n~%d or" % [c, cout_moyen(e, c)]
			b.tooltip_text = "Tentatives en boucle jusqu'au +%d. Coût moyen estimé : %d or (le hasard peut coûter plus ou moins)." % [c, cout_moyen(e, c)]
		b.disabled = _en_cours or niv >= Echos.NIVEAU_MAX or Sauvegarde.get_or() < Echos.cout_amelioration(e)
	_btn_arret.disabled = not _en_cours
	_btn_fermer.disabled = _en_cours


## cible = -1 : une seule tentative (+1) ; sinon, en boucle jusqu'au niveau cible.
func _lancer(cible: int) -> void:
	if _en_cours:
		return
	_en_cours = true
	_arret = false
	_maj()
	var tentatives := 0
	var depense := 0
	var avant: Dictionary = _echo().duplicate(true)
	for x in _recap.get_children():
		x.queue_free()
	while true:
		var e := _echo()
		var niv := int(e["niveau"])
		if niv >= Echos.NIVEAU_MAX or (cible > 0 and niv >= cible):
			break
		var cout := Echos.cout_amelioration(e)
		if not Sauvegarde.depenser_or(cout):
			_annoncer("Pas assez d'or (%d requis)." % cout, C_ECHEC)
			Audio.son("erreur")
			break
		tentatives += 1
		depense += cout
		# Barre de chargement
		var chance := Echos.chance_amelioration(e)
		_lbl_barre.text = "Amélioration vers +%d…   (%d %% de réussite)" % [niv + 1, int(round(chance * 100))]
		_lbl_barre.add_theme_color_override("font_color", UiCommun.C_TEXTE)
		_resultat.text = " "
		_barre.value = 0
		(_barre.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color("d0453a")
		var tw := create_tween()
		tw.tween_property(_barre, "value", 100.0, DUREE_RAPIDE if _rapide else DUREE_NORMALE)
		await tw.finished
		if not is_inside_tree():
			return
		var r := Echos.ameliorer(e, _rng)
		Sauvegarde._stat("ameliorations_echo")
		if r["reussi"] and int(e["niveau"]) >= Echos.NIVEAU_MAX:
			Sauvegarde._stat("echos_max")
		Sauvegarde.sauvegarder()
		(_barre.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = C_OK if r["reussi"] else C_ECHEC
		_annoncer(r["texte"], C_OK if r["reussi"] else C_ECHEC)
		Audio.son("niveau" if r["reussi"] else "erreur")
		_noter("+%d : %s   (−%d or)" % [niv + 1, "RÉUSSITE" if r["reussi"] else "échec", cout], C_OK if r["reussi"] else C_ECHEC)
		_maj()
		if cible < 0 or _arret:
			break
		await get_tree().create_timer(0.35 if _rapide else 0.6).timeout
		if not is_inside_tree():
			return
	_en_cours = false
	if cible > 0 and tentatives > 1:
		_lbl_barre.text = "%d tentatives   ·   %d or dépensés" % [tentatives, depense]
	if tentatives > 0:
		_afficher_recap(avant, _echo(), tentatives, depense)
	_maj()


## Récapitulatif : niveaux, stat principale, stats secondaires nouvelles ou renforcées.
func _afficher_recap(avant: Dictionary, apres: Dictionary, tentatives: int, depense: int) -> void:
	for x in _recap.get_children():
		x.queue_free()
	var n0 := int(avant["niveau"])
	var n1 := int(apres["niveau"])
	var titre := UiCommun.label("RÉCAPITULATIF   ·   +%d → +%d   ·   %d tentative%s, %d or" % [n0, n1, tentatives,
		"s" if tentatives > 1 else "", depense], 16, UiCommun.C_OR)
	_recap.add_child(titre)
	if n1 == n0:
		_recap.add_child(UiCommun.label("Aucun niveau gagné : les stats ne changent pas.", 15, UiCommun.C_DOUX))
		return
	var st: String = apres["principale"]
	var v0 := Echos.valeur_principale(avant)
	var v1 := Echos.valeur_principale(apres)
	_recap.add_child(UiCommun.label("Principale : %s  →  %s   (%s)" % [Echos.texte_stat(st, v0), Echos.texte_stat(st, v1),
		_ecart(st, v1 - v0)], 15, C_OK))
	var anciennes := {}
	for s0 in avant["secondaires"]:
		anciennes[s0["stat"]] = float(s0["valeur"])
	for s1 in apres["secondaires"]:
		var nom: String = s1["stat"]
		var v := float(s1["valeur"])
		if not anciennes.has(nom):
			_recap.add_child(UiCommun.label("Nouvelle stat : " + Echos.texte_stat(nom, v), 15, Color("8ad8ff")))
		elif v > float(anciennes[nom]):
			_recap.add_child(UiCommun.label("Renforcée : %s  →  %s   (%s)" % [Echos.texte_stat(nom, anciennes[nom]),
				Echos.texte_stat(nom, v), _ecart(nom, v - float(anciennes[nom]))], 15, Color("8ad8ff")))


func _ecart(stat: String, d: float) -> String:
	var v := str(snappedf(d, 0.1)) if stat in Echos.STATS_EN_POURCENT else str(int(round(d)))
	return "+" + v + (" %" if stat.ends_with("%") or stat == "degats_crit" else "")


func _annoncer(texte: String, c: Color) -> void:
	_resultat.text = texte.replace("\n", "   ·   ")
	_resultat.add_theme_color_override("font_color", c)
	_resultat.pivot_offset = _resultat.size / 2.0
	_resultat.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(_resultat, "scale", Vector2.ONE, 0.25)


func _noter(texte: String, c: Color) -> void:
	var l := UiCommun.label(texte, 14, c)
	_journal.add_child(l)
	_journal.move_child(l, 0)
	while _journal.get_child_count() > 40:
		_journal.get_child(_journal.get_child_count() - 1).free()


func _fermer() -> void:
	if _en_cours:
		return
	if _quand_fermee.is_valid():
		_quand_fermee.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _en_cours:
			_arret = true
		else:
			_fermer()
