-- Contrôle des tirages enregistrés, sans révéler les destinataires.
-- Vérification du 26/10/2026 :
-- groupe Famille, 4 participants, résultats des contrôles : 0 / 0 / 0.
-- Ce résultat valide le tirage testé, pas tous les cas possibles.

select
    g.name as groupe,

    (
        select count(*)
        from public.members as m
        where m.group_id = g.id
    ) as participants,

    (
        select count(*)
        from public.members as m
        where m.group_id = g.id
          and (
              select count(*)
              from public.gift_assignments as a
              where a.group_id = g.id
                and a.giver_id = m.id
          ) <> 2
    ) as participants_sans_exactement_2_cadeaux_offerts,

    (
        select count(*)
        from public.members as m
        where m.group_id = g.id
          and (
              select count(*)
              from public.gift_assignments as a
              where a.group_id = g.id
                and a.recipient_id = m.id
          ) <> 2
    ) as participants_sans_exactement_2_cadeaux_recus,

    (
        select count(*)
        from public.gift_assignments as a
        join public.members as donneur
          on donneur.id = a.giver_id
        join public.members as destinataire
          on destinataire.id = a.recipient_id
        where a.group_id = g.id
          and (
              donneur.id = destinataire.id
              or donneur.partner_id = destinataire.id
              or destinataire.partner_id = donneur.id
          )
    ) as attributions_interdites

from public.groups as g
where g.drawn_at is not null
order by g.name;