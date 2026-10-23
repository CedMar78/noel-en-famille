CREATE OR REPLACE FUNCTION public.get_group_registration_status(p_group_id uuid)
 RETURNS TABLE(member_id uuid, first_name text, wishes_count bigint, couple_valid boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
    if not exists (
        select 1
        from public.groups as g
        where g.id = p_group_id
          and g.organizer_user_id = auth.uid()
    ) then
        raise exception 'Seul l’organisateur peut consulter ce tableau.';
    end if;

    return query
    select
        m.id,
        m.first_name,

        (
            select count(*)
            from public.wishes as w
            where w.member_id = m.id
        ),

        coalesce(
            (
                m.has_partner = false
                and m.partner_id is null
            )
            or
            (
                m.has_partner = true
                and exists (
                    select 1
                    from public.members as partner
                    where partner.id = m.partner_id
                      and partner.id <> m.id
                      and partner.group_id = m.group_id
                      and partner.partner_id = m.id
                      and partner.has_partner = true
                )
            ),
            false
        )

    from public.members as m
    where m.group_id = p_group_id
    order by m.first_name, m.id;
end;
$function$;

