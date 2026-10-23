CREATE OR REPLACE FUNCTION public.draw_group(p_group_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    member_ids uuid[];
    partner_ids uuid[];
    assignment_count integer;
begin
    -- Vérifier les droits avant de prendre les verrous.
    perform public.check_group_before_draw(p_group_id);

    -- Stabiliser les inscriptions et les souhaits
    -- pendant le calcul et son enregistrement.
    lock table public.members in exclusive mode;
    lock table public.wishes in share mode;
    lock table public.gift_assignments in exclusive mode;

    perform g.id
    from public.groups as g
    where g.id = p_group_id
    for update;

    -- Revérifier après une éventuelle attente.
    perform public.check_group_before_draw(p_group_id);

    if exists (
        select 1
        from public.gift_assignments
        where group_id = p_group_id
    ) then
        raise exception 'Des attributions existent déjà pour ce groupe.';
    end if;

    select
        array_agg(m.id order by m.id),
        array_agg(m.partner_id order by m.id)
    into member_ids, partner_ids
    from public.members as m
    where m.group_id = p_group_id;

    insert into public.gift_assignments (
        group_id,
        giver_id,
        recipient_id
    )
    select
        p_group_id,
        result.giver_id,
        result.recipient_id
    from public.compute_gift_draw(
        member_ids,
        partner_ids
    ) as result;

    get diagnostics assignment_count = row_count;

    if assignment_count <> 2 * cardinality(member_ids) then
        raise exception 'Le nombre total de cadeaux est incorrect.';
    end if;

    -- Vérifier les deux cadeaux offerts et reçus par personne.
    if exists (
        select 1
        from public.members as m
        where m.group_id = p_group_id
          and (
              (
                  select count(*)
                  from public.gift_assignments as a
                  where a.group_id = p_group_id
                    and a.giver_id = m.id
              ) <> 2
              or
              (
                  select count(*)
                  from public.gift_assignments as a
                  where a.group_id = p_group_id
                    and a.recipient_id = m.id
              ) <> 2
          )
    ) then
        raise exception 'Le tirage ne respecte pas les deux cadeaux par personne.';
    end if;

    -- Vérifier aussi l'exclusion des conjoints.
    if exists (
        select 1
        from public.gift_assignments as a
        join public.members as giver
          on giver.id = a.giver_id
        join public.members as recipient
          on recipient.id = a.recipient_id
        where a.group_id = p_group_id
          and (
              a.giver_id = a.recipient_id
              or giver.partner_id = recipient.id
              or recipient.partner_id = giver.id
          )
    ) then
        raise exception 'Une attribution concerne soi-même ou un conjoint.';
    end if;

    update public.groups
    set drawn_at = now()
    where id = p_group_id;

    return assignment_count;
end;
$function$;
