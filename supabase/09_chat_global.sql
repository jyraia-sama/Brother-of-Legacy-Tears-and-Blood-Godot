-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — chat global
--  Étape 9 : discussion ouverte à tous les joueurs connectés, depuis le menu principal.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, APRÈS les fichiers 01 et 07. Peut être relancé sans danger.
--
--  MODÉRATION : les comptes de stats_admins (fichier 07, « jyraia ») peuvent supprimer
--  n'importe quel message depuis le jeu.
-- =====================================================================

create or replace function public.chat_global_reglages() returns jsonb language sql immutable as $$
	select jsonb_build_object(
		'longueur', 200,          -- caractères maximum par message
		'gardes', 500,            -- messages conservés (les plus anciens sont effacés)
		'delai_secondes', 3       -- délai minimum entre deux messages d'un même joueur
	)
$$;

create table if not exists public.chat_global (
	id       bigserial primary key,
	joueur   uuid references public.profils (id) on delete set null,
	pseudo   text not null,
	texte    text not null check (char_length(texte) between 1 and 200),
	cree_le  timestamptz not null default now()
);
create index if not exists chat_global_joueur on public.chat_global (joueur, cree_le desc);

alter table public.chat_global enable row level security;
-- Aucune lecture/écriture directe : tout passe par les fonctions ci-dessous.
revoke all on public.chat_global from anon, authenticated;


create or replace function public.chat_global_envoyer(p_texte text) returns text
language plpgsql security definer set search_path = public as $$
declare
	r jsonb := public.chat_global_reglages();
	t text := btrim(coalesce(p_texte, ''));
	v_pseudo text;
	dernier timestamptz;
begin
	if auth.uid() is null then return 'pas_connecte'; end if;
	if char_length(t) = 0 then return 'vide'; end if;
	t := left(t, (r ->> 'longueur')::int);
	select max(cree_le) into dernier from public.chat_global where joueur = auth.uid();
	if dernier is not null and dernier > now() - make_interval(secs => (r ->> 'delai_secondes')::int) then
		return 'trop_vite';
	end if;
	select p.pseudo into v_pseudo from public.profils p where p.id = auth.uid();
	if v_pseudo is null then return 'pas_de_profil'; end if;
	insert into public.chat_global (joueur, pseudo, texte) values (auth.uid(), v_pseudo, t);
	delete from public.chat_global where id < (select min(id) from
		(select id from public.chat_global order by id desc limit (r ->> 'gardes')::int) x);
	return 'ok';
end $$;

-- Messages plus récents que p_depuis (0 = les 50 derniers), du plus ancien au plus récent.
-- « admin » = message écrit par un modérateur (affiché avec une couronne).
create or replace function public.chat_global_lire(p_depuis bigint) returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'joueur', c.joueur, 'pseudo', c.pseudo,
			'texte', c.texte, 'cree_le', c.cree_le,
			'admin', exists (select 1 from public.stats_admins a where a.id = c.joueur)) order by c.id)
		from (select * from public.chat_global where id > coalesce(p_depuis, 0) order by id desc limit 50) c), '[]'::jsonb);
$$;

-- Numéro du dernier message (pour la pastille « nouveaux messages » du menu principal).
create or replace function public.chat_global_dernier() returns bigint
language sql stable security definer set search_path = public as $$
	select coalesce(max(id), 0) from public.chat_global;
$$;

-- Modération : supprimer un message (réservé aux comptes de stats_admins).
create or replace function public.chat_global_supprimer(p_id bigint) returns text
language plpgsql security definer set search_path = public as $$
begin
	if not exists (select 1 from public.stats_admins where id = auth.uid()) then return 'interdit'; end if;
	delete from public.chat_global where id = p_id;
	return 'ok';
end $$;


revoke all on function public.chat_global_envoyer(text), public.chat_global_lire(bigint),
	public.chat_global_dernier(), public.chat_global_supprimer(bigint) from public, anon;
grant execute on function public.chat_global_envoyer(text), public.chat_global_lire(bigint),
	public.chat_global_dernier(), public.chat_global_supprimer(bigint) to authenticated;
