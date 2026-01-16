local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-------------------------------------------
----- =======[ GLOBAL FUNCTION ]
-------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")
local VirtualUser = game:GetService("VirtualUser")
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")
local Constants = require(ReplicatedStorage:WaitForChild("Shared", 20):WaitForChild("Constants"))
local UserInputService = game:GetService("UserInputService")
_G.Characters = workspace:FindFirstChild("Characters"):WaitForChild(LocalPlayer.Name)
_G.HRP = _G.Characters:WaitForChild("HumanoidRootPart")
_G.Overhead = _G.HRP:WaitForChild("Overhead")
_G.Header = _G.Overhead:WaitForChild("Content"):WaitForChild("Header")
_G.LevelLabel = _G.Overhead:WaitForChild("LevelContainer"):WaitForChild("Label")
local Player = Players.LocalPlayer
local PlaceId = game.PlaceId
_G.XPBar = Player:WaitForChild("PlayerGui"):WaitForChild("XP")
_G.XPLevel = _G.XPBar:WaitForChild("Frame"):WaitForChild("LevelCount")
_G.Title = _G.Overhead:WaitForChild("TitleContainer"):WaitForChild("Label")
_G.TitleEnabled = _G.Overhead:WaitForChild("TitleContainer")
_G.DisplayNotif = game:GetService("Players").LocalPlayer.PlayerGui["Small Notification"].Display
local EquipOxy =  net:WaitForChild("RF/EquipOxygenTank")
local UnequipOxy =  net:WaitForChild("RF/UnequipOxygenTank")
local Radar = net:WaitForChild("RF/UpdateFishingRadar")

if Player and VirtualUser then
    Player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

task.spawn(function()
    if _G.XPBar then
        _G.XPBar.Enabled = true
    end
end)

_G.TeleportService = game:GetService("TeleportService")
_G.PlaceId = game.PlaceId

local function AutoReconnect()
    while task.wait(5) do
        if not Players.LocalPlayer or not Players.LocalPlayer:IsDescendantOf(game) then
            _G.TeleportService:Teleport(_G.PlaceId)
        end
    end
end

Players.LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        TeleportService:Teleport(PlaceId)
    end
end)

task.spawn(AutoReconnect)

local ijump = false

local RodIdle = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("ReelingIdle")

local RodShake = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Animations"):WaitForChild("RodThrow")

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")


local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

local RodShake = animator:LoadAnimation(RodShake)
local RodIdle = animator:LoadAnimation(RodIdle)

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
-----------------------------------------------------
-- SERVICES
-----------------------------------------------------

local Shared = ReplicatedStorage:WaitForChild("Shared", 5)
local Modules = ReplicatedStorage:WaitForChild("Modules", 5)

if Shared then
    if not _G.ItemUtility then
        local success, utility = pcall(require, Shared:WaitForChild("ItemUtility", 5))
        if success and utility then
            _G.ItemUtility = utility
        else
            warn("ItemUtility module not found or failed to load.")
        end
    end
    if not _G.ItemStringUtility and Modules then
        local success, stringUtility = pcall(require, Modules:WaitForChild("ItemStringUtility", 5))
        if success and stringUtility then
            _G.ItemStringUtility = stringUtility
        else
            warn("ItemStringUtility module not found or failed to load.")
        end
    end
    -- Memuat Replion, Promise, PromptController untuk Auto Accept Trade
    if not _G.Replion then pcall(function() _G.Replion = require(ReplicatedStorage.Packages.Replion) end) end
    if not _G.Promise then pcall(function() _G.Promise = require(ReplicatedStorage.Packages.Promise) end) end
    if not _G.PromptController then pcall(function() _G.PromptController = require(ReplicatedStorage.Controllers.PromptController) end) end
end

-- Custom Require Function
local function customRequire(module)
    if not module then return nil end
    local success, result = pcall(require, module)
    if success then
        return result
    else
        local clone = module:Clone()
        clone.Parent = nil
        local cloneSuccess, cloneResult = pcall(require, clone)
        if cloneSuccess then
            return cloneResult
        else
            warn("Failed to load module: " .. module:GetFullName())
            return nil
        end
    end
end

-- Load Global Utilities (Only for Fishing)
if Shared then
    if not _G.ItemUtility then
        local success, utility = pcall(require, Shared:WaitForChild("ItemUtility", 5))
        if success and utility then
            _G.ItemUtility = utility
        else
            warn("ItemUtility module not found or failed to load.")
        end
    end
end

-- Advanced Module Loading System
local ModulesTable = {}
local success, errorMessage = pcall(function()
    local Controllers = ReplicatedStorage:WaitForChild("Controllers", 20)
    local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild(
        "sleitnick_net@0.2.0"):WaitForChild("net", 20)
    
    if not (Controllers and NetFolder and Shared) then 
        error("Core game folders not found.") 
    end

    -- Load using customRequire
    ModulesTable.Replion = customRequire(ReplicatedStorage.Packages.Replion)
    ModulesTable.ItemUtility = customRequire(Shared.ItemUtility)
    ModulesTable.FishingController = customRequire(Controllers.FishingController)
    
    -- Net Events (ONLY FISHING RELATED)
    ModulesTable.EquipToolEvent = NetFolder["RE/EquipToolFromHotbar"]
    ModulesTable.ChargeRodFunc = NetFolder["RF/ChargeFishingRod"]
    ModulesTable.StartMinigameFunc = NetFolder["RF/RequestFishingMinigameStarted"]
    ModulesTable.CompleteFishingEvent = NetFolder["RE/FishingCompleted"]
end)

if not success then
    warn("FATAL ERROR DURING MODULE LOADING: " .. tostring(errorMessage))
    return
end

_G.FishingModules = ModulesTable

-------------------------------------------
---- ======== [ VARIABLE UTILITY & ENCHANT STONES ]
_G.AutoEnchantModule = (function()
    local module = {}
    
    -- SERVICES
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = game.Players.LocalPlayer
    local RepStorage = game:GetService("ReplicatedStorage")
    
    -- MODULES
    local ItemUtility, TierUtility
    
    local function LoadModules()
        if not ItemUtility then
            ItemUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
        end
        if not TierUtility then
            TierUtility = require(RepStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))
        end
    end
    
    -- REMOTE PATHS
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    local PlayerDataReplion = nil
    
    -- AUTO ENCHANT VARIABLES
    local autoEnchantState = false
    local autoEnchantThread = nil
    local selectedRodUUID = nil
    local selectedEnchantNames = {}
    
    -- CONSTANTS
    local ENCHANT_STONE_ID = 10
    local ENCHANT_MAPPING = {
        ["Cursed I"] = 12,
        ["Big Hunter I"] = 3,
        ["Empowered I"] = 9,
        ["Glistening I"] = 1,
        ["Gold Digger I"] = 4,
        ["Leprechaun I"] = 5,
        ["Leprechaun II"] = 6,
        ["Mutation Hunter I"] = 7,
        ["Mutation Hunter II"] = 14,
        ["Perfection"] = 15,
        ["Prismatic I"] = 13,
        ["Reeler I"] = 2,
        ["Stargazer I"] = 8,
        ["Stormhunter I"] = 11,
        ["Experienced I"] = 10,
    }
    
    -- ENCHANT NAMES ARRAY
    local ENCHANT_NAMES = {}
    for name, id in pairs(ENCHANT_MAPPING) do
        ENCHANT_NAMES[#ENCHANT_NAMES + 1] = name
    end
    
    -- MERCHANT SHOP DATA
    local MerchantStaticItems = {
        {Name = "Fluorescent Rod", ID = 1, Identifier = "Fluorescent Rod", Price = 685000},
        {Name = "Hazmat Rod", ID = 2, Identifier = "Hazmat Rod", Price = 1380000},
        {Name = "Singularity Bait", ID = 3, Identifier = "Singularity Bait", Price = 8200000},
        {Name = "Royal Bait", ID = 4, Identifier = "Royal Bait", Price = 425000},
        {Name = "Luck Totem", ID = 5, Identifier = "Luck Totem", Price = 650000},
        {Name = "Shiny Totem", ID = 7, Identifier = "Shiny Totem", Price = 400000},
        {Name = "Mutation Totem", ID = 8, Identifier = "Mutation Totem", Price = 800000}
    }
    
    -- UTILITY FUNCTIONS
    module.GetRemote = function(remotePath, name, timeout)
        local currentInstance = RepStorage
        for _, childName in ipairs(remotePath) do
            currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
            if not currentInstance then return nil end
        end
        return currentInstance:FindFirstChild(name)
    end
    
    module.GetHRP = function()
        local Character = LocalPlayer.Character
        if not Character then
            Character = LocalPlayer.CharacterAdded:Wait()
        end
        return Character:WaitForChild("HumanoidRootPart", 5)
    end
    
    module.GetPlayerDataReplion = function()
        if PlayerDataReplion then return PlayerDataReplion end
        local ReplionModule = RepStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return nil end
        local ReplionClient = require(ReplionModule).Client
        PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
        return PlayerDataReplion
    end
    
    module.GetFishNameAndRarity = function(item)
        LoadModules()
        
        local name = item.Identifier or "Unknown"
        local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
        local itemID = item.Id
        local itemData = nil
        
        if ItemUtility and itemID then
            pcall(function()
                itemData = ItemUtility:GetItemData(itemID)
                if not itemData then
                    local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                    if numericID then
                        itemData = ItemUtility:GetItemData(numericID)
                    end
                end
            end)
        end
        
        if itemData and itemData.Data and itemData.Data.Name then
            name = itemData.Data.Name
        end
        
        if item.Metadata and item.Metadata.Rarity then
            rarity = item.Metadata.Rarity
        elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
            local tierObj = nil
            pcall(function()
                tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
            end)
            
            if tierObj and tierObj.Name then
                rarity = tierObj.Name
            end
        end
        
        return name, rarity
    end
    
    module.GetEnchantNameFromId = function(id)
        id = tonumber(id)
        if not id then return nil end
        for name, eid in pairs(ENCHANT_MAPPING) do
            if eid == id then
                return name
            end
        end
        return nil
    end
    
    module.GetRodOptions = function()
        local rodOptions = {}
        local replion = module.GetPlayerDataReplion()
        if not replion then return {"(Gagal memuat Inventory)"} end
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData["Fishing Rods"] then
            return {"(Tidak ada Rod ditemukan)"}
        end
        
        local Rods = inventoryData["Fishing Rods"]
        for _, rod in ipairs(Rods) do
            local rodUUID = rod.UUID
            
            if typeof(rodUUID) ~= "string" or string.len(rodUUID) < 10 then
                continue
            end
            
            local rodName, _ = module.GetFishNameAndRarity(rod)
            
            if not string.find(rodName, "Rod", 1, true) then
                continue
            end
            
            local enchantStatus = ""
            local metadata = rod.Metadata or {}
            local enchants = {}
            
            if metadata.EnchantId then
                enchants[#enchants + 1] = metadata.EnchantId
            end
            
            local resolvedEnchantNames = {}
            for _, eid in ipairs(enchants) do
                local name = module.GetEnchantNameFromId(eid) or "ID:" .. eid
                resolvedEnchantNames[#resolvedEnchantNames + 1] = name
            end
            
            if #resolvedEnchantNames > 0 then
                enchantStatus = " [" .. table.concat(resolvedEnchantNames, ", ") .. "]"
            end
            
            local shortUUID = string.sub(rodUUID, 1, 8) .. "..."
            rodOptions[#rodOptions + 1] = rodName .. " (" .. shortUUID .. ")" .. enchantStatus
        end
        
        return rodOptions
    end
    
    module.GetUUIDFromFormattedName = function(formattedName)
        local uuidMatch = formattedName:match("%(([^%)]+)%.%.%.%)")
        if not uuidMatch then return nil end
        
        local replion = module.GetPlayerDataReplion()
        local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
        
        for _, rod in ipairs(Rods) do
            if string.sub(rod.UUID, 1, 8) == uuidMatch then
                return rod.UUID
            end
        end
        return nil
    end
    
    module.CheckIfEnchantReached = function(rodUUID)
        local replion = module.GetPlayerDataReplion()
        local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
        
        local targetRod = nil
        for _, rod in ipairs(Rods) do
            if rod.UUID == rodUUID then
                targetRod = rod
                break
            end
        end
        
        if not targetRod then return true end
        
        local metadata = targetRod.Metadata or {}
        local currentEnchants = {}
        if metadata.EnchantId then
            currentEnchants[#currentEnchants + 1] = metadata.EnchantId
        end
        
        for _, targetName in ipairs(selectedEnchantNames) do
            local targetID = ENCHANT_MAPPING[targetName]
            if targetID and table.find(currentEnchants, targetID) then
                return true
            end
        end
        
        return false
    end
    
    module.GetFirstStoneUUID = function()
        local replion = module.GetPlayerDataReplion()
        if not replion then return nil end
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then
            return nil
        end
        
        local GeneralItems = inventoryData.Items or {}
        for _, item in ipairs(GeneralItems) do
            if tonumber(item.Id) == ENCHANT_STONE_ID and item.UUID and item.Type ~= "Fishing Rods" and item.Type ~= "Bait" then
                return item.UUID
            end
        end
        return nil
    end
    
    module.UnequipAllEquippedItems = function()
        local RE_UnequipItem = module.GetRemote(RPath, "RE/UnequipItem")
        if not RE_UnequipItem then
            warn("[Auto Enchant] Gagal menemukan RE/UnequipItem remote.")
            return
        end
        
        local replion = module.GetPlayerDataReplion()
        local EquippedItems = replion:GetExpect("EquippedItems") or {}
        local EquippedSkinUUID = replion:Get("EquippedSkinUUID")
        
        if EquippedSkinUUID and EquippedSkinUUID ~= "" then
            pcall(function() RE_UnequipItem:FireServer(EquippedSkinUUID) end)
            task.wait(0.1)
        end
        
        for _, uuid in ipairs(EquippedItems) do
            pcall(function() RE_UnequipItem:FireServer(uuid) end)
            task.wait(0.05)
        end
    end
    
    module.TeleportToLookAt = function(position, lookVector)
        local hrp = module.GetHRP()
        
        if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
            local targetCFrame = CFrame.new(position, position + lookVector)
            hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
            
            if WindUI then
                WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin" })
            end
        else
            if WindUI then
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Data posisi tidak valid.", Duration = 3, Icon = "x" })
            end
        end
    end
    
    module.RunAutoEnchantLoop = function(rodUUID)
        if autoEnchantThread then
            task.cancel(autoEnchantThread)
        end
        
        local ENCHANT_ALTAR_POS = Vector3.new(3236.441, -1302.855, 1397.910)
        local ENCHANT_ALTAR_LOOK = Vector3.new(-0.954, -0.000, 0.299)
        
        local RE_UnequipItem = module.GetRemote(RPath, "RE/UnequipItem")
        local RE_EquipItem = module.GetRemote(RPath, "RE/EquipItem")
        local RE_EquipToolFromHotbar = module.GetRemote(RPath, "RE/EquipToolFromHotbar")
        local RE_ActivateEnchantingAltar = module.GetRemote(RPath, "RE/ActivateEnchantingAltar")
        
        if not (RE_UnequipItem and RE_EquipItem and RE_EquipToolFromHotbar and RE_ActivateEnchantingAltar) then
            if WindUI then
                WindUI:Notify({ Title = "Error Remote", Content = "Remote Enchanting tidak ditemukan.", Duration = 4, Icon = "x" })
            end
            autoEnchantState = false
            return
        end
        
        autoEnchantThread = task.spawn(function()
            module.UnequipAllEquippedItems()
            task.wait(2.5)
            
            module.TeleportToLookAt(ENCHANT_ALTAR_POS, ENCHANT_ALTAR_LOOK)
            task.wait(1.5)
            
            if WindUI then
                WindUI:Notify({ Title = "Auto Enchant Started", Content = "Memulai Roll Enchant...", Duration = 2, Icon = "zap" })
            end
            
            while autoEnchantState do
                if module.CheckIfEnchantReached(rodUUID) then
                    if WindUI then
                        WindUI:Notify({ Title = "Enchant Selesai!", Content = "Rod mencapai salah satu target enchant.", Duration = 5, Icon = "check" })
                    end
                    break
                end
                
                local enchantStoneUUID = module.GetFirstStoneUUID()
                if not enchantStoneUUID then
                    if WindUI then
                        WindUI:Notify({ Title = "Stone Habis!", Content = "Tidak ada Enchant Stone yang tersisa di inventaris.", Duration = 5, Icon = "stop-circle" })
                    end
                    break
                end
                
                pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
                task.wait(0.2)
                
                pcall(function() RE_EquipItem:FireServer(enchantStoneUUID, "Enchant Stones") end)
                task.wait(0.2)
                
                pcall(function() RE_EquipToolFromHotbar:FireServer(2) end)
                task.wait(0.3)
                
                pcall(function() RE_ActivateEnchantingAltar:FireServer() end)
                
                task.wait(2)
                
                pcall(function() RE_EquipToolFromHotbar:FireServer(0) end)
                
                task.wait(0.5)
            end
            
            autoEnchantState = false
            if WindUI then
                WindUI:Notify({ Title = "Auto Enchant Berhenti", Duration = 3, Icon = "x" })
            end
        end)
    end
    
    module.FormatNumber = function(n)
        if n >= 1000000000 then
            return string.format("%.1fB", n / 1000000000)
        elseif n >= 1000000 then
            return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then
            return string.format("%.1fK", n / 1000)
        else
            return tostring(n)
        end
    end
    
    -- GETTERS AND SETTERS
    module.GetAutoEnchantState = function() return autoEnchantState end
    module.SetAutoEnchantState = function(state) autoEnchantState = state end
    
    module.GetSelectedRodUUID = function() return selectedRodUUID end
    module.SetSelectedRodUUID = function(uuid) selectedRodUUID = uuid end
    
    module.GetSelectedEnchantNames = function() return selectedEnchantNames end
    module.SetSelectedEnchantNames = function(names) selectedEnchantNames = names end
    
    module.GetEnchantNames = function() return ENCHANT_NAMES end
    module.GetMerchantItems = function() return MerchantStaticItems end
    module.GetEnchantMapping = function() return ENCHANT_MAPPING end
    
    return module
end)()

-------------------------------------------
----- =======[ NOTIFY FUNCTION ]
-------------------------------------------

local function NotifySuccess(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "circle-check"
    })
end

local function NotifyError(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "ban"
    })
end

local function NotifyInfo(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "info"
    })
end

local function NotifyWarning(title, message, duration)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = duration,
        Icon = "triangle-alert"
    })
end

WindUI:AddTheme({
    Name = "Royal Void",
    Accent = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#7DEBFF"), Transparency = 0 },  -- Soft Cyan
        ["50"]  = { Color = Color3.fromHex("#F6FEFF"), Transparency = 0 },  -- Clean White
        ["100"] = { Color = Color3.fromHex("#4AC9FF"), Transparency = 0 },  -- Premium Cyan
    }, {
        Rotation = 45,
    }),

    Dialog = Color3.fromHex("#0E1A21"),         -- Dark cyan glass
    Outline = Color3.fromHex("#8EEFFF"),        -- Cyan clean outline
    Text = Color3.fromHex("#F8FFFF"),           -- Crystal white
    Placeholder = Color3.fromHex("#A6DDE6"),    -- Soft cyan placeholder
    Background = Color3.fromHex("#0A1419"),     -- Glass background
    Button = Color3.fromHex("#6FEFFF"),         -- Premium cyan button
    Icon = Color3.fromHex("#C9F7FF")            -- Soft cyan icon
})
WindUI.TransparencyValue = 0.45

local Window = WindUI:CreateWindow({
    Title = "Nikzz7ZXIT - Fish It",
    Icon = "droplets", -- ICON DIGANTI (premium cyan feel)
    Author = "Fishit | NewUpdate [Premium | 4.0 Version]",
    Folder = "Nikzz7ZXIT_V4",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Royal Void",
    Resizable = true,
    SideBarWidth = 190,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

Window:Tag({
    Title = "CREATED BY NIKZZ",
    Color = Color3.fromHex("#00FF66") -- Electric Green
})

local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("NewUpNKZ")


WindUI:Notify({
    Title = "NikzzHub",
    Content = "All Features Loaded!",
    Duration = 5,
    Image = "square-check-big"
})


-------------------------------------------
----- =======[ ALL TAB ]
-------------------------------------------

Window:Divider()

local Home = Window:Tab({
    Title = "Developer Info",
    Icon = "solar:users-group-two-rounded-bold"
})

_G.ServerPage = Window:Tab({
    Title = "Server List",
    Icon = "solar:server-square-update-bold"
})

_G.BugFish = Window:Tab({
    Title = "Special Menu",
    Icon = "ghost"
})

Window:Divider()


local AutoFish = Window:Tab({
    Title = "Fishing menu",
    Icon = "fish"
})

local BlatantSettings = Window:Tab({
    Title = "Blatant Menu",
    Icon = "fish"
})

local AutoFarmTab = Window:Tab({
    Title = "Farming Menu",
    Icon = "leaf"
})

local AutoFav = Window:Tab({
    Title = "Favorite Menu",
    Icon = "star"
})

local Trade = Window:Tab({
    Title = "Trade Menu",
    Icon = "arrow-left-right"
})

_G.DStones = Window:Tab({
    Title = "Enchant Rod",
    Icon = "wand"
})

local Player = Window:Tab({
    Title = "Player Menu",
    Icon = "solar:user-rounded-bold"
})

_G.AccConfig = Window:Tab({
    Title = "Account Settings",
    Icon = "user-cog"
})

local HookTab = Window:Tab({
    Title = "Hook Telegram",
    Icon = "webhook"
})

local Utils = Window:Tab({
    Title = "Utility Menu",
    Icon = "wrench"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "cog"
})

------------------------------------------

_G.__UIReady = false
_G.__ProtectedCallbacks = setmetatable({}, { __mode = "k" })

function _G.ProtectCallback(callback)
    if type(callback) ~= "function" then return callback end

    local wrapper = function(...)
        if not _G.__UIReady then
            -- abaikan eksekusi pertama
            return
        end

        return callback(...)
    end

    -- simpan biar GC tidak makan wrapper
    _G.__ProtectedCallbacks[wrapper] = callback
    return wrapper
end

-------------------------------------------
----- =======[ HOME TAB ]
-------------------------------------------

Home:Divider()

Home:Section({
    Title = "Developer Information",
    TextSize = 22,
    TextXAlignment = "Center",
})

Home:Divider()

Home:Paragraph({
    Title = "NikZzzXit | Fish It Premium",
    Color = "Blue",
    Desc = [[
Developer        : NikZz
Game            : Fish It
Script Version   : 4.0 (Premium)
Thema Script    : Mary Cristmas

Script Overview
────────────────────────────
Total Features    : 45+
Fishing Speed     : X3 Instant, X5 Instant, X7 Instant
Auto Features I   : Auto Fishing, Auto Shell, Auto Farm
Auto Features II   : Auto Enchant, Auto Totem
Utility Tools I      : Teleport, Copy Avatar, Speed Hack
Utility Tools II     : Anti Animation, No Cutscene, FPS Boost
Camera Tools     : Cinematic Mode, Theme Changer, Speed Camera
UI System         : WindUI Framework
Script Type        : Fully Automated & Modular
Optimization       : Stable FPS, Reduced Background Loops
Anti AFK          : Enabled

Status             : 🟢 WORKING 🟢
]]
})

_G.BugFish:Section({
    Title = "Visual Menu",
    TextSize = 22,
    TextXAlignment = "Center",
})

-------------------------------------------
----- =======[ SERVER PAGE TAB ]
-------------------------------------------

_G.ServerList = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
game.PlaceId .. "/servers/Private?sortOrder=Asc&limit=100"))

_G.ButtonList = {}

_G.ServerListAll = _G.ServerPage:Section({
    Title = "All Server List",
    TextSize = 22,
    TextXAlignment = "Center"
})

_G.ShowServersButton = _G.ServerListAll:Button({
    Title = "Show Server List",
    Desc = "Klik untuk menampilkan daftar server yang tersedia.",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        if _G.ServersShown then return end
        _G.ServersShown = true

        for _, server in ipairs(_G.ServerList.data) do
            _G.playerCount = string.format("%d/%d", server.playing, server.maxPlayers)
            _G.ping = server.ping
            _G.id = server.id

            local buttonServer = _G.ServerListAll:Button({
                Title = "Server",
                Desc = "Player: " .. tostring(_G.playerCount) .. "\nPing: " .. tostring(_G.ping),
                Locked = false,
                Icon = "",
                Callback = function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, _G.id,
                        game.Players.LocalPlayer)
                end
            })

            buttonServer:SetTitle("Server")
            buttonServer:SetDesc("Player: " .. tostring(_G.playerCount) .. "\nPing: " .. tostring(_G.ping))

            table.insert(_G.ButtonList, buttonServer)
        end

        if #_G.ButtonList == 0 then
            _G.ServerListAll:Button({
                Title = "No Servers Found",
                Desc = "Tidak ada server yang ditemukan.",
                Locked = true,
                Callback = function() end
            })
        end
    end
})

_G.AccConfig:Divider()

_G.AccConfig:Section({
    Title = "Account Configuration",
    TextSize = 22,
    TextXAlignment = "Center",
})

_G.AccConfig:Divider()

_G.AccConfig:Space()

_G.AntiStaffEnabled = false
_G.StaffUserIds = {
    [75974130] = true,
    [40397833] = true,
}
_G.__AntiStaffConns = {}

function isStaff(player)
    return _G.StaffUserIds[player.UserId] == true
end

function checkExistingPlayers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isStaff(plr) then
            NotifyWarning("Anti Talon", "Staff detected:" .. plr.Name)
            _G.ServerHop()
            return
        end
    end
end

function startAntiStaff()
    checkExistingPlayers()

    _G.__AntiStaffConns.playerAdded =
        Players.PlayerAdded:Connect(function(plr)
            if not _G.AntiStaffEnabled then return end
            if isStaff(plr) then
                NotifyWarning("Anti Talon", "Staff joined:" .. plr.Name)
                _G.ServerHop()
            end
        end)
end

function stopAntiStaff()
    for _, c in pairs(_G.__AntiStaffConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(_G.__AntiStaffConns)
end

_G.KickTalon = _G.AccConfig:Toggle({
    Title = "Anti Staff FishIt",
    Value = false,
    Callback = function(state)
        _G.AntiStaffEnabled = state
        if state then
            startAntiStaff()
        else
            stopAntiStaff()
        end
    end
})

myConfig:Register("KickTalon", _G.KickTalon)

_G.FPSPingEnabled = false
_G.__FPSPingLoop = nil
_G.__FPSPingGui = nil
_G.CoreGui = game:GetService("CoreGui")
_G.Stats = game:GetService("Stats")

function createFPSPingHUD()
    if _G.__FPSPingGui then return end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FPSPingHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = _G.CoreGui

    -- Container TANPA background
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.fromScale(0.18, 0.08)
    Holder.Position = UDim2.fromScale(0.02, 0.46) -- kiri tengah
    Holder.BackgroundTransparency = 1
    Holder.BorderSizePixel = 0
    Holder.Parent = ScreenGui

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    Layout.Parent = Holder

    local function makeLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center

        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 14
        lbl.Text = text

        -- Text utama
        lbl.TextColor3 = Color3.fromRGB(235, 245, 255)

        -- Stroke halus agar tetap kebaca tanpa background
        lbl.TextStrokeTransparency = 0.75
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

        lbl.Parent = Holder
        return lbl
    end

    _G.__FPSLabel = makeLabel("FPS: --")
    _G.__PingLabel = makeLabel("Ping: -- ms")

    _G.__FPSPingGui = ScreenGui
end

function startFPSPingLoop()
    if _G.__FPSPingLoop then return end

    createFPSPingHUD()

    _G.__FPSPingLoop = task.spawn(function()
        local frames = 0
        local last = tick()

        while _G.FPSPingEnabled do
            RunService.RenderStepped:Wait()
            frames = frames +  1

            if tick() - last >= 1 then
                local fps = frames
                frames = 0
                last = tick()

                local ping = math.floor(
                    _G.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
                )

                if _G.__FPSLabel then
                    _G.__FPSLabel.Text = "FPS: " .. fps
                end
                if _G.__PingLabel then
                    _G.__PingLabel.Text = "Ping: " .. ping .. " ms"
                end
            end
        end
    end)
end

function stopFPSPingLoop()
    if _G.__FPSPingLoop then
        task.cancel(_G.__FPSPingLoop)
        _G.__FPSPingLoop = nil
    end
    if _G.__FPSPingGui then
        _G.__FPSPingGui:Destroy()
        _G.__FPSPingGui = nil
    end
end

_G.AccConfig:Toggle({
    Title = "FPS & Ping Counter",
    Desc = "Show realtime FPS & Ping",
    Value = false,
    Callback = function(state)
        _G.FPSPingEnabled = state

        if state then
            startFPSPingLoop()
        else
            stopFPSPingLoop()
        end
    end
})

_G.AccConfig:Space()

function _G.getHeader()
    local Character = workspace:WaitForChild("Characters"):FindFirstChild(LocalPlayer.Name)
    if not Character then return nil end

    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return nil end

    local Overhead = HRP:FindFirstChild("Overhead")
    if not Overhead then return nil end

    local Header = Overhead:FindFirstChild("Content") and Overhead.Content:FindFirstChild("Header")
    return Header
end

_G.AccConfig:Colorpicker({
    Title = "Color Name",
    Default = _G.getHeader().TextColor3,
    Callback = function(color)
        local Header = _G.getHeader()
        if Header and Header:IsA("TextLabel") then
            Header.TextColor3 = color
        else
            warn("[Overhead] Header tidak ditemukan untuk LocalPlayer.")
        end
    end
})

_G.AccConfig:Input({
    Title = "Display Name",
    Placeholder = "Display Name...",
    Callback = function(input)
        if _G.Header and typeof(input) == "string" and input ~= "" then
            _G.Header.Text = input
        end
    end
})

_G.AccConfig:Input({
    Title = "Level",
    Placeholder = "Level.",
    Callback = function(input)
        local num = tonumber(input)
        if _G.LevelLabel and num then
            _G.LevelLabel.Text = "Lvl: " .. num
            _G.XPLevel.Text = "Lvl " .. num
        end
    end
})

function _G.HideIdentity(enabled)
    if enabled then
        _G.Header.Visible = false
        _G.LevelLabel.Visible = false
        _G.TitleEnabled.Visible = false
    else
        _G.Header.Visible = true
        _G.LevelLabel.Visible = true
        _G.TitleEnabled.Visible = true
    end
end

_G.AccConfig:Toggle({
    Title = "Hide Identity",
    Value = false,
    Callback = function(state)
        _G.HideIdentity(state)
    end
})

_G.AccConfig:Space()

_G.AccConfig:Divider()

_G.AccConfig:Section({
    Title = "Menu Gifting",
    TextSize = 22,
    TextXAlignment = "Center",
})

_G.AccConfig:Divider()

_G.GiftingController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("GiftingController"))

_G.LastGiftSkin = nil

_G.AccConfig:Input({
    Title = "Custom Gift Skin",
    Placeholder = "Enter skin name...",
    Callback = _G.ProtectCallback(function(inputText)
        if inputText and inputText ~= "" then
            _G.LastGiftSkin = inputText
            NotifyInfo("Gift Menu", ("Skin '%s' is ready to gift. Press the Gift button to open!"):format(inputText))
        else
            _G.LastGiftSkin = nil
            NotifyWarning("Gift Menu", "Skin name cannot be empty!")
        end
    end)
})

_G.AccConfig:Space()

_G.AccConfig:Button({
    Title = "Gift",
    Justify = "Center",
    Icon = "",
    Callback = _G.ProtectCallback(function()
        if _G.LastGiftSkin then
            _G.GiftingController:Open(_G.LastGiftSkin)
            NotifySuccess("Gift Menu", ("Gift '%s' opened!"):format(_G.LastGiftSkin))
        else
            NotifyWarning("Gift Menu", "No valid skin to gift. Please enter a skin name first!")
        end
    end)
})

_G.AccConfig:Space()

-------------------------------------------
----- =======[ AUTO FISH TAB ]
-------------------------------------------

_G.REFishingStopped = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingStopped"]
_G.RFCancelFishingInputs = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
_G.REUpdateChargeState = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/UpdateChargeState"]


_G.StopFishing = function()
    _G.RFCancelFishingInputs:InvokeServer()
    firesignal(_G.REFishingStopped.OnClientEvent)
end

local FuncAutoFish = {
    REReplicateTextEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"],
    autofish5x = false,
    perfectCast5x = true,
    fishingActive = false,
    delayInitialized = false,
    lastCatchTime5x = 0,
    CatchLast = tick(),
}



_G.REFishCaught = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]
_G.REPlayFishingEffect = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/PlayFishingEffect"]
_G.equipRemote = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
_G.REObtainedNewFishNotification = ReplicatedStorage
    .Packages._Index["sleitnick_net@0.2.0"]
    .net["RE/ObtainedNewFishNotification"]


_G.isSpamming = false
_G.rSpamming = false
_G.rStopSpam = false
_G.spamThread = nil
_G.rspamThread = nil
_G.stopThread = nil
_G.lastRecastTime = 0
_G.DELAY_ANTISTUCK = 10
_G.isRecasting5x = false
_G.STUCK_TIMEOUT = 10
_G.AntiStuckEnabled = false
_G.lastFishTime = tick()
_G.FINISH_DELAY = 1
_G.fishCounter = 0
_G.sellThreshold = 30
_G.sellActive = false
_G.AutoFishHighQuality = false
_G.CastTimeoutMode = "Fast"
_G.CastTimeoutValue = 0.01

function RandomFloat()
    return 0.01 + math.random() * 0.99
end

-- [[ KONFIGURASI DELAY ]] --

_G.RemotePackage = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
_G.RemoteFish = _G.RemotePackage["RE/ObtainedNewFishNotification"]
_G.RemoteSell = _G.RemotePackage["RF/SellAllItems"]

_G.RemoteFish.OnClientEvent:Connect(function(_, _, data)
    if _G.sellActive and data then
        _G.fishCounter = _G.fishCounter + 1
        if _G.fishCounter >= _G.sellThreshold then
            _G.TrySellNow()
            _G.fishCounter = 0
        end
    end
end)

_G.LastSellTick = 0

function _G.TrySellNow()
    local now = tick()
    if now - _G.LastSellTick < 1 then 
        return 
    end
    _G.LastSellTick = now
    _G.RemoteSell:InvokeServer()
end

function InitialCast5X()
    _G.StopFishing()
    local getPowerFunction = Constants.GetPower
    local perfectThreshold = 0.99
    local chargeStartTime = workspace:GetServerTimeNow()
    rodRemote:InvokeServer(chargeStartTime)
    local calculationLoopStart = tick()

    local timeoutDuration = tonumber(_G.CastTimeoutValue)

    local lastPower = 0
    while (tick() - calculationLoopStart < timeoutDuration) do
        local currentPower = getPowerFunction(Constants, chargeStartTime)
        if currentPower < lastPower and lastPower >= perfectThreshold then
            break
        end

        lastPower = currentPower
        task.wait(0.001)
    end
    miniGameRemote:InvokeServer(-1.25, 1.0, workspace:GetServerTimeNow())
end

function _G.StopSpam()
    if _G.rStopSpam then return end
    _G.rStopSpam = true
    _G.spamThread = task.spawn(function()
        for i = 1, 5 do
            task.wait(0.01) 
            _G.StopFishing()
        end
    end)
end


function _G.RecastSpam()
    if _G.rSpamming then return end
    _G.rSpamming = true
    
    _G.rspamThread = task.spawn(function()
        while _G.rSpamming do
            task.wait(0.01) 
            InitialCast5X()
        end
    end)
end

function _G.StopRecastSpam()
    _G.rSpamming = false
    if _G.rspamThread then
        task.cancel(_G.rspamThread) -- Membunuh thread
        _G.rspamThread = nil
    end
end

    

function _G.startSpam()
    if _G.isSpamming then return end
    _G.isSpamming = true
    _G.spamThread = task.spawn(function()
        task.wait(tonumber(_G.FINISH_DELAY))
        finishRemote:FireServer()
    end)
end
    
function _G.stopSpam()
   _G.isSpamming = false
end


_G.REPlayFishingEffect.OnClientEvent:Connect(function(player, head, data)
    if player == Players.LocalPlayer and FuncAutoFish.autofish5x then
        _G.StopRecastSpam() -- Menghentikan spam cast (sudah di-fix)
        _G.stopSpam()
    end
end)



local lastEventTime = tick()

task.spawn(function()
    while task.wait(1) do
        if _G.AutoFishHighQuality and FuncAutoFish.autofish5x and FuncAutoFish.REReplicateTextEffect then
            if tick() - lastEventTime > 10 then
                _G.StopSpam()
				task.wait(0.1)
				_G.RecastSpam()
                lastEventTime = tick()
            end
        end
    end
end)

local function approx(a, b, tolerance)
    return math.abs(a - b) <= (tolerance or 0.02)
end

