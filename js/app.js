console.log("JS chargé");

const joinButton = document.getElementById("joinButton");
const backButton = document.getElementById("backButton");
const continueButton = document.getElementById("continueButton");

const familyCodeInput = document.getElementById("familyCode");
const codeError = document.getElementById("codeError");

const heroSection = document.querySelector(".hero");
const joinSection = document.querySelector(".join");

const registerSection = document.querySelector(".register");

const registerButton = document.getElementById("registerButton");
const firstNameInput = document.getElementById("firstName");

const wishesSection = document.querySelector(".wishes");

const wishesTitle = document.getElementById("wishesTitle");

const saveWishesButton = document.getElementById("saveWishesButton");

const wish1Input = document.getElementById("wish1");
const wish2Input = document.getElementById("wish2");
const wish3Input = document.getElementById("wish3");

const partnerSection = document.querySelector(".partner");

const partnerYesButton = document.getElementById("partnerYesButton");
const partnerNoButton = document.getElementById("partnerNoButton");

const partnerSelection = document.getElementById("partnerSelection");
const partnerSelect = document.getElementById("partnerSelect");

const savePartnerButton = document.getElementById("savePartnerButton");

const summarySection = document.querySelector(".summary");

const summaryName = document.getElementById("summaryName");
const summaryWishes = document.getElementById("summaryWishes");
const summaryPartner = document.getElementById("summaryPartner");
const wishesError = document.getElementById("wishesError");

const organizerPanel = document.getElementById("organizerPanel");
const drawGroupButton = document.getElementById("drawGroupButton");
const drawStatus = document.getElementById("drawStatus");
const drawResults = document.getElementById("drawResults");
const giftResultsStatus = document.getElementById("giftResultsStatus");
const giftRecipients = document.getElementById("giftRecipients");
const summaryGroup = document.getElementById("summaryGroup");

const revealPanel = document.getElementById("revealPanel");
const revealWheel = document.getElementById("revealWheel");
const revealButton = document.getElementById("revealButton");
const revealStatus = document.getElementById("revealStatus");
const demoButton = document.getElementById("demoButton");
const demoSection = document.getElementById("demoSection");
const demoTitle = document.getElementById("demoTitle");
const demoBackButton = document.getElementById("demoBackButton");
const demoWheel = document.getElementById("demoWheel");
const demoRevealButton = document.getElementById("demoRevealButton");
const demoStatus = document.getElementById("demoStatus");
const demoResults = document.getElementById("demoResults");
const organizerDashboard =
    document.getElementById("organizerDashboard");

const registrationOverview =
    document.getElementById("registrationOverview");

const registrationList =
    document.getElementById("registrationList");
const refreshDrawStatusButton =
    document.getElementById("refreshDrawStatusButton");

const christmasSoundEnabled =
    document.getElementById("christmasSoundEnabled");

const previewChristmasSound =
    document.getElementById("previewChristmasSound");

let christmasAudioContext = null;
const participant = {
    groupId: null,
    groupName: "",
    memberId: null,
    firstName: "",
    wishes: [],
       hasPartner: null,
    partnerId: null,
       partnerName: "",
    registrationCompletedAt: null
};



console.log(joinButton);
console.log(backButton);
console.log(continueButton);
console.log(familyCodeInput);
console.log(codeError);


joinButton.addEventListener("click", function () {

    heroSection.classList.add("hidden");
    joinSection.classList.remove("hidden");

});


backButton.addEventListener("click", function () {

    joinSection.classList.add("hidden");
    heroSection.classList.remove("hidden");

});

async function restoreExistingRegistration() {

    const { data: registration, error: registrationError } =
        await supabaseClient
            .rpc("get_my_registration", {
                p_group_id: participant.groupId
            })
            .maybeSingle();

    if (registrationError) {
        throw registrationError;
    }

    if (!registration) {
        return false;
    }

    const { data: status, error: statusError } =
        await supabaseClient
            .rpc("get_group_draw_status", {
                p_group_id: participant.groupId
            })
            .single();

    if (statusError) {
        throw statusError;
    }

        const { data: completion, error: completionError } =
        await supabaseClient
            .from("members")
            .select("registration_completed_at")
            .eq("id", registration.member_id)
            .eq("group_id", participant.groupId)
            .single();

    if (completionError) {
        throw completionError;
    }

    participant.registrationCompletedAt =
        completion.registration_completed_at;

    participant.memberId = registration.member_id;
    participant.firstName = registration.first_name;
    participant.wishes = registration.wishes;
    participant.hasPartner = registration.has_partner;
    participant.partnerId = registration.partner_id;
    participant.partnerName = registration.partner_name || "";

    firstNameInput.value = participant.firstName;

    wish1Input.value = participant.wishes[0] || "";
    wish2Input.value = participant.wishes[1] || "";
    wish3Input.value = participant.wishes[2] || "";

    wishesTitle.textContent =
        `Les idées cadeaux de ${participant.firstName} 🎁`;

    joinSection.classList.add("hidden");

    if (status.drawn_at || participant.registrationCompletedAt) {

        showSummary();
        return true;

    }

    if (participant.wishes.length < 2 ||
        participant.wishes.length > 3) {

        wishesSection.classList.remove("hidden");
        return true;

    }

    partnerSection.classList.remove("hidden");
    partnerSelection.classList.add("hidden");

    if (participant.hasPartner) {

        partnerSelection.classList.remove("hidden");
        await loadPartnerOptions();

    }

    return true;

}


