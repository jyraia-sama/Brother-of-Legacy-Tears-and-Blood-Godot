-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — base de données en ligne
--  Étape 2 : ARÈNE JcJ (défenses, combats, classement, saisons, boutique).
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  (Le fichier 01_comptes_amis_guildes.sql doit avoir été lancé avant.)
--  Le script peut être relancé sans danger (il ne supprime aucune donnée).
--
--  Ce que le SERVEUR contrôle (impossible à tricher en modifiant sa sauvegarde) :
--   points de classement, essais par jour, Insignes d'Arène, achats de la boutique,
--   récompenses de saison, graine du combat, un seul résultat par combat.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Réglages (modifie les nombres ici puis relance le script)
-- ---------------------------------------------------------------------
create or replace function public.arene_reglages() returns jsonb language sql immutable as $$
	select jsonb_build_object(
		'points_depart', 1000,
		'essais_gratuits', 5,          -- combats gratuits par jour
		'essais_payants_max', 10,      -- combats en plus (payés en gemmes dans le jeu)
		'cout_essai_gemmes', 20,
		'duree_saison_jours', 14,
		'max_contre_meme_joueur', 3,   -- attaques par jour contre le même adversaire
		'insignes_victoire', 30,
		'insignes_defaite', 10,
		'minutes_pour_finir', 15       -- délai pour envoyer le résultat d'un combat
	)
$$;

-- Paliers : points minimum. « Légende » = top 10 avec au moins 1800 points.
create or replace function public.arene_palier(p_points int, p_rang int) returns text
language sql immutable as $$
	select case
		when p_rang between 1 and 10 and p_points >= 1800 then 'legende'
		when p_points >= 1800 then 'diamant'
		when p_points >= 1500 then 'platine'
		when p_points >= 1300 then 'or'
		when p_points >= 1100 then 'argent'
		else 'bronze' end
$$;

-- Récompenses de fin de saison par palier
create or replace function public.arene_recompense_palier(p_palier text) returns jsonb
language sql immutable as $$
	select case p_palier
		when 'legende' then '{"insignes": 1000, "gemmes": 250}'
		when 'diamant' then '{"insignes": 750, "gemmes": 150}'
		when 'platine' then '{"insignes": 500, "gemmes": 100}'
		when 'or'      then '{"insignes": 350, "gemmes": 70}'
		when 'argent'  then '{"insignes": 200, "gemmes": 40}'
		else                '{"insignes": 100, "gemmes": 20}' end::jsonb
$$;

-- Boutique : prix en Insignes et limite d'achats par saison
create or replace function public.arene_boutique() returns jsonb language sql immutable as $$
	select '[
		{"id": "elixir_petit",    "prix": 40,  "quantite": 1,  "limite": 20},
		{"id": "coffre_argent",   "prix": 60,  "quantite": 1,  "limite": 10},
		{"id": "poussiere_echo",  "prix": 60,  "quantite": 20, "limite": 10},
		{"id": "tome_grand",      "prix": 90,  "quantite": 1,  "limite": 10},
		{"id": "elixir_grand",    "prix": 110, "quantite": 1,  "limite": 10},
		{"id": "eclat_superieur", "prix": 150, "quantite": 1,  "limite": 5},
		{"id": "coffre_or",       "prix": 180, "quantite": 1,  "limite": 5},
		{"id": "pierre_eveil",    "prix": 400, "quantite": 1,  "limite": 2}
	]'::jsonb
$$;


-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
create table if not exists public.arene_saisons (
	numero  int primary key,
	debut   timestamptz not null,
	fin     timestamptz not null
);

-- Un joueur dans l'Arène : sa défense, ses points, ses essais du jour, ses Insignes.
create table if not exists public.arene_joueurs (
	joueur          uuid primary key references public.profils (id) on delete cascade,
	equipe          jsonb not null default '[]'::jsonb,   -- équipe de défense (5 places max)
	puissance       int  not null default 0,
	points          int  not null default 1000,
	saison          int  not null default 0,
	victoires       int  not null default 0,
	defaites        int  not null default 0,
	insignes        int  not null default 0,
	jour_essais     date,
	essais_utilises int  not null default 0,
	essais_payes    int  not null default 0,
	achats          jsonb not null default '{}'::jsonb,   -- achats de la saison {article: nombre}
	maj_defense     timestamptz not null default now()
);
create index if not exists arene_joueurs_points on public.arene_joueurs (points desc);

