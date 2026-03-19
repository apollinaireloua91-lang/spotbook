-- Exécuter ces tests dans le SQL Editor avec un rôle client authentifié.

-- 1) Client ne doit pas voir les bookings d'un autre pro
select * from bookings where pro_id = '00000000-0000-0000-0000-000000000000';
-- attendu: 0 ligne

-- 2) Audit logs: uniquement ses propres logs
select * from audit_logs;
-- attendu: uniquement user_id = auth.uid()

-- 3) Modification interdite des champs sensibles
update profiles_pro set commission_rate = 0;
-- attendu: erreur RLS

-- 4) Token social protégé
select access_token from social_connections;
-- attendu: RLS bloque, ou données chiffrées
