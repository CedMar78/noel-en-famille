CREATE OR REPLACE FUNCTION public.get_group_draw_status(p_group_id uuid)
 RETURNS TABLE(is_organizer boolean, drawn_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select
        coalesce(g.organizer_user_id = auth.uid(), false),
        g.drawn_at
    from public.groups as g
    where g.id = p_group_id
      and (
          g.organizer_user_id = auth.uid()
          or exists (
              select 1
              from public.members as me
              where me.group_id = g.id
                and me.user_id = auth.uid()
          )
      );
$function$;