local function isColor(r, g, b, R, G, B)
    return approx(r, R) and approx(g, G) and approx(b, B)
end

local BAD_COLORS = {
    COMMON    = {1,       0.980392, 0.964706},
    UNCOMMON  = {0.764706, 1,        0.333333},
    RARE      = {0.333333, 0.635294, 1},
    EPIC      = {0.678431, 0.309804, 1},
}

FuncAutoFish.REReplicateTextEffect.OnClientEvent:Connect(function(data)

    if not FuncAutoFish.autofish5x then return end

    local myHead = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Head")
    if not (data and data.TextData and data.TextData.TextColor and data.TextData.EffectType == "Exclaim" and myHead and data.Container == myHead) then
        return
    end

    lastEventTime = tick()
    if _G.AutoFishHighQuality then
        local colorValue = data.TextData.TextColor
        local r, g, b
    
        if typeof(colorValue) == "Color3" then
            r, g, b = colorValue.R, colorValue.G, colorValue.B
        elseif typeof(colorValue) == "ColorSequence" and #colorValue.Keypoints > 0 then
            local c = colorValue.Keypoints[1].Value
            r, g, b = c.R, c.G, c.B
        end
    
        if not (r and g and b) then return end
    
        local isBadFish = false
    
        for _, col in pairs(BAD_COLORS) do
            if isColor(r, g, b, col[1], col[2], col[3]) then
                isBadFish = true
                break
            end
        end
    
        if isBadFish then
            _G.StopFishing()
            _G.RecastSpam()
        else
            _G.startSpam()
        end
    else
        _G.startSpam()
    end
end)



_G.REFishCaught.OnClientEvent:Connect(function(fishName, info)
    if FuncAutoFish.autofish5x then
        _G.stopSpam()
        _G.lastFishTime = tick()
        _G.RecastSpam()
    end
end)

task.spawn(function()
	while task.wait(1) do
		if _G.AntiStuckEnabled and FuncAutoFish.autofish5x and not _G.AutoFishHighQuality then
			if tick() - _G.lastFishTime > tonumber(_G.STUCK_TIMEOUT) then
				StopAutoFish5X()
				task.wait(1)
				StartAutoFish5X()
				_G.lastFishTime = tick()
			end
		end
	end
end)


function StartAutoFish5X()
    _G.equipRemote:FireServer(1)
    FuncAutoFish.autofish5x = true
    _G.AntiStuckEnabled = true
    lastEventTime = tick()
    _G.lastFishTime = tick()
    task.wait(0.5)
    InitialCast5X()
end


function StopAutoFish5X()
    FuncAutoFish.autofish5x = false
    _G.AntiStuckEnabled = false
    _G.StopFishing()
    _G.isRecasting5x = false
    _G.StopSpam()
    _G.stopSpam()
    _G.StopRecastSpam()
end


--[[

INI AUTO FISH LEGIT 

]]


_G.RunService = game:GetService("RunService")
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")
_G.FishingControllerPath = _G.ReplicatedStorage.Controllers.FishingController
_G.FishingController = require(_G.FishingControllerPath)

_G.AutoFishingControllerPath = _G.ReplicatedStorage.Controllers.AutoFishingController
_G.AutoFishingController = require(_G.AutoFishingControllerPath)
_G.Replion = require(_G.ReplicatedStorage.Packages.Replion)

_G.AutoFishState = {
    IsActive = false,
    MinigameActive = false
}

_G.SPEED_LEGIT = 0.5

function _G.performClick()
    _G.FishingController:RequestFishingMinigameClick()
    task.wait(tonumber(_G.SPEED_LEGIT))
end

_G.originalAutoFishingStateChanged = _G.AutoFishingController.AutoFishingStateChanged
function _G.forceActiveVisual(arg1)
    _G.originalAutoFishingStateChanged(true)
end

_G.AutoFishingController.AutoFishingStateChanged = _G.forceActiveVisual

function _G.ensureServerAutoFishingOn()
    local replionData = _G.Replion.Client:WaitReplion("Data")
    local currentAutoFishingState = replionData:GetExpect("AutoFishing")

    if not currentAutoFishingState then
        local remoteFunctionName = "UpdateAutoFishingState"
        local Net = require(_G.ReplicatedStorage.Packages.Net)
        local UpdateAutoFishingRemote = Net:RemoteFunction(remoteFunctionName)

        local success, result = pcall(function()
            return UpdateAutoFishingRemote:InvokeServer(true)
        end)

        if success then
        else
        end
    else
    end
end

-- ===================================================================
-- BAGIAN 2: AUTO CLICK MINIGAME
-- ===================================================================

_G.originalRodStarted = _G.FishingController.FishingRodStarted
_G.originalFishingStopped = _G.FishingController.FishingStopped
_G.clickThread = nil

_G.FishingController.FishingRodStarted = function(self, arg1, arg2)
    _G.originalRodStarted(self, arg1, arg2)

    if _G.AutoFishState.IsActive and not _G.AutoFishState.MinigameActive then
        _G.AutoFishState.MinigameActive = true

        if _G.clickThread then
            task.cancel(_G.clickThread)
        end

        _G.clickThread = task.spawn(function()
            while _G.AutoFishState.IsActive and _G.AutoFishState.MinigameActive do
                _G.performClick()
            end
        end)
    end
end

_G.FishingController.FishingStopped = function(self, arg1)
    _G.originalFishingStopped(self, arg1)

    if _G.AutoFishState.MinigameActive then
        _G.AutoFishState.MinigameActive = false
        task.wait(1)
        _G.ensureServerAutoFishingOn()
    end
end

function _G.ToggleAutoClick(shouldActivate)
    _G.AutoFishState.IsActive = shouldActivate

    if shouldActivate then
        _G.ensureServerAutoFishingOn()
    else
        if _G.clickThread then
            task.cancel(_G.clickThread)
            _G.clickThread = nil
        end
        _G.AutoFishState.MinigameActive = false
    end
end

local v5 = {
    Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net,
    FishingController = require(ReplicatedStorage.Controllers.FishingController),
}

-------------------------------------------------
-- FORCE EQUIP SLOT 1 (AUTO)
-------------------------------------------------

local v6 = {
    Events = {
        REFishDone = v5.Net["RE/FishingCompleted"],
        REEquip = v5.Net["RE/EquipToolFromHotbar"],
    },
    Functions = {
        ChargeRod = v5.Net["RF/ChargeFishingRod"],
        StartMini = v5.Net["RF/RequestFishingMinigameStarted"],
        Cancel = v5.Net["RF/CancelFishingInputs"],
    }
}

_G.BlatantState = {
    enabled = false,
    mode = "Fast",
    fishingDelay = 1.0,
    reelDelay = 1.9
}

_G.__RodEquipped = false

_G.ForceEquipRod = function()
    pcall(function()
        v6.Events.REEquip:FireServer(1)
    end)
    task.wait(0.25)
end

task.spawn(function()
    local lastState = false

    while true do
        local enabled = _G.BlatantState.enabled

        -- rising edge: OFF -> ON
        if enabled and not lastState then
            _G.__RodEquipped = false

            pcall(function()
                v6.Events.REEquip:FireServer(1)
            end)

            task.delay(0.3, function()
                _G.__RodEquipped = true
            end)
        end

        lastState = enabled
        task.wait(0.1)
    end
end)

function Fastest()
    task.spawn(function()
        pcall(function()
            v6.Functions.Cancel:InvokeServer()
        end)
        local l_workspace_ServerTimeNow_0 = workspace:GetServerTimeNow()
        pcall(function()
            v6.Functions.ChargeRod:InvokeServer(l_workspace_ServerTimeNow_0)
        end)
        pcall(function()
            v6.Functions.StartMini:InvokeServer(-1, 0.999)
        end)
        task.wait(_G.BlatantState.fishingDelay)
        pcall(function()
            v6.Events.REFishDone:FireServer()
        end)
    end)
end

task.spawn(function()
    while true do
        if _G.BlatantState.enabled then
            if _G.BlatantState.mode == "Fast" then
                Fastest()
            end
            task.wait(_G.BlatantState.reelDelay)
        else
            task.wait(0.2)
        end
    end
end)

AutoFish:Divider()

