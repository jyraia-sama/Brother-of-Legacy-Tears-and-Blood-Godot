extends SceneTree
## PUBLIER UNE VERSION (web + ordinateur + Android).
## Lancé par le bouton « Publier cette version » de l'onglet Versions, ou à la main :
##   godot --headless --path . -s res://outils/publier_pc.gd
## Options (après « -- ») :
##   --obligatoire  : les joueurs doivent installer cette version pour continuer (Arène, etc.)
##   --complet      : refait aussi les installations complètes Windows, Mac et Linux (sinon : automatique
##                    quand le moteur Godot ou les réglages du projet ont changé)
##   --sans-web     : ne réexporte pas la version web (docs/index.*)
##   --android      : refait l'application Android (.apk) même sans installation complète
##   --linux        : refait l'installation Linux (.tar.gz) même sans installation complète
##   --garder-installation : n'impose pas de réinstallation même si l'empreinte a changé
##                    (à n'utiliser que si on est sûr que les applications déjà installées restent compatibles)
##
## Ce que fait l'outil :
##   1. recopie le numéro de scripts/version.gd dans les réglages du projet (application/config/version) ;
##   2. exporte la version web dans docs/ (sans les gros dossiers d'images, voir PAQUETS) ;
##   2b. fabrique les paquets d'images docs/paquets/<nom>.pck + docs/paquets/liste.json
##       (seuls les paquets dont une image a changé sont refaits : les joueurs ne retéléchargent qu'eux) ;
##   3. exporte le contenu du jeu pour ordinateur dans docs/maj/jeu.pck (la mise à jour rapide) ;
##   4. écrit la fiche docs/maj/version.json (numéro, nouveautés, taille, empreinte) ;
##   5. si besoin, crée les installations complètes dans build/ :
##        build/BrothersOfLegacy-Windows.zip, build/BrothersOfLegacy-Mac.zip et build/BrothersOfLegacy-Linux.tar.gz
##      (à déposer dans une « Release » GitHub nommée vX.Y.Z, voir GUIDE_VERSIONS.md) ;
##      et l'application Android dans build/BrothersOfLegacy-Android.apk (plus de 100 Mo : trop gros pour le
##      dépôt, elle se dépose dans la Release GitHub, à côté des fichiers Windows et Mac).
##      L'APK demande le kit Android et la clé de signature : s'ils manquent, il est simplement sauté.
## Il reste ensuite à faire le Commit + Push dans GitHub Desktop : les joueurs reçoivent la mise à jour.

