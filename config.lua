--[[
    Config.lua - Configuration file for Postbox Thief Script.
    Author: HellPortal

    Mini-game settings:
      - MiniGameDuration: Duration of the mini-game (progress circle) in milliseconds.

    Reward settings:
      - RewardCash: Cash reward range.
      - RewardItems: List of reward items (each with a minimum and maximum quantity).
      - RewardType: "money", "item", or "both" to determine which rewards are given.
      - Luck: If set to 0, rewards are always given; if set to 0.1, reward is given only if math.random() > 0.1 (~90% chance), etc.

    Target settings:
      - MailboxModels: Models used for mailbox interactions.

    Rate Limiting:
      - OperationLimit: Maximum number of successful operations allowed within the RateLimitWindow.
      - RateLimitWindow: Time window in seconds for rate limiting.

    Trial (Lockout) System:
      - MaxAttempts: Maximum successful attempts allowed before lockout (1 means a successful theft immediately triggers lockout).
      - LockoutDuration: Duration of the lockout period in seconds.

    Police Alert:
      - PoliceAlertChance: Chance (0 to 1.0) to trigger a police alert on a theft.

    Blacklisted Jobs:
      - Jobs that are not allowed to perform the theft.
--]]
Config = {}

Config.MiniGameDuration = 7000

Config.RewardCash = { min = 45, max = 90 }
Config.RewardItems = {
    { item = "water",    min = 1, max = 3 },
    { item = "sandwich", min = 1, max = 2 },
    { item = "phone",    min = 1, max = 1 }
}
Config.RewardType = "both"

Config.Luck = 0  -- 0 means always reward; 0.1 means ~90% chance, 0.2 means ~80%, etc.

Config.MailboxModels = { `prop_postbox_ss_01a`, `prop_postbox_01a` }

Config.OperationLimit = 3
Config.RateLimitWindow = 10

Config.MaxAttempts = 1
Config.LockoutDuration = 300

Config.PoliceAlertChance = 1.0

Config.BlacklistedJobs = {
    police = true,
    ambulance = true,
}
