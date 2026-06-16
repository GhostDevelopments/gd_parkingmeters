RegisterNetEvent('parkingmeter:rob', function(coords)
    local src = source
    local playerPed = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(playerPed)

    -- Anti-cheat
    if #(pedCoords - coords) > 15.0 then
        print('^1[Anti-Cheat] Suspicious parking meter robbery from ' .. GetPlayerName(src) .. '^7')
        return
    end

    local reward = math.random(Config.MinReward, Config.MaxReward)

    local success = exports.ox_inventory:AddItem(src, 'black_money', reward)

    if success then
        TriggerClientEvent('parkingmeter:success', src, reward)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Inventory Full',
            description = 'You couldn\'t carry the cash!',
            type = 'error'
        })
        return
    end

    -- Dispatch alert
    if math.random(100) <= Config.PoliceAlertChance then
        TriggerClientEvent('parkingmeter:sendDispatch', src, coords)
    end
end)