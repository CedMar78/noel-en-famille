-- Installation sur un projet Supabase vierge uniquement.

BEGIN;

-- Fichier : tables.sql
-- Structure des tables de Noël en famille.
-- À créer dans un projet Supabase avant les fonctions,
-- les permissions et les déclencheurs.
-- Les politiques RLS seront conservées séparément.

-- Groupes
CREATE TABLE public.groups (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    name text NOT NULL,
    invite_code text NOT NULL,
    message text,
    draw_locked boolean NOT NULL DEFAULT false,
    organizer_user_id uuid,
    drawn_at timestamptz,

    CONSTRAINT groups_pkey
        PRIMARY KEY (id),

    CONSTRAINT groups_invite_code_key
        UNIQUE (invite_code),

    CONSTRAINT groups_organizer_user_id_fkey
        FOREIGN KEY (organizer_user_id)
        REFERENCES auth.users(id)
);

-- Participants
CREATE TABLE public.members (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    group_id uuid NOT NULL,
    first_name text NOT NULL DEFAULT 'NULL'::text,
    has_partner boolean NOT NULL DEFAULT false,
    partner_id uuid,
    user_id uuid NOT NULL,
    gifts_revealed_at timestamptz,
    registration_completed_at timestamptz,

    CONSTRAINT members_pkey
        PRIMARY KEY (id),

    CONSTRAINT members_group_id_fkey
        FOREIGN KEY (group_id)
        REFERENCES public.groups(id)
        ON DELETE CASCADE,

    CONSTRAINT members_partner_id_fkey
        FOREIGN KEY (partner_id)
        REFERENCES public.members(id)
        ON DELETE SET NULL,

    CONSTRAINT members_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE
);

CREATE UNIQUE INDEX members_group_id_id_unique
    ON public.members (group_id, id);

CREATE UNIQUE INDEX members_user_group_unique
    ON public.members (user_id, group_id);

CREATE INDEX members_user_id_idx
    ON public.members (user_id);

-- Idées cadeaux
CREATE TABLE public.wishes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    member_id uuid NOT NULL,
    label text NOT NULL,

    CONSTRAINT wishes_pkey
        PRIMARY KEY (id),

    CONSTRAINT wishes_member_id_fkey
        FOREIGN KEY (member_id)
        REFERENCES public.members(id)
        ON DELETE CASCADE
);

CREATE INDEX wishes_member_id_idx
    ON public.wishes (member_id);

-- Attributions des cadeaux
CREATE TABLE public.gift_assignments (
    group_id uuid NOT NULL,
    giver_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT gift_assignments_pkey
        PRIMARY KEY (group_id, giver_id, recipient_id),

    CONSTRAINT gift_assignments_no_self
        CHECK (giver_id <> recipient_id),

    CONSTRAINT gift_assignments_group_id_fkey
        FOREIGN KEY (group_id)
        REFERENCES public.groups(id),

    CONSTRAINT gift_assignments_giver_group
        FOREIGN KEY (group_id, giver_id)
        REFERENCES public.members(group_id, id),

    CONSTRAINT gift_assignments_recipient_group
        FOREIGN KEY (group_id, recipient_id)
        REFERENCES public.members(group_id, id)
);

-- Activer la protection RLS dès la création des tables.
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_assignments ENABLE ROW LEVEL SECURITY;

-- Fichier : functions/find_group_by_invite_code.sql
-- Recherche un groupe à partir de son code d'invitation.
-- Nécessite la table public.groups.
-- Les autorisations d'exécution sont à conserver séparément.

CREATE OR REPLACE FUNCTION public.find_group_by_invite_code(code text)
RETURNS TABLE(id uuid, name text, message text)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
    SELECT
        g.id,
        g.name,
        g.message
    FROM public.groups AS g
    WHERE upper(g.invite_code) = upper(trim(code))
    LIMIT 1;
$function$;


-- Fichier : functions/list_group_partner_options.sql
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

-- Fichier : functions/choose_partner.sql
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

-- Fichier : functions/remove_partner.sql
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


-- Fichier : functions/complete_my_registration.sql
CREATE OR REPLACE FUNCTION public.complete_my_registration(p_group_id uuid)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    me public.members%rowtype;
    completion_date timestamptz;
begin
    select *
    into me
    from public.members
    where group_id = p_group_id
      and user_id = auth.uid()
    for update;
if not found then
    raise exception 'Ton inscription est introuvable.';
end if;

if (
    select count(*)
    from public.wishes as w
    where w.member_id = me.id
) not between 2 and 3 then
    raise exception 'Ajoute deux ou trois idées cadeaux avant de valider.';
