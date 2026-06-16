Config = {}

Config.MeterModels = {
    `prop_parknmeter_01`,
    `prop_parknmeter_02`,
    `prop_parknmeter_01b`,
    -- Add more parking meter models if needed
}

Config.RobTime = 15000              -- 15 seconds
Config.MinReward = 50
Config.MaxReward = 150
Config.PoliceAlertChance = 65       -- % chance to alert police

Config.PlayerCooldown = 300         -- 5 minutes cooldown per player

Config.Dispatch = {
    title = '10-90 - Parking Meter Tampering',
    message = 'Someone is tampering with a parking meter at %s',
    blipSprite = 431,
    blipColor = 1,
    blipScale = 1.2,
    blipTime = 15                   -- Minutes the blip stays on map for police
}