# Tests manuels — Noël en famille

Tests réalisés le 26 octobre 2026 sur la version de développement et le site GitHub Pages.

| Vérification | Résultat observé | État |
|---|---|---|
| Associer un email au compte existant de Cédric | Email confirmé, inscription et résultats conservés | Validé |
| Se connecter par email depuis GitHub Pages | Récapitulatif de Cédric retrouvé | Validé |
| Recharger la page dans Chrome | Session conservée, accès au groupe sans nouveau code email | Validé |
| Associer un email distinct au compte de Florence | Son inscription est conservée | Validé |
| Se connecter avec l’email de Florence | Son propre récapitulatif est retrouvé | Validé |
| Recharger la page dans le navigateur de Florence | Sa session est conservée | Validé |
| Saisir un code de connexion incorrect | Message de refus affiché, écran de connexion conservé | Validé |
| Corriger la saisie avec un code valide | Connexion réussie et récapitulatif retrouvé | Validé |
| Tenter une nouvelle inscription après le tirage | Inscription refusée avec un message visible | Validé |
| Contrôler le tirage du groupe Famille | 4 participants, chacun offre et reçoit 2 cadeaux, aucune attribution à soi-même ou au conjoint | Validé |

## Limites

Ces tests décrivent les scénarios effectivement vérifiés. Ils ne constituent pas un audit complet de sécurité.

L’installation sur une base vierge, les autres configurations de participants et les accès non autorisés restent à tester.

## Installation sur un projet Supabase vierge

Vérification réalisée le 26 octobre 2026
dans le projet séparé `noel-en-famille-test`.

| Vérification | Résultat | État |
|---|---|---|
| Exécution du script d’installation complet | Exécution réussie | Validé |
| Création des quatre tables | Tables présentes | Validé |
| Activation de la RLS | Active sur les quatre tables | Validé |
| Politiques RLS | 9 politiques présentes, réparties comme prévu | Validé |
| Fonctions SQL | 16 fonctions présentes | Validé |
| Déclencheurs | 2 déclencheurs présents | Validé |
| Exécution des fonctions sans connexion | Aucun accès pour le rôle anon | Validé |
| Accès direct aux quatre fonctions internes | Refusé au rôle authenticated | Validé |
| Accès aux autres fonctions | Autorisé au rôle authenticated | Validé |

Ces contrôles valident l’installation de la structure et les
autorisations d’exécution des fonctions. Le fonctionnement complet
de l’application sur ce nouveau projet reste à tester.

## Parcours sur la base reconstruite

Tests réalisés le 26 octobre 2026 dans `noel-en-famille-test`,
avec Alice Test, Bob Test, Claire Test et David Test.

| Vérification | Résultat | État |
|---|---|---|
| Inscription avec deux idées et sans conjoint | Récapitulatif et validation enregistrés | Validé |
| Association de Bob à Alice | Lien enregistré dans les deux sens | Validé |
| Trois inscrits dont un couple | Lancement désactivé avec une explication | Validé |
| Ajout d’un quatrième participant | Lancement du tirage disponible | Validé |
| Lancement par Alice, organisatrice | Tirage enregistré et destinataires affichés après la roue | Validé |
| Découverte par Bob | Destinataires et idées affichés | Validé |
| Interface de Bob | Tableau organisateur et bouton de lancement absents | Validé |
| Rechargement après la découverte de Bob | Destinataires retrouvés directement | Validé |
| Contrôle SQL du tirage | 4 participants, contrôles : 0 / 0 / 0 | Validé |

Le parcours principal a été testé sur la base reconstruite.
Ces résultats ne constituent pas un audit complet de sécurité
et ne couvrent pas toutes les configurations de participants.