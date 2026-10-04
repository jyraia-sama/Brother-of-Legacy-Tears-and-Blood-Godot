@tool
extends EditorPlugin
## Onglet « Versions » dans l'éditeur Godot (à droite, à côté de l'Inspecteur).
##  - Sauvegarder cette version : crée un .zip du projet (dossier  <projet>_versions/ à côté du projet).
##  - Ouvrir dans un nouveau dossier : récupère une ancienne version sans toucher au projet.
##  - Remplacer le projet : revient VRAIMENT à l'ancienne version (l'état actuel est sauvegardé avant).
##  - Publier cette version : exporte le web + la mise à jour ordinateur (outils/publier_pc.gd).

const Outil := preload("res://addons/bol_versions/outil.gd")

var _dock: VBoxContainer
var _lbl_version: Label
var _liste: ItemList
var _etat: Label
var _obligatoire: CheckBox
var _complet: CheckBox
var _publier: Button


func _enter_tree() -> void:
	_dock = VBoxContainer.new()
	_dock.name = "Versions"
	_dock.add_theme_constant_override("separation", 6)

	_lbl_version = Label.new()
	_lbl_version.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_lbl_version)

	var sauver := Button.new()
	sauver.text = "Sauvegarder cette version"
	sauver.tooltip_text = "Crée une archive .zip de tout le projet (sauf .godot, .git et docs)."
	sauver.pressed.connect(_sauvegarder)
	_dock.add_child(sauver)

	var titre := Label.new()
	titre.text = "Versions sauvegardées :"
	_dock.add_child(titre)
	_liste = ItemList.new()
	_liste.custom_minimum_size = Vector2(0, 220)
	_liste.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dock.add_child(_liste)

	var ouvrir := Button.new()
	ouvrir.text = "Ouvrir dans un nouveau dossier (sans risque)"
	ouvrir.pressed.connect(_restaurer_a_cote)
	_dock.add_child(ouvrir)
	var remplacer := Button.new()
	remplacer.text = "Remplacer le projet par cette version"
	remplacer.pressed.connect(_demander_remplacement)
	_dock.add_child(remplacer)
	var dossier := Button.new()
	dossier.text = "Ouvrir le dossier des sauvegardes"
	dossier.pressed.connect(func():
		DirAccess.make_dir_recursive_absolute(Outil.dossier_versions())
		OS.shell_open(Outil.dossier_versions()))
	_dock.add_child(dossier)
	var actualiser := Button.new()
	actualiser.text = "Actualiser"
	actualiser.pressed.connect(_rafraichir)
	_dock.add_child(actualiser)

	_dock.add_child(HSeparator.new())
	var titre_pub := Label.new()
	titre_pub.text = "Publier (web + Windows/Mac) :"
	_dock.add_child(titre_pub)
	_obligatoire = CheckBox.new()
	_obligatoire.text = "Mise à jour obligatoire"
	_obligatoire.tooltip_text = "Les joueurs devront installer cette version pour continuer (à cocher si l'Arène ou le serveur ont changé)."
	_dock.add_child(_obligatoire)
	_complet = CheckBox.new()
	_complet.text = "Refaire les installations complètes"
	_complet.tooltip_text = "Automatique si Godot ou les réglages du projet ont changé. À cocher seulement pour forcer."
	_dock.add_child(_complet)
	_publier = Button.new()
	_publier.text = "Publier cette version"
	_publier.tooltip_text = "Exporte le jeu web (docs/), la mise à jour ordinateur (docs/maj/) et, si besoin, les installations complètes (build/). Ensuite : Commit + Push dans GitHub Desktop."
	_publier.pressed.connect(_publier_version)
	_dock.add_child(_publier)

	_etat = Label.new()
	_etat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dock.add_child(_etat)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_rafraichir()


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()


func _rafraichir() -> void:
	_lbl_version.text = "Version du projet : v%s\n(modifiable dans scripts/version.gd)" % Outil.version_actuelle()
	_liste.clear()
	for f in Outil.liste_sauvegardes():
		_liste.add_item(f)


func _selection() -> String:
	var s := _liste.get_selected_items()
	if s.is_empty():
		_etat.text = "Choisis d'abord une version dans la liste."
		return ""
	return _liste.get_item_text(s[0])


func _sauvegarder() -> void:
	EditorInterface.save_all_scenes()
	var chemin := Outil.sauvegarder()
	_etat.text = ("Version sauvegardée :\n" + chemin.get_file()) if chemin != "" else "Erreur pendant la sauvegarde."
	_rafraichir()


func _restaurer_a_cote() -> void:
	var nom := _selection()
	if nom == "":
		return
	var dest := Outil.restaurer_a_cote(nom)
	if dest == "":
		_etat.text = "Impossible d'extraire cette version."
		return
	_etat.text = "Ancienne version extraite dans :\n%s\n\nDans le Gestionnaire de projets Godot : Importer -> choisis le fichier project.godot de ce dossier." % dest
	OS.shell_open(dest)


func _demander_remplacement() -> void:
	var nom := _selection()
	if nom == "":
		return
	var d := ConfirmationDialog.new()
	d.title = "Revenir à une ancienne version"
	d.dialog_text = "Remplacer TOUT le projet par :\n%s ?\n\nL'état actuel sera d'abord sauvegardé automatiquement (fichier « avant_retour »),\ntu pourras donc revenir en arrière.\nL'éditeur redémarrera ensuite." % nom
	d.ok_button_text = "Remplacer"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		EditorInterface.save_all_scenes()
		var secours := Outil.remplacer_projet(nom)
		if secours == "":
			_etat.text = "Échec : la sauvegarde de sécurité n'a pas pu être créée. Rien n'a été modifié."
			return
		_etat.text = "Projet remplacé. Sauvegarde de sécurité : " + secours.get_file()
		EditorInterface.restart_editor(false))
	d.canceled.connect(d.queue_free)
	EditorInterface.get_base_control().add_child(d)
	d.popup_centered()


func _publier_version() -> void:
	EditorInterface.save_all_scenes()
	_publier.disabled = true
	_etat.text = "Publication de la v%s en cours… (une à trois minutes, l'éditeur ne répond pas pendant ce temps)" % Outil.version_actuelle()
	await get_tree().process_frame
	await get_tree().process_frame
	var options := ["--headless", "--path", Outil.dossier_projet(), "-s", "res://outils/publier_pc.gd", "--"]
	if _obligatoire.button_pressed:
		options.append("--obligatoire")
	if _complet.button_pressed:
		options.append("--complet")
	var sortie := []
	var code := OS.execute(OS.get_executable_path(), options, sortie, true)
	var lignes := []
	for l in "\n".join(sortie).split("\n"):
		if l.begins_with("===") or l.begins_with("- ") or l.begins_with("À faire") or l.begins_with("INSTALL") \
				or l.begins_with("  ") or l.begins_with("Mise à jour") or l.begins_with("ÉCHEC") or l.begins_with("ATTENTION"):
			lignes.append(l)
	_etat.text = ("\n".join(lignes) if not lignes.is_empty() else "\n".join(sortie).right(1500))
	if code != 0 and lignes.is_empty():
		_etat.text = "Échec de la publication :\n" + _etat.text
	_obligatoire.button_pressed = false
	_complet.button_pressed = false
	_publier.disabled = false
	if code == 0 and DirAccess.dir_exists_absolute(Outil.dossier_projet() + "/build") and _etat.text.contains("INSTALLATION COMPLÈTE"):
		OS.shell_open(Outil.dossier_projet() + "/build")
