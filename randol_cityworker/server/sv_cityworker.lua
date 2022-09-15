local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('randol_cityworker:server:taskPayout', function(newtask)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local payout = math.random(Config.MinPayout, Config.MaxPayout)
    if not Player then return end
    taskcoords = newtask
    if Player.PlayerData.job.name == "cityworker" then
        if #(GetEntityCoords(GetPlayerPed(src)) - taskcoords) < 4.0 then
            Player.Functions.AddMoney(Config.MoneyType, payout)
            TriggerClientEvent('QBCore:Notify', src, "You were paid $"..payout.." for completing the job.", "success")
        else
            TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'randol_cityworker', 'red', '**Identifier**: `'..GetPlayerName(src) .. '` \n**Character**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CID**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license..'`\n\n **tried to exploit the randol_cityworker payout event**', true)
            DropPlayer(src, "Attempted to Exploit Randol_CityWorker")
            print("CHEATER CHEATER CHEATER")
        end
    end
end)

RegisterNetEvent('randol_cityworker:server:SetJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(Config.BossCoords.x,Config.BossCoords.y,Config.BossCoords.z)) < 4.0 then
        if Player.PlayerData.job.name ~= "cityworker" then
            Player.Functions.SetJob("cityworker", "0")
            TriggerClientEvent('QBCore:Notify', src, "You are now clocked in as a City Worker.", "success")
        end
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'randol_cityworker', 'red', '**Identifier**: `'..GetPlayerName(src) .. '` \n**Character**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CID**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license..'`\n\n **triggered the server event for randol_cityworker without being near the spot.**', true)
        DropPlayer(src, "Attempted to Exploit Randol_CityWorker")
        print("CHEATER CHEATER CHEATER")
    end
end)