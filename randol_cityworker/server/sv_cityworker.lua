local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('randol_cityworker:server:taskPayout', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local payout = math.random(Config.MinPayout, Config.MaxPayout)
    if not Player then return end
    if Player.PlayerData.job.name == "cityworker" then
        Player.Functions.AddMoney(Config.MoneyType, payout)
        TriggerClientEvent('QBCore:Notify', src, "You were paid $"..payout.." for completing the job.", "success")
    end
end)

RegisterNetEvent('randol_cityworker:server:SetJob', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.name ~= "cityworker" then
        Player.Functions.SetJob("cityworker", "0")
        TriggerClientEvent('QBCore:Notify', src, "You are now clocked in as a City Worker.", "success")
    end
end)