_G.FishAdvenc = AutoFish:Section({
    Title = "Fishing Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

AutoFish:Divider()

_G.BlatantSec = AutoFish:Section({
    Title = "Blatant Fishing",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

AutoFish:Divider()

_G.FishSec = AutoFish:Section({
    Title = "Auto Shell",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

AutoFish:Divider()

_G.AnimSec = _G.BugFish:Section({
    Title = "Animation Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = false
})

AutoFish:Divider()

_G.BlatantSec:Input({
    Title = "Delay Reel",
    Value = tostring(_G.BlatantState.reelDelay),
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            _G.BlatantState.reelDelay = num
        end
    end
})

_G.BlatantSec:Input({
    Title = "Delay Fishing",
    Value = tostring(_G.BlatantState.fishingDelay),
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            _G.BlatantState.fishingDelay = num
        end
    end
})

_G.BlatantSec:Toggle({
    Title = "Enable Blatant",
    Value = false,
    Callback = function(state)
        _G.BlatantState.enabled = state
    end
})

_G.DelayFinish = _G.FishAdvenc:Input({
    Title = "Delay Fish Instant",
    Desc = [[
Enter a valid delay settings
]],
    Type = "Input",
    Value = _G.FINISH_DELAY,
    Placeholder = "Input Delay Finish..",
    Callback = function(input)
        fDelays = tonumber(input)
        _G.FINISH_DELAY = fDelays
    end
})

myConfig:Register("DelayFinish", _G.DelayFinish)

_G.StuckDelay = _G.FishAdvenc:Input({
    Title = "Anti Stuck Delay",
    Desc = "Cooldown for anti stuck Auto Fish",
    Type = "Input",
    Value = _G.STUCK_TIMEOUT,
    Placeholder = "Input Delay Finish..",
    Callback = function(input)
        stuck = tonumber(input)
        _G.STUCK_TIMEOUT = stuck
    end
})

myConfig:Register("StuckDelay", _G.StuckDelay)

local REEquipItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipItem"]
local RFSellItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellItem"]

function ToggleAutoSellMythic(state)
    autoSellMythic = state
    if autoSellMythic then
        NotifySuccess("AutoSellMythic", "Status: ON")
    else
        NotifyWarning("AutoSellMythic", "Status: OFF")
    end
end

local oldFireServer
oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if autoSellMythic
        and method == "FireServer"
        and self == REEquipItem
        and typeof(args[1]) == "string"
        and args[2] == "Fishes" then
        local uuid = args[1]

        task.delay(1, function()
            pcall(function()
                local result = RFSellItem:InvokeServer(uuid)
                if result then
                    NotifySuccess("AutoSellMythic", "Items Sold!!")
                else
                    NotifyError("AutoSellMythic", "Failed to sell item!!")
                end
            end)
        end)
    end

    return oldFireServer(self, ...)
end)


function sellAllFishes()
    local charFolder = workspace:FindFirstChild("Characters")
    local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        NotifyError("Character Not Found", "HRP tidak ditemukan.")
        return
    end

    local originalPos = hrp.CFrame
    local sellRemote = net:WaitForChild("RF/SellAllItems")

    task.spawn(function()
        NotifyInfo("Selling...", "I'm going to sell all the fish, please wait...", 3)

        task.wait(1)
        local success, err = pcall(function()
            sellRemote:InvokeServer()
        end)

        if success then
            NotifySuccess("Sold!", "All the fish were sold successfully.", 3)
        else
            NotifyError("Sell Failed", tostring(err, 3))
        end
    end)
end

_G.FishSec:Space()

_G.SellThress = _G.FishSec:Input({
    Title = "Sell Threesold",
    Type = "Input",
    Placeholder = "Input Delay Finish..",
    Value = _G.sellThreshold,
    Callback = function(input)
        thresold = tonumber(input)
        _G.sellThreshold = thresold
    end
})

myConfig:Register("SellThresold", _G.SellThress)

_G.AutoSell = _G.FishSec:Toggle({
    Title = "Auto Sell",
    Callback = function(state)
        _G.sellActive = state
        if state then
            NotifySuccess("Auto Sell", "Limit: " .. _G.sellThreshold)
        else
            NotifySuccess("Auto Sell", "Disabled")
        end
    end
})

myConfig:Register("AutoSell", _G.AutoSell)

_G.FishSec:Button({
    Title = "Sell All Fishes",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        sellAllFishes()
    end
})

_G.SetCast = _G.FishAdvenc:Dropdown({
    Title = "Cast Mode",
    Desc = "Choose casting speed",
    Values = {"Perfect", "Fast", "Random"},
    Value = "Fast",
    Multi = false,
    Callback = function(selected)
        _G.CastTimeoutMode = selected
        if selected == "Perfect" then
            _G.CastTimeoutValue = 1
        elseif selected == "Random" then
            _G.CastTimeoutValue = RandomFloat()
        elseif selected == "Fast" then
            _G.CastTimeoutValue = 0.01
        end
    end
})

myConfig:Register("SetCast", _G.SetCast)

_G.HighFish = _G.FishAdvenc:Toggle({
    Title = "Fish High Quality",
    Desc = "Only Legendary, Mythic, & SECRET",
    Callback = function(state)
        _G.AutoFishHighQuality = state
    end
})

myConfig:Register("FishHigh", _G.HighFish)

_G.AutoFishes = _G.FishAdvenc:Toggle({
    Title = "Auto Fish Instant",
    Callback = function(value)
        if value then
            StartAutoFish5X()
        else
            StopAutoFish5X()
        end
    end
})

myConfig:Register("AutoFishing", _G.AutoFishes)

_G.SpeedLegit = _G.FishAdvenc:Input({
    Title = "Speed Legit",
    Desc = "Speed Click for Auto Fish Legit",
    Type = "Input",
    Placeholder = "Input Speed..",
    Value = _G.SPEED_LEGIT,
    Callback = function(input)
        DelayLegit = tonumber(input)
        _G.SPEED_LEGIT = DelayLegit
    end
})

myConfig:Register("SpeedLegit", _G.SpeedLegit)

_G.FishLegit = _G.FishAdvenc:Toggle({
    Title = "Auto Fish Legit",
    Callback = function(state)
        _G.equipRemote:FireServer(1)
        _G.ToggleAutoClick(state)

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:WaitForChild("Fishing"):WaitForChild("Main")
        local chargeGui = playerGui:WaitForChild("Charge"):WaitForChild("Main")

        if state then
            fishingGui.Visible = false
            chargeGui.Visible = false
        else
            fishingGui.Visible = true
            chargeGui.Visible = true
        end
    end
})

myConfig:Register("FishLegit", _G.FishLegit)

_G.FishSec:Space()

_G.FishAdvenc:Button({
    Title = "Stop Fishing",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.StopFishing()
        RodIdle:Stop()
        RodIdle:Stop()
        _G.stopSpam()
        _G.StopRecastSpam()
    end
})

_G.FishSec:Space()

-- =======================================================
-- == FAKE FISHING: VISUAL + INVENTORY UI FIX
-- =======================================================

-- 1. SERVICES & PLAYERS
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")
_G.Players = game:GetService("Players")
_G.HttpService = game:GetService("HttpService")
_G.LocalPlayer = _G.Players.LocalPlayer

-------------------------------------------
----- =======[ SUPER FISHING (FAKE) ]
-------------------------------------------

_G.FakeFishSection = AutoFish:Section({ 
    Title = "Visual Fishing", 
    TextSize = 22, 
    TextXAlignment = "Center", 
    Opened = true 
})

AutoFish:Divider()

local fakeFishState = {
    enabled = false,
    thread = nil,
    delay = 0.05,
    stepDelay = 0.05,
    FishDB_List = {},
    FishDB_ByName = {},
    Area_FishMap = {},
    loaded = false,
    selectedRarities = {},
    injectToInventory = true,
    useGolden = true,
    useRainbow = true,
    useVisualEffects = true
}

-- [HELPER] Load Data Ikan
local function ensureFakeDataLoaded()
    if fakeFishState.loaded then return end
    
    fakeFishState.FishDB_List = {}
    fakeFishState.FishDB_ByName = {}
    
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then return end
    
    for _, module in pairs(itemsFolder:GetChildren()) do
        if module:IsA("ModuleScript") then
            local success, data = pcall(require, module)
            if success and data and data.Data and data.Data.Type == "Fish" then
                local detectedTier = data.Data.Tier or data.Data.Rarity or 1
                if type(detectedTier) == "number" then
                    local tierMap = { [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic", [5] = "Legendary", [6] = "Mythic", [7] = "SECRET" }
                    detectedTier = tierMap[detectedTier] or "Common"
                end

                local fishData = {
                    Name = data.Data.Name,
                    Id = data.Data.Id,
                    WeightMin = (data.Weight and data.Weight.Default and data.Weight.Default.Min) or 1,
                    WeightMax = (data.Weight and data.Weight.Default and data.Weight.Default.Max) or 10,
                    Tier = tostring(detectedTier),
                    TierNum = data.Data.Tier or 1
                }
                
                table.insert(fakeFishState.FishDB_List, fishData)
                fakeFishState.FishDB_ByName[data.Data.Name] = fishData
            end
        end
    end

    local areasSuccess, AreasData = pcall(function() return require(ReplicatedStorage:WaitForChild("Areas")) end)
    if areasSuccess and type(AreasData) == "table" then
        for areaName, areaData in pairs(AreasData) do
            if areaData.Items then fakeFishState.Area_FishMap[areaName] = areaData.Items end
        end
    end
    
    fakeFishState.loaded = true
end

-- [LOGIC] Pilih Ikan Smart
local function getSmartFishFake()
    local currentZone = Players.LocalPlayer:GetAttribute("LocationName") or "Fisherman Island"
    local validFishList = {}

    local function isTierMatch(fishTier)
        if #fakeFishState.selectedRarities == 0 then return true end
        return table.find(fakeFishState.selectedRarities, fishTier) ~= nil
    end

    local areaItemNames = fakeFishState.Area_FishMap[currentZone]
    if areaItemNames then
        for _, itemName in ipairs(areaItemNames) do
            local fish = fakeFishState.FishDB_ByName[itemName]
            if fish and isTierMatch(fish.Tier) then table.insert(validFishList, fish) end
        end
    end

    if #validFishList == 0 then
        for _, fish in ipairs(fakeFishState.FishDB_List) do
            if isTierMatch(fish.Tier) then table.insert(validFishList, fish) end
        end
    end

    if #validFishList > 0 then return validFishList[math.random(1, #validFishList)] end
    return nil
end

-- [UI UPDATE] Modifier Bars (Golden/Rainbow)
local function updateModifierUI_Fake()
    pcall(function()
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        local backpack = pg:FindFirstChild("Backpack")
        if not backpack then return end
        local modifiers = backpack:FindFirstChild("Modifiers")
        if not modifiers then return end
        
        -- Golden Logic
        if fakeFishState.useGolden then
            local golden = modifiers:FindFirstChild("Golden")
            if golden and golden:FindFirstChild("Label") then
                local maxGolden = 10 
                local current = tonumber(golden.Label.Text:match("%d+")) or 0
                if current >= maxGolden then current = 0 end
                current = current + 1
                golden.Label.Text = string.format("%d/%d", current, maxGolden)
                golden.Visible = true

                local fill = golden:FindFirstChild("Fill")
                if fill then
                    local gradient = fill:FindFirstChild("UIGradient")
                    if gradient then
                        local percent = current / maxGolden
                        gradient.Offset = Vector2.new(0, -percent) -- Visual fix vertikal
                    end
                end
            end
        end
        
        -- Rainbow Logic
        if fakeFishState.useRainbow then
            local rainbow = modifiers:FindFirstChild("Rainbow")
            if rainbow and rainbow:FindFirstChild("Label") then
                local maxRainbow = 40
                local current = tonumber(rainbow.Label.Text:match("%d+")) or 0
                if current >= maxRainbow then current = 0 end
                current = current + 1
                rainbow.Label.Text = string.format("%d/%d", current, maxRainbow)
                rainbow.Visible = true

                local fill = rainbow:FindFirstChild("Fill")
                if fill then
                    local gradient = fill:FindFirstChild("UIGradient")
                    if gradient then
                        local percent = current / maxRainbow
                        gradient.Offset = Vector2.new(0, -percent) -- Visual fix vertikal
                    end
                end
            end
        end
    end)
end

-- [UI UPDATE] Bag Size
local function updateBagSizeUI_Fake()
    pcall(function()
        local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        
        local function setLabel(lbl)
            local current, max = lbl.Text:match("(%d+)/(%d+)")
            if current and max then
                current = tonumber(current) or 0
                max = tonumber(4500)
                lbl.Text = string.format("%d/%d", current + 1, max)
            end
        end

        -- Lokasi 1: Backpack
        local backpack = pg:FindFirstChild("Backpack")
        if backpack and backpack:FindFirstChild("Display") then
            local inv = backpack.Display:FindFirstChild("Inventory")
            if inv and inv:FindFirstChild("BagSize") then setLabel(inv.BagSize) end
        end
        
        -- Lokasi 2: Inventory UI Utama
        local inventoryGui = pg:FindFirstChild("Inventory")
        if inventoryGui and inventoryGui:FindFirstChild("Main") then
            local top = inventoryGui.Main:FindFirstChild("Top")
            if top and top:FindFirstChild("Options") and top.Options:FindFirstChild("Fish") then
                local lbl = top.Options.Fish:FindFirstChild("Label")
                if lbl and lbl:FindFirstChild("BagSize") then setLabel(lbl.BagSize) end
            end
        end
    end)
end

local function getTierColorFake(tierNum)
    local colorMap = {
        [1] = ColorSequence.new(Color3.fromRGB(200, 200, 200)), -- Common
        [2] = ColorSequence.new(Color3.fromRGB(0, 255, 0)),     -- Uncommon
        [3] = ColorSequence.new(Color3.fromRGB(0, 195, 255)),   -- Rare
        [4] = ColorSequence.new(Color3.fromRGB(255, 0, 255)),   -- Epic
        [5] = ColorSequence.new(Color3.fromRGB(255, 215, 0)),   -- Legendary
        [6] = ColorSequence.new(Color3.fromRGB(255, 85, 255)),  -- Mythic
        [7] = ColorSequence.new(Color3.fromRGB(255, 0, 0))      -- SECRET
    }
    return colorMap[tierNum] or colorMap[1]
end

-- MAIN LOOP FAKE FISHING
local function startSuperFishingLoop()
    local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
    
    -- Definisi Event (Pastikan executor support firesignal)
    local REBaitCastVisual = Net["RE/BaitCastVisual"]
    local REBaitSpawned = Net["RE/BaitSpawned"]
    local RECaughtFishVisual = Net["RE/CaughtFishVisual"]
    local REFishCaught = Net["RE/FishCaught"]
    local REObtainedNewFishNotification = Net["RE/ObtainedNewFishNotification"]
    local REPlayFishingEffect = Net["RE/PlayFishingEffect"]
    local REReplicateTextEffect = Net["RE/ReplicateTextEffect"]
    
    while fakeFishState.enabled do
        local loopSuccess, loopError = pcall(function()
            local char = Players.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            
            if not (char and hrp and head) then task.wait(0.5) return end
            
            local targetFish = getSmartFishFake()
            if not targetFish then task.wait(0.5) return end
            
            local rnd = Random.new()
            local syncedWeight = rnd:NextNumber(targetFish.WeightMin, targetFish.WeightMax)
            local fakeUUID = HttpService:GenerateGUID(false)
            
            local originPos = hrp.Position
            local lookVec = hrp.CFrame.LookVector
            local castPos = originPos + (lookVec * 15) + Vector3.new(0, -5, 0)
            
            local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!") or char:FindFirstChildWhichIsA("Tool")
            if not equippedTool then 
                NotifyWarning("Super Fishing", "Please equip a rod first!")
                task.wait(2) 
                return 
            end
            
            -- CAST
            pcall(firesignal, REBaitCastVisual.OnClientEvent, Players.LocalPlayer, {
                CastPosition = castPos, Origin = originPos + Vector3.new(0, 5, 0),
                RodName = equippedTool.Name, CustomModel = false, EquippedToolModel = equippedTool,
                ConnectingJoint = 4, NoFishingZone = false, BaitIdentifier = math.random(1, 5),
                CosmeticTemplateId = -1, Power = 0.9 + (math.random() * 0.1)
            })
            pcall(firesignal, REBaitSpawned.OnClientEvent, Players.LocalPlayer, equippedTool.Name, castPos)
            task.wait(fakeFishState.stepDelay)
            
            -- CAUGHT VISUAL
            
            
            -- EFFECTS
            if fakeFishState.useVisualEffects then
                pcall(firesignal, REPlayFishingEffect.OnClientEvent, Players.LocalPlayer, head, 1)
                local tierColor = getTierColorFake(targetFish.TierNum)
                pcall(firesignal, REReplicateTextEffect.OnClientEvent, {
                    UUID = HttpService:GenerateGUID(false), Channel = "All",
                    TextData = { AttachTo = head, Text = "!", EffectType = "Exclaim", TextColor = tierColor },
                    Duration = 0.5, Container = head
                })
            end
            task.wait(fakeFishState.stepDelay)
            
            -- FISH CAUGHT LOGIC
            pcall(firesignal, REFishCaught.OnClientEvent, targetFish.Name, { Weight = syncedWeight })
            
            pcall(firesignal, RECaughtFishVisual.OnClientEvent, Players.LocalPlayer, castPos, targetFish.Name, { Weight = syncedWeight }) 
            
            local fishMetadata = { Weight = syncedWeight }
            if fakeFishState.useGolden then fishMetadata.golden = true end
            if fakeFishState.useRainbow then fishMetadata.rainbow = true end
            
            -- NOTIFICATION
            pcall(firesignal, REObtainedNewFishNotification.OnClientEvent, targetFish.Id, fishMetadata, {
                CustomDuration = 5, Type = "Item", ItemType = "Fish", _newlyIndexed = false,
                InventoryItem = { Id = targetFish.Id, Favorited = false, UUID = fakeUUID, Metadata = fishMetadata },
                ItemId = targetFish.Id
            }, false)
            
            -- UPDATE UI
            updateModifierUI_Fake()
            updateBagSizeUI_Fake()
            
            -- INJECT INVENTORY (CLIENT SIDE)
            if fakeFishState.injectToInventory then
                task.spawn(function()
                    task.wait(0.3)
                    pcall(function()
                        local DataReplion = _G.Replion.Client:WaitReplion("Data")
                        if not DataReplion then return end
                        local currentInventory = DataReplion:Get({"Inventory", "Items"}) or {}
                        local fakeInventoryItem = { Id = targetFish.Id, UUID = fakeUUID, Favorited = false, Metadata = fishMetadata }
                        table.insert(currentInventory, fakeInventoryItem)
                        DataReplion:Set({"Inventory", "Items"}, currentInventory)
                    end)
                end)
            end
            pcall(function()
                        local PlayerGui = _G.LocalPlayer:FindFirstChild("PlayerGui")
                        if PlayerGui then
                            local label = PlayerGui.Backpack.Display.Inventory.Notification.Label
                            local notif = PlayerGui.Backpack.Display.Inventory.Notification
                            local currentNum = tonumber(label.Text) or 0
                            label.Text = tostring(currentNum + 1)
                            notif.Visible = true
                        end
                    end)
        end)
        
        if not loopSuccess then task.wait(1) end
        task.wait(fakeFishState.delay)
    end
end

_G.Lock1 = _G.FakeFishSection:Toggle({
    Title = "Enable Super Fishing",
    Desc = "high-speed fishing.",
    Callback = function(val)
        fakeFishState.enabled = val
        if fakeFishState.thread then 
            task.cancel(fakeFishState.thread)
            fakeFishState.thread = nil 
        end

        if val then
            if not firesignal then
                NotifyError("Error", "Your executor does not support 'firesignal'. Feature disabled.")
                return
            end
            
            ensureFakeDataLoaded()
            if #fakeFishState.FishDB_List == 0 then
                NotifyError("Error", "Failed to load fish data. Try rejoining.")
                return
            end
            
            fakeFishState.thread = task.spawn(startSuperFishingLoop)
            NotifySuccess("Super Fishing", "Started! Enjoy the show.")
        else
            NotifyWarning("Super Fishing", "Stopped.")
        end
    end
})

_G.Lock2 = _G.FakeFishSection:Slider({
    Title = "Catch Speed (Delay)",
    Desc = "Lower = Faster (0.05 is insanely fast)",
    Value = { Min = 0.01, Max = 1.0, Default = 0.05 },
    Step = 0.01,
    Callback = function(v)
        fakeFishState.delay = tonumber(v) or 0.05
        fakeFishState.stepDelay = tonumber(v) or 0.05
    end
})

_G.Lock3 = _G.FakeFishSection:Dropdown({
    Title = "Filter Rarity",
    Desc = "Only catch these rarities",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET" },
    Multi = true,
    AllowNone = true,
    Callback = function(v)
        fakeFishState.selectedRarities = v or {}
    end
})

_G.FakeFishSection:Space()

-------------------------------------------
----- =======[ ANIMATION TAB ]
-------------------------------------------


_G.CustomAnimationEnabled = false
_G.SelectedAnimationWeapon = "Holy Trident"

_G.Animations = require(
    game:GetService("ReplicatedStorage").Modules.Animations
)

_G.OriginalGetAnimation = _G.Animations.GetAnimation

_G.AnimationPresets = {
    ["The Vanquisher"] = {
        StartRodCharge   = "The Vanquisher - StartRodCharge",
        RodThrow         = "The Vanquisher - RodThrow",
        ReelStart        = "The Vanquisher - ReelStart",
        ReelingIdle      = "The Vanquisher - ReelingIdle",
        ReelIntermission = "The Vanquisher - ReelIntermission",
        FishCaught       = "The Vanquisher - FishCaught",
        EquipIdle        = "The Vanquisher - EquipIdle",
    },

    ["Soul Scythe"] = {
        StartRodCharge   = "Soul Scythe - StartRodCharge",
        RodThrow         = "Soul Scythe - RodThrow",
        ReelStart        = "Soul Scythe - ReelStart",
        ReelingIdle      = "Soul Scythe - ReelingIdle",
        ReelIntermission = "Soul Scythe - ReelIntermission",
        FishCaught       = "Soul Scythe - FishCaught",
        EquipIdle        = "Soul Scythe - EquipIdle",
    },

    ["Princess Parasol"] = {
        StartRodCharge   = "Princess Parasol - StartRodCharge",
        RodThrow         = "Princess Parasol - RodThrow",
        ReelStart        = "Princess Parasol - ReelStart",
        ReelingIdle      = "Princess Parasol - ReelingIdle",
        ReelIntermission = "Princess Parasol - ReelIntermission",
        FishCaught       = "Princess Parasol - FishCaught",
        EquipIdle        = "Princess Parasol - EquipIdle",
    },

    ["Oceanic Harpoon"] = {
        StartRodCharge   = "Oceanic Harpoon - StartRodCharge",
        RodThrow         = "Oceanic Harpoon - RodThrow",
        ReelStart        = "Oceanic Harpoon - ReelStart",
        ReelingIdle      = "Oceanic Harpoon - ReelingIdle",
        ReelIntermission = "Oceanic Harpoon - ReelIntermission",
        FishCaught       = "Oceanic Harpoon - FishCaught",
        EquipIdle        = "Oceanic Harpoon - EquipIdle",
    },

    ["Holy Trident"] = {
        StartRodCharge   = "Holy Trident - StartRodCharge",
        RodThrow         = "Holy Trident - RodThrow",
        ReelStart        = "Holy Trident - ReelStart",
        ReelingIdle      = "Holy Trident - ReelingIdle",
        ReelIntermission = "Holy Trident - ReelIntermission",
        FishCaught       = "Holy Trident - FishCaught",
        EquipIdle        = "Holy Trident - EquipIdle",
    },

    ["Gingerbread Katana"] = {
        StartRodCharge   = "Gingerbread Katana - StartRodCharge",
        RodThrow         = "Gingerbread Katana - RodThrow",
        ReelStart        = "Gingerbread Katana - ReelStart",
        ReelingIdle      = "Gingerbread Katana - ReelingIdle",
        ReelIntermission = "Gingerbread Katana - ReelIntermission",
        FishCaught       = "Gingerbread Katana - FishCaught",
        EquipIdle        = "Gingerbread Katana - EquipIdle",
    },

    ["Frozen Krampus Scythe"] = {
        StartRodCharge   = "Frozen Krampus Scythe - StartRodCharge",
        RodThrow         = "Frozen Krampus Scythe - RodThrow",
        ReelStart        = "Frozen Krampus Scythe - ReelStart",
        ReelingIdle      = "Frozen Krampus Scythe - ReelingIdle",
        ReelIntermission = "Frozen Krampus Scythe - ReelIntermission",
        FishCaught       = "Frozen Krampus Scythe - FishCaught",
        EquipIdle        = "Frozen Krampus Scythe - EquipIdle",
    },

    ["Eternal Flower"] = {
        StartRodCharge   = "Eternal Flower - StartRodCharge",
        RodThrow         = "Eternal Flower - RodThrow",
        ReelStart        = "Eternal Flower - ReelStart",
        ReelingIdle      = "Eternal Flower - ReelingIdle",
        ReelIntermission = "Eternal Flower - ReelIntermission",
        FishCaught       = "Eternal Flower - FishCaught",
        EquipIdle        = "Eternal Flower - EquipIdle",
    },

    ["Eclipse Katana"] = {
        StartRodCharge   = "Eclipse Katana - StartRodCharge",
        RodThrow         = "Eclipse Katana - RodThrow",
        ReelStart        = "Eclipse Katana - ReelStart",
        ReelingIdle      = "Eclipse Katana - ReelingIdle",
        ReelIntermission = "Eclipse Katana - ReelIntermission",
        FishCaught       = "Eclipse Katana - FishCaught",
        EquipIdle        = "Eclipse Katana - EquipIdle",
    },

    ["Corruption Edge"] = {
        StartRodCharge   = "Corruption Edge - StartRodCharge",
        RodThrow         = "Corruption Edge - RodThrow",
        ReelStart        = "Corruption Edge - ReelStart",
        ReelingIdle      = "Corruption Edge - ReelingIdle",
        ReelIntermission = "Corruption Edge - ReelIntermission",
        FishCaught       = "Corruption Edge - FishCaught",
        EquipIdle        = "Corruption Edge - EquipIdle",
    },

    ["Christmas Parasol"] = {
        StartRodCharge   = "Christmas Parasol - StartRodCharge",
        RodThrow         = "Christmas Parasol - RodThrow",
        ReelStart        = "Christmas Parasol - ReelStart",
        ReelingIdle      = "Christmas Parasol - ReelingIdle",
        ReelIntermission = "Christmas Parasol - ReelIntermission",
        FishCaught       = "Christmas Parasol - FishCaught",
        EquipIdle        = "Christmas Parasol - EquipIdle",
    },

    ["Blackhole Sword"] = {
        StartRodCharge   = "Blackhole Sword - StartRodCharge",
        RodThrow         = "Blackhole Sword - RodThrow",
        ReelStart        = "Blackhole Sword - ReelStart",
        ReelingIdle      = "Blackhole Sword - ReelingIdle",
        ReelIntermission = "Blackhole Sword - ReelIntermission",
        FishCaught       = "Blackhole Sword - FishCaught",
        EquipIdle        = "Blackhole Sword - EquipIdle",
    },

    ["Binary Edge"] = {
        StartRodCharge   = "Binary Edge - StartRodCharge",
        RodThrow         = "Binary Edge - RodThrow",
        ReelStart        = "Binary Edge - ReelStart",
        ReelingIdle      = "Binary Edge - ReelingIdle",
        ReelIntermission = "Binary Edge - ReelIntermission",
        FishCaught       = "Binary Edge - FishCaught",
        EquipIdle        = "Binary Edge - EquipIdle",
    },

    ["1x1x1x1 Ban Hammer"] = {
        StartRodCharge   = "1x1x1x1 Ban Hammer - StartRodCharge",
        RodThrow         = "1x1x1x1 Ban Hammer - RodThrow",
        ReelStart        = "1x1x1x1 Ban Hammer - ReelStart",
        ReelingIdle      = "1x1x1x1 Ban Hammer - ReelingIdle",
        ReelIntermission = "1x1x1x1 Ban Hammer - ReelIntermission",
        FishCaught       = "1x1x1x1 Ban Hammer - FishCaught",
        EquipIdle        = "1x1x1x1 Ban Hammer - EquipIdle",
    },
}

_G.AnimationBackup = _G.AnimationBackup or {}

for name, anim in pairs(_G.Animations) do
    if typeof(anim) == "Instance" then
        _G.AnimationBackup[name] = anim
    end
end

_G.ApplyAnimationPreset = function()
    -- restore dulu
    for name, anim in pairs(_G.AnimationBackup) do
        _G.Animations[name] = anim
    end

    if not _G.CustomAnimationEnabled then
        return
    end

    local preset = _G.AnimationPresets[_G.SelectedAnimationWeapon]
    if not preset then
        return
    end

    for defaultName, overrideName in pairs(preset) do
        if _G.Animations[overrideName] then
            _G.Animations[defaultName] = _G.Animations[overrideName]
        end
    end
end

_G.ResolveAnimation = function(name)
    if not _G.CustomAnimationEnabled then
        return _G.Animations[name]
    end

    local preset = _G.AnimationPresets[_G.SelectedAnimationWeapon]
    if not preset then
        return _G.Animations[name]
    end

    local overrideName = preset[name]
    if overrideName and _G.Animations[overrideName] then
        return _G.Animations[overrideName]
    end

    return _G.Animations[name]
end

if typeof(_G.OriginalGetAnimation) == "function" then
    _G.Animations.GetAnimation = function(self, name)
        return _G.ResolveAnimation(name)
    end
end

_G.AnimSec:Dropdown({
    Title = "Custom Animation Weapon",
    Values = {
        "The Vanquisher",
        "Soul Scythe",
        "Princess Parasol",
        "Oceanic Harpoon",
        "Holy Trident",
        "Gingerbread Katana",
        "Frozen Krampus Scythe",
        "Eternal Flower",
        "Eclipse Katana",
        "Corruption Edge",
        "Christmas Parasol",
        "Blackhole Sword",
        "Binary Edge",
        "1x1x1x1 Ban Hammer",
    },
    Value = "Holy Trident",
    Callback = _G.ProtectCallback(function(option)
        _G.SelectedAnimationWeapon = option
        _G.ApplyAnimationPreset()
    end)
})

_G.AnimSec:Toggle({
    Title = "Enable Custom Animations",
    Value = false,
    Callback = function(state)
        _G.CustomAnimationEnabled = state
        _G.ApplyAnimationPreset()
    end
})

-- ======================================================
-- SERVICES
-- ======================================================
_G.ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ======================================================
-- LOAD REPLION CLIENT
-- ======================================================
_G.ReplionClient = require(
    _G.ReplicatedStorage
        .Packages
        ._Index["ytrev_replion@2.0.0-rc.3"]
        .replion
        .Client
)

-- ======================================================
-- VARIANT LIST (GLOBAL)
-- ======================================================
_G.AllVariants = {
    "1x1x1x1",
    "Albino",
    "Artic Frost",
    "Bloodmoon",
    "Color Burn",
    "Corrupt",
    "Disco",
    "Fairy Dust",
    "Festive",
    "Frozen",
    "Galaxy",
    "Gemstone",
    "Ghost",
    "Gold",
    "Holograpich",
    "Leviathan's Rage",
    "Lightning",
    "Midnight",
    "Moon Fragment",
    "Noob",
    "Radioactive",
    "Sandy",
    "Stone"
}

-- ======================================================
-- FISH DATABASE
-- ======================================================
_G.FishDatabase = {
    ["Leviathan"] = {
        Id = 626,
        BigWeight = {740000, 880000},
        SmallWeight = {550000, 720000},
        Variants = _G.AllVariants
    },
    ["Bloodmoon Whale"] = {
        Id = 342,
        BigWeight = {472110, 525580},
        SmallWeight = {362780, 464180},
        Variants = _G.AllVariants
    },
    ["Strawberry Choc Megalodon"] = {
        Id = 468,
        BigWeight = {395000, 450000},
        SmallWeight = {305000, 365000},
        Variants = _G.AllVariants
    },
    ["Icebreaker Whale"] = {
        Id = 539,
        BigWeight = {460000, 500000},
        SmallWeight = {360000, 440000},
        Variants = _G.AllVariants
    },
    ["1x1x1x1 Comet Shark"] = {
        Id = 448,
        BigWeight = {352000, 455000},
        SmallWeight = {262000, 344000},
        Variants = _G.AllVariants
    },
    ["Pirate Megalodon"] = {
        Id = 627,
        BigWeight = {395000, 450000},
        SmallWeight = {305000, 365000},
        Variants = _G.AllVariants
    },
    ["Zombie Megalodon"] = {
        Id = 319,
        BigWeight = {395000, 450000},
        SmallWeight = {305000, 365000},
        Variants = _G.AllVariants
    },
    ["Ruby"] = {
        Id = 243,
        BigWeight = {7, 21},
        SmallWeight = {5, 5},
        Variants = "Gemstone" -- Fixed variant, tidak random
    }
}

-- ======================================================
-- CONFIG
-- ======================================================
_G.SelectedFish = "Leviathan" -- Default selection
_G.RandomVariant = true -- Default random variant enabled

-- ======================================================
-- FAKE FISH FUNCTION (DUPLICATE)
-- ======================================================
function _G.ApplyFakeFish()
    pcall(function()
        local fishData = _G.FishDatabase[_G.SelectedFish]
        if not fishData then
            warn("[ERROR] Fish not found in database!")
            return
        end
        
        local data = _G.ReplionClient:WaitReplion("Data")
        local items = data:Get({ "Inventory", "Items" })
        local cloned = table.clone(items)
        
        for _, item in ipairs(cloned) do
            item.Id = fishData.Id
            item.Metadata = item.Metadata or {}
            
            -- Random weight (80% big, 20% small)
            local isBig = math.random() < 0.8
            
            if isBig then
                item.Metadata.Weight = math.random(fishData.BigWeight[1], fishData.BigWeight[2])
            else
                item.Metadata.Weight = math.random(fishData.SmallWeight[1], fishData.SmallWeight[2])
            end
            
            -- Handle variant (fixed string atau random dari table)
            if type(fishData.Variants) == "string" then
                -- Fixed variant (contoh: Ruby selalu "Gemstone")
                item.Metadata.VariantId = fishData.Variants
            elseif type(fishData.Variants) == "table" and #fishData.Variants > 0 then
                -- Random atau fixed variant dari table
                if _G.RandomVariant then
                    local randomIndex = math.random(1, #fishData.Variants)
                    item.Metadata.VariantId = fishData.Variants[randomIndex]
                else
                    item.Metadata.VariantId = fishData.Variants[1] -- Default ke variant pertama
                end
            end
        end
        
        data:Set({ "Inventory", "Items" }, cloned)
        
        local variantStatus = _G.RandomVariant and "Random Variant" or "Fixed Variant"
        warn("[SUCCESS] All inventory items converted to " .. _G.SelectedFish .. " (" .. variantStatus .. ")")
    end)
end

-- ======================================================
-- UI SECTION
-- ======================================================
_G.AnimSec = _G.BugFish:Section({
    Title = "Duplicate Fish",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = false
})

-- Dropdown untuk memilih fish
_G.FishDropdown = _G.AnimSec:Dropdown({
    Title = "Select Fish",
    Desc = "Choose fish to duplicate",
    Values = {
        "Leviathan",
        "Bloodmoon Whale",
        "Strawberry Choc Megalodon",
        "Icebreaker Whale",
        "1x1x1x1 Comet Shark",
        "Pirate Megalodon",
        "Zombie Megalodon",
        "Ruby"
    },
    Value = "Leviathan",
    Multi = false,
    Callback = function(selected)
        _G.SelectedFish = selected
        warn("[INFO] Selected fish: " .. selected)
    end
})

-- Toggle untuk random variant
_G.VariantToggle = _G.AnimSec:Toggle({
    Title = "Random Variant",
    Desc = "Enable random variant for duplicated fish",
    Value = true,
    Callback = function(value)
        _G.RandomVariant = value
        local status = value and "Enabled" or "Disabled"
        warn("[INFO] Random Variant " .. status)
    end
})

-- Button untuk duplicate
_G.AnimSec:Button({
    Title = "Duplicate Selected Fish",
    Callback = function()
        _G.ApplyFakeFish()
    end
})
-------------------------------------------
----- =======[ AUTO FAV TAB ]
-------------------------------------------


local GlobalFav = {
    REObtainedNewFishNotification = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"],
    REFavoriteItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FavoriteItem"],

    FishIdToName = {},
    FishNameToId = {},
    FishNames = {},
    FishRarity = {},
    Variants = {},
    SelectedFishIds = {},
    SelectedVariants = {},
    SelectedRarities = {},
    AutoFavoriteEnabled = false
}

local TierToRarityName = {
    [3] = "RARE",
    [4] = "EPIC",
    [5] = "LEGENDARY",
    [6] = "MYTHIC",
    [7] = "SECRET"
}

for _, item in ipairs(ReplicatedStorage.Items:GetChildren()) do
    local ok, data = pcall(require, item)
    if ok and data.Data and data.Data.Type == "Fish" then
        local id = data.Data.Id
        local name = data.Data.Name
        local tier = data.Data.Tier or 1

        local nameWithId = name .. " [ID:" .. id .. "]"

        GlobalFav.FishIdToName[id] = nameWithId
        GlobalFav.FishNameToId[nameWithId] = id
        GlobalFav.FishRarity[id] = tier

        table.insert(GlobalFav.FishNames, nameWithId)
    end
end

-- Load Variants (BY NAME, MATCH METADATA)
for _, variantModule in pairs(ReplicatedStorage.Variants:GetChildren()) do
    local ok, variantData = pcall(require, variantModule)
    if ok and variantData.Data and variantData.Data.Name then
        local name = variantData.Data.Name
        GlobalFav.Variants[name] = name
    end
end

AutoFav:Section({
    Title = "Auto Favorite Menu",
    TextSize = 22,
    TextXAlignment = "Center",
})

_G.FavToggle = AutoFav:Toggle({
    Title = "Enable Auto Favorite",
    Value = false,
    Callback = function(state)
        GlobalFav.AutoFavoriteEnabled = state
        if state then
            NotifySuccess("Auto Favorite", "Auto Favorite feature enabled")
        else
            NotifyWarning("Auto Favorite", "Auto Favorite feature disabled")
        end
    end
})

myConfig:Register("ToggleFav", _G.FavToggle)

local fishName = GlobalFav.FishIdToName[itemId]

_G.FishList = AutoFav:Dropdown({
    Title = "Auto Favorite Fishes",
    Values = GlobalFav.FishNames,
    Value = {},
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedNames)
        GlobalFav.SelectedFishIds = {}

        for _, nameWithId in ipairs(selectedNames) do
            local id = GlobalFav.FishNameToId[nameWithId]
            if id then
                GlobalFav.SelectedFishIds[id] = true
            end
        end

        NotifyInfo("Auto Favorite", "Favoriting fish: " .. HttpService:JSONEncode(selectedNames))
    end)
})

GlobalFav.VariantList = {}

for variantName, _ in pairs(GlobalFav.Variants) do
    table.insert(GlobalFav.VariantList, variantName)
end

table.sort(GlobalFav.VariantList)


_G.FavVariantDropdown = AutoFav:Dropdown({
    Title = "Auto Favorite Variants",
    Values = GlobalFav.VariantList,
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedVariants)
        GlobalFav.SelectedVariants = {}

        for _, vName in ipairs(selectedVariants) do
            GlobalFav.SelectedVariants[vName] = true
        end

        NotifyInfo(
            "Auto Favorite",
            "Favoriting variants: " .. table.concat(selectedVariants, ", ")
        )
    end)
})

myConfig:Register("FavVariants", _G.FavVariantDropdown)

-- Rarity dropdown
local rarityList = {}
for tier, name in pairs(TierToRarityName) do
    table.insert(rarityList, name)
end

_G.FavRarityDropdown = AutoFav:Dropdown({
    Title = "Auto Favorite by Rarity",
    Values = rarityList,
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedRarities)
        GlobalFav.SelectedRarities = {}
        for _, rarityName in ipairs(selectedRarities) do
            for tier, name in pairs(TierToRarityName) do
                if name == rarityName then
                    GlobalFav.SelectedRarities[tier] = true
                end
            end
        end
        NotifyInfo("Auto Favorite", "Favoriting active for rarities: " .. HttpService:JSONEncode(selectedRarities))
    end)
})

myConfig:Register("FavRarity", _G.FavRarityDropdown)

function GlobalFav.ShouldFavorite(itemId, variantName, tier)
    local hasFish = next(GlobalFav.SelectedFishIds) ~= nil
    local hasVariant = next(GlobalFav.SelectedVariants) ~= nil
    local hasRarity = next(GlobalFav.SelectedRarities) ~= nil

    local matchFish =
        not hasFish or GlobalFav.SelectedFishIds[itemId]

    local matchVariant =
        not hasVariant or (variantName and GlobalFav.SelectedVariants[variantName])

    local matchRarity =
        not hasRarity or GlobalFav.SelectedRarities[tier]

    return matchFish and matchVariant and matchRarity
end

GlobalFav.REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
    if not GlobalFav.AutoFavoriteEnabled then return end
    if not data or not data.InventoryItem then return end

    local uuid = data.InventoryItem.UUID
    if not uuid then return end

    local variantName =
    data.InventoryItem.Metadata
    and (data.InventoryItem.Metadata.VariantId
        or data.InventoryItem.Metadata.VariantName
        or data.InventoryItem.Metadata.Variant)

    local tier = GlobalFav.FishRarity[itemId] or 1

    if GlobalFav.ShouldFavorite(itemId, variantName, tier) then
        GlobalFav.REFavoriteItem:FireServer(uuid)
    end
end)

---------------------------------------------------------------------
-- FUNGSI BARU: SCAN INVENTORY & EKSEKUSI (LOCK / UNLOCK)
---------------------------------------------------------------------
function GlobalFav.ProcessInventory(action)
    
    local actionName = action and "Favorite" or "Unfavorite"
    
    if not _G.DataReplion then 
        NotifyWarning("Inventory Scan", "Data Replion not found. Please wait...")
        return 
    end

    local inventory = _G.DataReplion:Get({"Inventory", "Items"})
    if not inventory then 
        NotifyWarning("Inventory Scan", "No fish found in inventory.")
        return 
    end

    local count = 0
    NotifyInfo(actionName, "Scanning inventory...")

    for key, item in pairs(inventory) do
        local uuid = item.UUID or key
        local itemId = item.Id
        local tier = GlobalFav.FishRarity[itemId] or 1
        local currentLocked = item.Favorited or false
    
        if currentLocked ~= action then
            local variantName =
                item.Metadata
                and (item.Metadata.VariantId
                    or item.Metadata.VariantName
                    or item.Metadata.Variant)
    
            if GlobalFav.ShouldFavorite(itemId, variantName, tier) then
                GlobalFav.REFavoriteItem:FireServer(uuid)
                count = count + 1
                task.wait(0.1)
            end
        end
    end

    NotifySuccess(actionName, "Finished! Processed " .. count .. " items.")
end

AutoFav:Space()

AutoFav:Button({
    Title = "Favorite Fish",
    Justify = "Center",
    Icon = "",
    Callback = function()
        GlobalFav.ProcessInventory(true) -- True untuk Lock
    end
})

AutoFav:Space()

AutoFav:Button({
    Title = "Unfavorite All Fish",
    Justify = "Center",
    Icon = "",
    Callback = function()
        GlobalFav.ProcessInventory(false)
    end
})


-------------------------------------------
----- =======[ AUTO FARM TAB ]
-------------------------------------------


local floatPlatform = nil

local function floatingPlat(enabled)
    if enabled then
        local charFolder = workspace:WaitForChild("Characters", 5)
        local char = charFolder:FindFirstChild(LocalPlayer.Name)
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        floatPlatform = Instance.new("Part")
        floatPlatform.Anchored = true
        floatPlatform.Size = Vector3.new(10, 1, 10)
        floatPlatform.Transparency = 1
        floatPlatform.CanCollide = true
        floatPlatform.Name = "FloatPlatform"
        floatPlatform.Parent = workspace

        task.spawn(function()
            while floatPlatform and floatPlatform.Parent do
                pcall(function()
                    floatPlatform.Position = hrp.Position - Vector3.new(0, 3.5, 0)
                end)
                task.wait(0.1)
            end
        end)

        NotifySuccess("Float Enabled", "This feature has been successfully activated!")
    else
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
        NotifyWarning("Float Disabled", "Feature disabled")
    end
end



local workspace = game:GetService("Workspace")

local BlockEnabled = false

local function createLocalBlock(size, position, color)
    local part = Instance.new("Part")
    part.Size = size or Vector3.new(5, 1, 5)
    part.Position = position or
    (LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, -3, 0)) or
    Vector3.new(0, 5, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Color = color or Color3.fromRGB(0, 0, 255)
    part.Material = Enum.Material.ForceField
    part.Name = "LocalBlock"
    part.Parent = workspace
    return part
end


local function createBlockUnderPlayer()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if workspace:FindFirstChild("LocalBlock") then
            workspace.LocalBlock:Destroy()
        end
        createLocalBlock(Vector3.new(6, 1, 6), hrp.Position - Vector3.new(0, 3, 0), Color3.fromRGB(0, 0, 255))
    end
end


function _G.ToggleBlockOnce(state)
    BlockEnabled = state
    if state then
        createBlockUnderPlayer()
    else
        if workspace:FindFirstChild("LocalBlock") then
            workspace.LocalBlock:Destroy()
        end
    end
end


local isAutoFarmRunning = false

local islandCodes = {
    ["01"] = "Crater Islands",
    ["02"] = "Tropical Grove",
    ["03"] = "Vulcano",
    ["04"] = "Coral Reefs",
    ["05"] = "Winter",
    ["06"] = "Machine",
    ["07"] = "Treasure Room",
    ["08"] = "Sisyphus Statue",
    ["09"] = "Fisherman Island",
    ["10"] = "Esoteric Depths",
    ["11"] = "Kohana",
    ["12"] = "Underground Cellar",
    ["13"] = "Ancient Jungle",
    ["14"] = "Secret Farm Ancient",
    ["15"] = "The Temple (Unlock First)",
    ["16"] = "Ancient Ruin",
    ["17"] = "Pirate Cove"
}

local farmLocations = {
    ["Crater Islands"] = {
        CFrame.new(1066.1864, 57.2025681, 5045.5542, -0.682534158, 1.00865822e-08, 0.730853677, -5.8900711e-09, 1,
            -1.93017531e-08, -0.730853677, -1.74788859e-08, -0.682534158),
        CFrame.new(1057.28992, 33.0884132, 5133.79883, 0.833871782, 5.44149223e-08, 0.551958203, -6.58184218e-09, 1,
            -8.86416984e-08, -0.551958203, 7.02829084e-08, 0.833871782),
        CFrame.new(988.954712, 42.8254471, 5088.71289, -0.849417388, -9.89310394e-08, 0.527721584, -5.96115086e-08, 1,
            9.15179328e-08, -0.527721584, 4.62786431e-08, -0.849417388),
        CFrame.new(1006.70685, 17.2302666, 5092.14844, -0.989664078, 5.6538525e-09, -0.143405005, 9.14879283e-09, 1,
            -2.3711717e-08, 0.143405005, -2.47786183e-08, -0.989664078),
        CFrame.new(1025.02356, 2.77259707, 5011.47021, -0.974474192, -6.87871804e-08, 0.224499553, -4.47472104e-08, 1,
            1.12170284e-07, -0.224499553, 9.92613209e-08, -0.974474192),
        CFrame.new(1071.14551, 3.528404, 5038.00293, -0.532300115, 3.38677708e-08, 0.84655571, 6.69992914e-08, 1,
            2.12149165e-09, -0.84655571, 5.7847906e-08, -0.532300115),
        CFrame.new(1022.55457, 16.6277809, 5066.28223, 0.721996129, 0, -0.691897094, 0, 1, 0, 0.691897094, 0, 0.721996129),
    },
    ["Tropical Grove"] = {
        CFrame.new(-2165.05469, 2.77070165, 3639.87451, -0.589090407, -3.61497356e-08, -0.808067143, -3.20645626e-08, 1,
            -2.13606164e-08, 0.808067143, 1.3326984e-08, -0.589090407)
    },
    ["Vulcano"] = {
        CFrame.new(-701.447937, 48.1446075, 93.1546631, -0.0770962164, 1.34335654e-08, -0.997023642, 9.84464776e-09, 1,
            1.27124169e-08, 0.997023642, -8.83526763e-09, -0.0770962164),
        CFrame.new(-654.994934, 57.2567711, 75.098526, -0.540957272, 2.58946509e-09, -0.841050088, -7.58775585e-08, 1,
            5.18827363e-08, 0.841050088, 9.1883166e-08, -0.540957272),
    },
    ["Coral Reefs"] = {
        CFrame.new(-3118.39624, 2.42531538, 2135.26392, 0.92336154, -1.0069185e-07, -0.383931547, 8.0607947e-08, 1,
            -6.84016968e-08, 0.383931547, 3.22115596e-08, 0.92336154),
    },
    ["Winter"] = {
        CFrame.new(2036.15308, 6.54998732, 3381.88916, 0.943401575, 4.71338666e-08, -0.331652641, -3.28136842e-08, 1,
            4.87781051e-08, 0.331652641, -3.51345975e-08, 0.943401575),
    },
    ["Machine"] = {
        CFrame.new(-1459.3772, 14.7103214, 1831.5188, 0.777951121, 2.52131862e-08, -0.628324807, -5.24126378e-08, 1,
            -2.47663063e-08, 0.628324807, 5.21991339e-08, 0.777951121)
    },
    ["Treasure Room"] = {
        CFrame.new(-3625.0708, -279.074219, -1594.57605, 0.918176472, -3.97606392e-09, -0.396171629, -1.12946204e-08, 1,
            -3.62128851e-08, 0.396171629, 3.77244298e-08, 0.918176472),
        CFrame.new(-3600.72632, -276.06427, -1640.79663, -0.696130812, -6.0491181e-09, 0.717914939, -1.09490363e-08, 1,
            -2.19084972e-09, -0.717914939, -9.38559541e-09, -0.696130812),
        CFrame.new(-3548.52222, -269.309845, -1659.26685, 0.0472991578, -4.08685423e-08, 0.998880744, -7.68598838e-08, 1,
            4.45538149e-08, -0.998880744, -7.88812216e-08, 0.0472991578),
        CFrame.new(-3581.84155, -279.09021, -1696.15637, -0.999634147, -0.000535600528, -0.0270430837, -0.000448358158,
            0.999994695, -0.00323198596, 0.0270446707, -0.00321867829, -0.99962908),
        CFrame.new(-3601.34302, -282.790955, -1629.37036, -0.526346684, 0.00143659476, 0.850268841, -0.000266355521,
            0.999998271, -0.00185445137, -0.850269973, -0.00120255165, -0.526345372)
    },
    ["Sisyphus Statue"] = {
        CFrame.new(-3777.43433, -135.074417, -975.198975, -0.284491211, -1.02338751e-08, -0.958678663, 6.38407585e-08, 1,
            -2.96199456e-08, 0.958678663, -6.96293867e-08, -0.284491211),
        
        CFrame.new(-3697.77124, -135.074417, -886.946411, 0.979794085, -9.24526766e-09, 0.200008959, 1.35701708e-08, 1,
            -2.02526174e-08, -0.200008959, 2.25575487e-08, 0.979794085),
        CFrame.new(-3764.021, -135.074417, -903.742493, 0.785813689, -3.05788426e-08, -0.618463278, -4.87374336e-08, 1,
            -1.11368585e-07, 0.618463278, 1.17657272e-07, 0.785813689)
    },
    ["Fisherman Island"] = {
        CFrame.new(-75.2439423, 3.24433279, 3103.45093, -0.996514142, -3.14880424e-08, -0.0834242329, -3.84156422e-08, 1,
            8.14354024e-08, 0.0834242329, 8.43563228e-08, -0.996514142),
        CFrame.new(-162.285294, 3.26205397, 2954.47412, -0.74356699, -1.93168272e-08, -0.668661416, 1.03873425e-08, 1,
            -4.04397653e-08, 0.668661416, -3.70152904e-08, -0.74356699),
        CFrame.new(-69.8645096, 3.2620542, 2866.48096, 0.342575252, 8.79649331e-09, 0.939490378, 4.78986739e-10, 1,
            -9.53770485e-09, -0.939490378, 3.71738529e-09, 0.342575252),
        CFrame.new(247.130951, 2.47001815, 3001.72412, -0.724809051, -8.27166033e-08, -0.688949764, -8.16509669e-08, 1,
            -3.41610367e-08, 0.688949764, 3.14931867e-08, -0.724809051)
    },
    ["Esoteric Depths"] = {
        CFrame.new(3253.26099, -1293.7677, 1435.24756, 0.21652025, -3.88184027e-08, -0.976278126, 1.20091812e-08, 1,
            -3.70982107e-08, 0.976278126, -3.69178754e-09, 0.21652025),
        CFrame.new(3299.66333, -1302.85474, 1370.98621, -0.440755099, -5.91509552e-09, 0.897627413, -2.5926683e-09, 1,
            5.31664224e-09, -0.897627413, 1.60869356e-11, -0.440755099),
        CFrame.new(3250.94531, -1302.85547, 1324.77942, -0.998184919, 5.84032058e-08, 0.0602233484, 5.50187451e-08, 1,
            -5.78567096e-08, -0.0602233484, -5.44382814e-08, -0.998184919),
        CFrame.new(3219.16309, -1294.03394, 1364.41492, 0.676777482, -4.18104094e-08, -0.736187637, 8.28715798e-08, 1,
            1.93907237e-08, 0.736187637, -7.41322381e-08, 0.676777482)
    },
    ["Kohana"] = {
        CFrame.new(-921.516602, 24.5000591, 373.572754, -0.315036476, -3.65496575e-08, -0.949079573, -2.09816324e-08, 1,
            -3.15460156e-08, 0.949079573, 9.97509186e-09, -0.315036476),
        CFrame.new(-821.466125, 18.0640106, 442.570953, 0.502961993, 3.55151641e-08, 0.864308536, -2.61714685e-08, 1,
            -2.58610324e-08, -0.864308536, -9.61310764e-09, 0.502961993),
        CFrame.new(-656.069275, 17.2500572, 450.77124, 0.899714053, -3.28262595e-09, -0.436479777, -5.17725418e-09, 1,
            -1.81925373e-08, 0.436479777, 1.86278477e-08, 0.899714053),
        CFrame.new(-584.202759, 17.2500572, 459.276672, 0.0987685546, 5.48308599e-09, 0.995110452, -6.92575881e-08, 1,
            1.36405531e-09, -0.995110452, -6.90536694e-08, 0.0987685546),
    },
    ["Underground Cellar"] = {
        CFrame.new(2159.65723, -91.198143, -730.99707, -0.392579645, -1.64555736e-09, 0.919718027, 4.08579943e-08, 1,
            1.92293435e-08, -0.919718027, 4.51268818e-08, -0.392579645),
        CFrame.new(2114.22144, -91.1976471, -732.656738, -0.543168366, -3.4070105e-08, -0.839623809, 2.10003783e-08, 1,
            -5.41633582e-08, 0.839623809, -4.70522394e-08, -0.543168366),
        CFrame.new(2134.35767, -91.1985855, -698.182983, 0.989448071, -1.28799131e-08, -0.144888103, 2.66212989e-08, 1,
            9.29025887e-08, 0.144888103, -9.57793915e-08, 0.989448071),
    },
    ["Ancient Jungle"] = {
        CFrame.new(1515.67676, 25.5616989, -306.595856, 0.763029754, -8.87780942e-08, 0.646363378, 5.24343307e-08, 1,
            7.5451581e-08, -0.646363378, -2.36801707e-08, 0.763029754),
        CFrame.new(1489.29553, 6.23855162, -342.620209, -0.831362545, 6.32348289e-08, -0.555730462, 7.59748353e-09, 1,
            1.02421176e-07, 0.555730462, 8.09269736e-08, -0.831362545),
        CFrame.new(1467.59143, 7.2090292, -324.716827, -0.086521171, 2.06461745e-08, -0.996250033, -4.92800183e-08, 1,
            2.50037022e-08, 0.996250033, 5.12585707e-08, -0.086521171),
    },
    ["Secret Farm Ancient"] = {
        CFrame.new(2110.91431, -58.1463356, -732.848816, 0.0894816518, -9.7328666e-08, -0.995988488, 5.18647809e-08, 1,
            -9.30610398e-08, 0.995988488, -4.3329468e-08, 0.0894816518)
    },
    ["The Temple (Unlock First)"] = {
        CFrame.new(1479.11865, -22.1250019, -662.669373, 0.161120579, -2.03902815e-08, -0.986934721, -3.03227985e-08, 1,
            -2.56105164e-08, 0.986934721, 3.40530022e-08, 0.161120579),
        CFrame.new(1465.41211, -22.1250019, -670.940002, -0.21706377, -2.10148947e-08, 0.976157427, 3.29077707e-08, 1,
            2.88457365e-08, -0.976157427, 3.83845311e-08, -0.21706377),
        CFrame.new(1470.30334, -12.2246475, -587.052612, -0.101084575, -9.68974163e-08, 0.994877815, -1.47451953e-08, 1,
            9.5898109e-08, -0.994877815, -4.97584818e-09, -0.101084575),
        CFrame.new(1451.19983, -22.1250019, -621.852478, -0.986927867, 8.68970318e-09, -0.161162451, 9.61592317e-09, 1,
            -4.96716179e-09, 0.161162451, -6.4519563e-09, -0.986927867),
        CFrame.new(1499.44788, -22.1250019, -628.441711, -0.985374331, 7.20484294e-08, -0.170403719, 8.45688035e-08, 1,
            -6.62162876e-08, 0.170403719, -7.9658669e-08, -0.985374331)
    },
    ["Ancient Ruin"] = {
        CFrame.new(6096.86865, -585.924683, 4667.34521, -0.0791911632, 5.17708685e-08, 0.996859431, -4.35256062e-08, 1, -5.53916735e-08, -0.996859431, -4.77754405e-08, -0.0791911632),
        CFrame.new(6022.87109, -585.924194, 4631.0127, -0.669677734, -6.96009084e-10, -0.74265182, -5.20333909e-09, 1, 3.75485687e-09, 0.74265182, 6.37881348e-09, -0.669677734),
        CFrame.new(6057.14893, -557.975098, 4485.46631, -0.985172093, -3.35700534e-08, -0.171569183, -3.98707982e-08, 1, 3.32783721e-08, 0.171569183, 3.9625526e-08, -0.985172093)
    },
    ["Pirate Cove"] = {
        CFrame.new(3469.79932, 4.19277096, 3496.23315, 0.598028243, -1.68198007e-08, 0.801475048, 3.59461581e-08, 1, -5.83551296e-09, -0.801475048, 3.22997487e-08, 0.598028243),
        CFrame.new(3423.27734, 4.19297075, 3433.854, -0.852984607, -4.74888253e-08, -0.521936059, -8.19830319e-08, 1, 4.29965361e-08, 0.521936059, 7.94652877e-08, -0.852984607)
    },

}

local function startAutoFarmLoop()
    NotifySuccess("Auto Farm Enabled", "Fishing started on island: " .. selectedIsland)

    while isAutoFarmRunning do
        local islandSpots = farmLocations[selectedIsland]
        if type(islandSpots) == "table" and #islandSpots > 0 then
            location = islandSpots[math.random(1, #islandSpots)]
        else
            location = islandSpots
        end

        if not location then
            NotifyError("Invalid Island", "Selected island name not found.")
            return
        end

        local char = workspace:FindFirstChild("Characters"):FindFirstChild(LocalPlayer.Name)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            NotifyError("Teleport Failed", "HumanoidRootPart not found.")
            return
        end

        hrp.CFrame = location
        task.wait(1.5)
        
        _G.ConfirmFishType = false
        _G.DialogFish = Window:Dialog({
            Icon = "crown",
            Title = "Important!",
            Content = "Please select Auto Fish type!",
            Buttons = {
                {
                    Title = "Auto Fish",
                    Callback = function()
                        StartAutoFish5X()
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Auto Fish Legit",
                    Callback = function()
                        _G.ToggleAutoClick(true)
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Blatant",
                    Callback = function()
                        _G.BlatantState.enabled = true
                        _G.ConfirmFishType = true
                    end,
                },
            },
        })
    
        repeat task.wait() until _G.ConfirmFishType

        while isAutoFarmRunning do
            if not isAutoFarmRunning then
                StopAutoFish5X()
                _G.ToggleAutoClick(false)
                StopCast()
                NotifyWarning("Auto Farm Stopped", "Auto Farm manually disabled. Auto Fish stopped.")
                break
            end
            task.wait(0.5)
        end
    end
end

local nameList = {}
local islandNamesToCode = {}

for code, name in pairs(islandCodes) do
    table.insert(nameList, name)
    islandNamesToCode[name] = code
end

table.sort(nameList)

_G.EventSection = AutoFarmTab:Section({
    Title = "Event Farming Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

_G.FarmSec = AutoFarmTab:Section({
    Title = "Farming Island Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

_G.ArtSec = AutoFarmTab:Section({
    Title = "Farming Artifact Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

_G.RuinSec = AutoFarmTab:Section({
    Title = "Farming Ancient Ruin Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

do
    _G.lastPositionBeforeEvent = nil
    _G.autoJoinEventActive = false
    _G.LOCHNESS_POS = Vector3.new(6063.347, -585.925, 4713.696)
    _G.LOCHNESS_LOOK = Vector3.new(-0.376, -0.000, -0.927)
    _G.EventSyncThread = nil
    
    -- FIXED FUNCTION DENGAN PATH YANG BENAR
    _G.GetEventGUI = function()
        local success, result = pcall(function()
            --CORREECTED PATH: workspace['!!! DEPENDENCIES']['Event Tracker']
            local dependencies = workspace:FindFirstChild("!!! DEPENDENCIES")
            if dependencies then
                local eventTracker = dependencies:FindFirstChild("Event Tracker")
                if eventTracker then
                    -- Cari struktur GUI di dalam Event Tracker
                    local main = eventTracker:FindFirstChild("Main")
                    if main then
                        local gui = main:FindFirstChild("Gui")
                        if gui then
                            local content = gui:FindFirstChild("Content")
                            if content then
                                local items = content:FindFirstChild("Items")
                                if items then
                                    local countdown = items:FindFirstChild("Countdown")
                                    local statsContainer = items:FindFirstChild("Stats")
                                    
                                    if countdown and statsContainer then
                                        return {
                                            Countdown = countdown:FindFirstChild("Label"),
                                            Timer = statsContainer:FindFirstChild("Timer") and statsContainer.Timer:FindFirstChild("Label"),
                                            Quantity = statsContainer:FindFirstChild("Quantity"),
                                            Odds = statsContainer:FindFirstChild("Odds"),
                                        }
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Fallback: Deep search dalam Event Tracker
                    local countdown = eventTracker:FindFirstDescendant("Countdown")
                    local timer = eventTracker:FindFirstDescendant("Timer")
                    local stats = eventTracker:FindFirstDescendant("Stats")
                    
                    if countdown or timer then
                        return {
                            Countdown = countdown and (countdown:FindFirstChild("Label") or countdown),
                            Timer = timer and (timer:FindFirstChild("Label") or timer),
                            Quantity = stats and stats:FindFirstChild("Quantity"),
                            Odds = stats and stats:FindFirstChild("Odds"),
                        }
                    end
                end
            end
            
            -- Fallback 2: PlayerGui Event GUIs
            local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                -- Cek GUI: Events
                local eventsGui = playerGui:FindFirstChild("Events")
                if eventsGui then
                    local countdown = eventsGui:FindFirstDescendant("Countdown")
                    local timer = eventsGui:FindFirstDescendant("Timer")
                    local stats = eventsGui:FindFirstDescendant("Stats")
                    
                    if countdown or timer then
                        return {
                            Countdown = countdown and (countdown:FindFirstChild("Label") or countdown),
                            Timer = timer and (timer:FindFirstChild("Label") or timer),
                            Quantity = stats and stats:FindFirstChild("Quantity"),
                            Odds = stats and stats:FindFirstChild("Odds"),
                        }
                    end
                end
                
                -- Cek GUI: EventUI
                local eventUI = playerGui:FindFirstChild("EventUI")
                if eventUI then
                    local countdown = eventUI:FindFirstDescendant("Countdown")
                    local timer = eventUI:FindFirstDescendant("Timer")
                    local stats = eventUI:FindFirstDescendant("Stats")
                    
                    if countdown or timer then
                        return {
                            Countdown = countdown and (countdown:FindFirstChild("Label") or countdown),
                            Timer = timer and (timer:FindFirstChild("Label") or timer),
                            Quantity = stats and stats:FindFirstChild("Quantity"),
                            Odds = stats and stats:FindFirstChild("Odds"),
                        }
                    end
                end
            end
            
            return nil
        end)
        
        if success and result then
            return result
        end
        return nil
    end
    
    -- ADVANCED DEBUG FUNCTION
    _G.InspectEventGUI = function()
        print("\n╔══════════════════════════════════════╗")
        print("║   EVENT GUI STRUCTURE INSPECTOR      ║")
        print("╚══════════════════════════════════════╝\n")
        
        local dependencies = workspace:FindFirstChild("!!! DEPENDENCIES")
        if dependencies then
            local eventTracker = dependencies:FindFirstChild("Event Tracker")
            if eventTracker then
                print("✓ Event Tracker found at: workspace['!!! DEPENDENCIES']['Event Tracker']")
                print("\n📁 Structure:")
                
                local function printChildren(obj, indent)
                    indent = indent or 0
                    local prefix = string.rep("  ", indent)
                    
                    for _, child in pairs(obj:GetChildren()) do
                        local icon = child:IsA("TextLabel") and "📝" or 
                                    child:IsA("Frame") and "🔲" or 
                                    child:IsA("Folder") and "📁" or "📄"
                        
                        print(prefix .. icon .. " " .. child.Name .. " (" .. child.ClassName .. ")")
                        
                        -- Print text content if available
                        if child:IsA("TextLabel") or child:IsA("TextBox") then
                            local text = child.Text or child.ContentText or ""
                            if text ~= "" then
                                print(prefix .. "  └─ Text: \"" .. text .. "\"")
                            end
                        end
                        
                        -- Recursively print children (max 3 levels)
                        if indent < 3 and #child:GetChildren() > 0 then
                            printChildren(child, indent + 1)
                        end
                    end
                end
                
                printChildren(eventTracker)
            else
                print("✗ Event Tracker not found in Dependencies")
            end
        else
            print("✗ !!! DEPENDENCIES not found in workspace")
        end
        
        print("\n" .. string.rep("─", 40))
        print("📱 PlayerGui Event GUIs:")
        local playerGui = game.Players.LocalPlayer.PlayerGui
        for _, gui in pairs({"Events", "EventUI", "EventLimitedShop"}) do
            local found = playerGui:FindFirstChild(gui)
            if found then
                print("  ✓ " .. gui)
                local countdown = found:FindFirstDescendant("Countdown")
                local timer = found:FindFirstDescendant("Timer")
                if countdown then print("    └─ Has Countdown") end
                if timer then print("    └─ Has Timer") end
            else
                print("  ✗ " .. gui .. " (not found)")
            end
        end
        print(string.rep("═", 40) .. "\n")
    end
    
    -- DEFINE REQUIRED GLOBAL FUNCTIONS
    _G.GetHRP = function()
        if _G.AutoEnchantModule then
            return _G.AutoEnchantModule.GetHRP()
        end
        
        local Character = game.Players.LocalPlayer.Character
        if not Character then
            Character = game.Players.LocalPlayer.CharacterAdded:Wait()
        end
        return Character:WaitForChild("HumanoidRootPart", 5)
    end
    
    _G.TeleportToLookAt = function(position, lookVector)
        if _G.AutoEnchantModule then
            _G.AutoEnchantModule.TeleportToLookAt(position, lookVector)
            return
        end
        
        local hrp = _G.GetHRP()
        
        if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
            local targetCFrame = CFrame.new(position, position + lookVector)
            hrp.CFrame = targetCFrame * CFrame.new(0, 0.5, 0)
            
            if WindUI then
                WindUI:Notify({ Title = "Teleport Successful!", Duration = 3, Icon = "map-pin" })
            end
        else
            if WindUI then
                WindUI:Notify({ Title = "Teleport Failed", Content = "Invalid position data.", Duration = 3, Icon = "x" })
            end
        end
    end

    -- UI ELEMENTS
    _G.loknesParagraph = _G.EventSection:Paragraph({
        Title = "Ancient Lochness Event",
        Content = "Monitoring event status...",
        Icon = "clock"
    })
    
    _G.StatsParagraph = _G.EventSection:Paragraph({
        Title = "Event Stats: N/A",
        Content = "Timer: N/A\nCaught: N/A\nChance: N/A",
        Icon = "trending-up"
    })
    
    -- IMPROVED UPDATE FUNCTION
    _G.UpdateEventStats = function()
        local gui = _G.GetEventGUI()
        
        if not gui then
            _G.loknesParagraph:SetTitle("Event Countdown: GUI Not Found ❌")
            _G.loknesParagraph:SetDesc("Waiting for Event GUI to load...")
            _G.StatsParagraph:SetTitle("Event Stats: N/A")
            _G.StatsParagraph:SetDesc("Timer: N/A\nCaught: N/A\nChance: N/A")
            return false
        end
        
        -- Extract text dengan fallback
        local function getText(obj)
            if not obj then return "N/A" end
            if obj:IsA("TextLabel") or obj:IsA("TextBox") then
                return obj.ContentText or obj.Text or "N/A"
            end
            -- Jika objek adalah Frame/Folder, cari TextLabel di dalamnya
            local label = obj:FindFirstChildOfClass("TextLabel")
            if label then
                return label.ContentText or label.Text or "N/A"
            end
            return tostring(obj.Value or "N/A")
        end
        
        local countdownText = getText(gui.Countdown)
        local timerText = getText(gui.Timer)
        local quantityText = getText(gui.Quantity)
        local oddsText = getText(gui.Odds)

        _G.loknesParagraph:SetTitle("Ancient Lochness Start In:")
        _G.loknesParagraph:SetDesc(countdownText)

        _G.StatsParagraph:SetTitle("Ancient Lochness Stats")
        _G.StatsParagraph:SetDesc(string.format("• Timer: %s\n• Caught: %s\n• Chance: %s",
            timerText, quantityText, oddsText))

        -- Check if event is active
        local isEventActive = false
        if timerText ~= "N/A" then
            -- Event aktif jika ada waktu yang bukan 0
            local hasTime = timerText:find("%d") and not timerText:match("^0+[MmSs:]*0*$")
            local notEnded = not timerText:lower():find("ended") and not timerText:lower():find("inactive")
            isEventActive = hasTime and notEnded
        end
        
        return isEventActive
    end

    _G.RunEventSyncLoop = function()
        if _G.EventSyncThread then task.cancel(_G.EventSyncThread) end

        _G.EventSyncThread = task.spawn(function()
            local isTeleportedToEvent = false
            local consecutiveFailures = 0
            
            while true do
                local success, isEventActive = pcall(_G.UpdateEventStats)
                
                if not success then
                    consecutiveFailures = consecutiveFailures + 1
                    if consecutiveFailures >= 5 then
                        if WindUI then
                            WindUI:Notify({ 
                                Title = "Error Detected", 
                                Content = "Multiple failures. Use 'Inspect Event GUI' button.", 
                                Duration = 5, 
                                Icon = "alert-circle" 
                            })
                        end
                        consecutiveFailures = 0
                    end
                    task.wait(2)
                    continue
                end
                
                consecutiveFailures = 0
                
                if _G.autoJoinEventActive then
                    if isEventActive and not isTeleportedToEvent then
                        if _G.lastPositionBeforeEvent == nil then
                            local hrp = _G.GetHRP()
                            if hrp then
                                _G.lastPositionBeforeEvent = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
                                if WindUI then
                                    WindUI:Notify({ Title = "Position Saved", Content = "Saving current location.", Duration = 2, Icon = "save" })
                                end
                            end
                        end
                        
                        _G.TeleportToLookAt(_G.LOCHNESS_POS, _G.LOCHNESS_LOOK)
                        isTeleportedToEvent = true
                        if WindUI then
                            WindUI:Notify({ Title = "Event Started! 🌊", Content = "Teleporting to Ancient Lochness.", Duration = 4, Icon = "zap" })
                        end

                    elseif isTeleportedToEvent and not isEventActive and _G.lastPositionBeforeEvent ~= nil then
                        _G.TeleportToLookAt(_G.lastPositionBeforeEvent.Pos, _G.lastPositionBeforeEvent.Look)
                        _G.lastPositionBeforeEvent = nil
                        isTeleportedToEvent = false
                        if WindUI then
                            WindUI:Notify({ Title = "Event Ended ✓", Content = "Returning to previous location.", Duration = 4, Icon = "home" })
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end
    
    -- Start synchronization loop
    _G.RunEventSyncLoop()
    
    -- Toggle for Auto Join
    _G.EventSection:Toggle({
        Title = "Auto Join Ancient Lochness Event",
        Desc = "Automatically teleport when event starts and return when it ends.",
        Value = false,
        Flag = "Toggleloch",
        Callback = function(state)
            _G.autoJoinEventActive = state
            if WindUI then
                if state then
                    WindUI:Notify({ Title = "Auto Join Enabled ✓", Content = "Monitoring Ancient Lochness event.", Duration = 3, Icon = "eye" })
                else
                    WindUI:Notify({ Title = "Auto Join Disabled", Content = "Event monitoring stopped.", Duration = 3, Icon = "eye-off" })
                end
            end
        end
    })

    -- Manual teleport button
    _G.EventSection:Button({
        Title = "Teleport to Ancient Lochness",
        Icon = "map-pin",
        Callback = function()
            _G.TeleportToLookAt(_G.LOCHNESS_POS, _G.LOCHNESS_LOOK)
        end
    })
    _G.EventSection:Divider()
    
    -- Initial notification
    -- if WindUI then
    --    WindUI:Notify({ 
    --        Title = "Event Module Loaded", 
    --        Content = "Ancient Lochness event tracking active.", 
    --        Duration = 3, 
    --        Icon = "check-circle" 
    --    })
    -- end
end

_G.FarmSec:Space()

_G.CodeIsland = _G.FarmSec:Dropdown({
    Title = "Farm Island",
    Values = nameList,
    Value = nameList[9],
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedName)
        local code = islandNamesToCode[selectedName]
        local islandName = islandCodes[code]
        if islandName and farmLocations[islandName] then
            selectedIsland = islandName
            NotifySuccess("Island Selected", "Farming location set to " .. islandName)
        else
            NotifyError("Invalid Selection", "The island name is not recognized.")
        end
    end)
})

myConfig:Register("IslCode", _G.CodeIsland)

_G.AutoFarm = _G.FarmSec:Toggle({
    Title = "Start Auto Farm",
    Callback = function(state)
        isAutoFarmRunning = state
        if state then
            startAutoFarmLoop()
        else
            StopAutoFish5X()
        end
    end
})

myConfig:Register("AutoFarmStart", _G.AutoFarm)


do
    --------------------------------------------------
    -- DEPENDENCIES
    --------------------------------------------------
    _G.Replion = require(
        ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion
    )

    _G.EventsReplion = _G.Replion.Client:WaitReplion("Events")

    --------------------------------------------------
    -- STATE
    --------------------------------------------------
    _G.AutoEventTeleport = {
        selectedEvent = "OFF",
        originalCFrame = nil,
        lastSpawnPos = nil,
    }
    
    _G.__LastEventSignature = nil

    --------------------------------------------------
    -- HELPERS
    --------------------------------------------------
    _G.getHRP = function()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    _G.SafeTeleport = function(cf)
        local hrp = _G.getHRP()
        if hrp then
            hrp.CFrame = cf
        end
    end

    --------------------------------------------------
    -- EVENTS WITH SPAWN ONLY
    --------------------------------------------------
    _G.GetTeleportableEvents = function()
        local events = _G.EventsReplion:Get("Events")
        local spawns = _G.EventsReplion:Get("EventSpawnLocations")

        if typeof(events) ~= "table" or typeof(spawns) ~= "table" then
            return { "OFF" }
        end

        local results = { "OFF" }

        for _, name in ipairs(events) do
            if typeof(spawns[name]) == "Vector3" then
                table.insert(results, tostring(name))
            end
        end

        return results
    end
    
    _G.BuildEventSignature = function()
        local events = _G.EventsReplion:Get("Events")
        local spawns = _G.EventsReplion:Get("EventSpawnLocations")
    
        if typeof(events) ~= "table" or typeof(spawns) ~= "table" then
            return ""
        end
    
        local parts = {}
    
        for _, name in ipairs(events) do
            local pos = spawns[name]
            if typeof(pos) == "Vector3" then
                table.insert(
                    parts,
                    string.format(
                        "%s:%d,%d,%d",
                        name,
                        pos.X,
                        pos.Y,
                        pos.Z
                    )
                )
            end
        end
    
        table.sort(parts)
        return table.concat(parts, "|")
    end

    --------------------------------------------------
    -- CHECK EVENT ACTIVE
    --------------------------------------------------
    _G.IsEventActive = function(name)
        if name == "OFF" then return false end

        local events = _G.EventsReplion:Get("Events")
        if typeof(events) ~= "table" then return false end

        for _, ev in ipairs(events) do
            if ev == name then
                return true
            end
        end
        return false
    end

    --------------------------------------------------
    -- APPLY TELEPORT (AUTO FOLLOW)
    --------------------------------------------------
    _G.ApplyEventTeleport = function()
        local selected = _G.AutoEventTeleport.selectedEvent
    
        -- JANGAN sentuh posisi kalau OFF
        if selected == "OFF" then
            _G.AutoEventTeleport.lastSpawnPos = nil
            return
        end

        -- event yang DIPILIH benar-benar berakhir
        if selected ~= "OFF" and not _G.IsEventActive(selected) then
            if _G.AutoEventTeleport.originalCFrame then
                _G.SafeTeleport(_G.AutoEventTeleport.originalCFrame)
            end
        
            _G.AutoEventTeleport.selectedEvent = "OFF"
            _G.AutoEventTeleport.lastSpawnPos = nil
        
            if _G.AutoEventDropdown then
                _G.AutoEventDropdown:Refresh(_G.GetTeleportableEvents())
            end
        
            return
        end

        if not _G.IsEventActive(selected) then
            if _G.AutoEventTeleport.originalCFrame then
                _G.SafeTeleport(_G.AutoEventTeleport.originalCFrame)
            end
            _G.AutoEventTeleport.selectedEvent = "OFF"
            _G.AutoEventTeleport.lastSpawnPos = nil
            return
        end

        local spawns = _G.EventsReplion:Get("EventSpawnLocations")
        local pos = spawns and spawns[selected]

        if typeof(pos) == "Vector3" then
            if not _G.AutoEventTeleport.lastSpawnPos
            or (_G.AutoEventTeleport.lastSpawnPos - pos).Magnitude > 3 then

                _G.AutoEventTeleport.lastSpawnPos = pos
                local targetCF = CFrame.new(pos + Vector3.new(0, 15, 0))
                _G.SafeTeleport(targetCF)

                if _G.ToggleBlockOnce then
                    pcall(function()
                        _G.ToggleBlockOnce(true)
                    end)
                end
            end
        end
    end
    
    _G.ForceRefreshEvents = function()
        -- akses ulang semua path agar Replion "bangun"
        pcall(function()
            _G.EventsReplion:Get("Events")
            _G.EventsReplion:Get("EventSpawnLocations")
        end)
    end

    _G.AutoEventDropdown = _G.FarmSec:Dropdown({
        Title = "Auto Event Teleport",
        Values = _G.GetTeleportableEvents(),
        Value = "OFF",
        Callback = function(v)
            local prev = _G.AutoEventTeleport.selectedEvent
            _G.AutoEventTeleport.selectedEvent = v
        
            -- simpan posisi awal saat PERTAMA kali masuk event
            if prev == "OFF" and v ~= "OFF" then
                local hrp = _G.getHRP()
                if hrp then
                    _G.AutoEventTeleport.originalCFrame = hrp.CFrame
                end
            end
        
            -- USER PILIH OFF → BALIK KE POSISI AWAL
            if v == "OFF" then
                if _G.AutoEventTeleport.originalCFrame then
                    _G.SafeTeleport(_G.AutoEventTeleport.originalCFrame)
                end
        
                _G.AutoEventTeleport.lastSpawnPos = nil
                return
            end
        
            -- user pilih event
            _G.AutoEventTeleport.lastSpawnPos = nil
            _G.ApplyEventTeleport()
        end
    })

    task.spawn(function()
        while true do
            task.wait(0.5)
    
            local sig = _G.BuildEventSignature()
    
            if sig ~= _G.__LastEventSignature then
                _G.__LastEventSignature = sig
    
                if _G.AutoEventDropdown then
                    _G.AutoEventDropdown:Refresh(
                        _G.GetTeleportableEvents()
                    )
                end
    
                -- HANYA follow jika user memang sedang di event
                if _G.AutoEventTeleport.selectedEvent ~= "OFF" then
                    _G.ApplyEventTeleport()
                end
            end
        end
    end)
end



-------------------------------------------
----- =======[ ARTIFACT TAB ]
-------------------------------------------

local REPlaceLeverItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/PlaceLeverItem"]

_G.UnlockTemple = function()
    task.spawn(function()
        local Artifacts = {
            "Hourglass Diamond Artifact",
            "Crescent Artifact",
            "Arrow Artifact",
            "Diamond Artifact"
        }

        for _, artifact in ipairs(Artifacts) do
            REPlaceLeverItem:FireServer(artifact)
            NotifyInfo("Temple Unlock", "Placing: " .. artifact)
            task.wait(2.1)
        end

        NotifySuccess("Temple Unlock", "All Artifacts placed successfully!")
    end)
end


_G.ArtifactSpots = {
    ["Spot 1"] = CFrame.new(1404.16931, 6.38866091, 118.118126, -0.964853525, 8.69606822e-08, 0.262788326, 9.85441346e-08,
        1, 3.08992689e-08, -0.262788326, 5.5709517e-08, -0.964853525),
    ["Spot 2"] = CFrame.new(883.969788, 6.62499952, -338.560059, -0.325799465, 2.72482961e-08, 0.945438921,
        3.40634649e-08, 1, -1.70824759e-08, -0.945438921, 2.6639464e-08, -0.325799465),
    ["Spot 3"] = CFrame.new(1834.76819, 6.62499952, -296.731476, 0.413336992, -7.92166972e-08, -0.910578132,
        3.06007166e-08, 1, -7.31055181e-08, 0.910578132, 2.35287234e-09, 0.413336992),
    ["Spot 4"] = CFrame.new(1483.25586, 6.62499952, -848.38031, -0.986296117, 2.72397838e-08, 0.164984599, 3.60663037e-08,
        1, 5.05033348e-08, -0.164984599, 5.57616318e-08, -0.986296117)
}

local REFishCaught = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]

local saveFile = "ArtifactProgress.json"

if isfile(saveFile) then
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(saveFile))
    end)
    if success and type(data) == "table" then
        _G.ArtifactCollected = data.ArtifactCollected or 0
        _G.CurrentSpot = data.CurrentSpot or 1
    else
        _G.ArtifactCollected = 0
        _G.CurrentSpot = 1
    end
else
    _G.ArtifactCollected = 0
    _G.CurrentSpot = 1
end

_G.ArtifactFarmEnabled = false

local function saveProgress()
    local data = {
        ArtifactCollected = _G.ArtifactCollected,
        CurrentSpot = _G.CurrentSpot
    }
    writefile(saveFile, game:GetService("HttpService"):JSONEncode(data))
end

_G.StartArtifactFarm = function()
    if _G.ArtifactFarmEnabled then return end
    _G.ArtifactFarmEnabled = true

    updateParagraphArtifact("Auto Farm Artifact", ("Resuming from Spot %d..."):format(_G.CurrentSpot))

    local Player = game.Players.LocalPlayer
    task.wait(1)
    Player.Character:PivotTo(_G.ArtifactSpots["Spot " .. tostring(_G.CurrentSpot)])
    task.wait(1)

    _G.ConfirmFishType = false
    _G.DialogFish = Window:Dialog({
            Icon = "crown",
            Title = "Important!",
            Content = "Please select Auto Fish type!",
            Buttons = {
                {
                    Title = "Auto Fish",
                    Callback = function()
                        StartAutoFish5X()
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Auto Fish Legit",
                    Callback = function()
                        _G.ToggleAutoClick(true)
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Blatant",
                    Callback = function()
                        _G.BlatantState.enabled = true
                        _G.ConfirmFishType = true
                    end,
                },
            },
        })
    
    repeat task.wait() until _G.ConfirmFishType
    _G.AutoFishStarted = true

    _G.ArtifactConnection = _G.REFishCaught.OnClientEvent:Connect(function(fishName, data)
        if string.find(fishName) then
            _G.ArtifactCollected = _G.ArtifactCollected + 1
            saveProgress()

            updateParagraphArtifact(
                "Auto Farm Artifact",
                ("Artifact Found : %s\nTotal: %d/4"):format(fishName, _G.ArtifactCollected)
            )

            if _G.ArtifactCollected < 4 then
                _G.CurrentSpot = _G.CurrentSpot + 1
                saveProgress()
                local spotName = "Spot " .. tostring(_G.CurrentSpot)
                if _G.ArtifactSpots[spotName] then
                    task.wait(2)
                    Player.Character:PivotTo(_G.ArtifactSpots[spotName])
                    updateParagraphArtifact("Auto Farm Artifact",
                        ("Artifact Found : %s\nTotal : %d/4\n\nTeleporting to %s..."):format(
                            fishName,
                            _G.ArtifactCollected,
                            spotName
                        )
                    )
                    task.wait(1)
                end
            else
                updateParagraphArtifact("Auto Farm Artifact", "All Artifacts collected! Unlocking Temple...")
                StopAutoFish5X()
                _G.ToggleAutoClick(false)
                StopCast()
                task.wait(1.5)
                if typeof(_G.UnlockTemple) == "function" then
                    _G.UnlockTemple()
                end
                _G.StopArtifactFarm()
                delfile(saveFile)
            end
        end
    end)
end

_G.StopArtifactFarm = function()
    StopAutoFish()
    _G.ArtifactFarmEnabled = false
    _G.AutoFishStarted = false
    if _G.ArtifactConnection then
        _G.ArtifactConnection:Disconnect()
        _G.ArtifactConnection = nil
    end
    saveProgress()
    updateParagraphArtifact("Auto Farm Artifact", "Auto Farm Artifact stopped. Progress saved.")
end

function updateParagraphArtifact(title, desc)
    if _G.ArtifactParagraph then
        _G.ArtifactParagraph:SetDesc(desc)
    end
end

_G.ArtifactParagraph = _G.ArtSec:Paragraph({
    Title = "Auto Farm Artifact",
    Desc = "Waiting for activation...",
    Color = "Green",
})

_G.ArtSec:Space()

_G.ArtSec:Toggle({
    Title = "Auto Farm Artifact",
    Desc = "Automatically collects 4 Artifacts and unlocks The Temple.",
    Default = false,
    Callback = function(state)
        if state then
            _G.StartArtifactFarm()
        else
            _G.StopArtifactFarm()
        end
    end
})

local spotNames = {}
for name in pairs(_G.ArtifactSpots) do
    table.insert(spotNames, name)
end

_G.ArtSec:Dropdown({
    Title = "Teleport to Lever Temple",
    Values = spotNames,
    Callback = function(selected)
        local spotCFrame = _G.ArtifactSpots[selected]
        if spotCFrame then
            local player = game.Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")

            if hrp then
                hrp.CFrame = spotCFrame
                NotifySuccess("Lever Temple", "Teleported to " .. selected)
            else
                warn("HumanoidRootPart not found!")
            end
        else
            warn("Invalid teleport spot: " .. tostring(selected))
        end
    end
})

_G.ArtSec:Button({
    Title = "Unlock The Temple",
    Desc = "Still need Artifacts!",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.UnlockTemple()
    end
})

-------------------------------------------
----- =======[ ANCIENT RUIN FARMING ]
-------------------------------------------


_G.REPlaceItems = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/PlacePressureItem"]

_G.AncientRuinFish = {
    ["crocodile"] = true,
    ["goliath tiger"] = true,
    ["freshwater piranha"] = true,
    ["sacred guardian squid"] = true,
}

_G.UnlockRuin = function()
    task.spawn(function()
        local Ruins = {
            "Crocodile",
            "Goliath Tiger",
            "Freshwater Piranha",
            "Sacred Guardian Squid",
        }

        for _, ruins in ipairs(Ruins) do
            _G.REPlaceItems:FireServer(ruins)
            NotifyInfo("Ancient Ruin", "Placing: " .. ruins)
            task.wait(2.1)
        end

        NotifySuccess("Ancient Ruin", "All Fish placed successfully!")
    end)
end

_G.TempleSpot = {
    ["Spot 1"] = CFrame.new(1466.27673, -22.1250019, -658.204651, -0.0791874304, 1.48164281e-08, 0.996859729, -8.54522781e-08, 1, -2.16511644e-08, -0.996859729, -8.68984387e-08, -0.0791874304),
    ["Spot 2"] = CFrame.new(1502.93958, -22.1250019, -627.15155, -0.994363189, 2.65133604e-08, -0.106027618, 2.21884164e-08, 1, 4.19703348e-08, 0.106027618, 3.93811703e-08, -0.994363189),
    ["Spot 3"] = CFrame.new(1466.27673, -22.1250019, -658.204651, -0.0791874304, 1.48164281e-08, 0.996859729, -8.54522781e-08, 1, -2.16511644e-08, -0.996859729, -8.68984387e-08, -0.0791874304),
    ["Spot 4"] = CFrame.new(1502.93958, -22.1250019, -627.15155, -0.994363189, 2.65133604e-08, -0.106027618, 2.21884164e-08, 1, 4.19703348e-08, 0.106027618, 3.93811703e-08, -0.994363189),
}

-- FORCE ONLY ONE CFRAME (ANTI MOVE SPOT)
_G.CurrentSpot = 1

function GetFixedTempleCFrame()
    return _G.TempleSpot["Spot 1"]
end

_G.REFishCaught = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]

_G.saveFile = "RuinsProgress.json"

if isfile(_G.saveFile) then
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(_G.saveFile))
    end)
    if success and type(data) == "table" then
        _G.FishCollected = data.FishCollected or 0
        _G.CurrentSpot = data.CurrentSpot or 1
    else
        _G.FishCollected = 0
        _G.CurrentSpot = 1
    end
else
    _G.FishCollected = 0
    _G.CurrentSpot = 1
end

_G.RuinFarmEnabled = false

local function saveProgress()
    local data = {
        FishCollected = _G.FishCollected,
        CurrentSpot = _G.CurrentSpot
    }
    writefile(_G.saveFile, game:GetService("HttpService"):JSONEncode(data))
end

_G.StartRuinFarm = function()
    if _G.RuinFarmEnabled then return end
    _G.RuinFarmEnabled = true

    updateParagraph("Auto Farm Ancient Ruin", ("Resuming from Spot %d..."):format(_G.CurrentSpot))

    local Player = game.Players.LocalPlayer
    task.wait(1)
    Player.Character:PivotTo(GetFixedTempleCFrame())
    task.wait(1)

    _G.ConfirmFishType = false
    _G.DialogFish = Window:Dialog({
            Icon = "crown",
            Title = "Important!",
            Content = "Please select Auto Fish type!",
            Buttons = {
                {
                    Title = "Auto Fish",
                    Callback = function()
                        StartAutoFish5X()
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Auto Fish Legit",
                    Callback = function()
                        _G.ToggleAutoClick(true)
                        _G.ConfirmFishType = true
                    end,
                },
                {
                    Title = "Blatant",
                    Callback = function()
                        _G.BlatantState.enabled = true
                        _G.ConfirmFishType = true
                    end,
                },
            },
        })
    
    repeat task.wait() until _G.ConfirmFishType
    _G.AutoFishStarted = true

    _G.RuinConnection = REFishCaught.OnClientEvent:Connect(function(fishName, data)
        local fishLower = string.lower(fishName)
        if _G.AncientRuinFish[fishLower] then
            _G.FishCollected = _G.FishCollected + 1
            saveProgress()

            updateParagraph(
                "Auto Farm Ancient Ruin",
                ("Fish Found : %s\nTotal: %d/4"):format(fishName, _G.FishCollected)
            )

            if _G.FishCollected < 4 then
                _G.CurrentSpot = _G.CurrentSpot + 1
                saveProgress()
                local spotName = "Spot " .. tostring(_G.CurrentSpot)
                if _G.TempleSpot[spotName] then
                    task.wait(2)
                    -- Disable spot switching, stay on one cframe
                    Player.Character:PivotTo(GetFixedTempleCFrame())
                    updateParagraph("Auto Farm Ancient Ruin",
                        ("Fish Found : %s\nTotal : %d/4\n\nTeleporting to %s..."):format(
                            fishName,
                            _G.FishCollected,
                            spotName
                        )
                    )
                    task.wait(1)
                end
            else
                updateParagraph("Auto Farm Ancient Ruin", "All Fish collected! Unlocking Ancient Ruin...")
                StopAutoFish5X()
                _G.ToggleAutoClick(false)
                StopCast()
                task.wait(1.5)
                if typeof(_G.UnlockRuin) == "function" then
                    _G.UnlockRuin()
                end
                _G.StopRuinFarm()
                delfile(_G.saveFile)
            end
        end
    end)
end

_G.StopRuinFarm = function()
    StopAutoFish5X()
    _G.RuinFarmEnabled = false
    _G.AutoFishStarted = false
    if _G.RuinConnection then
        _G.RuinConnection:Disconnect()
        _G.RuinConnection = nil
    end
    saveProgress()
    updateParagraph("Auto Farm Ancient Ruin", "Auto Farm stopped. Progress saved.")
end

function updateParagraph(title, desc)
    if _G.RuinParagraph then
        _G.RuinParagraph:SetDesc(desc)
    end
end

_G.RuinParagraph = _G.RuinSec:Paragraph({
    Title = "Auto Farm Ancient Ruin",
    Desc = "Waiting for activation...",
    Color = "Green",
})

_G.RuinSec:Space()

_G.RuinSec:Toggle({
    Title = "Auto Farm Ancient Ruin",
    Desc = "Automatically collects 4 Fish and unlocks Ancient Ruin.",
    Default = false,
    Callback = function(state)
        if state then
            _G.StartRuinFarm()
        else
            _G.StopRuinFarm()
        end
    end
})


_G.RuinSec:Button({
    Title = "Unlock Ancient Ruin",
    Desc = "Still need 4 Fish!",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.UnlockRuin()
    end
})

-------------------------------------------
----- =======[ MASS TRADE TAB ]
-------------------------------------------

-- [Trade State]
local tradeState = { 
    selectedPlayerName = nil, 
    selectedPlayerId = nil, 
    autoTradeV1 = false,
    saveTempMode = false,
    TempTradeList = {}, 
    onTrade = false 
}

-- Asumsi Modul game inti sudah tersedia
local ItemUtility = _G.ItemUtility or require(ReplicatedStorage.Shared.ItemUtility) 
local ItemStringUtility = _G.ItemStringUtility or require(ReplicatedStorage.Modules.ItemStringUtility)
local InitiateTrade = net:WaitForChild("RF/InitiateTrade") 
local RFAwaitTradeResponse = net:WaitForChild("RF/AwaitTradeResponse") 

-- Fungsi utilitas untuk mendapatkan daftar pemain
local function getPlayerList()
    local list = {}; 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer then 
            table.insert(list, p.Name) 
        end 
    end; 
    table.sort(list); 
    return list
end

-- =======================================================
-- LOGIKA HOOKING
-- =======================================================

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
_G.REEquipItem = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipItem"]

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()

    -- Logika Save/Send Trade
    if method == "FireServer" and self == _G.REEquipItem then
        local uuid, categoryName = args[1], args[2]

        if tradeState.saveTempMode then
            if uuid and categoryName then
                table.insert(tradeState.TempTradeList, {
                    UUID = uuid,
                    Category = categoryName
                })
                NotifySuccess("Save Mode", "Added item: " .. uuid .. " (" .. categoryName .. ")")
            else
                NotifyError("Save Mode", "Invalid data received.")
            end
            return nil
        end

        if tradeState.onTrade then
            if uuid and tradeState.selectedPlayerId then
                InitiateTrade:InvokeServer(tradeState.selectedPlayerId, uuid)
                NotifySuccess("Trade Sent", "Trade sent to " .. tradeState.selectedPlayerName or tradeState.selectedPlayerId)
            else
                NotifyError("Trade Error", "Invalid target or item.")
            end
            return nil
        end
    end

	if _G.autoSellMythic 
		and method == "FireServer"
		and self == _G.REEquipItem 
		and typeof(args[1]) == "string"
		and args[2] == "Fishes" then

		local uuid = args[1]

		task.delay(1, function()
			pcall(function()
				local result = RFSellItem:InvokeServer(uuid)
				if result then
					NotifySuccess("AutoSellMythic", "Items Sold!!")
				else
					NotifyError("AutoSellMythic", "Failed to sell item!!")
				end
			end)
		end)
	end
    
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- Implementasi Auto Accept Trade
pcall(function()
    local PromptController = _G.PromptController or ReplicatedStorage:WaitForChild("Controllers").PromptController 
    local Promise = _G.Promise or require(ReplicatedStorage.Packages.Promise) 
    
    if PromptController and PromptController.FirePrompt then
        local oldFirePrompt = PromptController.FirePrompt
        PromptController.FirePrompt = function(self, promptText, ...)
            -- Cek apakah Auto Accept aktif dan prompt adalah Trade
            if _G.AutoAcceptTradeEnabled and type(promptText) == "string" and promptText:find("Accept") and promptText:find("from:") then
                -- Mengembalikan Promise yang otomatis me-resolve (menerima) setelah jeda.
                return Promise.new(function(resolve)
                    task.wait(2) -- Tunggu 2 detik
                    resolve(true)
                end)
            end
            return oldFirePrompt(self, promptText, ...)
        end
    end
end)

-- =======================================================
-- DEFINISI UI
-- =======================================================

Trade:Section({
    Title = "Auto Trade Menu",
    TextSize = 22,
    TextXAlignment = "Center",
})

local playerDropdown = Trade:Dropdown({
    Title = "Select Trade Target",
    Values = getPlayerList(),
    Value = getPlayerList()[1] or nil,
    SearchBarEnabled = true,
    Callback = function(selected)
        tradeState.selectedPlayerName = selected
        local player = Players:FindFirstChild(selected)
        if player then
            tradeState.selectedPlayerId = player.UserId
        else
            tradeState.selectedPlayerId = nil
            NotifyError("Target Error", "Player not found!", 3)
        end
    end
})

Trade:Section({Title = "Auto Accept Trade"})

Trade:Toggle({
    Title = "Enable Auto Accept Trade",
    Desc = "Automatically accepts incoming trade requests.",
    Value = false,
    Callback = function(value)
        _G.AutoAcceptTradeEnabled = value
        if value then
            NotifySuccess("Auto Accept", "Auto accept trade enabled.", 3)
        else
            NotifyWarning("Auto Accept", "Auto accept trade disabled.", 3)
        end
    end
})

Trade:Section({Title = "Mass Trade V1"})

-- Toggle Mode Save Items
local saveModeToggle = Trade:Toggle({
    Title = "Mode Save Items",
    Desc = "Click inventory item to add for Mass Trade",
    Value = false,
    Callback = function(state)
        tradeState.saveTempMode = state
        if state then
            tradeState.TempTradeList = {}
            NotifySuccess("Save Mode", "Enabled - Click items to save")
        else
            NotifyInfo("Save Mode", "Disabled - "..#tradeState.TempTradeList.." items saved")
        end
    end
})

-- Toggle Trade (Original Send)
local originalTradeToggle = Trade:Toggle({
    Title = "Trade (Original Send)",
    Desc = "Click inventory items to Send Trade",
    Value = false,
    Callback = function(state)
        tradeState.onTrade = state
        if state then
            NotifySuccess("Trade", "Trade Mode Enabled. Click an item to send trade.")
        else
            NotifyWarning("Trade", "Trade Mode Disabled.")
        end
    end
})

-- Fungsi Trade All
local function TradeAll()       
    if not tradeState.selectedPlayerId then    
        NotifyError("Mass Trade", "Set trade target first!")       
        return         
    end          
    if #tradeState.TempTradeList == 0 then       
        NotifyWarning("Mass Trade", "No items saved!")          
        return         
    end          
    
    NotifyInfo("Mass Trade", "Starting trade of "..#tradeState.TempTradeList.." items...")      
    
    task.spawn(function()          
        for i, item in ipairs(tradeState.TempTradeList) do          
            if not tradeState.autoTradeV1 then
                NotifyWarning("Mass Trade", "Trade stopped!")         
                break          
            end          
        
            local uuid = item.UUID          
            local category = item.Category          
        
            NotifyInfo("Mass Trade", "Trade item "..i.." of "..#tradeState.TempTradeList)          
            InitiateTrade:InvokeServer(tradeState.selectedPlayerId, uuid, category)          
        
            -- Trade response logic
            task.wait(6.5) -- Delay antar trade         
        end          
    
        NotifySuccess("Mass Trade", "Finished trading!")        
        tradeState.autoTradeV1 = false          
        tradeState.TempTradeList = {}          
    end)          
end

-- Toggle Auto Trade
local autoTradeToggle = Trade:Toggle({
    Title = "Start Mass Trade",
    Desc = "Trade all saved items automatically.",
    Value = false,
    Callback = function(state)
        tradeState.autoTradeV1 = state
        if state then
            if #tradeState.TempTradeList == 0 then
                NotifyError("Mass Trade", "No items saved to trade!")
                tradeState.autoTradeV1 = false
                return
            end
            TradeAll()
            NotifySuccess("Mass Trade", "Auto Trade Enabled")
        else
            NotifyWarning("Mass Trade", "Auto Trade Disabled")
        end
    end
})

-------------------------------------------
----- =======[ ENCHANT STONES ]
-------------------------------------------

-- =======================================================
-- AUTO ENCHANT (GLOBAL VARIABLE VERSION)
-- =======================================================

_G.DStones:Section({
    Title = "Auto Enchant Rod",
    TextSize = 22,
    TextXAlignment = "Center",
})

do
    -- Get references to the module functions
    local GetRodOptions = _G.AutoEnchantModule.GetRodOptions
    local GetUUIDFromFormattedName = _G.AutoEnchantModule.GetUUIDFromFormattedName
    local RunAutoEnchantLoop = _G.AutoEnchantModule.RunAutoEnchantLoop
    local GetEnchantNames = _G.AutoEnchantModule.GetEnchantNames
    
    -- Get initial enchant names
    local ENCHANT_NAMES = GetEnchantNames()
    
    local RodDropdown = _G.DStones:Dropdown({
        Title = "Select Rod From Inventory",
        Values = GetRodOptions(),
        Value = nil, 
        Multi = false,
        AllowNone = true,
        Callback = function(name)
            local uuid = GetUUIDFromFormattedName(name)
            if uuid then
                _G.AutoEnchantModule.SetSelectedRodUUID(uuid)
                WindUI:Notify({ 
                    Title = "Rod Dipilih", 
                    Content = "UUID Rod disiapkan untuk enchant.", 
                    Duration = 2, 
                    Icon = "tool" 
                })
            end
        end
    })
    
    local rodlist = _G.DStones:Button({
        Title = "Refresh Rod List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetRodOptions()
            pcall(function() RodDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() RodDropdown:Set(false) end)
            _G.AutoEnchantModule.SetSelectedRodUUID(nil)
            
            WindUI:Notify({ 
                Title = "Daftar Rod Diperbarui", 
                Content = string.format("%d Rods ditemukan. Pilih target baru.", #newOptions), 
                Duration = 2, 
                Icon = "check" 
            })
        end 
    })

    local dropenchant = _G.DStones:Dropdown({
        Title = "Enchant To Apply (stop when reached)",
        Desc = "Pilih enchant yang diinginkan. Auto-roll akan berhenti jika salah satu enchant ini didapat.",
        Values = ENCHANT_NAMES,
        Value = nil, 
        Multi = true,
        AllowNone = false,
        Flag = "dchant",
        Callback = function(names)
            _G.AutoEnchantModule.SetSelectedEnchantNames(names or {})
        end
    })

    local autoenc = _G.DStones:Toggle({
        Title = "Enable Auto Enchant",
        Value = false,
        Flag = "Tchant",
        Callback = function(state)
            _G.AutoEnchantModule.SetAutoEnchantState(state)
            
            if state then
                -- Check conditions before starting
                local selectedRodUUID = _G.AutoEnchantModule.GetSelectedRodUUID()
                local selectedEnchantNames = _G.AutoEnchantModule.GetSelectedEnchantNames()
                
                if not selectedRodUUID then
                    WindUI:Notify({ 
                        Title = "Error", 
                        Content = "Pilih Rod target terlebih dahulu.", 
                        Duration = 3, 
                        Icon = "alert-triangle" 
                    })
                    
                    -- Toggle back to false
                    task.wait()
                    if autoenc then
                        autoenc:Set(false)
                    end
                    return
                end
                
                if #selectedEnchantNames == 0 then
                    WindUI:Notify({ 
                        Title = "Error", 
                        Content = "Pilih minimal satu Enchant target.", 
                        Duration = 3, 
                        Icon = "alert-triangle" 
                    })
                    
                    -- Toggle back to false
                    task.wait()
                    if autoenc then
                        autoenc:Set(false)
                    end
                    return
                end
                
                -- Start the auto enchant process
                RunAutoEnchantLoop(selectedRodUUID)
            else
                -- Stop the auto enchant process
                local autoEnchantThread = _G.AutoEnchantModule.autoEnchantThread
                if autoEnchantThread then 
                    task.cancel(autoEnchantThread) 
                    _G.AutoEnchantModule.autoEnchantThread = nil 
                end
                
                WindUI:Notify({ 
                    Title = "Auto Enchant OFF!", 
                    Duration = 3, 
                    Icon = "x"
                })
            end
        end
    })
    
    -- Add a function to update the UI state based on module state
    local function UpdateUIFromModuleState()
        local currentState = _G.AutoEnchantModule.GetAutoEnchantState()
        if autoenc then
            autoenc:Set(currentState)
        end
    end
    
    -- Optional: Add a way to check module status
    local statusCheck = _G.DStones:Button({
        Title = "Check Enchant Status",
        Icon = "info",
        Callback = function()
            local selectedRodUUID = _G.AutoEnchantModule.GetSelectedRodUUID()
            local selectedEnchantNames = _G.AutoEnchantModule.GetSelectedEnchantNames()
            local isRunning = _G.AutoEnchantModule.GetAutoEnchantState()
            
            local statusMsg = string.format(
                "Status: %s\nRod Selected: %s\nTarget Enchants: %d\n",
                isRunning and "RUNNING" or "STOPPED",
                selectedRodUUID and "YES" or "NO",
                #selectedEnchantNames
            )
            
            if #selectedEnchantNames > 0 then
                statusMsg = statusMsg .. "Enchants: " .. table.concat(selectedEnchantNames, ", ")
            end
            
            WindUI:Notify({
                Title = "Auto Enchant Status",
                Content = statusMsg,
                Duration = 5,
                Icon = "info"
            })
        end
    })
end

_G.DStones:Space()

_G.DStones:Section({
    Title = "Double Enchant Rod",
    TextSize = 22,
    TextXAlignment = "Center",
})

_G.DStones:Paragraph({
    Title = "Guide",
    Color = "Green",
    Desc = [[
TUTORIAL FOR DOUBLE ENCHANT

1. "Enabled Double Enchant" first
2. Hold your "SECRET" fish, then click "Get Enchant Stone"
3. Click "Double Enchant Rod" to do Double Enchant, and don't forget to place the stone in slot 5

Good Luck!
]]
})

_G.ReplicatedStorage = game:GetService("ReplicatedStorage")

_G.DStones:Space()

_G.DStones:Button({
    Title = "Enable Double Enchant",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.ActivateDoubleEnchant = _G.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        ["RE/ActivateSecondEnchantingAltar"]
        if _G.ActivateDoubleEnchant then
            _G.ActivateDoubleEnchant:FireServer()
            NotifySuccess("Double Enchant", "Double Enchant Enabled for Rods")
        else
            warn("Cant find Double Enchant functions")
        end
    end
})

_G.DStones:Space()

_G.DStones:Button({
    Title = "Get Enchant Stones",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.CreateTranscendedStone = _G.ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        ["RF/CreateTranscendedStone"]
        if _G.CreateTranscendedStone then
            local result = _G.CreateTranscendedStone:InvokeServer()
            NotifySuccess("Double Enchant", "Got Enchant Stone!")
        else
            warn("[] Tidak dapat menemukan RemoteFunction CreateTranscendedStone.")
        end
    end
})

_G.DStones:Space()

_G.DStones:Button({
    Title = "Double Enchant Rod",
    Desc = "Hold the stone in slot 5",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.ActiveStone = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        ["RE/ActivateSecondEnchantingAltar"]
        if _G.ActiveStone then
            local result = _G.ActiveStone:FireServer()
            NotifySuccess("Double Enchant", "Enchanting....")
        else
            warn("Error something")
        end
    end
})

-------------------------------------------
----- =======[ PLAYER TAB ]
-------------------------------------------

-- ============================
-- INIT GLOBAL STATE DULU
-- ============================
_G.Cinematic = _G.Cinematic or {
    Enabled = false,
    FreeCam = false,
    HideUI = false,
    Speed = 1.5,
    FOV = 70,
    Sensitivity = 1.0
}

_G.SavedUIState = _G.SavedUIState or {}

-- ============================
-- ULTRA SMOOTH FOV CONTROLLER
-- ============================
local smoothFOV = workspace.CurrentCamera.FieldOfView

game:GetService("RunService").RenderStepped:Connect(function()
    if _G.Cinematic.Enabled then
        -- Ultra smooth FOV dengan alpha lebih kecil
        local targetFOV = _G.Cinematic.FOV
        smoothFOV = smoothFOV + (targetFOV - smoothFOV) * 0.08
        workspace.CurrentCamera.FieldOfView = smoothFOV
    end
end)

-- ============================
-- UI SECTION
-- ============================
_G.CineTools = Player:Section({
    Title = "Cinematic Tools",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = false
})

-- ============================
-- FREECAM TOGGLE
-- ============================
_G.CineTools:Toggle({
    Title = "Enable Free Cam",
    Default = false,
    Callback = function(state)
        _G.Cinematic.FreeCam = state

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")

        local player = Players.LocalPlayer
        local cam = workspace.CurrentCamera

        -- ============================
        -- PLAYER MODULE (JOYSTICK)
        -- ============================
        local playerScripts = player:WaitForChild("PlayerScripts")
        local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
        local controls = playerModule:GetControls()

        -- ============================
        -- CLEAN
        -- ============================
        if _G.__FreeCamConn then
            _G.__FreeCamConn:Disconnect()
            _G.__FreeCamConn = nil
        end
        
        if _G.__TouchConn then
            _G.__TouchConn:Disconnect()
            _G.__TouchConn = nil
        end
        
        if _G.__TouchEndConn then
            _G.__TouchEndConn:Disconnect()
            _G.__TouchEndConn = nil
        end

        -- ============================
        -- OFF MODE
        -- ============================
        if not state then
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
            
            -- Unanchor character
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.Anchored = false
            end
            
            return
        end

        -- ============================
        -- ON MODE - ULTRA SMOOTH
        -- ============================
        cam.CameraType = Enum.CameraType.Scriptable
        smoothFOV = _G.Cinematic.FOV
        cam.FieldOfView = smoothFOV

        -- Anchor character TAPI simpan velocity & CFrame
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local savedCFrame = rootPart and rootPart.CFrame
        local savedVelocity = rootPart and rootPart.Velocity
        
        if rootPart then
            rootPart.Anchored = true
            -- Lock posisi kamera agar tidak goyang saat animasi
            rootPart.CFrame = savedCFrame or rootPart.CFrame
        end

        -- Enable mouse/touch untuk rotasi kamera
        local UserInputService = game:GetService("UserInputService")
        local rotationX = 0
        local rotationY = 0
        local lastTouchPos = nil
        
        -- Simpan rotasi awal dari kamera
        local _, startY, _ = cam.CFrame:ToOrientation()
        rotationY = startY
        
        -- ULTRA Smoothing variables (lebih halus)
        local smoothRotationX = 0
        local smoothRotationY = rotationY
        local targetPosition = cam.CFrame.Position
        local currentPosition = cam.CFrame.Position
        
        -- Tambahan: smooth velocity untuk gerakan lebih natural
        local velocity = Vector3.new(0, 0, 0)
        local targetVelocity = Vector3.new(0, 0, 0)

        -- Handle touch/mouse drag untuk rotasi
        if _G.__TouchConn then _G.__TouchConn:Disconnect() end
        if _G.__TouchEndConn then _G.__TouchEndConn:Disconnect() end
        
        _G.__TouchConn = UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
            if gameProcessed or not _G.Cinematic.FreeCam then return end
            
            if lastTouchPos then
                local delta = touch.Position - lastTouchPos
                local sensitivity = _G.Cinematic.Sensitivity * 0.003  -- Kurangi dari 0.004
                rotationY = rotationY - delta.X * sensitivity
                rotationX = math.clamp(rotationX - delta.Y * sensitivity, -math.pi/2 + 0.1, math.pi/2 - 0.1)
            end
            lastTouchPos = touch.Position
        end)
        
        _G.__TouchEndConn = UserInputService.TouchEnded:Connect(function()
            lastTouchPos = nil
        end)

        _G.__FreeCamConn = RunService.RenderStepped:Connect(function(dt)
            if not _G.Cinematic.FreeCam then return end

            -- ULTRA SMOOTH rotation (alpha lebih kecil = lebih smooth)
            local rotationSmooth = 0.12  -- Dari 0.2 -> 0.12 (LEBIH SMOOTH)
            smoothRotationX = smoothRotationX + (rotationX - smoothRotationX) * rotationSmooth
            smoothRotationY = smoothRotationY + (rotationY - smoothRotationY) * rotationSmooth

            -- Buat rotation CFrame dari input touch/mouse
            local cameraCFrame = CFrame.new(Vector3.new()) 
                * CFrame.Angles(0, smoothRotationY, 0) 
                * CFrame.Angles(smoothRotationX, 0, 0)

            -- Ambil input joystick / WASD
            local move = controls:GetMoveVector()
            
            if move.Magnitude > 0 then
                local speed = _G.Cinematic.Speed * 60 * dt

                -- Arah relatif kamera
                local right = cameraCFrame.RightVector
                local forward = cameraCFrame.LookVector

                -- Target velocity dengan smoothing
                targetVelocity = (right * move.X - forward * move.Z) * speed
            else
                -- Deceleration saat tidak ada input (smooth stop)
                targetVelocity = targetVelocity * 0.85
            end
            
            -- Smooth velocity interpolation (menghilangkan gerakan patah-patah)
            velocity = velocity:Lerp(targetVelocity, 0.18)
            targetPosition = targetPosition + velocity
            
            -- ULTRA SMOOTH position interpolation (alpha lebih kecil)
            local positionSmooth = 0.18  -- Dari 0.25 -> 0.18 (LEBIH SMOOTH)
            currentPosition = currentPosition:Lerp(targetPosition, positionSmooth)
            
            -- Apply final camera position + rotation
            cam.CFrame = CFrame.new(currentPosition) * cameraCFrame
            
            -- Smooth FOV update (sudah dihandle di RenderStepped atas)
            
            -- LOCK character position agar tidak goyang saat animasi (PENTING!)
            if rootPart then
                rootPart.Anchored = true
                -- Force lock CFrame untuk mencegah jitter dari animasi/physics
                if savedCFrame then
                    rootPart.CFrame = savedCFrame
                end
                rootPart.Velocity = Vector3.new(0, 0, 0)
                rootPart.RotVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
})

-- ============================
-- HIDE UI TOGGLE + PERMANENT LOCK
-- ============================
_G.CineTools:Toggle({
    Title = "Hide All UI",
    Default = false,
    Callback = function(state)
        _G.Cinematic.HideUI = state

        local Players = game:GetService("Players")
        local StarterGui = game:GetService("StarterGui")
        local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if not playerGui then return end

        -- Disconnect semua connection lama
        if _G.__UIChangedConns then
            for _, conn in pairs(_G.__UIChangedConns) do
                conn:Disconnect()
            end
            _G.__UIChangedConns = nil
        end
        
        if _G.__UIChildAddedConn then
            _G.__UIChildAddedConn:Disconnect()
            _G.__UIChildAddedConn = nil
        end

        -- ============================
        -- HIDE MODE + PERMANENT LOCK
        -- ============================
        if state then
            table.clear(_G.SavedUIState)
            _G.__UIChangedConns = {}

            -- Function untuk lock UI permanen
            local function lockUI(ui)
                if not ui:IsA("ScreenGui") then return end
                
                -- Simpan state original
                if not _G.SavedUIState[ui] then
                    _G.SavedUIState[ui] = ui.Enabled
                end
                
                -- Set ke false
                ui.Enabled = false
                
                -- LOCK PERMANEN: Kalau UI coba enabled lagi, langsung false!
                local conn = ui:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if _G.Cinematic.HideUI and ui.Enabled then
                        ui.Enabled = false
                    end
                end)
                
                table.insert(_G.__UIChangedConns, conn)
            end

            -- Lock semua UI yang ada sekarang
            for _, ui in ipairs(playerGui:GetChildren()) do
                lockUI(ui)
            end

            -- HIDE CORE UI (KECUALI JOYSTICK!)
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
            end)

            -- Listener untuk UI BARU yang spawn (fishing result, dll)
            _G.__UIChildAddedConn = playerGui.ChildAdded:Connect(function(child)
                if _G.Cinematic.HideUI then
                    task.wait(0.05)  -- Delay minimal biar UI sempat exist
                    lockUI(child)
                end
            end)
        
        -- ============================
        -- SHOW MODE
        -- ============================
        else
            -- RESTORE PLAYER UI
            for ui, enabled in pairs(_G.SavedUIState) do
                if ui and ui.Parent then
                    ui.Enabled = enabled
                end
            end

            -- RESTORE CORE UI
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
            end)
        end
    end
})

-- ============================
-- CAMERA SPEED SLIDER
-- ============================
_G.CineTools:Slider({
    Title = "Camera Speed",
    Value = {
        Min = 0.1,
        Max = 15,
        Default = 1.5,
        Increment = 0.1
    },
    Callback = function(v)
        _G.Cinematic.Speed = v
    end
})

-- ============================
-- CAMERA SENSITIVITY SLIDER
-- ============================
_G.CineTools:Slider({
    Title = "Camera Sensitivity",
    Value = {
        Min = 0.1,
        Max = 3,
        Default = 1.0,
        Increment = 0.1
    },
    Callback = function(v)
        _G.Cinematic.Sensitivity = v
    end
})

-- ============================
-- CAMERA FOV SLIDER
-- ============================
_G.CineTools:Slider({
    Title = "Camera FOV",
    Value = {
        Min = 30,
        Max = 120,
        Default = 70
    },
    Callback = function(v)
        _G.Cinematic.FOV = v
        _G.Cinematic.Enabled = true
    end
})

-- =========================================================
-- ===============  COPY AVATAR SYSTEM =====================
-- =========================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- GLOBALS
_G.CopyAvatarEnabled = false
_G.CopyAvatarTarget = nil
_G.OriginalAppearance = nil
_G.CurrentCopiedUserId = nil

-- EXACT COPY FUNCTIONS FROM avatar_stealer.lua
local function saveOriginalAppearance()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            _G.OriginalAppearance = humanoid:GetAppliedDescription()
            return true
        end
    end
    return false
end

local function applyBlockyBody(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    
    local blockyDescription = Instance.new("HumanoidDescription")
    blockyDescription.BodyTypeScale = 1
    blockyDescription.DepthScale = 1
    blockyDescription.HeadScale = 1
    blockyDescription.HeightScale = 1
    blockyDescription.ProportionScale = 0
    blockyDescription.WidthScale = 1
    
    humanoid:ApplyDescriptionClientServer(blockyDescription)
    return true
end

local function removeAllClothingAndAccessories(character)
    local itemsRemoved = 0
    
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("HairAccessory") then
            item:Destroy()
            itemsRemoved = itemsRemoved + 1
        end
    end
    
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
            itemsRemoved = itemsRemoved + 1
        end
    end
    
    for _, item in pairs(character:GetDescendants()) do
        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("HairAccessory") or 
           item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
            itemsRemoved = itemsRemoved + 1
        end
    end
    
    return itemsRemoved
end

local function getUserIdFromUsername(username)
    local success, result = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    
    if not success then
        local httpSuccess, httpResult = pcall(function()
            local response = game:HttpGet("https://api.roblox.com/users/get-by-username?username=" .. username)
            local data = HttpService:JSONDecode(response)
            if data and data.Id then
                return data.Id
            end
        end)
        
        if httpSuccess and httpResult then
            return httpResult
        else
            error("Cannot find player: " .. username)
        end
    end
    
    return result
end

local function copyAvatarThroughDescription(userId)
    local description = Players:GetHumanoidDescriptionFromUserId(userId)
    if not description then
        error("Cannot get avatar description")
    end
    
    local character = LocalPlayer.Character
    if not character then
        error("Character not found")
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        error("Humanoid not found")
    end
    
    -- Apply Blocky Body
    applyBlockyBody(character)
    task.wait(0.3)
    
    -- Remove all clothing and accessories
    removeAllClothingAndAccessories(character)
    task.wait(0.5)
    
    -- Apply avatar description
    humanoid:ApplyDescriptionClientServer(description)
    
    return true
end

local function copyAvatarByUsername(username)
    local userId = getUserIdFromUsername(username)
    
    if not _G.OriginalAppearance then
        saveOriginalAppearance()
    end
    
    local success = copyAvatarThroughDescription(userId)
    
    if success then
        _G.CurrentCopiedUserId = userId
        return true
    end
    return false
end

local function resetToOriginalAppearance()
    if _G.OriginalAppearance then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                removeAllClothingAndAccessories(character)
                humanoid:ApplyDescriptionClientServer(_G.OriginalAppearance)
                _G.CurrentCopiedUserId = nil
                _G.CopyAvatarTarget = nil
                return true
            end
        end
    end
    return false
end

local function safeCopyAvatar(username)
    if not _G.CopyAvatarEnabled then
        return false, "System is disabled"
    end
    
    local success, errorMsg = pcall(function()
        return copyAvatarByUsername(username)
    end)
    
    if success then
        return true
    else
        return false, errorMsg
    end
end

-- =========================================================
-- ==================== UI IMPLEMENTATION ==================
-- =========================================================

local function getPlayerDisplayNames()
    local out = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(out, player.DisplayName)
        end
    end
    return out
end

-- Fungsi untuk mencari player berdasarkan Display Name dan mendapatkan Username
local function findPlayerByDisplayName(displayName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.DisplayName == displayName then
            return player
        end
    end
    return nil
end

local function refreshDropdown()
    if _G.CopyAvatarDropdown and type(_G.CopyAvatarDropdown) == "table" then
        pcall(function()
            _G.CopyAvatarDropdown.Values = getPlayerDisplayNames()
            _G.CopyAvatarDropdown:Set(getPlayerDisplayNames())
        end)
    end
end

-- Toggle for ON/OFF
_G.CopyAvatarToggle = Player:Toggle({
    Title = "Copy Avatar System",
    Desc = "Enable/disable the copy avatar system",
    Value = false,
    Callback = function(state)
        _G.CopyAvatarEnabled = state
        if not state then
            resetToOriginalAppearance()
        else
            if not _G.OriginalAppearance then
                saveOriginalAppearance()
            end
        end
    end
})

-- Dropdown for player selection (NOW USING DISPLAY NAMES)
_G.CopyAvatarDropdown = Player:Dropdown({
    Title = "Select Target Player", 
    Desc = "Choose player to copy avatar from (by Display Name)",
    Values = getPlayerDisplayNames(),
    Value = nil, 
    SearchBarEnabled = true,
    Callback = function(selectedDisplayName)
        -- Only work if system is enabled
        if not _G.CopyAvatarEnabled then
            return
        end
        
        -- Cari player berdasarkan Display Name
        local foundPlayer = findPlayerByDisplayName(selectedDisplayName)

        if foundPlayer then
            _G.CopyAvatarTarget = foundPlayer
            -- Gunakan Username untuk copy function (karena getUserIdFromUsername butuh username)
            safeCopyAvatar(foundPlayer.Name)
        end
    end,
})

-- Reset character button
Player:Button({
    Title = "Reset Character",
    Desc = "Reset to original appearance", 
    Callback = function()
        resetToOriginalAppearance()
    end
})

Player:Space()

-- =========================================================
-- ==================== EVENT HANDLERS =====================
-- =========================================================

-- Auto refresh dropdown
Players.PlayerAdded:Connect(function()
    task.wait(1)
    refreshDropdown()
end)

Players.PlayerRemoving:Connect(function()
    task.wait(1)
    refreshDropdown()
end)

-- Auto reapply on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    
    if _G.CopyAvatarEnabled and _G.CopyAvatarTarget then
        task.spawn(function()
            task.wait(0.5)
            safeCopyAvatar(_G.CopyAvatarTarget.Name)
        end)
    end
end)

-- Initial setup
task.spawn(function()
    task.wait(3)
    refreshDropdown()
    saveOriginalAppearance()
end)

local lastSelectedPlayer = nil
local isRefreshing = false

local currentDropdown = nil

function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.DisplayName)
        end
    end
    return list
end


function teleportToPlayerExact(target)
    local characters = workspace:FindFirstChild("Characters")
    if not characters then return end

    local targetChar = characters:FindFirstChild(target)
    local myChar = characters:FindFirstChild(LocalPlayer.Name)

    if targetChar and myChar then
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame + Vector3.new(2, 0, 0)
        end
    end
end

function refreshDropdown()
    if currentDropdown then
        isRefreshing = true
        currentDropdown:Refresh(getPlayerList())
        task.delay(0.1, function()
            isRefreshing = false
        end)
    end
end

currentDropdown = Player:Dropdown({
    Title = "Teleport to Player",
    Desc = "Select player to teleport",
    Values = getPlayerList(),
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedDisplayName)
        -- ❌ Abaikan callback palsu
        if isRefreshing then return end
        if not selectedDisplayName then return end
        if selectedDisplayName == lastSelectedPlayer then return end

        lastSelectedPlayer = selectedDisplayName

        for _, p in ipairs(Players:GetPlayers()) do
            if p.DisplayName == selectedDisplayName then
                teleportToPlayerExact(p.Name)
                NotifySuccess(
                    "Teleport Successfully",
                    "Successfully Teleported to " .. p.DisplayName .. "!",
                    3
                )
                break
            end
        end
    end)
})

Players.PlayerAdded:Connect(function()
    task.delay(0.1, refreshDropdown)
end)

Players.PlayerRemoving:Connect(function()
    task.delay(0.1, refreshDropdown)
end)

refreshDropdown()

local defaultMinZoom = LocalPlayer.CameraMinZoomDistance
local defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance

Player:Toggle({
    Title = "Unlimited Zoom",
    Desc = "Unlimited Camera Zoom for take a Picture",
    Value = false,
    Callback = function(state)
        if state then
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 9999
        else
            LocalPlayer.CameraMinZoomDistance = defaultMinZoom
            LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
        end
    end
})

function accessAllBoats()
    local vehicles = workspace:FindFirstChild("Vehicles")
    if not vehicles then
        NotifyError("Not Found", "Vehicles container not found.")
        return
    end

    local count = 0

    for _, boat in ipairs(vehicles:GetChildren()) do
        if boat:IsA("Model") and boat:GetAttribute("OwnerId") then
            local currentOwner = boat:GetAttribute("OwnerId")
            if currentOwner ~= LocalPlayer.UserId then
                boat:SetAttribute("OwnerId", LocalPlayer.UserId)
                count = count + 1
            end
        end
    end

    NotifySuccess("Access Granted", "You now own " .. count .. " boat(s).", 3)
end

Player:Space()

Player:Button({
    Title = "Access All Boats",
    Justify = "Center",
    Icon = "",
    Callback = accessAllBoats
})

Player:Space()

_G.FreezePlayerEnabled = false
_G.HideIslandEnabled = false
_G.__IslandVisualCache = _G.__IslandVisualCache or {}

_G.FreezePlayer = function(state)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    local function applyFreeze(char)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")

        if not hrp or not humanoid then return end

        if state then
            -- Freeze core
            hrp.Anchored = true
            humanoid.PlatformStand = true

            -- Kill physics forces
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            -- Optional: anti collision with other players
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties =
                        PhysicalProperties.new(0, 0, 0, 0, 0)
                end
            end
        else
            -- Unfreeze
            hrp.Anchored = false
            humanoid.PlatformStand = false

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = nil
                end
            end
        end
    end

    -- Apply immediately
    if player.Character then
        applyFreeze(player.Character)
    end

    -- Reapply if character respawns
    if not _G.__FreezeCharConn then
        _G.__FreezeCharConn = player.CharacterAdded:Connect(function(char)
            char:WaitForChild("HumanoidRootPart")
            task.wait(0.2)
            if _G.FreezePlayerEnabled then
                applyFreeze(char)
            end
        end)
    end

    -- Physics enforcement loop (anti exploit push)
    if state and not _G.__FreezeLoop then
        _G.__FreezeLoop = RunService.Heartbeat:Connect(function()
            if not _G.FreezePlayerEnabled then return end
            local char = player.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    elseif not state and _G.__FreezeLoop then
        _G.__FreezeLoop:Disconnect()
        _G.__FreezeLoop = nil
    end

    _G.FreezePlayerEnabled = state
end

_G.SetIslandHidden = function(state)
    local Islands = workspace:FindFirstChild("Islands")
    if not Islands then
        warn("Islands folder not found!")
        return
    end

    for _, obj in ipairs(Islands:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- cache once
            if _G.__IslandVisualCache[obj] == nil then
                _G.__IslandVisualCache[obj] = obj.LocalTransparencyModifier
            end

            -- VISUAL ONLY (SAFE)
            obj.LocalTransparencyModifier = state and 1 or _G.__IslandVisualCache[obj]
            obj.CastShadow = not state

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            -- Decal/Texture aman pakai Transparency
            obj.Transparency = state and 1 or 0

        elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
            obj.Enabled = not state
        end
    end

    _G.HideIslandEnabled = state
end

do
    -- =========================================================
    -- NO ANIMATION
    -- =========================================================
    local NoAnimActive = false
    local originalAnimator = nil
    local originalAnimate = nil

    local function DisableAnim()
        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local animateScript = char:FindFirstChild("Animate")
        if animateScript then
            originalAnimate = animateScript.Enabled
            animateScript.Enabled = false
        end

        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            originalAnimator = animator
            animator:Destroy()
        end
    end

    local function EnableAnim()
        local char = LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        local animateScript = char:FindFirstChild("Animate")
        if animateScript and originalAnimate ~= nil then
            animateScript.Enabled = originalAnimate
        end

        if not hum:FindFirstChildOfClass("Animator") then
            Instance.new("Animator").Parent = hum
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if NoAnimActive then task.wait(0.2); DisableAnim() end
    end)

    Player:Toggle({
        Title = "No Animation",
        Flag = "util_noanim",
        Value = false,
        Callback = function(state)
            NoAnimActive = state
            if state then
                DisableAnim()
                WindUI:Notify({ Title = "No Animation ON", Duration = 3, Icon = "zap" })
            else
                EnableAnim()
                WindUI:Notify({ Title = "No Animation OFF", Duration = 3, Icon = "x" })
            end
        end
    })

    -- =========================================================
    -- NO CUTSCENE
    -- =========================================================
    local CutsceneController, OldPlay = nil, nil
    pcall(function()
        CutsceneController = require(ReplicatedStorage.Controllers.CutsceneController)
        OldPlay = CutsceneController.Play
    end)

    Player:Toggle({
        Title = "No Cutscene",
        Flag = "util_nocutscene",
        Value = false,
        Callback = function(state)
            if CutsceneController and OldPlay then
                if state then
                    CutsceneController.Play = function() end
                else
                    CutsceneController.Play = OldPlay
                end
            end

            WindUI:Notify({
                Title = state and "No Cutscene ON" or "No Cutscene OFF",
                Duration = 3,
                Icon = state and "video-off" or "video"
            })
        end
    })

    -- =========================================================
    -- REMOVE SKIN EFFECT
    -- =========================================================
    local VFX = require(ReplicatedStorage.Controllers.VFXController)
    local originalVFX = VFX.Handle

    Player:Toggle({
        Title = "Remove Skin Effect",
        Flag = "util_noskin",
        Value = false,
        Callback = function(state)
            if state then
                VFX.Handle = function() end
                VFX.RenderInstance = function() end
                VFX.RenderAtPoint = function() end

                local cos = workspace:FindFirstChild("CosmeticFolder")
                if cos then pcall(function() cos:ClearAllChildren() end) end

                WindUI:Notify({ Title = "No Skin Effect ON", Duration = 3, Icon = "eye-off" })
            else
                VFX.Handle = originalVFX
                WindUI:Notify({ Title = "Skin Effect Restored", Duration = 3, Icon = "eye" })
            end
        end
    })
end

Player:Toggle({
    Title = "Freeze Player",
    Justify = "Center",
    Icon = "",
    Value = false,
    Callback = function(state)
        _G.FreezePlayer(state)

        if state then
            NotifySuccess("Freeze", "Player Frozen")
        else
            NotifyInfo("Freeze", "Player Unfrozen")
        end
    end
})

_G.HideIsland = Player:Toggle({
    Title = "Hide All Island",
    Justify = "Center",
    Icon = "",
    Value = false,
    Callback = function(state)
        _G.SetIslandHidden(state)
        if state then
            NotifySuccess("Island", "All islands hidden")
        else
            NotifyInfo("Island", "All islands restored")
        end
    end
})

myConfig:Register("HideAllIsland", _G.HideIsland)

local AntiDrown_Enabled = false
local rawmt = getrawmetatable(game)
setreadonly(rawmt, false)
local oldNamecall = rawmt.__namecall

rawmt.__namecall = newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if tostring(self) == "URE/UpdateOxygen" and method == "FireServer" and AntiDrown_Enabled then
        return nil
    end

    return oldNamecall(self, ...)
end)

local DrownBN = true

-- ===== ENABLE RADAR =====
local function ToggleRadar(state)
    pcall(function()
        Radar:InvokeServer(state)
    end)
end

-- ===== ENABLE DIVING GEAR =====
local function ToggleDivingGear(state)
    pcall(function()
        if state then
            EquipOxy:InvokeServer(105)
        else
            UnequipOxy:InvokeServer()
        end
    end)
end

local ToggleRadar = Player:Toggle({
    Title = "Enable Fishing Radar",
    Value = false,
    Callback = function(enabled)
        ToggleRadar(enabled)
    end,
})

myConfig:Register("RadarConfig", ToggleRadarUI)

local ToggleDivingGear = Player:Toggle({
    Title = "Enable Diving Gear",
    Value = false,
    Callback = function(enabled)
        ToggleDivingGear(enabled)
    end,
})

myConfig:Register("AntiDrown", ToggleDivingGearUI)

Player:Toggle({
    Title = "Infinity Jump",
    Callback = function(val)
        ijump = val
    end,
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if ijump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

WalkWaterPlatform = WalkWaterPlatform
WalkWaterConnection = WalkWaterConnection
WalkWater_Enabled = false

-- CREATE PLATFORM (global)
function NKZ_WaterPlatform()
    p = Instance.new("Part")
    p.Name = "NKZ_WaterWalk"
    p.Anchored = true
    p.CanCollide = true
    p.Transparency = 1
    p.Size = Vector3.new(18, 1, 18)
    p.Parent = workspace
    return p
end

Player:Toggle({
    Title = "Walk on Water",
    Value = false,
    Callback = function(state)

        WalkWater_Enabled = state

        if state == true then
            WindUI:Notify({ Title = "Walk on Water ON!", Duration = 2, Icon = "check" })

            if WalkWaterPlatform == nil then
                WalkWaterPlatform = NKZ_WaterPlatform()
            end

            if WalkWaterConnection then
                WalkWaterConnection:Disconnect()
            end

            WalkWaterConnection = RunService.RenderStepped:Connect(function(step)

                if WalkWater_Enabled ~= true then return end

                character = LocalPlayer.Character
                if not character then return end

                hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                hum = character:FindFirstChild("Humanoid")
                if not hum then return end

                -- FAST RAYCAST (lebih cepat dari contohmu)
                rayParams = RaycastParams.new()
                rayParams.IgnoreWater = false
                rayParams.FilterDescendantsInstances = {workspace.Terrain}
                rayParams.FilterType = Enum.RaycastFilterType.Include

                origin = hrp.Position + Vector3.new(0, 4, 0)
                direction = Vector3.new(0, -40, 0)

                cast = workspace:Raycast(origin, direction, rayParams)

                if cast and cast.Material == Enum.Material.Water then
                    
                    surfaceY = cast.Position.Y

                    -- SMOOTH FOLLOW PLATFORM - TERCEPAT & TIDAK KASAR
                    WalkWaterPlatform.Position = Vector3.new(
                        hrp.Position.X,
                        surfaceY,
                        hrp.Position.Z
                    )

                    -- PLAYER STABILIZER (tidak tenggelam)
                    desiredY = surfaceY + 3.15
                    
                    if hrp.Position.Y <= desiredY - 0.2 then
                        hrp.CFrame = CFrame.new(
                            hrp.Position.X,
                            desiredY,
                            hrp.Position.Z
                        )
                    end

                    -- Jangan naik kalau sedang loncat
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then return end

                else
                    -- Hilangkan platform ketika bukan di air
                    WalkWaterPlatform.Position = Vector3.new(0, -9999, 0)
                end
            end)

        else
            WindUI:Notify({ Title = "Walk on Water OFF!", Duration = 2, Icon = "x" })
            WalkWater_Enabled = false

            if WalkWaterConnection then WalkWaterConnection:Disconnect() end
            WalkWaterConnection = nil

            if WalkWaterPlatform then WalkWaterPlatform:Destroy() end
            WalkWaterPlatform = nil
        end
    end
})

local EnableFloat = Player:Toggle({
    Title = "Enable Float",
    Value = false,
    Callback = function(enabled)
        floatingPlat(enabled)
    end,
})

myConfig:Register("ActiveFloat", EnableFloat)

local universalNoclip = false
local originalCollisionState = {}

local NoClip = Player:Toggle({
    Title = "Universal No Clip",
    Value = false,
    Callback = function(val)
        universalNoclip = val

        if val then
            NotifySuccess("Universal Noclip Active", "You & your vehicle can penetrate all objects.", 3)
        else
            for part, state in pairs(originalCollisionState) do
                if part and part:IsA("BasePart") then
                    part.CanCollide = state
                end
            end
            originalCollisionState = {}
            NotifyWarning("Universal Noclip Disabled", "All collisions are returned to their original state.", 3)
        end
    end,
})

game:GetService("RunService").Stepped:Connect(function()
    if not universalNoclip then return end

    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                originalCollisionState[part] = true
                part.CanCollide = false
            end
        end
    end

    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChildWhichIsA("VehicleSeat", true) then
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide == true then
                    originalCollisionState[part] = true
                    part.CanCollide = false
                end
            end
        end
    end
end)

myConfig:Register("NoClip", NoClip)

local AntiDrown_Enabled = false
local rawmt = getrawmetatable(game)
setreadonly(rawmt, false)
local oldNamecall = rawmt.__namecall

rawmt.__namecall = newcclosure(function(self, ...)
    local args = { ... }
    local method = getnamecallmethod()

    if tostring(self) == "URE/UpdateOxygen" and method == "FireServer" and AntiDrown_Enabled then
        return nil
    end

    return oldNamecall(self, ...)
end)

local ADrown = Player:Toggle({
    Title = "Anti Drown (Oxygen Bypass)",
    Callback = function(state)
        AntiDrown_Enabled = state
        if state then
            NotifySuccess("Anti Drown Active", "Oxygen loss has been blocked.", 3)
        else
            NotifyWarning("Anti Drown Disabled", "You're vulnerable to drowning again.", 3)
        end
    end,
})

myConfig:Register("AntiDrown", ADrown)

local Speed = Player:Slider({
    Title = "WalkSpeed",
    Value = {
        Min = 16,
        Max = 200,
        Default = 20
    },
    Step = 1,
    Callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end,
})

myConfig:Register("PlayerSpeed", Speed)

local Jp = Player:Slider({
    Title = "Jump Power",
    Value = {
        Min = 50,
        Max = 500,
        Default = 35
    },
    Step = 10,
    Callback = function(val)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = val
            end
        end
    end,
})

myConfig:Register("JumpPower", Jp)

-------------------------------------------
----- =======[ UTILITY TAB ]
-------------------------------------------

do
    -- Inisialisasi _G jika belum ada
    _G.AutoEnchantModule = _G.AutoEnchantModule or {}
    _G.MerchantReplion = nil
    _G.UpdateCleanupFunction = nil
    _G.MainDisplayElement = nil
    _G.UpdateThread = nil
    _G.MerchantButtons = {}
    _G.autoBuySelectedState = false
    _G.autoBuyStockState = false
    _G.autoBuyThread = nil
    _G.selectedStaticItemName = nil

    -- Pastikan RepStorage ada
    if not game:GetService("ReplicatedStorage") then
        warn("[Shop] ReplicatedStorage tidak ditemukan!")
        return
    end
    
    local RepStorage = game:GetService("ReplicatedStorage")

    -- Fungsi helper dengan pengecekan aman
    _G.GetRemote = function(path, name)
        if not _G.AutoEnchantModule or not _G.AutoEnchantModule.GetRemote then
            return nil
        end
        return _G.AutoEnchantModule.GetRemote(path, name)
    end

    _G.TeleportToLookAt = function(...)
        if not _G.AutoEnchantModule or not _G.AutoEnchantModule.TeleportToLookAt then
            return nil
        end
        return _G.AutoEnchantModule.TeleportToLookAt(...)
    end

    _G.FormatNumber = function(...)
        if not _G.AutoEnchantModule or not _G.AutoEnchantModule.FormatNumber then
            return tostring(...)
        end
        return _G.AutoEnchantModule.FormatNumber(...)
    end

    _G.MerchantStaticItems = function()
        if not _G.AutoEnchantModule or not _G.AutoEnchantModule.GetMerchantItems then
            return {}
        end
        return _G.AutoEnchantModule.GetMerchantItems() or {}
    end

    -- Remote dengan pengecekan aman
    _G.RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    _G.RF_PurchaseMarketItem = _G.GetRemote(_G.RPath, "RF/PurchaseMarketItem")

    -- Fungsi utama dalam _G dengan pcall
    _G.GetReplions = function()
        if _G.MerchantReplion then return true end
        
        local success, result = pcall(function()
            local ReplionModule = RepStorage:WaitForChild("Packages", 5)
            if ReplionModule then
                ReplionModule = ReplionModule:WaitForChild("Replion", 5)
                if ReplionModule then
                    local ReplionClient = require(ReplionModule).Client
                    _G.MerchantReplion = ReplionClient:WaitReplion("Merchant", 5)
                    return _G.MerchantReplion ~= nil
                end
            end
            return false
        end)
        
        return success and result or false
    end

    _G.getNextRefreshTimeString = function()
        local success, serverTime = pcall(function()
            return workspace:GetServerTimeNow()
        end)
        
        if not success then
            return "Next Refresh: Unknown"
        end
        
        local secondsInDay = 86400
        local nextRefreshTime = (math.floor(serverTime / secondsInDay) + 1) * secondsInDay
        local timeRemaining = math.max(nextRefreshTime - serverTime, 0)
        local h = math.floor(timeRemaining / 3600)
        local m = math.floor((timeRemaining % 3600) / 60)
        local s = math.floor(timeRemaining % 60)
        return string.format("Next Refresh: %dH, %dM, %dS", h, m, s)
    end

    _G.GetMerchantStockDetails = function(merchantData)
        if not merchantData or not merchantData.Items or type(merchantData.Items) ~= "table" then
            return {}
        end
        
        local MarketItemData
        local success = pcall(function()
            local shared = RepStorage:FindFirstChild("Shared")
            if shared then
                local marketItemDataModule = shared:FindFirstChild("MarketItemData")
                if marketItemDataModule then
                    MarketItemData = require(marketItemDataModule)
                end
            end
        end)
        
        if not success or not MarketItemData then 
            return {} 
        end
        
        local itemDetails = {}
        for _, itemID in ipairs(merchantData.Items) do
            local marketData
            for _, data in ipairs(MarketItemData) do
                if data.Id == itemID then 
                    marketData = data
                    break 
                end
            end

            if marketData and not marketData.SkinCrate and marketData.Price and marketData.Currency then
                local itemDetail
                local ItemUtility
                
                pcall(function()
                    local shared = RepStorage:FindFirstChild("Shared")
                    if shared then
                        local itemUtilityModule = shared:FindFirstChild("ItemUtility")
                        if itemUtilityModule then
                            ItemUtility = require(itemUtilityModule)
                        end
                    end
                end)
                
                if ItemUtility then
                    pcall(function() 
                        itemDetail = ItemUtility:GetItemDataFromItemType(marketData.Type, marketData.Identifier) 
                    end)
                end
                
                local name = (itemDetail and itemDetail.Data and itemDetail.Data.Name) or marketData.Identifier or "Unknown Item"
                table.insert(itemDetails, {
                    Name = name,
                    ID = itemID,
                    Price = marketData.Price,
                    Currency = marketData.Currency,
                })
            end
        end
        return itemDetails
    end

    _G.BuyMerchantItem = function(itemID, itemName)
        if not _G.RF_PurchaseMarketItem then
            if WindUI then
                WindUI:Notify({ 
                    Title = "Purchase Failed", 
                    Content = "Remote Purchase Market Item tidak ditemukan.", 
                    Duration = 4, 
                    Icon = "x" 
                })
            end
            return false
        end
        
        local success, result = pcall(function()
            return _G.RF_PurchaseMarketItem:InvokeServer(itemID)
        end)

        if success then
            if WindUI then
                WindUI:Notify({ 
                    Title = "Purchase Attempted!", 
                    Content = "Mencoba membeli: " .. itemName, 
                    Duration = 1.5, 
                    Icon = "check" 
                })
            end
            return true
        else
            if WindUI then
                WindUI:Notify({ 
                    Title = "Purchase Failed", 
                    Content = "Gagal: " .. (result or "Unknown Error"), 
                    Duration = 2, 
                    Icon = "x" 
                })
            end
            return false
        end
    end

    _G.ClearOldMerchantButtons = function()
        if not _G.MerchantButtons then
            _G.MerchantButtons = {}
            return
        end
        
        for _, btn in ipairs(_G.MerchantButtons) do
            if btn and type(btn) == "table" and btn.Destroy then
                pcall(function()
                    btn:Destroy()
                end)
            end
        end
        _G.MerchantButtons = {}
    end

    _G.CreateStockListString = function(itemDetails)
        local list = {"--- CURRENT STOCK ---"}
        if not itemDetails or #itemDetails == 0 then
            table.insert(list, "Stok Item unik kosong saat ini.")
            return table.concat(list, "\n")
        end

        for _, item in ipairs(itemDetails) do
            local formattedPrice = _G.FormatNumber(item.Price)
            local currency = item.Currency or "Coins"
            table.insert(list, string.format(" • %s: %s %s", item.Name, formattedPrice, currency))
        end
        
        return table.concat(list, "\n")
    end

    _G.RedrawMerchantButtons = function(itemDetails)
        if not _G.shopTab then return end
        
        _G.ClearOldMerchantButtons()
        
        if not itemDetails then
            itemDetails = {}
        end
        
        if #itemDetails > 0 then
            for _, item in ipairs(itemDetails) do
                local formattedPrice = _G.FormatNumber(item.Price)
                local currency = item.Currency or "Coins"
                
                local newButton = Utils:Button({
                    Title = string.format("BUY: %s", item.Name),
                    Desc = string.format("Price: %s %s", formattedPrice, currency),
                    Icon = "shopping-cart",
                    Callback = function()
                        _G.BuyMerchantItem(item.ID, item.Name)
                    end
                })
                table.insert(_G.MerchantButtons, newButton)
            end
        else
            local noStockIndicator = Utils:Paragraph({
                Title = "No Buyable Items",
                Desc = "Tidak ada tombol yang tersedia.",
                Icon = "info",
            })
            table.insert(_G.MerchantButtons, noStockIndicator)
        end
    end

    _G.RunAutoBuyStockLoop = function()
        if _G.autoBuyThread then 
            task.cancel(_G.autoBuyThread) 
        end
        
        _G.autoBuyThread = task.spawn(function()
            while _G.autoBuyStockState do
                if _G.MerchantReplion and _G.MerchantReplion.Data then
                    local currentDetails = _G.GetMerchantStockDetails(_G.MerchantReplion.Data)
                    if currentDetails and #currentDetails > 0 then
                        for _, item in ipairs(currentDetails) do
                            _G.BuyMerchantItem(item.ID, item.Name)
                            task.wait(0.5)
                        end
                    end
                end
                task.wait(3)
            end
        end)
    end

    _G.RunAutoBuySelectedLoop = function(itemID, itemName)
        if _G.autoBuyThread then 
            task.cancel(_G.autoBuyThread) 
        end

        _G.autoBuyThread = task.spawn(function()
            while _G.autoBuySelectedState do
                _G.BuyMerchantItem(itemID, itemName)
                task.wait(1)
            end
        end)
    end

    _G.RunMerchantSyncLoop = function(mainDisplay)
        if _G.UpdateThread then 
            task.cancel(_G.UpdateThread) 
        end

        if not _G.MerchantReplion or not _G.MerchantReplion.Data then
            return function() end
        end
        
        local initialDetails = _G.GetMerchantStockDetails(_G.MerchantReplion.Data)
        _G.RedrawMerchantButtons(initialDetails)
        
        local stockUpdateConnection = nil
        if _G.MerchantReplion and _G.MerchantReplion.OnChange then
            stockUpdateConnection = _G.MerchantReplion:OnChange("Items", function(newItems)
                local currentDetails = _G.GetMerchantStockDetails(_G.MerchantReplion.Data)
                _G.RedrawMerchantButtons(currentDetails)
                
                local timeString = _G.getNextRefreshTimeString()
                local stockListString = _G.CreateStockListString(currentDetails)
                if mainDisplay and mainDisplay.SetTitle then
                    mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
                end
            end)
        end
        
        local isRunning = true
        
        _G.UpdateThread = task.spawn(function()
            while isRunning do
                local timeString = _G.getNextRefreshTimeString()
                local currentDetails = _G.GetMerchantStockDetails(_G.MerchantReplion.Data)
                local stockListString = _G.CreateStockListString(currentDetails)
                
                if mainDisplay and mainDisplay.SetTitle then
                    mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
                end
                task.wait(1)
            end
            
            if stockUpdateConnection then 
                stockUpdateConnection:Disconnect() 
            end
            _G.ClearOldMerchantButtons()
        end)
        
        return function()
            isRunning = false
            if _G.UpdateThread then 
                task.cancel(_G.UpdateThread) 
                _G.UpdateThread = nil 
            end
            if stockUpdateConnection then 
                stockUpdateConnection:Disconnect() 
            end
            _G.ClearOldMerchantButtons()
        end
    end

    _G.ToggleMerchantSync = function(state, mainDisplay)
        if state then
            task.spawn(function()
                if not _G.GetReplions() then
                    if WindUI then
                        WindUI:Notify({ 
                            Title = "Sync Gagal", 
                            Content = "Gagal memuat Replion Merchant.", 
                            Duration = 4, 
                            Icon = "x" 
                        })
                    end
                    if mainDisplay and mainDisplay.SetTitle then
                        mainDisplay:SetTitle("Sync Gagal: Merchant Replion missing/timeout.")
                        mainDisplay:SetDesc("Toggle OFF dan coba lagi.")
                    end
                    return
                end

                if WindUI then
                    WindUI:Notify({ 
                        Title = "Sync ON!", 
                        Content = "Memulai live update stok dan tombol beli.", 
                        Duration = 2, 
                        Icon = "check" 
                    })
                end
                if mainDisplay and mainDisplay.SetDesc then
                    mainDisplay:SetDesc("Waktu refresh dihitung akurat dari server.")
                end
                _G.UpdateCleanupFunction = _G.RunMerchantSyncLoop(mainDisplay)
            end)
            
            return true
        else
            if WindUI then
                WindUI:Notify({ 
                    Title = "Sync OFF!", 
                    Duration = 3, 
                    Icon = "x" 
                })
            end
            
            if _G.UpdateCleanupFunction then
                _G.UpdateCleanupFunction()
                _G.UpdateCleanupFunction = nil
            end
            
            if mainDisplay and mainDisplay.SetTitle then
                mainDisplay:SetTitle("Merchant Live Data OFF.")
                mainDisplay:SetDesc("Toggle ON untuk melihat status live.")
            end
            _G.ClearOldMerchantButtons()
            
            return false
        end
    end

    _G.GetStaticMerchantOptions = function()
        local options = {}
        local items = _G.MerchantStaticItems()
        if not items or #items == 0 then
            return options
        end
        
        for _, item in ipairs(items) do
            local formattedPrice = _G.FormatNumber(item.Price)
            table.insert(options, string.format("%s (%s)", item.Name, formattedPrice))
        end
        return options
    end

    _G.GetStaticMerchantItemID = function(dropdownValue)
        if not dropdownValue then 
            return nil, nil 
        end
        
        local items = _G.MerchantStaticItems()
        if not items then
            return nil, nil
        end
        
        for _, item in ipairs(items) do
            if dropdownValue:match("^" .. item.Name:gsub("%%", "%%%%") .. " ") then
                return item.ID, item.Name
            end
        end
        return nil, nil
    end

    -- UI MERCHANT
    if not Utils then return end
    
    local merchant = Utils:Section({
        Title = "Traveling Merchant",
        TextSize = 20,
        TextXAlignment = "Center",
        Opened = true
    })
    Utils:Divider()

    _G.MainDisplayElement = merchant:Paragraph({
        Title = "Merchant Live Data OFF.",
        Desc = "Toggle ON untuk melihat status live.",
        Icon = "clock"
    })

    local tlive = merchant:Toggle({
        Title = "Live Stock & Buy Actions",
        Value = false,
        Flag = "tlive",
        Callback = function(state)
            return _G.ToggleMerchantSync(state, _G.MainDisplayElement)
        end,
    })

    local tcurst = merchant:Toggle({
        Title = "Auto Buy Current Stock",
        Value = false,
        Flag = "tcurst",
        Callback = function(state)
            _G.autoBuyStockState = state
            if state then
                _G.RunAutoBuyStockLoop()
                if _G.autoBuySelectedState then
                    _G.autoBuySelectedState = false
                    local toggle = Utils:GetElementByTitle("Auto Buy Item Terpilih")
                    if toggle and toggle.Set then 
                        toggle:Set(false) 
                    end
                end
            else
                if _G.autoBuyThread then 
                    task.cancel(_G.autoBuyThread) 
                    _G.autoBuyThread = nil 
                end
            end
        end
    })

    local merchantStaticOptions = _G.GetStaticMerchantOptions()
    local StaticDropdown = merchant:Dropdown({
        Title = "Pilih Item Merchant",
        Values = merchantStaticOptions or {},
        Value = false,
        Multi = false,
        AllowNone = true,
        Flag = "dmerc",
        Callback = function(value)
            _G.selectedStaticItemName = value
            if _G.autoBuySelectedState then
                _G.autoBuySelectedState = false
                local toggle = Utils:GetElementByTitle("Auto Buy Item Terpilih")
                if toggle and toggle.Set then 
                    toggle:Set(false) 
                end
            end
        end
    })

    local butmerc = merchant:Button({
        Title = "Beli Sekali Item Terpilih",
        Icon = "mouse-pointer-click",
        Callback = function()
            local itemID, itemName = _G.GetStaticMerchantItemID(_G.selectedStaticItemName)
            if itemID then
                _G.BuyMerchantItem(itemID, itemName)
            else
                if WindUI then
                    WindUI:Notify({ 
                        Title = "Error", 
                        Content = "Item tidak valid atau belum dipilih.", 
                        Duration = 3, 
                        Icon = "x" 
                    })
                end
            end
        end
    })

    local ToggleSelectedBuy = merchant:Toggle({
        Title = "Auto Buy Item Terpilih",
        Value = false,
        Flag = "curst",
        Callback = function(state)
            _G.autoBuySelectedState = state
            if state then
                local itemID, itemName = _G.GetStaticMerchantItemID(_G.selectedStaticItemName)
                if itemID then
                    _G.RunAutoBuySelectedLoop(itemID, itemName)
                    if _G.autoBuyStockState then
                        _G.autoBuyStockState = false
                        local toggle = Utils:GetElementByTitle("Auto Buy Current Stock")
                        if toggle and toggle.Set then 
                            toggle:Set(false) 
                        end
                    end
                else
                    if WindUI then
                        WindUI:Notify({ 
                            Title = "Error", 
                            Content = "Pilih item valid di dropdown.", 
                            Duration = 3, 
                            Icon = "x" 
                        })
                    end
                    return false
                end
            else
                if _G.autoBuyThread then 
                    task.cancel(_G.autoBuyThread) 
                    _G.autoBuyThread = nil 
                end
            end
        end
    })

    local telemerc = merchant:Button({ 
        Title = "Teleport To Merchant Shop", 
        Icon = "map-pin", 
        Callback = function() 
            local teleportFunc = _G.TeleportToLookAt or function() end
            teleportFunc(Vector3.new(-127.747, 2.718, 2759.031), Vector3.new(-0.920, 0.000, -0.392))
        end 
    })
end

Utils:Space()

_G.TotemsSec = Utils:Section({
    Title = "Totems Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true,
})

Utils:Space()

_G.PotionsSec = Utils:Section({
    Title = "Potion Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true,
})

Utils:Space()

_G.Misc = Utils:Section({
    Title = "Teleport & Misc Menu",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true,
})


-- =================================================================
-- LIBRARY & DEPENDENCIES
-- =================================================================
_G.ItemUtilityModule = require(ReplicatedStorage.Shared.ItemUtility)
_G.ClientReplionModule = require(ReplicatedStorage.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Client.ClientReplion)

-- Menyimpan Remote Event
_G.RESpawnTotem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/SpawnTotem"]

-- Mencoba mencari Remote Oxygen Tank (Untuk Anti-Drown)
pcall(function()
    local packages = game:GetService("ReplicatedStorage"):FindFirstChild("Packages")
    if packages then
        for _, v in pairs(packages:GetDescendants()) do
            if v.Name == "RF/EquipOxygenTank" then _G.RF_EquipOxygenTank = v end
            if v.Name == "RF/UnequipOxygenTank" then _G.RF_UnequipOxygenTank = v end
        end
    end
end)

-- =================================================================
-- VARIABLES & CONFIGURATION
-- =================================================================
_G.TotemInventoryCache = {} 
_G.TotemsList = {}
_G.AutoTotemState = {
    IsRunning = false,
    DelayMinutes = 10,
    SelectedTotemName = nil,
    LoopThread = nil,
}

_G.AUTO_9_TOTEM_ACTIVE = false
_G.AUTO_9_TOTEM_THREAD = nil
_G.stateConnection = nil
_G.RunService = game:GetService("RunService")

-- [CONFIG] Koordinat Formasi V3 (Relative Offsets)
-- Ini memastikan formasi tetap rapi (3 Bawah, 3 Tengah, 3 Atas)
_G.REF_CENTER = Vector3.new(93.932, 9.532, 2684.134)
_G.REF_SPOTS = {
    -- TENGAH (Y ~ 9.5)
    Vector3.new(45.0468979, 9.51625347, 2730.19067),   -- 1
    Vector3.new(145.644608, 9.51625347, 2721.90747),   -- 2
    Vector3.new(84.6406631, 10.2174253, 2636.05786),   -- 3
    -- ATAS (Y ~ 109.5)
    Vector3.new(45.0468979, 110.516253, 2730.19067),   -- 4
    Vector3.new(145.644608, 110.516253, 2721.90747),   -- 5
    Vector3.new(84.6406631, 111.217425, 2636.05786),   -- 6
    -- BAWAH (Y ~ -90.5)
    Vector3.new(45.0468979, -92.483747, 2730.19067),   -- 7
    Vector3.new(145.644608, -92.483747, 2721.90747),   -- 8
    Vector3.new(84.6406631, -93.782575, 2636.05786),   -- 9
}

-- =================================================================
-- INVENTORY FUNCTIONS
-- =================================================================
function _G.RefreshTotemInventory()
    if not _G.DataReplion then return end

    _G.TotemInventoryCache = {}
    _G.TotemsList = {}

    local items = _G.DataReplion:Get({ "Inventory", "Totems" })

    if not items then
        if _G.TotemDropdown then _G.TotemDropdown:Refresh({}) end
        if _G.TotemStatusParagraph then
            _G.TotemStatusParagraph:SetDesc("Inventory refreshed. Found 0 types of totems.")
        end
        return
    end

    for _, item in ipairs(items) do
        local totemData = _G.ItemUtilityModule:GetTotemsData(item.Id)
        if totemData and totemData.Data then
            local name = totemData.Data.Name
            if not _G.TotemInventoryCache[name] then
                _G.TotemInventoryCache[name] = {}
            end
            table.insert(_G.TotemInventoryCache[name], item.UUID)
        end
    end

    for name, list in pairs(_G.TotemInventoryCache) do
        local count = #list 
        table.insert(_G.TotemsList, string.format("%s (x%d)", name, count))
    end

    table.sort(_G.TotemsList)

    if _G.TotemDropdown then
        _G.TotemDropdown:Refresh(_G.TotemsList)
    end

    if _G.TotemStatusParagraph then
        _G.TotemStatusParagraph:SetDesc(
            string.format("Inventory refreshed. Found %d types of totems.", #_G.TotemsList)
        )
    end
end

function _G.ConsumeTotemUUID(totemName)
    if not _G.TotemInventoryCache then return nil end
    -- Bersihkan nama dari "(x5)" -> "Luck Totem"
    local cleanName = totemName:match("^(.-) %(") or totemName
    
    local list = _G.TotemInventoryCache[cleanName]
    if list and #list > 0 then
        return table.remove(list, 1)
    end
    return nil
end

-- =================================================================
-- PHYSICS V3 ENGINE (Anti-Fall & Smooth Fly)
-- =================================================================
function _G.GetFlyPart()
    local char = game.Players.LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

function _G.MaintainAntiFallState(enable)
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return end

    if enable then
        -- Matikan state jatuh agar server tidak menolak posisi
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

        if not _G.stateConnection then
            _G.stateConnection = _G.RunService.Heartbeat:Connect(function()
                if hum and _G.AUTO_9_TOTEM_ACTIVE then
                    -- Paksa swimming agar stabil di udara
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
                end
            end)
        end
    else
        if _G.stateConnection then _G.stateConnection:Disconnect(); _G.stateConnection = nil end
        -- Kembalikan normal
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    end
end

function _G.EnableV3Physics()
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local mainPart = _G.GetFlyPart()
    
    if not mainPart or not hum then return end

    if char:FindFirstChild("Animate") then char.Animate.Disabled = true end
    hum.PlatformStand = true
    
    _G.MaintainAntiFallState(true)

    local bg = mainPart:FindFirstChild("FlyGuiGyro") or Instance.new("BodyGyro")
    bg.Name = "FlyGuiGyro"; bg.P = 9e4; bg.maxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = mainPart.CFrame; bg.Parent = mainPart

    local bv = mainPart:FindFirstChild("FlyGuiVelocity") or Instance.new("BodyVelocity")
    bv.Name = "FlyGuiVelocity"; bv.velocity = Vector3.new(0, 0.1, 0); bv.maxForce = Vector3.new(9e9, 9e9, 9e9); bv.Parent = mainPart

    task.spawn(function()
        while _G.AUTO_9_TOTEM_ACTIVE and char do
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            task.wait(0.1)
        end
    end)
end

function _G.DisableV3Physics()
    local char = game.Players.LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local mainPart = _G.GetFlyPart()

    if mainPart then
        if mainPart:FindFirstChild("FlyGuiGyro") then mainPart.FlyGuiGyro:Destroy() end
        if mainPart:FindFirstChild("FlyGuiVelocity") then mainPart.FlyGuiVelocity:Destroy() end

        mainPart.Velocity = Vector3.zero
        mainPart.RotVelocity = Vector3.zero
        mainPart.AssemblyLinearVelocity = Vector3.zero
        mainPart.AssemblyAngularVelocity = Vector3.zero

        local _, y, _ = mainPart.CFrame:ToEulerAnglesYXZ()
        mainPart.CFrame = CFrame.new(mainPart.Position) * CFrame.fromEulerAnglesYXZ(0, y, 0)

        -- Anti nyangkut lantai
        local ray = Ray.new(mainPart.Position, Vector3.new(0, -5, 0))
        local hit = workspace:FindPartOnRay(ray, char)
        if hit then mainPart.CFrame = mainPart.CFrame + Vector3.new(0, 3, 0) end
    end

    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    _G.MaintainAntiFallState(false)

    if char and char:FindFirstChild("Animate") then char.Animate.Disabled = false end

    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

function _G.FlyPhysicsTo(targetPos)
    local mainPart = _G.GetFlyPart()
    if not mainPart then return end
    
    local bv = mainPart:FindFirstChild("FlyGuiVelocity")
    local bg = mainPart:FindFirstChild("FlyGuiGyro")
    
    local SPEED = 120
    
    while _G.AUTO_9_TOTEM_ACTIVE do
        local currentPos = mainPart.Position
        local diff = targetPos - currentPos
        local dist = diff.Magnitude
        
        if bg then bg.CFrame = CFrame.lookAt(currentPos, targetPos) end

        if dist < 1.0 then 
            if bv then bv.velocity = Vector3.new(0, 0.1, 0) end
            break
        else
            if bv then bv.velocity = diff.Unit * SPEED end
        end
        _G.RunService.Heartbeat:Wait()
    end
end

-- =================================================================
-- LOGIC 9 TOTEM (Pause Fish -> Oxygen -> Spawn -> Resume)
-- =================================================================
function _G.Run9TotemLoop()
    if _G.AUTO_9_TOTEM_ACTIVE then return end
    
    if not _G.AutoTotemState.SelectedTotemName then 
        NotifyError("Error", "Select a totem first!")
        return 
    end

    _G.AUTO_9_TOTEM_ACTIVE = true

    task.spawn(function()
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local hum = char:WaitForChild("Humanoid")


        local myStartPos = hrp.Position
        local firstPost = hrp.CFrame
        
        if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Starting V3 Engine...") end

        -- 2. Equip Oxygen (Anti-Drown)
        if _G.RF_EquipOxygenTank then 
            pcall(function() _G.RF_EquipOxygenTank:InvokeServer(105) end) 
        end

        _G.EnableV3Physics()

        for i, refSpot in ipairs(_G.REF_SPOTS) do
            if not _G.AUTO_9_TOTEM_ACTIVE then break end

            local uuid = _G.ConsumeTotemUUID(_G.AutoTotemState.SelectedTotemName)
            if not uuid then 
                NotifyError("Error", "Ran out of totems at stack #"..i)
                break 
            end

            -- Hitung Posisi Relative
            local relativePos = refSpot - _G.REF_CENTER
            local targetPos = myStartPos + relativePos

            -- Terbang ke posisi
            if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Flying to spot #"..i) end
            _G.FlyPhysicsTo(targetPos)

            -- Stabilisasi (0.6s)
            task.wait(0.6)

            -- Spawn Totem
            _G.RESpawnTotem:FireServer(uuid)
            if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Spawning #"..i) end

            -- Jeda antar spawn (1.5s)
            task.wait(1.5)
        end

        -- 3. Kembali ke posisi awal
        if _G.AUTO_9_TOTEM_ACTIVE then
            if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Returning...") end
            hrp.CFrame = firstPost
            task.wait(0.5)
        end

        -- 4. Cleanup & Landing
        if _G.RF_UnequipOxygenTank then 
            pcall(function() _G.RF_UnequipOxygenTank:InvokeServer() end) 
        end

        _G.DisableV3Physics()
        _G.AUTO_9_TOTEM_ACTIVE = false
        
        if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Landing & Stabilizing...") end
        
        -- FIX: Tunggu sampai karakter menyentuh tanah dan animasi "GettingUp" selesai
        task.wait(1.5) 

        -- Paksa Equip Rod (Pancingan) agar AutoFish tidak error
        pcall(function()
            local bp = player.Backpack
            local rod = bp:FindFirstChild("Rod") or bp:FindFirstChild("Fishing Rod")
            if rod and hum then hum:EquipTool(rod) end
        end)
        task.wait(0.5)
        
        NotifySuccess("Success", "9 Totem Stack")
    end)
end

-- =================================================================
-- LOGIC AUTO TOTEM BIASA (SINGLE LOOP)
-- =================================================================
function _G.StopAutoTotem()
    _G.AutoTotemState.IsRunning = false
    if _G.AutoTotemState.LoopThread then
        task.cancel(_G.AutoTotemState.LoopThread)
        _G.AutoTotemState.LoopThread = nil
    end
    if _G.TotemStatusParagraph then
        _G.TotemStatusParagraph:SetDesc("Auto Totem Stopped.")
    end
    NotifyWarning("Auto Totem", "Stopped.")
end

function _G.StartAutoTotem()
    _G.AutoTotemState.IsRunning = true

    _G.AutoTotemState.LoopThread = task.spawn(function()
        while _G.AutoTotemState.IsRunning do
            local player = game.Players.LocalPlayer
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            local hum = char:WaitForChild("Humanoid")
            local rawName = _G.AutoTotemState.SelectedTotemName
            if not rawName or rawName == "" then
                NotifyError("Auto Totem", "No totem selected.")
                return _G.StopAutoTotem()
            end

            -- Clean name
            local cleanName = rawName:match("^(.-) %(") or rawName

            -- Cek Stok
            local totemList = _G.TotemInventoryCache[cleanName]
            if not totemList or #totemList == 0 then
                _G.RefreshTotemInventory()
                task.wait(1)
                totemList = _G.TotemInventoryCache[cleanName]
                if not totemList or #totemList == 0 then
                    NotifyError("Auto Totem", "No more '" .. cleanName .. "'.")
                    return _G.StopAutoTotem()
                end
            end


            -- Spawn Totem
            local uuid = table.remove(totemList, 1)
            if uuid then
                _G.RESpawnTotem:FireServer(uuid)
                NotifySuccess("Auto Totem", "Spawned 1x " .. cleanName)
            end
            
                    -- Paksa Equip Rod (Pancingan) agar AutoFish tidak error
            pcall(function()
                local bp = player.Backpack
                local rod = bp:FindFirstChild("Rod") or bp:FindFirstChild("Fishing Rod")
                if rod and hum then hum:EquipTool(rod) end
            end)
            task.wait(0.5)
                

            -- Delay Countdown
            local delaySeconds = _G.AutoTotemState.DelayMinutes * 60
            local waited = 0
            
            while waited < delaySeconds and _G.AutoTotemState.IsRunning do
                local remaining = delaySeconds - waited
                local minutes = math.floor(remaining / 60)
                local seconds = remaining % 60
            
                if _G.TotemStatusParagraph then
                    _G.TotemStatusParagraph:SetDesc(
                        string.format("Waiting %02d:%02d...", minutes, seconds)
                    )
                end
                
                local step = math.min(5, remaining)
                task.wait(step)
                waited = waited + step
            end
        end
    end)
end

-- =======================================================
-- UI SETUP
-- =======================================================

_G.TotemStatusParagraph = _G.TotemsSec:Paragraph({
    Title = "Auto Totem Status",
    Desc = "Waiting for data..."
})

_G.TotemDropdown = _G.TotemsSec:Dropdown({
    Title = "Select Totem",
    Values = {"Loading inventory..."},
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(val)
        if not val then
            _G.AutoTotemState.SelectedTotemName = nil
            return
        end
        local clean = val:match("^(.-) %(") or val
        _G.AutoTotemState.SelectedTotemName = clean
    end
})

_G.TotemDelayInput = _G.TotemsSec:Input({
    Title = "Delay",
    Placeholder = "Enter minutes...",
    Default = 10,
    Callback = function(val)
        _G.AutoTotemState.DelayMinutes = tonumber(val) or 10
    end
})

_G.TotemsSec:Button({ Title = "Refresh Totems", Icon = "refresh-cw", Callback = _G.RefreshTotemInventory })

_G.TotemsSec:Toggle({
    Title = "Enable Auto Totem",
    Value = false,
    Callback = function(state)
        if state then _G.StartAutoTotem() else _G.StopAutoTotem() end
    end
})

_G.TotemsSec:Space()

_G.TotemsSec:Button({
    Title = "Spawn 9 Totems",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.Run9TotemLoop()
    end
})

task.spawn(function()
    while not _G.Replion do 
        if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Waiting for _G.Replion...") end
        task.wait(2) 
    end
    
    _G.DataReplion = _G.Replion.Client:WaitReplion("Data")
    if not _G.DataReplion then
        if _G.TotemStatusParagraph then _G.TotemStatusParagraph:SetDesc("Error: Failed to connect to Server Data.") end
        return
    end

    _G.RefreshTotemInventory()
end)

_G.TotemsSec:Space()

-- Remote for consuming potions
_G.RFConsumePotion = ReplicatedStorage
    .Packages._Index["sleitnick_net@0.2.0"]
    .net["RF/ConsumePotion"]

-- Global states
_G.PotionInventoryCache = {} -- { ["Potion Name"] = {uuid1, uuid2, ...} }
_G.PotionList = {}

_G.AutoPotionState = {
    IsRunning = false,
    DelayMinutes = 5,
    Amount = 1,
    SelectedPotionName = nil,
    LoopThread = nil
}

function _G.RefreshPotionInventory()
    if not _G.DataReplion then return end

    _G.PotionInventoryCache = {}
    _G.PotionList = {}

    local potions = _G.DataReplion:Get({ "Inventory", "Potions" })
    if not potions then
        if _G.PotionDropdown then _G.PotionDropdown:Refresh({}) end
        return
    end

    for _, item in ipairs(potions) do
        local potionData = _G.ItemUtilityModule:GetPotionData(item.Id)
        if potionData and potionData.Data then
            local name = potionData.Data.Name

            -- Format baru: setiap nama menyimpan 1 UUID + Quantity
            _G.PotionInventoryCache[name] = {
                UUID = item.UUID,
                Quantity = item.Quantity or 1,
                Id = item.Id
            }

            table.insert(_G.PotionList, string.format("%s (x%d)", name, item.Quantity or 1))
        end
    end

    table.sort(_G.PotionList)
    if _G.PotionDropdown then
        _G.PotionDropdown:Refresh(_G.PotionList)
    end
    
    if _G.PotionStatusParagraph then
        _G.PotionStatusParagraph:SetDesc(
            string.format("Inventory refreshed. Found %d types of potions.", #_G.PotionList)
        )
    end
end

function _G.StopAutoPotion()
    _G.AutoPotionState.IsRunning = false
    if _G.AutoPotionState.LoopThread then
        task.cancel(_G.AutoPotionState.LoopThread)
        _G.AutoPotionState.LoopThread = nil
    end

    if _G.PotionStatusParagraph then
        _G.PotionStatusParagraph:SetDesc("Auto Potion Stopped.")
    end
end

function _G.StartAutoPotion()
    _G.AutoPotionState.IsRunning = true

    _G.AutoPotionState.LoopThread = task.spawn(function()
        while _G.AutoPotionState.IsRunning do

            -- Validasi pilihan
            local raw = _G.AutoPotionState.SelectedPotionName
            if not raw then
                NotifyError("Auto Potion", "No potion selected.")
                return _G.StopAutoPotion()
            end

            local cleanName = raw:match("^(.-) %(") or raw
            local potionInfo = _G.PotionInventoryCache[cleanName]

            if not potionInfo then
                NotifyError("Auto Potion", "Potion not found: " .. cleanName)
                _G.RefreshPotionInventory()
                return _G.StopAutoPotion()
            end

            local uuid = potionInfo.UUID
            local quantity = potionInfo.Quantity or 0
            local amount = tonumber(_G.AutoPotionState.Amount) or 1

            -- ============== PERBAIKAN UTAMA ==============
            -- amount tidak boleh lebih besar dari stack
            if amount > quantity then
                amount = quantity
            end
            -- =============================================

            if quantity <= 0 then
                NotifyError("Auto Potion", cleanName .. " is out of stock.")
                _G.RefreshPotionInventory()
                return _G.StopAutoPotion()
            end

            local success, result = pcall(function()
                return _G.RFConsumePotion:InvokeServer(uuid, amount)
            end)

            if success then
                NotifySuccess("Potion", "Consumed " .. amount .. "x " .. cleanName)
                potionInfo.Quantity = potionInfo.Quantity - amount
            else
                NotifyError("Potion", "Failed consuming potion.")
            end    

            -- Delay
            local delaySeconds = (_G.AutoPotionState.DelayMinutes or 1) * 60
            local waited = 0

            while waited < delaySeconds and _G.AutoPotionState.IsRunning do
                local remaining = delaySeconds - waited
                local m = math.floor(remaining / 60)
                local s = remaining % 60

                _G.PotionStatusParagraph:SetDesc(
                    string.format("Next: %02d:%02d | %s left: %d", 
                        m, s, cleanName, potionInfo.Quantity)
                )

                local step = math.min(5, remaining)
                task.wait(step)
                waited = waited + step
            end

            -- refresh supaya UI dan cache update benar setelah konsumsi
            _G.RefreshPotionInventory()
        end
    end)
end

_G.PotionStatusParagraph = _G.PotionsSec:Paragraph({
    Title = "Auto Potion Status",
    Desc = "Waiting for data..."
})

_G.PotionDropdown = _G.PotionsSec:Dropdown({
    Title = "Select Potion",
    Values = { "Loading..." },
    SearchBarEnabled = true,
    AllowNone = true,
    Callback = function(val)
        if not val then
            _G.AutoPotionState.SelectedPotionName = nil
            return
        end

        local clean = val:match("^(.-) %(") or val
        _G.AutoPotionState.SelectedPotionName = clean
    end
})

_G.PotionsSec:Input({
    Title = "Amount",
    Placeholder = "e.g. 1",
    Default = 1,
    Type = "Input",
    Callback = function(val)
        _G.AutoPotionState.Amount = tonumber(val) or 1
    end
})

_G.PotionsSec:Input({
    Title = "Delay (Minutes)",
    Placeholder = "e.g. 5",
    Default = 5,
    Type = "Input",
    Callback = function(val)
        _G.AutoPotionState.DelayMinutes = tonumber(val) or 5
    end
})

_G.PotionsSec:Button({
    Title = "Refresh Potions",
    Icon = "refresh-cw",
    Callback = _G.RefreshPotionInventory
})

_G.PotionsSec:Toggle({
    Title = "Enable Auto Potion",
    Value = false,
    Callback = function(state)
        if state then
            _G.StartAutoPotion()
        else
            _G.StopAutoPotion()
        end
    end
})

task.spawn(function()
    while not _G.Replion do
        _G.PotionStatusParagraph:SetDesc("Waiting for _G.Replion...")
        task.wait(1)
    end

    if not _G.DataReplion then
        _G.DataReplion = _G.Replion.Client:WaitReplion("Data")
    end

    if not _G.DataReplion then
        _G.PotionStatusParagraph:SetDesc("Failed to read inventory.")
        return
    end

    _G.RefreshPotionInventory()
end)

_G.PotionsSec:Space()

_G.AutoSellEnchantState = {
    Enabled = false,
    Amount = 1,
    LoopThread = nil
}

_G.RFSellItem = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellItem"]


_G.AutoSellProgressParagraph = _G.Misc:Paragraph({
    Title = "Auto Sell Status",
    Desc = "Idle..."
})

_G.Misc:Space()

_G.RFRedeemCode = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RF/RedeemCode"]
_G.RedeemCodes = {
    "BLAMETALON",
    "FISHMAS2025",
    "GOLDENSHARK",
    "THANKYOU",
    "PURPLEMOON"
}


_G.RedeemAllCodes = function()
    for _, code in ipairs(_G.RedeemCodes) do
        local success, result = pcall(function()
            return _G.RFRedeemCode:InvokeServer(code)
        end)
        task.wait(1)
    end
end

_G.Misc:Button({
    Title = "Redeem All Codes",
    Locked = false,
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.RedeemAllCodes()
    end
})

_G.Misc:Space()

local weatherActive = {}
local weatherData = {
    ["Storm"] = { duration = 900 },
    ["Cloudy"] = { duration = 900 },
    ["Snow"] = { duration = 900 },
    ["Wind"] = { duration = 900 },
    ["Radiant"] = { duration = 900 }
}

local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

local function autoBuyWeather(weatherType)
    local purchaseRemote = ReplicatedStorage:WaitForChild("Packages")
        :WaitForChild("_Index")
        :WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net")
        :WaitForChild("RF/PurchaseWeatherEvent")

    task.spawn(function()
        while weatherActive[weatherType] do
            pcall(function()
                purchaseRemote:InvokeServer(weatherType)
                NotifySuccess("Weather Purchased", "Successfully activated " .. weatherType)

                task.wait(weatherData[weatherType].duration)

                local randomWait = randomDelay(1, 5)
                NotifyInfo("Waiting...", "Delay before next purchase: " .. tostring(randomWait) .. "s")
                task.wait(randomWait)
            end)
        end
    end)
end

local WeatherDropdown = _G.Misc:Dropdown({
    Title = "Auto Buy Weather",
    Values = { "Storm", "Cloudy", "Snow", "Wind", "Radiant" },
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        for weatherType, active in pairs(weatherActive) do
            if active and not table.find(selected, weatherType) then
                weatherActive[weatherType] = false
                NotifyWarning("Auto Weather", "Auto buying " .. weatherType .. " has been stopped.")
            end
        end
        for _, weatherType in pairs(selected) do
            if not weatherActive[weatherType] then
                weatherActive[weatherType] = true
                NotifyInfo("Auto Weather", "Auto buying " .. weatherType .. " has started!")
                autoBuyWeather(weatherType)
            end
        end
    end
})

myConfig:Register("WeatherDropdown", WeatherDropdown)

_G.Misc:Space()

local islandCoords = {
    ["01"] = { name = "Weather Machine", position = Vector3.new(-1471, -3, 1929) },
    ["02"] = { name = "Esoteric Depths", position = Vector3.new(3157, -1303, 1439) },
    ["03"] = { name = "Tropical Grove", position = Vector3.new(-2038, 3, 3650) },
    ["04"] = { name = "Fisherman Island", position = Vector3.new(-32, 4, 2773) },
    ["05"] = { name = "Kohana Volcano", position = Vector3.new(-519, 24, 189) },
    ["06"] = { name = "Coral Reefs", position = Vector3.new(-3095, 1, 2177) },
    ["07"] = { name = "Crater Island", position = Vector3.new(968, 1, 4854) },
    ["08"] = { name = "Kohana", position = Vector3.new(-658, 3, 719) },
    ["09"] = { name = "Winter Fest", position = Vector3.new(1611, 4, 3280) },
    ["10"] = { name = "Isoteric Island", position = Vector3.new(1987, 4, 1400) },
    ["11"] = { name = "Treasure Hall", position = Vector3.new(-3600, -267, -1558) },
    ["12"] = { name = "Lost Shore", position = Vector3.new(-3663, 38, -989) },
    ["13"] = { name = "Sishypus Statue", position = Vector3.new(-3792, -135, -986) },
    ["14"] = { name = "Ancient Jungle", position = Vector3.new(1478, 131, -613) },
    ["15"] = { name = "The Temple", position = Vector3.new(1477, -22, -631) },
    ["16"] = { name = "Underground Cellar", position = Vector3.new(2133, -91, -674) },
    ["17"] = {name = "Ancient Ruin", position = Vector3.new(6052, -546, 4427) },
    ["21"] = {name = "Pirate Cove", position = Vector3.new(3497, 4, 3447) }
}

local islandNames = {}
for _, data in pairs(islandCoords) do
    table.insert(islandNames, data.name)
end

_G.Misc:Dropdown({
    Title = "Island Selector",
    Desc = "Select island to teleport",
    Values = islandNames,
    SearchBarEnabled = true,
    Callback = _G.ProtectCallback(function(selectedName)
        for code, data in pairs(islandCoords) do
            if data.name == selectedName then
                local success, err = pcall(function()
                    local charFolder = workspace:WaitForChild("Characters", 5)
                    local char = charFolder:FindFirstChild(LocalPlayer.Name)
                    if not char then error("Character not found") end
                    local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
                    if not hrp then error("HumanoidRootPart not found") end
                    hrp.CFrame = CFrame.new(data.position + Vector3.new(0, 5, 0))
                end)

                if success then
                    NotifySuccess("Teleported!", "You are now at " .. selectedName)
                else
                    NotifyError("Teleport Failed", tostring(err))
                end
                break
            end
        end
    end)
})

local eventsList = { 
    "Shark Hunt", 
    "Ghost Shark Hunt", 
    "Worm Hunt", 
    "Black Hole", 
    "Shocked", 
    "Ghost Worm", 
    "Meteor Rain", 
    "Megalodon Hunt" 
}

_G.Client = require(ReplicatedStorage.Packages.Replion).Client



function getPartRecursive(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        elseif child:IsA("Model") or child:IsA("Folder") then
            local found = getPartRecursive(child)
            if found then return found end
        end
    end
    return nil
end

_G.Misc:Dropdown({
    Title = "Teleport Event",
    Values = eventsList,
    Callback = function(option)
        local eventReplion = _G.Client:GetReplion("Events")
        local activeEvents = eventReplion and eventReplion:GetExpect("Events") or {}
        
        local isActive = false
        for _, name in ipairs(activeEvents) do
            if name == option then isActive = true break end
        end

        if not isActive then
            WindUI:Notify({Title = "Not Active", Content = option .. " Not yet started!", Icon = "clock"})
            return
        end

        local target = findEventPart(option)
        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if target and hrp then
            hrp.CFrame = target:GetPivot() + Vector3.new(0, 15, 0)
            WindUI:Notify({
                Title = "Success",
                Content = "Teleported to " .. option,
                Icon = "circle-check"
            })
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Failed find the Event Path!",
                Icon = "ban"
            })
        end
    end
})





local TweenService = game:GetService("TweenService")

local HRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera

local Items = ReplicatedStorage:WaitForChild("Items")
local Baits = ReplicatedStorage:WaitForChild("Baits")
local net = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")


local npcCFrame = CFrame.new(
    66.866745, 4.62500143, 2858.98535,
    -0.981261611, 5.77215005e-08, -0.192680314,
    6.94250204e-08, 1, -5.39889484e-08,
    0.192680314, -6.63541186e-08, -0.981261611
)


local function FadeScreen(duration)
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.1

    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.2), { BackgroundTransparency = 0.1 })
    tweenIn:Play()
    tweenIn.Completed:Wait()

    wait(duration)

    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 0.1 })
    tweenOut:Play()
    tweenOut.Completed:Wait()
    gui:Destroy()
end

local function SafePurchase(callback)
    local originalCFrame = HRP.CFrame
    HRP.CFrame = npcCFrame
    FadeScreen(0.2)
    pcall(callback)
    wait(0.1)
    HRP.CFrame = originalCFrame
end

local rodOptions = {}
local rodData = {}

for _, rod in ipairs(Items:GetChildren()) do
    if rod:IsA("ModuleScript") then
        local success, module = pcall(require, rod)
        if success and module and module.Data and module.Data.Type == "Fishing Rods" then
            local id = module.Data.Id
            local name = module.Data.Name or rod.Name
            local price = module.Price or module.Data.Price

            if price then
                table.insert(rodOptions, name .. " | Price: " .. tostring(price))
                rodData[name] = id
            end
        end
    end
end

_G.Misc:Dropdown({
    Title = "Rod Shop",
    Desc = "Select Rod to Buy",
    Values = rodOptions,
    SearchBarEnabled = true,
    Callback = function(option)
        local selectedName = option:split(" |")[1]
        local id = rodData[selectedName]

        SafePurchase(function()
            net:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(id)
            NotifySuccess("Rod Purchased", selectedName .. " has been successfully purchased!")
        end)
    end,
})


local baitOptions = {}
local baitData = {}

for _, bait in ipairs(Baits:GetChildren()) do
    if bait:IsA("ModuleScript") then
        local success, module = pcall(require, bait)
        if success and module and module.Data then
            local id = module.Data.Id
            local name = module.Data.Name or bait.Name
            local price = module.Price or module.Data.Price

            if price then
                table.insert(baitOptions, name .. " | Price: " .. tostring(price))
                baitData[name] = id
            end
        end
    end
end

_G.Misc:Dropdown({
    Title = "Baits Shop",
    Desc = "Select Baits to Buy",
    Values = baitOptions,
    SearchBarEnabled = true,
    Callback = function(option)
        local selectedName = option:split(" |")[1]
        local id = baitData[selectedName]

        SafePurchase(function()
            net:WaitForChild("RF/PurchaseBait"):InvokeServer(id)
            NotifySuccess("Bait Purchased", selectedName .. " has been successfully purchased!")
        end)
    end,
})

local npcFolder = game:GetService("ReplicatedStorage"):WaitForChild("NPC")

local npcList = {}
for _, npc in pairs(npcFolder:GetChildren()) do
    if npc:IsA("Model") then
        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
        if hrp then
            table.insert(npcList, npc.Name)
        end
    end
end


_G.Misc:Dropdown({
    Title = "NPC",
    Desc = "Select NPC to Teleport",
    Values = npcList,
    SearchBarEnabled = true,
    Callback = function(selectedName)
        local npc = npcFolder:FindFirstChild(selectedName)
        if npc and npc:IsA("Model") then
            local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            if hrp then
                local charFolder = workspace:FindFirstChild("Characters", 5)
                local char = charFolder and charFolder:FindFirstChild(LocalPlayer.Name)
                if not char then return end
                local myHRP = char:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    myHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                    NotifySuccess("Teleported!", "You are now near: " .. selectedName)
                end
            end
        end
    end
})

-------------------------------------------
----- =======[ SETTINGS TAB ]
-------------------------------------------

function _G.Disable3DRendering(enabled)
	if enabled then
		RunService:Set3dRenderingEnabled(false)
	else
		RunService:Set3dRenderingEnabled(true)
	end
end

SettingsTab:Toggle({
    Title = "Disable 3D Rendering",
    Value = false,
    Callback = function(state)
        _G.Disable3DRendering(state)
    end
})

SettingsTab:Button({
    Title = "Boost FPS (Ultra Low Graphics)",
    Callback = function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
                v.Transparency = v.Transparency > 0.5 and 1 or v.Transparency

            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1

            elseif v:IsA("ParticleEmitter") then
                v.Lifetime = NumberRange.new(0)

            elseif v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)

            elseif v:IsA("Smoke") 
            or v:IsA("Fire") 
            or v:IsA("Explosion") 
            or v:IsA("ForceField") 
            or v:IsA("Sparkles") 
            or v:IsA("Beam") then
                v.Enabled = false

            elseif v:IsA("Beam") 
            or v:IsA("SpotLight") 
            or v:IsA("PointLight") 
            or v:IsA("SurfaceLight") then
                v.Enabled = false

            elseif v:IsA("ShirtGraphic") 
            or v:IsA("Shirt") 
            or v:IsA("Pants") then
                v:Destroy()
            end
        end

        local Lighting = game:GetService("Lighting")
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ClockTime = 12
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)

        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            Terrain.Decoration = false
        end

        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.TextureQuality = Enum.TextureQuality.Low

        game:GetService("UserSettings").GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        game:GetService("UserSettings").GameSettings.Fullscreen = true

        for _, s in pairs(workspace:GetDescendants()) do
            if s:IsA("Sound") and s.Playing and s.Volume > 0.5 then
                s.Volume = 0.1
            end
        end

        if collectgarbage then
            collectgarbage("collect")
        end

        local fullWhite = Instance.new("ScreenGui")
        fullWhite.Name = "FullWhiteScreen"
        fullWhite.ResetOnSpawn = false
        fullWhite.IgnoreGuiInset = true
        fullWhite.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        fullWhite.Parent = game:GetService("CoreGui")

        local whiteFrame = Instance.new("Frame")
        whiteFrame.Size = UDim2.new(1, 0, 1, 0)
        whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1)
        whiteFrame.BorderSizePixel = 0
        whiteFrame.Parent = fullWhite

        NotifySuccess("Boost FPS", "Boost FPS mode applied successfully with Full White Screen!")
    end
})

