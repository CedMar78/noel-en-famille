CREATE OR REPLACE FUNCTION public.confirm_gift_reveal(p_group_id uuid)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    reveal_date timestamptz;
begin
    update public.members as me
    set gifts_revealed_at = coalesce(
        me.gifts_revealed_at,
        now()
    )
    from public.groups as g
    where me.group_id = p_group_id
      and me.user_id = auth.uid()
      and g.id = me.group_id
      and g.drawn_at is not null
      and (
          select count(*)
          from public.gift_assignments as a
          where a.group_id = me.group_id
            and a.giver_id = me.id
      ) = 2
    returning me.gifts_revealed_at into reveal_date;

    if not found then
        raise exception 'Aucun tirage terminé ne permet cette découverte.';
    end if;

    return reveal_date;
end;
$function$;