-- Combats : ouverts par arene_commencer, fermés par arene_terminer.
create table if not exists public.arene_combats (
	id          uuid primary key default gen_random_uuid(),
	attaquant   uuid not null references public.profils (id) on delete cascade,
	defenseur   uuid references public.profils (id) on delete cascade,   -- null = gardien d'entraînement
	graine      bigint not null,
	cree_le     timestamptz not null default now(),
	fini_le     timestamptz,
	victoire    boolean,
	points_att  int,
	points_def  int,
	insignes    int
);
create index if not exists arene_combats_att on public.arene_combats (attaquant, cree_le desc);
create index if not exists arene_combats_def on public.arene_combats (defenseur, cree_le desc);

-- Récompenses de fin de saison en attente
create table if not exists public.arene_recompenses (
	joueur    uuid not null references public.profils (id) on delete cascade,
	saison    int  not null,
	palier    text not null,
	rang      int  not null,
	points    int  not null,
	insignes  int  not null,
	gemmes    int  not null,
	reclamee  boolean not null default false,
	primary key (joueur, saison)
);

alter table public.arene_saisons enable row level security;
alter table public.arene_joueurs enable row level security;
alter table public.arene_combats enable row level security;
alter table public.arene_recompenses enable row level security;
drop policy if exists saisons_lecture on public.arene_saisons;
create policy saisons_lecture on public.arene_saisons for select to authenticated using (true);
revoke all on public.arene_saisons, public.arene_joueurs, public.arene_combats, public.arene_recompenses from anon, authenticated;
grant select on public.arene_saisons to authenticated;
-- Tout le reste passe par les fonctions ci-dessous.


-- ---------------------------------------------------------------------
-- Saison en cours (créée ou clôturée automatiquement)
-- ---------------------------------------------------------------------
create or replace function public._arene_saison() returns public.arene_saisons
language plpgsql security definer set search_path = public as $$
declare
	s public.arene_saisons;
	duree interval := make_interval(days => (public.arene_reglages() ->> 'duree_saison_jours')::int);
	depart int := (public.arene_reglages() ->> 'points_depart')::int;
begin
	select * into s from public.arene_saisons order by numero desc limit 1;
	if found and s.fin > now() then
		return s;
	end if;
	-- Un seul appel à la fois clôture la saison
	perform pg_advisory_xact_lock(424242);
	select * into s from public.arene_saisons order by numero desc limit 1;
	if found and s.fin > now() then
		return s;
	end if;
	if found then
		-- Récompenses selon le classement final
		insert into public.arene_recompenses (joueur, saison, palier, rang, points, insignes, gemmes)
		select c.joueur, s.numero, c.palier, c.rang, c.points,
			(public.arene_recompense_palier(c.palier) ->> 'insignes')::int,
			(public.arene_recompense_palier(c.palier) ->> 'gemmes')::int
		from (
			select j.joueur, j.points, rank() over (order by j.points desc)::int as rang,
				public.arene_palier(j.points, (rank() over (order by j.points desc))::int) as palier
			from public.arene_joueurs j
			where j.saison = s.numero and (j.victoires + j.defaites) > 0
		) c
		on conflict do nothing;
		-- Remise à zéro partielle : on garde la moitié de l'écart avec le départ
		update public.arene_joueurs set
			points = depart + (points - depart) / 2,
			victoires = 0, defaites = 0, achats = '{}'::jsonb,
			saison = s.numero + 1;
		insert into public.arene_saisons (numero, debut, fin)
			values (s.numero + 1, now(), greatest(s.fin + duree, now() + interval '1 day'))
			returning * into s;
	else
		insert into public.arene_saisons (numero, debut, fin)
			values (1, now(), now() + duree) returning * into s;
	end if;
	return s;
end $$;

-- Ligne du joueur connecté (créée si besoin), avec essais remis à zéro chaque jour.
create or replace function public._arene_moi() returns public.arene_joueurs
language plpgsql security definer set search_path = public as $$
declare
	moi uuid := auth.uid();
	j public.arene_joueurs;
	s public.arene_saisons := public._arene_saison();
	aujourdhui date := (now() at time zone 'Europe/Paris')::date;
