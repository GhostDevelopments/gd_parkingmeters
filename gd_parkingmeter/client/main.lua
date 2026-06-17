-- Client-side parking meter theft script
local robbedMeters = {}
local isRobbing = false
local isInitialized = false

--- Initialize target options and assets
local function initializeResource()
    if isInitialized then return true end

    -- Verify ox_target exports
    if GetResourceState("ox_target") ~= "started" or not exports.ox_target then
        return false
    end

    -- Clear existing to prevent duplicates
    pcall(function()
        exports.ox_target:removeModel(Config.MeterModels, "rob_parking_meter")
    end)

    -- Register models with ox_target
    local status, err = pcall(function()
        exports.ox_target:addModel(Config.MeterModels, {
            {
                name = "rob_parking_meter",
                icon = "fas fa-hand-holding-dollar",
                label = "Tamper with Meter",
                distance = 1.5,
                onSelect = function(data)
                    if data and data.entity then
                        ExecuteRobbery(data.entity)
                    end
                end,
                canInteract = function(entity, distance, coords, name, bone)
                    if isRobbing then return false end
                    
                    local pos = GetEntityCoords(entity)
                    if not pos or pos == vec3(0, 0, 0) then return true end
                    
                    local key = ("%.1f_%.1f"):format(pos.x, pos.y)
                    local lastTime = robbedMeters[key] or 0

                    return (GetGameTimer() - lastTime) > (Config.PlayerCooldown * 1000)
                end
            }
        })
    end)

    if not status then
        if Config.Debug then print(("^1[ParkingMeter] Target registration error: %s^7"):format(tostring(err))) end
        return false
    end

    -- Cache assets
    RequestAnimDict(Config.Animation.dict)
    local modelHash = type(Config.Animation.propModel) == "number" and Config.Animation.propModel or GetHashKey(Config.Animation.propModel)
    RequestModel(modelHash)

    isInitialized = true
    if Config.Debug then print("^2[ParkingMeter] Successfully initialized^7") end
    return true
end

-- Startup logic
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(500) end
    
    -- Delay for server boot stability
    Wait(2500)

    local timeout = GetGameTimer() + 60000
    while not isInitialized and GetGameTimer() < timeout do
        if initializeResource() then break end
        Wait(2500)
    end
end)

-- Resource event handlers
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == "ox_target" then
        Wait(1000)
        isInitialized = false
        initializeResource()
    end
end)

--- Perform the robbery action
--- @param entity number Entity handle
function ExecuteRobbery(entity)
    if not entity or entity == 0 or isRobbing then return end

    local ped = cache.ped
    if IsPedInAnyVehicle(ped, true) then
        return lib.notify({ title = "Action Impossible", description = "You cannot do this from a vehicle.", type = "error" })
    end

    local pos = GetEntityCoords(entity)
    if #(pos) < 1.0 then return end

    isRobbing = true

    -- Prepare particles
    if not HasNamedPtfxAssetLoaded(Config.Fx.asset) then
        RequestNamedPtfxAsset(Config.Fx.asset)
        while not HasNamedPtfxAssetLoaded(Config.Fx.asset) do Wait(0) end
    end

    UseParticleFxAssetNextCall(Config.Fx.asset)
    local sparks = StartParticleFxLoopedOnEntity(Config.Fx.effect, entity, 0.0, 0.0, 0.15, 0.0, 0.0, 0.0, 0.45, false, false, false)

    -- Progress Bar
    local success = lib.progressBar({
        duration = Config.RobTime,
        label = "Prying open parking meter...",
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = Config.Animation.dict,
            clip = Config.Animation.name,
            flag = 49
        },
        prop = {
            model = Config.Animation.propModel,
            bone = 18905,
            pos = vec3(0.12, 0.08, -0.01),
            rot = vec3(-36.0, -46.0, 0.0)
        }
    })

    if sparks then StopParticleFxLooped(sparks, false) end

    if not success then
        isRobbing = false
        return lib.notify({ title = "Cancelled", description = "You stopped tampering with the meter.", type = "warning" })
    end

    -- Skill check
    if Config.SkillCheck.enabled then
        FreezeEntityPosition(ped, true)
        local skillSuccess = lib.skillCheck(Config.SkillCheck.difficulty)
        FreezeEntityPosition(ped, false)
        
        if not skillSuccess then
            isRobbing = false
            return lib.notify({ title = "Failed", description = "You failed to pry open the meter.", type = "error" })
        end
    end

    -- Register cooldown and trigger server
    local key = ("%.1f_%.1f"):format(pos.x, pos.y)
    robbedMeters[key] = GetGameTimer()

    TriggerServerEvent("parkingmeter:rob", { x = pos.x, y = pos.y, z = pos.z })
    isRobbing = false
end

-- Success/Failure events
RegisterNetEvent("parkingmeter:success", function(amount)
    lib.notify({
        title = "Success",
        description = ("You stole $%d from the meter!"):format(amount),
        type = "success"
    })
end)

RegisterNetEvent("parkingmeter:failed", function(reason)
    lib.notify({
        title = "Failed",
        description = reason or "Something went wrong.",
        type = "error"
    })
end)

-- Dispatch logic
RegisterNetEvent("parkingmeter:sendDispatch", function(coords)
    if not Config.Dispatch.enabled or GetResourceState(Config.Dispatch.resource) ~= "started" then return end

    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

    TriggerEvent(Config.Dispatch.resource .. ":AddNotification", {
        job_table = { "police" },
        coords = coords,
        title = Config.Dispatch.title,
        message = Config.Dispatch.message:format(streetName or "Unknown"),
        flash = 0,
        unique_id = "parking_" .. GetGameTimer(),
        sound = 1,
        blip = {
            sprite = Config.Dispatch.blipSprite,
            scale = Config.Dispatch.blipScale,
            colour = Config.Dispatch.blipColor,
            flashes = Config.Dispatch.blipFlashes,
            text = "Parking Meter Theft",
            time = Config.Dispatch.blipTime,
        }
    })
end)

-- Cleanup Loop (infrequent)
CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        local now = GetGameTimer()
        local threshold = (Config.PlayerCooldown * 1000) + 60000

        for key, time in pairs(robbedMeters) do
            if now - time > threshold then
                robbedMeters[key] = nil
            end
        end
    end
end)
