-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — profil public détaillé
--  Étape 6 : la « vitrine » de chaque joueur (titre, héros principal, équipe,
--            statistiques, collection) visible quand on ouvre son profil,
--            avec ses résultats d'Arène, d'Arène classée et de Marche Maudite.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, APRÈS les fichiers 01 à 05. Peut être relancé sans danger.
-- =====================================================================

-- La vitrine est envoyée par le jeu du joueur lui-même (lecture seule pour les autres).
alter table public.profils add column if not exists vitrine jsonb not null default '{}'::jsonb;
alter table public.profils drop constraint if exists profils_vitrine_taille;
alter table public.profils add constraint profils_vitrine_taille check (pg_column_size(vitrine) < 20000);
grant update (vitrine) on public.profils to authenticated;


-- Fiche complète d'un joueur.
create or replace function public.profil_joueur(p_joueur uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('id', p.id, 'pseudo', p.pseudo, 'niveau', p.niveau,
		'heros_vitrine', p.heros_vitrine, 'vu_le', p.vu_le, 'cree_le', p.cree_le,
		'vitrine', p.vitrine,
		'guilde', coalesce((select g.nom from public.guilde_membres m join public.guildes g on g.id = m.guilde where m.joueur = p.id), ''),
		'role', coalesce((select m.role from public.guilde_membres m where m.joueur = p.id), ''),
		'arene', coalesce((select jsonb_build_object('points', a.points, 'victoires', a.victoires, 'defaites', a.defaites,
			'puissance', a.puissance, 'equipe', a.equipe)
			from public.arene_joueurs a where a.joueur = p.id), '{}'::jsonb),
		'classee', coalesce((select jsonb_build_object('points', c.points, 'victoires', c.victoires, 'defaites', c.defaites,
			'egalites', c.egalites)
			from public.ac_joueurs c where c.joueur = p.id), '{}'::jsonb),
		'marche_record', coalesce((select max(m.score) from public.marche_scores m where m.joueur = p.id), 0))
	from public.profils p where p.id = p_joueur;
$$;

grant execute on function public.profil_joueur(uuid) to authenticated;
