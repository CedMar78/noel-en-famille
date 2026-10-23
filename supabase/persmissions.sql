-- Autorisations de la fonction de recherche par code.
-- À appliquer après la création de la fonction.

REVOKE ALL
ON FUNCTION public.find_group_by_invite_code(text)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.find_group_by_invite_code(text)
TO authenticated, postgres, service_role;

-- Autorisations de la liste des conjoints disponibles.

REVOKE ALL
ON FUNCTION public.list_group_partner_options(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.list_group_partner_options(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de l'enregistrement du couple.

REVOKE ALL
ON FUNCTION public.choose_partner(uuid, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.choose_partner(uuid, uuid)
TO authenticated, postgres, service_role;

-- Autorisations du retrait du lien entre conjoints.

REVOKE ALL
ON FUNCTION public.remove_partner(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.remove_partner(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la validation finale de l'inscription.

REVOKE ALL
ON FUNCTION public.complete_my_registration(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.complete_my_registration(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la lecture de sa propre inscription.

REVOKE ALL
ON FUNCTION public.get_my_registration(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_my_registration(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la consultation du statut du tirage.

REVOKE ALL
ON FUNCTION public.get_group_draw_status(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_draw_status(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la lecture de ses destinataires et de leurs idées.

REVOKE ALL
ON FUNCTION public.get_my_gift_recipients(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_my_gift_recipients(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la confirmation de découverte des destinataires.

REVOKE ALL
ON FUNCTION public.confirm_gift_reveal(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.confirm_gift_reveal(uuid)
TO authenticated, postgres, service_role;

-- Autorisations du tableau de suivi des inscriptions.

REVOKE ALL
ON FUNCTION public.get_group_registration_status(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_registration_status(uuid)
TO authenticated, postgres, service_role;

-- Autorisations du suivi détaillé des inscriptions.

REVOKE ALL
ON FUNCTION public.get_group_registration_progress(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_registration_progress(uuid)
TO authenticated, postgres, service_role;

-- Fonction interne de vérification avant le tirage.

REVOKE ALL
ON FUNCTION public.check_group_before_draw(uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.check_group_before_draw(uuid)
TO postgres, service_role;

-- Fonction interne de calcul de la répartition des cadeaux.

REVOKE ALL
ON FUNCTION public.compute_gift_draw(uuid[], uuid[])
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.compute_gift_draw(uuid[], uuid[])
TO postgres, service_role;


-- Autorisations du lancement du tirage.
-- La fonction vérifie que l'appelant est l'organisateur.

REVOKE ALL
ON FUNCTION public.draw_group(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.draw_group(uuid)
TO authenticated, postgres, service_role;

-- Fonction appelée par le déclencheur de protection des inscriptions.

REVOKE ALL
ON FUNCTION public.guard_members_after_draw()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.guard_members_after_draw()
TO postgres, service_role;

-- Fonction appelée par le déclencheur de contrôle des inscriptions validées.

REVOKE ALL
ON FUNCTION public.require_completed_registrations()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.require_completed_registrations()
TO postgres, service_role;