Config = {}

-- General settings
Config.Debug = false
Config.UseOxTarget = true -- Set to true to use ox_target

-- Pickpocketing settings
Config.PickpocketTime = 3000 -- Changed from 5000 to 3000 (3 seconds) for quicker stealing
Config.PickpocketMinDistance = 1.0 -- Minimum distance to target
Config.PickpocketMaxDistance = 1.5 -- Maximum distance to initiate pickpocketing
Config.CheckForPolice = true -- Check if there are any police officers nearby
Config.MinPoliceCount = 0 -- Minimum police count required to pickpocket
Config.PoliceJobs = {"police", "lspd"} -- Jobs that count as police

-- Chance settings (in percentage)
Config.Chances = {
    runAway = 30, -- 30% chance the NPC will run away
    fight = 25,   -- 25% chance the NPC will fight back
    nothing = 45  -- 45% chance nothing will happen (undetected)
}

-- Items that can be found while pickpocketing
Config.Items = {
    { name = "money", min = 10, max = 250, chance = 70 },
    { name = "phone", min = 1, max = 1, chance = 15 },
    { name = "credit_card", min = 1, max = 1, chance = 10 },
    { name = "watch", min = 1, max = 1, chance = 20 },
    { name = "jewels", min = 1, max = 3, chance = 5 },
    { name = "lockpick", min = 1, max = 1, chance = 5 },
}

-- Animation settings
Config.Animations = {
    dict = "mp_common",
    anim = "givetake1_a"
}

-- Sound settings
Config.Sounds = {
    pickpocket = {
        name = "pickpocket",
        file = "pickpocket.ogg"
    }
}

-- Notifications (Danish)
Config.Texts = {
    startPickpocketing = "Du begynder at stjæle...",
    cancelledPickpocketing = "Du afbrød tyveriet",
    tooFar = "Personen bevægede sig væk",
    noPolice = "Der er ikke nok politi i byen",
    stealSuccess = "Du stjal noget fra personen",
    stealFailed = "Du fandt ikke noget værdifuldt",
    npcNoticed = "Personen opdagede dig!",
    npcFighting = "Personen angriber dig!",
    npcFled = "Personen løb væk i panik!"
}

-- Target text (Danish)
Config.TargetLabel = "Stjæl fra person..."

-- Progress circle settings (ox_lib)
Config.Progress = {
    label = "Stjæler...",
    duration = Config.PickpocketTime,
    position = 'bottom',
    useWhileDead = false,
    canCancel = true,
    disable = {
        car = true,
        move = true,
        combat = true,
    },
    -- Updated animation to be more appropriate for pickpocketing
    anim = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
        flag = 49
    },
} 