SettingsTab:Space()

local TeleportService = game:GetService("TeleportService")

function _G.Rejoin()
    local player = Players.LocalPlayer
    if player then
        TeleportService:Teleport(game.PlaceId, player)
    end
end

function _G.ServerHop()
    local placeId = game.PlaceId
    local servers = {}
    local cursor = ""
    local found = false

    repeat
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor ~= "" then
            url = url .. "&cursor=" .. cursor
        end

        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if success and result and result.data then
            for _, server in pairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
            cursor = result.nextPageCursor or ""
        else
            break
        end
    until not cursor or #servers > 0

    if #servers > 0 then
        local targetServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
    else
        NotifyError("Server Hop Failed", "No servers available or all are full!")
    end
end

_G.Keybind = SettingsTab:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open UI",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

myConfig:Register("Keybind", _G.Keybind)

SettingsTab:Space()

SettingsTab:Button({
    Title = "Rejoin Server",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.Rejoin()
    end,
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Server Hop (New Server)",
    Justify = "Center",
    Icon = "",
    Callback = function()
        _G.ServerHop()
    end,
})

SettingsTab:Space()

SettingsTab:Section({
    Title = "Configuration",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = true
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Save",
    Justify = "Center",
    Icon = "",
    Callback = function()
        myConfig:Save()
        NotifySuccess("Config Saved", "Config has been saved!")
    end
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Load",
    Justify = "Center",
    Icon = "",
    Callback = function()
        myConfig:Load()
        NotifySuccess("Config Loaded", "Config has beed loaded!")
    end
})

