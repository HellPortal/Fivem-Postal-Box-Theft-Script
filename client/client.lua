-- client/client.lua
-- Handles player interaction and displays progress circle above the target.
if not _G.Framework then error("Framework not loaded!") end
local Framework = _G.Framework

local cache = {}
Citizen.CreateThread(function()
    while true do
        cache.ped = PlayerPedId()
        Wait(1000)
    end
end)

lib.callback.register('postboxThief:client:getZoneName', function(coords)
    return GetNameOfZone(coords.x, coords.y, coords.z)
end)

-- DrawText3D draws text at a given world coordinate.
local function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(0, 255, 0, 215)  -- green
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(screenX, screenY)
end

local showPersistentText = false
local persistentTextCoords = nil  -- expected as {x, y, z}
local lastInteractionTime = 0
local theftActive = false
local notified = false  -- flag to prevent duplicate notifications

local MAX_DISTANCE = 5.0  -- Maximum allowed distance from the target

Citizen.CreateThread(function()
    while true do
        if showPersistentText and persistentTextCoords then
            local playerPos = GetEntityCoords(PlayerPedId())
            local targetPos = vec3(persistentTextCoords[1], persistentTextCoords[2], persistentTextCoords[3])
            local dist = #(playerPos - targetPos)
            if dist <= MAX_DISTANCE then
                DrawText3D(persistentTextCoords[1], persistentTextCoords[2], persistentTextCoords[3] + 1.0, "Press E to start theft")
            else
                if not notified then
                    Framework.DoNotification("You moved too far away. Theft failed.", "error")
                    notified = true
                end
                showPersistentText = false
                theftActive = false
            end
            if (GetGameTimer() - lastInteractionTime) > 60000 then
                if not notified then
                    Framework.DoNotification("You are locked out. Please try again in 60 seconds.", "error")
                    notified = true
                end
                showPersistentText = false
                break
            end
        end
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
    exports.ox_target:addModel(Config.MailboxModels, {
        {
            event = "postboxThief:stealMail",
            icon = "fas fa-envelope",
            label = "Steal from Postbox",
            distance = 2.0,
        }
    })
end)

RegisterNetEvent("postboxThief:stealMail", function(targetCoords)
    if theftActive then return end
    theftActive = true
    notified = false  -- Reset notification flag for this attempt

    if targetCoords and targetCoords.x and targetCoords.y and targetCoords.z then
        persistentTextCoords = { targetCoords.x, targetCoords.y, targetCoords.z }
    else
        local pos = GetEntityCoords(cache.ped)
        persistentTextCoords = { pos.x, pos.y, pos.z }
    end

    local playerJob = "unknown"
    if exports['qb-core'] then
        local PlayerData = exports['qb-core']:GetCoreObject().Functions.GetPlayerData()
        if PlayerData and PlayerData.job then
            playerJob = PlayerData.job.name
        end
    end
    if Config.BlacklistedJobs[playerJob] then
        Framework.DoNotification("You cannot perform this action with your current job.", "error")
        theftActive = false
        return
    end

    local skillSuccess = lib.skillCheck({"easy", "easy", "medium"}, {"w", "a", "s", "d"})
    if skillSuccess then
        showPersistentText = true
        lastInteractionTime = GetGameTimer()
        Framework.DoNotification("Press E to start theft", "inform")
        
        Citizen.CreateThread(function()
            local startTime = GetGameTimer()
            while (GetGameTimer() - startTime) < 60000 do
                local playerPos = GetEntityCoords(PlayerPedId())
                local targetPos = vec3(persistentTextCoords[1], persistentTextCoords[2], persistentTextCoords[3])
                if #(playerPos - targetPos) > MAX_DISTANCE then
                    showPersistentText = false
                    if not notified then
                        Framework.DoNotification("You moved too far away. Theft failed.", "error")
                        notified = true
                    end
                    theftActive = false
                    return
                end
                if IsControlJustPressed(0, 38) then -- E key
                    break
                end
                Citizen.Wait(0)
            end
            if (GetGameTimer() - startTime) >= 60000 then
                showPersistentText = false
                if not notified then
                    Framework.DoNotification("You are locked out. Please try again in 60 seconds.", "error")
                    notified = true
                end
                theftActive = false
                return
            end
            showPersistentText = false
            Framework.DoNotification("Theft in progress...", "inform")
            if lib.progressCircle({
                duration = Config.MiniGameDuration,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    sprint = true,
                    combat = true,
                    car = true,
                },
                anim = {
                    dict = "anim@amb@nightclub@mini@drinking@drinking_shots@ped_a@drunk@heeled@",
                    clip = "pickup",
                },
            }) then
                TriggerServerEvent("postboxThief:server:Reward", skillSuccess)
            else
                Framework.DoNotification("Action cancelled!", "error")
            end
            theftActive = false
        end)
    else
        Framework.DoNotification("Theft failed!", "error")
        theftActive = false
    end
end)

RegisterNetEvent("postboxThief:client:RewardItem", function(itemName, count)
    Framework.DoNotification("You stole " .. count .. " x " .. itemName .. " from the postbox!", "success")
end)

RegisterNetEvent("postboxThief:client:RewardCash", function(amount)
    Framework.DoNotification("You stole $" .. amount .. "!", "success")
end)

RegisterNetEvent("postboxThief:client:Failed", function()
    Framework.DoNotification("The target caught you!", "error")
end)

RegisterNetEvent("postboxThief:client:RewardResult", function(success)
    if success then
        Framework.DoNotification("Postbox successfully robbed!", "success")
    else
        Framework.DoNotification("Theft failed!", "error")
    end
end)

RegisterNetEvent("postboxThief:client:Lockout", function(lockoutSeconds)
    Framework.DoNotification("You are locked out for " .. lockoutSeconds .. " seconds. Please try again later.", "error")
end)