continueButton.addEventListener("click", async function () {

    const familyCode = familyCodeInput.value.trim();

    if (familyCode === "") {
        codeError.textContent = "Entre un code d'invitation.";
        codeError.classList.remove("hidden");
        return;
    }

    continueButton.disabled = true;
    continueButton.textContent = "Vérification...";

    const { data, error } = await supabaseClient.rpc(
        "find_group_by_invite_code",
        {
            code: familyCode
        }
    );

    continueButton.disabled = false;
    continueButton.textContent = "Continuer";

    if (error) {
        console.error("Erreur lors de la vérification :", error);

        codeError.textContent =
            "Impossible de vérifier le code pour le moment.";

        codeError.classList.remove("hidden");

        return;
    }

    if (!data || data.length === 0) {

        codeError.textContent = "Code d'invitation incorrect.";
        codeError.classList.remove("hidden");

        return;
    }

    const group = data[0];

    participant.groupId = group.id;
    participant.groupName = group.name;

    console.log("Groupe trouvé :", group);

    continueButton.disabled = true;
    continueButton.textContent = "Recherche de ton inscription…";

    try {

        codeError.classList.add("hidden");

        const restored = await restoreExistingRegistration();

        if (restored) {
            return;
        }

        joinSection.classList.add("hidden");
        registerSection.classList.remove("hidden");

    } catch (error) {

        console.error("Erreur récupération de l’inscription :", error);

        codeError.textContent =
            "Impossible de retrouver ton inscription. Réessaie.";

        codeError.classList.remove("hidden");

    } finally {

        continueButton.disabled = false;
        continueButton.textContent = "Continuer";

    }

});


registerButton.addEventListener("click", async function () {

    const firstName = firstNameInput.value.trim();

    if (firstName === "") {
        return;
    }

    const {
        data: { user },
        error: userError
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
        console.error(
            "Impossible de récupérer l'utilisateur :",
            userError
        );

        return;
    }

    const { data, error } = await supabaseClient
        .from("members")
        .upsert(
            {
                user_id: user.id,
                group_id: participant.groupId,
                first_name: firstName
            },
            {
                onConflict: "user_id,group_id"
            }
        )
                .select("id, has_partner, partner_id")
        .single();

if (error) {
    console.error("Erreur création du membre :", error);

    const registerError =
        document.getElementById("registerError");

    const drawIsLocked =
        error.code === "P0001" &&
        error.message?.includes(
            "les inscriptions et les couples sont verrouillés"
        );

    registerError.textContent = drawIsLocked
        ? "Les inscriptions sont fermées : le tirage a déjà eu lieu. " +
          "Si tu es déjà inscrit, retrouve ton inscription depuis " +
          "le navigateur et l’adresse du site utilisés au départ."
        : "Impossible d’enregistrer ton inscription. Réessaie dans un instant.";

    registerError.classList.remove("hidden");

    return;
}

    participant.firstName = firstName;
    participant.memberId = data.id;
    participant.hasPartner = data.has_partner;
    participant.partnerId = data.partner_id;
    participant.partnerName = "";

    console.log(
        "Membre enregistré :",
        participant
    );

    wishesTitle.textContent =
        `Les idées cadeaux de ${firstName} 🎁`;

    registerSection.classList.add("hidden");
    wishesSection.classList.remove("hidden");

});

saveWishesButton.addEventListener("click", async function () {

    const wish1 = wish1Input.value.trim();
    const wish2 = wish2Input.value.trim();
    const wish3 = wish3Input.value.trim();

    const wishes = [wish1, wish2, wish3].filter(function (wish) {
        return wish !== "";
    });

    if (wishes.length < 2) {
        wishesError.classList.remove("hidden");
        return;
    }

    wishesError.classList.add("hidden");

    if (!participant.memberId) {
        console.error("Aucun memberId disponible.");
        return;
    }

    saveWishesButton.disabled = true;
    saveWishesButton.textContent = "Enregistrement...";

    // On supprime d'abord les anciens souhaits de ce membre.
    // Très pratique pendant nos tests et si l'utilisateur modifie sa liste.
    const { error: deleteError } = await supabaseClient
        .from("wishes")
        .delete()
        .eq("member_id", participant.memberId);

    if (deleteError) {

        console.error(
            "Erreur suppression des anciens souhaits :",
            deleteError
        );

        saveWishesButton.disabled = false;
        saveWishesButton.textContent = "Enregistrer mes idées";

        return;
    }

    const wishesToInsert = wishes.map(function (wish) {

        return {
            member_id: participant.memberId,
            label: wish
        };

    });

    const { data, error } = await supabaseClient
        .from("wishes")
        .insert(wishesToInsert)
        .select("id, label");

    saveWishesButton.disabled = false;
    saveWishesButton.textContent = "Enregistrer mes idées";

    if (error) {

        console.error(
            "Erreur enregistrement des souhaits :",
            error
        );

        return;
    }

    participant.wishes = wishes;

    console.log(
        "Souhaits enregistrés :",
        data
    );

    wishesSection.classList.add("hidden");
    partnerSection.classList.remove("hidden");
    if (participant.hasPartner) {

        partnerSelection.classList.remove("hidden");
        await loadPartnerOptions();

    } else {

        partnerSelection.classList.add("hidden");

    }
});

