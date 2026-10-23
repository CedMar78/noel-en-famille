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