begin
	insert into public.arene_joueurs (joueur, points, saison)
		values (moi, (public.arene_reglages() ->> 'points_depart')::int, s.numero)
		on conflict (joueur) do nothing;
	select * into j from public.arene_joueurs where joueur = moi for update;
	if j.saison <> s.numero then
		update public.arene_joueurs set saison = s.numero, victoires = 0, defaites = 0, achats = '{}'::jsonb
			where joueur = moi returning * into j;
	end if;
	if j.jour_essais is distinct from aujourdhui then
		update public.arene_joueurs set jour_essais = aujourdhui, essais_utilises = 0, essais_payes = 0
			where joueur = moi returning * into j;
	end if;
	return j;
end $$;

create or replace function public._arene_rang(p_points int) returns int
language sql stable security definer set search_path = public as $$
	select 1 + count(*)::int from public.arene_joueurs
	where points > p_points and saison = (select max(numero) from public.arene_saisons);
$$;


-- ---------------------------------------------------------------------
-- État de l'Arène pour le joueur connecté
-- ---------------------------------------------------------------------
create or replace function public.arene_etat() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.arene_joueurs;
	s public.arene_saisons;
	r int;
	reg jsonb := public.arene_reglages();
begin
	if auth.uid() is null then return null; end if;
	perform public._arene_regler_abandons();
	j := public._arene_moi();
	select * into s from public.arene_saisons where numero = j.saison;
	r := public._arene_rang(j.points);
	return jsonb_build_object(
		'points', j.points, 'rang', r, 'palier', public.arene_palier(j.points, r),
		'victoires', j.victoires, 'defaites', j.defaites, 'insignes', j.insignes,
		'essais_gratuits_restants', greatest(0, (reg ->> 'essais_gratuits')::int - j.essais_utilises),
		'essais_payants_restants', greatest(0, (reg ->> 'essais_payants_max')::int - j.essais_payes),
		'cout_essai_gemmes', (reg ->> 'cout_essai_gemmes')::int,
		'equipe', j.equipe, 'puissance', j.puissance,
		'saison', s.numero, 'fin_saison', s.fin,
		'achats', j.achats, 'boutique', public.arene_boutique(),
		'recompenses', coalesce((select jsonb_agg(jsonb_build_object('saison', saison, 'palier', palier, 'rang', rang,
			'points', points, 'insignes', insignes, 'gemmes', gemmes) order by saison)
			from public.arene_recompenses where joueur = auth.uid() and not reclamee), '[]'::jsonb));
end $$;


-- ---------------------------------------------------------------------
-- Équipe de défense
-- ---------------------------------------------------------------------
-- p_equipe : [{id, niveau, place, etoiles, echos}, ...] (5 max)
-- Réponses : ok, vide, invalide
create or replace function public.arene_definir_defense(p_equipe jsonb, p_puissance int) returns text
language plpgsql security definer set search_path = public as $$
declare
	u jsonb;
	places int[] := '{}';
begin
	if auth.uid() is null then return 'non_connecte'; end if;
	if jsonb_typeof(p_equipe) <> 'array' or jsonb_array_length(p_equipe) = 0 then return 'vide'; end if;
	if jsonb_array_length(p_equipe) > 5 or pg_column_size(p_equipe) > 20000 then return 'invalide'; end if;
	for u in select * from jsonb_array_elements(p_equipe) loop
		-- Contrôles de vraisemblance : niveau, étoiles, place
		if coalesce(u ->> 'id', '') !~ '^[a-z0-9_]{1,40}$'
			or coalesce((u ->> 'niveau')::int, 0) not between 1 and 30
			or coalesce((u ->> 'etoiles')::int, 0) not between 0 and 6
			or coalesce((u ->> 'place')::int, -1) not between 0 and 4
			or (u ->> 'place')::int = any(places) then
			return 'invalide';
		end if;
		places := places || (u ->> 'place')::int;
	end loop;
	perform public._arene_moi();
	update public.arene_joueurs set equipe = p_equipe, puissance = greatest(0, least(p_puissance, 10000000)),
		maj_defense = now() where joueur = auth.uid();
	return 'ok';
end $$;


-- ---------------------------------------------------------------------
-- Adversaires proposés : un plus faible, un proche, un plus fort
-- ---------------------------------------------------------------------
create or replace function public.arene_adversaires() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.arene_joueurs;
	res jsonb := '[]'::jsonb;
	choix uuid;
	deja uuid[] := '{}';
	tranche record;