const DEPOT := "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot"
const PRESET_WEB := "Web"
const PRESET_WINDOWS := "Windows Desktop"
const PRESET_MAC := "macOS"
const PRESET_ANDROID := "Android"
const PRESET_LINUX := "Linux"
const LINUX := "BrothersOfLegacy-Linux.tar.gz"
const SITE := "https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/"
const APK := "BrothersOfLegacy-Android.apk"
const NB_NOUVEAUTES := 15
## Gros dossiers d'images sortis du contenu de base et livrés à part (scripts/paquets.gd les télécharge).
## « seaux » : nombre de paquets entre lesquels le dossier est réparti (chaque image va toujours dans
## le même seau, d'après son nom). Si un paquet approche 90 Mo, augmente son nombre de seaux.
## Ces dossiers ne doivent pas être utilisés par l'écran de chargement ni par les scripts lancés au démarrage.
const PAQUETS := [
	{"nom": "figurines", "dossier": "assets/figurines", "seaux": 4},
	{"nom": "portraits", "dossier": "assets/unites", "seaux": 2},
	{"nom": "fonds", "dossier": "assets/fonds", "seaux": 1},
	{"nom": "actes", "dossier": "assets/actes", "seaux": 1},
	{"nom": "boss_monde", "dossier": "assets/boss_monde", "seaux": 1},
]

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

	if not _exclure_paquets_des_exports():
		_echec("impossible de modifier export_presets.cfg"); return
	DirAccess.make_dir_recursive_absolute(projet + "/docs/maj")
	DirAccess.make_dir_recursive_absolute(projet + "/build/windows")
	DirAccess.make_dir_recursive_absolute(projet + "/build/linux")
	_creer_fichier(projet + "/build/.gdignore", "")

	# 2. Version web
	if not "--sans-web" in args:
		print("- Export web…")
		if not _exporter(["--export-release", PRESET_WEB, projet + "/docs/index.html"]):
			_echec("l'export web a échoué"); return
		_completer_manifeste(numero)

	# 2b. Paquets d'images (après l'export web, qui a remis à jour les images importées)
	print("- Paquets d'images…")
	var poids_paquets := _fabriquer_paquets(numero)
	if poids_paquets < 0:
		_echec("la fabrication des paquets a échoué"); return

	# 3. Contenu du jeu pour ordinateur (Windows, Mac et Linux utilisent le même fichier)
	print("- Export du contenu ordinateur (jeu.pck)…")
	var pck := projet + "/docs/maj/jeu.pck"
	if not _exporter(["--export-pack", PRESET_WINDOWS, pck]):
		_echec("l'export du contenu (jeu.pck) a échoué"); return
	var taille := FileAccess.open(pck, FileAccess.READ).get_length()
	var empreinte_pck := FileAccess.get_sha256(pck)

	# 4. Installation complète nécessaire ? (moteur, réglages du projet ou système de mise à jour changés)
	var ancienne := _lire_json(projet + "/docs/maj/version.json")
	var empreinte_install := _empreinte_installation()
	var complet := "--complet" in args or (str(ancienne.get("empreinte_installation", "")) != empreinte_install \
			and not "--garder-installation" in args)
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

	var linux_refait := false
	if complet or "--linux" in args:
		print("- Installation complète Linux…")
		linux_refait = _exporter_linux()
		if not linux_refait:
			print("ATTENTION : installation Linux non refaite (modèles d'export Linux absents ?).")

	var apk_refait := false
	if complet or "--android" in args:
		print("- Application Android…")
		apk_refait = _exporter_android(numero)
		if not apk_refait:
			print("ATTENTION : APK Android non refait (kit Android ou clé de signature absents sur cet ordinateur).")
			print("  Les téléphones gardent l'ancienne application ; demande à Claude de refaire l'APK.")

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
			"linux": "%s/releases/latest/download/%s" % [DEPOT, LINUX],
			"android": "%s/releases/latest/download/%s" % [DEPOT, APK],
		},
		"nouveautes": nouveautes,
	}
	_creer_fichier(projet + "/docs/maj/version.json", JSON.stringify(fiche, "\t"))

	print("")
	print("=== v%s publiée localement (contenu de base : %.1f Mo, paquets d'images : %.1f Mo) ===" % [
		numero, taille / 1048576.0, poids_paquets / 1048576.0])
	print("À faire : GitHub Desktop -> Commit « v%s — … » -> Push origin." % numero)
	if complet:
		print("INSTALLATION COMPLÈTE CRÉÉE : sur GitHub, crée une Release « v%s » et dépose-y" % numero)
		print("  build/BrothersOfLegacy-Windows.zip et build/BrothersOfLegacy-Mac.zip")
		print("  (les joueurs devront réinstaller : le jeu leur proposera le téléchargement).")
	else:
		print("Mise à jour rapide : les joueurs la recevront au prochain lancement du jeu.")
	if linux_refait:
		print("Installation Linux prête : build/%s -> à déposer dans la Release GitHub." % LINUX)
	if apk_refait:
		print("Application Android prête : build/%s -> à déposer dans la Release GitHub." % APK)
	if version_minimum == numero:
		print("Mise à jour OBLIGATOIRE.")
	quit(0)


# ---------------------------------------------------------------------

## Range chaque dossier de PAQUETS dans le filtre « exclure » des 5 exports (web, Windows, Mac, Android, Linux).
func _exclure_paquets_des_exports() -> bool:
	var filtres: Array = []
	for p in PAQUETS:
		filtres.append(str(p.dossier) + "/*")
	var chemin := projet + "/export_presets.cfg"
	var texte := FileAccess.get_file_as_string(chemin)
	if texte == "":
		return false
	var re := RegEx.new()
	re.compile("(?m)^exclude_filter=.*$")
	var nouveau := re.sub(texte, "exclude_filter=\"%s\"" % ", ".join(filtres), true)
	return nouveau == texte or _creer_fichier(chemin, nouveau)


