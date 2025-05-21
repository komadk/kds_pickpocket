local ESX = exports["es_extended"]:getSharedObject()
local isPickpocketing = false
local currentTarget = nil

-- Load sound (simplified to avoid RegisterSoundId which doesn't exist)
CreateThread(function()
    local soundFile = Config.Sounds.pickpocket.file
    local soundName = Config.Sounds.pickpocket.name
    
    -- Just request audio bank without using RegisterSoundId which doesn't exist
    RequestScriptAudioBank("GENERIC_SOUNDS", false)
end)

-- Check if player is behind a ped
local function isPlayerBehindPed(ped)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(ped)
    
    local targetHeading = GetEntityHeading(ped)
    local playerToTargetAngle = GetHeadingFromVector_2d(targetCoords.x - playerCoords.x, targetCoords.y - playerCoords.y)
    
    local angleDiff = math.abs((targetHeading - playerToTargetAngle + 180) % 360 - 180)
    
    return angleDiff < 45
end

-- Check if player is close enough to a ped
local function isPlayerCloseEnough(ped)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(ped)
    
    local distance = #(playerCoords - targetCoords)
    
    return distance <= Config.PickpocketMaxDistance
end

-- Check if enough police are online
local function isEnoughPoliceOnline()
    if not Config.CheckForPolice then return true end
    
    -- Call server side event to check police count and wait for response
    local policeCount = 0
    local countReceived = false
    
    TriggerServerEvent('kds_pickpocket:server:checkPoliceCount')
    
    RegisterNetEvent('kds_pickpocket:client:policeCountResult')
    AddEventHandler('kds_pickpocket:client:policeCountResult', function(count)
        policeCount = count
        countReceived = true
    end)
    
    -- Wait for the response (with timeout)
    local timeout = 1000 -- 1 second timeout
    local start = GetGameTimer()
    while not countReceived and GetGameTimer() - start < timeout do
        Wait(10)
    end
    
    return policeCount >= Config.MinPoliceCount
end

-- Get a random item from the loot table
local function getRandomLoot()
    local possibleItems = {}
    
    for _, item in ipairs(Config.Items) do
        if math.random(100) <= item.chance then
            table.insert(possibleItems, item)
        end
    end
    
    if #possibleItems > 0 then
        local selectedItem = possibleItems[math.random(#possibleItems)]
        local amount = math.random(selectedItem.min, selectedItem.max)
        
        return {
            name = selectedItem.name,
            amount = amount
        }
    end
    
    return nil
end

-- Improved handle ped reaction function
local function handlePedReaction(ped)
    local reaction = math.random(100)
    local totalChance = 0
    
    -- Run away reaction
    totalChance = totalChance + Config.Chances.runAway
    if reaction <= totalChance then
        ClearPedTasks(ped)
        TaskSmartFleePed(ped, PlayerPedId(), 100.0, -1, true, true)
        lib.notify({
            title = Config.TargetLabel,
            description = Config.Texts.npcFled,
            type = 'info'
        })
        return
    end
    
    -- Fight reaction
    totalChance = totalChance + Config.Chances.fight
    if reaction <= totalChance then
        ClearPedTasks(ped)
        -- Make NPC aggressive and attack player
        SetPedCombatAttributes(ped, 46, true)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
        SetPedKeepTask(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, false)
        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 17, true)
        
        lib.notify({
            title = Config.TargetLabel,
            description = Config.Texts.npcFighting,
            type = 'error'
        })
        return
    end
    
    -- Default: Nothing happens (undetected)
    lib.notify({
        title = Config.TargetLabel,
        description = Config.Texts.stealSuccess,
        type = 'success'
    })
end

-- Start pickpocketing
local function startPickpocketing(ped)
    if isPickpocketing then return end
    
    -- Checks before pickpocketing
    if not isPlayerBehindPed(ped) then
        lib.notify({
            title = Config.TargetLabel,
            description = Config.Texts.tooFar,
            type = 'error'
        })
        return
    end
    
    if Config.CheckForPolice then
        -- Using server callback instead of direct check
        TriggerServerEvent('kds_pickpocket:server:checkPoliceCount')
        
        local policeCount = 0
        local countReceived = false
        
        RegisterNetEvent('kds_pickpocket:client:policeCountResult', function(count)
            policeCount = count
            countReceived = true
        end)
        
        -- Wait for the response (with timeout)
        local timeout = 1000 -- 1 second timeout
        local start = GetGameTimer()
        while not countReceived and GetGameTimer() - start < timeout do
            Wait(10)
        end
        
        if policeCount < Config.MinPoliceCount then
            lib.notify({
                title = Config.TargetLabel,
                description = Config.Texts.noPolice,
                type = 'error'
            })
            return
        end
    end
    
    isPickpocketing = true
    currentTarget = ped
    
    -- Play sound
    PlaySoundFrontend(-1, "Grab_Possession", "ROBBERY_MONEY_GRAB", 1)
    
    -- Start progress circle
    if lib.progressCircle(Config.Progress) then
        -- Progress completed successfully
        TriggerServerEvent('kds_pickpocket:server:pickpocketSuccess')
        
        -- Handle ped reaction
        handlePedReaction(ped)
    else
        -- Progress was cancelled
        lib.notify({
            title = Config.TargetLabel,
            description = Config.Texts.cancelledPickpocketing,
            type = 'info'
        })
    end
    
    isPickpocketing = false
    currentTarget = nil
end

-- Register target options if ox_target is enabled
if Config.UseOxTarget then
    exports.ox_target:addGlobalPed({
        {
            name = 'kds_pickpocket:pickpocket',
            icon = 'fas fa-hand-holding-dollar',
            label = Config.TargetLabel,
            canInteract = function(entity, distance, coords, name)
                if IsPedAPlayer(entity) then return false end
                if IsPedInAnyVehicle(entity, true) then return false end
                if IsPedDeadOrDying(entity, true) then return false end
                if distance > Config.PickpocketMaxDistance then return false end
                if not isPlayerBehindPed(entity) then return false end
                
                return true
            end,
            onSelect = function(data)
                startPickpocketing(data.entity)
            end
        }
    })
end

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    if Config.UseOxTarget then
        exports.ox_target:removeGlobalPed('kds_pickpocket:pickpocket')
    end
end)

-- Helper function to check if value exists in table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end 