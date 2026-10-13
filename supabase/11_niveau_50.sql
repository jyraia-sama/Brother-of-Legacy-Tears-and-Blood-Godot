-- =====================================================================
-- v0.66 « Le prix des étoiles » : le niveau maximum des héros passe à 50 (★6 Éveillé).
-- Les contrôles de vraisemblance des équipes (Arène, Arène classée, Guerre des Bannières)
-- acceptaient les niveaux 1 à 40 : ils acceptent maintenant 1 à 50.
-- À exécuter UNE fois dans Supabase -> SQL Editor (sans risque : remplace 3 fonctions).
-- =====================================================================

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
			or coalesce((u ->> 'niveau')::int, 0) not between 1 and 50   -- 50 : niveau max à ★6 (v0.66)
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
			or coalesce((u ->> 'niveau')::int, 0) not between 1 and 50
			or coalesce((u ->> 'etoiles')::int, 0) not between 0 and 6
			or coalesce((u ->> 'place')::int, -1) not between 0 and 4
			or (u ->> 'place')::int = any(places) then
			return false;
		end if;
		places := places || (u ->> 'place')::int;
	end loop;
	return true;
end $$;

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
			or coalesce((u ->> 'niveau')::int, 0) not between 1 and 50
			or coalesce((u ->> 'etoiles')::int, 0) not between 0 and 6
			or coalesce((u ->> 'place')::int, -1) not between 0 and 4
			or (u ->> 'place')::int = any(places) then
			return false;
		end if;
		places := places || (u ->> 'place')::int;
	end loop;
	return true;
end $$;
