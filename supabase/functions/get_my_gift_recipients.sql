CREATE OR REPLACE FUNCTION public.get_my_gift_recipients(p_group_id uuid)
 RETURNS TABLE(recipient_id uuid, first_name text, wishes jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select
        recipient.id,
        recipient.first_name,
        coalesce(
            (
                select jsonb_agg(w.label order by w.id)
                from public.wishes as w
                where w.member_id = recipient.id
            ),
            '[]'::jsonb
        )
    from public.members as me
    join public.groups as g
      on g.id = me.group_id
    join public.gift_assignments as assignment
      on assignment.giver_id = me.id
     and assignment.group_id = me.group_id
    join public.members as recipient
      on recipient.id = assignment.recipient_id
     and recipient.group_id = me.group_id
    where me.user_id = auth.uid()
      and me.group_id = p_group_id
      and g.drawn_at is not null
    order by recipient.first_name, recipient.id;
$function$;

