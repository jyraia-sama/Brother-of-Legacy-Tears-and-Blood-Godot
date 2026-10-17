class_name FicheSorts
extends RefCounted
## Section « SORTS » de la fiche d'un héros (Deck, Mon héros) : chaque sort avec son niveau,
## ce que donne le niveau, sa description et le bouton « Améliorer » (voir sorts_niveaux.gd).
##
##   FicheSorts.remplir(conteneur, uid, apres_changement)   # apres_changement : Callable sans argument


static func remplir(parent: Control, uid: int, apres_changement: Callable) -> void:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return
	var u := UnitesData.get_unite(h["id"])
	var maxi := SortsNiveaux.niveau_max(h)
	parent.add_child(UiCommun.titre_section("SORTS", UiCommun.C_OR, 18))
	var poss := UiCommun.label(UiCommun.t("Pages de Grimoire : %d   ·   Grimoires Interdits : %d   ·   niveau max des sorts : %d (%s)") % [
		Sauvegarde.get_objet(SortsNiveaux.PAGE), Sauvegarde.get_objet(SortsNiveaux.GRIMOIRE), maxi,
		Fusion.texte_etoiles(Fusion.etoiles(h))], 13, UiCommun.C_DOUX)
	poss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(poss)
	var skills: Array = u.get("skills", [])
	for i in skills.size():
		var sk: Dictionary = skills[i]
		var appris := SortsNiveaux.est_appris(h, sk)
		var n := SortsNiveaux.niveau(h, i)
		var bloc := VBoxContainer.new()
		bloc.add_theme_constant_override("separation", 2)
		parent.add_child(bloc)
		var tete := HBoxContainer.new()
		tete.add_theme_constant_override("separation", 10)
		bloc.add_child(tete)
		var titre := UiCommun.label("%s  (%s)" % [sk["nom"], "actif" if sk["type"] == "actif" else "passif"], 17,
			UiCommun.C_OR if appris else UiCommun.C_DOUX)
		titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tete.add_child(titre)
		if appris:
			var raison := SortsNiveaux.raison_impossible(uid, i)
			var b := UiCommun.bouton("", 14)
			if n >= SortsNiveaux.NIVEAU_MAX:
				b.text = "MAX"
			elif n >= maxi:
				b.text = UiCommun.t("Étoile requise")
			else:
				b.text = UiCommun.t("Améliorer")
			b.disabled = raison != ""
			b.tooltip_text = raison if raison != "" else UiCommun.t("Passer au niveau %d : effets +%d %%.") % [n + 1,
				int(round((SortsNiveaux.multiplicateur(n + 1) - 1.0) * 100))]
			b.custom_minimum_size = Vector2(0, 34)
			var index := i
			b.pressed.connect(func():
				var nouveau := SortsNiveaux.ameliorer(uid, index)
				if nouveau > 0:
					Audio.son("coffre")
					apres_changement.call())
			tete.add_child(b)
			if n < maxi:
				var cout := UiCommun.label(UiCommun.t("Niveau %d → %d : %s") % [n, n + 1,
					Reliquaire.texte_cout(SortsNiveaux.cout(n), SortsNiveaux.cout_or(n))], 13, UiCommun.C_DOUX)
				cout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				bloc.add_child(cout)
			# Raison écrite en clair sous le titre (sur téléphone, les info-bulles n'existent pas)
			if raison != "" and n < SortsNiveaux.NIVEAU_MAX:
				var pourquoi := UiCommun.label("⚠ " + raison, 13, Color("ff9a6a"))
				pourquoi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				bloc.add_child(pourquoi)
		var ligne := UiCommun.label(SortsNiveaux.resume(sk, n, maxi) if appris else UiCommun.t("Pas encore appris : le héros l'apprend au niveau %d (il est niveau %d)") % [int(sk["niveau"]), int(h["niveau"])],
			14, Color("ffd060") if appris else UiCommun.C_DOUX)
		ligne.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloc.add_child(ligne)
		var d := UiCommun.label(str(sk["description"]), 14, UiCommun.C_TEXTE if appris else UiCommun.C_DOUX)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloc.add_child(d)
		if appris and n > 1:
			var bonus := UiCommun.label(UiCommun.t("(valeurs de la description +%d %% grâce au niveau du sort)") %
				int(round((SortsNiveaux.multiplicateur(n) - 1.0) * 100)), 12, Color("8affa0"))
			bloc.add_child(bonus)
