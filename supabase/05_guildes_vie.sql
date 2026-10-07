-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — la vie de guilde
--  Étape 5 : niveau et trésor de guilde, dons quotidiens, Sceaux de guilde,
--            annonce du chef, journal, bénédictions, boutique, Boss de guilde
--            et discussion (chat) de guilde.
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire une fois, APRÈS le fichier 01. Peut être relancé sans danger.
--
--  RÉGLAGES : les nombres modifiables sont dans guilde_reglages() juste en dessous.
-- =====================================================================

create or replace function public.guilde_reglages() returns jsonb language sql immutable as $$
	select jsonb_build_object(
		-- Dons : un seul par jour et par membre. xp = XP de guilde, tresor = trésor de guilde, sceaux = pour le joueur
		'dons', jsonb_build_object(
			'salut',  jsonb_build_object('cout_or', 0,     'cout_gemmes', 0,  'xp', 5,  'tresor', 5,  'sceaux', 5),
			'or',     jsonb_build_object('cout_or', 20000, 'cout_gemmes', 0,  'xp', 20, 'tresor', 20, 'sceaux', 20),
			'gemmes', jsonb_build_object('cout_or', 0,     'cout_gemmes', 50, 'xp', 50, 'tresor', 50, 'sceaux', 50)),
		-- Bénédictions : 5 rangs chacune ; rang n coûte cout * n en trésor et demande le niveau de guilde 2n-1
		'benedictions', jsonb_build_object(
			'force', 3, 'vitalite', 3, 'rempart', 3, 'fortune', 5, 'savoir', 5),
		'benediction_rang_max', 5,
		'benediction_cout', 300,
		-- Boss de guilde (un par semaine) : PV = pv_par_membre x nombre de membres (au moins pv_min_membres)
		'boss_pv_par_membre', 600000,
		'boss_pv_min_membres', 3,
		'boss_essais_jour', 2,
		'boss_degats_max_coup', 260000,
		'boss_paliers', jsonb_build_array(25, 50, 75, 100),
		'boss_sceaux', jsonb_build_array(20, 30, 40, 60),
		'boss_butin', jsonb_build_array(
			jsonb_build_object('or', 5000, 'coffre_argent', 1),
			jsonb_build_object('or', 10000, 'tome_grand', 1),
			jsonb_build_object('or', 15000, 'coffre_or', 1),
			jsonb_build_object('or', 25000, 'eclat_superieur', 1)),
		-- Discussion
		'chat_longueur', 200,
		'chat_gardes', 300,
		'chat_delai_secondes', 2
	)
$$;

-- Boutique de guilde (payée en Sceaux de guilde ; limite = achats par semaine)
create or replace function public.guilde_boutique() returns jsonb language sql immutable as $$
	select jsonb_build_array(
		jsonb_build_object('id', 'elixir_grand',    'quantite', 1,  'prix', 40,  'limite', 3),
		jsonb_build_object('id', 'tome_grand',      'quantite', 1,  'prix', 60,  'limite', 3),
		jsonb_build_object('id', 'poussiere_echo',  'quantite', 50, 'prix', 50,  'limite', 3),
		jsonb_build_object('id', 'sceau_sauvage',   'quantite', 3,  'prix', 70,  'limite', 2),
		jsonb_build_object('id', 'coffre_or',       'quantite', 1,  'prix', 90,  'limite', 2),
		jsonb_build_object('id', 'pierre_eveil',    'quantite', 1,  'prix', 150, 'limite', 1),
		jsonb_build_object('id', 'eclat_superieur', 'quantite', 1,  'prix', 220, 'limite', 1))
$$;


-- ---------------------------------------------------------------------
-- Colonnes et tables
-- ---------------------------------------------------------------------
alter table public.guildes add column if not exists xp int not null default 0;
alter table public.guildes add column if not exists tresor int not null default 0;
alter table public.guildes add column if not exists annonce text not null default '';
alter table public.guildes add column if not exists benedictions jsonb not null default '{}'::jsonb;

