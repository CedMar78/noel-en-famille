-- Recherche un groupe à partir de son code d'invitation.
-- Nécessite la table public.groups.
-- Les autorisations d'exécution sont à conserver séparément.

CREATE OR REPLACE FUNCTION public.find_group_by_invite_code(code text)
RETURNS TABLE(id uuid, name text, message text)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
    SELECT
        g.id,
        g.name,
        g.message
    FROM public.groups AS g
    WHERE upper(g.invite_code) = upper(trim(code))
    LIMIT 1;
$function$;
