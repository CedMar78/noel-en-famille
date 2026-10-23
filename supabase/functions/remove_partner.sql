CREATE OR REPLACE FUNCTION public.remove_partner(p_group_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    my_id uuid;
    previous_partner_id uuid;
    current_partner_id uuid;
begin
    -- Retrouver mon inscription grâce à ma session.
    select id, partner_id
    into my_id, previous_partner_id
    from public.members
    where group_id = p_group_id
      and user_id = auth.uid();
if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

-- Verrouiller les inscriptions dans le même ordre
-- que la fonction de confirmation du couple.
perform m.id
from public.members as m
where m.id in (my_id, previous_partner_id)
order by m.id
for update;

-- Vérifier que le couple n'a pas changé entre-temps.
select partner_id
into current_partner_id
from public.members
where id = my_id
  and group_id = p_group_id
  and user_id = auth.uid();

if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

if current_partner_id is distinct from previous_partner_id then
    raise exception 'Le couple a changé. Recharge la page et réessaie.';
end if;

-- Retirer le lien de mon conjoint uniquement
-- si ce lien pointe bien vers moi.
if previous_partner_id is not null then

    update public.members
    set partner_id = null,
        has_partner = false
    where id = previous_partner_id
      and group_id = p_group_id
      and partner_id = my_id;

    if not found then
        raise exception 'Les liens du couple sont incohérents.';
    end if;

end if;

-- Retirer mon propre lien.
update public.members
set partner_id = null,
    has_partner = false
where id = my_id;
end;
$function$;
