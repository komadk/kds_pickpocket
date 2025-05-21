local ESX = exports["es_extended"]:getSharedObject()
local ox_inventory = exports.ox_inventory

-- Get police count
local function getPoliceCount()
    local policeCount = 0
    local xPlayers = ESX.GetPlayers()
    
    for i=1, #xPlayers do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer and table.contains(Config.PoliceJobs, xPlayer.job.name) then
            policeCount = policeCount + 1
        end
    end
    
    return policeCount
end

-- Event to check police count and send result back to client
RegisterNetEvent('kds_pickpocket:server:checkPoliceCount')
AddEventHandler('kds_pickpocket:server:checkPoliceCount', function()
    local src = source
    local count = getPoliceCount()
    
    TriggerClientEvent('kds_pickpocket:client:policeCountResult', src, count)
end)

-- Get random loot based on configuration
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

-- Handle successful pickpocketing
RegisterNetEvent('kds_pickpocket:server:pickpocketSuccess')
AddEventHandler('kds_pickpocket:server:pickpocketSuccess', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    -- Chance to find nothing
    if math.random(100) <= 20 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.TargetLabel,
            description = Config.Texts.stealFailed,
            type = 'error'
        })
        return
    end
    
    -- Get random loot
    local loot = getRandomLoot()
    
    if not loot then
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.TargetLabel,
            description = Config.Texts.stealFailed,
            type = 'error'
        })
        return
    end
    
    -- Special handling for money
    if loot.name == 'money' then
        xPlayer.addMoney(loot.amount)
        TriggerClientEvent('ox_lib:notify', src, {
            title = Config.TargetLabel,
            description = Config.Texts.stealSuccess .. ' (' .. loot.amount .. ' DKK)',
            type = 'success'
        })
    else
        -- Add item to inventory using ox_inventory
        local canCarry = ox_inventory:CanCarryItem(src, loot.name, loot.amount)
        
        if canCarry then
            if ox_inventory:AddItem(src, loot.name, loot.amount) then
                TriggerClientEvent('ox_lib:notify', src, {
                    title = Config.TargetLabel,
                    description = Config.Texts.stealSuccess,
                    type = 'success'
                })
            else
                TriggerClientEvent('ox_lib:notify', src, {
                    title = Config.TargetLabel,
                    description = Config.Texts.stealFailed,
                    type = 'error'
                })
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = Config.TargetLabel,
                description = 'Din lomme er fuld',
                type = 'error'
            })
        end
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