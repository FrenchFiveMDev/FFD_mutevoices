Config              = {}
-- Si true : seuls les joueurs avec l'ACE "muet.use" peuvent l'utiliser
-- (dans server.cfg : add_ace identifier.license:XXXX muet.use allow)
Config.RequireAce   = false
Config.OpenKey      = ''
Config.Language     = 'fr'
Config.MaxLength    = 200
Config.Cooldown     = 1500
Config.ShowBubble   = true
Config.ShowChat     = false
Config.MouthAnim    = true
Config.Ranges       = {
    whisper = 3.0,
    normal  = 10.0,
    shout   = 25.0,
}

Config.QuickPhrases = {
    'Bonjour !', 'Bonsoir !', 'Merci', 'De rien',
    'Oui', 'Non', 'D\'accord', 'Excusez-moi',
    'Aidez-moi !', 'Suivez-moi', 'Attendez-moi', 'Au revoir',
}

-- ───────────── Dictée vocale (micro → texte) ─────────────
Config.RecLang      = 'fr-FR'
Config.AutoSend     = false   -- true = envoie tout de suite après la dictée (false = le joueur relit/corrige avant)

-- Mode téléphone / navigateur : page web servie par le serveur.
Config.WebUrl       = 'https://ffdmutevoices.vercel.app/'
Config.WebCodeTTL   = 7200 -- durée de validité du code de liaison (secondes)
