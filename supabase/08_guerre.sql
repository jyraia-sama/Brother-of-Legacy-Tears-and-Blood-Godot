-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — la Guerre des Bannières (v0.57)
--  Guerre de guildes hebdomadaire, en asynchrone.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, APRÈS les fichiers 01 et 05. Peut être relancé sans danger.
--
--  La semaine (heure de Paris) :
--    lundi, mardi        : PRÉPARATION (inscription de la guilde, défenses de guerre)
--    mercredi → samedi   : ASSAUTS (2 attaques par jour et par membre)
--    dimanche            : BILAN (vainqueur, butin)
--  Au premier passage d'un membre pendant les assauts, la guilde inscrite reçoit un adversaire :
--  une autre guilde inscrite de force proche, sinon LA LÉGION DE LA SOIF (guilde fantôme faite
--  de reflets de défenses de joueurs). Les défenses sont figées à ce moment-là.
--
--  Forteresse : un poste par membre, en 3 couches (Remparts, Tours, Donjon) rangées par puissance.
--  Une couche ne s'attaque qu'une fois la précédente percée (chaque poste pris au moins 1 étoile).
--  Étoiles d'une attaque (calculées par le jeu, bornées ici) : 1 = victoire, 2 = victoire avec
--  3 unités debout ou plus, 3 = victoire sans perte. Seul le meilleur résultat par poste compte.
--  Fatigue : une unité qui a attaqué ne peut plus attaquer avant le lendemain.
--
--  RÉGLAGES : guerre_reglages() juste en dessous.
-- =====================================================================

create or replace function public.guerre_reglages() returns jsonb language sql immutable as $$
	select jsonb_build_object(
		'attaques_jour', 2,
		'eclaireurs_jour', 1,
		-- Légion de la Soif : part des étoiles possibles qu'elle prend, sur les 4 jours d'assaut
		'legion_part', 0.55,
		-- Appariement : rapport de puissance maximal entre deux vraies guildes
		'rapport_puissance_max', 1.6,
		-- Butin (par membre ayant attaqué au moins une fois). Sceaux = Sceaux de guilde (boutique de guilde)
		'sceaux', jsonb_build_object('victoire', 60, 'egalite', 40, 'defaite', 25),
		'sceaux_par_etoile', 4,
		'sceaux_max', 140,
		'butin', jsonb_build_object(
			'victoire', jsonb_build_object('or', 25000, 'coffre_or', 1, 'tome_grand', 1),
			'egalite',  jsonb_build_object('or', 15000, 'coffre_argent', 1),
			'defaite',  jsonb_build_object('or', 8000)),
		-- Pour la guilde (une fois par guerre)
		'guilde_xp', jsonb_build_object('victoire', 300, 'egalite', 180, 'defaite', 100),
		'guilde_tresor', jsonb_build_object('victoire', 200, 'egalite', 120, 'defaite', 60)
	)
$$;

-- Noms des postes de la Légion de la Soif
create or replace function public._guerre_noms_legion() returns text[] language sql immutable as $$
	select array['Sentinelle de la Soif', 'Écorcheur des Cendres', 'Veilleur Sanglant', 'Lame de l''Éclipse',
		'Gardien des Ronces', 'Croc de la Nuit', 'Héraut du Sceau Brisé', 'Bourreau Pâle',
		'Chevalier Exsangue', 'Prêtresse des Larmes Noires', 'Lieutenant de la Soif', 'Capitaine Carmin',
		'Seigneur des Charniers', 'Main de l''Héritier', 'Champion de la Soif']
$$;


-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
alter table public.guildes add column if not exists guerre_inscrite boolean not null default false;
alter table public.guildes add column if not exists guerre_victoires int not null default 0;
alter table public.guildes add column if not exists guerre_egalites int not null default 0;
alter table public.guildes add column if not exists guerre_defaites int not null default 0;

-- Défense de guerre de chaque joueur (gardée d'une semaine à l'autre)
create table if not exists public.guerre_defenses (
	joueur     uuid primary key references public.profils (id) on delete cascade,
	equipe     jsonb not null,
	puissance  int not null default 0,
	elements   jsonb not null default '[]'::jsonb,
	maj        timestamptz not null default now()
);

create table if not exists public.guerres (
	id          uuid primary key default gen_random_uuid(),
	semaine     date not null,
	guilde_a    uuid not null references public.guildes (id) on delete cascade,
	guilde_b    uuid references public.guildes (id) on delete cascade,      -- null = Légion de la Soif
	nom_b       text not null default 'La Légion de la Soif',
	etoiles_a   int not null default 0,
	etoiles_b   int not null default 0,
	gagnant     int,                       -- 0 = A, 1 = B, -1 = égalité (rempli au bilan)
	finie       boolean not null default false,
	cree_le     timestamptz not null default now()
);
create unique index if not exists guerres_a on public.guerres (semaine, guilde_a);
create unique index if not exists guerres_b on public.guerres (semaine, guilde_b) where guilde_b is not null;

