class_name EcranQuetes
extends EcranBase
## QUÊTES : récompense de connexion, quêtes du jour et de la semaine. Règles : quetes.gd.

const SCENE := "res://scenes/quetes.tscn"
const C_JOUR := Color("ffb060")
const C_SEMAINE := Color("b08aff")
const C_OK := Color("8affa0")


func _fond_ecran() -> String:
	return "res://assets/fonds/quetes.png"


func _titre_ecran() -> String:
	return "QUÊTES"


func _remplir() -> void:
	_connexion()
	_periode("jour", "QUÊTES DU JOUR", UiCommun.t("Nouvelles quêtes dans %s") % Calendrier.texte_duree(Calendrier.secondes_avant_demain()), C_JOUR)
	_periode("semaine", "QUÊTES DE LA SEMAINE", UiCommun.t("Nouvelles quêtes dans %s") % Calendrier.texte_duree(Calendrier.secondes_avant_semaine()), C_SEMAINE)


func _connexion() -> void:
	_titre("RÉCOMPENSE DE CONNEXION")
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 8)
	_contenu.add_child(ligne)
	var suivant := Quetes.connexion_index()
	var dispo := Quetes.connexion_disponible()
	for i in Quetes.CONNEXION.size():
		var fait := i < suivant or (i == suivant and false)
		var aujourdhui := i == suivant
		var c := C_OK if (aujourdhui and dispo) else (UiCommun.C_OR if aujourdhui else Color(0.4, 0.35, 0.35))
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size = Vector2(0, 104)
		var st := UiCommun.style_panneau(c, Color(0.07, 0.03, 0.04, 0.92) if not fait else Color(0.03, 0.03, 0.03, 0.8))
		st.set_content_margin_all(8)
		if aujourdhui and dispo:
			st.shadow_color = Color(C_OK, 0.45)
			st.shadow_size = 10
		p.add_theme_stylebox_override("panel", st)
		ligne.add_child(p)
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		p.add_child(vb)
		var j := UiCommun.label(UiCommun.t("Jour %d%s") % [i + 1, "  ✔" if fait else ""], 16, c)
		j.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(j)
		var r := UiCommun.label(Quetes.texte_recompense(Quetes.CONNEXION[i]).replace(" · ", "\n"), 13, UiCommun.C_TEXTE if not fait else UiCommun.C_DOUX)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(r)
	var b := UiCommun.bouton(UiCommun.t("Réclamer la récompense du jour %d") % (suivant + 1) if dispo else "Déjà réclamée aujourd'hui — reviens demain !", 17)
	b.disabled = not dispo
	b.custom_minimum_size = Vector2(0, 52)
	UiCommun.bouton_vif(b)
	b.pressed.connect(func():
		_annoncer(Quetes.reclamer_connexion())
		rafraichir())
	_contenu.add_child(b)
	_contenu.add_child(HSeparator.new())


func _periode(periode: String, titre: String, reset: String, couleur: Color) -> void:
	var tete := HBoxContainer.new()
	_contenu.add_child(tete)
	var t := UiCommun.label(titre, 20, couleur)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	tete.add_child(UiCommun.label(reset, 14, UiCommun.C_DOUX))
	var liste := Quetes.liste(periode)
	for q in liste:
		var h := _ligne(C_OK.darkened(0.3) if (q["fait"] and not q["reclame"]) else couleur.darkened(0.55))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(vb)
		vb.add_child(UiCommun.label(("✔  " if q["reclame"] else "") + str(q["texte"]), 17, UiCommun.C_DOUX if q["reclame"] else UiCommun.C_TEXTE))
		vb.add_child(UiCommun.label("Récompense : " + Quetes.texte_recompense(q["recompense"]), 14, UiCommun.C_OR))
		var pb := VBoxContainer.new()
		pb.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_child(pb)
		pb.add_child(_barre(q["progres"], q["objectif"], C_OK if q["fait"] else couleur, 240))
		var lp := UiCommun.label("%d / %d" % [int(q["progres"]), int(q["objectif"])], 14, UiCommun.C_TEXTE)
		lp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pb.add_child(lp)
		var b := UiCommun.bouton("Réclamer" if not q["reclame"] else "Réclamée", 16)
		b.custom_minimum_size = Vector2(150, 44)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = q["reclame"] or not q["fait"]
		UiCommun.bouton_vif(b)            # vert vif et lumineux quand on peut réclamer
		var id: String = q["id"]
		b.pressed.connect(func():
			_annoncer(Quetes.reclamer(periode, id))
			rafraichir())
		h.add_child(b)
	# Bonus
	var bonus: Dictionary = Quetes.BONUS[periode]
	var dispo := Quetes.bonus_disponible(periode)
	var deja := Quetes.bonus_reclame(periode)
	var faites := liste.filter(func(x): return x["fait"]).size()
	var hb := _ligne(C_OK if dispo else Color("ffd060").darkened(0.4))
	var vbb := VBoxContainer.new()
	vbb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vbb)
	vbb.add_child(UiCommun.label(UiCommun.t("COFFRE BONUS  —  %s  (%d / %d)") % [bonus["texte"], faites, liste.size()], 17, Color("ffd060")))
	vbb.add_child(UiCommun.label("Récompense : " + Quetes.texte_recompense(bonus["recompense"]), 14, UiCommun.C_OR))
	var bb := UiCommun.bouton("Ouvrir le coffre" if not deja else "Ouvert", 16)
	bb.custom_minimum_size = Vector2(170, 44)
	bb.disabled = not dispo
	UiCommun.bouton_vif(bb, Color("c8901e"))     # coffre bonus : doré
	bb.pressed.connect(func():
		_annoncer(Quetes.reclamer(periode, "bonus"))
		rafraichir())
	hb.add_child(bb)
	_contenu.add_child(HSeparator.new())
