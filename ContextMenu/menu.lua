-- menu.lua - Version Optimisée avec Système de Backup
local PlayerData = {}
local showPlayerInfo = true -- Variable pour la checkbox admin

-- Cache pour éviter les appels répétés
local adminCache = {}
local lastAdminCheck = 0
local ADMIN_CHECK_INTERVAL = 5000 -- 5 secondes

Citizen.CreateThread(function()
    while not ESX.GetPlayerData().job do
        Citizen.Wait(100)
    end
    
    PlayerData = ESX.GetPlayerData()
    
    -- Event pour mettre à jour les données joueur
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
    end)

    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        PlayerData.job = job
    end)
end)

-- Configuration optimisée
Config = {
    isDebug = false, -- Désactivé en production
    jobs = {
        {name = "police", label = "👮 Police", emoji = "👮"},
        {name = "ambulance", label = "👨‍⚕️ Ambulancier", emoji = "👨‍⚕️"},
        {name = "sherif", label = "🤠 Shérif", emoji = "🤠"},
        {name = "mechanic", label = "🔧 Mécanicien", emoji = "🔧"},
        {name = "concess", label = "🚗 Concessionnaire", emoji = "🚗"},
        {name = "unemployed", label = "Sans emploi", emoji = ""}
    },
    -- Configuration du système de backup
    backupLevels = {
        {
            id = 1,
            name = "😅 Backup: Niveau 1",
            description = "Un agent a besoin d'aide !",
            priority = false,
            color = "^2" -- Vert
        },
        {
            id = 2,
            name = "🤨 Backup: Niveau 2", 
            description = "Un agent a besoin d'aide importante !",
            priority = false,
            color = "^3" -- Jaune
        },
        {
            id = 3,
            name = "😰 Backup: Niveau 3",
            description = "Un agent a besoin d'aide de TOUTE URGENCE !",
            priority = true,
            color = "^1" -- Rouge
        }
    },
    -- Jobs autorisés à utiliser le backup
    backupJobs = {
        "police",
        "sherif", 
        "ambulance"
    },
    weathers = {"Clear", "Extrasunny", "Clouds", "Overcast", "Rain", "Clearing", "Thunder", "Smog", "Foggy", "Xmas", "Snowlight", "Blizzard"},
    times = {
        {"🌅 Matin", 8},
        {"☀️ Après-midi", 14},
        {"🌆 Soirée", 18},
        {"🌙 Nuit", 22}
    },
    adminActions = {
        player = {
            {"💉 Soigner", "heal"},
            {"🍔 Faim/Soif MAX", "needs"},
            {"💊 Réanimer", "revive"},
            {"🚀 Téléporter vers moi", "bring"},
            {"🌟 Aller vers le joueur", "goto"}
        },
        vehicle = {
            {"🧰 Réparer", "repair"},
            {"🧽 Nettoyer", "clean"},
            {"⛽ Faire le plein", "fuel"},
            {"🔑 Donner les clés", "givekeys"}
        }
    }
}

-- Utility Functions optimisées
function Log(text)
    if Config.isDebug then
        print("[ContextMenu] " .. tostring(text))
    end
end

function IsPlayerAdmin()
    local currentTime = GetGameTimer()
    local playerId = PlayerId()
    
    -- Cache admin check pour éviter les appels répétés
    if adminCache[playerId] and (currentTime - lastAdminCheck) < ADMIN_CHECK_INTERVAL then
        return adminCache[playerId]
    end
    
    -- Vérification côté client basée sur les données ESX
    local isAdmin = (PlayerData.group and (
        PlayerData.group == "admin" or 
        PlayerData.group == "superadmin" or 
        PlayerData.group == "mod"
    ))
    
    -- Vérification supplémentaire via callback serveur (asynchrone)
    if not adminCache[playerId] then
        ESX.TriggerServerCallback('ContextMenu:isPlayerAdmin', function(serverAdmin)
            adminCache[playerId] = serverAdmin
        end)
    end
    
    adminCache[playerId] = isAdmin
    lastAdminCheck = currentTime
    
    return isAdmin
end

function ShowNotification(message, type)
    type = type or 'inform'
    
    -- Utilise ox_lib si disponible, sinon ESX
    if exports.ox_lib then
        exports.ox_lib:notify({
            title = 'Context Menu',
            description = message,
            type = type
        })
    else
        ESX.ShowNotification(message)
    end
end

