CREATE OR REPLACE FUNCTION public.get_my_registration(p_group_id uuid)
 RETURNS TABLE(member_id uuid, first_name text, has_partner boolean, partner_id uuid, partner_name text, wishes jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select
        me.id,
        me.first_name,
        me.has_partner,
        me.partner_id,
        partner.first_name,
        coalesce(
            (
                select jsonb_agg(w.label order by w.id)
                from public.wishes as w
                where w.member_id = me.id
            ),
            '[]'::jsonb
        )
    from public.members as me
    left join public.members as partner
      on partner.id = me.partner_id
     and partner.group_id = me.group_id
     and partner.partner_id = me.id
    where me.group_id = p_group_id
      and me.user_id = auth.uid();
$function$;
