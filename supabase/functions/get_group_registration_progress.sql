CREATE OR REPLACE FUNCTION public.get_group_registration_progress(p_group_id uuid)
 RETURNS TABLE(member_id uuid, first_name text, wishes_count bigint, couple_valid boolean, registration_completed_at timestamp with time zone, eligible_recipient_count bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select
        status.member_id,
        status.first_name,
        status.wishes_count,
        status.couple_valid,
        m.registration_completed_at,
    (
        select count(*)
        from public.members as candidate
        where candidate.group_id = m.group_id
          and candidate.id <> m.id
          and candidate.id is distinct from m.partner_id
          and candidate.partner_id is distinct from m.id
    )

from public.get_group_registration_status(p_group_id) as status
join public.members as m
  on m.id = status.member_id
 and m.group_id = p_group_id;
$function$;
