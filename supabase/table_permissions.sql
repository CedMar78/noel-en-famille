-- Copie des autorisations actuelles sur les tables.
-- À appliquer après tables.sql.

-- Retirer les droits éventuellement accordés par défaut.
REVOKE ALL PRIVILEGES
ON TABLE
    public.groups,
    public.members,
    public.wishes,
    public.gift_assignments
FROM PUBLIC, anon, authenticated;

-- Groupes : lecture seule, filtrée par les politiques RLS.
-- Le parcours utilise les fonctions SQL dédiées.
GRANT SELECT
ON TABLE public.groups
TO anon, authenticated;

-- Participants et idées cadeaux.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.members, public.wishes
TO authenticated;

-- Attributions : lecture uniquement depuis le client.
GRANT SELECT
ON TABLE public.gift_assignments
TO authenticated;

-- Administration.
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
ON TABLE
    public.groups,
    public.members,
    public.wishes,
    public.gift_assignments
TO postgres, service_role;

-- Les inscriptions passent par la fonction qui vérifie le code.
REVOKE INSERT
ON TABLE public.members
FROM PUBLIC, anon, authenticated;

-- Limiter les modifications directes des inscriptions.
REVOKE UPDATE
ON TABLE public.members
FROM PUBLIC, anon, authenticated;

GRANT UPDATE (first_name, has_partner)
ON TABLE public.members
TO authenticated;