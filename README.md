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

Le parcours principal est fonctionnel et le projet continue d’être amélioré.

L’inscription commence avec une session anonyme. Chaque participant peut ensuite associer et confirmer son adresse email pour retrouver ses inscriptions depuis un autre navigateur ou appareil, grâce à un code de connexion reçu par email.

Sans adresse email confirmée, retrouver son inscription dépend de la conservation de la session initiale.

## 🗄️ Installation et base de données

Le dossier [supabase](supabase/README.md) contient les tables, les fonctions SQL, les politiques RLS, les permissions et les déclencheurs, ainsi que leur ordre d’installation.

Une première installation et le parcours principal ont été vérifiés sur un projet Supabase vierge. Le script a ensuite été actualisé avec une dix-septième fonction et des restrictions d’accès supplémentaires ; cette version complète reste à réinstaller sur une base vierge.

La configuration de l’authentification, des emails et des groupes nécessite des réglages complémentaires décrits dans le guide.

## 🧪 Vérifications

Les scénarios réalisés et leurs résultats sont consignés dans [les tests manuels](docs/tests-manuels.md).

Ils couvrent notamment la connexion par email, les couples, le tirage et plusieurs contrôles d’accès côté serveur.

Ces vérifications ne constituent pas un audit exhaustif de sécurité.