-- Postes des deux forteresses (camp 0 = guilde A, camp 1 = guilde B ou Légion)
create table if not exists public.guerre_postes (
	guerre     uuid not null references public.guerres (id) on delete cascade,
	camp       int  not null check (camp in (0, 1)),
	numero     int  not null,
	couche     int  not null check (couche between 0 and 2),    -- 0 Remparts, 1 Tours, 2 Donjon
	joueur     uuid references public.profils (id) on delete set null,
	nom        text not null,
	equipe     jsonb not null,
	puissance  int not null default 0,
	elements   jsonb not null default '[]'::jsonb,
	etoiles    int not null default 0,     -- meilleur résultat obtenu CONTRE ce poste
	primary key (guerre, camp, numero)
);

create table if not exists public.guerre_attaques (
	id          uuid primary key default gen_random_uuid(),
	guerre      uuid not null references public.guerres (id) on delete cascade,
	camp        int  not null,              -- camp de l'attaquant
	attaquant   uuid references public.profils (id) on delete set null,
	numero      int  not null,              -- poste visé (dans le camp adverse)
	graine      bigint not null,
	equipe      jsonb not null,             -- équipe d'attaque (pour revoir le combat)
	cree_le     timestamptz not null default now(),
	fini_le     timestamptz,
	etoiles     int,
	gain        int                         -- étoiles nouvelles apportées à la guilde
);
create index if not exists guerre_attaques_guerre on public.guerre_attaques (guerre, cree_le desc);

create table if not exists public.guerre_joueurs (
	guerre      uuid not null references public.guerres (id) on delete cascade,
	joueur      uuid not null references public.profils (id) on delete cascade,
	camp        int  not null,
	jour        date,
	attaques    int not null default 0,     -- attaques du jour
	fatigue     jsonb not null default '[]'::jsonb,   -- uids des unités épuisées aujourd'hui
	eclaireur   date,
	eclaireurs  int not null default 0,
	vus         jsonb not null default '[]'::jsonb,   -- postes révélés (numéros)
	attaques_total int not null default 0,
	etoiles_total  int not null default 0,
	reclame     boolean not null default false,
	primary key (guerre, joueur)
);

create table if not exists public.guerre_journal (
	id       bigserial primary key,
	guerre   uuid not null references public.guerres (id) on delete cascade,
	camp     int,
	texte    text not null,
	attaque  uuid,
	cree_le  timestamptz not null default now()
);
create index if not exists guerre_journal_guerre on public.guerre_journal (guerre, id desc);

alter table public.guerre_defenses enable row level security;
alter table public.guerres enable row level security;
alter table public.guerre_postes enable row level security;
alter table public.guerre_attaques enable row level security;
alter table public.guerre_joueurs enable row level security;
alter table public.guerre_journal enable row level security;
revoke all on public.guerre_defenses, public.guerres, public.guerre_postes, public.guerre_attaques,
	public.guerre_joueurs, public.guerre_journal from anon, authenticated;


-- ---------------------------------------------------------------------
-- Outils
-- ---------------------------------------------------------------------
-- Jour de la semaine à Paris : 1 = lundi … 7 = dimanche
create or replace function public._guerre_jour_semaine() returns int language sql stable as $$
	select extract(isodow from now() at time zone 'Europe/Paris')::int
$$;

create or replace function public._guerre_phase() returns text language sql stable as $$
	select case when public._guerre_jour_semaine() <= 2 then 'preparation'
		when public._guerre_jour_semaine() <= 6 then 'assaut' else 'bilan' end
$$;

-- Fin de la phase en cours (pour le compte à rebours du jeu), en UTC
create or replace function public._guerre_fin_phase() returns timestamptz language sql stable as $$
	select ((public._guilde_semaine() + case public._guerre_phase() when 'preparation' then 2 when 'assaut' then 6 else 7 end)::timestamp)
		at time zone 'Europe/Paris'
$$;

-- Jours d'assaut écoulés (0 à 4, fractionnaire) pour la progression de la Légion
create or replace function public._guerre_jours_assaut(p_semaine date) returns float language sql stable as $$
	select least(4.0, greatest(0.0, extract(epoch from (now() - ((p_semaine + 2)::timestamp at time zone 'Europe/Paris'))) / 86400.0))
$$;

create or replace function public._guerre_valider_equipe(p_equipe jsonb) returns boolean
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

create or replace function public._guerre_ecrire(p_guerre uuid, p_camp int, p_texte text, p_attaque uuid default null) returns void
language sql security definer set search_path = public as $$
	insert into public.guerre_journal (guerre, camp, texte, attaque) values (p_guerre, p_camp, left(p_texte, 200), p_attaque);
$$;

