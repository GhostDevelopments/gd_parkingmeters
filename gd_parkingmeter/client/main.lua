local robbedMeters = {}  -- Cooldown by position

Citizen.CreateThread(function()
    if Config.Debug then
        print('^2[ParkingMeter] Resource loaded - Adding targets...^7')
    end

    for _, model in ipairs(Config.MeterModels) do
        exports.ox_target:addModel(model, {
            {
                name = 'rob_parking_meter',
                icon = 'fas fa-hand-holding-dollar',
                label = 'Steal from Parking Meter',
                distance = 3.0,
                onSelect = function(data)
                    RobParkingMeter(data.entity)
                end,
                canInteract = function(entity, distance, coords, name, bone)
                    if not entity or entity == 0 then return false end
                    
                    local pos = GetEntityCoords(entity)
                    local key = math.floor(pos.x) .. "_" .. math.floor(pos.y)  -- Position-based key
                    
                    local lastTime = robbedMeters[key] or 0
                    return (GetGameTimer() - lastTime) > (Config.PlayerCooldown * 1000)
                end
            }
        })
    end
end)

function RobParkingMeter(entity)
    if not entity or entity == 0 then return end

    PlaySoundFrontend(-1, "Drill_01", "DLC_HEIST_FLEECA_SOUNDSET", true)

    if lib.progressBar({
        duration = Config.RobTime,
        label = 'Tampering with parking meter...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = 'anim@heists@fleeca_bank@drilling',
            clip = 'drill_straight_fail',
            flag = 49
        }
    }) then
        -- Position-based cooldown (fixes local entity issue)
        local pos = GetEntityCoords(entity)
        local key = math.floor(pos.x) .. "_" .. math.floor(pos.y)
        robbedMeters[key] = GetGameTimer()

        local coords = pos
        TriggerServerEvent('parkingmeter:rob', coords)

        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        StopSoundFrontend()
        lib.notify({ title = 'Cancelled', description = 'You stopped tampering.', type = 'error' })
    end
end

RegisterNetEvent('parkingmeter:success', function(amount)
    lib.notify({ title = 'Success', description = 'You stole $' .. amount .. ' from the meter!', type = 'success' })
end)

RegisterNetEvent('parkingmeter:sendDispatch', function(coords)
    local data = exports['cd_dispatch']:GetPlayerInfo() or {}
    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = {'police'},
        coords = coords,
        title = Config.Dispatch.title,
        message = string.format(Config.Dispatch.message, data.street or 'Unknown'),
        flash = 0,
        unique_id = data.unique_id,
        sound = 1,
        blip = {
            sprite = Config.Dispatch.blipSprite,
            scale = Config.Dispatch.blipScale,
            colour = Config.Dispatch.blipColor,
            flashes = true,
            text = 'Parking Meter Theft',
            time = Config.Dispatch.blipTime,
            radius = 0,
        }
    })
end)

-- Optional cleanup
Citizen.CreateThread(function()
    while true do
        Wait(120000) -- every 2 minutes
        for key, time in pairs(robbedMeters) do
            if GetGameTimer() - time > (Config.PlayerCooldown * 1000 + 300000) then
                robbedMeters[key] = nil
            end
        end
    end
end)
