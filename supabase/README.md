# Configuration Supabase — Noël en famille

Ce dossier conserve la structure SQL de l’application.

Les scripts ont été récupérés depuis la base de développement. Leur installation complète sur un projet vierge reste à tester.

## Contenu

- `tables.sql` : tables, contraintes, index et activation de la RLS.
- `functions/` : fonctions de gestion des inscriptions, des couples et du tirage.
- `policies.sql` : politiques RLS.
- `permissions.sql` : autorisations d’exécution des fonctions.
- `table_permissions.sql` : autorisations sur les tables.
- `triggers.sql` : déclencheurs de protection.
- `checks/` : requêtes de vérification.

## Ordre de préparation d’une nouvelle base

Utiliser un projet Supabase de test vierge. Ces scripts ne sont pas des migrations à relancer sur la base existante.

Préparer un seul script d’installation entouré de `BEGIN;` et `COMMIT;`, avec les fichiers dans cet ordre :

1. `tables.sql`
2. Les fonctions, dans l’ordre indiqué ci-dessous
3. `policies.sql`
4. `permissions.sql`
5. `table_permissions.sql`
6. `triggers.sql`

La transaction permet d’appliquer l’ensemble, y compris les restrictions d’accès, avant de rendre les changements disponibles.

### Ordre des fonctions

1. `find_group_by_invite_code.sql`
2. `register_member_by_invite_code.sql`
3. `list_group_partner_options.sql`
4. `choose_partner.sql`
5. `remove_partner.sql`
6. `complete_my_registration.sql`
7. `get_my_registration.sql`
8. `get_group_draw_status.sql`
9. `get_my_gift_recipients.sql`
10. `confirm_gift_reveal.sql`
11. `get_group_registration_status.sql`
12. `get_group_registration_progress.sql`
13. `check_group_before_draw.sql`
14. `compute_gift_draw.sql`
15. `draw_group.sql`
16. `guard_members_after_draw.sql`
17. `require_completed_registrations.sql`

## Configuration complémentaire

Les scripts SQL ne configurent pas :

- l’authentification anonyme ;
- l’association d’un email au compte ;
- le serveur SMTP ;
- les modèles d’emails de confirmation et de connexion ;
- les URL de l’application ;
- la création des groupes et la désignation de leur organisateur.

Ces réglages doivent être documentés et vérifiés séparément.

Les mots de passe SMTP ne doivent jamais être placés dans ce dépôt.

## Vérification du tirage

Le fichier `checks/check_draw_results.sql` contrôle les tirages enregistrés sans révéler les destinataires.

Pour chaque groupe tiré, les trois colonnes de contrôle doivent valoir `0` :

- aucun participant n’offre un nombre de cadeaux différent de deux ;
- aucun participant ne reçoit un nombre de cadeaux différent de deux ;
- aucune attribution ne concerne soi-même ou son conjoint.

Ce contrôle vérifie les résultats présents dans la base. Il ne remplace pas les tests des autres situations possibles.