async function loadMyGiftRecipients() {

    drawResults.classList.remove("hidden");
    giftRecipients.replaceChildren();
    giftResultsStatus.textContent = "Chargement de tes destinataires…";

    try {

        const { data, error } = await supabaseClient.rpc(
            "get_my_gift_recipients",
            {
                p_group_id: participant.groupId
            }
        );

        if (error) {
            throw error;
        }

        if (!data || data.length !== 2) {
            throw new Error("Deux destinataires étaient attendus.");
        }

        data.forEach(function (recipient) {

            const card = document.createElement("article");
            const name = document.createElement("h4");
            const wishesList = document.createElement("ul");

            name.textContent = recipient.first_name;

            recipient.wishes.forEach(function (wish) {

                const item = document.createElement("li");
                item.textContent = wish;
                wishesList.appendChild(item);

            });

            card.append(name, wishesList);
            giftRecipients.appendChild(card);

        });

        giftResultsStatus.textContent =
            "Voici les deux personnes à qui tu offres un cadeau.";
                    return true;

    } catch (error) {

        console.error("Erreur lecture des destinataires :", error);

        giftResultsStatus.textContent =
            "Impossible de charger tes destinataires. Recharge la page pour réessayer.";
                    return false;

    }

}

async function loadOrganizerDashboard() {

    registrationList.replaceChildren();
    registrationOverview.textContent = "Chargement des inscriptions…";

    try {

        const { data, error } = await supabaseClient.rpc(
            "get_group_registration_progress",
            {
                p_group_id: participant.groupId
            }
        );

        if (error) {
            throw error;
        }

        let readyCount = 0;

        data.forEach(function (member) {

            const ready =
                member.wishes_count >= 2 &&
                member.wishes_count <= 3 &&
                member.couple_valid &&
                Boolean(member.registration_completed_at);

            if (ready) {
                readyCount++;
            }

            const item = document.createElement("li");

            const coupleText = member.couple_valid
                ? "choix couple complet"
                : "choix couple à vérifier";

            const validationText = member.registration_completed_at
                ? "inscription validée"
                : "confirmation finale attendue";

            item.textContent =
                `${member.first_name} — ` +
                `${member.wishes_count} idées · ` +
                `${coupleText} · ${validationText} · ` +
                (ready ? "Prêt ✅" : "À compléter ⏳");

            registrationList.appendChild(item);

        });

        const count = data.length;

        registrationOverview.textContent =
            `${count} participant${count === 1 ? "" : "s"} ` +
            `inscrit${count === 1 ? "" : "s"} · ` +
            `${readyCount} inscription${readyCount === 1 ? "" : "s"} ` +
            `complète${readyCount === 1 ? "" : "s"}`;

        const enoughRecipients = data.every(function (member) {
            return member.eligible_recipient_count >= 2;
        });

        let message;
        let canAttemptDraw = false;

        if (count < 3) {

            message = "Il faut au moins trois participants pour un tirage.";

        } else if (readyCount !== count) {

            message = "Des inscriptions restent à compléter ou à confirmer.";

        } else if (!enoughRecipients) {

            message =
                "Au moins une personne a moins de deux destinataires autorisés. " +
                "D’autres inscriptions sont nécessaires.";

        } else {

            canAttemptDraw = true;
            message = "Les contrôles préalables sont complets. Tu peux lancer le tirage.";

        }

        return { canAttemptDraw, message };

    } catch (error) {

        console.error("Erreur lecture des inscriptions :", error);

        registrationOverview.textContent =
            "Impossible de charger les inscriptions. Actualise pour réessayer.";

        return null;

    }

}

