local Config = lib.require('config')
local isHired, activeJob = false
local cityBoss, startZone, currZone

local CITY_BLIP = AddBlipForCoord(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
SetBlipSprite(CITY_BLIP, 566)
SetBlipDisplay(CITY_BLIP, 4)
SetBlipScale(CITY_BLIP, 0.8)
SetBlipAsShortRange(CITY_BLIP, true)
SetBlipColour(CITY_BLIP, 5)
BeginTextCommandSetBlipName("STRING")
AddTextComponentSubstringPlayerName("City Worker Job")
EndTextCommandSetBlipName(CITY_BLIP)

local function resetJob()
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeZone(currZone)
    else
        exports['qb-target']:RemoveZone(currZone)
    end
    currZone = nil
    RemoveBlip(JobBlip)
    isHired = false
    activeJob = false
    if DoesEntityExist(cityBoss) then
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:removeLocalEntity(cityBoss, {'Start Work', 'Finish Work'})
        else
            exports['qb-target']:RemoveTargetEntity(cityBoss, {'Start Work', 'Finish Work'})
        end
        DeleteEntity(cityBoss)
        cityBoss = nil
    end
    if startZone then startZone:remove() startZone = nil end
end

local function startWork(netid, data)
    local workVehicle = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToVeh(netid)
        end
    end, 'Could not load entity in time.', 3000)

    SetVehicleNumberPlateText(workVehicle, 'CITY'..tostring(math.random(1000, 9999)))
    SetVehicleColours(workVehicle, 111, 111)
    SetVehicleDirtLevel(workVehicle, 1)
    handleVehicleKeys(workVehicle)
    SetVehicleEngineOn(workVehicle, true, true)
    isHired = true
    NextDelivery(data)
    Wait(500)
    if Config.FuelScript.enable then
        exports[Config.FuelScript.script]:SetFuel(workVehicle, 100.0)
    else
        Entity(workVehicle).state.fuel = 100
    end
end

local function finishWork()
    local ped = cache.ped
    local pos = GetEntityCoords(ped)

    local finishspot = vec3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    if #(pos - finishspot) > 10.0 or not isHired then return end

    local success = lib.callback.await('randol_cityworker:server:clockOut', false)
    if success then
        DoNotification('You ended your shift.', 'success')
        RemoveBlip(JobBlip)
        isHired, activeJob = false
    end
end

local function yeetPed()
    if DoesEntityExist(cityBoss) then
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:removeLocalEntity(cityBoss, {'Start Work', 'Finish Work'})
        else
            exports['qb-target']:RemoveTargetEntity(cityBoss, {'Start Work', 'Finish Work'})
        end
        DeleteEntity(cityBoss)
        cityBoss = nil
    end
end

local function spawnPed()
    if DoesEntityExist(cityBoss) then return end
    
    lib.requestModel(Config.BossModel)
    cityBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
    SetEntityAsMissionEntity(cityBoss)
    SetPedFleeAttributes(cityBoss, 0, 0)
    SetBlockingOfNonTemporaryEvents(cityBoss, true)
    SetEntityInvincible(cityBoss, true)
    FreezeEntityPosition(cityBoss, true)
    TaskStartScenarioInPlace(cityBoss, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetModelAsNoLongerNeeded(Config.BossModel)
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(cityBoss, {
            {
                icon = 'fa-solid fa-clipboard-list',
                label = 'Start Work',
                onSelect = function()
                    local netid, data = lib.callback.await('randol_cityworker:server:spawnVehicle', false)
                    if netid and data then
                        startWork(netid, data)
                    end
                end,
                canInteract = function()
                    return not isHired
                end,
                distance = 1.5,
            },
            {
                icon = 'fa-solid fa-clipboard-check',
                label = 'Finish Work',
                onSelect = function()
                    finishWork()
                end,
                canInteract = function() return isHired end,
                distance = 1.5,
            },
        })
    else
        exports['qb-target']:AddTargetEntity(cityBoss, { 
            options = {
                {
                    icon = 'fa-solid fa-clipboard-list',
                    label = 'Start Work',
                    action = function()
                        local netid, data = lib.callback.await('randol_cityworker:server:spawnVehicle', false)
                        if netid and data then
                            startWork(netid, data)
                        end
                    end,
                    canInteract = function()
                        return not isHired
                    end,
                },
                {
                    icon = 'fa-solid fa-clipboard-check',
                    label = 'Finish Work',
                    action = function()
                        finishWork()
                    end,
                    canInteract = function()
                        return isHired
                    end,
                },
            }, 
            distance = 1.5, 
        })
    end
end

local function repairSpot()
    if not isHired then return end
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeZone(currZone)
    else
        exports['qb-target']:RemoveZone(currZone)
    end
    currZone = nil
    TaskStartScenarioInPlace(cache.ped, 'WORLD_HUMAN_HAMMERING', 0, true)
    if lib.progressCircle({
        duration = 10000,
        position = 'bottom',
        label = 'Completing the task..',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then
        ClearPedTasksImmediately(cache.ped)
        local success = lib.callback.await('randol_cityworker:server:Payment', false)
        if success then
            RemoveBlip(JobBlip)
            activeJob = false
            DoNotification('Job complete. Wait for your next task.', 'success')
        end
    end
end

function NextDelivery(data)
    if activeJob then return end

    currentLoc = data.location
    JobBlip = AddBlipForCoord(currentLoc.x, currentLoc.y, currentLoc.z)
    SetBlipSprite(JobBlip, 566)
    SetBlipDisplay(JobBlip, 4)
    SetBlipScale(JobBlip, 0.6)
    SetBlipAsShortRange(JobBlip, true)
    SetBlipColour(JobBlip, 3)
    SetBlipRoute(JobBlip, true)
    SetBlipRouteColour(JobBlip, 3)
    SetBlipFlashes(JobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("City Worker Task")
    EndTextCommandSetBlipName(JobBlip)

    if GetResourceState('ox_target') == 'started' then
        currZone = exports.ox_target:addSphereZone({
            coords = vec3(currentLoc.x, currentLoc.y, currentLoc.z),
            radius = 1.3,
            debug = false,
            options = {
                {
                    icon = 'fa-solid fa-hammer', 
                    label = 'Repair',
                    onSelect = repairSpot,
                },
                
            }
        })
    else
        exports['qb-target']:AddCircleZone('workBox', vec3(currentLoc.x, currentLoc.y, currentLoc.z), 1.3,{
            name = 'workBox', 
            debugPoly = false, 
            useZ=true, 
        }, { options = {
            { 
                icon = 'fa-solid fa-hammer', 
                label = 'Repair',
                action = repairSpot,
            },}, 
            distance = 1.5 
        })
        currZone = 'workBox'
    end

    activeJob = true
    DoNotification('You have been assigned a new task.', 'success')
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
end

local function startJobPoint()
    startZone = lib.points.new({
        coords = Config.BossCoords.xyz,
        distance = 50,
        onEnter = spawnPed,
        onExit = yeetPed,
    })
end

function OnPlayerLoaded()
    startJobPoint()
end

function OnPlayerUnload()
    resetJob()
end

RegisterNetEvent('randol_cityworker:client:generatedLocation', function(data)
    if GetInvokingResource() or not data then return end
    NextDelivery(data)
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not hasPlyLoaded() then return end
    startJobPoint()
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() ~= resourceName then return end
    resetJob()
end)