task.defer(function()
    task.wait(0.5)
    _G.__UIReady = true
end)

-- ============================================================================
-- TELEGRAM SYSTEM - FIXED VARIANT DETECTION FOR ALL TIERS
-- ============================================================================

-- ========== CORE CONFIG ==========
_G.TELEGRAM_BOT_TOKEN = "8500785655:AAExgQrUUzLnT-yQwmSzQriJyQ-y0LY6r_E"

_G.TelegramConfig = {
    Enabled = false,
    BotToken = _G.TELEGRAM_BOT_TOKEN,
    ChatID = "",
    SelectedRarities = {},
    SelectedVariants = {},
    MaxSelection = 3,
    MaxVariantSelection = 5,
    QuestNotifications = true,
    DisconnectNotifications = true
}

-- ========== DATABASE INITIALIZATION ==========
_G.FishDataById = {}
_G.VariantDatabase = {}
_G.VariantIdToName = {}
_G.VariantNameToId = {}
_G.FishCategories = {
    ["Secret"] = {
        "Ancient Lochness Monster", "Ancient Whale", "Blob Shark", "Bloodmoon Whale", "Bone Whale",
        "Cryoshade Glider", "Crystal Crab", "Dead Zombie Shark", "Eerie Shark", "Elshark Gran Maja",
        "Frostborn Shark", "Ghost Shark", "Ghost Worm Fish", "Giant Squid", "Gladiator Shark",
        "Great Christmas Whale", "Great Whale", "King Jelly", "Lochness Monster", "Megalodon",
        "Monster Shark", "Mosasaur Shark", "Orca", "Queen Crab", "Robot Kraken", "Scare",
        "Skeleton Narwhal", "Talon Serpent", "Thin Armor Shark", "Wild Serpent", "Worm Fish",
        "Zombie Megalodon", "Zombie Shark"
    },
    ["Mythic"] = {
        "Ancient Relic Crocodile", "Ancient Squid", "Armor Catfish", "Blob Fish", "Cavern Dweller",
        "Crocodile", "Dark Pumpkin Appafish", "Flatheaded Whale Shark", "Fossilized Shark",
        "Frankenstein Longsnapper", "Gingerbread Shark", "Hammerhead Mummy",
        "Hybodus Shark", "King Crab", "Loving Shark", "Luminous Fish", "Magma Shark",
        "Mammoth Appafish", "Panther Eel", "Plasma Serpent", "Primordial Octopus",
        "Pumpkin Ray", "Runic Sea Crustacean", "Runic Squid", "Sea Crustacean",
        "Sharp One", "Starlight Manta Ray"
    },
    ["Legendary"] = {
        "Abyss Seahorse", "Ancient Pufferfish", "Blueflame Ray", "Crystal Salamander",
        "Deep Sea Crab", "Diamond Ring", "Dotted Stingray", "Fish Fossil", "Flying Manta",
        "Ghastly Crab", "Ghastly Hermit Crab", "Gingerbread Turtle", "Hammerhead Shark",
        "Hawks Turtle", "Lake Sturgeon", "Lined Cardinal Fish", "Loggerhead Turtle",
        "Manoai Statue Fish", "Manta Ray", "Plasma Shark", "Primal Axolotl",
        "Primal Lobster", "Prismy Seahorse", "Pumpkin Carved Shark", "Pumpkin Jellyfish",
        "Pumpkin StoneTurtle", "Ruby", "Runic Axolotl", "Runic Lobster",
        "Sacred Guardian Squid", "Saw Fish", "Strippled Seahorse", "Synodontis",
        "Temple Spokes Tuna", "Thresher Shark", "Wizard Stingray"
    }
}