end if;

if (
    (
        me.has_partner = false
        and me.partner_id is null
    )
    or
    (
        me.has_partner = true
        and exists (
            select 1
            from public.members as partner
            where partner.id = me.partner_id
              and partner.id <> me.id
              and partner.group_id = me.group_id
              and partner.partner_id = me.id
              and partner.has_partner = true
        )
    )
) is not true then
    raise exception 'Complète ton choix de conjoint avant de valider.';
end if;

update public.members as m
set registration_completed_at = coalesce(
    m.registration_completed_at,
    now()
)
where m.id = me.id
returning m.registration_completed_at into completion_date;

return completion_date;
end;
$function$;


-- Fichier : functions/get_my_registration.sql
CREATE OR REPLACE FUNCTION public.get_my_registration(p_group_id uuid)
 RETURNS TABLE(member_id uuid, first_name text, has_partner boolean, partner_id uuid, partner_name text, wishes jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    select
        me.id,
        me.first_name,
        me.has_partner,
        me.partner_id,
        partner.first_name,
        coalesce(
            (
                select jsonb_agg(w.label order by w.id)
                from public.wishes as w
                where w.member_id = me.id
            ),
            '[]'::jsonb
        )
    from public.members as me
    left join public.members as partner
      on partner.id = me.partner_id
     and partner.group_id = me.group_id
     and partner.partner_id = me.id
    where me.group_id = p_group_id
      and me.user_id = auth.uid();
$function$;


-- Fichier : functions/get_group_draw_status.sql
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


-- Fichier : functions/get_my_gift_recipients.sql
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



-- Fichier : functions/confirm_gift_reveal.sql
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



-- Fichier : functions/get_group_registration_status.sql
CREATE OR REPLACE FUNCTION public.get_group_registration_status(p_group_id uuid)
 RETURNS TABLE(member_id uuid, first_name text, wishes_count bigint, couple_valid boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
    if not exists (
        select 1
        from public.groups as g
        where g.id = p_group_id
          and g.organizer_user_id = auth.uid()
    ) then
        raise exception 'Seul l’organisateur peut consulter ce tableau.';
    end if;

    return query
    select
        m.id,
        m.first_name,

        (
            select count(*)
            from public.wishes as w
            where w.member_id = m.id
        ),

        coalesce(
            (
                m.has_partner = false
                and m.partner_id is null
            )
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
            ),
            false
        )

    from public.members as m
    where m.group_id = p_group_id
    order by m.first_name, m.id;
end;
$function$;



-- Fichier : functions/get_group_registration_progress.sql
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


-- Fichier : functions/check_group_before_draw.sql
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



-- Fichier : functions/compute_gift_draw.sql
CREATE OR REPLACE FUNCTION public.compute_gift_draw(p_member_ids uuid[], p_partner_ids uuid[])
 RETURNS TABLE(giver_id uuid, recipient_id uuid)
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
    n integer := cardinality(p_member_ids);
    node_count integer;
    sink integer;
    residual integer[][];
    parents integer[];
    queue integer[];
    head integer;
    flow integer := 0;
    i integer;
    j integer;
    u integer;
    v integer;
    neighbor integer;
begin
    if p_member_ids is null
       or p_partner_ids is null
       or n < 3
       or cardinality(p_partner_ids) <> n then
        raise exception 'Liste de participants invalide.';
    end if;

    node_count := 2 * n + 2;
    sink := node_count;

    residual := array_fill(
        0,
        array[node_count, node_count]
    );

    -- Chaque personne offre deux cadeaux
    -- et reçoit deux cadeaux.
    for i in 1..n loop
        residual[1][1 + i] := 2;
        residual[n + 1 + i][sink] := 2;

        for j in 1..n loop
            if i <> j
               and p_member_ids[j]
                   is distinct from p_partner_ids[i]
               and p_member_ids[i]
                   is distinct from p_partner_ids[j] then

                residual[1 + i][n + 1 + j] := 1;

            end if;
        end loop;
    end loop;

    -- Ajouter les cadeaux, en réorganisant
    -- les choix précédents si nécessaire.
    while flow < 2 * n loop

        parents := array_fill(0, array[node_count]);
        parents[1] := -1;
        queue := array[1];
        head := 1;

        while head <= cardinality(queue)
              and parents[sink] = 0 loop

            u := queue[head];
            head := head + 1;

            for neighbor in
                select nodes.node
                from generate_series(1, node_count)
                    as nodes(node)
                order by random()
            loop
                if parents[neighbor] = 0
                   and residual[u][neighbor] > 0 then

                    parents[neighbor] := u;
                    queue := array_append(queue, neighbor);

                    if neighbor = sink then
                        exit;
                    end if;

                end if;
            end loop;
        end loop;

        if parents[sink] = 0 then
            raise exception
                'Aucun tirage ne peut respecter toutes les règles avec ces participants.';
        end if;

        v := sink;

        while v <> 1 loop
            u := parents[v];

            residual[u][v] := residual[u][v] - 1;
            residual[v][u] := residual[v][u] + 1;

            v := u;
        end loop;

        flow := flow + 1;
    end loop;

    -- Renvoyer les attributions obtenues.
    for i in 1..n loop
        for j in 1..n loop
            if residual[n + 1 + j][1 + i] > 0 then
                giver_id := p_member_ids[i];
                recipient_id := p_member_ids[j];
                return next;
            end if;
        end loop;
    end loop;
end;
$function$;


-- Fichier : functions/draw_group.sql
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


-- Fichier : functions/guard_members_after_draw.sql
CREATE OR REPLACE FUNCTION public.guard_members_after_draw()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
    group_ids uuid[];
    checked_group record;
begin
    if TG_OP = 'INSERT' then

        group_ids := array[NEW.group_id];

    elsif TG_OP = 'DELETE' then

        group_ids := array[OLD.group_id];

    else

        -- Un simple changement de prénom reste autorisé.
        if row(
            NEW.id,
            NEW.group_id,
            NEW.user_id,
            NEW.has_partner,
            NEW.partner_id
        ) is not distinct from row(
            OLD.id,
            OLD.group_id,
            OLD.user_id,
            OLD.has_partner,
            OLD.partner_id
        ) then
            return null;
        end if;

        group_ids := array[OLD.group_id, NEW.group_id];

    end if;

    for checked_group in
        select g.id, g.drawn_at
        from public.groups as g
        where g.id = any(group_ids)
        order by g.id
        for share
    loop
        if checked_group.drawn_at is not null then
            raise exception
                'Le tirage a déjà eu lieu : les inscriptions et les couples sont verrouillés.';
        end if;
    end loop;

    return null;
end;
$function$;


-- Fichier : functions/require_completed_registrations.sql
CREATE OR REPLACE FUNCTION public.require_completed_registrations()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
    if exists (
        select 1
        from public.members as m
        where m.group_id = NEW.id
          and m.registration_completed_at is null
    ) then
        raise exception
            'Tous les participants doivent valider leur inscription avant le tirage.';
    end if;

    return NEW;
end;
$function$;


-- Fichier : policies.sql
-- Politiques RLS de Noël en famille.
-- À appliquer après tables.sql.
-- Aucune politique d'accès direct sur public.groups.

-- INSCRIPTIONS

CREATE POLICY members_select_own
ON public.members
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    (SELECT auth.uid()) = user_id
);