function GetJobLabel(jobName)
    for _, job in ipairs(Config.jobs) do
        if job.name == jobName then
            return job.label
        end
    end
    return "Inconnu"
end

function CanUseBackup(jobName)
    for _, allowedJob in ipairs(Config.backupJobs) do
        if allowedJob == jobName then
            return true
        end
    end
    return false
end

-- Menu System optimisé
local menuPool = MenuPool()
local currentMenus = {}
local currentContextMenu = nil
local lastMenuTime = 0
local MENU_COOLDOWN = 300 -- 300ms de cooldown entre les menus

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        menuPool:Process(function(screenPosition, hitSomething, worldPosition, hitEntityHandle, normalDirection)
            local currentTime = GetGameTimer()
            
            -- Cooldown pour éviter le spam de menus
            if currentTime - lastMenuTime < MENU_COOLDOWN then
                return
            end
            
            -- Ferme le menu actuel avant d'en créer un nouveau
            if currentContextMenu then
                currentContextMenu:Visible(false)
                currentContextMenu = nil
            end
            
            -- Ferme tous les menus ouverts
            menuPool:CloseAllMenus()
            
            -- Nettoie les anciens menus
            CleanupMenus()
            
            -- Crée le nouveau menu
            CreateContextMenu(screenPosition, worldPosition, hitEntityHandle)
            
            lastMenuTime = currentTime
        end)
    end
end)

function CleanupMenus()
    -- Ferme tous les menus visibles
    menuPool:CloseAllMenus()
    
    -- Limite le nombre de menus en mémoire
    if #currentMenus > 3 then -- Réduit le nombre pour plus de fluidité
        for i = 1, #currentMenus - 3 do
            if currentMenus[i] then
                currentMenus[i]:Visible(false)
                table.remove(currentMenus, i)
            end
        end
    end
end

-- Système de Backup Optimisé
function CreateBackupMenu(parentMenu, jobName)
    if not CanUseBackup(jobName) then
        Log("Job " .. tostring(jobName) .. " non autorisé pour le backup")
        return nil
    end

    local backupMenu = menuPool:AddSubmenu(parentMenu, "💪 Demande de Backup")
    
    for _, level in ipairs(Config.backupLevels) do
        local item = backupMenu:AddItem(level.name)
        item.OnClick = function()
            SendBackupRequest(jobName, level)
        end
    end
    
    return backupMenu
end

function SendBackupRequest(jobName, level)
    -- Vérification que le joueur a toujours le bon job
    if not PlayerData.job or PlayerData.job.name ~= jobName then
        ShowNotification("Vous n'avez plus accès à cette fonction", 'error')
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local playerId = GetPlayerServerId(PlayerId())
    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    
    -- Données à envoyer au système de dispatch
    local backupData = {
        jobName = jobName,
        level = level.id,
        title = level.name,
        description = level.description,
        coords = coords,
        priority = level.priority,
        playerId = playerId,
        streetName = streetName,
        timestamp = GetGameTimer()
    }
    
    -- Envoi au système op-dispatch
    TriggerServerEvent('Opto_dispatch:Server:SendAlert', jobName, level.name, level.description, coords, level.priority, playerId)
    
    -- Notification locale
    ShowNotification(level.color .. level.name .. "^0 envoyée !", 'success')
    
    -- Animation du joueur
    ExecuteCommand('me demande du backup via radio')
    
    -- Log pour debug
    Log("Backup envoyé: " .. level.name .. " pour " .. jobName .. " par ID " .. playerId)
end

function CreatePlayerInfoCheckbox(adminMenu)
    -- Version simplifiée sans checkbox si le système ne supporte pas
    local statusText = showPlayerInfo and "👁️ Masquer Info Joueurs" or "👁️ Afficher Info Joueurs"
    local toggleItem = adminMenu:AddItem(statusText)
    
    toggleItem.OnClick = function()
        showPlayerInfo = not showPlayerInfo
        -- Met à jour le texte de l'item
        toggleItem.text = showPlayerInfo and "👁️ Masquer Info Joueurs" or "👁️ Afficher Info Joueurs"
        ShowNotification("Affichage des infos joueurs: " .. (showPlayerInfo and "Activé" or "Désactivé"))
    end
    
    return toggleItem
end