begin
	if auth.uid() is null then return '[]'::jsonb; end if;
	j := public._arene_moi();
	for tranche in select * from (values (-400, -60), (-60, 60), (60, 400)) t(bas, haut) loop
		select a.joueur into choix from public.arene_joueurs a
		where a.joueur <> j.joueur and not a.joueur = any(deja)
			and jsonb_array_length(a.equipe) > 0
			and a.points between j.points + tranche.bas and j.points + tranche.haut
		order by random() limit 1;
		if choix is null then
			-- Pas assez de joueurs dans la tranche : le plus proche en points
			select a.joueur into choix from public.arene_joueurs a
			where a.joueur <> j.joueur and not a.joueur = any(deja) and jsonb_array_length(a.equipe) > 0
			order by abs(a.points - (j.points + (tranche.bas + tranche.haut) / 2)) limit 1;
		end if;
		if choix is not null then
			deja := deja || choix;
		end if;
		choix := null;
	end loop;
	select coalesce(jsonb_agg(public._arene_fiche(x) order by a.points), '[]'::jsonb) into res
	from unnest(deja) x join public.arene_joueurs a on a.joueur = x;
	return res;
end $$;

-- Fiche publique d'un défenseur
create or replace function public._arene_fiche(p_joueur uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select jsonb_build_object('id', a.joueur, 'pseudo', p.pseudo, 'niveau', p.niveau,
		'heros_vitrine', p.heros_vitrine, 'points', a.points,
		'palier', public.arene_palier(a.points, public._arene_rang(a.points)),
		'puissance', a.puissance, 'equipe', a.equipe,
		'guilde', coalesce((select g.nom from public.guilde_membres m join public.guildes g on g.id = m.guilde where m.joueur = a.joueur), ''))
	from public.arene_joueurs a join public.profils p on p.id = a.joueur
	where a.joueur = p_joueur;
$$;

create or replace function public.arene_fiche(p_joueur uuid) returns jsonb
language sql stable security definer set search_path = public as $$
	select public._arene_fiche(p_joueur);
$$;


-- ---------------------------------------------------------------------
-- Combat : commencer puis terminer
-- ---------------------------------------------------------------------
-- p_adversaire null = gardien d'entraînement (quand il n'y a pas assez de joueurs).
-- p_payant = utiliser un essai payant (le jeu retire les gemmes).
-- Réponse : {ok, erreur, combat, graine, adversaire}
create or replace function public.arene_commencer(p_adversaire uuid, p_payant boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.arene_joueurs;
	reg jsonb := public.arene_reglages();
	id_combat uuid;
	g bigint := floor(random() * 2000000000)::bigint + 1;
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	perform public._arene_regler_abandons();
	j := public._arene_moi();
	if jsonb_array_length(j.equipe) = 0 then
		return jsonb_build_object('ok', false, 'erreur', 'pas_de_defense');
	end if;
	if p_adversaire = j.joueur then return jsonb_build_object('ok', false, 'erreur', 'soi_meme'); end if;
	if p_adversaire is not null then
		if not exists (select 1 from public.arene_joueurs where joueur = p_adversaire and jsonb_array_length(equipe) > 0) then
			return jsonb_build_object('ok', false, 'erreur', 'introuvable');
		end if;
		if (select count(*) from public.arene_combats where attaquant = j.joueur and defenseur = p_adversaire
				and cree_le > now() - interval '1 day') >= (reg ->> 'max_contre_meme_joueur')::int then
			return jsonb_build_object('ok', false, 'erreur', 'trop_contre_lui');
		end if;
	end if;
	if p_payant then
		if j.essais_payes >= (reg ->> 'essais_payants_max')::int then
			return jsonb_build_object('ok', false, 'erreur', 'plus_d_essais');
		end if;
		update public.arene_joueurs set essais_payes = essais_payes + 1 where joueur = j.joueur;
	else
		if j.essais_utilises >= (reg ->> 'essais_gratuits')::int then
			return jsonb_build_object('ok', false, 'erreur', 'plus_d_essais_gratuits');
		end if;
		update public.arene_joueurs set essais_utilises = essais_utilises + 1 where joueur = j.joueur;
	end if;
	insert into public.arene_combats (attaquant, defenseur, graine) values (j.joueur, p_adversaire, g)
		returning id into id_combat;
	return jsonb_build_object('ok', true, 'combat', id_combat, 'graine', g,
		'adversaire', case when p_adversaire is null then null else public._arene_fiche(p_adversaire) end);
end $$;

-- Envoie le résultat d'un combat (une seule fois).
-- Réponse : {ok, erreur, victoire, points (variation), points_total, insignes, adversaire_points}
create or replace function public.arene_terminer(p_combat uuid, p_victoire boolean) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	c public.arene_combats;
	att public.arene_joueurs;
	def_points int;
	ecart int;
	gain int;
	perte_def int;
	ins int;
	reg jsonb := public.arene_reglages();
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	select * into c from public.arene_combats where id = p_combat and attaquant = auth.uid() for update;
	if not found then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	if c.fini_le is not null then return jsonb_build_object('ok', false, 'erreur', 'deja_termine'); end if;
	-- Trop tard : compté comme une défaite
	if now() - c.cree_le > make_interval(mins => (reg ->> 'minutes_pour_finir')::int) then
		p_victoire := false;
	end if;
	att := public._arene_moi();
	if c.defenseur is null then
		def_points := att.points;          -- gardien d'entraînement : même niveau que toi
	else
		select points into def_points from public.arene_joueurs where joueur = c.defenseur for update;
		def_points := coalesce(def_points, att.points);
	end if;
	ecart := def_points - att.points;
	if p_victoire then
		gain := greatest(5, least(40, round(20 + ecart / 20.0)::int));
		if c.defenseur is null then gain := least(gain, 10); end if;
		perte_def := round(gain / 2.0)::int;
		ins := (reg ->> 'insignes_victoire')::int;
		update public.arene_joueurs set points = points + gain, victoires = victoires + 1, insignes = insignes + ins
			where joueur = att.joueur;
		if c.defenseur is not null then
			update public.arene_joueurs set points = greatest(0, points - perte_def) where joueur = c.defenseur;
		end if;
		update public.arene_combats set fini_le = now(), victoire = true, points_att = gain, points_def = -perte_def,
			insignes = ins where id = c.id;
	else
		gain := -greatest(3, least(20, round(10 - ecart / 40.0)::int));
		if c.defenseur is null then gain := greatest(gain, -5); end if;
		perte_def := round(-gain / 2.0)::int;      -- le défenseur gagne des points
		ins := (reg ->> 'insignes_defaite')::int;
		update public.arene_joueurs set points = greatest(0, points + gain), defaites = defaites + 1, insignes = insignes + ins
			where joueur = att.joueur;
		if c.defenseur is not null then
			update public.arene_joueurs set points = points + perte_def where joueur = c.defenseur;
		end if;
		update public.arene_combats set fini_le = now(), victoire = false, points_att = gain, points_def = perte_def,
			insignes = ins where id = c.id;
	end if;
	select * into att from public.arene_joueurs where joueur = att.joueur;
	return jsonb_build_object('ok', true, 'victoire', p_victoire, 'points', gain, 'points_total', att.points,
		'insignes', ins, 'insignes_total', att.insignes, 'rang', public._arene_rang(att.points),
		'palier', public.arene_palier(att.points, public._arene_rang(att.points)));
end $$;

-- Combats abandonnés (jeu fermé pendant le combat) : comptés comme des défaites.
create or replace function public._arene_regler_abandons() returns void
language plpgsql security definer set search_path = public as $$
declare c record;
begin
	for c in select id from public.arene_combats
		where attaquant = auth.uid() and fini_le is null
			and cree_le < now() - make_interval(mins => (public.arene_reglages() ->> 'minutes_pour_finir')::int)
	loop
		perform public.arene_terminer(c.id, false);
	end loop;
end $$;


-- ---------------------------------------------------------------------
-- Classement, historique, boutique, récompenses de saison
-- ---------------------------------------------------------------------
create or replace function public.arene_classement(p_limite int) returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce(jsonb_agg(x order by (x ->> 'rang')::int, x ->> 'pseudo'), '[]'::jsonb) from (
		select jsonb_build_object('rang', rank() over (order by a.points desc), 'id', a.joueur, 'pseudo', p.pseudo,
			'niveau', p.niveau, 'heros_vitrine', p.heros_vitrine, 'points', a.points,
			'victoires', a.victoires, 'defaites', a.defaites,
			'palier', public.arene_palier(a.points, (rank() over (order by a.points desc))::int),
			'guilde', coalesce((select g.nom from public.guilde_membres m join public.guildes g on g.id = m.guilde where m.joueur = a.joueur), '')) x
		from public.arene_joueurs a join public.profils p on p.id = a.joueur
		where a.saison = (select max(numero) from public.arene_saisons)
			and (jsonb_array_length(a.equipe) > 0 or a.victoires + a.defaites > 0)
		order by a.points desc
		limit greatest(1, least(coalesce(p_limite, 100), 200))
	) t;
$$;

-- 30 derniers combats où le joueur était attaquant ou défenseur
create or replace function public.arene_historique() returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce(jsonb_agg(x order by x ->> 'date' desc), '[]'::jsonb) from (
		select jsonb_build_object(
			'id', c.id, 'date', c.fini_le,
			'attaque', c.attaquant = auth.uid(),
			'autre_id', case when c.attaquant = auth.uid() then c.defenseur else c.attaquant end,
			'autre_pseudo', coalesce((select pseudo from public.profils where id =
				case when c.attaquant = auth.uid() then c.defenseur else c.attaquant end), 'Gardien de l''Arène'),
			-- Victoire du point de vue du joueur connecté
			'victoire', case when c.attaquant = auth.uid() then c.victoire else not c.victoire end,
			'points', case when c.attaquant = auth.uid() then c.points_att else c.points_def end) x
		from public.arene_combats c
		where (c.attaquant = auth.uid() or c.defenseur = auth.uid()) and c.fini_le is not null
		order by c.fini_le desc limit 30
	) t;
$$;

-- Achat dans la boutique (le serveur retire les Insignes, le jeu donne l'objet).
-- Réponse : {ok, erreur, id, quantite, insignes}
create or replace function public.arene_acheter(p_article text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	j public.arene_joueurs;
	a jsonb;
	deja int;
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	select x into a from jsonb_array_elements(public.arene_boutique()) x where x ->> 'id' = p_article;
	if a is null then return jsonb_build_object('ok', false, 'erreur', 'introuvable'); end if;
	j := public._arene_moi();
	deja := coalesce((j.achats ->> p_article)::int, 0);
	if deja >= (a ->> 'limite')::int then return jsonb_build_object('ok', false, 'erreur', 'limite'); end if;
	if j.insignes < (a ->> 'prix')::int then return jsonb_build_object('ok', false, 'erreur', 'pas_assez'); end if;
	update public.arene_joueurs set insignes = insignes - (a ->> 'prix')::int,
		achats = achats || jsonb_build_object(p_article, deja + 1)
		where joueur = j.joueur returning * into j;
	return jsonb_build_object('ok', true, 'id', p_article, 'quantite', (a ->> 'quantite')::int, 'insignes', j.insignes);
end $$;

-- Réclame les récompenses de saison en attente (Insignes crédités ici, gemmes données par le jeu).
-- Réponse : {ok, insignes, gemmes}
create or replace function public.arene_reclamer() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	ins int;
	gem int;
begin
	if auth.uid() is null then return jsonb_build_object('ok', false, 'erreur', 'non_connecte'); end if;
	perform public._arene_moi();
	with r as (
		update public.arene_recompenses set reclamee = true
		where joueur = auth.uid() and not reclamee returning insignes, gemmes)
	select coalesce(sum(insignes), 0), coalesce(sum(gemmes), 0) into ins, gem from r;
	update public.arene_joueurs set insignes = insignes + ins where joueur = auth.uid();
	return jsonb_build_object('ok', true, 'insignes', ins, 'gemmes', gem);
end $$;


-- ---------------------------------------------------------------------
-- Droits d'exécution
-- ---------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on function public.pseudo_disponible(text) to anon, authenticated;
grant execute on function
	public.arene_etat(), public.arene_definir_defense(jsonb, int), public.arene_adversaires(),
	public.arene_fiche(uuid), public.arene_commencer(uuid, boolean), public.arene_terminer(uuid, boolean),
	public.arene_classement(int), public.arene_historique(), public.arene_acheter(text), public.arene_reclamer(),
	public.arene_reglages(), public.arene_palier(int, int), public.arene_boutique(), public.arene_recompense_palier(text)
to authenticated;
-- Les fonctions internes (nom commençant par _) ne sont pas appelables directement.
revoke execute on function public._arene_saison(), public._arene_moi(), public._arene_rang(int),
	public._arene_fiche(uuid), public._arene_regler_abandons(), public._nb_amis(uuid), public._mon_role(uuid) from authenticated;
