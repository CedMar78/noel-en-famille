CREATE OR REPLACE FUNCTION public.list_group_partner_options(p_group_id uuid)
 RETURNS TABLE(id uuid, first_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select candidate.id, candidate.first_name
    from public.members as candidate
    join public.members as me
      on me.group_id = candidate.group_id
     and me.user_id = auth.uid()
    where candidate.group_id = p_group_id
      and candidate.id <> me.id
      and (
          candidate.partner_id is null
          or candidate.partner_id = me.id
      )
    order by candidate.first_name, candidate.id;
$function$;