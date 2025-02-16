-- server/server.lua
-- Handles reward processing, rate limiting, and trial (lockout) system.
if not _G.Framework then error("Framework not loaded!") end
local Framework = _G.Framework

local operationCount = {}  -- Timestamps of successful operations per player
local trialData = {}       -- Lockout expiry per player

RegisterNetEvent('postboxThief:server:Reward', function(skillSuccess)
    local src = source
    local currentTime = os.time()

    if not skillSuccess then
        TriggerClientEvent('postboxThief:client:RewardResult', src, false)
        return
    end

    -- Rate Limiting: Count successful operations within the RateLimitWindow.
    operationCount[src] = operationCount[src] or {}
    for i = #operationCount[src], 1, -1 do
        if currentTime - operationCount[src][i] > Config.RateLimitWindow then
            table.remove(operationCount[src], i)
        end
    end
    table.insert(operationCount[src], currentTime)
    if #operationCount[src] > Config.OperationLimit then
        Framework.handleExploit(src, "Too many successful operations in a short time")
        return
    end

    -- Trial system: Allow only one successful attempt per lockout period.
    trialData[src] = trialData[src] or { lockoutExpiry = 0 }
    if currentTime < trialData[src].lockoutExpiry then
        local remaining = trialData[src].lockoutExpiry - currentTime
        TriggerClientEvent('postboxThief:client:Lockout', src, remaining)
        return
    end
    trialData[src].lockoutExpiry = currentTime + Config.LockoutDuration

    local Player = Framework.GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.job and Config.BlacklistedJobs[Player.PlayerData.job.name] then
        return
    end

    pcall(function()
        if math.random() <= Config.PoliceAlertChance then
            exports['ps-dispatch']:SuspiciousActivity()
        end
    end)

    -- Process rewards for both money and item if applicable.
    if Config.RewardType == "money" or Config.RewardType == "both" then
        local cashAmount = math.random(Config.RewardCash.min, Config.RewardCash.max)
        if Player then
            Player.Functions.AddMoney("cash", cashAmount)
            TriggerClientEvent('postboxThief:client:RewardCash', src, cashAmount)
        end
    end
    if Config.RewardType == "item" or Config.RewardType == "both" then
        local rewards = Config.RewardItems
        if rewards and #rewards > 0 then
            local rewardData = rewards[math.random(#rewards)]
            local itemName = rewardData.item
            local count = math.random(rewardData.min, rewardData.max)
            if Player then
                local added = Player.Functions.AddItem(itemName, count)
                if added then
                    TriggerClientEvent('postboxThief:client:RewardItem', src, itemName, count)
                end
            end
        end
    end

    TriggerClientEvent('postboxThief:client:RewardResult', src, true)
end)