alter table public.guilde_membres add column if not exists sceaux int not null default 0;
alter table public.guilde_membres add column if not exists don_jour date;
alter table public.guilde_membres add column if not exists dons_total int not null default 0;
alter table public.guilde_membres add column if not exists boutique jsonb not null default '{}'::jsonb;

create table if not exists public.guilde_journal (
	id       bigserial primary key,
	guilde   uuid not null references public.guildes (id) on delete cascade,
	texte    text not null,
	cree_le  timestamptz not null default now()
);
create index if not exists guilde_journal_guilde on public.guilde_journal (guilde, id desc);

create table if not exists public.guilde_chat (
	id       bigserial primary key,
	guilde   uuid not null references public.guildes (id) on delete cascade,
	joueur   uuid references public.profils (id) on delete set null,
	pseudo   text not null,
	texte    text not null check (char_length(texte) between 1 and 200),
	cree_le  timestamptz not null default now()
);
create index if not exists guilde_chat_guilde on public.guilde_chat (guilde, id desc);

create table if not exists public.guilde_boss (
	guilde     uuid not null references public.guildes (id) on delete cascade,
	semaine    date not null,
	pv_max     bigint not null,
	degats     bigint not null default 0,
	abattu_le  timestamptz,
	primary key (guilde, semaine)
);

create table if not exists public.guilde_boss_joueurs (
	guilde     uuid not null references public.guildes (id) on delete cascade,
	semaine    date not null,
	joueur     uuid not null references public.profils (id) on delete cascade,
	degats     bigint not null default 0,
	coups      int not null default 0,
	jour       date,
	essais     int not null default 0,
	paliers    int not null default 0,      -- nombre de paliers déjà réclamés
	primary key (guilde, semaine, joueur)
);

alter table public.guilde_journal enable row level security;
alter table public.guilde_chat enable row level security;
alter table public.guilde_boss enable row level security;
alter table public.guilde_boss_joueurs enable row level security;
-- Aucune lecture/écriture directe : tout passe par les fonctions ci-dessous.
revoke all on public.guilde_journal, public.guilde_chat, public.guilde_boss, public.guilde_boss_joueurs from anon, authenticated;


-- ---------------------------------------------------------------------
-- Outils
-- ---------------------------------------------------------------------
create or replace function public._guilde_jour() returns date language sql stable as $$
	select (now() at time zone 'Europe/Paris')::date
$$;

create or replace function public._guilde_semaine() returns date language sql stable as $$
	select date_trunc('week', now() at time zone 'Europe/Paris')::date
$$;

-- Niveau de guilde selon l'XP : 250 XP -> niv. 2, 1000 -> 3, 2250 -> 4, 4000 -> 5 ... (max 30)
create or replace function public._guilde_niveau(p_xp int) returns int language sql immutable as $$
	select least(30, 1 + floor(sqrt(greatest(p_xp, 0) / 250.0))::int)
$$;

create or replace function public._guilde_xp_pour(p_niveau int) returns int language sql immutable as $$
	select (250 * (p_niveau - 1) * (p_niveau - 1))::int
$$;

create or replace function public._guilde_ecrire_journal(p_guilde uuid, p_texte text) returns void
language plpgsql security definer set search_path = public as $$
begin
	insert into public.guilde_journal (guilde, texte) values (p_guilde, left(p_texte, 200));
	delete from public.guilde_journal where guilde = p_guilde
		and id < (select min(id) from (select id from public.guilde_journal where guilde = p_guilde order by id desc limit 60) t);
end $$;

-- Ajoute de l'XP à la guilde et note les passages de niveau dans le journal.
create or replace function public._guilde_gagner_xp(p_guilde uuid, p_xp int, p_tresor int) returns void
language plpgsql security definer set search_path = public as $$
declare
	avant int;
	apres int;
begin
	select niveau into avant from public.guildes where id = p_guilde;
	update public.guildes set xp = xp + p_xp, tresor = tresor + p_tresor,
		niveau = public._guilde_niveau(xp + p_xp)
		where id = p_guilde returning niveau into apres;
	if apres > avant then
		perform public._guilde_ecrire_journal(p_guilde, format('La guilde atteint le niveau %s !', apres));
	end if;