async function loadDrawStatus() {

        organizerDashboard.classList.add("hidden");

        revealPanel.classList.add("hidden");
                    revealButton.disabled = false;
            revealStatus.textContent = "";

        drawResults.classList.add("hidden");
    organizerPanel.classList.add("hidden");
    drawGroupButton.disabled = true;
    drawStatus.textContent = "Vérification du tirage…";

    try {

        const { data, error } = await supabaseClient
            .rpc("get_group_draw_status", {
                p_group_id: participant.groupId
            })
            .single();

        if (error) {
            throw error;
        }

        let registrationProgress = null;

        if (data.is_organizer) {

            organizerDashboard.classList.remove("hidden");

            registrationProgress = await loadOrganizerDashboard();

        }
         if (data.drawn_at) {

            const { data: member, error: memberError } =
                await supabaseClient
                    .from("members")
                    .select("gifts_revealed_at")
                    .eq("id", participant.memberId)
                    .eq("group_id", participant.groupId)
                    .single();

            if (memberError) {
                throw memberError;
            }

            if (member.gifts_revealed_at) {

                drawStatus.textContent =
                    "Retrouve les deux personnes que tu vas gâter 🎁";

                await loadMyGiftRecipients();

            } else {

                drawStatus.textContent =
                    "Le tirage est prêt : à toi de découvrir tes deux personnes !";

                revealPanel.classList.remove("hidden");

                revealButton.disabled = false;
                revealStatus.textContent = "";

            }

            return;

        }



        if (data.is_organizer) {

            organizerPanel.classList.remove("hidden");

            drawGroupButton.disabled =
                !registrationProgress?.canAttemptDraw;

            drawStatus.textContent = registrationProgress
                ? registrationProgress.message
                : "Impossible de vérifier les inscriptions. Actualise pour réessayer.";

        } else {

            drawStatus.textContent =
                "En attente du tirage par l’organisateur.";

        }

    } catch (error) {

        console.error("Erreur lecture du statut du tirage :", error);

        drawStatus.textContent =
            "Impossible de vérifier le statut du tirage.";

    }

}

function showSummary() {

    refreshAccountEmailPanel();

    partnerSection.classList.add("hidden");
    summarySection.classList.remove("hidden");

    summaryName.textContent = participant.firstName;
        summaryGroup.textContent = participant.groupName;

    if (participant.hasPartner) {

        summaryPartner.textContent = participant.partnerName
            ? `Oui — ${participant.partnerName}`
            : "Oui";

    } else {

        summaryPartner.textContent = "Non";

    }

    summaryWishes.innerHTML = "";

    participant.wishes.forEach(function (wish) {

        const listItem = document.createElement("li");

        listItem.textContent = wish;

        summaryWishes.appendChild(listItem);

    });
    loadDrawStatus();
}

async function loadPartnerOptions() {

    partnerSelect.disabled = true;
    partnerSelect.replaceChildren(
        new Option("Chargement des participants...", "")
    );

    try {

        const { data, error } = await supabaseClient.rpc(
            "list_group_partner_options",
            {
                p_group_id: participant.groupId
            }
        );

        if (error) {
            throw error;
        }

        console.log("Participants pour la liste conjoint :", data);

        partnerSelect.replaceChildren(
            new Option(
                data.length > 0
                    ? "Choisis ton conjoint ou ta conjointe"
                    : "Aucun autre participant visible pour le moment",
                ""
            )
        );

        data.forEach(function (member) {

            const option = new Option(
                member.first_name,
                member.id
            );

            partnerSelect.add(option);

        });

                const savedPartner = data.find(function (member) {
            return member.id === participant.partnerId;
        });

        if (savedPartner) {

            partnerSelect.value = savedPartner.id;
            participant.partnerName = savedPartner.first_name;

        }

        partnerSelect.disabled = data.length === 0;

    } catch (error) {

        console.error(
            "Erreur chargement des participants :",
            error
        );

        partnerSelect.replaceChildren(
            new Option("Chargement impossible", "")
        );

        alert(
            "Impossible de charger la liste. Clique sur Oui pour réessayer."
        );

    }

}

async function completeRegistration() {

    const { data, error } = await supabaseClient.rpc(
        "complete_my_registration",
        {
            p_group_id: participant.groupId
        }
    );

    if (error) {
        throw error;
    }

    participant.registrationCompletedAt = data;

}

async function savePartnerChoice(hasPartner) {

    if (!participant.memberId || !participant.groupId) {
        alert("Ton inscription est introuvable. Recharge la page.");
        return;
    }

    if (!hasPartner) {

        const confirmed = window.confirm(
            "Confirmer que tu participes sans conjoint ?\n\n" +
            "Si un couple est enregistré, le lien sera retiré pour vous deux."
        );

        if (!confirmed) {
            return;
        }

    }

    partnerYesButton.disabled = true;
    partnerNoButton.disabled = true;
    savePartnerButton.disabled = true;

    try {

        if (hasPartner) {

            const { data, error } = await supabaseClient
                .from("members")
                .update({
                    has_partner: true
                })
                .eq("id", participant.memberId)
                .eq("group_id", participant.groupId)
                .select("id, has_partner, partner_id")
                .single();

            if (error) {
                throw error;
            }

            participant.hasPartner = data.has_partner;
            participant.partnerId = data.partner_id;
            participant.partnerName = "";

            partnerSelection.classList.remove("hidden");

            await loadPartnerOptions();

        } else {

            const { error } = await supabaseClient.rpc(
                "remove_partner",
                {
                    p_group_id: participant.groupId
                }
            );

            if (error) {
                throw error;
            }

            participant.hasPartner = false;
            participant.partnerId = null;
            participant.partnerName = "";

            partnerSelect.value = "";
            partnerSelection.classList.add("hidden");

            await completeRegistration();

            showSummary();

            

        }

        console.log("Choix conjoint enregistré :", {
            hasPartner: participant.hasPartner,
            partnerId: participant.partnerId
        });

    } catch (error) {

        console.error(
            "Erreur enregistrement du choix conjoint :",
            error
        );

        alert("Impossible d’enregistrer ton choix. Réessaie.");

    } finally {

        partnerYesButton.disabled = false;
        partnerNoButton.disabled = false;
        savePartnerButton.disabled = false;

    }

}

