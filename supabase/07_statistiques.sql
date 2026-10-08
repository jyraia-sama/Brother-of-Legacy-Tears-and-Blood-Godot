-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — statistiques du jeu (v0.53)
--  Onglet « Statistiques du jeu » du menu Admin, réservé au compte du créateur.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, après les fichiers 01 à 06. Peut être relancé sans danger.
--
--  Sécurité : le code du jeu est public. La vérification « est-ce bien le créateur ? »
--  se fait donc ICI, sur le serveur : stats_jeu() refuse de répondre à tout autre compte,
--  même si quelqu'un modifiait le jeu pour afficher l'onglet.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. ADMINISTRATEURS DES STATISTIQUES
-- ---------------------------------------------------------------------
create table if not exists public.stats_admins (
	id uuid primary key references auth.users (id) on delete cascade
);
alter table public.stats_admins enable row level security;
revoke all on public.stats_admins from anon, authenticated;     -- personne ne lit ni n'écrit directement

-- ▼▼▼ Le compte du créateur. Si ton pseudo n'est pas « jyraia », remplace-le ici et relance. ▼▼▼
insert into public.stats_admins (id)
	select id from public.profils where lower(pseudo) = lower('jyraia')
	on conflict do nothing;

create or replace function public.est_admin_stats() returns boolean
language sql stable security definer set search_path = public as $$
	select exists (select 1 from public.stats_admins where id = auth.uid());
$$;
revoke all on function public.est_admin_stats() from public, anon;
grant execute on function public.est_admin_stats() to authenticated;


-- ---------------------------------------------------------------------
-- 2. INSTALLATIONS : chaque appareil qui lance le jeu (anonyme)
--    Un identifiant tiré au hasard sur l'appareil, la plateforme et la version.
--    Rien de personnel. Le compte n'est relié que si le joueur est connecté.
-- ---------------------------------------------------------------------
create table if not exists public.installations (
	id                 uuid primary key,
	plateforme         text not null,
	version            text not null default '',
	joueur             uuid references auth.users (id) on delete set null,
	premier_lancement  timestamptz not null default now(),
	dernier_lancement  timestamptz not null default now(),
	lancements         int  not null default 1
);
create index if not exists installations_dernier on public.installations (dernier_lancement desc);
create index if not exists installations_joueur on public.installations (joueur);
alter table public.installations enable row level security;
revoke all on public.installations from anon, authenticated;

-- Appareils et comptes actifs, jour par jour (pour les courbes)
create table if not exists public.activite_jour (
	jour          date not null,
	installation  uuid not null,
	joueur        uuid,
	primary key (jour, installation)
);
create index if not exists activite_jour_joueur on public.activite_jour (jour, joueur);
alter table public.activite_jour enable row level security;
revoke all on public.activite_jour from anon, authenticated;

-- Appelée par le jeu au lancement (p_lancement = true) et à la connexion au compte (false).
create or replace function public.signaler_installation(p_id uuid, p_plateforme text, p_version text, p_lancement boolean default true)
returns void language plpgsql security definer set search_path = public as $$
declare
	v_plat text := case when p_plateforme in ('windows', 'macos', 'linux', 'android', 'web-pc', 'web-android', 'web-iphone')
		then p_plateforme else 'autre' end;
	v_version text := left(coalesce(p_version, ''), 16);
begin
	if p_id is null then
		return;
	end if;
	insert into public.installations as i (id, plateforme, version, joueur)
		values (p_id, v_plat, v_version, auth.uid())
	on conflict (id) do update set
		plateforme = excluded.plateforme,
		version = excluded.version,
		joueur = coalesce(auth.uid(), i.joueur),
		dernier_lancement = now(),
		lancements = i.lancements + case when p_lancement then 1 else 0 end;
	insert into public.activite_jour as a (jour, installation, joueur)
		values ((now() at time zone 'Europe/Paris')::date, p_id, auth.uid())
	on conflict (jour, installation) do update set joueur = coalesce(excluded.joueur, a.joueur);
end $$;
revoke all on function public.signaler_installation(uuid, text, text, boolean) from public;
grant execute on function public.signaler_installation(uuid, text, text, boolean) to anon, authenticated;


-- ---------------------------------------------------------------------
-- 3. LES STATISTIQUES (réservées aux administrateurs)
-- ---------------------------------------------------------------------
create or replace function public._compter(p_requete text) returns bigint
language plpgsql stable security definer set search_path = public as $$
declare
	n bigint := 0;
begin
	execute p_requete into n;
	return coalesce(n, 0);
exception when undefined_table or undefined_column then
	return 0;      -- fichier SQL correspondant pas encore lancé
end $$;
revoke all on function public._compter(text) from public, anon, authenticated;


create or replace function public.stats_jeu() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
	v_auj date := (now() at time zone 'Europe/Paris')::date;
	r jsonb := '{}'::jsonb;
