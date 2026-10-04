extends SceneTree
## PUBLIER UNE VERSION (web + ordinateur).
## Lancé par le bouton « Publier cette version » de l'onglet Versions, ou à la main :
##   godot --headless --path . -s res://outils/publier_pc.gd
## Options (après « -- ») :
##   --obligatoire  : les joueurs doivent installer cette version pour continuer (Arène, etc.)
##   --complet      : refait aussi les installations complètes Windows et Mac (sinon : automatique
##                    quand le moteur Godot ou les réglages du projet ont changé)
##   --sans-web     : ne réexporte pas la version web (docs/index.*)
##
## Ce que fait l'outil :
##   1. recopie le numéro de scripts/version.gd dans les réglages du projet (application/config/version) ;
##   2. exporte la version web dans docs/ ;
##   3. exporte le contenu du jeu pour ordinateur dans docs/maj/jeu.pck (la mise à jour rapide) ;
##   4. écrit la fiche docs/maj/version.json (numéro, nouveautés, taille, empreinte) ;
##   5. si besoin, crée les installations complètes dans build/ :
##        build/BrothersOfLegacy-Windows.zip et build/BrothersOfLegacy-Mac.zip
##      (à déposer dans une « Release » GitHub nommée vX.Y.Z, voir GUIDE_VERSIONS.md).
## Il reste ensuite à faire le Commit + Push dans GitHub Desktop : les joueurs reçoivent la mise à jour.

const DEPOT := "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot"
const PRESET_WEB := "Web"
const PRESET_WINDOWS := "Windows Desktop"
const PRESET_MAC := "macOS"
const NB_NOUVEAUTES := 15

var projet := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	projet = ProjectSettings.globalize_path("res://").trim_suffix("/")
	var V = load("res://scripts/version.gd")
	var numero: String = V.NUMERO
	print("=== Publication de la version v%s ===" % numero)
	if V.HISTORIQUE.is_empty() or str(V.HISTORIQUE[0].get("version", "")) != numero:
		print("ATTENTION : la première entrée de HISTORIQUE (scripts/version.gd) n'est pas v%s." % numero)

	# 1. Numéro de version dans project.godot (lu par l'application installée)
	if not _ecrire_version_projet(numero):
		_echec("impossible de modifier project.godot"); return

	DirAccess.make_dir_recursive_absolute(projet + "/docs/maj")
	DirAccess.make_dir_recursive_absolute(projet + "/build/windows")
	_creer_fichier(projet + "/build/.gdignore", "")

	# 2. Version web
	if not "--sans-web" in args:
		print("- Export web…")
		if not _exporter(["--export-release", PRESET_WEB, projet + "/docs/index.html"]):
			_echec("l'export web a échoué"); return

	# 3. Contenu du jeu pour ordinateur (Windows et Mac utilisent le même fichier)
	print("- Export du contenu ordinateur (jeu.pck)…")
	var pck := projet + "/docs/maj/jeu.pck"
	if not _exporter(["--export-pack", PRESET_WINDOWS, pck]):
		_echec("l'export du contenu (jeu.pck) a échoué"); return
	var taille := FileAccess.open(pck, FileAccess.READ).get_length()
	var empreinte_pck := FileAccess.get_sha256(pck)

	# 4. Installation complète nécessaire ? (moteur, réglages du projet ou système de mise à jour changés)
	var ancienne := _lire_json(projet + "/docs/maj/version.json")
	var empreinte_install := _empreinte_installation()
	var complet := "--complet" in args or str(ancienne.get("empreinte_installation", "")) != empreinte_install
	var installation_minimum := numero if complet else str(ancienne.get("installation_minimum", numero))
	var version_minimum := numero if "--obligatoire" in args else str(ancienne.get("version_minimum", ""))

	if complet:
		print("- Installation complète Windows…")
		var exe := projet + "/build/windows/BrothersOfLegacy.exe"
		if not _exporter(["--export-release", PRESET_WINDOWS, exe]):
			_echec("l'export Windows a échoué (modèles d'export installés ?)"); return
		if not _zipper(exe, projet + "/build/BrothersOfLegacy-Windows.zip", "Brothers of Legacy/BrothersOfLegacy.exe"):
			_echec("impossible de créer le zip Windows"); return
		print("- Installation complète Mac…")
		if not _exporter(["--export-release", PRESET_MAC, projet + "/build/BrothersOfLegacy-Mac.zip"]):
			_echec("l'export Mac a échoué (modèles d'export installés ?)"); return

	# 5. Fiche de version lue par le jeu
	var nouveautes: Array = []
	for i in mini(NB_NOUVEAUTES, V.HISTORIQUE.size()):
		var h: Dictionary = V.HISTORIQUE[i]
		nouveautes.append({"version": h.get("version", ""), "titre": h.get("titre", ""), "changements": h.get("changements", [])})
	var fiche := {
		"version": numero,
		"date": V.DATE,
		"godot": _version_moteur(),
		"pck": {"url": "jeu.pck", "taille": taille, "sha256": empreinte_pck},
		"installation_minimum": installation_minimum,
		"empreinte_installation": empreinte_install,
		"version_minimum": version_minimum,
		"installations": {
			"windows": "%s/releases/download/v%s/BrothersOfLegacy-Windows.zip" % [DEPOT, installation_minimum],
			"macos": "%s/releases/download/v%s/BrothersOfLegacy-Mac.zip" % [DEPOT, installation_minimum],
		},
		"nouveautes": nouveautes,
	}
	_creer_fichier(projet + "/docs/maj/version.json", JSON.stringify(fiche, "\t"))

	print("")
	print("=== v%s publiée localement (contenu : %.1f Mo) ===" % [numero, taille / 1048576.0])
	print("À faire : GitHub Desktop -> Commit « v%s — … » -> Push origin." % numero)
	if complet:
		print("INSTALLATION COMPLÈTE CRÉÉE : sur GitHub, crée une Release « v%s » et dépose-y" % numero)
		print("  build/BrothersOfLegacy-Windows.zip et build/BrothersOfLegacy-Mac.zip")
		print("  (les joueurs devront réinstaller : le jeu leur proposera le téléchargement).")
	else:
		print("Mise à jour rapide : les joueurs la recevront au prochain lancement du jeu.")
	if version_minimum == numero:
		print("Mise à jour OBLIGATOIRE.")
	quit(0)


