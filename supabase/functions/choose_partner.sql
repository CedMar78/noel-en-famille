CREATE OR REPLACE FUNCTION public.choose_partner(p_group_id uuid, p_partner_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    me public.members%rowtype;
    chosen public.members%rowtype;
begin
    -- Retrouver mon inscription grâce à ma session.
    select *
    into me
    from public.members
    where group_id = p_group_id
      and user_id = auth.uid();
if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

if p_partner_id is null or p_partner_id = me.id then
    raise exception 'Choisis une autre personne que toi.';
end if;

-- Verrouiller les deux inscriptions dans un ordre fixe.
-- Cela protège contre deux confirmations simultanées.
perform m.id
from public.members as m
where m.id in (me.id, p_partner_id)
order by m.id
for update;

-- Relire les informations après le verrouillage.
select *
into me
from public.members
where group_id = p_group_id
  and user_id = auth.uid();

if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

select *
into chosen
from public.members
where id = p_partner_id
  and group_id = p_group_id;

if not found then
    raise exception 'Cette personne ne fait pas partie de ton groupe.';
end if;

if me.partner_id is not null
   and me.partner_id <> chosen.id then
    raise exception 'Tu as déjà un autre conjoint enregistré.';
end if;

if chosen.partner_id is not null
   and chosen.partner_id <> me.id then
    raise exception 'Cette personne a déjà un autre conjoint enregistré.';
end if;

update public.members
set partner_id = chosen.id,
    has_partner = true
where id = me.id;

update public.members
set partner_id = me.id,
    has_partner = true
where id = chosen.id;
end;
$function$;