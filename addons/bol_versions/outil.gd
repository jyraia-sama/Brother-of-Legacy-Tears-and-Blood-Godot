@tool
extends RefCounted
## Outils de l'extension « Versions du jeu » (utilisés par plugin.gd).
## Les sauvegardes sont rangées À CÔTÉ du projet, dans le dossier  <nom du projet>_versions/
## (jamais dans le projet lui-même, pour ne pas s'archiver soi-même).

## Dossiers jamais archivés ni effacés
const EXCLUS := [".godot", ".git", ".import", "docs", "build", "export", "exports", ".vs", ".vscode"]
const DOSSIER_EXTENSION := "addons/bol_versions"


## Dossier du projet (chemin système, sans / final).
static func dossier_projet() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/")


static func dossier_versions() -> String:
	var p := dossier_projet()
	return p.get_base_dir().path_join(p.get_file() + "_versions")


## Numéro de version lu dans scripts/version.gd (sans charger le script).
static func version_actuelle() -> String:
	var f := FileAccess.open("res://scripts/version.gd", FileAccess.READ)
	if f == null:
		return "0.0.0"
	var texte := f.get_as_text()
	var re := RegEx.new()
	re.compile("const NUMERO := \"([^\"]+)\"")
	var m := re.search(texte)
	return m.get_string(1) if m else "0.0.0"


static func _exclu(chemin_relatif: String) -> bool:
	var premier := chemin_relatif.split("/")[0]
	return premier in EXCLUS or premier.ends_with("_versions")


## Liste des fichiers du projet (chemins relatifs), sans les dossiers exclus.
static func fichiers_projet(dossier := "") -> PackedStringArray:
	var resultat := PackedStringArray()
	var base := dossier_projet().path_join(dossier) if dossier != "" else dossier_projet()
	var d := DirAccess.open(base)
	if d == null:
		return resultat
	d.include_hidden = true
	d.list_dir_begin()
	var nom := d.get_next()
	while nom != "":
		if nom != "." and nom != "..":
			var rel := dossier.path_join(nom) if dossier != "" else nom
			if not _exclu(rel):
				if d.current_is_dir():
					resultat.append_array(fichiers_projet(rel))
				else:
					resultat.append(rel)
		nom = d.get_next()
	d.list_dir_end()
	return resultat


## Crée une archive .zip du projet. Renvoie son chemin ("" en cas d'erreur).
static func sauvegarder(note := "") -> String:
	DirAccess.make_dir_recursive_absolute(dossier_versions())
	var t := Time.get_datetime_dict_from_system()
	var nom := "BoL_v%s_%04d-%02d-%02d_%02dh%02d%s.zip" % [version_actuelle(), t.year, t.month, t.day, t.hour, t.minute,
		("_" + note) if note != "" else ""]
	var chemin := dossier_versions().path_join(nom)
	var zip := ZIPPacker.new()
	if zip.open(chemin) != OK:
		push_error("Versions : impossible de créer " + chemin)
		return ""
	for rel in fichiers_projet():
		var donnees := FileAccess.get_file_as_bytes(dossier_projet().path_join(rel))
		zip.start_file(rel)
		zip.write_file(donnees)
		zip.close_file()
	zip.close()
	return chemin


## Archives existantes, les plus récentes d'abord.
static func liste_sauvegardes() -> PackedStringArray:
	var l := PackedStringArray()
	var d := DirAccess.open(dossier_versions())
	if d == null:
		return l
	for f in d.get_files():
		if f.ends_with(".zip"):
			l.append(f)
	l.sort()
	l.reverse()
	return l


## Extrait une archive dans un dossier (créé si besoin). Renvoie le nombre de fichiers extraits.
static func extraire(nom_zip: String, destination: String, sauf_extension := false) -> int:
	var zip := ZIPReader.new()
	if zip.open(dossier_versions().path_join(nom_zip)) != OK:
		push_error("Versions : archive illisible " + nom_zip)
		return -1
	var n := 0
	for rel in zip.get_files():
		if rel.ends_with("/"):
			continue
		if sauf_extension and rel.begins_with(DOSSIER_EXTENSION):
			continue
		var cible := destination.path_join(rel)
		DirAccess.make_dir_recursive_absolute(cible.get_base_dir())
		var f := FileAccess.open(cible, FileAccess.WRITE)
		if f == null:
			continue
		f.store_buffer(zip.read_file(rel))
		f.close()
		n += 1
	zip.close()
	return n


## Ouvre une ancienne version dans un NOUVEAU dossier à côté du projet (sans rien toucher au projet).
static func restaurer_a_cote(nom_zip: String) -> String:
	var dest := dossier_projet().get_base_dir().path_join(dossier_projet().get_file() + "_" + nom_zip.get_basename())
	if extraire(nom_zip, dest) < 0:
		return ""
	return dest


## Remplace le projet actuel par l'ancienne version.
## 1) sauvegarde automatique de l'état actuel ; 2) efface les fichiers du projet ; 3) extrait l'archive.
static func remplacer_projet(nom_zip: String) -> String:
	var secours := sauvegarder("avant_retour")
	if secours == "":
		return ""
	for rel in fichiers_projet():
		if rel.begins_with(DOSSIER_EXTENSION):
			continue
		DirAccess.remove_absolute(dossier_projet().path_join(rel))
	extraire(nom_zip, dossier_projet(), true)
	return secours
