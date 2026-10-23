CREATE OR REPLACE FUNCTION public.complete_my_registration(p_group_id uuid)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    me public.members%rowtype;
    completion_date timestamptz;
begin
    select *
    into me
    from public.members
    where group_id = p_group_id
      and user_id = auth.uid()
    for update;
if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

if (
    select count(*)
    from public.wishes as w
    where w.member_id = me.id
) not between 2 and 3 then
    raise exception 'Ajoute deux ou trois idées cadeaux avant de valider.';
end if;

if (
    (
        me.has_partner = false
        and me.partner_id is null
    )
    or
    (
        me.has_partner = true
        and exists (
            select 1
            from public.members as partner
            where partner.id = me.partner_id
              and partner.id <> me.id
              and partner.group_id = me.group_id
              and partner.partner_id = me.id
              and partner.has_partner = true
        )
    )
) is not true then
    raise exception 'Complète ton choix de conjoint avant de valider.';
end if;

update public.members as m
set registration_completed_at = coalesce(
    m.registration_completed_at,
    now()
)
where m.id = me.id
returning m.registration_completed_at into completion_date;

return completion_date;
end;
$function$;
