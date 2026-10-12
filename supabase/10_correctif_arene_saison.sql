-- CORRECTIF ARÈNE (v0.62.1) : « UPDATE requires WHERE clause »
-- À la fin d'une saison d'Arène, la remise à zéro des points faisait un UPDATE sans WHERE,
-- ce que Supabase refuse : toute l'Arène renvoyait « erreur du serveur (400) ».
-- Supabase → SQL Editor → New query → colle TOUT ce fichier → Run → « Success ».
-- (Sans danger : ne remplace que cette fonction, aucune donnée n'est effacée.)

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
			saison = s.numero + 1
		where joueur is not null;      -- (Supabase refuse un UPDATE sans WHERE)
		insert into public.arene_saisons (numero, debut, fin)
			values (s.numero + 1, now(), greatest(s.fin + duree, now() + interval '1 day'))
			returning * into s;
	else
		insert into public.arene_saisons (numero, debut, fin)
			values (1, now(), now() + duree) returning * into s;
	end if;
	return s;
end $$;