end $$;

-- Boss de la semaine (créé au premier passage de la semaine).
create or replace function public._guilde_boss(p_guilde uuid) returns public.guilde_boss
language plpgsql security definer set search_path = public as $$
declare
	b public.guilde_boss;
	r jsonb := public.guilde_reglages();
	nb int;
begin
	select * into b from public.guilde_boss where guilde = p_guilde and semaine = public._guilde_semaine();
	if found then return b; end if;
	select count(*) into nb from public.guilde_membres where guilde = p_guilde;
	insert into public.guilde_boss (guilde, semaine, pv_max)
	values (p_guilde, public._guilde_semaine(),
		(r ->> 'boss_pv_par_membre')::bigint * greatest(nb, (r ->> 'boss_pv_min_membres')::int))
	on conflict (guilde, semaine) do nothing;
	select * into b from public.guilde_boss where guilde = p_guilde and semaine = public._guilde_semaine();
	return b;
end $$;


-- ---------------------------------------------------------------------
-- Lecture : tout ce que l'écran de guilde affiche (hors membres, déjà dans ma_guilde)
-- ---------------------------------------------------------------------
create or replace function public.guilde_vie() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	g public.guildes;
	b public.guilde_boss;
	bj public.guilde_boss_joueurs;
	r jsonb := public.guilde_reglages();
	sem text := public._guilde_semaine()::text;
	achats jsonb;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return null; end if;
	select * into g from public.guildes where id = moi.guilde;
	b := public._guilde_boss(g.id);
	select * into bj from public.guilde_boss_joueurs where guilde = g.id and semaine = b.semaine and joueur = auth.uid();
	achats := case when moi.boutique ->> 'semaine' = sem then coalesce(moi.boutique -> 'achats', '{}'::jsonb) else '{}'::jsonb end;
	return jsonb_build_object(
		'niveau', public._guilde_niveau(g.xp), 'xp', g.xp,
		'xp_niveau', public._guilde_xp_pour(public._guilde_niveau(g.xp)),
		'xp_suivant', public._guilde_xp_pour(public._guilde_niveau(g.xp) + 1),
		'tresor', g.tresor, 'annonce', g.annonce, 'benedictions', g.benedictions,
		'mes_sceaux', moi.sceaux, 'don_fait', coalesce(moi.don_jour = public._guilde_jour(), false), 'mes_dons', moi.dons_total,
		'reglages', r, 'boutique', public.guilde_boutique(), 'achats', achats,
		'journal', coalesce((select jsonb_agg(jsonb_build_object('texte', j.texte, 'cree_le', j.cree_le) order by j.id desc)
			from (select * from public.guilde_journal where guilde = g.id order by id desc limit 30) j), '[]'::jsonb),
		'boss', jsonb_build_object(
			'semaine', b.semaine, 'pv_max', b.pv_max, 'degats', b.degats, 'abattu', b.abattu_le is not null,
			'mes_degats', coalesce(bj.degats, 0), 'mes_coups', coalesce(bj.coups, 0),
			'essais_restants', (r ->> 'boss_essais_jour')::int
				- case when bj.jour = public._guilde_jour() then coalesce(bj.essais, 0) else 0 end,
			'paliers_reclames', coalesce(bj.paliers, 0),
			'classement', coalesce((select jsonb_agg(jsonb_build_object('pseudo', p.pseudo, 'degats', x.degats, 'coups', x.coups)
					order by x.degats desc)
				from public.guilde_boss_joueurs x join public.profils p on p.id = x.joueur
				where x.guilde = g.id and x.semaine = b.semaine and x.degats > 0), '[]'::jsonb))
	);
end $$;


