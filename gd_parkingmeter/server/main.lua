-- Server-side parking meter theft handler
local meterCooldowns = {}

--- Get cooldown key for a meter position
--- @param coords vector3
--- @return string
local function getMeterKey(coords)
    return ("%.1f_%.1f"):format(coords.x, coords.y)
end

--- Check and set cooldown
--- @param coords vector3
--- @return boolean
local function checkAndSetCooldown(coords)
    local key = getMeterKey(coords)
    local now = os.time()
    
    if meterCooldowns[key] and now < meterCooldowns[key] then
        return false
    end
    
    meterCooldowns[key] = now + Config.PlayerCooldown
    return true
end

--- Main robbery handler
RegisterNetEvent("parkingmeter:rob", function(coords)
    local src = source
    if src <= 0 or not coords or type(coords) ~= "table" then return end

    local meterCoords = vector3(coords.x, coords.y, coords.z)
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    local dist = #(playerCoords - meterCoords)
    
    -- Anti-cheat
    if dist > Config.AntiCheat.maxDistance then
        if Config.Debug then
            print(("^1[ParkingMeter] Distance Check Failed: %s is %.2fm away^7"):format(GetPlayerName(src), dist))
        end
        return TriggerClientEvent("parkingmeter:failed", src, "You moved too far away!")
    end

    -- Cooldown check
    if not checkAndSetCooldown(meterCoords) then
        return TriggerClientEvent("parkingmeter:failed", src, "This meter was recently tampered with.")
    end

    -- Calculate reward
    local reward = math.random(Config.MinReward, Config.MaxReward)

    -- Add to inventory
    if exports.ox_inventory:AddItem(src, Config.RewardItem, reward) then
        TriggerClientEvent("parkingmeter:success", src, reward)
        
        -- Police alert
        if math.random(100) <= Config.PoliceAlertChance then
            TriggerClientEvent("parkingmeter:sendDispatch", -1, meterCoords)
        end
    else
        TriggerClientEvent("ox_lib:notify", src, { title = "Inventory Full", description = "You couldn't carry the cash!", type = "error" })
    end
end)

-- Cleanup loop
CreateThread(function()
    while true do
        Wait(600000) -- 10 mins
        local now = os.time()
        for key, cooldownEnd in pairs(meterCooldowns) do
            if cooldownEnd < now then meterCooldowns[key] = nil end
        end
    end
end)
