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
