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

    local ped = PlayerPedId()

    -- Lockpick/Screwdriver Prop
    local model = `prop_tool_screwdvr03`

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(
    prop,
    ped,
    GetPedBoneIndex(ped, 57005),
    0.10, 0.01, -0.01,
    180.0, 0.0, 90.0,
    true, true, false, true, 1, true
)

    -- Load Sparks Asset
    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do
        Wait(0)
    end

    UseParticleFxAssetNextCall("core")

    local sparks = StartParticleFxLoopedOnEntity(
        "ent_dst_elec_fire_sp",
        entity,
        0.0, 0.0, 0.15,
        0.0, 0.0, 0.0,
        0.4,
        false,
        false,
        false
    )

    local success = lib.progressBar({
        duration = Config.RobTime,
        label = 'Prying open parking meter...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'veh@break_in@0h@p_m_one@',
            clip = 'low_force_entry_ds',
            flag = 49
        }
    })

    -- Cleanup FX
    if sparks then
        StopParticleFxLooped(sparks, false)
    end

    -- Cleanup Prop
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end

    if not success then
        lib.notify({
            title = 'Cancelled',
            description = 'You stopped tampering.',
            type = 'error'
        })
        return
    end

    -- Easy x3 Skill Check
    local passed = lib.skillCheck(
        {'easy', 'easy', 'easy'},
        {'e', 'e', 'e', 'e'}
    )

    if not passed then
        lib.notify({
            title = 'Failed',
            description = 'You failed to pry open the meter.',
            type = 'error'
        })
        return
    end

    -- Position-based cooldown
    local pos = GetEntityCoords(entity)
    local key = math.floor(pos.x) .. "_" .. math.floor(pos.y)

    robbedMeters[key] = GetGameTimer()

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
