-- client_events.lua - Gestion des événements côté client

-- Événements pour les actions admin
RegisterNetEvent('ContextMenu:heal')
AddEventHandler('ContextMenu:heal', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    ClearPedBloodDamage(playerPed)
    
    ShowNotification("Vous avez été soigné", 'success')
end)

RegisterNetEvent('ContextMenu:revive')
AddEventHandler('ContextMenu:revive', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed, true)
    
    NetworkResurrectLocalPlayer(coords, true, true, false)
    SetPlayerInvincible(playerPed, false)
    ClearPedBloodDamage(playerPed)
    
    -- Reset des besoins si ESX Basic Needs est présent
    TriggerEvent('esx_basicneeds:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
    
    ShowNotification("Vous avez été réanimé", 'success')
end)

RegisterNetEvent('ContextMenu:teleport')
AddEventHandler('ContextMenu:teleport', function(coords)
    local playerPed = PlayerPedId()
    
    -- Téléportation sécurisée
    DoScreenFadeOut(500)
    Citizen.Wait(500)
    
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z + 1.0)
    
    Citizen.Wait(500)
    DoScreenFadeIn(500)
    
    ShowNotification("Téléporté!", 'inform')
end)

RegisterNetEvent('ContextMenu:executeVehicleAction')
AddEventHandler('ContextMenu:executeVehicleAction', function(action, vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if not DoesEntityExist(vehicle) then
        ShowNotification("Véhicule introuvable", 'error')
        return
    end
    
    if action == "repair" then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, false)
        ShowNotification("Véhicule réparé", 'success')
        
    elseif action == "clean" then
        SetVehicleDirtLevel(vehicle, 0.0)
        ShowNotification("Véhicule nettoyé", 'success')
        
    elseif action == "fuel" then
        SetVehicleFuelLevel(vehicle, 100.0)
        ShowNotification("Réservoir rempli", 'success')
        
    elseif action == "givekeys" then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('ContextMenu:giveVehicleKeys', plate)
    end
end)