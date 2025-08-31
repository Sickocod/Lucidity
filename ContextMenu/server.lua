-- server.lua - Version Optimisée

-- Vérification des permissions admin
function IsPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    return IsPlayerAceAllowed(source, "admin") or 
           (xPlayer.getGroup() == "admin") or
           (xPlayer.getGroup() == "superadmin")
end

-- Logs sécurisés
function LogAction(source, action, target, details)
    local xPlayer = ESX.GetPlayerFromId(source)
    local playerName = xPlayer and xPlayer.getName() or "Inconnu"
    local identifier = xPlayer and xPlayer.getIdentifier() or "Inconnu"
    
    print(string.format("[ContextMenu] %s (%s) a utilisé: %s sur %s - %s", 
          playerName, identifier, action, target or "N/A", details or ""))
end

-- Callback pour vérifier les permissions admin
ESX.RegisterServerCallback('ContextMenu:isPlayerAdmin', function(source, cb)
    cb(IsPlayerAdmin(source))
end)

-- Callback pour récupérer les données d'un joueur
ESX.RegisterServerCallback('ContextMenu:getPlayerData', function(source, cb, targetId)
    if not targetId then
        cb(nil)
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        cb({
            job = xTarget.job,
            money = xTarget.getMoney(),
            name = xTarget.getName(),
            group = xTarget.getGroup()
        })
    else
        cb(nil)
    end
end)

-- Actions administratives sur les joueurs
RegisterNetEvent('ContextMenu:adminAction')
AddEventHandler('ContextMenu:adminAction', function(action, targetId, entityHandle)
    local source = source
    
    -- Vérification admin
    if not IsPlayerAdmin(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Accès refusé',
            type = 'error'
        })
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Joueur introuvable',
            type = 'error'
        })
        return
    end
    
    LogAction(source, action, targetId, xTarget.getName())
    
    if action == "heal" then
        TriggerClientEvent('ContextMenu:heal', targetId)
        
    elseif action == "needs" then
        TriggerClientEvent('esx_status:set', targetId, 'hunger', 1000000)
        TriggerClientEvent('esx_status:set', targetId, 'thirst', 1000000)
        
    elseif action == "revive" then
        TriggerClientEvent('ContextMenu:revive', targetId)
        
    elseif action == "bring" then
        local adminCoords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent('ContextMenu:teleport', targetId, adminCoords)
        
    elseif action == "goto" then
        local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
        TriggerClientEvent('ContextMenu:teleport', source, targetCoords)
    end
    
    -- Notification admin
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Action effectuée',
        description = 'Action "' .. action .. '" sur ' .. xTarget.getName(),
        type = 'success'
    })
end)

-- Changement de métier
RegisterNetEvent('ContextMenu:setPlayerJob')
AddEventHandler('ContextMenu:setPlayerJob', function(targetId, jobName)
    local source = source
    
    if not IsPlayerAdmin(source) then return end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    xTarget.setJob(jobName, 0)
    
    LogAction(source, "setjob", targetId, jobName)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Métier changé',
        description = xTarget.getName() .. ' est maintenant ' .. jobName,
        type = 'success'
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Nouveau métier',
        description = 'Votre métier a été changé en ' .. jobName,
        type = 'inform'
    })
end)

-- Actions sur véhicules
RegisterNetEvent('ContextMenu:vehicleAction')
AddEventHandler('ContextMenu:vehicleAction', function(action, vehicleNetId)
    local source = source
    
    if not IsPlayerAdmin(source) then return end
    
    LogAction(source, "vehicle_" .. action, vehicleNetId)
    TriggerClientEvent('ContextMenu:executeVehicleAction', source, action, vehicleNetId)
end)

-- Supprimer entité
RegisterNetEvent('ContextMenu:deleteEntity')
AddEventHandler('ContextMenu:deleteEntity', function(entityNetId)
    local source = source
    
    if not IsPlayerAdmin(source) then return end
    
    LogAction(source, "delete_entity", entityNetId)
    TriggerClientEvent('ContextMenu:deleteEntityClient', -1, entityNetId)
end)

-- Fouiller un joueur (Police/Sherif)
RegisterNetEvent('ContextMenu:searchPlayer')
AddEventHandler('ContextMenu:searchPlayer', function(targetId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or (xPlayer.job.name ~= 'police' and xPlayer.job.name ~= 'sherif') then
        return
    end
    
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    -- Ouvre l'inventaire du joueur ciblé
    exports.ox_inventory:forceOpenInventory(source, 'player', targetId)
    
    LogAction(source, "search", targetId, xTarget.getName())
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Fouille',
        description = 'Vous êtes en cours de fouille par ' .. xPlayer.getName(),
        type = 'inform'
    })
end)

-- Système de backup
RegisterNetEvent('ContextMenu:SendBackup')
AddEventHandler('ContextMenu:SendBackup', function(jobName, level, message, coords, priority, playerId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.job.name ~= jobName then return end
    
    -- Envoie l'alerte aux joueurs du même job
    local players = ESX.GetPlayers()
    for _, id in ipairs(players) do
        local xTarget = ESX.GetPlayerFromId(id)
        if xTarget and xTarget.job.name == jobName and id ~= source then
            TriggerClientEvent('ContextMenu:receiveBackup', id, {
                level = level,
                message = message,
                coords = coords,
                priority = priority,
                sender = xPlayer.getName(),
                senderId = playerId
            })
        end
    end
    
    LogAction(source, "backup_" .. jobName, level, message)
end)

-- Verrouillage véhicule
RegisterNetEvent('ContextMenu:toggleVehicleLock')
AddEventHandler('ContextMenu:toggleVehicleLock', function(vehicleNetId)
    local source = source
    TriggerClientEvent('ContextMenu:toggleLock', source, vehicleNetId)
end)

-- Donner les clés d'un véhicule (Admin)
RegisterNetEvent('ContextMenu:giveVehicleKeys')
AddEventHandler('ContextMenu:giveVehicleKeys', function(plate)
    local source = source
    
    if not IsPlayerAdmin(source) then return end
    
    -- Donne les clés via ox_inventory
    exports.ox_inventory:AddItem(source, 'keys', 1, {
        plate = plate,
        model = 'vehicle'
    })
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Clés reçues',
        description = 'Clés du véhicule ' .. plate .. ' ajoutées',
        type = 'success'
    })
    
    LogAction(source, "give_keys", plate)
end)

-- Commands utiles
ESX.RegisterCommand('contextmenu', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('ox_lib:notify', xPlayer.source, {
        title = 'Context Menu',
        description = 'Maintenez ALT + Clic droit pour ouvrir le menu contextuel',
        type = 'inform'
    })
end, false, {help = 'Aide pour le context menu'})

-- Commande pour réinitialiser les caches
ESX.RegisterCommand('resetcache', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('ContextMenu:resetCache', -1)
    TriggerClientEvent('ox_lib:notify', xPlayer.source, {
        title = 'Cache réinitialisé',
        description = 'Le cache du context menu a été réinitialisé',
        type = 'success'
    })
end, false, {help = 'Réinitialise le cache du context menu'})

print("^2[ContextMenu]^0 Script serveur chargé avec succès!")