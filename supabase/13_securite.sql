-- =====================================================================
--  BROTHERS OF LEGACY : TEARS AND BLOOD — renforcement de la sécurité (v0.81)
--
--  À COLLER EN ENTIER dans Supabase > SQL Editor > New query, puis « Run ».
--  À faire après TOUS les autres fichiers (01 à 12), et à relancer après chaque nouveau fichier.
--  Peut être relancé sans danger : il ne touche à aucune donnée.
--
--  Pourquoi : dans Postgres, une fonction peut être appelée par TOUT LE MONDE tant qu'on ne
--  l'interdit pas. Les fonctions « internes » du jeu (celles dont le nom commence par _ : donner de
--  l'XP à une guilde, clore un match d'Arène classée, finir une guerre…) n'étaient donc pas
--  protégées : un tricheur aurait pu les appeler directement. Ce fichier :
--    1. interdit les fonctions internes (_…) à tous les joueurs (le jeu, lui, les appelle depuis le
--       serveur, ça continue de marcher) ;
--    2. réserve toutes les autres fonctions aux joueurs CONNECTÉS, sauf les trois qui doivent marcher
--       sans compte (pseudo libre ?, compter l'appareil, envoyer un signalement).
-- =====================================================================

do $$
declare
	f record;
	sans_compte text[] := array['pseudo_disponible', 'signaler_installation', 'envoyer_signalement'];
begin
	for f in
		select p.oid::regprocedure as sig, p.proname as nom
		from pg_proc p join pg_namespace n on n.oid = p.pronamespace
		where n.nspname = 'public' and p.prokind = 'f'
	loop
		if f.nom like '\_%' then
			execute format('revoke all on function %s from public, anon, authenticated', f.sig);
		elsif f.nom = any (sans_compte) then
			execute format('revoke all on function %s from public', f.sig);
			execute format('grant execute on function %s to anon, authenticated', f.sig);
		else
			execute format('revoke all on function %s from public, anon', f.sig);
			execute format('grant execute on function %s to authenticated', f.sig);
		end if;
	end loop;
end;
$$;