_G.tierToRarity = {
    [1] = "COMMON",
    [2] = "UNCOMMON",
    [3] = "RARE",
    [4] = "EPIC",
    [5] = "LEGENDARY",
    [6] = "MYTHIC",
    [7] = "SECRET"
}

-- Load fish data
print("[Telegram] Loading fish database...")
_G.FishLoadedCount = 0
for _, item in pairs(ReplicatedStorage.Items:GetChildren()) do
    pcall(function()
        local data = require(item)
        if data.Data and data.Data.Type == "Fish" then
            _G.FishDataById[data.Data.Id] = {
                Name = data.Data.Name,
                SellPrice = data.SellPrice or 0,
                Tier = data.Data.Tier or 1,
                Source = data.Data.Source or nil,
                Icon = data.Data.Icon or nil,
                Weight = data.Data.Weight or nil,
                RawModule = data
            }
            _G.FishLoadedCount = _G.FishLoadedCount + 1
        end
    end)
end

-- Load variant data with MULTIPLE methods
print("[Telegram] Loading variant database...")
_G.VariantLoadedCount = 0

for _, variant in pairs(ReplicatedStorage.Variants:GetChildren()) do
    pcall(function()
        local data = require(variant)
        if data.Data then
            local variantId = data.Data.Id or variant.Name
            local variantName = data.Data.Name or variant.Name
            
            -- Multiple mappings for reliability
            _G.VariantDatabase[variantName] = variantId
            _G.VariantIdToName[variantId] = variantName
            _G.VariantNameToId[variantName] = variantId
            
            -- Also map by string version of ID
            _G.VariantIdToName[tostring(variantId)] = variantName
            
            _G.VariantLoadedCount = _G.VariantLoadedCount + 1
            print("[Telegram] Loaded variant:", variantName, "ID:", variantId)
        end
    end)
