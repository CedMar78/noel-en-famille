# 🎄 Noël en famille

Application web de Secret Santa permettant d’organiser des échanges de cadeaux en famille, avec des idées cadeaux et une découverte animée des destinataires.

Projet personnel développé progressivement dans le cadre de mon apprentissage et présenté dans mon portfolio BTS.

## 🎡 Démonstration

[Découvrir l’application](https://cedmar78.github.io/noel-en-famille/)

Depuis l’accueil, le bouton **« Découvrir la démo »** permet de tester l’animation et l’affichage des cadeaux avec des personnages fictifs, sans inscription.

Les résultats de cette démonstration sont prédéfinis et ne déclenchent aucun véritable tirage.

## 🎁 Règles du jeu

- Chaque participant offre un cadeau à deux personnes distinctes.
- Chaque participant reçoit un cadeau de deux personnes différentes.
- Personne ne peut être son propre destinataire.
- Les conjoints ne peuvent pas être destinataires l’un de l’autre.
- Chaque participant renseigne deux à trois idées cadeaux.

## ✨ Fonctionnalités

- Accès à un groupe avec un code d’invitation.
- Enregistrement du prénom et des idées cadeaux.
- Sélection du conjoint parmi les participants du même groupe.
- Gestion réciproque des liens entre conjoints.
- Validation des inscriptions.
- Suivi des inscriptions pour l’organisateur.
- Tirage commun respectant les règles de répartition.
- Découverte individuelle des deux destinataires avec une roue animée.
- Affichage des idées cadeaux des destinataires.
- Effets visuels et clochettes de Noël désactivables.
- Interface adaptée aux petits écrans.
- Gestion de plusieurs groupes.
## 🛠️ Technologies
- **HTML** : structure des pages.
- **CSS** : mise en forme, animations et adaptation aux écrans.
- **JavaScript** : interactions et communication avec Supabase.
- **Supabase** : base de données PostgreSQL, authentification anonyme, politiques d’accès RLS et fonctions SQL appelées par RPC.
- **GitHub Pages** : hébergement du site.
## 🧠 Apprentissages
Ce projet me permet de travailler :
- la manipulation du DOM et les événements JavaScript ;
- les appels asynchrones avec `async` et `await` ;
- la modélisation d’une base de données relationnelle ;
- les relations et contraintes entre les données ;
- les autorisations d’accès aux données ;
- la traduction de règles métier en contrôles applicatifs ;
- les animations et les interactions audio ;
- la publication d’une application web.
Le développement est réalisé étape par étape avec une assistance pédagogique par IA, puis intégré et vérifié manuellement.
## 📌 État du projet
Le projet est en cours d’amélioration.

L’application utilise actuellement une authentification anonyme : retrouver son inscription dépend de la conservation de la session dans le navigateur utilisé. La récupération d’accès par email reste à mettre en place.

Le fonctionnement complet nécessite la configuration Supabase associée, avec ses tables, ses politiques d’accès et ses fonctions SQL. Ces éléments ne sont pas encore fournis sous forme de scripts d’installation dans ce dépôt.
