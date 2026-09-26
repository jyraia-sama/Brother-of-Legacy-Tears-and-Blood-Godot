@tool
extends EditorPlugin
## Onglet « Versions » dans l'éditeur Godot (à droite, à côté de l'Inspecteur).
##  - Sauvegarder cette version : crée un .zip du projet (dossier  <projet>_versions/ à côté du projet).
##  - Ouvrir dans un nouveau dossier : récupère une ancienne version sans toucher au projet.
##  - Remplacer le projet : revient VRAIMENT à l'ancienne version (l'état actuel est sauvegardé avant).

const Outil := preload("res://addons/bol_versions/outil.gd")

var _dock: VBoxContainer
var _lbl_version: Label
var _liste: ItemList
var _etat: Label


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