## Fabrique docs/paquets/*.pck et docs/paquets/liste.json. Renvoie le poids total (-1 en cas d'échec).
## Un paquet n'est refait que si ses images (ou leurs réglages d'import) ont changé : sa « signature »
## dépend des fichiers sources, pas de l'ordinateur qui publie.
func _fabriquer_paquets(numero: String) -> int:
	var dossier := projet + "/docs/paquets"
	DirAccess.make_dir_recursive_absolute(dossier)
	var ancienne := _lire_json(dossier + "/liste.json")
	var anciens := {}
	for e in ancienne.get("paquets", []):
		anciens[str(e.get("nom", ""))] = e
	var liste: Array = []
	var total := 0
	for p in PAQUETS:
		var seaux := int(p.seaux)
		var groupes: Array = []
		for i in seaux:
			groupes.append([])
		var d := DirAccess.open(projet + "/" + str(p.dossier))
		if d == null:
			continue
		var fichiers := Array(d.get_files())
		fichiers.sort()
		for f in fichiers:
			if not str(f).ends_with(".import"):
				continue
			var source: String = str(p.dossier) + "/" + str(f).trim_suffix(".import")
			var i: int = source.get_file().get_basename().md5_text().substr(0, 2).hex_to_int() % seaux
			groupes[i].append(source)
		for i in seaux:
			if groupes[i].is_empty():
				continue
			var nom := str(p.nom) if seaux == 1 else "%s_%d" % [p.nom, i]
			var signature := _signature(groupes[i])
			var fichier := nom + ".pck"
			var a: Dictionary = anciens.get(nom, {})
			var chemin := dossier + "/" + fichier
			if str(a.get("signature", "")) == signature and FileAccess.file_exists(chemin) \
					and FileAccess.get_sha256(chemin) == str(a.get("sha256", "")):
				liste.append(a)
				total += int(a.get("taille", 0))
				continue
			if not _ecrire_paquet(chemin, groupes[i]):
				return -1
			var taille := FileAccess.open(chemin, FileAccess.READ).get_length()
			print("    paquet %s refait (%d images, %.1f Mo)" % [nom, groupes[i].size(), taille / 1048576.0])
			if taille > 90 * 1048576:
				print("ATTENTION : le paquet %s dépasse 90 Mo : augmente ses « seaux » dans PAQUETS." % nom)
			liste.append({"nom": nom, "fichier": fichier, "taille": taille, "sha256": FileAccess.get_sha256(chemin),
				"signature": signature, "images": groupes[i].size(), "depuis": numero})
			total += taille
	# Efface les paquets qui n'existent plus
	var garder := {}
	for e in liste:
		garder[str(e.fichier)] = true
	var dd := DirAccess.open(dossier)
	for f in dd.get_files():
		if f.ends_with(".pck") and not garder.has(f):
			dd.remove(f)
	_creer_fichier(dossier + "/liste.json", JSON.stringify({"version": numero, "paquets": liste}, "\t"))
	return total


func _signature(sources: Array) -> String:
	var t := ""
	for s in sources:
		t += "%s|%s|%s\n" % [s, FileAccess.get_sha256(projet + "/" + s), FileAccess.get_sha256(projet + "/" + s + ".import")]
	return t.sha256_text()


## Écrit un paquet Godot avec, pour chaque image : son fichier .import et l'image importée (.godot/imported).
func _ecrire_paquet(chemin: String, sources: Array) -> bool:
	var pk := PCKPacker.new()
	if pk.pck_start(chemin) != OK:
		print("    impossible de créer " + chemin)
		return false
	for s in sources:
		var cfg := ConfigFile.new()
		if cfg.load(projet + "/" + s + ".import") != OK:
			print("    import illisible : " + s)
			return false
		pk.add_file("res://" + s + ".import", projet + "/" + s + ".import")
		var dest: Array = cfg.get_value("deps", "dest_files", [])
		if dest.is_empty():
			dest = [cfg.get_value("remap", "path", "")]
		for f in dest:
			var reel := projet + "/" + str(f).trim_prefix("res://")
			if not FileAccess.file_exists(reel):
				print("    image pas encore importée : %s (ouvre le projet dans Godot ou lance --import)" % s)
				return false
			pk.add_file(str(f), reel)
	return pk.flush() == OK


## Complète le manifeste de l'appli web écrit par Godot : icône 192 px (exigée par Android pour
## « Installer l'application », sinon le jeu s'ouvre dans un onglet avec la barre du navigateur),
## nom court, identifiant, couleurs. Les icônes portent le numéro de version (rafraîchissement).
func _completer_manifeste(numero: String) -> void:
	var img := Image.load_from_file(projet + "/assets/pwa/icone_512.png")
	if img:
		img.resize(192, 192, Image.INTERPOLATE_LANCZOS)
		img.save_png(projet + "/docs/index.192x192.png")
	var m := _lire_json(projet + "/docs/index.manifest.json")
	m["id"] = "./index.html"
	m["name"] = "Brothers of Legacy : Tears and Blood"
	m["short_name"] = "Brothers of Legacy"
	m["start_url"] = "./index.html"
	m["scope"] = "./"
	m["display"] = "fullscreen"
	m["display_override"] = ["fullscreen", "standalone"]
	m["orientation"] = "landscape"
	m["background_color"] = "#07040a"
	m["theme_color"] = "#07040a"
	var icones: Array = []
	for t in [144, 180, 192, 512]:
		icones.append({"src": "index.%dx%d.png?v=%s" % [t, t, numero], "sizes": "%dx%d" % [t, t], "type": "image/png", "purpose": "any"})
	m["icons"] = icones
	_creer_fichier(projet + "/docs/index.manifest.json", JSON.stringify(m, "\t"))


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
func _exporter_android(numero: String) -> bool:
	# Numéro de version Android : doit toujours augmenter (0.36.2 -> 3602)
	var p := numero.split(".")
	var code := 0
	for i in 3:
		code = code * 100 + (p[i].to_int() if i < p.size() else 0)
	var chemin := projet + "/export_presets.cfg"
	var texte := FileAccess.get_file_as_string(chemin)
	var re := RegEx.new()
	re.compile("(?m)^version/code=\\d+$")
	if re.search(texte):
		_creer_fichier(chemin, re.sub(texte, "version/code=%d" % maxi(code, 1)))
	var sortie := projet + "/build/BrothersOfLegacy-Android.apk"
	if FileAccess.file_exists(sortie):
		DirAccess.remove_absolute(sortie)
	# Plus de 100 Mo : l'APK reste dans build/ et se dépose dans la Release GitHub.
	return _exporter(["--export-release", PRESET_ANDROID, sortie]) and FileAccess.file_exists(sortie)