-- Fige la forteresse d'une guilde : un poste par membre ayant une défense de guerre (ou d'Arène).
create or replace function public._guerre_figer(p_guerre uuid, p_camp int, p_guilde uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
	n int;
	i int := 0;
	rec record;
begin
	select count(*) into n from public.guilde_membres m
		where m.guilde = p_guilde and (exists (select 1 from public.guerre_defenses d where d.joueur = m.joueur)
			or exists (select 1 from public.arene_joueurs a where a.joueur = m.joueur and jsonb_array_length(a.equipe) > 0));
	for rec in
		select m.joueur, p.pseudo,
			coalesce(d.equipe, a.equipe) as equipe, coalesce(d.puissance, a.puissance, 0) as puissance,
			coalesce(d.elements, '[]'::jsonb) as elements
		from public.guilde_membres m
		join public.profils p on p.id = m.joueur
		left join public.guerre_defenses d on d.joueur = m.joueur
		left join public.arene_joueurs a on a.joueur = m.joueur
		where m.guilde = p_guilde and (d.joueur is not null or (a.joueur is not null and jsonb_array_length(a.equipe) > 0))
		order by coalesce(d.puissance, a.puissance, 0) asc, m.joueur
	loop
		insert into public.guerre_postes (guerre, camp, numero, couche, joueur, nom, equipe, puissance, elements)
		values (p_guerre, p_camp, i, case when n <= 1 then 2 else least(2, (i * 3) / n) end,
			rec.joueur, rec.pseudo, rec.equipe, rec.puissance, rec.elements);
		i := i + 1;
	end loop;
	return i;
end $$;

-- Forteresse de la Légion de la Soif : autant de postes que la guilde (au moins 3), chacun reflet
-- d'une défense de guerre d'un joueur d'une AUTRE guilde de puissance proche, sinon d'un membre.
create or replace function public._guerre_legion(p_guerre uuid, p_guilde uuid) returns int
language plpgsql security definer set search_path = public as $$
declare
	noms text[] := public._guerre_noms_legion();
	n int;
	i int;
	cible record;
	src record;
	v_couche int;
begin
	select count(*) into n from public.guerre_postes where guerre = p_guerre and camp = 0;
	if n = 0 then return 0; end if;
	for i in 0 .. greatest(n, 3) - 1 loop
		select * into cible from public.guerre_postes where guerre = p_guerre and camp = 0 and numero = i % n;
		select d.equipe, d.puissance, d.elements into src
			from public.guerre_defenses d
			where d.joueur not in (select joueur from public.guilde_membres where guilde = p_guilde)
				and d.puissance between cible.puissance * 0.75 and cible.puissance * 1.25
			order by random() limit 1;
		if not found then
			-- reflet d'un membre de la guilde (décalé : jamais son propre poste quand c'est possible)
			select equipe, puissance, elements into src from public.guerre_postes
				where guerre = p_guerre and camp = 0 and numero = (i + 1) % n;
		end if;
		v_couche := least(2, (i * 3) / greatest(n, 3));
		insert into public.guerre_postes (guerre, camp, numero, couche, joueur, nom, equipe, puissance, elements)
		values (p_guerre, 1, i, v_couche, null,
			noms[1 + v_couche * 5 + (i % 5)],
			src.equipe, src.puissance, src.elements);
	end loop;
	return greatest(n, 3);
end $$;

-- Puissance totale des défenses d'une guilde (pour l'appariement)
create or replace function public._guerre_puissance_guilde(p_guilde uuid) returns bigint language sql stable as $$
	select coalesce(sum(coalesce(d.puissance, a.puissance, 0)), 0)
	from public.guilde_membres m
	left join public.guerre_defenses d on d.joueur = m.joueur
	left join public.arene_joueurs a on a.joueur = m.joueur
	where m.guilde = p_guilde
$$;

-- Guerre de la semaine pour une guilde : la crée (appariement) si on est en phase d'assaut.
create or replace function public._guerre_de(p_guilde uuid, p_creer boolean) returns public.guerres
language plpgsql security definer set search_path = public as $$
declare
	g public.guerres;
	sem date := public._guilde_semaine();
	moi public.guildes;
	adv uuid;
	p_moi bigint;
	r jsonb := public.guerre_reglages();
	nb int;
