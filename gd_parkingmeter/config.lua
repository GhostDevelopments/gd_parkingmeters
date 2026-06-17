Config = {}

-- Parking meter model names (strings are more reliable for ox_target)
Config.MeterModels = {
    "prop_parknmeter_01",
    "prop_parknmeter_01b",
    "prop_parknmeter_02",
    "prop_parknmeter_02b",
    "prop_parknmeter_03",
    "prop_parkingmeter_1",
    "prop_parkingmeter_2",
}

-- Robbery settings
Config.RewardItem = "black_money"    -- Item to receive (e.g. money, black_money)
Config.RobTime = 12000              -- Duration in ms (12 seconds)
Config.MinReward = 100
Config.MaxReward = 250
Config.PoliceAlertChance = 60       -- 60% chance

-- Cooldown settings (seconds)
Config.PlayerCooldown = 300         -- 5 minutes per meter

-- Skill check settings
Config.SkillCheck = {
    enabled = true,
    difficulty = { "easy", "medium" }, -- Sequential circle checks
}

-- Animation settings
Config.Animation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    name = "machinic_loop_mechandplayer",
    propModel = `bzzz_props_lockpick_01`,
}

-- Particle effects
Config.Fx = {
    asset = "core",
    effect = "ent_dst_elec_fire_sp",
}

-- Police dispatch (optional - set enabled = false to disable)
Config.Dispatch = {
    enabled = true,
    resource = "cd_dispatch",       -- Dispatch resource name
    title = "10-90 - Parking Meter Tampering",
    message = "Someone is tampering with a parking meter at %s",
    blipSprite = 431,
    blipColor = 1,
    blipScale = 1.2,
    blipTime = 15,
    blipFlashes = true,
}

-- Anti-cheat settings
Config.AntiCheat = {
    maxDistance = 10.0,             -- Increased distance buffer (standard is ~2-3m, 10.0 allows for lag/animation)
    alertThreshold = 20.0,          -- Distance to trigger alert
}

-- Debug mode
Config.Debug = false
