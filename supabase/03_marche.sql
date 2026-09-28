-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — base de données en ligne
--  Étape 3 : LA MARCHE MAUDITE (une marche par jour, classement du jour).
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  (Les fichiers 01 et 02 doivent avoir été lancés avant.)
--  Le script peut être relancé sans danger (il ne supprime aucune donnée).
--
--  Ce que le SERVEUR contrôle : une seule marche classée par jour et par joueur,
--  un seul score envoyé, score plafonné, classement du jour.
--  Le jour change à minuit, heure de Paris.
-- =====================================================================

create table if not exists public.marche_scores (
	joueur      uuid not null references public.profils (id) on delete cascade,
	jour        date not null,
	commence_le timestamptz not null default now(),
	fini_le     timestamptz,
	score       int,
	detail      jsonb not null default '{}'::jsonb,   -- région atteinte, équipe, bénédictions...
	primary key (joueur, jour)
);
create index if not exists marche_scores_jour on public.marche_scores (jour, score desc);

alter table public.marche_scores enable row level security;
revoke all on public.marche_scores from anon, authenticated;
-- Tout passe par les fonctions ci-dessous.

create or replace function public._marche_jour() returns date language sql stable as $$
	select (now() at time zone 'Europe/Paris')::date
$$;


-- Commencer la marche du jour. Réponse : {ok, erreur}
--   erreur « deja_jouee » : ce joueur a déjà commencé la marche aujourd'hui.
create or replace function public.marche_commencer() returns jsonb
language plpgsql security definer set search_path = public as $$
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	if exists (select 1 from public.marche_scores where joueur = auth.uid() and jour = public._marche_jour()) then
		return jsonb_build_object('ok', false, 'erreur', 'deja_jouee');
	end if;
	insert into public.marche_scores (joueur, jour) values (auth.uid(), public._marche_jour());
	return jsonb_build_object('ok', true);
end $$;


-- Envoyer le score de la marche du jour (une seule fois). Réponse : {ok, erreur, rang, total}
create or replace function public.marche_terminer(p_score int, p_detail jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	m public.marche_scores;
	s int := greatest(0, least(coalesce(p_score, 0), 5000));
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	select * into m from public.marche_scores where joueur = auth.uid() and jour = public._marche_jour() for update;
	if m.joueur is null then return jsonb_build_object('ok', false, 'erreur', 'pas_commencee'); end if;
	if m.fini_le is not null then return jsonb_build_object('ok', false, 'erreur', 'deja_envoye'); end if;
	update public.marche_scores set score = s, fini_le = now(), detail = coalesce(p_detail, '{}'::jsonb)
		where joueur = auth.uid() and jour = m.jour;
	return jsonb_build_object('ok', true,
		'rang', 1 + (select count(*) from public.marche_scores where jour = m.jour and score > s),
		'total', (select count(*) from public.marche_scores where jour = m.jour and score is not null));
end $$;


-- Classement du jour (p_decalage : 0 = aujourd'hui, 1 = hier). Réponse :
--   {jour, total, liste: [{rang, id, pseudo, niveau, heros_vitrine, score, detail}], moi: {rang, score} | null}
create or replace function public.marche_classement(p_limite int, p_decalage int default 0) returns jsonb
language sql stable security definer set search_path = public as $$
	with j as (select public._marche_jour() - greatest(0, least(coalesce(p_decalage, 0), 30)) as jour),
	c as (
		select rank() over (order by m.score desc, m.fini_le) as rang, m.joueur, m.score, m.detail
		from public.marche_scores m, j where m.jour = j.jour and m.score is not null
	)
	select jsonb_build_object(
		'jour', (select jour from j),
		'total', (select count(*) from c),
		'liste', coalesce((select jsonb_agg(jsonb_build_object('rang', c.rang, 'id', c.joueur, 'pseudo', p.pseudo,
			'niveau', p.niveau, 'heros_vitrine', p.heros_vitrine, 'score', c.score, 'detail', c.detail) order by c.rang)
			from (select * from c order by rang limit greatest(1, least(coalesce(p_limite, 50), 200))) c
			join public.profils p on p.id = c.joueur), '[]'::jsonb),
		'moi', (select jsonb_build_object('rang', c.rang, 'score', c.score) from c where c.joueur = auth.uid())
	)
$$;

grant execute on function public.marche_commencer() to authenticated;
grant execute on function public.marche_terminer(int, jsonb) to authenticated;
grant execute on function public.marche_classement(int, int) to authenticated;