begin
	if not public.est_admin_stats() then
		raise exception 'Accès réservé.';
	end if;

	-- Comptes
	r := r || jsonb_build_object('comptes', jsonb_build_object(
		'total', (select count(*) from public.profils),
		'jour', (select count(*) from public.profils where cree_le >= now() - interval '1 day'),
		'semaine', (select count(*) from public.profils where cree_le >= now() - interval '7 days'),
		'mois', (select count(*) from public.profils where cree_le >= now() - interval '30 days'),
		'en_ligne', (select count(*) from public.profils where vu_le >= now() - interval '5 minutes'),
		'actifs_jour', (select count(*) from public.profils where vu_le >= now() - interval '1 day'),
		'actifs_semaine', (select count(*) from public.profils where vu_le >= now() - interval '7 days'),
		'actifs_mois', (select count(*) from public.profils where vu_le >= now() - interval '30 days')
	));

	-- Appareils (installations)
	r := r || jsonb_build_object('appareils', jsonb_build_object(
		'total', (select count(*) from public.installations),
		'semaine', (select count(*) from public.installations where premier_lancement >= now() - interval '7 days'),
		'actifs_jour', (select count(*) from public.installations where dernier_lancement >= now() - interval '1 day'),
		'actifs_mois', (select count(*) from public.installations where dernier_lancement >= now() - interval '30 days'),
		'sans_compte', (select count(*) from public.installations where joueur is null),
		'lancements', (select coalesce(sum(lancements), 0) from public.installations),
		'par_plateforme', coalesce((select jsonb_object_agg(plateforme, n) from
			(select plateforme, count(*) n from public.installations group by plateforme) t), '{}'::jsonb),
		'par_plateforme_actifs', coalesce((select jsonb_object_agg(plateforme, n) from
			(select plateforme, count(*) n from public.installations
			 where dernier_lancement >= now() - interval '30 days' group by plateforme) t), '{}'::jsonb),
		'par_version', coalesce((select jsonb_agg(jsonb_build_object('version', version, 'n', n) order by n desc) from
			(select version, count(*) n from public.installations
			 where dernier_lancement >= now() - interval '30 days' group by version) t), '[]'::jsonb)
	));

	-- Courbe des 30 derniers jours
	r := r || jsonb_build_object('jours', (
		select jsonb_agg(jsonb_build_object(
			'jour', d::date,
			'appareils', (select count(*) from public.activite_jour a where a.jour = d::date),
			'comptes', (select count(distinct a.joueur) from public.activite_jour a where a.jour = d::date and a.joueur is not null),
			'nouveaux_comptes', (select count(*) from public.profils p where (p.cree_le at time zone 'Europe/Paris')::date = d::date),
			'nouveaux_appareils', (select count(*) from public.installations i where (i.premier_lancement at time zone 'Europe/Paris')::date = d::date)
		) order by d)
		from generate_series(v_auj - 29, v_auj, interval '1 day') d
	));

	-- Le jeu en ligne
	r := r || jsonb_build_object('jeu', jsonb_build_object(
		'guildes', public._compter('select count(*) from public.guildes'),
		'membres_guilde', public._compter('select count(*) from public.guilde_membres'),
		'arene_joueurs', public._compter('select count(*) from public.arene_joueurs'),
		'arene_combats', public._compter('select count(*) from public.arene_combats where fini_le is not null'),
		'arene_combats_semaine', public._compter('select count(*) from public.arene_combats where fini_le >= now() - interval ''7 days'''),
		'classee_joueurs', public._compter('select count(*) from public.ac_joueurs'),
		'classee_matchs', public._compter('select count(*) from public.ac_matchs where etat <> ''en_cours'''),
		'marche_jour', public._compter('select count(*) from public.marche_scores where jour = (now() at time zone ''Europe/Paris'')::date'),
		'marche_total', public._compter('select count(*) from public.marche_scores'),
		'sauvegardes', public._compter('select count(*) from public.sauvegardes')
	));

	-- La liste des joueurs (pseudo seulement : pas d'adresse e-mail)
	r := r || jsonb_build_object('joueurs', coalesce((
		select jsonb_agg(jsonb_build_object(
			'pseudo', p.pseudo,
			'niveau', p.niveau,
			'cree_le', p.cree_le,
			'vu_le', p.vu_le,
			'chapitres', coalesce((p.vitrine -> 'stats' ->> 'chapitres')::int, 0),
			'unites', coalesce((p.vitrine ->> 'nb_unites')::int, 0),
			'puissance', coalesce((p.vitrine ->> 'puissance')::int, 0),
			'version', coalesce(nullif(s.version_jeu, ''), p.vitrine ->> 'version', ''),
			'guilde', coalesce(g.nom, ''),
			'plateformes', coalesce((select jsonb_agg(distinct i.plateforme) from public.installations i where i.joueur = p.id), '[]'::jsonb)
		) order by p.vu_le desc)
		from public.profils p
		left join public.sauvegardes s on s.joueur = p.id
		left join public.guilde_membres gm on gm.joueur = p.id
		left join public.guildes g on g.id = gm.guilde
	), '[]'::jsonb));

	return r;
end $$;
revoke all on function public.stats_jeu() from public, anon;
grant execute on function public.stats_jeu() to authenticated;
