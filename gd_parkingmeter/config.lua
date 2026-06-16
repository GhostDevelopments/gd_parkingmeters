Config = {}

Config.MeterModels = {
    `prop_parknmeter_01`,
    `prop_parknmeter_02`,
    `prop_parknmeter_01b`,
    `prop_parknmeter_02b`,
    `prop_parknmeter_03`,
    `prop_parkingmeter_1`,
    `prop_parkingmeter_2`,
}

Config.RobTime = 18000              -- 18 seconds (slightly longer for lockpick feel)
Config.MinReward = 50
Config.MaxReward = 150
Config.PoliceAlertChance = 65

Config.PlayerCooldown = 180         -- 3 minutes per meter

Config.RequiredItem = 'lockpick'    -- Change if your lockpick item has a different name

Config.Dispatch = {
    title = '10-90 - Parking Meter Tampering',
    message = 'Someone is tampering with a parking meter at %s',
    blipSprite = 431,
    blipColor = 1,
    blipScale = 1.2,
    blipTime = 15
}

Config.Debug = false
