local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = QBCore.Functions.GetPlayerData().job
local activeJob = false

CreateThread(function()
    CityJob = AddBlipForCoord(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    SetBlipSprite(CityJob, 566)
    SetBlipDisplay(CityJob, 4)
    SetBlipScale(CityJob, 0.8)
    SetBlipAsShortRange(CityJob, true)
    SetBlipColour(CityJob, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("City Worker Job")
    EndTextCommandSetBlipName(CityJob)
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        exports['qb-target']:RemoveZone("workBox")
        RemoveBlip(JobBlip)
        activeJob = false
	end 
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    ClockInPed()
    activeJob = false
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        ClockInPed()
        activeJob = false 
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    exports['qb-target']:RemoveZone("workBox")
    RemoveBlip(JobBlip)
    activeJob = false
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(JobInfo)
    PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = JobInfo
end)

function loadAnimDict(dict) while (not HasAnimDictLoaded(dict)) do RequestAnimDict(dict) Wait(0) end end

function ClockInPed()

    if not DoesEntityExist(conBoss) then

        RequestModel(Config.BossModel) while not HasModelLoaded(Config.BossModel) do Wait(0) end

        conBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
        
        SetEntityAsMissionEntity(conBoss)
        SetPedFleeAttributes(conBoss, 0, 0)
        SetBlockingOfNonTemporaryEvents(conBoss, true)
        SetEntityInvincible(conBoss, true)
        FreezeEntityPosition(conBoss, true)
        loadAnimDict("amb@world_human_leaning@female@wall@back@holding_elbow@idle_a")        
        TaskPlayAnim(conBoss, "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", "idle_a", 8.0, 1.0, -1, 01, 0, 0, 0, 0)

        exports['qb-target']:AddTargetEntity(conBoss, { 
            options = {
                { 
                    type = "client",
                    event = "randol_cityworker:client:finishJob",
                    icon = "fa-solid fa-clipboard-check",
                    label = "Finish Work",
                    job = "cityworker"
                },
                { 
                    type = "client",
                    event = "randol_cityworker:client:startJob",
                    icon = "fa-solid fa-clipboard-list",
                    label = "Start Work",
                },
            }, 
            distance = 1.5, 
        })
    end
end

function AssignTask()
    newtask = Config.JobLocs[math.random(1, #Config.JobLocs)]

    JobBlip = AddBlipForCoord(newtask.x, newtask.y, newtask.z)
    SetBlipSprite(JobBlip, 566)
    SetBlipDisplay(JobBlip, 4)
    SetBlipScale(JobBlip, 0.6)
    SetBlipAsShortRange(JobBlip, true)
    SetBlipColour(JobBlip, 3)
    SetBlipFlashes(JobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("City Worker Task")
    EndTextCommandSetBlipName(JobBlip)
    SetNewWaypoint(newtask.x, newtask.y)
    exports['qb-target']:AddCircleZone("workBox", vector3(newtask.x, newtask.y, newtask.z), 1.3,{ name = "workBox", debugPoly = false, useZ=true, }, { options = { { type = "client", event = "randol_cityworker:client:completeRepairs", icon = "fa-solid fa-hammer", label = "Repair", job = "cityworker" }, }, distance = 1.5 })
    activeJob = true
    QBCore.Functions.Notify("You have been assigned a new task.", "success")
end

RegisterNetEvent('randol_cityworker:client:startJob', function(vehicle)
    local vehicle = Config.JobVehicle
    local coords = Config.VehicleSpawn
    if Config.ServerSideSpawn then -- Newer Core.
        TriggerServerEvent("randol_cityworker:server:SetJob")
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleNumberPlateText(veh, "CITY"..tostring(math.random(1000, 9999)))
            SetVehicleCustomPrimaryColour(veh, 255,255,255)
            SetVehicleCustomSecondaryColour(veh, 255,255,255)
            DecorSetFloat(veh, "city_worker", 1)
            SetEntityAsMissionEntity(veh, true, true)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
            props = {} props.modEngine = 3 props.modTransmission = 2 props.modSuspension = -1 props.modArmor = 4 props.modBrakes = 2 props.modTurbo = true props.dirtLevel = 0 QBCore.Functions.SetVehicleProperties(veh, props)
            CurrentPlate = QBCore.Functions.GetPlate(veh)
            exports[Config.FuelScript]:SetFuel(veh, 100.0)
        end, vehicle, coords, true)
        AssignTask()
    else -- Older core.
        TriggerServerEvent("randol_cityworker:server:SetJob")
        QBCore.Functions.SpawnVehicle(vehicle, function(veh)
            SetVehicleNumberPlateText(veh, "CITY"..tostring(math.random(1000, 9999)))
            DecorSetFloat(veh, "city_worker", 1)
            SetEntityAsMissionEntity(veh, true, true)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            CurrentPlate = QBCore.Functions.GetPlate(veh)
            exports[Config.FuelScript]:SetFuel(veh, 100.0)
        end, coords, true)
        AssignTask()
    end
end)

RegisterNetEvent('randol_cityworker:client:finishJob', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, true)
    if activeJob then
        if DecorExistOn((veh), "city_worker") then
            QBCore.Functions.DeleteVehicle(veh)
        else
            QBCore.Functions.Notify("This is not a work vehicle.", "error")
        end
        exports['qb-target']:RemoveZone("workBox") -- remove the zone.
        RemoveBlip(JobBlip)
        activeJob = false
    end
end)

RegisterNetEvent('randol_cityworker:client:completeRepairs', function()
    if activeJob then
        TriggerEvent('animations:client:EmoteCommandStart', {"hammer"})
        QBCore.Functions.Progressbar("city_repair", "Completing the task..", Config.ProgressBarTime, false, false, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            exports['qb-target']:RemoveZone("workBox") -- remove the zone.
            RemoveBlip(JobBlip)
            TriggerEvent('animations:client:EmoteCommandStart', {"hammer"}) -- This is a hacky way of fixing the hammer getting stuck in your hand. Don't question it.
            Wait(100)
            TriggerEvent('animations:client:EmoteCommandStart', {"c"})
            TriggerServerEvent("randol_cityworker:server:taskPayout", newtask)
            QBCore.Functions.Notify("Wait for your next task!", "success")
            SetTimeout(Config.Timeout, function()
                activeJob = false
                AssignTask()
            end)
        end)
    end
end)

CreateThread(function()
    DecorRegister("city_worker", 1)
end)