partnerYesButton.addEventListener("click", function () {

    savePartnerChoice(true);

});

partnerNoButton.addEventListener("click", function () {

    savePartnerChoice(false);

});

savePartnerButton.addEventListener("click", async function () {

    const partnerId = partnerSelect.value;

    if (!partnerId) {
        alert("Choisis ton conjoint ou ta conjointe dans la liste.");
        return;
    }

    savePartnerButton.disabled = true;
    partnerYesButton.disabled = true;
    partnerNoButton.disabled = true;
    partnerSelect.disabled = true;

    savePartnerButton.textContent = "Enregistrement...";

    try {

        const { error } = await supabaseClient.rpc(
            "choose_partner",
            {
                p_group_id: participant.groupId,
                p_partner_id: partnerId
            }
        );

        if (error) {
            throw error;
        }

        participant.hasPartner = true;
        participant.partnerId = partnerId;

                participant.partnerName =
            partnerSelect.selectedOptions[0].textContent;
        console.log("Couple enregistré :", {
            memberId: participant.memberId,
            partnerId: participant.partnerId
        });

        await completeRegistration();

        showSummary();

    } catch (error) {

        console.error("Erreur enregistrement du couple :", error);

        alert(
            "Impossible de confirmer le couple. " +
            "Vérifie que cette personne est toujours disponible."
        );

    } finally {

        savePartnerButton.disabled = false;
        partnerYesButton.disabled = false;
        partnerNoButton.disabled = false;
        partnerSelect.disabled = false;

        savePartnerButton.textContent = "Confirmer mon conjoint";

    }

});

drawGroupButton.addEventListener("click", async function () {

    const confirmed = window.confirm(
        "Lancer le tirage pour tout ce groupe ?\n\n" +
        "Vérifie que toutes les inscriptions sont terminées.\n" +
        "Après le tirage, les participants et les couples seront verrouillés."
    );

    if (!confirmed) {
        return;
    }

    drawGroupButton.disabled = true;
    drawGroupButton.textContent = "Tirage en cours…";
    drawStatus.textContent = "Calcul et enregistrement du tirage…";

    try {

        const { data, error } = await supabaseClient.rpc(
            "draw_group",
            {
                p_group_id: participant.groupId
            }
        );

        if (error) {
            throw error;
        }

        console.log("Tirage enregistré :", data, "cadeaux");

        await loadDrawStatus();

        drawStatus.textContent =
            `Le tirage est terminé : ${data} cadeaux attribués !`;

    } catch (error) {

        console.error("Erreur lancement du tirage :", error);

        alert(
            "Le lancement n’a pas pu être confirmé. " +
            "Le statut du groupe va être actualisé."
        );

        await loadDrawStatus();

    } finally {

        drawGroupButton.textContent = "Lancer le tirage";

    }

});

revealButton.addEventListener("click", async function () {

    if (revealButton.disabled) {
        return;
    }
    prepareChristmasAudio();
    revealButton.disabled = true;
    revealButton.textContent = "La surprise arrive…";
    revealStatus.textContent = "Tes deux personnes vont se dévoiler !";

    drawResults.classList.add("hidden");

    let animation = null;

    try {

        const reduceMotion = window.matchMedia(
            "(prefers-reduced-motion: reduce)"
        ).matches;

        if (!reduceMotion) {

            animation = revealWheel.animate(
                [
                    { transform: "rotate(0deg)" },
                    { transform: "rotate(1800deg)" }
                ],
                {
                    duration: 4000,
                    easing: "cubic-bezier(0.12, 0.75, 0.12, 1)",
                    fill: "forwards"
                }
            );

            await animation.finished;

        }

        revealStatus.textContent = "Ouverture de tes cadeaux…";

        const loaded = await loadMyGiftRecipients();

        if (!loaded) {

            revealStatus.textContent =
                "Le chargement a échoué. Tu peux réessayer.";

            return;

        }
        const { error: revealError } = await supabaseClient.rpc(
            "confirm_gift_reveal",
            {
                p_group_id: participant.groupId
            }
        );

        if (revealError) {

            console.error(
                "Erreur mémorisation de la découverte :",
                revealError
            );

            giftResultsStatus.textContent =
                "Tes destinataires sont affichés. " +
                "La découverte n’a pas pu être mémorisée : " +
                "la roue pourra réapparaître à ta prochaine visite.";

        }

        revealPanel.classList.add("hidden");

                        revealPanel.classList.add("hidden");

        playChristmasChime();
        launchChristmasSparkles();

        giftResultsStatus.tabIndex = -1;

        giftResultsStatus.tabIndex = -1;
        giftResultsStatus.focus();

    } catch (error) {

        console.error("Erreur pendant la révélation :", error);

        revealStatus.textContent =
            "La découverte a été interrompue. Réessaie.";

    } finally {

        if (animation) {
            animation.cancel();
        }

        revealButton.disabled = false;
        revealButton.textContent = "Tourner ma roue";

    }

});

