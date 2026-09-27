-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — base de données en ligne
--  Étape 1 : comptes (pseudo), sauvegarde en ligne, amis, guildes.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  Le script peut être relancé sans danger (il ne supprime aucune donnée).
--
--  Règle d'or : les joueurs ne peuvent RIEN écrire directement dans les
--  tables amis / guildes. Tout passe par les fonctions ci-dessous, qui
--  vérifient les droits (chef, officier...) côté serveur.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. PROFILS : un par compte (pseudo visible par les autres joueurs)
-- ---------------------------------------------------------------------
create table if not exists public.profils (
	id             uuid primary key references auth.users (id) on delete cascade,
	pseudo         text not null check (pseudo ~ '^[A-Za-z0-9_-]{3,16}$'),
	niveau         int  not null default 1 check (niveau between 1 and 999),
	heros_vitrine  text not null default '' check (char_length(heros_vitrine) <= 40),
	vu_le          timestamptz not null default now(),
	cree_le        timestamptz not null default now()
);
create unique index if not exists profils_pseudo_unique on public.profils (lower(pseudo));

alter table public.profils enable row level security;
drop policy if exists profils_lecture on public.profils;
create policy profils_lecture on public.profils for select to authenticated using (true);
drop policy if exists profils_modif on public.profils;
create policy profils_modif on public.profils for update to authenticated
	using (id = auth.uid()) with check (id = auth.uid());

revoke all on public.profils from anon, authenticated;
grant select on public.profils to authenticated;
-- Le joueur peut seulement changer ces 3 colonnes de SON profil (pas son pseudo).
grant update (niveau, heros_vitrine, vu_le) on public.profils to authenticated;

-- Création automatique du profil à l'inscription (le pseudo est envoyé par le jeu).
create or replace function public.creer_profil() returns trigger
language plpgsql security definer set search_path = public as $$
begin
	insert into public.profils (id, pseudo)
	values (new.id, coalesce(new.raw_user_meta_data ->> 'pseudo', 'Joueur' || substr(replace(new.id::text, '-', ''), 1, 8)));
	return new;
end $$;

drop trigger if exists quand_compte_cree on auth.users;
create trigger quand_compte_cree after insert on auth.users
	for each row execute function public.creer_profil();

-- Vérifie qu'un pseudo est libre (appelé AVANT la création du compte).
create or replace function public.pseudo_disponible(p_pseudo text) returns boolean
language sql stable security definer set search_path = public as $$
	select p_pseudo ~ '^[A-Za-z0-9_-]{3,16}$'
		and not exists (select 1 from public.profils where lower(pseudo) = lower(p_pseudo));
$$;


-- ---------------------------------------------------------------------
-- 2. SAUVEGARDES : la partie complète du joueur (une ligne par compte)
-- ---------------------------------------------------------------------
create table if not exists public.sauvegardes (
	joueur       uuid primary key default auth.uid() references auth.users (id) on delete cascade,
	donnees      jsonb not null,
	version_jeu  text not null default '',
	maj          timestamptz not null default now(),
	constraint sauvegarde_taille check (pg_column_size(donnees) < 3000000)
);

-- L'heure de mise à jour est toujours celle du serveur (sert à comparer les appareils).
create or replace function public.sauvegarde_horodatage() returns trigger
language plpgsql as $$
begin
	new.maj := now();
	return new;
end $$;
drop trigger if exists sauvegarde_maj on public.sauvegardes;
create trigger sauvegarde_maj before insert or update on public.sauvegardes
	for each row execute function public.sauvegarde_horodatage();

alter table public.sauvegardes enable row level security;
drop policy if exists sauvegarde_lecture on public.sauvegardes;
create policy sauvegarde_lecture on public.sauvegardes for select to authenticated using (joueur = auth.uid());
drop policy if exists sauvegarde_ajout on public.sauvegardes;
create policy sauvegarde_ajout on public.sauvegardes for insert to authenticated with check (joueur = auth.uid());
drop policy if exists sauvegarde_modif on public.sauvegardes;
create policy sauvegarde_modif on public.sauvegardes for update to authenticated
	using (joueur = auth.uid()) with check (joueur = auth.uid());

revoke all on public.sauvegardes from anon, authenticated;
grant select, insert, update on public.sauvegardes to authenticated;


-- ---------------------------------------------------------------------
-- 3. AMIS
-- ---------------------------------------------------------------------
create table if not exists public.amities (
	demandeur  uuid not null references public.profils (id) on delete cascade,
	receveur   uuid not null references public.profils (id) on delete cascade,
	statut     text not null default 'attente' check (statut in ('attente', 'acceptee')),
	cree_le    timestamptz not null default now(),
	primary key (demandeur, receveur),
	check (demandeur <> receveur)
);
create index if not exists amities_receveur on public.amities (receveur);