function CreateContextMenu(screenPosition, worldPosition, hitEntityHandle)
    -- Ferme le menu précédent s'il existe
    if currentContextMenu then
        currentContextMenu:Visible(false)
    end
    
    local contextMenu = menuPool:AddMenu()
    currentContextMenu = contextMenu -- Stocke la référence du menu actuel
    table.insert(currentMenus, contextMenu)

    if hitEntityHandle and DoesEntityExist(hitEntityHandle) then
        
        -- === JOUEUR ===
        if IsPedAPlayer(hitEntityHandle) then
            local targetPlayerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(hitEntityHandle))
            
            -- Affiche les infos seulement si activé (pour les admins)
            if not IsPlayerAdmin() or showPlayerInfo then
                contextMenu:AddItem("🆔 ID: ~b~" .. targetPlayerId)
            end
            
            -- Menu informations
            local infoMenu = menuPool:AddSubmenu(contextMenu, "📋 Informations")
            local jobItem = infoMenu:AddItem("💼 Métier: ~y~Chargement...")
            
            -- Callback optimisé avec l'ancienne méthode mais améliorée
            ESX.TriggerServerCallback('getPlayerData', function(data)
                if data and data.job and data.job.label then
                    jobItem.text = "💼 Métier: ~b~" .. data.job.label
                else
                    jobItem.text = "💼 Métier: ~r~Inconnu"
                    -- Solution de secours si c'est le joueur local
                    if targetPlayerId == GetPlayerServerId(PlayerId()) and PlayerData.job then
                        jobItem.text = "💼 Métier: ~b~" .. (PlayerData.job.label or GetJobLabel(PlayerData.job.name))
                    end
                end
            end, targetPlayerId)
            
            -- Actions admin
            if IsPlayerAdmin() then
                local adminMenu = menuPool:AddSubmenu(contextMenu, "💎 Actions Admin")
                
                -- Checkbox pour afficher/masquer les infos
                CreatePlayerInfoCheckbox(adminMenu)
                
                -- Actions sur le joueur
                for _, action in ipairs(Config.adminActions.player) do
                    local item = adminMenu:AddItem(action[1])
                    item.OnClick = function()
                        TriggerServerEvent('ContextMenu:adminAction', action[2], targetPlayerId, hitEntityHandle)
                    end
                end
                
                -- Menu changement de métier
                local jobMenu = menuPool:AddSubmenu(adminMenu, "💼 Changer métier")
                for _, job in ipairs(Config.jobs) do
                    local jobItem = jobMenu:AddItem(job.label)
                    jobItem.OnClick = function()
                        TriggerServerEvent('esx:setJob', targetPlayerId, job.name, 0)
                        ShowNotification("Métier changé: " .. job.label)
                    end
                end
            end
            
            -- Actions spécifiques aux métiers avec système de backup
            CreateJobSpecificMenus(contextMenu, targetPlayerId, hitEntityHandle)
            
        -- === VEHICULE ===
        elseif IsEntityAVehicle(hitEntityHandle) then
            CreateVehicleMenu(contextMenu, hitEntityHandle)
            
        -- === PED NPC ===
        elseif IsEntityAPed(hitEntityHandle) then
            if IsPlayerAdmin() then
                local deleteItem = contextMenu:AddItem("🗑️ Supprimer PED")
                deleteItem.OnClick = function()
                    SetEntityAsMissionEntity(hitEntityHandle)
                    DeleteEntity(hitEntityHandle)
                    ShowNotification("PED supprimé")
                end
            end
            
        -- === OBJET ===
        elseif IsEntityAnObject(hitEntityHandle) then
            if IsPlayerAdmin() then
                local deleteItem = contextMenu:AddItem("🗑️ Supprimer objet")
                deleteItem.OnClick = function()
                    SetEntityAsMissionEntity(hitEntityHandle)
                    DeleteEntity(hitEntityHandle)
                    ShowNotification("Objet supprimé")
                end
            end
        end
        
    else
        -- Menu dans le vide (admin uniquement)
        if IsPlayerAdmin() then
            CreateAdminWorldMenu(contextMenu, worldPosition)
        end
    end

    contextMenu:SetPosition(screenPosition)
    contextMenu:Visible(true)
end