begin
	select * into g from public.guerres where semaine = sem and (guilde_a = p_guilde or guilde_b = p_guilde);
	if found or not p_creer or public._guerre_phase() <> 'assaut' then return g; end if;
	select * into moi from public.guildes where id = p_guilde;
	if not moi.guerre_inscrite then return g; end if;
	perform pg_advisory_xact_lock(hashtext('guerre_appariement'));
	select * into g from public.guerres where semaine = sem and (guilde_a = p_guilde or guilde_b = p_guilde);
	if found then return g; end if;
	-- Adversaire : guilde inscrite, sans guerre cette semaine, de puissance proche
	p_moi := greatest(public._guerre_puissance_guilde(p_guilde), 1);
	select x.id into adv from public.guildes x
		where x.guerre_inscrite and x.id <> p_guilde
			and not exists (select 1 from public.guerres w where w.semaine = sem and (w.guilde_a = x.id or w.guilde_b = x.id))
			and greatest(public._guerre_puissance_guilde(x.id), 1) between p_moi / (r ->> 'rapport_puissance_max')::float
				and p_moi * (r ->> 'rapport_puissance_max')::float
		order by abs(public._guerre_puissance_guilde(x.id) - p_moi) limit 1;
	insert into public.guerres (semaine, guilde_a, guilde_b, nom_b)
	values (sem, p_guilde, adv, coalesce((select nom from public.guildes where id = adv), 'La Légion de la Soif'))
	returning * into g;
	nb := public._guerre_figer(g.id, 0, p_guilde);
	if nb = 0 then
		delete from public.guerres where id = g.id;
		g := null;
		return g;
	end if;
	if adv is not null then
		if public._guerre_figer(g.id, 1, adv) = 0 then
			-- l'adversaire n'a aucune défense : il affronte la Légion à la place
			update public.guerres set guilde_b = null, nom_b = 'La Légion de la Soif' where id = g.id returning * into g;
			adv := null;
		end if;
	end if;
	if adv is null then
		perform public._guerre_legion(g.id, p_guilde);
	end if;
	perform public._guerre_ecrire(g.id, null, format('La guerre est déclarée : %s contre %s !', moi.nom, g.nom_b));
	return g;
end $$;