alter table public.amities enable row level security;
drop policy if exists amities_lecture on public.amities;
create policy amities_lecture on public.amities for select to authenticated
	using (auth.uid() in (demandeur, receveur));
revoke all on public.amities from anon, authenticated;
grant select on public.amities to authenticated;

create or replace function public.amis_max() returns int language sql immutable as $$ select 100 $$;

create or replace function public._nb_amis(p_joueur uuid) returns int
language sql stable security definer set search_path = public as $$
	select count(*)::int from public.amities
	where statut = 'acceptee' and p_joueur in (demandeur, receveur);
$$;

-- Envoie une demande d'ami par pseudo.
-- Réponses : introuvable, soi_meme, deja_ami, deja_envoyee, acceptee (il t'avait déjà demandé), limite, envoyee
create or replace function public.envoyer_demande_ami(p_pseudo text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi   uuid := auth.uid();
	cible uuid;
	lien  public.amities;
begin
	if moi is null then return 'non_connecte'; end if;
	select id into cible from public.profils where lower(pseudo) = lower(trim(p_pseudo));
	if cible is null then return 'introuvable'; end if;
	if cible = moi then return 'soi_meme'; end if;

	select * into lien from public.amities
	where (demandeur = moi and receveur = cible) or (demandeur = cible and receveur = moi);
	if found then
		if lien.statut = 'acceptee' then return 'deja_ami'; end if;
		if lien.demandeur = moi then return 'deja_envoyee'; end if;
		-- Il m'avait déjà envoyé une demande : on accepte directement.
		if public._nb_amis(moi) >= public.amis_max() then return 'limite'; end if;
		update public.amities set statut = 'acceptee' where demandeur = cible and receveur = moi;
		return 'acceptee';
	end if;

	if public._nb_amis(moi) >= public.amis_max() then return 'limite'; end if;
	insert into public.amities (demandeur, receveur) values (moi, cible);
	return 'envoyee';
end $$;

-- Accepte ou refuse une demande reçue. Réponses : acceptee, refusee, introuvable, limite
create or replace function public.repondre_demande_ami(p_joueur uuid, p_accepter boolean) returns text
language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
	if moi is null then return 'non_connecte'; end if;
	if not exists (select 1 from public.amities where demandeur = p_joueur and receveur = moi and statut = 'attente') then
		return 'introuvable';
	end if;
	if not p_accepter then
		delete from public.amities where demandeur = p_joueur and receveur = moi;
		return 'refusee';
	end if;
	if public._nb_amis(moi) >= public.amis_max() or public._nb_amis(p_joueur) >= public.amis_max() then
		return 'limite';
	end if;
	update public.amities set statut = 'acceptee' where demandeur = p_joueur and receveur = moi;
	return 'acceptee';
end $$;

-- Retire un ami, ou annule une demande envoyée.
create or replace function public.retirer_ami(p_joueur uuid) returns text
language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
	if moi is null then return 'non_connecte'; end if;
	delete from public.amities
	where (demandeur = moi and receveur = p_joueur) or (demandeur = p_joueur and receveur = moi);
	return 'ok';
end $$;


-- ---------------------------------------------------------------------
-- 4. GUILDES
-- ---------------------------------------------------------------------
create table if not exists public.guildes (
	id           uuid primary key default gen_random_uuid(),
	nom          text not null check (nom ~ '^[A-Za-zÀ-ÖØ-öø-ÿ0-9 ''_-]{3,20}$'),
	description  text not null default '' check (char_length(description) <= 200),
	recrutement  text not null default 'ouvert' check (recrutement in ('ouvert', 'demande', 'ferme')),
	niveau_min   int  not null default 1 check (niveau_min between 1 and 999),
	niveau       int  not null default 1,
	cree_le      timestamptz not null default now()
);
create unique index if not exists guildes_nom_unique on public.guildes (lower(nom));

create table if not exists public.guilde_membres (
	joueur     uuid primary key references public.profils (id) on delete cascade,  -- 1 guilde max par joueur
	guilde     uuid not null references public.guildes (id) on delete cascade,
	role       text not null default 'membre' check (role in ('chef', 'officier', 'membre')),
	rejoint_le timestamptz not null default now()
);
create index if not exists guilde_membres_guilde on public.guilde_membres (guilde);

create table if not exists public.guilde_demandes (
	guilde   uuid not null references public.guildes (id) on delete cascade,
	joueur   uuid not null references public.profils (id) on delete cascade,
	cree_le  timestamptz not null default now(),
	primary key (guilde, joueur)
);

alter table public.guildes enable row level security;
alter table public.guilde_membres enable row level security;
alter table public.guilde_demandes enable row level security;
drop policy if exists guildes_lecture on public.guildes;
create policy guildes_lecture on public.guildes for select to authenticated using (true);
drop policy if exists membres_lecture on public.guilde_membres;
create policy membres_lecture on public.guilde_membres for select to authenticated using (true);
drop policy if exists demandes_lecture on public.guilde_demandes;
create policy demandes_lecture on public.guilde_demandes for select to authenticated using (joueur = auth.uid());
revoke all on public.guildes, public.guilde_membres, public.guilde_demandes from anon, authenticated;
grant select on public.guildes, public.guilde_membres, public.guilde_demandes to authenticated;

create or replace function public.guilde_capacite() returns int language sql immutable as $$ select 30 $$;

-- Rôle du joueur connecté dans une guilde ('' s'il n'en fait pas partie).
create or replace function public._mon_role(p_guilde uuid) returns text
language sql stable security definer set search_path = public as $$
	select coalesce((select role from public.guilde_membres where joueur = auth.uid() and guilde = p_guilde), '');
$$;

-- Crée une guilde (le créateur devient chef).
-- Réponses : deja_membre, nom_invalide, nom_pris, ok
create or replace function public.creer_guilde(p_nom text, p_description text, p_recrutement text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi uuid := auth.uid();
	g   uuid;
begin
	if moi is null then return 'non_connecte'; end if;
	if exists (select 1 from public.guilde_membres where joueur = moi) then return 'deja_membre'; end if;
	p_nom := trim(regexp_replace(p_nom, '\s+', ' ', 'g'));
	if p_nom !~ '^[A-Za-zÀ-ÖØ-öø-ÿ0-9 ''_-]{3,20}$' then return 'nom_invalide'; end if;
	if exists (select 1 from public.guildes where lower(nom) = lower(p_nom)) then return 'nom_pris'; end if;
	if p_recrutement not in ('ouvert', 'demande', 'ferme') then p_recrutement := 'ouvert'; end if;
	insert into public.guildes (nom, description, recrutement)
		values (p_nom, left(coalesce(p_description, ''), 200), p_recrutement) returning id into g;
	insert into public.guilde_membres (joueur, guilde, role) values (moi, g, 'chef');
	delete from public.guilde_demandes where joueur = moi;
	return 'ok';
end $$;

-- Rejoindre (recrutement ouvert) ou postuler (sur demande).
-- Réponses : deja_membre, introuvable, fermee, niveau, pleine, deja_demande, rejoint, demande_envoyee
create or replace function public.postuler_guilde(p_guilde uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi uuid := auth.uid();
	g   public.guildes;
	mon_niveau int;
begin
	if moi is null then return 'non_connecte'; end if;
	if exists (select 1 from public.guilde_membres where joueur = moi) then return 'deja_membre'; end if;
	select * into g from public.guildes where id = p_guilde;
	if not found then return 'introuvable'; end if;
	if g.recrutement = 'ferme' then return 'fermee'; end if;
	select niveau into mon_niveau from public.profils where id = moi;
	if coalesce(mon_niveau, 1) < g.niveau_min then return 'niveau'; end if;
	if (select count(*) from public.guilde_membres where guilde = g.id) >= public.guilde_capacite() then return 'pleine'; end if;
	if g.recrutement = 'ouvert' then
		insert into public.guilde_membres (joueur, guilde) values (moi, g.id);
		delete from public.guilde_demandes where joueur = moi;
		return 'rejoint';
	end if;
	if exists (select 1 from public.guilde_demandes where guilde = g.id and joueur = moi) then return 'deja_demande'; end if;
	insert into public.guilde_demandes (guilde, joueur) values (g.id, moi);
	return 'demande_envoyee';
end $$;

create or replace function public.annuler_demande_guilde(p_guilde uuid) returns text
language plpgsql security definer set search_path = public as $$
begin
	delete from public.guilde_demandes where guilde = p_guilde and joueur = auth.uid();
	return 'ok';
end $$;

-- Chef ou officier : accepter / refuser un candidat.
-- Réponses : interdit, introuvable, deja_membre, pleine, acceptee, refusee
create or replace function public.repondre_demande_guilde(p_joueur uuid, p_accepter boolean) returns text
language plpgsql security definer set search_path = public as $$
declare g uuid;
begin
	if auth.uid() is null then return 'non_connecte'; end if;
	select guilde into g from public.guilde_membres where joueur = auth.uid() and role in ('chef', 'officier');
	if g is null then return 'interdit'; end if;
	if not exists (select 1 from public.guilde_demandes where guilde = g and joueur = p_joueur) then return 'introuvable'; end if;
	if not p_accepter then
		delete from public.guilde_demandes where guilde = g and joueur = p_joueur;
		return 'refusee';
	end if;
	if exists (select 1 from public.guilde_membres where joueur = p_joueur) then
		delete from public.guilde_demandes where joueur = p_joueur;
		return 'deja_membre';
	end if;
	if (select count(*) from public.guilde_membres where guilde = g) >= public.guilde_capacite() then return 'pleine'; end if;
	insert into public.guilde_membres (joueur, guilde) values (p_joueur, g);
	delete from public.guilde_demandes where joueur = p_joueur;
	return 'acceptee';
end $$;

-- Quitter sa guilde. Si le chef part, le plus ancien officier (sinon membre) devient chef.
-- Si c'était le dernier membre, la guilde est dissoute. Réponses : pas_de_guilde, ok, dissoute
create or replace function public.quitter_guilde() returns text
language plpgsql security definer set search_path = public as $$
declare
	moi uuid := auth.uid();
	m   public.guilde_membres;
	successeur uuid;
begin
	if moi is null then return 'non_connecte'; end if;
	select * into m from public.guilde_membres where joueur = moi;
	if not found then return 'pas_de_guilde'; end if;
	delete from public.guilde_membres where joueur = moi;
	if not exists (select 1 from public.guilde_membres where guilde = m.guilde) then
		delete from public.guildes where id = m.guilde;
		return 'dissoute';
	end if;
	if m.role = 'chef' then
		select joueur into successeur from public.guilde_membres where guilde = m.guilde
			order by (role = 'officier') desc, rejoint_le asc limit 1;
		update public.guilde_membres set role = 'chef' where joueur = successeur;
	end if;
	return 'ok';
end $$;

-- Gestion des membres. p_action : promouvoir, retrograder, exclure, nommer_chef
-- Chef : tout. Officier : exclure un simple membre.
-- Réponses : interdit, introuvable, ok
create or replace function public.gerer_membre(p_joueur uuid, p_action text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi   public.guilde_membres;
	cible public.guilde_membres;
begin
	if auth.uid() is null then return 'non_connecte'; end if;
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found or moi.role = 'membre' then return 'interdit'; end if;
	select * into cible from public.guilde_membres where joueur = p_joueur and guilde = moi.guilde;
	if not found or cible.joueur = moi.joueur then return 'introuvable'; end if;

	if p_action = 'exclure' then
		if moi.role = 'officier' and cible.role <> 'membre' then return 'interdit'; end if;
		delete from public.guilde_membres where joueur = cible.joueur;
		return 'ok';
	end if;
	if moi.role <> 'chef' then return 'interdit'; end if;
	if p_action = 'promouvoir' then
		update public.guilde_membres set role = 'officier' where joueur = cible.joueur;
	elsif p_action = 'retrograder' then
		update public.guilde_membres set role = 'membre' where joueur = cible.joueur;
	elsif p_action = 'nommer_chef' then
		update public.guilde_membres set role = 'officier' where joueur = moi.joueur;
		update public.guilde_membres set role = 'chef' where joueur = cible.joueur;
	else
		return 'introuvable';
	end if;
	return 'ok';
end $$;

-- Chef ou officier : description, recrutement, niveau minimum. Réponses : interdit, ok
create or replace function public.modifier_guilde(p_description text, p_recrutement text, p_niveau_min int) returns text
language plpgsql security definer set search_path = public as $$
declare g uuid;
begin
	select guilde into g from public.guilde_membres where joueur = auth.uid() and role in ('chef', 'officier');
	if g is null then return 'interdit'; end if;
	update public.guildes set
		description = left(coalesce(p_description, ''), 200),
		recrutement = case when p_recrutement in ('ouvert', 'demande', 'ferme') then p_recrutement else recrutement end,
		niveau_min  = greatest(1, least(999, coalesce(p_niveau_min, 1)))
	where id = g;
	return 'ok';
end $$;

-- Recherche de guildes (texte vide = les plus peuplées).
create or replace function public.chercher_guildes(p_texte text)
returns table (id uuid, nom text, description text, recrutement text, niveau_min int, niveau int,
	membres int, chef text, demande_envoyee boolean)
language sql stable security definer set search_path = public as $$
	select g.id, g.nom, g.description, g.recrutement, g.niveau_min, g.niveau,
		(select count(*)::int from public.guilde_membres m where m.guilde = g.id),
		(select p.pseudo from public.guilde_membres m join public.profils p on p.id = m.joueur
			where m.guilde = g.id and m.role = 'chef' limit 1),
		exists (select 1 from public.guilde_demandes d where d.guilde = g.id and d.joueur = auth.uid())
	from public.guildes g
	where coalesce(trim(p_texte), '') = '' or g.nom ilike '%' || trim(p_texte) || '%'
	order by 7 desc, g.cree_le asc
	limit 30;
$$;

-- Tout ce qu'il faut pour l'écran Guilde (null si le joueur n'a pas de guilde).
create or replace function public.ma_guilde() returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	res jsonb;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return null; end if;
	select jsonb_build_object(
		'id', g.id, 'nom', g.nom, 'description', g.description, 'recrutement', g.recrutement,
		'niveau_min', g.niveau_min, 'niveau', g.niveau, 'cree_le', g.cree_le,
		'capacite', public.guilde_capacite(), 'mon_role', moi.role,
		'membres', coalesce((select jsonb_agg(jsonb_build_object(
				'id', p.id, 'pseudo', p.pseudo, 'niveau', p.niveau, 'heros_vitrine', p.heros_vitrine,
				'vu_le', p.vu_le, 'role', m.role, 'rejoint_le', m.rejoint_le)
				order by case m.role when 'chef' then 0 when 'officier' then 1 else 2 end, p.niveau desc)
			from public.guilde_membres m join public.profils p on p.id = m.joueur where m.guilde = g.id), '[]'::jsonb),
		'demandes', case when moi.role in ('chef', 'officier') then coalesce((select jsonb_agg(jsonb_build_object(
				'id', p.id, 'pseudo', p.pseudo, 'niveau', p.niveau, 'heros_vitrine', p.heros_vitrine, 'cree_le', d.cree_le)
				order by d.cree_le)
			from public.guilde_demandes d join public.profils p on p.id = d.joueur where d.guilde = g.id), '[]'::jsonb)
			else '[]'::jsonb end)
	into res
	from public.guildes g where g.id = moi.guilde;
	return res;
end $$;

-- Liste pour l'écran Social : amis, demandes reçues, demandes envoyées.
-- relation : 'ami', 'recue', 'envoyee'
create or replace function public.mes_amis()
returns table (id uuid, pseudo text, niveau int, heros_vitrine text, vu_le timestamptz, guilde text, relation text)
language sql stable security definer set search_path = public as $$
	select p.id, p.pseudo, p.niveau, p.heros_vitrine, p.vu_le,
		coalesce((select g.nom from public.guilde_membres m join public.guildes g on g.id = m.guilde where m.joueur = p.id), ''),
		case when a.statut = 'acceptee' then 'ami' when a.receveur = auth.uid() then 'recue' else 'envoyee' end
	from public.amities a
	join public.profils p on p.id = case when a.demandeur = auth.uid() then a.receveur else a.demandeur end
	where auth.uid() in (a.demandeur, a.receveur)
	order by 7, p.vu_le desc;
$$;

-- Profil public d'un joueur (écran Social > Profil).
create or replace function public.profil_joueur(p_joueur uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('id', p.id, 'pseudo', p.pseudo, 'niveau', p.niveau,
		'heros_vitrine', p.heros_vitrine, 'vu_le', p.vu_le, 'cree_le', p.cree_le,
		'guilde', coalesce((select g.nom from public.guilde_membres m join public.guildes g on g.id = m.guilde where m.joueur = p.id), ''),
		'role', coalesce((select m.role from public.guilde_membres m where m.joueur = p.id), ''))
	from public.profils p where p.id = p_joueur;
$$;


-- ---------------------------------------------------------------------
-- 5. DROITS D'EXÉCUTION DES FONCTIONS
-- ---------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on function public.pseudo_disponible(text) to anon, authenticated;
grant execute on function
	public.envoyer_demande_ami(text), public.repondre_demande_ami(uuid, boolean), public.retirer_ami(uuid),
	public.mes_amis(), public.profil_joueur(uuid),
	public.creer_guilde(text, text, text), public.postuler_guilde(uuid), public.annuler_demande_guilde(uuid),
	public.repondre_demande_guilde(uuid, boolean), public.quitter_guilde(), public.gerer_membre(uuid, text),
	public.modifier_guilde(text, text, int), public.chercher_guildes(text), public.ma_guilde(),
	public.amis_max(), public.guilde_capacite()
to authenticated;