async function prepareChristmasAudio() {

    if (!christmasSoundEnabled.checked) {
        return;
    }

    try {

        const AudioContextClass =
            window.AudioContext || window.webkitAudioContext;

        if (!AudioContextClass) {
            return;
        }

        if (!christmasAudioContext) {
            christmasAudioContext = new AudioContextClass();
        }

        await christmasAudioContext.resume();

    } catch (error) {

        console.warn("Le son n’a pas pu être activé :", error);

    }

}

function playChristmasChime() {

    if (!christmasSoundEnabled.checked ||
        christmasAudioContext?.state !== "running") {
        return;
    }

    try {

        const context = christmasAudioContext;
        const notes = [523.25, 659.25, 783.99, 1046.50, 783.99, 1046.50];
        const start = context.currentTime + 0.03;

        notes.forEach(function (frequency, index) {

            [1, 2.76].forEach(function (harmonic) {

                const bell = context.createOscillator();
                const volume = context.createGain();
                const when = start + index * 0.18;

                bell.type = "sine";
                bell.frequency.value = frequency * harmonic;

                volume.gain.setValueAtTime(0, when);
                volume.gain.linearRampToValueAtTime(
                    harmonic === 1 ? 0.06 : 0.015,
                    when + 0.01
                );
                volume.gain.exponentialRampToValueAtTime(
                    0.0001,
                    when + 0.8
                );

                bell.connect(volume);
                volume.connect(context.destination);

                bell.start(when);
                bell.stop(when + 0.85);

                bell.onended = function () {
                    bell.disconnect();
                    volume.disconnect();
                };

            });

        });

    } catch (error) {

        console.warn("Les clochettes n’ont pas pu être jouées :", error);

    }

}

previewChristmasSound.addEventListener("click", async function () {

    await prepareChristmasAudio();

    playChristmasChime();
    launchChristmasSparkles();

});

function launchChristmasSparkles() {

    if (window.matchMedia(
        "(prefers-reduced-motion: reduce)"
    ).matches) {
        return;
    }

    document.getElementById("christmasSparkles")?.remove();

    const layer = document.createElement("div");

    layer.id = "christmasSparkles";
    layer.className = "christmas-sparkles";
    layer.setAttribute("aria-hidden", "true");

    const symbols = ["✨", "❄️", "⭐"];

    for (let index = 0; index < 28; index++) {

        const sparkle = document.createElement("span");

        sparkle.textContent = symbols[index % symbols.length];

        sparkle.style.left = `${Math.random() * 100}%`;

        sparkle.style.setProperty(
            "--size", `${18 + Math.random() * 16}px`
        );

        sparkle.style.setProperty(
            "--drift", `${Math.random() * 160 - 80}px`
        );

        sparkle.style.setProperty(
            "--delay", `${Math.random() * 0.3}s`
        );

        sparkle.style.setProperty(
            "--duration", `${1.8 + Math.random()}s`
        );

        layer.appendChild(sparkle);

    }

    document.body.appendChild(layer);

    window.setTimeout(function () {
        layer.remove();
    }, 3500);

}

refreshDrawStatusButton.addEventListener("click", async function () {

    refreshDrawStatusButton.disabled = true;
    refreshDrawStatusButton.textContent = "Actualisation…";

    try {

        await loadDrawStatus();

    } finally {

        refreshDrawStatusButton.disabled = false;
        refreshDrawStatusButton.textContent = "↻ Actualiser le tirage";

    }

});

try {

    const savedSound = localStorage.getItem("noelChristmasSound");

    if (savedSound !== null) {
        christmasSoundEnabled.checked = savedSound === "on";
    }

} catch (error) {

    console.warn("Préférence sonore indisponible :", error);

}

christmasSoundEnabled.addEventListener("change", function () {

    try {

        localStorage.setItem(
            "noelChristmasSound",
            christmasSoundEnabled.checked ? "on" : "off"
        );

    } catch (error) {

        console.warn("Préférence sonore non enregistrée :", error);

    }

});

demoButton.addEventListener("click", function () {

    heroSection.classList.add("hidden");
    demoSection.classList.remove("hidden");
    demoResults.classList.add("hidden");
    demoStatus.textContent = "";
    demoRevealButton.disabled = false;
    demoRevealButton.textContent = "Découvrir mes deux personnes";
    demoTitle.focus();

});

demoBackButton.addEventListener("click", function () {

    demoSection.classList.add("hidden");
    heroSection.classList.remove("hidden");

    demoButton.focus();

});