CREATE POLICY members_insert_own
ON public.members
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    (SELECT auth.uid()) = user_id
);

CREATE POLICY members_update_own
ON public.members
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    (SELECT auth.uid()) = user_id
)
WITH CHECK (
    (SELECT auth.uid()) = user_id
);

CREATE POLICY members_delete_own
ON public.members
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    (SELECT auth.uid()) = user_id
);

-- IDÉES CADEAUX

CREATE POLICY wishes_select_own
ON public.wishes
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.members AS m
        WHERE m.id = wishes.member_id
          AND m.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY wishes_insert_own
ON public.wishes
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.members AS m
        WHERE m.id = wishes.member_id
          AND m.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY wishes_update_own
ON public.wishes
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.members AS m
        WHERE m.id = wishes.member_id
          AND m.user_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.members AS m
        WHERE m.id = wishes.member_id
          AND m.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY wishes_delete_own
ON public.wishes
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.members AS m
        WHERE m.id = wishes.member_id
          AND m.user_id = (SELECT auth.uid())
    )
);

-- ATTRIBUTIONS : lire uniquement ses cadeaux à offrir.

CREATE POLICY gift_assignments_select_own
ON public.gift_assignments
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.members AS me
        WHERE me.id = gift_assignments.giver_id
          AND me.group_id = gift_assignments.group_id
          AND me.user_id = (SELECT auth.uid())
    )
);

-- Fichier : permissions.sql
-- Autorisations de la fonction de recherche par code.
-- À appliquer après la création de la fonction.

REVOKE ALL
ON FUNCTION public.find_group_by_invite_code(text)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.find_group_by_invite_code(text)
TO authenticated, postgres, service_role;

