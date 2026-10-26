CREATE OR REPLACE FUNCTION public.register_member_by_invite_code(
    p_invite_code text,
    p_first_name text
)
RETURNS TABLE (
    id uuid,
    has_partner boolean,
    partner_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
    current_user_id uuid := auth.uid();
    selected_group_id uuid;
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Une connexion est nécessaire.';
    END IF;

    IF p_first_name IS NULL OR trim(p_first_name) = '' THEN
        RAISE EXCEPTION 'Renseigne ton prénom.';
    END IF;

    SELECT g.id
    INTO selected_group_id
    FROM public.groups AS g
    WHERE upper(g.invite_code) = upper(trim(p_invite_code))
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Code d’invitation incorrect.';
    END IF;

    RETURN QUERY
    INSERT INTO public.members AS m (
        group_id,
        user_id,
        first_name
    )
    VALUES (
        selected_group_id,
        current_user_id,
        trim(p_first_name)
    )
    ON CONFLICT (user_id, group_id)
    DO UPDATE SET first_name = EXCLUDED.first_name
    RETURNING m.id, m.has_partner, m.partner_id;
END;
$function$;