demoRevealButton.addEventListener("click", async function () {

    if (demoRevealButton.disabled) {
        return;
    }

    demoRevealButton.disabled = true;
    demoBackButton.disabled = true;

    demoRevealButton.textContent = "La surprise arrive…";
    demoStatus.textContent = "Découverte de tes destinataires fictifs…";
    demoResults.classList.add("hidden");

    let animation = null;

    try {

        await prepareChristmasAudio();

        const reduceMotion = window.matchMedia(
            "(prefers-reduced-motion: reduce)"
        ).matches;

        if (!reduceMotion) {

            animation = demoWheel.animate(
                [
                    { transform: "rotate(0deg)" },
                    { transform: "rotate(1800deg)" }
                ],
                {
                    duration: 4000,
                    easing: "cubic-bezier(0.12, 0.75, 0.12, 1)",
                    fill: "forwards"
                }
            );

            await animation.finished;

        }

        demoResults.classList.remove("hidden");

        demoStatus.textContent =
            "Voici un exemple de découverte. Aucun véritable tirage n’a été effectué.";

        playChristmasChime();
        launchChristmasSparkles();

        demoResults.focus();

    } catch (error) {

        console.error("Erreur animation de démonstration :", error);

        demoStatus.textContent =
            "La démonstration a été interrompue. Tu peux réessayer.";

    } finally {

        if (animation) {
            animation.cancel();
        }

        demoRevealButton.disabled = false;
        demoBackButton.disabled = false;
        demoRevealButton.textContent = "Rejouer la démo 🎡";

    }

});

const accountEmailInput =
    document.getElementById("accountEmail");

const sendAccountCodeButton =
    document.getElementById("sendAccountCodeButton");

const accountCodePanel =
    document.getElementById("accountCodePanel");

const accountEmailStatus =
    document.getElementById("accountEmailStatus");

let pendingAccountEmail = "";
let pendingAccountUserId = null;

sendAccountCodeButton.disabled = false;

sendAccountCodeButton.addEventListener("click", async function () {
    if (!accountEmailInput.reportValidity()) {
        return;
    }

    const email = accountEmailInput.value.trim();

    if (!email) {
        accountEmailStatus.textContent = "Renseigne ton adresse email.";
        return;
    }

    sendAccountCodeButton.disabled = true;
    accountEmailStatus.textContent = "Envoi du code…";

    try {
        const { data: userData, error: userError } =
            await supabaseClient.auth.getUser();

        if (userError || !userData.user) {
            throw new Error("Ta session est introuvable. Recharge la page.");
        }

        if (!userData.user.is_anonymous) {
            accountEmailStatus.textContent =
                "Ton compte possède déjà un moyen de connexion.";
            return;
        }

        const { error } = await supabaseClient.auth.updateUser({
            email: email
        });

        if (error) {
            throw error;
        }

        pendingAccountEmail = email;
        pendingAccountUserId = userData.user.id;

        accountEmailInput.readOnly = true;
        accountCodePanel.classList.remove("hidden");

        accountEmailStatus.textContent =
            "Code envoyé ! Consulte ta boîte mail et les courriers indésirables.";

    } catch (error) {
        console.error("Erreur envoi du code email :", error);

        accountEmailStatus.textContent =
            "Impossible d’envoyer le code. Vérifie ton adresse et réessaie.";

    } finally {
        sendAccountCodeButton.disabled = false;
    }
});
const accountEmailCodeInput =
    document.getElementById("accountEmailCode");

const verifyAccountCodeButton =
    document.getElementById("verifyAccountCodeButton");

verifyAccountCodeButton.disabled = false;

verifyAccountCodeButton.addEventListener("click", async function () {
    const token = accountEmailCodeInput.value.trim();

    if (!pendingAccountEmail || !pendingAccountUserId) {
        accountEmailStatus.textContent =
            "Demande d’abord un code depuis cette page.";
        return;
    }

    if (!token) {
        accountEmailStatus.textContent = "Saisis le code reçu par email.";
        return;
    }

    verifyAccountCodeButton.disabled = true;
    sendAccountCodeButton.disabled = true;
    accountEmailStatus.textContent = "Vérification…";

    let confirmed = false;

    try {
        const { data: current, error: sessionError } =
            await supabaseClient.auth.getUser();

        if (
            sessionError ||
            current.user?.id !== pendingAccountUserId
        ) {
            throw new Error("La session a changé.");
        }

        const { error } = await supabaseClient.auth.verifyOtp({
            email: pendingAccountEmail,
            token: token,
            type: "email_change"
        });

        if (error) {
            throw error;
        }

        const { data: verified, error: verifiedError } =
            await supabaseClient.auth.getUser();

        if (
            verifiedError ||
            verified.user?.id !== pendingAccountUserId ||
            verified.user?.is_anonymous !== false ||
            verified.user?.email?.toLowerCase() !==
                pendingAccountEmail.toLowerCase()
        ) {
            throw new Error("La confirmation du compte reste à vérifier.");
        }

        confirmed = true;
        accountEmailCodeInput.value = "";
        accountCodePanel.classList.add("hidden");

        accountEmailStatus.textContent =
            "Adresse confirmée ! Ton compte et tes inscriptions sont conservés 🎄";

            await refreshAccountEmailPanel();

    } catch (error) {
        console.error("Erreur confirmation de l’email :", error);

        accountEmailStatus.textContent =
            "Confirmation impossible. Vérifie le dernier code reçu. " +
            "S’il a expiré, demande un nouveau code.";

    } finally {
        verifyAccountCodeButton.disabled = confirmed;
        sendAccountCodeButton.disabled = confirmed;
    }
});

const openLoginButton =
    document.getElementById("openLoginButton");