function CreateJobSpecificMenus(contextMenu, targetPlayerId, hitEntityHandle)
    if not PlayerData.job then return end
    
    local jobName = PlayerData.job.name
    
    if jobName == 'ambulance' then
        local emsMenu = menuPool:AddSubmenu(contextMenu, "👨‍⚕️ E.M.S")
        CreateBackupMenu(emsMenu, 'ambulance')
        
    elseif jobName == 'police' or jobName == 'sherif' then
        local menuTitle = jobName == 'police' and "👮 Police" or "🤠 Shérif"
        local jobMenu = menuPool:AddSubmenu(contextMenu, menuTitle)
        
        -- Action fouiller (adaptée de l'ancienne version)
        local searchItem = jobMenu:AddItem("🔍 Fouiller")
        searchItem.OnClick = function()
            if DoesEntityExist(hitEntityHandle) and IsEntityAPed(hitEntityHandle) then
                -- Utilise ox_inventory si disponible
                if exports.ox_inventory then
                    exports.ox_inventory:openInventory('player', targetPlayerId)
                else
                    TriggerServerEvent('ContextMenu:searchPlayer', targetPlayerId)
                end
                ExecuteCommand('me fouille quelqu\'un')
            else
                ShowNotification("Impossible de fouiller cette personne", 'error')
            end
        end
        
        -- Système de backup intégré
        CreateBackupMenu(jobMenu, jobName)
        
    elseif jobName == 'mechanic' then
        local mechMenu = menuPool:AddSubmenu(contextMenu, "🔧 Mécanicien")
        local repairItem = mechMenu:AddItem("🔧 Proposer réparation")
        repairItem.OnClick = function()
            ShowNotification("Réparation proposée au joueur")
        end
    end
end

function CreateVehicleMenu(contextMenu, vehicle)
    -- Actions admin
    if IsPlayerAdmin() then
        local adminMenu = menuPool:AddSubmenu(contextMenu, "💎 Actions Admin")
        
        -- Actions véhicule simplifiées (reprises de l'ancienne version)
        local adminActions = {
            {"🗑️ Supprimer véhicule", function() 
                SetEntityAsMissionEntity(vehicle) 
                DeleteEntity(vehicle) 
                ShowNotification("Véhicule supprimé")
            end},
            {"🧰 Réparer", function() 
                SetEntityAsMissionEntity(vehicle) 
                SetVehicleFixed(vehicle) 
                ShowNotification("Véhicule réparé")
            end},
            {"🧽 Nettoyer", function() 
                SetEntityAsMissionEntity(vehicle) 
                SetVehicleDirtLevel(vehicle, 0.0) 
                ShowNotification("Véhicule nettoyé")
            end},
            {"⛽ Faire le plein", function() 
                SetEntityAsMissionEntity(vehicle) 
                SetVehicleFuelLevel(vehicle, 100.0) 
                ShowNotification("Réservoir plein")
            end},
            {"🔑 Se donner clés", function()
                local plate = GetVehicleNumberPlateText(vehicle)
                if plate then
                    TriggerServerEvent('ContextMenu:giveVehicleKeys', plate)
                    ShowNotification("Clés données")
                else
                    ShowNotification("Impossible de récupérer la plaque", 'error')
                end
            end}
        }
        
        for _, action in ipairs(adminActions) do
            local item = adminMenu:AddItem(action[1])
            item.OnClick = action[2]
        end
    end

    local ropeItem = contextMenu:AddItem("🪢 Cordes")
    ropeItem.OnClick = function()
       ExecuteCommand("tow") 
    end

    local engineMenu = menuPool:AddSubmenu(contextMenu, "⚙️ Moteur")
    local startItem = engineMenu:AddItem("✔️ Démarrer le moteur")
    startItem.OnClick = function()
        SetEntityAsMissionEntity(vehicle)
        SetVehicleEngineOn(vehicle, true, false, true)
        ShowNotification("Moteur démarré")
    end
    
    local stopItem = engineMenu:AddItem("❌ Éteindre le moteur")
    stopItem.OnClick = function()
        SetEntityAsMissionEntity(vehicle)
        SetVehicleEngineOn(vehicle, false, false, true)
        ShowNotification("Moteur éteint")
    end
    
    -- Menu portes (repris de l'ancienne version)
    CreateVehicleDoorMenu(contextMenu, vehicle)
    
    -- Ancre pour bateaux
    if IsThisModelABoat(GetEntityModel(vehicle)) then
        local anchorItem = contextMenu:AddItem("⚓ Jeter l'ancre")
        anchorItem.OnClick = function()
            SetBoatAnchor(vehicle, true)
            ShowNotification("Ancre jetée")
        end
    end
    
    -- Backup pour véhicules de police (repris de l'ancienne version)
    if PlayerData.job and PlayerData.job.name == 'police' then
        local model = GetEntityModel(vehicle)
        local vehicleClass = GetVehicleClass(vehicle)
        local isPoliceCar = IsVehicleModel(vehicle, GetHashKey("police")) or
            IsVehicleModel(vehicle, GetHashKey("police2")) or
            IsVehicleModel(vehicle, GetHashKey("police3")) or
            IsVehicleModel(vehicle, GetHashKey("police4")) or
            IsVehicleModel(vehicle, GetHashKey("fbi")) or
            IsVehicleModel(vehicle, GetHashKey("fbi2")) or
            (vehicleClass == 18)
            
        if isPoliceCar then
            CreateBackupMenu(menuPool:AddSubmenu(contextMenu, "👮 Police"), 'police')
        end
    end
end

function CreateVehicleDoorMenu(contextMenu, vehicle)
    local doorMenu = menuPool:AddSubmenu(contextMenu, "🚪 Gestionnaire des portes")
    
    -- Verrouillage (repris de l'ancienne version)
    local lockMenu = menuPool:AddSubmenu(doorMenu, "🔑 Vérouillage des portes")
    local lockItem = lockMenu:AddItem("🔒 Verrouiller/Déverrouiller les portes")
    lockItem.OnClick = function()
        local coords = GetEntityCoords(GetPlayerPed(-1))
        local closestVehicle, distance = ESX.Game.GetClosestVehicle(coords)
        if not closestVehicle or distance > 5.0 then
            ShowNotification('Aucun véhicule à proximité.', 'error')
            return
        end
        
        -- Vérification des clés
        local hasKeys = false
        if exports.ox_inventory then
            hasKeys = exports.ox_inventory:GetItemCount('keys', nil, false) > 0
        end
        
        if not hasKeys then
            ShowNotification('Vous n\'avez pas les clés de ce véhicule.', 'error')
            return
        end
        
        TriggerServerEvent('idev_keys:check', NetworkGetNetworkIdFromEntity(closestVehicle))
    end
    
    -- Contrôle des portes individuelles (repris de l'ancienne version)
    local doorCount = GetNumberOfVehicleDoors(vehicle)
    if doorCount > 0 then
        local doorControlMenu = menuPool:AddSubmenu(doorMenu, "🚪 Ouverture/Fermeture portes")
        for i = 1, doorCount do
            local doorItem = doorControlMenu:AddItem("Porte " .. i)
            doorItem.OnClick = function()
                local door = i - 1
                if GetVehicleDoorAngleRatio(vehicle, door) < 0.1 then
                    SetVehicleDoorOpen(vehicle, door, false, false)
                else
                    SetVehicleDoorShut(vehicle, door, false)
                end
            end
        end
    end
end

function CreateAdminWorldMenu(contextMenu, worldPosition)
    -- Téléportation
    local tpItem = contextMenu:AddItem("🌪️ Téléporter ici")
    tpItem.OnClick = function()
        SetEntityCoords(PlayerPedId(), worldPosition.x, worldPosition.y, worldPosition.z)
        ShowNotification("Téléporté!")
    end
    
    -- Menu météo
    local weatherMenu = menuPool:AddSubmenu(contextMenu, "⛅ Changer météo")
    for _, weather in ipairs(Config.weathers) do
        local weatherItem = weatherMenu:AddItem(weather)
        weatherItem.OnClick = function()
            SetWeatherTypeOvertimePersist(weather, 5.0)
            ShowNotification("Météo changée: " .. weather)
        end
    end
    
    -- Menu heure
    local timeMenu = menuPool:AddSubmenu(contextMenu, "🕒 Changer l'heure")
    for _, time in ipairs(Config.times) do
        local timeItem = timeMenu:AddItem(time[1])
        timeItem.OnClick = function()
            NetworkOverrideClockTime(time[2], 0, 0)
            ShowNotification("Heure changée: " .. time[1])
        end
    end
end

-- Nettoyage automatique des ressources
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        menuPool:CloseAllMenus()
        currentMenus = {}
        currentContextMenu = nil
        adminCache = {}
    end
end)

-- Event pour fermer le menu avec une touche (optionnel)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Ferme le menu avec Échap ou Retour arrière
        if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) then -- Échap ou Retour arrière
            if currentContextMenu and currentContextMenu:Visible() then
                currentContextMenu:Visible(false)
                currentContextMenu = nil
            end
        end
    end
end)