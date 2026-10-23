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