-- La Légion avance au fil des jours d'assaut : elle prend des étoiles à la forteresse de la guilde.
create or replace function public._guerre_avancer_legion(p_guerre uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
	g public.guerres;
	r jsonb := public.guerre_reglages();
	possible int;
	cible int;
	deja int;
	p record;
	reste int;
	prend int;
	noms text[] := public._guerre_noms_legion();
begin
	select * into g from public.guerres where id = p_guerre for update;
	if g.guilde_b is not null or g.finie then return; end if;
	select count(*) * 3 into possible from public.guerre_postes where guerre = g.id and camp = 0;
	cible := floor(possible * (r ->> 'legion_part')::float * public._guerre_jours_assaut(g.semaine) / 4.0)::int;
	select coalesce(sum(etoiles), 0) into deja from public.guerre_postes where guerre = g.id and camp = 0;
	reste := cible - deja;
	if reste <= 0 then return; end if;
	for p in select * from public.guerre_postes where guerre = g.id and camp = 0 and etoiles < 3
		order by couche, numero
	loop
		exit when reste <= 0;
		prend := least(reste, 3 - p.etoiles, 1 + (abs(hashtext(g.id::text || p.numero)) % 3));
		update public.guerre_postes set etoiles = etoiles + prend where guerre = g.id and camp = 0 and numero = p.numero;
		reste := reste - prend;
		perform public._guerre_ecrire(g.id, 1, format('%s frappe le poste de %s : %s',
			noms[1 + abs(hashtext(g.id::text || p.numero || 'l')) % array_length(noms, 1)], p.nom,
			repeat('★', p.etoiles + prend)));
	end loop;
	update public.guerres set etoiles_b = (select coalesce(sum(etoiles), 0) from public.guerre_postes where guerre = g.id and camp = 0)
		where id = g.id;
end $$;

-- Bilan : désigne le vainqueur et récompense la guilde (une fois).
create or replace function public._guerre_finir(p_guerre uuid) returns void
language plpgsql security definer set search_path = public as $$
declare
	g public.guerres;
	r jsonb := public.guerre_reglages();
	res_a text;
	res_b text;
begin
	perform public._guerre_avancer_legion(p_guerre);
	select * into g from public.guerres where id = p_guerre for update;
	if g.finie then return; end if;
	g.gagnant := case when g.etoiles_a > g.etoiles_b then 0 when g.etoiles_b > g.etoiles_a then 1 else -1 end;
	update public.guerres set finie = true, gagnant = g.gagnant where id = g.id;
	res_a := case g.gagnant when 0 then 'victoire' when 1 then 'defaite' else 'egalite' end;
	res_b := case g.gagnant when 1 then 'victoire' when 0 then 'defaite' else 'egalite' end;
	update public.guildes set
		guerre_victoires = guerre_victoires + (res_a = 'victoire')::int,
		guerre_egalites = guerre_egalites + (res_a = 'egalite')::int,
		guerre_defaites = guerre_defaites + (res_a = 'defaite')::int where id = g.guilde_a;
	perform public._guilde_gagner_xp(g.guilde_a, (r -> 'guilde_xp' ->> res_a)::int, (r -> 'guilde_tresor' ->> res_a)::int);
	perform public._guilde_ecrire_journal(g.guilde_a, format('Guerre contre %s : %s (%s ★ à %s ★).', g.nom_b,
		case res_a when 'victoire' then 'VICTOIRE' when 'defaite' then 'défaite' else 'égalité' end, g.etoiles_a, g.etoiles_b));
	if g.guilde_b is not null then
		update public.guildes set
			guerre_victoires = guerre_victoires + (res_b = 'victoire')::int,
			guerre_egalites = guerre_egalites + (res_b = 'egalite')::int,
			guerre_defaites = guerre_defaites + (res_b = 'defaite')::int where id = g.guilde_b;
		perform public._guilde_gagner_xp(g.guilde_b, (r -> 'guilde_xp' ->> res_b)::int, (r -> 'guilde_tresor' ->> res_b)::int);
		perform public._guilde_ecrire_journal(g.guilde_b, format('Guerre contre %s : %s (%s ★ à %s ★).',
			(select nom from public.guildes where id = g.guilde_a),
			case res_b when 'victoire' then 'VICTOIRE' when 'defaite' then 'défaite' else 'égalité' end, g.etoiles_b, g.etoiles_a));
	end if;
	perform public._guerre_ecrire(g.id, null, case g.gagnant when -1 then 'Fin de la guerre : égalité !'
		else format('Fin de la guerre : victoire de %s !', case g.gagnant when 0 then (select nom from public.guildes where id = g.guilde_a) else g.nom_b end) end);
end $$;


-- ---------------------------------------------------------------------
-- Défense de guerre du joueur
-- ---------------------------------------------------------------------
create or replace function public.guerre_definir_defense(p_equipe jsonb, p_puissance int, p_elements jsonb) returns text
language plpgsql security definer set search_path = public as $$
begin
	if auth.uid() is null then return 'non_connecte'; end if;
	if not public._guerre_valider_equipe(p_equipe) then return 'invalide'; end if;
	insert into public.guerre_defenses (joueur, equipe, puissance, elements)
	values (auth.uid(), p_equipe, greatest(0, least(coalesce(p_puissance, 0), 10000000)),
		case when jsonb_typeof(p_elements) = 'array' and jsonb_array_length(p_elements) <= 5 then p_elements else '[]'::jsonb end)
	on conflict (joueur) do update set equipe = excluded.equipe, puissance = excluded.puissance,
		elements = excluded.elements, maj = now();
	return 'ok';
end $$;

-- Inscription de la guilde aux guerres (chef ou officier). Reste valable chaque semaine.
create or replace function public.guerre_inscrire(p_oui boolean) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return 'pas_de_guilde'; end if;
	if moi.role not in ('chef', 'officier') then return 'droits'; end if;
	update public.guildes set guerre_inscrite = coalesce(p_oui, false) where id = moi.guilde;
	perform public._guilde_ecrire_journal(moi.guilde, case when p_oui then 'La guilde s''inscrit à la Guerre des Bannières.'
		else 'La guilde se retire de la Guerre des Bannières.' end);
	return 'ok';
end $$;


-- ---------------------------------------------------------------------
-- État complet (ce que l'écran de guerre affiche)
-- ---------------------------------------------------------------------
create or replace function public._guerre_postes_json(p_guerre uuid, p_camp int, p_mon_camp int, p_vus jsonb) returns jsonb
language sql stable security definer set search_path = public as $$
	select coalesce(jsonb_agg(jsonb_build_object(
		'numero', p.numero, 'couche', p.couche, 'nom', p.nom, 'puissance', p.puissance,
		'elements', p.elements, 'etoiles', p.etoiles, 'moi', coalesce(p.joueur = auth.uid(), false),
		-- l'équipe n'est visible que pour son propre camp, ou une fois révélée par l'éclaireur
		'equipe', case when p_camp = p_mon_camp or p_vus @> to_jsonb(p.numero) then p.equipe else null end
	) order by p.couche desc, p.numero), '[]'::jsonb)
	from public.guerre_postes p where p.guerre = p_guerre and p.camp = p_camp
$$;

create or replace function public.guerre_etat() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	gu public.guildes;
	g public.guerres;
	gj public.guerre_joueurs;
	r jsonb := public.guerre_reglages();
	v_camp int;
	v_adv int;
	d public.guerre_defenses;
	derniere public.guerres;
	res jsonb;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	select * into gu from public.guildes where id = moi.guilde;
	select * into d from public.guerre_defenses where joueur = auth.uid();
	-- Guerres passées non terminées : bilan
	for derniere in select * from public.guerres
		where (guilde_a = gu.id or guilde_b = gu.id) and not finie
			and (semaine < public._guilde_semaine() or public._guerre_phase() = 'bilan')
	loop
		perform public._guerre_finir(derniere.id);
	end loop;
	g := public._guerre_de(gu.id, true);
	if g.id is null then
		-- pas de guerre cette semaine : on montre la dernière (pour réclamer son butin)
		select * into g from public.guerres where guilde_a = gu.id or guilde_b = gu.id order by semaine desc limit 1;
	else
		perform public._guerre_avancer_legion(g.id);
		select * into g from public.guerres where id = g.id;
	end if;
	res := jsonb_build_object(
		'code', 'ok', 'phase', public._guerre_phase(), 'fin_phase', public._guerre_fin_phase(),
		'semaine', public._guilde_semaine(), 'reglages', r,
		'guilde', jsonb_build_object('nom', gu.nom, 'inscrite', gu.guerre_inscrite, 'mon_role', moi.role,
			'victoires', gu.guerre_victoires, 'egalites', gu.guerre_egalites, 'defaites', gu.guerre_defaites),
		'butin_en_attente', exists (select 1 from public.guerres w join public.guerre_joueurs x on x.guerre = w.id
			and x.joueur = auth.uid() where w.finie and x.attaques_total > 0 and not x.reclame),
		'ma_defense', case when d.joueur is null then null else jsonb_build_object('equipe', d.equipe, 'puissance', d.puissance, 'maj', d.maj) end,
		'guerre', null);
	if g.id is null then return res; end if;
	v_camp := case when g.guilde_a = gu.id then 0 else 1 end;
	v_adv := 1 - v_camp;
	select * into gj from public.guerre_joueurs where guerre = g.id and joueur = auth.uid();
	return res || jsonb_build_object('guerre', jsonb_build_object(
		'id', g.id, 'semaine', g.semaine, 'en_cours', g.semaine = public._guilde_semaine() and not g.finie,
		'finie', g.finie, 'legion', g.guilde_b is null,
		'nous', jsonb_build_object('nom', gu.nom, 'etoiles', case v_camp when 0 then g.etoiles_a else g.etoiles_b end),
		'eux', jsonb_build_object('nom', case v_camp when 0 then g.nom_b else (select nom from public.guildes where id = g.guilde_a) end,
			'etoiles', case v_camp when 0 then g.etoiles_b else g.etoiles_a end),
		'gagnant', case when g.gagnant is null then null when g.gagnant = -1 then 'egalite'
			when g.gagnant = v_camp then 'nous' else 'eux' end,
		'postes_eux', public._guerre_postes_json(g.id, v_adv, v_camp, coalesce(gj.vus, '[]'::jsonb)),
		'postes_nous', public._guerre_postes_json(g.id, v_camp, v_camp, '[]'::jsonb),
		'moi', jsonb_build_object(
			'attaques_restantes', (r ->> 'attaques_jour')::int
				- case when gj.jour = public._guilde_jour() then coalesce(gj.attaques, 0) else 0 end,
			'eclaireurs_restants', (r ->> 'eclaireurs_jour')::int
				- case when gj.eclaireur = public._guilde_jour() then coalesce(gj.eclaireurs, 0) else 0 end,
			'fatigue', case when gj.jour = public._guilde_jour() then coalesce(gj.fatigue, '[]'::jsonb) else '[]'::jsonb end,
			'attaques_total', coalesce(gj.attaques_total, 0), 'etoiles_total', coalesce(gj.etoiles_total, 0),
			'peut_reclamer', g.finie and coalesce(gj.attaques_total, 0) > 0 and not coalesce(gj.reclame, false)),
		'membres', coalesce((select jsonb_agg(jsonb_build_object('pseudo', p.pseudo, 'attaques', x.attaques_total, 'etoiles', x.etoiles_total)
				order by x.etoiles_total desc, x.attaques_total desc)
			from public.guerre_joueurs x join public.profils p on p.id = x.joueur
			where x.guerre = g.id and x.camp = v_camp), '[]'::jsonb),
		'journal', coalesce((select jsonb_agg(jsonb_build_object('texte', j.texte, 'camp', j.camp, 'nous', coalesce(j.camp = v_camp, false),
				'attaque', j.attaque, 'cree_le', j.cree_le) order by j.id desc)
			from (select * from public.guerre_journal where guerre = g.id order by id desc limit 80) j), '[]'::jsonb)
	));
end $$;


-- ---------------------------------------------------------------------
-- Éclaireur : révèle l'équipe d'un poste ennemi (1 fois par jour)
-- ---------------------------------------------------------------------
create or replace function public.guerre_eclaireur(p_numero int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	g public.guerres;
	gj public.guerre_joueurs;
	r jsonb := public.guerre_reglages();
	v_camp int;
	p public.guerre_postes;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	g := public._guerre_de(moi.guilde, false);
	if g.id is null or g.finie or public._guerre_phase() <> 'assaut' then return jsonb_build_object('code', 'pas_en_guerre'); end if;
	v_camp := case when g.guilde_a = moi.guilde then 0 else 1 end;
	select * into p from public.guerre_postes where guerre = g.id and camp = 1 - v_camp and numero = p_numero;
	if not found then return jsonb_build_object('code', 'introuvable'); end if;
	insert into public.guerre_joueurs (guerre, joueur, camp) values (g.id, auth.uid(), v_camp) on conflict do nothing;
	select * into gj from public.guerre_joueurs where guerre = g.id and joueur = auth.uid() for update;
	if gj.vus @> to_jsonb(p_numero) then return jsonb_build_object('code', 'ok', 'equipe', p.equipe); end if;
	if gj.eclaireur = public._guilde_jour() and gj.eclaireurs >= (r ->> 'eclaireurs_jour')::int then
		return jsonb_build_object('code', 'eclaireur');
	end if;
	update public.guerre_joueurs set
		eclaireurs = case when eclaireur = public._guilde_jour() then eclaireurs + 1 else 1 end,
		eclaireur = public._guilde_jour(), vus = vus || to_jsonb(p_numero)
		where guerre = g.id and joueur = auth.uid();
	return jsonb_build_object('code', 'ok', 'equipe', p.equipe);
end $$;


-- ---------------------------------------------------------------------
-- Attaque : commencer (vérifie tout, épuise les unités) puis terminer (étoiles)
-- ---------------------------------------------------------------------
create or replace function public.guerre_commencer(p_numero int, p_equipe jsonb, p_uids jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	g public.guerres;
	gj public.guerre_joueurs;
	r jsonb := public.guerre_reglages();
	v_camp int;
	p public.guerre_postes;
	v_fatigue jsonb;
	u jsonb;
	a public.guerre_attaques;
	bloque boolean;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	g := public._guerre_de(moi.guilde, true);
	if g.id is null or g.finie or public._guerre_phase() <> 'assaut' then return jsonb_build_object('code', 'pas_en_guerre'); end if;
	if not public._guerre_valider_equipe(p_equipe) or jsonb_typeof(p_uids) <> 'array'
		or jsonb_array_length(p_uids) <> jsonb_array_length(p_equipe) then
		return jsonb_build_object('code', 'invalide');
	end if;
	v_camp := case when g.guilde_a = moi.guilde then 0 else 1 end;
	select * into p from public.guerre_postes where guerre = g.id and camp = 1 - v_camp and numero = p_numero;
	if not found then return jsonb_build_object('code', 'introuvable'); end if;
	-- La couche précédente doit être percée (chaque poste pris au moins une étoile)
	select exists (select 1 from public.guerre_postes x where x.guerre = g.id and x.camp = 1 - v_camp
		and x.couche < p.couche and x.etoiles = 0) into bloque;
	if bloque then return jsonb_build_object('code', 'couche'); end if;
	insert into public.guerre_joueurs (guerre, joueur, camp) values (g.id, auth.uid(), v_camp) on conflict do nothing;
	select * into gj from public.guerre_joueurs where guerre = g.id and joueur = auth.uid() for update;
	if gj.jour is distinct from public._guilde_jour() then
		gj.attaques := 0;
		gj.fatigue := '[]'::jsonb;
	end if;
	if gj.attaques >= (r ->> 'attaques_jour')::int then return jsonb_build_object('code', 'attaques'); end if;
	v_fatigue := gj.fatigue;
	for u in select * from jsonb_array_elements(p_uids) loop
		if v_fatigue @> jsonb_build_array(u) then return jsonb_build_object('code', 'fatigue'); end if;
		v_fatigue := v_fatigue || jsonb_build_array(u);
	end loop;
	update public.guerre_joueurs set jour = public._guilde_jour(), attaques = gj.attaques + 1, fatigue = v_fatigue,
		attaques_total = attaques_total + 1
		where guerre = g.id and joueur = auth.uid();
	insert into public.guerre_attaques (guerre, camp, attaquant, numero, graine, equipe)
	values (g.id, v_camp, auth.uid(), p_numero, (floor(random() * 2000000000) + 1)::bigint, p_equipe)
	returning * into a;
	return jsonb_build_object('code', 'ok', 'attaque', a.id, 'graine', a.graine, 'defense', p.equipe,
		'nom', p.nom, 'etoiles_avant', p.etoiles);
end $$;

create or replace function public.guerre_terminer(p_attaque uuid, p_etoiles int) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	a public.guerre_attaques;
	g public.guerres;
	p public.guerre_postes;
	e int := least(3, greatest(0, coalesce(p_etoiles, 0)));
	v_gain int;
	pseudo text;
	total int;
begin
	select * into a from public.guerre_attaques where id = p_attaque and attaquant = auth.uid() for update;
	if not found then return jsonb_build_object('code', 'introuvable'); end if;
	if a.fini_le is not null then return jsonb_build_object('code', 'deja'); end if;
	select * into g from public.guerres where id = a.guerre for update;
	if g.finie then
		update public.guerre_attaques set fini_le = now(), etoiles = e, gain = 0 where id = a.id;
		return jsonb_build_object('code', 'finie');
	end if;
	select * into p from public.guerre_postes where guerre = g.id and camp = 1 - a.camp and numero = a.numero for update;
	v_gain := greatest(0, e - p.etoiles);
	update public.guerre_attaques set fini_le = now(), etoiles = e, gain = v_gain where id = a.id;
	if v_gain > 0 then
		update public.guerre_postes set etoiles = e where guerre = g.id and camp = 1 - a.camp and numero = a.numero;
		update public.guerre_joueurs set etoiles_total = etoiles_total + v_gain where guerre = g.id and joueur = auth.uid();
	end if;
	select coalesce(sum(etoiles), 0) into total from public.guerre_postes where guerre = g.id and camp = 1 - a.camp;
	if a.camp = 0 then
		update public.guerres set etoiles_a = total where id = g.id;
	else
		update public.guerres set etoiles_b = total where id = g.id;
	end if;
	select x.pseudo into pseudo from public.profils x where x.id = auth.uid();
	perform public._guerre_ecrire(g.id, a.camp, case when e = 0
		then format('%s est repoussé par %s.', pseudo, p.nom)
		else format('%s attaque %s : %s%s', pseudo, p.nom, repeat('★', e), case when v_gain > 0 then format(' (+%s)', v_gain) else '' end) end,
		a.id);
	return jsonb_build_object('code', 'ok', 'etoiles', e, 'gain', v_gain, 'total', total);
end $$;

-- Revoir un combat (journal) : les deux équipes et la graine suffisent à le rejouer à l'identique.
create or replace function public.guerre_revoir(p_attaque uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	a public.guerre_attaques;
	g public.guerres;
	p public.guerre_postes;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	select * into a from public.guerre_attaques where id = p_attaque and fini_le is not null;
	if not found then return jsonb_build_object('code', 'introuvable'); end if;
	select * into g from public.guerres where id = a.guerre and (guilde_a = moi.guilde or guilde_b = moi.guilde);
	if not found then return jsonb_build_object('code', 'introuvable'); end if;
	select * into p from public.guerre_postes where guerre = g.id and camp = 1 - a.camp and numero = a.numero;
	return jsonb_build_object('code', 'ok', 'graine', a.graine, 'equipe', a.equipe, 'defense', p.equipe,
		'nom', p.nom, 'attaquant', (select pseudo from public.profils where id = a.attaquant), 'etoiles', a.etoiles);
end $$;


-- ---------------------------------------------------------------------
-- Butin (après le bilan, pour qui a attaqué au moins une fois)
-- ---------------------------------------------------------------------
create or replace function public.guerre_reclamer() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	g public.guerres;
	gj public.guerre_joueurs;
	r jsonb := public.guerre_reglages();
	res text;
	v_sceaux int;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	select w.* into g from public.guerres w join public.guerre_joueurs x on x.guerre = w.id and x.joueur = auth.uid()
		where w.finie and x.attaques_total > 0 and not x.reclame order by w.semaine desc limit 1;
	if not found then return jsonb_build_object('code', 'rien'); end if;
	select * into gj from public.guerre_joueurs where guerre = g.id and joueur = auth.uid() for update;
	res := case when g.gagnant = -1 then 'egalite' when g.gagnant = gj.camp then 'victoire' else 'defaite' end;
	v_sceaux := least((r ->> 'sceaux_max')::int,
		(r -> 'sceaux' ->> res)::int + (r ->> 'sceaux_par_etoile')::int * gj.etoiles_total);
	update public.guerre_joueurs set reclame = true where guerre = g.id and joueur = auth.uid();
	update public.guilde_membres set sceaux = sceaux + v_sceaux where joueur = auth.uid();
	return jsonb_build_object('code', 'ok', 'resultat', res, 'sceaux', v_sceaux, 'recompense', r -> 'butin' -> res);
end $$;


-- Droits : les joueurs connectés appellent les fonctions publiques, jamais les tables.
revoke all on function public._guerre_figer(uuid, int, uuid), public._guerre_legion(uuid, uuid),
	public._guerre_de(uuid, boolean), public._guerre_avancer_legion(uuid), public._guerre_finir(uuid),
	public._guerre_ecrire(uuid, int, text, uuid), public._guerre_postes_json(uuid, int, int, jsonb)
	from public, anon, authenticated;
grant execute on function public.guerre_etat(), public.guerre_definir_defense(jsonb, int, jsonb),
	public.guerre_inscrire(boolean), public.guerre_eclaireur(int), public.guerre_commencer(int, jsonb, jsonb),
	public.guerre_terminer(uuid, int), public.guerre_revoir(uuid), public.guerre_reclamer() to authenticated;
