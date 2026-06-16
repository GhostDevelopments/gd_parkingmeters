local robbedMeters = {}

-- Asset hashes
local particleAsset = "core"
local particleEffect = "ent_dst_elec_fire_sp"

-- Robust initialization with multiple fallback methods
local function InitializeTargets()
    if not exports.ox_target or not exports.ox_lib then
        print('^1[ParkingMeter] Dependencies not ready yet, retrying...^7')
        return false
    end

    if Config.Debug then
        print('^2[ParkingMeter] Dependencies detected. Loading assets and adding targets...^7')
    end

    -- Load particle asset
    RequestNamedPtfxAsset(particleAsset)

    for _, model in ipairs(Config.MeterModels) do
        exports.ox_target:addModel(model, {
            {
                name = 'rob_parking_meter',
                icon = 'fas fa-hand-holding-dollar',
                label = 'Steal from Parking Meter',
                distance = 3.0,
                onSelect = function(data)
                    if data and data.entity and data.entity ~= 0 then
                        RobParkingMeter(data.entity)
                    end
                end,
                canInteract = function(entity)
                    if not entity or entity == 0 then return false end

                    local pos = GetEntityCoords(entity)
                    local key = string.format("%.1f_%.1f", pos.x, pos.y)

                    local lastTime = robbedMeters[key] or 0
                    return (GetGameTimer() - lastTime) > (Config.PlayerCooldown * 1000)
                end
            }
        })
    end

    if Config.Debug then
        print('^2[ParkingMeter] Targets successfully added! Resource fully loaded.^7')
    end
    return true
end

-- Main initialization thread
Citizen.CreateThread(function()
    if Config.Debug then
        print('^2[ParkingMeter] Resource starting...^7')
    end

    robbedMeters = {}

    -- Initial wait
    local attempts = 0
    while (not exports.ox_target or not exports.ox_lib) and attempts < 100 do
        attempts = attempts + 1
        Wait(100)
    end

    if InitializeTargets() then
        return
    end

    -- Fallback: Retry every second for up to 30 seconds
    print('^3[ParkingMeter] Waiting for ox_target & ox_lib...^7')
    local retryCount = 0
    while retryCount < 30 do
        Wait(1000)
        retryCount = retryCount + 1
        if InitializeTargets() then
            return
        end
    end

    -- Final failure
    print('^1[ParkingMeter] CRITICAL ERROR: ox_target or ox_lib still not available after 30+ seconds!^7')
    print('^1[ParkingMeter] Make sure ox_lib and ox_target are started before parkingmeter.^7')
end)

-- Also listen for resource start events (helps on restarts)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == 'ox_lib' or resourceName == 'ox_target' then
        if Config.Debug then
            print('^3[ParkingMeter] Resource start detected for: ' .. resourceName .. '^7')
        end
        Wait(1000)
        InitializeTargets()
    end
end)

function RobParkingMeter(entity)
    if not entity or entity == 0 then return end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(entity)

    if Config.Debug then print('^2[ParkingMeter] Robbery started at:', pos) end

    -- Animation + Prop
    local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
    local animName = "machinic_loop_mechandplayer"

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do Wait(10) end
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

    local propModel = `bzzz_props_lockpick_01`
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end

    local prop = CreateObject(propModel, pos.x, pos.y, pos.z, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 18905), 0.12, 0.08, -0.01, -36.0, -46.0, 0.0, true, true, false, true, 1, true)

    -- Sparks
    UseParticleFxAssetNextCall(particleAsset)
    local sparks = StartParticleFxLoopedOnEntity(particleEffect, entity, 0.0, 0.0, 0.15, 0.0, 0.0, 0.0, 0.45, false, false, false)

    -- Progress Bar
    local success = lib.progressBar({
        duration = Config.RobTime,
        label = 'Prying open parking meter...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    -- Cleanup
    if DoesEntityExist(prop) then DeleteEntity(prop) end
    if sparks then StopParticleFxLooped(sparks, false) end
    StopAnimTask(ped, animDict, animName, -4.0)
    RemoveAnimDict(animDict)

    if not success then
        lib.notify({ title = 'Cancelled', description = 'You stopped tampering.', type = 'error' })
        return
    end

    if not lib.skillCheck({'easy', 'easy', 'easy'}, {'e', 'e', 'e', 'e'}) then
        lib.notify({ title = 'Failed', description = 'You failed to pry open the meter.', type = 'error' })
        return
    end

    -- Cooldown
    local key = string.format("%.1f_%.1f", pos.x, pos.y)
    robbedMeters[key] = GetGameTimer()

    if Config.Debug then
        print('^2[ParkingMeter] COOLDOWN SET for key: ' .. key .. '^7')
    end

    TriggerServerEvent('parkingmeter:rob', pos)
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

-- Cooldown cleanup
Citizen.CreateThread(function()
    while true do
        Wait(60000)
        local now = GetGameTimer()
        local expireTime = (Config.PlayerCooldown * 1000) + 300000

        for key, time in pairs(robbedMeters) do
            if now - time > expireTime then
                robbedMeters[key] = nil
            end
        end
    end
end)
