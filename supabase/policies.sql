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