func _empreinte_installation() -> String:
	# On ignore le numéro de version et les extensions de l'éditeur (sans effet sur le jeu installé).
	var lignes := []
	var section := ""
	for l in FileAccess.get_file_as_string(projet + "/project.godot").split("\n"):
		l = l.strip_edges(false, true)
		if l.begins_with("["):
			section = l
		if section == "[editor_plugins]" or l.begins_with("config/version="):
			continue
		lignes.append(l)
	var texte := "\n".join(lignes).strip_edges()
	var re := RegEx.new()
	re.compile("const VERSION_SYSTEME := (\\d+)")
	var m := re.search(FileAccess.get_file_as_string(projet + "/scripts/mise_a_jour.gd"))
	texte += "systeme=" + (m.get_string(1) if m else "0")
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


## Exporte le jeu Linux et l'emballe dans build/BrothersOfLegacy-Linux.tar.gz.
## Un .tar.gz (et pas un .zip) : c'est le seul format qui garde le droit « exécutable » du jeu,
## le joueur n'a ainsi qu'à décompresser puis double-cliquer.
func _exporter_linux() -> bool:
	var bin := projet + "/build/linux/BrothersOfLegacy.x86_64"
	if FileAccess.file_exists(bin):
		DirAccess.remove_absolute(bin)
	if not _exporter(["--export-release", PRESET_LINUX, bin]) or not FileAccess.file_exists(bin):
		return false
	return _tar_gz(bin, projet + "/build/" + LINUX, "Brothers of Legacy/BrothersOfLegacy.x86_64")


## Archive .tar.gz d'un seul fichier, marqué exécutable (droits 755).
func _tar_gz(source: String, archive: String, nom_dans_archive: String) -> bool:
	var donnees := FileAccess.get_file_as_bytes(source)
	if donnees.is_empty():
		return false
	var dossier := nom_dans_archive.get_base_dir() + "/"
	var tar := PackedByteArray()
	tar.append_array(_entete_tar(dossier, 0, "5"))
	tar.append_array(_entete_tar(nom_dans_archive, donnees.size(), "0"))
	tar.append_array(donnees)
	var reste := donnees.size() % 512
	if reste != 0:
		var bourrage := PackedByteArray()
		bourrage.resize(512 - reste)
		tar.append_array(bourrage)
	var fin := PackedByteArray()
	fin.resize(1024)
	tar.append_array(fin)
	var gz := tar.compress(FileAccess.COMPRESSION_GZIP)
	var f := FileAccess.open(archive, FileAccess.WRITE)
	if f == null or gz.is_empty():
		return false
	f.store_buffer(gz)
	f.close()
	return true


## En-tête « ustar » de 512 octets (les cases non écrites restent à zéro). type "0" = fichier, "5" = dossier.
func _entete_tar(nom: String, taille: int, type: String) -> PackedByteArray:
	var h := PackedByteArray()
	h.resize(512)
	h = _poser(h, 0, nom)
	h = _poser(h, 100, "0000755")
	h = _poser(h, 108, "0000000")
	h = _poser(h, 116, "0000000")
	h = _poser(h, 124, "%011o" % taille)
	h = _poser(h, 136, "%011o" % int(Time.get_unix_time_from_system()))
	h = _poser(h, 148, "        ")
	h = _poser(h, 156, type)
	h = _poser(h, 257, "ustar")
	h = _poser(h, 263, "00")
	h = _poser(h, 265, "joueur")
	h = _poser(h, 297, "joueur")
	var somme := 0
	for o in h:
		somme += o
	h = _poser(h, 148, "%06o" % somme)
	h[154] = 0
	h[155] = 32
	return h


## Écrit un texte dans l'en-tête à partir de la case « debut » (un tableau d'octets se copie :
## on renvoie le tableau modifié).
func _poser(h: PackedByteArray, debut: int, texte: String) -> PackedByteArray:
	var o := texte.to_utf8_buffer()
	for i in o.size():
		h[debut + i] = o[i]
	return h


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
