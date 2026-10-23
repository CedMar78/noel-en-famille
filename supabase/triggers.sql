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