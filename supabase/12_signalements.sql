-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — signalements des joueurs (v0.81)
--  Bouton « Signaler un bug / Donner mon avis » du jeu, lu seulement par le créateur.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, après le fichier 07 (il réutilise la liste des administrateurs).
--  Peut être relancé sans danger.
--
--  Sécurité : personne ne lit ni n'écrit la table directement. Les joueurs passent par
--  envoyer_signalement() (avec une limite par jour), et seul un compte de stats_admins
--  peut lire et ranger les messages (lister_signalements / ranger_signalement).
-- =====================================================================

create table if not exists public.signalements (
	id          bigserial primary key,
	cree        timestamptz not null default now(),
	joueur      uuid references auth.users (id) on delete set null,
	pseudo      text not null default '',
	appareil    uuid,
	categorie   text not null default 'autre',
	message     text not null,
	version     text not null default '',
	plateforme  text not null default '',
	ecran       text not null default '',
	details     text not null default '',
	etat        text not null default 'nouveau'      -- nouveau, lu, corrige
);
create index if not exists signalements_cree on public.signalements (cree desc);
create index if not exists signalements_appareil on public.signalements (appareil, cree);
alter table public.signalements enable row level security;
revoke all on public.signalements from anon, authenticated;
revoke all on sequence public.signalements_id_seq from anon, authenticated;

-- Envoyer un message (avec ou sans compte). Limite : 10 messages par appareil (ou compte) et par jour.
create or replace function public.envoyer_signalement(p_appareil uuid, p_categorie text, p_message text,
	p_version text, p_plateforme text, p_ecran text, p_details text default '')
returns jsonb language plpgsql security definer set search_path = public as $$
declare
	v_msg text := left(btrim(coalesce(p_message, '')), 2000);
	v_cat text := case when p_categorie in ('bug', 'difficulte', 'idee', 'autre') then p_categorie else 'autre' end;
	v_nb int;
	v_pseudo text := '';
begin
	if length(v_msg) < 3 then
		return jsonb_build_object('ok', false, 'erreur', 'Message trop court.');
	end if;
	select count(*) into v_nb from public.signalements
		where cree > now() - interval '1 day'
		and ((p_appareil is not null and appareil = p_appareil) or (auth.uid() is not null and joueur = auth.uid()));
	if v_nb >= 10 then
		return jsonb_build_object('ok', false, 'erreur', 'Tu as déjà envoyé beaucoup de messages aujourd''hui. Merci, réessaie demain !');
	end if;
	if auth.uid() is not null then
		select coalesce(pseudo, '') into v_pseudo from public.profils where id = auth.uid();
	end if;
	insert into public.signalements (joueur, pseudo, appareil, categorie, message, version, plateforme, ecran, details)
	values (auth.uid(), coalesce(v_pseudo, ''), p_appareil, v_cat, v_msg, left(coalesce(p_version, ''), 16),
		left(coalesce(p_plateforme, ''), 16), left(coalesce(p_ecran, ''), 80), left(coalesce(p_details, ''), 600));
	return jsonb_build_object('ok', true);
end;
$$;
revoke all on function public.envoyer_signalement(uuid, text, text, text, text, text, text) from public;
grant execute on function public.envoyer_signalement(uuid, text, text, text, text, text, text) to anon, authenticated;

-- Lire les messages (créateur seulement). p_etat : '' = tous, sinon nouveau / lu / corrige.
create or replace function public.lister_signalements(p_etat text default '', p_limite int default 200)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
	if not public.est_admin_stats() then
		raise exception 'Accès réservé.';
	end if;
	return coalesce((select jsonb_agg(to_jsonb(s) order by s.cree desc) from (
		select id, cree, pseudo, categorie, message, version, plateforme, ecran, details, etat
		from public.signalements
		where p_etat = '' or etat = p_etat
		order by cree desc limit least(greatest(p_limite, 1), 500)) s), '[]'::jsonb);
end;
$$;
revoke all on function public.lister_signalements(text, int) from public, anon;
grant execute on function public.lister_signalements(text, int) to authenticated;

-- Ranger un message (créateur seulement) : lu, corrige, nouveau, ou supprime.
create or replace function public.ranger_signalement(p_id bigint, p_etat text)
returns void language plpgsql security definer set search_path = public as $$
begin
	if not public.est_admin_stats() then
		raise exception 'Accès réservé.';
	end if;
	if p_etat = 'supprime' then
		delete from public.signalements where id = p_id;
	elsif p_etat in ('nouveau', 'lu', 'corrige') then
		update public.signalements set etat = p_etat where id = p_id;
	end if;
end;
$$;
revoke all on function public.ranger_signalement(bigint, text) from public, anon;
grant execute on function public.ranger_signalement(bigint, text) to authenticated;
