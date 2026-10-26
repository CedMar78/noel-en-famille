CREATE OR REPLACE FUNCTION public.guard_members_after_draw()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    group_ids uuid[];
    checked_group record;
begin
    if TG_OP = 'INSERT' then

        group_ids := array[NEW.group_id];

    elsif TG_OP = 'DELETE' then

        group_ids := array[OLD.group_id];

    else

        -- Un simple changement de prénom reste autorisé.
        if row(
            NEW.id,
            NEW.group_id,
            NEW.user_id,
            NEW.has_partner,
            NEW.partner_id
        ) is not distinct from row(
            OLD.id,
            OLD.group_id,
            OLD.user_id,
            OLD.has_partner,
            OLD.partner_id
        ) then
            return null;
        end if;

        group_ids := array[OLD.group_id, NEW.group_id];

    end if;

    for checked_group in
        select g.id, g.drawn_at
        from public.groups as g
        where g.id = any(group_ids)
        order by g.id
        for share
    loop
        if checked_group.drawn_at is not null then
            raise exception
                'Le tirage a déjà eu lieu : les inscriptions et les couples sont verrouillés.';
        end if;
    end loop;

    return null;
end;
$function$;
