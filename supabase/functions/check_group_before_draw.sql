CREATE OR REPLACE FUNCTION public.check_group_before_draw(p_group_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    organizer_id uuid;
    draw_date timestamptz;
begin
    select organizer_user_id, drawn_at
    into organizer_id, draw_date
    from public.groups
    where id = p_group_id;

    if not found then
        raise exception 'Groupe introuvable.';
    end if;

    if auth.uid() is null
       or organizer_id is distinct from auth.uid() then
        raise exception 'Seul l’organisateur peut lancer le tirage.';
    end if;

    if draw_date is not null then
        raise exception 'Le tirage de ce groupe a déjà eu lieu.';
    end if;

    if (
        select count(*)
        from public.members
        where group_id = p_group_id
    ) < 3 then
        raise exception 'Il faut au moins trois participants.';
    end if;

    if exists (
        select 1
        from public.members as m
        where m.group_id = p_group_id
          and (
              select count(*)
              from public.wishes as w
              where w.member_id = m.id
          ) not between 2 and 3
    ) then
        raise exception 'Chaque participant doit avoir deux ou trois idées cadeaux.';
    end if;

    if exists (
        select 1
        from public.members as m
        where m.group_id = p_group_id
          and (
              (m.has_partner = false and m.partner_id is null)
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
              )
          ) is not true
    ) then
        raise exception 'Une inscription possède un choix de conjoint incomplet ou incohérent.';
    end if;
end;
$function$;

