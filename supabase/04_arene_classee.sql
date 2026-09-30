-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — base de données en ligne
--  Étape 4 : ARÈNE CLASSÉE EN TEMPS RÉEL (combat manuel à deux joueurs).
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  (Les fichiers 01 et 02 doivent avoir été lancés avant.)
--  Le script peut être relancé sans danger (il ne supprime aucune donnée).
--
--  Principe : les deux joueurs calculent le même combat sur leur appareil (même graine,
--  mêmes équipes). Le serveur garde la LISTE DES ACTIONS (action n°0, n°1, ...) :
--  chaque joueur envoie les actions de ses unités, et lit celles de l'adversaire.
--  Le serveur contrôle : l'ordre des actions (une seule action par numéro), le minuteur
--  (un joueur absent est remplacé par l'IA), les points (Elo), les saisons et récompenses.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Réglages
-- ---------------------------------------------------------------------
create or replace function public.ac_reglages() returns jsonb language sql immutable as $$
	select jsonb_build_object(
		'points_depart', 1000,
		'k', 32,                       -- force de l'Elo (points gagnés / perdus)
		'saison_jours', 28,            -- saisons de 4 semaines
		'secondes_absence', 40,        -- délai avant que l'IA joue à la place d'un joueur absent
		'secondes_forfait', 60,        -- adversaire injoignable depuis ce délai : victoire par forfait
		'minutes_match', 40            -- un match plus vieux est abandonné (sans points)
	)
$$;

create or replace function public.ac_palier(p_points int) returns text language sql immutable as $$
	select case
		when p_points >= 1700 then 'legende'
		when p_points >= 1550 then 'diamant'
		when p_points >= 1400 then 'platine'
		when p_points >= 1250 then 'or'
		when p_points >= 1100 then 'argent'
		else 'bronze' end
$$;

-- Récompenses de fin de saison (gemmes, et un titre à partir de l'Or)
create or replace function public.ac_recompense_palier(p_palier text) returns jsonb language sql immutable as $$
	select case p_palier
		when 'legende' then '{"gemmes": 600, "titre": "Légende de l''Arène"}'
		when 'diamant' then '{"gemmes": 400, "titre": "Gladiateur de Diamant"}'
		when 'platine' then '{"gemmes": 250, "titre": "Gladiateur de Platine"}'
		when 'or'      then '{"gemmes": 150, "titre": "Gladiateur d''Or"}'
		when 'argent'  then '{"gemmes": 80}'
		else                '{"gemmes": 40}' end::jsonb
$$;

-- Numéro de saison (blocs de 28 jours) et date de fin
create or replace function public._ac_saison() returns int language sql stable as $$
	select floor(extract(epoch from now()) / ((public.ac_reglages() ->> 'saison_jours')::int * 86400))::int
$$;
create or replace function public._ac_fin_saison() returns timestamptz language sql stable as $$
	select to_timestamp((public._ac_saison() + 1)::bigint * (public.ac_reglages() ->> 'saison_jours')::int * 86400)
$$;
-- Numéro affiché (la saison 1 est celle qui finit le 22 octobre 2026)
create or replace function public._ac_saison_affichee(p int) returns int language sql immutable as $$
	select p - 739
$$;


-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
create table if not exists public.ac_joueurs (
	joueur     uuid primary key references public.profils (id) on delete cascade,
	points     int  not null default 1000,
	saison     int  not null default 0,
	victoires  int  not null default 0,
	defaites   int  not null default 0,
	egalites   int  not null default 0,
	vu_le      timestamptz not null default now()
);
create index if not exists ac_joueurs_points on public.ac_joueurs (saison, points desc);

create table if not exists public.ac_file (
	joueur     uuid primary key references public.profils (id) on delete cascade,
	points     int  not null,
	equipe     jsonb not null,
	version    text not null,
	depuis     timestamptz not null default now(),
	vu_le      timestamptz not null default now()
);

create table if not exists public.ac_matchs (
	id         uuid primary key default gen_random_uuid(),
	saison     int  not null,
	j1         uuid not null references public.profils (id) on delete cascade,
	j2         uuid not null references public.profils (id) on delete cascade,
	equipe1    jsonb not null,
	equipe2    jsonb not null,
	graine     bigint not null,
	version    text not null,
	etat       text not null default 'en_cours' check (etat in ('en_cours', 'fini', 'abandon')),
	gagnant    int,                         -- 0 = j1, 1 = j2, -1 = égalité
	delta1     int,
	delta2     int,
	vu1        timestamptz not null default now(),
	vu2        timestamptz not null default now(),
	cree_le    timestamptz not null default now(),
	fini_le    timestamptz,
	forfait    boolean not null default false
);
create index if not exists ac_matchs_j1 on public.ac_matchs (j1, cree_le desc);
create index if not exists ac_matchs_j2 on public.ac_matchs (j2, cree_le desc);

create table if not exists public.ac_actions (
	match      uuid not null references public.ac_matchs (id) on delete cascade,
	n          int  not null,
	camp       int  not null,
	action     jsonb not null,
	joueur     uuid,
	cree_le    timestamptz not null default now(),
	primary key (match, n)
);

create table if not exists public.ac_defis (
	id         uuid primary key default gen_random_uuid(),
	de         uuid not null references public.profils (id) on delete cascade,
	a          uuid not null references public.profils (id) on delete cascade,
	equipe     jsonb not null,
	version    text not null,
	etat       text not null default 'attente' check (etat in ('attente', 'acceptee', 'refusee', 'annulee')),
	match      uuid,
	cree_le    timestamptz not null default now()
);
create index if not exists ac_defis_a on public.ac_defis (a, cree_le desc);

create table if not exists public.ac_recompenses (
	joueur     uuid not null references public.profils (id) on delete cascade,
	saison     int  not null,
	palier     text not null,
	points     int  not null,
	gemmes     int  not null,
	titre      text not null default '',
	reclamee   boolean not null default false,
	primary key (joueur, saison)
);

alter table public.ac_joueurs enable row level security;
alter table public.ac_file enable row level security;
alter table public.ac_matchs enable row level security;
alter table public.ac_actions enable row level security;
alter table public.ac_defis enable row level security;
alter table public.ac_recompenses enable row level security;
revoke all on public.ac_joueurs, public.ac_file, public.ac_matchs, public.ac_actions, public.ac_defis, public.ac_recompenses
	from anon, authenticated;
-- Tout passe par les fonctions ci-dessous.


-- ---------------------------------------------------------------------
-- Outils internes
-- ---------------------------------------------------------------------

-- Ligne du joueur connecté (créée si besoin). Changement de saison : récompense + points resserrés.
create or replace function public._ac_moi() returns public.ac_joueurs
language plpgsql security definer set search_path = public as $$
declare
	moi uuid := auth.uid();
	j public.ac_joueurs;
	s int := public._ac_saison();
	depart int := (public.ac_reglages() ->> 'points_depart')::int;
	pal text;
	rec jsonb;
begin
	insert into public.ac_joueurs (joueur, points, saison) values (moi, depart, s) on conflict (joueur) do nothing;
	select * into j from public.ac_joueurs where joueur = moi for update;
	if j.saison <> s then
		if j.victoires + j.defaites + j.egalites > 0 then
			pal := public.ac_palier(j.points);
			rec := public.ac_recompense_palier(pal);
			insert into public.ac_recompenses (joueur, saison, palier, points, gemmes, titre)
				values (moi, j.saison, pal, j.points, (rec ->> 'gemmes')::int, coalesce(rec ->> 'titre', ''))
				on conflict do nothing;
		end if;
		update public.ac_joueurs set saison = s, points = depart + (points - depart) / 2,
			victoires = 0, defaites = 0, egalites = 0 where joueur = moi returning * into j;
	end if;
	update public.ac_joueurs set vu_le = now() where joueur = moi returning * into j;
	return j;
end $$;

create or replace function public._ac_rang(p_points int) returns int
language sql stable security definer set search_path = public as $$
	select 1 + count(*)::int from public.ac_joueurs
	where saison = public._ac_saison() and points > p_points and victoires + defaites + egalites > 0;
$$;

create or replace function public._ac_fiche(p_joueur uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('id', p.id, 'pseudo', p.pseudo, 'niveau', p.niveau, 'heros_vitrine', p.heros_vitrine,
		'points', coalesce(j.points, 1000), 'palier', public.ac_palier(coalesce(j.points, 1000)))
	from public.profils p left join public.ac_joueurs j on j.joueur = p.id
	where p.id = p_joueur;
$$;

-- Équipe vraisemblable : 1 à 5 unités, niveaux, étoiles et places valides.
create or replace function public._ac_equipe_valide(p_equipe jsonb) returns boolean
language plpgsql immutable as $$
declare
	u jsonb;
	places int[] := '{}';
begin
	if jsonb_typeof(p_equipe) <> 'array' or jsonb_array_length(p_equipe) = 0
		or jsonb_array_length(p_equipe) > 5 or pg_column_size(p_equipe) > 20000 then
		return false;
	end if;
	for u in select * from jsonb_array_elements(p_equipe) loop
		if coalesce(u ->> 'id', '') !~ '^[a-z0-9_]{1,40}$'
			or coalesce((u ->> 'niveau')::int, 0) not between 1 and 40
			or coalesce((u ->> 'etoiles')::int, 0) not between 0 and 6
			or coalesce((u ->> 'place')::int, -1) not between 0 and 4
			or (u ->> 'place')::int = any(places) then
			return false;
		end if;
		places := places || (u ->> 'place')::int;
	end loop;
	return true;
end $$;

-- Match en cours du joueur connecté (le plus récent, pas trop vieux)
create or replace function public._ac_match_en_cours() returns public.ac_matchs
language sql stable security definer set search_path = public as $$
	select * from public.ac_matchs
	where etat = 'en_cours' and auth.uid() in (j1, j2)
		and cree_le > now() - make_interval(mins => (public.ac_reglages() ->> 'minutes_match')::int)
	order by cree_le desc limit 1;
$$;

create or replace function public._ac_creer_match(p_j1 uuid, p_e1 jsonb, p_j2 uuid, p_e2 jsonb, p_version text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
	id_match uuid;
begin
	-- Les anciens matchs non terminés des deux joueurs sont abandonnés (sans points)
	update public.ac_matchs set etat = 'abandon', fini_le = now()
		where etat = 'en_cours' and (j1 in (p_j1, p_j2) or j2 in (p_j1, p_j2));
	insert into public.ac_matchs (saison, j1, j2, equipe1, equipe2, graine, version)
		values (public._ac_saison(), p_j1, p_j2, p_e1, p_e2, floor(random() * 2000000000)::bigint + 1, p_version)
		returning id into id_match;
	delete from public.ac_file where joueur in (p_j1, p_j2);
	update public.ac_defis set etat = 'annulee' where etat = 'attente' and (de in (p_j1, p_j2) or a in (p_j1, p_j2));
	return id_match;
end $$;

create or replace function public._ac_match_json(p_id uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('id', m.id, 'j1', public._ac_fiche(m.j1), 'j2', public._ac_fiche(m.j2),
		'equipe1', m.equipe1, 'equipe2', m.equipe2, 'graine', m.graine, 'version', m.version,
		'mon_camp', case when m.j1 = auth.uid() then 0 else 1 end,
		'etat', m.etat, 'gagnant', m.gagnant, 'forfait', m.forfait,
		'delta', case when m.j1 = auth.uid() then m.delta1 else m.delta2 end)
	from public.ac_matchs m where m.id = p_id and auth.uid() in (m.j1, m.j2);
$$;


-- ---------------------------------------------------------------------
-- État de l'Arène classée
-- ---------------------------------------------------------------------
create or replace function public.ac_etat() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.ac_joueurs;
	m public.ac_matchs;
	r int;
begin
	if auth.uid() is null then return null; end if;
	j := public._ac_moi();
	m := public._ac_match_en_cours();
	r := public._ac_rang(j.points);
	return jsonb_build_object(
		'points', j.points, 'palier', public.ac_palier(j.points), 'rang', r,
		'victoires', j.victoires, 'defaites', j.defaites, 'egalites', j.egalites,
		'saison', public._ac_saison_affichee(j.saison), 'fin_saison', public._ac_fin_saison(),
		'match', case when m.id is null then null else public._ac_match_json(m.id) end,
		'en_file', exists (select 1 from public.ac_file where joueur = auth.uid()),
		'dans_la_file', (select count(*) from public.ac_file where vu_le > now() - interval '15 seconds'),
		'defis_recus', coalesce((select jsonb_agg(jsonb_build_object('id', d.id, 'de', public._ac_fiche(d.de), 'version', d.version)
			order by d.cree_le desc) from public.ac_defis d
			where d.a = auth.uid() and d.etat = 'attente' and d.cree_le > now() - interval '2 minutes'), '[]'::jsonb),
		'defi_envoye', (select jsonb_build_object('id', d.id, 'a', public._ac_fiche(d.a), 'etat', d.etat, 'match', d.match)
			from public.ac_defis d where d.de = auth.uid() and d.cree_le > now() - interval '2 minutes'
			order by d.cree_le desc limit 1),
		'recompenses', coalesce((select jsonb_agg(jsonb_build_object('saison', public._ac_saison_affichee(saison), 'palier', palier,
			'points', points, 'gemmes', gemmes, 'titre', titre) order by saison)
			from public.ac_recompenses where joueur = auth.uid() and not reclamee), '[]'::jsonb));
end $$;


-- ---------------------------------------------------------------------
-- Recherche d'un adversaire (file d'attente). À rappeler toutes les 2 s pendant l'attente.
-- Réponse : {ok, erreur, match (fiche du match) | attente (secondes)}
-- ---------------------------------------------------------------------
create or replace function public.ac_chercher(p_equipe jsonb, p_version text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.ac_joueurs;
	m public.ac_matchs;
	f public.ac_file;
	adv public.ac_file;
	attente int;
	tolerance int;
	id_match uuid;
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	if not public._ac_equipe_valide(p_equipe) then return jsonb_build_object('ok', false, 'erreur', 'invalide'); end if;
	j := public._ac_moi();
	m := public._ac_match_en_cours();
	if m.id is not null and m.cree_le > now() - interval '2 minutes' then
		return jsonb_build_object('ok', true, 'match', public._ac_match_json(m.id));
	end if;
	perform pg_advisory_xact_lock(515151);
	delete from public.ac_file where vu_le < now() - interval '15 seconds';
	insert into public.ac_file (joueur, points, equipe, version) values (auth.uid(), j.points, p_equipe, p_version)
		on conflict (joueur) do update set points = excluded.points, equipe = excluded.equipe,
			version = excluded.version, vu_le = now();
	select * into f from public.ac_file where joueur = auth.uid();
	attente := extract(epoch from now() - f.depuis)::int;
	-- Écart de points accepté : s'élargit avec l'attente (tout le monde après 2 minutes)
	tolerance := case when attente >= 120 then 100000 else 150 + attente * 5 end;
	select * into adv from public.ac_file a
	where a.joueur <> auth.uid() and a.version = p_version and abs(a.points - j.points) <= tolerance
	order by abs(a.points - j.points), a.depuis limit 1;
	if adv.joueur is not null then
		id_match := public._ac_creer_match(adv.joueur, adv.equipe, auth.uid(), p_equipe, p_version);
		return jsonb_build_object('ok', true, 'match', public._ac_match_json(id_match));
	end if;
	return jsonb_build_object('ok', true, 'attente', attente,
		'dans_la_file', (select count(*) from public.ac_file where vu_le > now() - interval '15 seconds'));
end $$;

create or replace function public.ac_quitter_file() returns text
language sql security definer set search_path = public as $$
	delete from public.ac_file where joueur = auth.uid();
	select 'ok';
$$;


-- ---------------------------------------------------------------------
-- Défis entre amis (comptent pour le classement)
-- ---------------------------------------------------------------------
-- Réponses : ok, non_connecte, invalide, pas_ami
create or replace function public.ac_defier(p_ami uuid, p_equipe jsonb, p_version text) returns text
language plpgsql security definer set search_path = public as $$
begin
	if auth.uid() is null then return 'non_connecte'; end if;
	if not public._ac_equipe_valide(p_equipe) then return 'invalide'; end if;
	if not exists (select 1 from public.amities where statut = 'acceptee'
		and ((demandeur = auth.uid() and receveur = p_ami) or (demandeur = p_ami and receveur = auth.uid()))) then
		return 'pas_ami';
	end if;
	perform public._ac_moi();
	update public.ac_defis set etat = 'annulee' where de = auth.uid() and etat = 'attente';
	insert into public.ac_defis (de, a, equipe, version) values (auth.uid(), p_ami, p_equipe, p_version);
	return 'ok';
end $$;

-- Réponse : {ok, erreur, match}
create or replace function public.ac_repondre_defi(p_defi uuid, p_accepter boolean, p_equipe jsonb, p_version text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	d public.ac_defis;
	id_match uuid;
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	select * into d from public.ac_defis where id = p_defi and a = auth.uid() for update;
	if not found or d.etat <> 'attente' or d.cree_le < now() - interval '2 minutes' then
		return jsonb_build_object('ok', false, 'erreur', 'expire');
	end if;
	if not p_accepter then
		update public.ac_defis set etat = 'refusee' where id = p_defi;
		return jsonb_build_object('ok', true);
	end if;
	if d.version <> p_version then return jsonb_build_object('ok', false, 'erreur', 'version'); end if;
	if not public._ac_equipe_valide(p_equipe) then return jsonb_build_object('ok', false, 'erreur', 'invalide'); end if;
	perform public._ac_moi();
	id_match := public._ac_creer_match(d.de, d.equipe, auth.uid(), p_equipe, p_version);
	update public.ac_defis set etat = 'acceptee', match = id_match where id = p_defi;
	return jsonb_build_object('ok', true, 'match', public._ac_match_json(id_match));
end $$;

create or replace function public.ac_annuler_defi() returns text
language sql security definer set search_path = public as $$
	update public.ac_defis set etat = 'annulee' where de = auth.uid() and etat = 'attente';
	select 'ok';
$$;


-- ---------------------------------------------------------------------
-- Déroulement d'un match
-- ---------------------------------------------------------------------
create or replace function public.ac_match(p_match uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select public._ac_match_json(p_match);
$$;

-- Actions à partir du numéro p_depuis. Signale aussi que le joueur est présent.
-- Réponse : {actions: [{n, camp, action}], etat, gagnant, delta, adversaire_absent (s), depuis_derniere (s)}
create or replace function public.ac_actions(p_match uuid, p_depuis int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
	camp int;
	derniere timestamptz;
begin
	select * into m from public.ac_matchs where id = p_match and auth.uid() in (j1, j2);
	if not found then return null; end if;
	camp := case when m.j1 = auth.uid() then 0 else 1 end;
	if m.etat = 'en_cours' then
		if camp = 0 then
			update public.ac_matchs set vu1 = now() where id = p_match returning * into m;
		else
			update public.ac_matchs set vu2 = now() where id = p_match returning * into m;
		end if;
	end if;
	select coalesce(max(cree_le), m.cree_le) into derniere from public.ac_actions where match = p_match;
	return jsonb_build_object(
		'actions', coalesce((select jsonb_agg(jsonb_build_object('n', n, 'camp', a.camp, 'action', a.action) order by n)
			from public.ac_actions a where a.match = p_match and a.n >= p_depuis), '[]'::jsonb),
		'etat', m.etat, 'gagnant', m.gagnant, 'forfait', m.forfait,
		'delta', case when camp = 0 then m.delta1 else m.delta2 end,
		'adversaire_absent', extract(epoch from now() - case when camp = 0 then m.vu2 else m.vu1 end)::int,
		'depuis_derniere', extract(epoch from now() - derniere)::int);
end $$;

-- Envoie l'action n°p_n (unité du camp p_camp). Un joueur ne joue que ses unités ;
-- pour l'adversaire, seule l'action « auto » est acceptée, et seulement après le délai d'absence.
-- Réponse : {ok, erreur, action (celle retenue par le serveur)}
create or replace function public.ac_jouer(p_match uuid, p_n int, p_camp int, p_action jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
	camp int;
	prochain int;
	derniere timestamptz;
	retenue jsonb;
begin
	select * into m from public.ac_matchs where id = p_match and auth.uid() in (j1, j2);
	if not found then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	select action into retenue from public.ac_actions where match = p_match and n = p_n;
	if retenue is not null then return jsonb_build_object('ok', true, 'action', retenue); end if;
	if m.etat <> 'en_cours' then return jsonb_build_object('ok', false, 'erreur', 'termine'); end if;
	if jsonb_typeof(p_action) <> 'object' or pg_column_size(p_action) > 500 then
		return jsonb_build_object('ok', false, 'erreur', 'invalide');
	end if;
	camp := case when m.j1 = auth.uid() then 0 else 1 end;
	perform pg_advisory_xact_lock(hashtext(p_match::text));
	select coalesce(max(n) + 1, 0), coalesce(max(cree_le), m.cree_le) into prochain, derniere
		from public.ac_actions where match = p_match;
	if p_n <> prochain then return jsonb_build_object('ok', false, 'erreur', 'ordre'); end if;
	if p_camp <> camp then
		if coalesce(p_action ->> 'type', '') <> 'auto'
			or now() - derniere < make_interval(secs => (public.ac_reglages() ->> 'secondes_absence')::int) then
			return jsonb_build_object('ok', false, 'erreur', 'pas_ton_tour');
		end if;
	end if;
	insert into public.ac_actions (match, n, camp, action, joueur) values (p_match, p_n, p_camp, p_action, auth.uid())
		on conflict do nothing;
	select action into retenue from public.ac_actions where match = p_match and n = p_n;
	return jsonb_build_object('ok', true, 'action', retenue);
end $$;

-- Résultat du combat (les deux appareils calculent le même). Le premier envoi compte.
-- p_gagnant : 0 = j1, 1 = j2, -1 = égalité. Réponse : {ok, erreur, gagnant, delta, points}
create or replace function public.ac_terminer(p_match uuid, p_gagnant int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
begin
	select * into m from public.ac_matchs where id = p_match and auth.uid() in (j1, j2) for update;
	if not found then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	if m.etat = 'en_cours' then
		if p_gagnant not in (-1, 0, 1) then return jsonb_build_object('ok', false, 'erreur', 'invalide'); end if;
		perform public._ac_clore(p_match, p_gagnant, false);
	end if;
	return public._ac_bilan(p_match);
end $$;

create or replace function public._ac_bilan(p_match uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('ok', true, 'etat', m.etat, 'gagnant', m.gagnant, 'forfait', m.forfait,
		'delta', case when m.j1 = auth.uid() then m.delta1 else m.delta2 end,
		'points', (select points from public.ac_joueurs where joueur = auth.uid()))
	from public.ac_matchs m where m.id = p_match;
$$;

-- Clôture : Elo (somme nulle), victoires / défaites.
create or replace function public._ac_clore(p_match uuid, p_gagnant int, p_forfait boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
	p1 int;
	p2 int;
	attendu float;
	score float;
	d int;
	k int := (public.ac_reglages() ->> 'k')::int;
begin
	select * into m from public.ac_matchs where id = p_match for update;
	if m.etat <> 'en_cours' then return; end if;
	insert into public.ac_joueurs (joueur) values (m.j1), (m.j2) on conflict do nothing;
	select points into p1 from public.ac_joueurs where joueur = m.j1;
	select points into p2 from public.ac_joueurs where joueur = m.j2;
	attendu := 1.0 / (1.0 + power(10.0, (p2 - p1) / 400.0));
	score := case p_gagnant when 0 then 1.0 when 1 then 0.0 else 0.5 end;
	d := round(k * (score - attendu));
	if p_gagnant = 0 then d := greatest(d, 5); elsif p_gagnant = 1 then d := least(d, -5); end if;
	update public.ac_joueurs set points = greatest(0, points + d),
		victoires = victoires + (p_gagnant = 0)::int, defaites = defaites + (p_gagnant = 1)::int,
		egalites = egalites + (p_gagnant = -1)::int where joueur = m.j1;
	update public.ac_joueurs set points = greatest(0, points - d),
		victoires = victoires + (p_gagnant = 1)::int, defaites = defaites + (p_gagnant = 0)::int,
		egalites = egalites + (p_gagnant = -1)::int where joueur = m.j2;
	update public.ac_matchs set etat = 'fini', gagnant = p_gagnant, delta1 = d, delta2 = -d,
		fini_le = now(), forfait = p_forfait where id = p_match;
end $$;

-- Victoire par forfait si l'adversaire ne donne plus signe de vie.
create or replace function public.ac_forfait(p_match uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
	camp int;
	absent int;
begin
	select * into m from public.ac_matchs where id = p_match and auth.uid() in (j1, j2) for update;
	if not found then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	if m.etat = 'en_cours' then
		camp := case when m.j1 = auth.uid() then 0 else 1 end;
		absent := extract(epoch from now() - case when camp = 0 then m.vu2 else m.vu1 end)::int;
		if absent < (public.ac_reglages() ->> 'secondes_forfait')::int then
			return jsonb_build_object('ok', false, 'erreur', 'adversaire_present');
		end if;
		perform public._ac_clore(p_match, camp, true);
	end if;
	return public._ac_bilan(p_match);
end $$;

-- Abandon volontaire : défaite immédiate.
create or replace function public.ac_abandonner(p_match uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.ac_matchs;
begin
	select * into m from public.ac_matchs where id = p_match and auth.uid() in (j1, j2) for update;
	if not found then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	if m.etat = 'en_cours' then
		perform public._ac_clore(p_match, case when m.j1 = auth.uid() then 1 else 0 end, true);
	end if;
	return public._ac_bilan(p_match);
end $$;


-- ---------------------------------------------------------------------
-- Classement, historique et récompenses
-- ---------------------------------------------------------------------
create or replace function public.ac_classement(p_limite int) returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce(jsonb_agg(x order by (x ->> 'points')::int desc), '[]'::jsonb) from (
		select jsonb_build_object('id', j.joueur, 'pseudo', p.pseudo, 'points', j.points, 'palier', public.ac_palier(j.points),
			'victoires', j.victoires, 'defaites', j.defaites, 'heros_vitrine', p.heros_vitrine) as x
		from public.ac_joueurs j join public.profils p on p.id = j.joueur
		where j.saison = public._ac_saison() and j.victoires + j.defaites + j.egalites > 0
		order by j.points desc limit least(greatest(p_limite, 1), 200)
	) t;
$$;

create or replace function public.ac_historique() returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce(jsonb_agg(x order by x ->> 'date' desc), '[]'::jsonb) from (
		select jsonb_build_object('date', m.fini_le,
			'adversaire', (select pseudo from public.profils where id = case when m.j1 = auth.uid() then m.j2 else m.j1 end),
			'resultat', case when m.gagnant = -1 then 'egalite'
				when (m.gagnant = 0) = (m.j1 = auth.uid()) then 'victoire' else 'defaite' end,
			'delta', case when m.j1 = auth.uid() then m.delta1 else m.delta2 end, 'forfait', m.forfait) as x
		from public.ac_matchs m
		where auth.uid() in (m.j1, m.j2) and m.etat = 'fini'
		order by m.fini_le desc limit 20
	) t;
$$;

-- Réclame les récompenses de saison en attente. Réponse : [{saison, palier, gemmes, titre}]
create or replace function public.ac_reclamer() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	res jsonb;
begin
	if auth.uid() is null then return '[]'::jsonb; end if;
	with r as (
		update public.ac_recompenses set reclamee = true where joueur = auth.uid() and not reclamee
		returning saison, palier, gemmes, titre
	)
	select coalesce(jsonb_agg(jsonb_build_object('saison', public._ac_saison_affichee(saison), 'palier', palier,
		'gemmes', gemmes, 'titre', titre)), '[]'::jsonb) into res from r;
	return res;
end $$;


-- ---------------------------------------------------------------------
-- Droits : seules les fonctions publiques sont appelables par le jeu
-- ---------------------------------------------------------------------
revoke execute on function public._ac_moi(), public._ac_creer_match(uuid, jsonb, uuid, jsonb, text),
	public._ac_clore(uuid, int, boolean) from anon, authenticated, public;
grant execute on function public.ac_etat(), public.ac_chercher(jsonb, text), public.ac_quitter_file(),
	public.ac_defier(uuid, jsonb, text), public.ac_repondre_defi(uuid, boolean, jsonb, text), public.ac_annuler_defi(),
	public.ac_match(uuid), public.ac_actions(uuid, int), public.ac_jouer(uuid, int, int, jsonb),
	public.ac_terminer(uuid, int), public.ac_forfait(uuid), public.ac_abandonner(uuid),
	public.ac_classement(int), public.ac_historique(), public.ac_reclamer() to authenticated;