-- Autorisations de la liste des conjoints disponibles.

REVOKE ALL
ON FUNCTION public.list_group_partner_options(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.list_group_partner_options(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de l'enregistrement du couple.

REVOKE ALL
ON FUNCTION public.choose_partner(uuid, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.choose_partner(uuid, uuid)
TO authenticated, postgres, service_role;

-- Autorisations du retrait du lien entre conjoints.

REVOKE ALL
ON FUNCTION public.remove_partner(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.remove_partner(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la validation finale de l'inscription.

REVOKE ALL
ON FUNCTION public.complete_my_registration(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.complete_my_registration(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la lecture de sa propre inscription.

REVOKE ALL
ON FUNCTION public.get_my_registration(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_my_registration(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la consultation du statut du tirage.

REVOKE ALL
ON FUNCTION public.get_group_draw_status(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_draw_status(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la lecture de ses destinataires et de leurs idées.

REVOKE ALL
ON FUNCTION public.get_my_gift_recipients(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_my_gift_recipients(uuid)
TO authenticated, postgres, service_role;

-- Autorisations de la confirmation de découverte des destinataires.

REVOKE ALL
ON FUNCTION public.confirm_gift_reveal(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.confirm_gift_reveal(uuid)
TO authenticated, postgres, service_role;

-- Autorisations du tableau de suivi des inscriptions.

REVOKE ALL
ON FUNCTION public.get_group_registration_status(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_registration_status(uuid)
TO authenticated, postgres, service_role;

-- Autorisations du suivi détaillé des inscriptions.

REVOKE ALL
ON FUNCTION public.get_group_registration_progress(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.get_group_registration_progress(uuid)
TO authenticated, postgres, service_role;

-- Fonction interne de vérification avant le tirage.

REVOKE ALL
ON FUNCTION public.check_group_before_draw(uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.check_group_before_draw(uuid)
TO postgres, service_role;

-- Fonction interne de calcul de la répartition des cadeaux.

REVOKE ALL
ON FUNCTION public.compute_gift_draw(uuid[], uuid[])
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.compute_gift_draw(uuid[], uuid[])
TO postgres, service_role;


-- Autorisations du lancement du tirage.
-- La fonction vérifie que l'appelant est l'organisateur.

REVOKE ALL
ON FUNCTION public.draw_group(uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.draw_group(uuid)
TO authenticated, postgres, service_role;

-- Fonction appelée par le déclencheur de protection des inscriptions.

REVOKE ALL
ON FUNCTION public.guard_members_after_draw()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.guard_members_after_draw()
TO postgres, service_role;

-- Fonction appelée par le déclencheur de contrôle des inscriptions validées.

REVOKE ALL
ON FUNCTION public.require_completed_registrations()
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.require_completed_registrations()
TO postgres, service_role;

-- Fichier : table_permissions.sql
-- Copie des autorisations actuelles sur les tables.
-- À appliquer après tables.sql.

-- Retirer les droits éventuellement accordés par défaut.
REVOKE ALL PRIVILEGES
ON TABLE
    public.groups,
    public.members,
    public.wishes,
    public.gift_assignments
FROM PUBLIC, anon, authenticated;

-- Groupes : lecture seule, filtrée par les politiques RLS.
-- Le parcours utilise les fonctions SQL dédiées.
GRANT SELECT
ON TABLE public.groups
TO anon, authenticated;

-- Participants et idées cadeaux.
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.members, public.wishes
TO authenticated;

-- Attributions : lecture uniquement depuis le client.
GRANT SELECT
ON TABLE public.gift_assignments
TO authenticated;

-- Administration.
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE
ON TABLE
    public.groups,
    public.members,
    public.wishes,
    public.gift_assignments
TO postgres, service_role;

-- Fichier : triggers.sql
-- À appliquer après la création des tables et des fonctions.

-- Vérifier que toutes les inscriptions sont validées
-- avant d'enregistrer la date du tirage.
CREATE TRIGGER groups_require_completed_registrations
BEFORE UPDATE OF drawn_at ON public.groups
FOR EACH ROW
WHEN (
    OLD.drawn_at IS NULL
    AND NEW.drawn_at IS NOT NULL
)
EXECUTE FUNCTION public.require_completed_registrations();

-- Protéger les inscriptions et les couples après le tirage.
CREATE TRIGGER members_guard_after_draw
AFTER INSERT OR DELETE OR UPDATE ON public.members
FOR EACH ROW
EXECUTE FUNCTION public.guard_members_after_draw();

COMMIT;