# ---------------------------------------------------------------------

func _exporter(arguments: Array) -> bool:
	var sortie := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", projet] + arguments, sortie, true)
	var texte := "\n".join(sortie)
	if code != 0 or "ERROR: Project export" in texte or "Cannot export project" in texte:
		print(texte.right(3000))
		return false
	return true


## Empreinte de ce qui ne peut changer qu'avec une installation complète :
## réglages du projet (hors numéro de version), système de mise à jour, moteur Godot.
func _empreinte_installation() -> String:
	var lignes := []
	for l in FileAccess.get_file_as_string(projet + "/project.godot").split("\n"):
		if not l.begins_with("config/version="):
			lignes.append(l.strip_edges(false, true))
	var texte := "\n".join(lignes).strip_edges()
	texte += FileAccess.get_file_as_string(projet + "/scripts/mise_a_jour.gd").replace("\r", "")
	texte += _version_moteur()
	return texte.sha256_text()


func _ecrire_version_projet(numero: String) -> bool:
	var chemin := projet + "/project.godot"
	var texte := FileAccess.get_file_as_string(chemin)
	if texte == "":
		return false
	var re := RegEx.new()
	re.compile("(?m)^config/version=.*$")
	var ligne := "config/version=\"%s\"" % numero
	if re.search(texte):
		texte = re.sub(texte, ligne)
	else:
		texte = texte.replace("[application]\n", "[application]\n\n" + ligne + "\n").replace("[application]\n\n\n", "[application]\n\n")
	return _creer_fichier(chemin, texte)


func _zipper(source: String, zip: String, nom_dans_zip: String) -> bool:
	var z := ZIPPacker.new()
	if z.open(zip) != OK:
		return false
	z.start_file(nom_dans_zip)
	z.write_file(FileAccess.get_file_as_bytes(source))
	z.close_file()
	z.close()
	return true


func _version_moteur() -> String:
	var e := Engine.get_version_info()
	return "%d.%d" % [e.major, e.minor]


func _lire_json(chemin: String) -> Dictionary:
	if not FileAccess.file_exists(chemin):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	return d if d is Dictionary else {}


func _creer_fichier(chemin: String, texte: String) -> bool:
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(texte)
	f.close()
	return true


func _echec(message: String) -> void:
	print("ÉCHEC : " + message)
	quit(1)