end

print("[Telegram] Loaded", _G.FishLoadedCount, "fish items")
print("[Telegram] Loaded", _G.VariantLoadedCount, "variants")

-- ========== CORE FUNCTIONS ==========
_G.GetItemInfo = function(itemId)
    local fishData = _G.FishDataById[itemId]
    if fishData then
        local tierNum = fishData.Tier or 1
        return {
            Name = fishData.Name,
            Type = "Fish",
            Tier = tierNum,
            SellPrice = fishData.SellPrice or 0,
            Weight = fishData.Weight or { Default = nil, Big = nil },
            Icon = fishData.Icon or nil,
            Source = fishData.Source or nil,
            Rarity = _G.tierToRarity[tierNum] or "UNKNOWN",
            RawModule = fishData.RawModule
        }
    end
    return {
        Name = "Unknown Item " .. tostring(itemId),
        Type = "Unknown",
        Tier = 0,
        SellPrice = 0,
        Weight = { Default = nil, Big = nil },
        Icon = nil,
        Rarity = "UNKNOWN"
    }
end

-- FIXED: Get variant name with AGGRESSIVE detection
_G.GetVariantName = function(variantId)
    if not variantId or variantId == "" or variantId == "0" or variantId == 0 then
        return ""
    end
    
    -- Try direct lookup (both types)
    local vId = tostring(variantId)
    if _G.VariantIdToName[variantId] then
        return _G.VariantIdToName[variantId]
    end
    if _G.VariantIdToName[vId] then
        return _G.VariantIdToName[vId]
    end
    
    -- Aggressive search
    local found = nil
    pcall(function()
        for _, variant in pairs(ReplicatedStorage.Variants:GetChildren()) do
            if variant.Name == vId or variant.Name == tostring(variantId) then
                local ok, data = pcall(require, variant)
                if ok and data.Data then
                    found = data.Data.Name or variant.Name
                    _G.VariantIdToName[variantId] = found
                    _G.VariantIdToName[vId] = found
                    print("[Telegram] Found variant via search:", found, "for ID:", variantId)
                    return
                end
            end
        end
        
        -- Try by Data.Id match
        for _, variant in pairs(ReplicatedStorage.Variants:GetChildren()) do
            local ok, data = pcall(require, variant)
            if ok and data.Data then
                local dataId = data.Data.Id or variant.Name
                if tostring(dataId) == vId or dataId == variantId then
                    found = data.Data.Name or variant.Name
                    _G.VariantIdToName[variantId] = found
                    _G.VariantIdToName[vId] = found
                    print("[Telegram] Found variant via Data.Id:", found, "for ID:", variantId)
                    return
                end
            end
        end
    end)
    
    if found then
        return found
    end
    
    print("[Telegram] WARNING: Variant ID not found:", variantId, "Type:", type(variantId))
    return ""
end

_G.GetFishRarityFromName = function(fishName)
    for rarity, list in pairs(_G.FishCategories) do
        for _, name in ipairs(list) do
            if name == fishName then
                return string.upper(rarity)
            end
        end
    end
    return "UNKNOWN"
end

-- ========== HTTP & UTILITY ==========
_G.safeJSONEncode = function(tbl)
    local ok, res = pcall(function() return HttpService:JSONEncode(tbl) end)
    if ok then return res end
    return "{}"
end

_G.pickHTTPRequest = function(requestTable)
    local ok, result
    if type(syn) == "table" and type(syn.request) == "function" then
        ok, result = pcall(function() return syn.request(requestTable) end)
    elseif type(http_request) == "function" then
        ok, result = pcall(function() return http_request(requestTable) end)
    elseif type(request) == "function" then
        ok, result = pcall(function() return request(requestTable) end)
    elseif type(http) == "table" and type(http.request) == "function" then
        ok, result = pcall(function() return http.request(requestTable) end)
    else
        return false, "No HTTP function"
    end
    return ok, result
end

_G.CountSelected = function()
    local c = 0
    for k, v in pairs(_G.TelegramConfig.SelectedRarities) do
        if v then c = c + 1 end
    end
    return c
end

_G.CountSelectedVariants = function()
    local c = 0
    for k, v in pairs(_G.TelegramConfig.SelectedVariants) do
        if v then c = c + 1 end
    end
    return c
end

_G.GetPlayerStats = function()
    local caught, rarest = "Unknown", "Unknown"
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        pcall(function()
            local c = ls:FindFirstChild("Caught") or ls:FindFirstChild("caught")
            if c and c.Value then caught = tostring(c.Value) end
            local r = ls:FindFirstChild("Rarest Fish") or ls:FindFirstChild("RarestFish") or ls:FindFirstChild("Rarest")
            if r and r.Value then rarest = tostring(r.Value) end
        end)
    end
    return caught, rarest
end

_G.RefreshInventoryCount = function()
    local count = 0
    pcall(function()
        if LocalPlayer.PlayerGui then
            local backpack = LocalPlayer.PlayerGui:FindFirstChild("Backpack")
            if backpack then
                for _, element in pairs(backpack:GetDescendants()) do
                    if element:IsA("TextLabel") and string.find(element.Text or "", "/") then
                        local current = string.match(element.Text, "(%d+)/")
                        if current then
                            count = tonumber(current) or 0
                            break
                        end
                    end
                end
            end
        end
    end)
    return count
end

-- ========== ROD DETECTION ==========
_G.RodDelays = {
    ["Ares Rod"] = true, ["Angler Rod"] = true, ["Ghostfinn Rod"] = true,
    ["Bamboo Rod"] = true, ["Element Rod"] = true, ["Fluorescent Rod"] = true,
    ["Astral Rod"] = true, ["Hazmat Rod"] = true, ["Chrome Rod"] = true,
    ["Steampunk Rod"] = true, ["Lucky Rod"] = true, ["Midnight Rod"] = true,
    ["Demascus Rod"] = true, ["Grass Rod"] = true, ["Luck Rod"] = true,
    ["Carbon Rod"] = true, ["Lava Rod"] = true, ["Starter Rod"] = true,
    ["Diamond Rod"] = true,
}

_G.GetValidRodName = function()
    local player = Players.LocalPlayer
    if not player then return "N/A" end
    local backpack = nil
    pcall(function() backpack = player.PlayerGui and player.PlayerGui:FindFirstChild("Backpack") end)
    if not backpack then return "N/A" end
    local display = backpack:FindFirstChild("Display")
    if not display then return "N/A" end
    for _, tile in ipairs(display:GetChildren()) do
        local inner = tile:FindFirstChild("Inner")
        local tags = inner and inner:FindFirstChild("Tags")
        local itemNameLabel = tags and tags:FindFirstChild("ItemName")
        if itemNameLabel and itemNameLabel:IsA("TextLabel") then
            local nm = itemNameLabel.Text
            if _G.RodDelays[nm] then return nm end
        end
    end
    return "Rod Not Found"
end

-- ========== IMAGE HELPERS ==========
_G.GetRobloxImage = function(assetId)
    if not assetId then return nil end
    local ok, response = pcall(function()
        return game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. tostring(assetId) .. "&size=420x420&format=Png&isCircular=false")
    end)
    if not ok or not response then return nil end
    local success, data = pcall(function() return HttpService:JSONDecode(response) end)
    if success and data and data.data and data.data[1] and data.data[1].imageUrl then
        return data.data[1].imageUrl
    end
    return nil
end

_G.GetPlayerAvatarUrl = function(userId)
    if not userId then return nil end
    local ok, response = pcall(function()
        return game:HttpGet(("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=png"):format(tostring(userId)))
    end)
    if not ok or not response then return nil end
    local success, data = pcall(function() return HttpService:JSONDecode(response) end)
    if success and data and data.data and data.data[1] and data.data[1].imageUrl then
        return data.data[1].imageUrl
    end
    return nil
end

-- ========== SIZE DETECTION ==========
_G.GetFishSizeLabel = function(itemInfo, weightValue, notificationData)
    if notificationData and notificationData.InventoryItem and notificationData.InventoryItem.Metadata then
        local meta = notificationData.InventoryItem.Metadata
        if meta.Size and type(meta.Size) == "string" then
            if meta.Size:lower():find("big") then return "Big" end
            return meta.Size
        end
        if meta.IsBig ~= nil then
            return meta.IsBig == true and "Big" or "Default"
        end
    end
    
    if itemInfo and itemInfo.Weight and (type(itemInfo.Weight) == "table") then
        local w = itemInfo.Weight
        if w.Big and w.Default and type(weightValue) == "number" then
            local tol = math.max(0.001, w.Default * 0.01)
            if math.abs(weightValue - (w.Big or 0)) <= tol then
                return "Big"
            else
                return "Default"
            end
        end
    end
    
    if type(weightValue) == "number" and weightValue >= 100 then
        return "Big"
    end
    
    return "Default"
end

-- ========== MESSAGE BUILDERS ==========
_G.BuildRarityMessage = function(fishInfo, fishId, fishRarity, weight, variantName, sizeLabel, rodName)
    local playerName = LocalPlayer.Name or "Unknown"
    local displayName = LocalPlayer.DisplayName or playerName
    local userId = tostring(LocalPlayer.UserId or "Unknown")
    local caught, rarest = _G.GetPlayerStats()
    local serverTime = os.date("%H:%M:%S")
    local serverDate = os.date("%Y-%m-%d")
    local inventoryCount = _G.RefreshInventoryCount()
    
    local fishName = (fishInfo and fishInfo.Name) or "Unknown"
    local fishTier = tostring((fishInfo and fishInfo.Tier) or "?")
    local sellPrice = tostring((fishInfo and fishInfo.SellPrice) or "?")
    
    local weightDisplay = "?"
    if weight then
        if type(weight) == "number" then
            weightDisplay = string.format("%.2fkg", weight)
        else
            weightDisplay = tostring(weight) .. "kg"
        end
    end
    
    local fishRarityStr = string.upper(tostring(fishRarity or (fishInfo and fishInfo.Rarity) or "UNKNOWN"))
    local invDisplay = inventoryCount and tostring(inventoryCount) .. "/4500" or "Unknown"
    
    local mutationText = "NO MUTATIONS"
    if variantName and variantName ~= "" and variantName ~= "0" then
        mutationText = variantName
    end
    
    local message = "```\n"
    message = message .. "🎉 HOREE ANDA BERHASIL MENDAPATKAN " .. fishRarityStr .. "! 🎉\n\n"
    message = message .. "========================================\n"
    message = message .. "NIKZZ SCRIPT FISH IT\n"
    message = message .. "DEVELOPER: NIKZZ\n"
    message = message .. "========================================\n\n"
    message = message .. "PLAYER INFORMATION\n"
    message = message .. "     NAME: " .. playerName .. "\n"
    if displayName ~= playerName then
        message = message .. "     DISPLAY: " .. displayName .. "\n"
    end
    message = message .. "     ID: " .. userId .. "\n"
    message = message .. "     CAUGHT: " .. caught .. "\n"
    message = message .. "     RAREST: " .. rarest .. "\n\n"
    message = message .. "FISH DETAILS\n"
    message = message .. "     NAME: " .. fishName .. "\n"
    message = message .. "     ID: " .. tostring(fishId or "?") .. "\n"
    message = message .. "     TIER: " .. fishTier .. "\n"
    message = message .. "     RARITY: " .. fishRarityStr .. "\n"
    message = message .. "     WEIGHT: " .. weightDisplay .. "\n"
    message = message .. "     SIZE: " .. (sizeLabel or "Default") .. "\n"
    message = message .. "     VARIANT: " .. mutationText .. "\n"
    message = message .. "     PRICE: " .. sellPrice .. " COINS\n\n"
    message = message .. "INVENTORY STATUS\n"
    message = message .. "     COUNT: " .. invDisplay .. "\n"
    message = message .. "     ROD: " .. (rodName or "Unknown") .. "\n\n"
    message = message .. "SYSTEM STATS\n"
    message = message .. "     TIME: " .. serverTime .. "\n"
    message = message .. "     DATE: " .. serverDate .. "\n\n"
    message = message .. "DEVELOPER SOCIALS\n"
    message = message .. "     TIKTOK: @nikzzxit\n"
    message = message .. "     INSTAGRAM: @n1kzx.z\n"
    message = message .. "STATUS: ACTIVE\n"
    message = message .. "========================================\n```"
    
    return message
end

