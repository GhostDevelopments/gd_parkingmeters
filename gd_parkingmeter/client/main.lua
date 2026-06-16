local lastRobTime = 0

-- Add ox_target to parking meters
Citizen.CreateThread(function()
    for _, model in ipairs(Config.MeterModels) do
        exports.ox_target:addModel(model, {
            {
                name = 'rob_parking_meter',
                icon = 'fas fa-hand-holding-dollar',
                label = 'Steal from Parking Meter',
                onSelect = function(data)
                    RobParkingMeter(data.entity)
                end,
                canInteract = function(entity, distance, coords, name, bone)
                    return (GetGameTimer() - lastRobTime) > (Config.PlayerCooldown * 1000)
                end
            }
        })
    end
end)

function RobParkingMeter(entity)
    -- Drilling sound
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
        lastRobTime = GetGameTimer()

        local coords = GetEntityCoords(entity)
        TriggerServerEvent('parkingmeter:rob', coords)

        -- Success sound
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        -- Stop sound on cancel
        StopSoundFrontend()
        lib.notify({
            title = 'Cancelled',
            description = 'You stopped tampering.',
            type = 'error'
        })
    end
end

RegisterNetEvent('parkingmeter:success', function(amount)
    lib.notify({
        title = 'Success',
        description = 'You stole $' .. amount .. ' from the meter!',
        type = 'success'
    })
end)

RegisterNetEvent('parkingmeter:sendDispatch', function(coords)
    local data = exports['cd_dispatch']:GetPlayerInfo() or {}

    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = {'police', sasp},
        coords = coords,
        title = Config.Dispatch.title,
        message = string.format(Config.Dispatch.message, data.street_1 or 'Unknown'),
        flash = 0,
        unique_id = 'meter_rob_' .. GetPlayerServerId(PlayerId()) .. '_' .. GetGameTimer(),
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