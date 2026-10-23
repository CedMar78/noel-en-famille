const SUPABASE_URL = "https://vvbswpdipfgeuxsgficf.supabase.co";
const SUPABASE_KEY = "sb_publishable_RVqptWWhroIAqrK4Cz7mJg_-h0VAj5Q";

const supabaseClient = supabase.createClient(
    SUPABASE_URL,
    SUPABASE_KEY
);

console.log("Supabase connecté !");

async function testSupabaseConnection() {

    const { data, error } = await supabaseClient
        .from("groups")
        .select("id, name");

    if (error) {
        console.error("Erreur Supabase :", error);
        return;
    }

    console.log("Réponse de Supabase :", data);
}

testSupabaseConnection();

async function ensureAnonymousUser() {

    const { data: sessionData } = await supabaseClient.auth.getSession();

    if (sessionData.session) {
        console.log(
            "Utilisateur déjà connecté :",
            sessionData.session.user.id
        );

        return sessionData.session.user;
    }

    const { data, error } = await supabaseClient.auth.signInAnonymously();

    if (error) {
        console.error(
            "Erreur connexion anonyme :",
            error
        );

        return null;
    }

    console.log(
        "Nouvel utilisateur anonyme :",
        data.user.id
    );

    return data.user;
}

ensureAnonymousUser();