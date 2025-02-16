-- bridge/framework.lua
if not Config then error("Config not found!") end

local detectedFramework = nil
if GetResourceState('qbx_core') == 'started' then
    detectedFramework = "QBX"
elseif GetResourceState('es_extended') == 'started' then
    detectedFramework = "ESX"
elseif GetResourceState('qb-core') == 'started' then
    detectedFramework = "QBCore"
elseif lib and lib.checkDependency and lib.checkDependency('ND_Core', '2.0.0') then
    detectedFramework = "ND"
else
    error("No supported framework found!")
end

_G.Framework = {}
local Framework = _G.Framework

if detectedFramework == "QBX" then
    Framework.GetPlayer = function(id) return exports.qbx_core:GetPlayer(id) end
    if IsDuplicityVersion() then
        Framework.DoNotification = function(src, text, nType) exports.qbx_core:Notify(src, text, nType) end
    else
        Framework.DoNotification = function(text, nType) exports.qbx_core:Notify(text, nType) end
    end
    Framework.AddMoney = function(Player, moneyType, amount) Player.Functions.AddMoney(moneyType, amount, "postbox-thief") end
    Framework.handleExploit = function(id, reason) exports.qbx_core:ExploitBan(id, reason) end
    Framework.hasPlyLoaded = function() return LocalPlayer.state.isLoggedIn end

elseif detectedFramework == "ESX" then
    local ESX = exports['es_extended']:getSharedObject()
    Framework.GetPlayer = function(id) return ESX.GetPlayerFromId(id) end
    if IsDuplicityVersion() then
        Framework.DoNotification = function(src, text, nType) TriggerClientEvent('esx:showNotification', src, text, nType) end
    else
        Framework.DoNotification = function(text, nType) ESX.ShowNotification(text, nType) end
    end
    Framework.AddMoney = function(Player, moneyType, amount)
        local account = (moneyType == 'cash') and 'money' or moneyType
        Player.addAccountMoney(account, amount, "postbox-thief")
    end
    Framework.handleExploit = function(id, reason) DropPlayer(id, 'You were dropped for exploiting.') end
    Framework.hasPlyLoaded = function() return true end

elseif detectedFramework == "QBCore" then
    local QBCore = exports['qb-core']:GetCoreObject()
    Framework.GetPlayer = function(id) return QBCore.Functions.GetPlayer(id) end
    Framework.DoNotification = function(src, text, nType) TriggerClientEvent('QBCore:Notify', src, text, nType) end
    Framework.AddMoney = function(Player, moneyType, amount) Player.Functions.AddMoney(moneyType, amount, "postbox-thief") end
    Framework.handleExploit = function(id, reason) DropPlayer(id, 'You were banned for exploiting.') end
    Framework.hasPlyLoaded = function() return LocalPlayer.state.isLoggedIn end

elseif detectedFramework == "ND" then
    NDCore = {}
    lib.load('@ND_Core.init')
    Framework.GetPlayer = function(id) return NDCore.getPlayer(id) end
    Framework.DoNotification = function(src, text, nType) TriggerClientEvent('ox_lib:notify', src, { type = nType, description = text }) end
    Framework.AddMoney = function(Player, moneyType, amount) Player.addMoney(moneyType, amount) end
    Framework.handleExploit = function(id, reason) DropPlayer(id, 'You were dropped for exploiting.') end
    Framework.hasPlyLoaded = function() return LocalPlayer.state.isLoggedIn end
end