_G.BuildVariantMessage = function(fishInfo, fishId, fishRarity, weight, variantName, sizeLabel, rodName)
    local playerName = LocalPlayer.Name or "Unknown"
    local displayName = LocalPlayer.DisplayName or playerName
    local userId = tostring(LocalPlayer.UserId or "Unknown")
    local caught, rarest = _G.GetPlayerStats()
    local serverTime = os.date("%H:%M:%S")
    local serverDate = os.date("%Y-%m-%d")
    local inventoryCount = _G.RefreshInventoryCount()
    
    local fishName = (fishInfo and fishInfo.Name) or "Unknown"
    local fishTier = tostring((fishInfo and fishInfo.Tier) or "?")
    local sellPrice = tostring((fishInfo and fishInfo.SellPrice) or "?")
    
    local weightDisplay = "?"
    if weight then
        if type(weight) == "number" then
            weightDisplay = string.format("%.2fkg", weight)
        else
            weightDisplay = tostring(weight) .. "kg"
        end
    end
    
    local fishRarityStr = string.upper(tostring(fishRarity or (fishInfo and fishInfo.Rarity) or "UNKNOWN"))
    local invDisplay = inventoryCount and tostring(inventoryCount) .. "/4500" or "Unknown"
    
    local mutationText = variantName and variantName ~= "" and variantName ~= "0" and variantName or "Unknown Variant"
    
    local message = "```\n"
    message = message .. "💎 SELAMAT! ANDA MENDAPATKAN " .. mutationText .. "! 💎\n\n"
    message = message .. "========================================\n"
    message = message .. "NIKZZ SCRIPT FISH IT\n"
    message = message .. "VARIANT CATCH NOTIFICATION\n"
    message = message .. "========================================\n\n"
    message = message .. "PLAYER INFORMATION\n"
    message = message .. "     NAME: " .. playerName .. "\n"
    if displayName ~= playerName then
        message = message .. "     DISPLAY: " .. displayName .. "\n"
    end
    message = message .. "     ID: " .. userId .. "\n"
    message = message .. "     CAUGHT: " .. caught .. "\n"
    message = message .. "     RAREST: " .. rarest .. "\n\n"
    message = message .. "FISH DETAILS\n"
    message = message .. "     NAME: " .. fishName .. "\n"
    message = message .. "     VARIANT: " .. mutationText .. "\n"
    message = message .. "     RARITY: " .. fishRarityStr .. "\n"
    message = message .. "     TIER: " .. fishTier .. "\n"
    message = message .. "     SIZE: " .. (sizeLabel or "Default") .. "\n"
    message = message .. "     WEIGHT: " .. weightDisplay .. "\n"
    message = message .. "     PRICE: " .. sellPrice .. " COINS\n\n"
    message = message .. "EQUIPMENT\n"
    message = message .. "     ROD: " .. (rodName or "Unknown") .. "\n"
    message = message .. "     INVENTORY: " .. invDisplay .. "\n\n"
    message = message .. "SYSTEM STATS\n"
    message = message .. "     TIME: " .. serverTime .. "\n"
    message = message .. "     DATE: " .. serverDate .. "\n\n"
    message = message .. "DEVELOPER SOCIALS\n"
    message = message .. "     TIKTOK: @nikzzxit\n"
    message = message .. "     INSTAGRAM: @n1kzx.z\n"
    message = message .. "STATUS: VARIANT OBTAINED\n"
    message = message .. "========================================\n```"
    
    return message
end

_G.BuildDisconnectMessage = function(reason)
    local playerName = LocalPlayer.Name or "Unknown"
    local displayName = LocalPlayer.DisplayName or playerName
    local userId = tostring(LocalPlayer.UserId or "Unknown")
    local serverTime = os.date("%H:%M:%S")
    local serverDate = os.date("%Y-%m-%d")
    local caught, rarest = _G.GetPlayerStats()
    
    local message = "```\n⚠️ DISCONNECTED FROM SERVER ⚠️\n\n"
    message = message .. "PLAYER: " .. playerName .. "\nREASON: " .. tostring(reason) .. "\nTIME: " .. serverTime .. "\n```"
    
    return message
end

-- ========== TELEGRAM SENDERS ==========
_G.SendTelegram = function(message)
    if not _G.TelegramConfig.Enabled then return false, "disabled" end
    if not _G.TelegramConfig.ChatID or _G.TelegramConfig.ChatID == "" then return false, "no chat id" end
    
    local url = ("https://api.telegram.org/bot%s/sendMessage"):format(_G.TelegramConfig.BotToken)
    local payload = {
        chat_id = _G.TelegramConfig.ChatID,
        text = message,
        parse_mode = "Markdown"
    }
    
    local req = {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = _G.safeJSONEncode(payload)
    }
    
    local ok, res = _G.pickHTTPRequest(req)
    if not ok then return false, res end
    
    if type(res) == "table" and (res.Success or (res.StatusCode and res.StatusCode == 200)) then
        return true, res
    else
        return false, res
    end
end

_G.SendTelegramPhoto = function(photoUrl, caption)
    if not _G.TelegramConfig.Enabled then return false, "disabled" end
    if not _G.TelegramConfig.ChatID or _G.TelegramConfig.ChatID == "" then return false, "no chat id" end
    if not photoUrl or photoUrl == "" then return false, "no photo" end
    
    local url = ("https://api.telegram.org/bot%s/sendPhoto"):format(_G.TelegramConfig.BotToken)
    local safeCaption = tostring(caption or "")
    
    if #safeCaption > 1000 then
        local payload = { chat_id = _G.TelegramConfig.ChatID, photo = photoUrl }
        local req = { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) }
        local ok, res = _G.pickHTTPRequest(req)
        if not ok then return false, res end
        _G.SendTelegram(safeCaption)
        return true, res
    else
        local payload = {
            chat_id = _G.TelegramConfig.ChatID,
            photo = photoUrl,
            caption = safeCaption,
            parse_mode = "Markdown"
        }
        local req = { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) }
        local ok, res = _G.pickHTTPRequest(req)
        return ok, res
    end
end

_G.ShouldSendByRarity = function(rarity)
    if not _G.TelegramConfig.Enabled then return false end
    if _G.CountSelected() == 0 then return false end
    local key = string.upper(tostring(rarity or "UNKNOWN"))
    return _G.TelegramConfig.SelectedRarities[key] == true
end

_G.ShouldSendByVariant = function(variantId)
    if not _G.TelegramConfig.Enabled then return false end
    if _G.CountSelectedVariants() == 0 then return false end
    
    -- Try both direct ID and string version
    if _G.TelegramConfig.SelectedVariants[variantId] then
        return true
    end
    if _G.TelegramConfig.SelectedVariants[tostring(variantId)] then
        return true
    end
    
    return false
end

-- ========== FISH NOTIFICATION HOOK ==========
_G.SetupFishHook = function()
    if _G.FishHookConnected then
        print("[Telegram] Hook already connected")
        return
    end
    _G.FishHookConnected = true
    
    local REObtainedNewFishNotification = ReplicatedStorage
        .Packages._Index["sleitnick_net@0.2.0"]
        .net["RE/ObtainedNewFishNotification"]
    
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, data)
            if not _G.TelegramConfig.Enabled then return end
            if not itemId or not data then return end
            
            local fishId = itemId
            local weight = data.InventoryItem and data.InventoryItem.Metadata and data.InventoryItem.Metadata.Weight
            local variantId = data.InventoryItem and data.InventoryItem.Metadata and (data.InventoryItem.Metadata.VariantId or data.InventoryItem.Metadata.Variant)
            
            -- AGGRESSIVE VARIANT DETECTION
            print("[Telegram] Fish caught - ID:", fishId, "VariantId:", variantId, "Type:", type(variantId))
            
            local variantName = ""
            if variantId and variantId ~= "" and variantId ~= "0" and variantId ~= 0 then
                variantName = _G.GetVariantName(variantId)
                print("[Telegram] Variant detected:", variantName, "from ID:", variantId)
            end
            
            local itemInfo = _G.GetItemInfo(fishId)
            local rodName = _G.GetValidRodName()
            local sizeLabel = _G.GetFishSizeLabel(itemInfo, weight, data)
            
            local actualRarity = _G.GetFishRarityFromName(itemInfo.Name)
            if actualRarity == "UNKNOWN" then actualRarity = itemInfo.Rarity end
            
            -- Check filters
            local sendByRarity = _G.ShouldSendByRarity(actualRarity)
            local sendByVariant = false
            
            if variantId and variantId ~= "" and variantId ~= "0" and variantId ~= 0 then
                sendByVariant = _G.ShouldSendByVariant(variantId)
                print("[Telegram] Variant filter check:", sendByVariant, "for ID:", variantId)
            end
            
            print("[Telegram] Filter results - Rarity:", sendByRarity, "Variant:", sendByVariant)
            
            if sendByRarity or sendByVariant then
                local caption = nil
                if sendByVariant and variantName ~= "" then
                    caption = _G.BuildVariantMessage(itemInfo, fishId, actualRarity, weight, variantName, sizeLabel, rodName)
                    print("[Telegram] Using VARIANT message format")
                else
                    caption = _G.BuildRarityMessage(itemInfo, fishId, actualRarity, weight, variantName, sizeLabel, rodName)
                    print("[Telegram] Using RARITY message format")
                end
                
                local fishImageUrl = nil
                
                if itemInfo and itemInfo.Icon and type(itemInfo.Icon) == "string" then
                    local id = tostring(itemInfo.Icon):match("(%d+)")
                    if id then
                        fishImageUrl = _G.GetRobloxImage(id)
                    else
                        fishImageUrl = itemInfo.Icon
                    end
                end
                
                if not fishImageUrl and data.InventoryItem and data.InventoryItem.Metadata then
                    local meta = data.InventoryItem.Metadata
                    if meta.AssetId then
                        fishImageUrl = _G.GetRobloxImage(meta.AssetId)
                    end
                end
                
                if not fishImageUrl then
                    pcall(function()
                        for _, mod in pairs(ReplicatedStorage.Items:GetChildren()) do
                            local ok, dat = pcall(require, mod)
                            if ok and dat and dat.Data and dat.Data.Id == fishId then
                                if dat.Data.Icon then
                                    local id = tostring(dat.Data.Icon):match("(%d+)")
                                    if id then 
                                        fishImageUrl = _G.GetRobloxImage(id)
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
                
                if not fishImageUrl then
                    fishImageUrl = _G.GetPlayerAvatarUrl(LocalPlayer.UserId) or ""
                end
                
                spawn(function()
                    local ok, res
                    if fishImageUrl and fishImageUrl ~= "" then
                        ok, res = _G.SendTelegramPhoto(fishImageUrl, caption)
                    else
                        ok, res = _G.SendTelegram(caption)
                    end
                    
                    if ok then
                        if sendByVariant then
                            print("[Telegram] ✅ Variant notification sent:", itemInfo.Name, "(" .. variantName .. ")")
                        else
                            print("[Telegram] ✅ Rarity notification sent:", itemInfo.Name, "(" .. actualRarity .. ")")
                        end
                    else
                        warn("[Telegram] ❌ Failed to send:", res)
                    end
                end)
            else
                print("[Telegram] Skipped - No matching filter")
            end
        end)
        
        print("[Telegram] ✅ Fish hook setup successfully!")
    else
        warn("[Telegram] ❌ ObtainedNewFishNotification not found")
    end
end

print("[TELEGRAM SYSTEM] ✅ Loaded Successfully!")
print("[TELEGRAM SYSTEM] Fish Database:", _G.FishLoadedCount, "items")
print("[TELEGRAM SYSTEM] Variant Database:", _G.VariantLoadedCount, "variants")

-------------------------------------------
----- =======[ HOOK TAB UI ]
-------------------------------------------

HookTab:Section({
    Title = "Telegram Settings",
    TextSize = 20,
    TextXAlignment = "Center",
    Opened = true
})

_G.TelegramToggle = HookTab:Toggle({
    Title = "Enable Telegram Hook",
    Desc = "Send fish notifications to Telegram",
    Value = _G.TelegramConfig.Enabled,
    Callback = function(v)
        _G.TelegramConfig.Enabled = v
        if v then
            NotifySuccess("Telegram", "Notifications enabled!")
            task.wait(1)
            _G.SetupFishHook()
        else
            NotifyWarning("Telegram", "Notifications disabled")
        end
    end
})

myConfig:Register("TelegramEnabled", _G.TelegramToggle)

HookTab:Space()

_G.ChatIDInput = HookTab:Input({
    Title = "Telegram Chat ID",
    Desc = "Enter your Telegram Chat ID",
    Placeholder = "e.g., -1001234567890",
    Value = _G.TelegramConfig.ChatID or "",
    Callback = function(Text)
        _G.TelegramConfig.ChatID = Text
    end
})

myConfig:Register("TelegramChatID", _G.ChatIDInput)

HookTab:Space()

HookTab:Paragraph({
    Title = "ℹ️ Token Info",
    Desc = "Bot token is pre-configured. Enter your Chat ID above.\n\nGet Chat ID: Message @userinfobot on Telegram"
})

HookTab:Space()

HookTab:Section({
    Title = "Filter by Rarity (Max 3)",
    TextSize = 20,
    TextXAlignment = "Center",
    Opened = true
})

_G.RaritiesList = {"SECRET", "MYTHIC", "LEGENDARY", "EPIC", "RARE", "UNCOMMON", "COMMON"}

if not _G.TelegramConfig.SelectedRarities then
    _G.TelegramConfig.SelectedRarities = {}
end

_G.GetDefaultRaritySelections = function()
    local list = {}
    for rarity, selected in pairs(_G.TelegramConfig.SelectedRarities) do
        if selected then
            table.insert(list, rarity)
        end
    end
    return list
end

_G.RarityDropdown = HookTab:Dropdown({
    Title = "Choose Rarities",
    Desc = "Select up to 3 rarities",
    Values = _G.RaritiesList,
    Value = {},
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Default = _G.GetDefaultRaritySelections(),
    Callback = function(selectedList)
        if #selectedList > _G.TelegramConfig.MaxSelection then
            NotifyWarning("⚠️ Max 3 Rarities", "You can only select 3!")
            task.spawn(function()
                task.wait(0.05)
                _G.RarityDropdown:SetValue(_G.GetDefaultRaritySelections())
            end)
            return
        end

        for _, r in ipairs(_G.RaritiesList) do
            _G.TelegramConfig.SelectedRarities[r] = false
        end
        
        for _, r in ipairs(selectedList) do
            _G.TelegramConfig.SelectedRarities[r] = true
        end

        if #selectedList > 0 then
            NotifySuccess("Rarity Updated", "Selected: " .. table.concat(selectedList, ", "))
        end
        
        print("[Telegram] Rarity filter updated:", selectedList)
    end
})

myConfig:Register("RaritySelections", _G.RarityDropdown)

HookTab:Space()

HookTab:Section({
    Title = "Filter by Variant (Max 5)",
    TextSize = 20,
    TextXAlignment = "Center",
    Opened = true
})

_G.VariantNamesList = {}
for vName, vId in pairs(_G.VariantDatabase) do
    table.insert(_G.VariantNamesList, vName)
end
table.sort(_G.VariantNamesList)

if not _G.TelegramConfig.SelectedVariants then
    _G.TelegramConfig.SelectedVariants = {}
end

_G.GetDefaultVariantSelections = function()
    local list = {}
    for variantId, selected in pairs(_G.TelegramConfig.SelectedVariants) do
        if selected then
            local vName = _G.VariantIdToName[variantId] or _G.VariantIdToName[tostring(variantId)]
            if vName then
                table.insert(list, vName)
            end
        end
    end
    return list
end

_G.VariantDropdown = HookTab:Dropdown({
    Title = "Choose Variants",
    Desc = "Select up to 5 variants",
    Values = _G.VariantNamesList,
    Value = {},
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Default = _G.GetDefaultVariantSelections(),
    Callback = function(selectedList)
        if #selectedList > _G.TelegramConfig.MaxVariantSelection then
            NotifyWarning("⚠️ Max 5 Variants", "You can only select 5!")
            task.spawn(function()
                task.wait(0.05)
                _G.VariantDropdown:SetValue(_G.GetDefaultVariantSelections())
            end)
            return
        end

        _G.TelegramConfig.SelectedVariants = {}
        
        for _, vName in ipairs(selectedList) do
            local vId = _G.VariantDatabase[vName]
            if vId then
                _G.TelegramConfig.SelectedVariants[vId] = true
                _G.TelegramConfig.SelectedVariants[tostring(vId)] = true
                print("[Telegram] Selected variant:", vName, "ID:", vId)
            end
        end

        if #selectedList > 0 then
            NotifySuccess("Variant Updated", "Selected: " .. table.concat(selectedList, ", "))
        end
        
        print("[Telegram] Variant filter updated:", selectedList)
    end
})

myConfig:Register("VariantSelections", _G.VariantDropdown)

HookTab:Space()

HookTab:Section({
    Title = "Test Notifications",
    TextSize = 20,
    TextXAlignment = "Center",
    Opened = true
})

HookTab:Button({
    Title = "Test SECRET (Rarity)",
    Desc = "Send test SECRET notification",
    Justify = "Center",
    Icon = "send",
    Callback = function()
        if _G.TelegramConfig.ChatID == "" then
            NotifyError("❌ Error", "Enter Chat ID first!")
            return
        end
        
        local secretItems = {}
        for id, fishData in pairs(_G.FishDataById) do
            if fishData.Tier == 7 then
                table.insert(secretItems, {Id = id, Data = fishData})
            end
        end
        
        if #secretItems == 0 then
            NotifyError("❌ No Data", "No SECRET items")
            return
        end
        
        local chosen = secretItems[math.random(1, #secretItems)]
        local weight = math.random(2, 6) + math.random()
        local itemInfo = _G.GetItemInfo(chosen.Id)
        local rodName = _G.GetValidRodName()
        local sizeLabel = "Big"
        
        local msg = _G.BuildRarityMessage(itemInfo, chosen.Id, "SECRET", weight, "Shiny", sizeLabel, rodName)
        local success, result = _G.SendTelegram(msg)
        
        if success then
            NotifySuccess("✅ Test Sent", "SECRET notification sent!")
        else
            NotifyError("❌ Failed", "Failed to send")
        end
    end
})

HookTab:Space()

HookTab:Button({
    Title = "Test Variant",
    Desc = "Send test variant notification",
    Justify = "Center",
    Icon = "send",
    Callback = function()
        if _G.TelegramConfig.ChatID == "" then
            NotifyError("❌ Error", "Enter Chat ID first!")
            return
        end
        
        if #_G.VariantNamesList == 0 then
            NotifyError("❌ No Data", "No variants found")
            return
        end
        
        local randomVariant = _G.VariantNamesList[math.random(1, #_G.VariantNamesList)]
        local randomFishId = math.random(1, 100)
        local itemInfo = _G.GetItemInfo(randomFishId)
        local weight = math.random(1, 5) + math.random()
        local rodName = _G.GetValidRodName()
        local sizeLabel = "Default"
        
        local msg = _G.BuildVariantMessage(itemInfo, randomFishId, itemInfo.Rarity, weight, randomVariant, sizeLabel, rodName)
        local success, result = _G.SendTelegram(msg)
        
        if success then
            NotifySuccess("✅ Test Sent", "Variant notification sent!")
        else
            NotifyError("❌ Failed", "Failed to send")
        end
    end
})

HookTab:Space()

HookTab:Button({
    Title = "Debug Status",
    Desc = "Check Telegram settings & database",
    Justify = "Center",
    Icon = "bug",
    Callback = function()
        local selectedRarity = {}
        for rarity, isSelected in pairs(_G.TelegramConfig.SelectedRarities) do
            if isSelected then table.insert(selectedRarity, rarity) end
        end
        
        local selectedVariant = {}
        for varId, isSelected in pairs(_G.TelegramConfig.SelectedVariants) do
            if isSelected then
                local vName = _G.VariantIdToName[varId] or _G.VariantIdToName[tostring(varId)] or tostring(varId)
                table.insert(selectedVariant, vName)
            end
        end
        
        local status = string.format(
            "Enabled: %s\nChat ID: %s\nRarities: %s\nVariants: %s\nFish DB: %d\nVariant DB: %d",
            tostring(_G.TelegramConfig.Enabled),
            _G.TelegramConfig.ChatID ~= "" and "Set" or "Not set",
            #selectedRarity > 0 and table.concat(selectedRarity, ", ") or "None",
            #selectedVariant > 0 and table.concat(selectedVariant, ", ") or "None",
            _G.FishLoadedCount or 0,
            _G.VariantLoadedCount or 0
        )
        
        NotifyInfo("📋 Telegram Status", status)
        print("[Telegram DEBUG]")
        print("Enabled:", _G.TelegramConfig.Enabled)
        print("Chat ID:", _G.TelegramConfig.ChatID)
        print("Selected Rarities:", selectedRarity)
        print("Selected Variants:", selectedVariant)
        print("Fish Database:", _G.FishLoadedCount)
        print("Variant Database:", _G.VariantLoadedCount)
        print("Variant Mappings:")
        for vName, vId in pairs(_G.VariantDatabase) do
            print("  ", vName, "->", vId)
        end
    end
})

do
    -- State management di _G tanpa merusak fungsi
    _G.BlatantV1Core = _G.BlatantV1Core or {
        blatantInstantState = false,
        fishDetected = false,
        completeDelay = 3.055,
        cancelDelay = 0.3,
        loopInterval = 1.715,
        blatantLoopThread = nil
    }
    
    local S = _G.BlatantV1Core
    
    -- Remote path
    local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
    
    -- Function GetRemote (ringan)
    local function GetRemote(remotePath, name, timeout)
        local currentInstance = ReplicatedStorage
        for _, childName in ipairs(remotePath) do
            currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
            if not currentInstance then return nil end
        end
        return currentInstance:FindFirstChild(name)
    end
    
    -- Load remotes
    local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
    local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
    local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
    local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
    local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
    local RE_ReplicateTextEffect = GetRemote(RPath, "RE/ReplicateTextEffect")
    
    -- Fish Detection hook
    if RE_ReplicateTextEffect then
        RE_ReplicateTextEffect.OnClientEvent:Connect(function(data)
            if not S.blatantInstantState then return end
            if data and data.TextData then
                if data.TextData.Text == "!" and data.TextData.EffectType == "Exclaim" then
                    S.fishDetected = true
                end
            end
        end)
    end
    
    -- Delay Notification 30 detik hook
    local RE_ObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
    
    if RE_ObtainedNewFishNotification then
        local existingConnections = {}
        for _, connection in pairs(getconnections(RE_ObtainedNewFishNotification.OnClientEvent)) do
            table.insert(existingConnections, connection.Function)
        end
        
        local function hookNotification(...)
            local args = {...}
            if #args >= 3 and type(args[3]) == "table" then
                args[3].CustomDuration = 7
            end
            
            for _, func in ipairs(existingConnections) do
                pcall(func, ...)
            end
        end
        
        for _, connection in pairs(getconnections(RE_ObtainedNewFishNotification.OnClientEvent)) do
            connection:Disconnect()
        end
        
        RE_ObtainedNewFishNotification.OnClientEvent:Connect(hookNotification)
    end
    
    -- Check remotes
    local function checkFishingRemotes(silent)
        local remotes = {RE_EquipToolFromHotbar, RF_ChargeFishingRod, RF_RequestFishingMinigameStarted,
                        RE_FishingCompleted, RF_CancelFishingInputs}
        for _, remote in ipairs(remotes) do
            if not remote then
                if not silent then
                    WindUI:Notify({Title = "Remote Error!", Content = "Remote Fishing tidak ditemukan!", Duration = 5, Icon = "x"})
                end
                return false
            end
        end
        return true
    end
    
    -- Core fishing function (tidak diubah)
    local function runBlatantInstant()
        if not S.blatantInstantState then return end
        if not checkFishingRemotes(true) then 
            S.blatantInstantState = false 
            return 
        end

        task.spawn(function()
            S.fishDetected = false
            local startTime = os.clock()
            
            local timestamp = os.time() + os.clock()
            pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
            pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) end)
            
            local maxWait = S.completeDelay
            while not S.fishDetected and (os.clock() - startTime) < maxWait and S.blatantInstantState do
                task.wait(0.01)
            end
            
            if S.fishDetected then
                local elapsed = os.clock() - startTime
                if elapsed < 0.1 then task.wait(0.1 - elapsed) end
            end
            
            pcall(function() RE_FishingCompleted:FireServer() end)
            task.wait(S.cancelDelay)
            pcall(function() RF_CancelFishingInputs:InvokeServer() end)
        end)
    end
    
    -- Export fungsi yang diperlukan ke _G untuk akses luar
    _G.BlatantV1 = {
        toggleFishing = function(state)
            if not checkFishingRemotes() then return end
            S.blatantInstantState = state
            
            if state then
                pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                task.wait(0.1)
                
                S.blatantLoopThread = task.spawn(function()
                    while S.blatantInstantState do
                        runBlatantInstant()
                        task.wait(S.loopInterval)
                    end
                end)
                
                if WindUI then
                    WindUI:Notify({Title = "Blatant Fish ON", Content = "Ultra speed detection active!", Duration = 3, Icon = "zap"})
                end
            else
                if S.blatantLoopThread then 
                    task.cancel(S.blantantLoopThread) 
                    S.blatantLoopThread = nil 
                end
                if WindUI then
                    WindUI:Notify({Title = "Blatant Fish OFF", Duration = 3, Icon = "x"})
                end
            end
        end,
        
        setLoopInterval = function(value)
            local num = tonumber(value)
            if num and num >= 0.5 then S.loopInterval = num end
        end,
        
        setCompleteDelay = function(value)
            local num = tonumber(value)
            if num and num >= 0.5 then S.completeDelay = num end
        end,
        
        setCancelDelay = function(value)
            local num = tonumber(value)
            if num and num >= 0.5 then S.cancelDelay = num end
        end,
        
        saveConfig = function()
            local configData = {
                LoopInterval = S.loopInterval,
                CompleteDelay = S.completeDelay,
                CancelDelay = S.cancelDelay
            }
            
            local success, jsonData = pcall(game.HttpService.JSONEncode, game.HttpService, configData)
            if success and jsonData then
                writefile("Blatant_config.json", jsonData)
                if WindUI then
                    WindUI:Notify({Title = "Configuration Saved", Content = "Blatant settings saved!", Duration = 3, Icon = "save"})
                end
            end
        end,
        
        loadConfig = function()
            if isfile("Blatant_config.json") then
                local success, jsonData = pcall(readfile, "Blatant_config.json")
                if success and jsonData then
                    local success2, configData = pcall(game.HttpService.JSONDecode, game.HttpService, jsonData)
                    if success2 and configData then
                        S.loopInterval = configData.LoopInterval or 1.715
                        S.completeDelay = configData.CompleteDelay or 3.055
                        S.cancelDelay = configData.CancelDelay or 0.3
                        
                        if WindUI then
                            WindUI:Notify({Title = "Configuration Loaded", Content = "Blatant settings loaded!", Duration = 3, Icon = "download"})
                        end
                        return true
                    end
                end
            end
            return false
        end
    }
    
    -- Setup UI jika BlatantSettings ada
    if BlatantSettings then
        local BlatantV1Section = BlatantSettings:Section({
            Title = "Blatant Fishing V1",
            TextSize = 22,
            TextXAlignment = "Center",
            Opened = false
        })
        
        local LoopIntervalInput = BlatantV1Section:Input({
            Title = "Spam Reel", 
            Value = tostring(S.loopInterval), 
            Icon = "fast-forward", 
            Type = "Input", 
            Placeholder = "1.715", 
            Callback = function(input)
                _G.BlatantV1.setLoopInterval(input)
            end
        })
        
        local CompleteDelayInput = BlatantV1Section:Input({
            Title = "Complete Delay", 
            Value = tostring(S.completeDelay), 
            Icon = "loader", 
            Type = "Input", 
            Placeholder = "3.055", 
            Callback = function(input)
                _G.BlatantV1.setCompleteDelay(input)
            end
        })
        
        local CancelDelayInput = BlatantV1Section:Input({
            Title = "Cancel Delay", 
            Value = tostring(S.cancelDelay), 
            Icon = "loader", 
            Type = "Input", 
            Placeholder = "0.3", 
            Callback = function(input)
                local num = tonumber(input)
                if num and num >= 0.1 then S.cancelDelay = num end
            end
        })
        
        BlatantV1Section:Toggle({
            Title = "Instant Fishing (Blatant)",
            Value = false,
            Callback = _G.BlatantV1.toggleFishing
        })
        
        BlatantV1Section:Button({
            Title = "Save Blatant Config",
            Desc = "Save current Blatant settings",
            Callback = _G.BlatantV1.saveConfig
        })
        
        BlatantV1Section:Button({
            Title = "Load Blatant Config",
            Desc = "Load saved Blatant settings",
            Callback = function()
                if _G.BlatantV1.loadConfig() then
                    LoopIntervalInput:Set(tostring(S.loopInterval))
                    CompleteDelayInput:Set(tostring(S.completeDelay))
                    CancelDelayInput:Set(tostring(S.cancelDelay))
                end
            end
        })
        
        -- Auto load config
        task.spawn(_G.BlatantV1.loadConfig)
    end
end

_X5instant = BlatantSettings:Section({
    Title = "Instant X5 Fishing",
    TextSize = 22,
    TextXAlignment = "Center",
    Opened = false
})

do
    local _G = getfenv(0)
    
    -- Minimal state management
    _G.InstantFishX5State = _G.InstantFishX5State or {
        AutoFish = false,
        Instant_ChargeDelay = 0.01,
        Instant_SpamCount = 10,
        Instant_WorkerCount = 3,
        Instant_StartDelay = 1.20,
        Instant_CatchTimeout = 0.25,
        Instant_CycleDelay = 0.10,
        Instant_ResetCount = 15,
        Instant_ResetPause = 0.1
    }
    
    local S = _G.InstantFishX5State
    
    -- System Save/Load (Lightweight)
    local function saveConfig()
        local success, jsonData = pcall(game.HttpService.JSONEncode, game.HttpService, {
            Instant_ChargeDelay = S.Instant_ChargeDelay,
            Instant_SpamCount = S.Instant_SpamCount,
            Instant_WorkerCount = S.Instant_WorkerCount,
            Instant_StartDelay = S.Instant_StartDelay,
            Instant_CatchTimeout = S.Instant_CatchTimeout,
            Instant_CycleDelay = S.Instant_CycleDelay,
            Instant_ResetCount = S.Instant_ResetCount,
            Instant_ResetPause = S.Instant_ResetPause
        })
        
        if success and jsonData then
            writefile("InstantFishX5_config.json", jsonData)
            WindUI:Notify({Title = "Saved", Content = "Settings saved!", Duration = 3, Icon = "save"})
        end
    end
    
    local function loadConfig()
        if isfile("InstantFishX5_config.json") then
            local success, jsonData = pcall(readfile, "InstantFishX5_config.json")
            if success and jsonData then
                local success2, data = pcall(game.HttpService.JSONDecode, game.HttpService, jsonData)
                if success2 and data then
                    for k, v in pairs(data) do if S[k] ~= nil then S[k] = v end end
                    WindUI:Notify({Title = "Loaded", Content = "Settings loaded!", Duration = 3, Icon = "download"})
                    return true
                end
            end
        end
        return false
    end
    
    -- Load Modules Once
    local M = {}
    for _, name in ipairs({"Replion", "ItemUtility", "FishingController", "EquipToolEvent", "ChargeRodFunc", 
                          "StartMinigameFunc", "CompleteFishingEvent"}) do
        M[name] = ModulesTable[name]
    end
    
    local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild(
        "sleitnick_net@0.2.0"):WaitForChild("net", 20)
    
    M.CancelFishing = NetFolder["RF/CancelFishingInputs"]
    M.ReplicateTextEffect = NetFolder["RE/ReplicateTextEffect"]
    M.FishingStopped = NetFolder["RE/FishingStopped"]
    M.UnequipTool = NetFolder["RE/UnequipToolFromHotbar"]
    
    -- Lightweight Management
    local fishingThreads = {}
    local lastEventTime = tick()
    local fishCaughtEvent = Instance.new("BindableEvent")
    
    -- Fish Detection
    if M.ReplicateTextEffect then
        M.ReplicateTextEffect.OnClientEvent:Connect(function(data)
            if not S.AutoFish then return end
            local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if data and data.TextData and data.TextData.EffectType == "Exclaim" and myHead and data.Container == myHead then
                lastEventTime = tick()
                fishCaughtEvent:Fire("caught")
            end
        end)
    end
    
    -- Anti-Stuck
    task.spawn(function()
        while task.wait(1) do
            if S.AutoFish and tick() - lastEventTime > 10 then
                pcall(M.FishingController.RequestClientStopFishing, M.FishingController, true)
                lastEventTime = tick()
            end
        end
    end)
    
    local function stopFishing()
        S.AutoFish = false
        for _, t in ipairs(fishingThreads) do if typeof(t) == "thread" then task.cancel(t) end end
        fishingThreads = {}
        pcall(function() M.FishingController:RequestClientStopFishing(true) end)
    end
    
    -- Core Instant Fish X5 Method
    local function startInstantFish()
        if not (M.ChargeRodFunc and M.StartMinigameFunc and M.CompleteFishingEvent) then return end
        
        S.AutoFish = true
        local chargeCount = 0
        local isResetting = false
        local counterLock = false
        
        local function worker()
            while S.AutoFish and LocalPlayer do
                local resetTarget = S.Instant_ResetCount
                if isResetting or chargeCount >= resetTarget then break end
                
                pcall(function()
                    if not S.AutoFish or isResetting or chargeCount >= resetTarget then return end
                    
                    -- Counter
                    local lockTimeout = 0
                    while counterLock do 
                        task.wait(0.01)
                        lockTimeout = lockTimeout + 0.01
                        if lockTimeout > 5 then 
                            counterLock = false
                            break 
                        end
                    end
                    
                    counterLock = true
                    if chargeCount < resetTarget then chargeCount = chargeCount + 1 end
                    counterLock = false
                    
                    -- 1. Charge
                    M.ChargeRodFunc:InvokeServer(workspace:GetServerTimeNow())
                    task.wait(S.Instant_ChargeDelay)
                    
                    -- 2. Start Minigame
                    M.StartMinigameFunc:InvokeServer(-1.25, 1, workspace:GetServerTimeNow())
                    task.wait(S.Instant_StartDelay)
                    
                    -- 3. Spam Complete
                    for _ = 1, S.Instant_SpamCount do
                        if not S.AutoFish or isResetting then break end
                        M.CompleteFishingEvent:FireServer()
                        task.wait(0.01)
                    end
                    
                    -- 4. Wait for Signal
                    local signalReceived = false
                    local conn = fishCaughtEvent.Event:Connect(function() signalReceived = true end)
                    
                    local timeout = task.delay(S.Instant_CatchTimeout, function()
                        if conn and conn.Connected then conn:Disconnect() end
                    end)
                    
                    M.CancelFishing:InvokeServer()
                    
                    while not signalReceived and task.wait() do
                        if not S.AutoFish or isResetting then break end
                        if timeout and coroutine.status(timeout) == "dead" then break end
                    end
                    
                    if conn and conn.Connected then conn:Disconnect() end
                    M.CancelFishing:InvokeServer()
                    pcall(M.FishingController.RequestClientStopFishing, M.FishingController, true)
                end)
                
                if not S.AutoFish then break end
                task.wait(S.Instant_CycleDelay)
            end
        end
        
        -- Worker Manager
        local mainThread = task.spawn(function()
            while S.AutoFish do
                local resetTarget = S.Instant_ResetCount
                local pauseTime = S.Instant_ResetPause
                
                chargeCount = 0
                isResetting = false
                local workers = {}
                
                for i = 1, S.Instant_WorkerCount do
                    if not S.AutoFish then break end
                    local t = task.spawn(worker)
                    table.insert(workers, t)
                    table.insert(fishingThreads, t)
                end
                
                while S.AutoFish and chargeCount < resetTarget do task.wait() end
                
                isResetting = true
                if S.AutoFish then
                    for _, t in ipairs(workers) do task.cancel(t) end
                    task.wait(pauseTime)
                end
            end
            stopFishing()
        end)
        
        table.insert(fishingThreads, mainThread)
    end
    
    local function toggleFishing(enable)
        if enable then
            stopFishing()
            S.AutoFish = true
            pcall(M.EquipToolEvent.FireServer, M.EquipToolEvent, 1)
            task.wait(0.2)
            startInstantFish()
        else
            stopFishing()
        end
    end
    
    -- UI Setup
    if BlatantSettings then
        
        local startDelayInput = _X5instant:Input({
            Title = "Start Delay",
            Desc = "Delay before starting (Default: 1.20)",
            Value = tostring(S.Instant_StartDelay),
            Placeholder = "Input number...",
            Callback = function(v) local n = tonumber(v) if n then S.Instant_StartDelay = n end end
        })
        
        local catchTimeoutInput = _X5instant:Input({
            Title = "Spam Finish",
            Desc = "Timeout for catching fish (Default: 0.25)",
            Value = tostring(S.Instant_CatchTimeout),
            Placeholder = "Input number...",
            Callback = function(v) local n = tonumber(v) if n then S.Instant_CatchTimeout = n end end
        })
        
        local cycleDelayInput = _X5instant:Input({
            Title = "Delay Spam",
            Desc = "Delay between cycles (Default: 0.10)",
            Value = tostring(S.Instant_CycleDelay),
            Placeholder = "Input number...",
            Callback = function(v) local n = tonumber(v) if n then S.Instant_CycleDelay = n end end
        })
        
        _X5instant:Button({
            Title = "Save Configuration",
            Desc = "Save current settings",
            Callback = saveConfig
        })
        
        _X5instant:Button({
            Title = "Load Configuration",
            Desc = "Load saved settings",
            Callback = function()
                if loadConfig() then
                    startDelayInput:Set(tostring(S.Instant_StartDelay))
                    catchTimeoutInput:Set(tostring(S.Instant_CatchTimeout))
                    cycleDelayInput:Set(tostring(S.Instant_CycleDelay))
                end
            end
        })
        
        _X5instant:Section({Title = "UltraFish Start", TextSize = 20, TextXAlignment = "Center", Opened = true})
        
        _X5instant:Toggle({
            Title = "Instant Fish X5",
            Desc = "Enable Instant Fish X5 auto fishing",
            Value = false,
            Callback = toggleFishing
        })
        
        task.spawn(loadConfig)
    end
end