const loginSection =
    document.getElementById("loginSection");

const loginBackButton =
    document.getElementById("loginBackButton");

const loginEmailInput =
    document.getElementById("loginEmail");

openLoginButton.addEventListener("click", function () {
    heroSection.classList.add("hidden");
    loginSection.classList.remove("hidden");

    loginEmailInput.focus();
});

loginBackButton.addEventListener("click", function () {
    loginSection.classList.add("hidden");
    heroSection.classList.remove("hidden");

    openLoginButton.focus();
});

const sendLoginCodeButton =
    document.getElementById("sendLoginCodeButton");

const loginCodePanel =
    document.getElementById("loginCodePanel");

const loginStatus =
    document.getElementById("loginStatus");

let pendingLoginEmail = "";

sendLoginCodeButton.disabled = false;

sendLoginCodeButton.addEventListener("click", async function () {
    if (!loginEmailInput.reportValidity()) {
        return;
    }

    const email = loginEmailInput.value.trim();

    if (!email) {
        loginStatus.textContent = "Renseigne ton adresse email.";
        return;
    }

    sendLoginCodeButton.disabled = true;
    loginStatus.textContent = "Envoi du code…";

    try {
        const { error } = await supabaseClient.auth.signInWithOtp({
            email: email,
            options: {
                shouldCreateUser: false
            }
        });

        if (error) {
            throw error;
        }

        pendingLoginEmail = email;
        loginEmailInput.readOnly = true;

        loginCodePanel.classList.remove("hidden");

        loginStatus.textContent =
            "Si cette adresse correspond à un compte, " +
            "un code de connexion a été envoyé. " +
            "Consulte aussi les courriers indésirables.";

        setTimeout(function () {
            sendLoginCodeButton.disabled = false;
        }, 60000);

    } catch (error) {
        console.error("Erreur envoi du code de connexion :", error);

        loginStatus.textContent =
            "Envoi impossible. Vérifie ton adresse ou attends " +
            "un instant avant de réessayer.";

        sendLoginCodeButton.disabled = false;
    }
});

const loginCodeInput =
    document.getElementById("loginCode");

const verifyLoginCodeButton =
    document.getElementById("verifyLoginCodeButton");

verifyLoginCodeButton.disabled = false;

verifyLoginCodeButton.addEventListener("click", async function () {
    const token = loginCodeInput.value.trim();

    if (!pendingLoginEmail || !token) {
        loginStatus.textContent =
            "Demande un code, puis saisis le dernier code reçu.";
        return;
    }

    verifyLoginCodeButton.disabled = true;
    sendLoginCodeButton.disabled = true;
    loginBackButton.disabled = true;

    loginStatus.textContent = "Connexion…";

    let connected = false;

    try {
        const { data, error } =
            await supabaseClient.auth.verifyOtp({
                email: pendingLoginEmail,
                token: token,
                type: "email"
            });

        if (error) {
            throw error;
        }

        if (
            !data.session ||
            !data.user ||
            data.user.is_anonymous !== false ||
            data.user.email?.toLowerCase() !==
                pendingLoginEmail.toLowerCase()
        ) {
            throw new Error("La connexion reste à vérifier.");
        }

        Object.assign(participant, {
            groupId: null,
            groupName: "",
            memberId: null,
            firstName: "",
            wishes: [],
            hasPartner: null,
            partnerId: null,
            partnerName: "",
            registrationCompletedAt: null
        });

        connected = true;
        pendingLoginEmail = "";
        loginCodeInput.value = "";

        loginSection.classList.add("hidden");
        joinSection.classList.remove("hidden");

        document.getElementById("codeError")
            .classList.add("hidden");

        document.getElementById("familyCode").focus();

    } catch (error) {
        console.error("Erreur connexion par code :", error);

        loginStatus.textContent =
            "Connexion impossible. Vérifie le dernier code reçu. " +
            "S’il a expiré, demande un nouveau code.";

    } finally {
        verifyLoginCodeButton.disabled = false;
        loginBackButton.disabled = false;

        if (!connected) {
            sendLoginCodeButton.disabled = false;
        }
    }
});

async function refreshAccountEmailPanel() {
    const panel = document.getElementById("accountEmailPanel");
    const message = document.getElementById("accountSavedMessage");

    panel.classList.add("hidden");
    message.classList.remove("hidden");
    message.textContent = "Vérification de ton accès…";

    try {
        const { data, error } = await supabaseClient.auth.getUser();

        if (error || !data.user) {
            throw error || new Error("Session introuvable.");
        }

        const emailConfirmed =
            data.user.is_anonymous === false &&
            Boolean(data.user.email) &&
            Boolean(data.user.email_confirmed_at);

        if (emailConfirmed) {
            message.textContent =
                "Ton accès est sauvegardé ✅ " +
                "Tu peux retrouver tes inscriptions avec ton adresse email.";
        } else {
            message.classList.add("hidden");
            panel.classList.remove("hidden");
        }

    } catch (error) {
        console.error("Erreur vérification de l’accès :", error);

        message.textContent =
            "Impossible de vérifier ton accès pour le moment. Recharge la page.";
    }
}