-- ---------------------------------------------------------------------
-- Don quotidien ('salut', 'or' ou 'gemmes'). Le jeu retire l'or / les gemmes s'il reçoit 'ok'.
-- ---------------------------------------------------------------------
create or replace function public.guilde_donner(p_type text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	d jsonb := public.guilde_reglages() -> 'dons' -> p_type;
	pseudo text;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid() for update;
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	if d is null then return jsonb_build_object('code', 'introuvable'); end if;
	if moi.don_jour = public._guilde_jour() then return jsonb_build_object('code', 'deja_donne'); end if;
	update public.guilde_membres set don_jour = public._guilde_jour(), dons_total = dons_total + 1,
		sceaux = sceaux + (d ->> 'sceaux')::int where joueur = auth.uid();
	perform public._guilde_gagner_xp(moi.guilde, (d ->> 'xp')::int, (d ->> 'tresor')::int);
	select p.pseudo into pseudo from public.profils p where p.id = auth.uid();
	perform public._guilde_ecrire_journal(moi.guilde, format('%s a fait un don (%s) : +%s XP de guilde.', pseudo,
		case p_type when 'or' then 'or' when 'gemmes' then 'gemmes' else 'salut' end, d ->> 'xp'));
	return jsonb_build_object('code', 'ok', 'cout_or', (d ->> 'cout_or')::int, 'cout_gemmes', (d ->> 'cout_gemmes')::int,
		'sceaux', (d ->> 'sceaux')::int, 'xp', (d ->> 'xp')::int);
end $$;


-- ---------------------------------------------------------------------
-- Annonce du chef (chef ou officier)
-- ---------------------------------------------------------------------
create or replace function public.guilde_annonce(p_texte text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return 'pas_de_guilde'; end if;
	if moi.role not in ('chef', 'officier') then return 'interdit'; end if;
	update public.guildes set annonce = left(coalesce(p_texte, ''), 200) where id = moi.guilde;
	return 'ok';
end $$;


-- ---------------------------------------------------------------------
-- Bénédictions (chef ou officier, payées avec le trésor de guilde)
-- ---------------------------------------------------------------------
create or replace function public.guilde_benir(p_benediction text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	g public.guildes;
	r jsonb := public.guilde_reglages();
	rang int;
	cout int;
	noms jsonb := '{"force": "Force", "vitalite": "Vitalité", "rempart": "Rempart", "fortune": "Fortune", "savoir": "Savoir"}'::jsonb;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return 'pas_de_guilde'; end if;
	if moi.role not in ('chef', 'officier') then return 'interdit'; end if;
	if not (r -> 'benedictions') ? p_benediction then return 'introuvable'; end if;
	select * into g from public.guildes where id = moi.guilde for update;
	rang := coalesce((g.benedictions ->> p_benediction)::int, 0) + 1;
	if rang > (r ->> 'benediction_rang_max')::int then return 'rang_max'; end if;
	if public._guilde_niveau(g.xp) < 2 * rang - 1 then return 'niveau_guilde'; end if;
	cout := (r ->> 'benediction_cout')::int * rang;
	if g.tresor < cout then return 'tresor'; end if;
	update public.guildes set tresor = tresor - cout,
		benedictions = benedictions || jsonb_build_object(p_benediction, rang) where id = g.id;
	perform public._guilde_ecrire_journal(g.id, format('Bénédiction %s rang %s accordée à toute la guilde !',
		noms ->> p_benediction, rang));
	return 'ok';
end $$;


-- ---------------------------------------------------------------------
-- Boutique de guilde (Sceaux du joueur). Renvoie l'objet à donner dans le jeu.
-- ---------------------------------------------------------------------
create or replace function public.guilde_acheter(p_article text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	a jsonb;
	sem text := public._guilde_semaine()::text;
	achats jsonb;
	deja int;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid() for update;
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	select x into a from jsonb_array_elements(public.guilde_boutique()) x where x ->> 'id' = p_article;
	if a is null then return jsonb_build_object('code', 'introuvable'); end if;
	achats := case when moi.boutique ->> 'semaine' = sem then coalesce(moi.boutique -> 'achats', '{}'::jsonb) else '{}'::jsonb end;
	deja := coalesce((achats ->> p_article)::int, 0);
	if deja >= (a ->> 'limite')::int then return jsonb_build_object('code', 'limite'); end if;
	if moi.sceaux < (a ->> 'prix')::int then return jsonb_build_object('code', 'sceaux'); end if;
	achats := achats || jsonb_build_object(p_article, deja + 1);
	update public.guilde_membres set sceaux = sceaux - (a ->> 'prix')::int,
		boutique = jsonb_build_object('semaine', sem, 'achats', achats) where joueur = auth.uid();
	return jsonb_build_object('code', 'ok', 'recompense', jsonb_build_object(a ->> 'id', (a ->> 'quantite')::int));
end $$;


-- ---------------------------------------------------------------------
-- Boss de guilde : un coup (= un assaut) ; le jeu envoie les dégâts infligés.
-- ---------------------------------------------------------------------
create or replace function public.guilde_boss_frapper(p_degats bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	b public.guilde_boss;
	bj public.guilde_boss_joueurs;
	r jsonb := public.guilde_reglages();
	coup bigint;
	pseudo text;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	b := public._guilde_boss(moi.guilde);
	insert into public.guilde_boss_joueurs (guilde, semaine, joueur) values (moi.guilde, b.semaine, auth.uid())
		on conflict do nothing;
	select * into bj from public.guilde_boss_joueurs
		where guilde = moi.guilde and semaine = b.semaine and joueur = auth.uid() for update;
	if bj.jour is distinct from public._guilde_jour() then
		bj.essais := 0;
	end if;
	if bj.essais >= (r ->> 'boss_essais_jour')::int then return jsonb_build_object('code', 'essais'); end if;
	select * into b from public.guilde_boss where guilde = moi.guilde and semaine = b.semaine for update;
	coup := least(greatest(coalesce(p_degats, 0), 0), (r ->> 'boss_degats_max_coup')::bigint);
	coup := least(coup, greatest(b.pv_max - b.degats, 0));
	update public.guilde_boss_joueurs set degats = degats + coup, coups = coups + 1,
		jour = public._guilde_jour(), essais = bj.essais + 1
		where guilde = moi.guilde and semaine = b.semaine and joueur = auth.uid();
	update public.guilde_boss set degats = degats + coup,
		abattu_le = case when abattu_le is null and degats + coup >= pv_max then now() else abattu_le end
		where guilde = moi.guilde and semaine = b.semaine returning * into b;
	if b.abattu_le is not null and b.degats >= b.pv_max and b.degats - coup < b.pv_max then
		select p.pseudo into pseudo from public.profils p where p.id = auth.uid();
		perform public._guilde_ecrire_journal(moi.guilde, format('Le Boss de guilde est abattu ! Coup final : %s.', pseudo));
		perform public._guilde_gagner_xp(moi.guilde, 200, 200);
	end if;
	return jsonb_build_object('code', 'ok', 'coup', coup, 'degats', b.degats, 'pv_max', b.pv_max,
		'abattu', b.abattu_le is not null);
end $$;

-- Récompenses des paliers atteints par la guilde (pour ceux qui ont frappé au moins une fois cette semaine).
create or replace function public.guilde_boss_reclamer() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	b public.guilde_boss;
	bj public.guilde_boss_joueurs;
	r jsonb := public.guilde_reglages();
	atteints int := 0;
	i int;
	butin jsonb := '{}'::jsonb;
	k text;
	v_sceaux int := 0;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return jsonb_build_object('code', 'pas_de_guilde'); end if;
	b := public._guilde_boss(moi.guilde);
	select * into bj from public.guilde_boss_joueurs
		where guilde = moi.guilde and semaine = b.semaine and joueur = auth.uid() for update;
	if not found or bj.coups = 0 then return jsonb_build_object('code', 'pas_participe'); end if;
	for i in 0 .. jsonb_array_length(r -> 'boss_paliers') - 1 loop
		if b.degats * 100 >= (r -> 'boss_paliers' ->> i)::bigint * b.pv_max then atteints := i + 1; end if;
	end loop;
	if atteints <= bj.paliers then return jsonb_build_object('code', 'rien'); end if;
	for i in bj.paliers .. atteints - 1 loop
		v_sceaux := v_sceaux + (r -> 'boss_sceaux' ->> i)::int;
		for k in select jsonb_object_keys(r -> 'boss_butin' -> i) loop
			butin := butin || jsonb_build_object(k, coalesce((butin ->> k)::int, 0) + (r -> 'boss_butin' -> i ->> k)::int);
		end loop;
	end loop;
	update public.guilde_boss_joueurs set paliers = atteints
		where guilde = moi.guilde and semaine = b.semaine and joueur = auth.uid();
	update public.guilde_membres set sceaux = sceaux + v_sceaux where joueur = auth.uid();
	return jsonb_build_object('code', 'ok', 'recompense', butin, 'sceaux', v_sceaux, 'paliers', atteints - bj.paliers);
end $$;


-- ---------------------------------------------------------------------
-- Discussion de guilde
-- ---------------------------------------------------------------------
create or replace function public.guilde_chat_envoyer(p_texte text) returns text
language plpgsql security definer set search_path = public as $$
declare
	moi public.guilde_membres;
	r jsonb := public.guilde_reglages();
	t text := btrim(coalesce(p_texte, ''));
	pseudo text;
	dernier timestamptz;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return 'pas_de_guilde'; end if;
	if char_length(t) = 0 then return 'vide'; end if;
	t := left(t, (r ->> 'chat_longueur')::int);
	select max(cree_le) into dernier from public.guilde_chat where guilde = moi.guilde and joueur = auth.uid();
	if dernier is not null and dernier > now() - make_interval(secs => (r ->> 'chat_delai_secondes')::int) then
		return 'trop_vite';
	end if;
	select p.pseudo into pseudo from public.profils p where p.id = auth.uid();
	insert into public.guilde_chat (guilde, joueur, pseudo, texte) values (moi.guilde, auth.uid(), pseudo, t);
	delete from public.guilde_chat where guilde = moi.guilde and id < (select min(id) from
		(select id from public.guilde_chat where guilde = moi.guilde order by id desc limit (r ->> 'chat_gardes')::int) x);
	return 'ok';
end $$;

-- Messages plus récents que p_depuis (0 = les 50 derniers), du plus ancien au plus récent.
create or replace function public.guilde_chat_lire(p_depuis bigint) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
	moi public.guilde_membres;
begin
	select * into moi from public.guilde_membres where joueur = auth.uid();
	if not found then return '[]'::jsonb; end if;
	return coalesce((select jsonb_agg(jsonb_build_object('id', c.id, 'joueur', c.joueur, 'pseudo', c.pseudo,
			'texte', c.texte, 'cree_le', c.cree_le) order by c.id)
		from (select * from public.guilde_chat where guilde = moi.guilde and id > coalesce(p_depuis, 0)
			order by id desc limit 50) c), '[]'::jsonb);
end $$;


-- Les joueurs connectés peuvent appeler ces fonctions (et seulement elles).
revoke all on function public.guilde_vie(), public.guilde_donner(text), public.guilde_annonce(text),
	public.guilde_benir(text), public.guilde_acheter(text), public.guilde_boss_frapper(bigint),
	public.guilde_boss_reclamer(), public.guilde_chat_envoyer(text), public.guilde_chat_lire(bigint) from public, anon;
grant execute on function public.guilde_vie(), public.guilde_donner(text), public.guilde_annonce(text),
	public.guilde_benir(text), public.guilde_acheter(text), public.guilde_boss_frapper(bigint),
	public.guilde_boss_reclamer(), public.guilde_chat_envoyer(text), public.guilde_chat_lire(bigint) to authenticated;
revoke all on function public._guilde_ecrire_journal(uuid, text), public._guilde_gagner_xp(uuid, int, int),
	public._guilde_boss(uuid) from public, anon, authenticated;
