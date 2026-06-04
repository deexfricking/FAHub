if _G.FAHubLoaded then error("FA Hub: Already Loaded!") end
_G.FAHubLoaded = true

-- ============================================================
--  SERVICES
-- ============================================================
local Player            = game.Players.LocalPlayer
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local CoreGui           = game:GetService("CoreGui")

-- ============================================================
--  CHARACTER
-- ============================================================
local Character        = Player.Character or Player.CharacterAdded:Wait()
local Humanoid         = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================================
--  REMOTES
-- ============================================================
local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local Modules  = ReplicatedStorage:WaitForChild("Modules")
local Net      = Modules:WaitForChild("Net")
local CommF_   = Remotes:WaitForChild("CommF_")

-- ============================================================
--  CONNECTION MANAGEMENT
-- ============================================================
local Connections = {}
local function AddConnection(conn)
    table.insert(Connections, conn)
    return conn
end
local function DisconnectAll()
    for _, conn in ipairs(Connections) do
        if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
    end
    table.clear(Connections)
end

-- ============================================================
--  STATE
-- ============================================================
local autoAttack       = false
local autofarm         = false
local autoRaid         = false
local selectedRaid     = "Flame"
local chestFarmEnabled = false
local autoStats        = false
local infJumpEnabled   = false
local holding          = false
local isBuyingChip     = false
local isStartingRaid   = false
local selectedWeapon   = "Melee"
local selectedStat     = "Melee"
local addAmount        = 1
local SetWalkSpeed     = Humanoid.WalkSpeed
local questInfo        = nil
local lastEquippedType = nil
local UIHotkey         = Enum.KeyCode.RightControl
local ActiveTween      = nil

local autoBossFarm     = false
local farmAllBosses    = false
local selectedBoss     = "None"
local autoFruitRoll    = false
local autoStoreFruit   = false

local Settings = { Distance = 50, AttackDelay = 0 }

-- ============================================================
--  ORBIT STATE
-- ============================================================
local orbitRadius   = 10
local orbitHeight   = 15
local snapTime      = 1.5
local snapIndex     = 1
local lastSwitch    = os.clock()
local orbitDistance = 15
local snapOffsets   = {
    Vector3.new(orbitRadius, orbitHeight, 0),
    Vector3.new(0, orbitHeight, orbitRadius),
    Vector3.new(-orbitRadius, orbitHeight, 0),
    Vector3.new(0, orbitHeight, -orbitRadius),
}

-- ============================================================
--  BOSSES
-- ============================================================
local Bosses = {
    [27539155] = { -- First Sea
        {Name = "The Gorilla King", Island = "Jungle", Level = 20, Args = {"StartQuest", "JungleQuest", 3}},
        {Name = "Bobby", Island = "Pirate", Level = 55, Args = {"StartQuest", "BuggyQuest1", 3}},
        {Name = "The Saw", Island = "Pirate", Level = 100, Args = {"StartQuest", "SharkQuest", 1}},
        {Name = "Yeti", Island = "Ice", Level = 110, Args = {"StartQuest", "SnowQuest", 3}},
        {Name = "Vice Admiral", Island = "MarineBase", Level = 130, Args = {"StartQuest", "MarineQuest2", 2}},
        {Name = "Warden", Island = "Prison", Level = 220, Args = {"StartQuest", "WardenQuest", 1}},
        {Name = "Chief Warden", Island = "Prison", Level = 230, Args = {"StartQuest", "WardenQuest", 2}},
        {Name = "Swan", Island = "Prison", Level = 240, Args = {"StartQuest", "WardenQuest", 3}},
        {Name = "Magma Admiral", Island = "Magma", Level = 350, Args = {"StartQuest", "MagmaQuest", 3}},
        {Name = "Fishman Lord", Island = "Fishmen", Level = 425, Args = {"StartQuest", "FishmanQuest", 3}},
        {Name = "Wysper", Island = "SkyArea1", Level = 500, Args = {"StartQuest", "SkyExp1Quest", 3}},
        {Name = "Thunder God", Island = "SkyArea2", Level = 575, Args = {"StartQuest", "SkyExp2Quest", 3}},
        {Name = "Cyborg", Island = "Fountain", Level = 675, Args = {"StartQuest", "FountainQuest", 3}},
    },
    [4442272183] = { -- Second Sea
        {Name = "Diamond", Island = "Kingdom of Rose", Level = 750, Args = {"StartQuest", "Area1Quest", 3}},
        {Name = "Jeremy", Island = "Kingdom of Rose", Level = 850, Args = {"StartQuest", "Area2Quest", 3}},
        {Name = "Fajita", Island = "Green Bit", Level = 925, Args = {"StartQuest", "MarineQuest3", 3}},
        {Name = "Don Swan", Island = "Mansion", Level = 1000, Args = {"StartQuest", "SwanQuest", 1}},
        {Name = "Smoke Admiral", Island = "Hot and Cold", Level = 1150, Args = {"StartQuest", "IceSideQuest", 3}},
        {Name = "Tide Keeper", Island = "Forgotten Island", Level = 1475, Args = {"StartQuest", "ForgottenQuest", 3}},
    },
    [7449925010] = { -- Third Sea
        {Name = "Stone", Island = "Port Town", Level = 1550, Args = {"StartQuest", "PiratePortQuest", 3}},
        {Name = "Island Empress", Island = "Hydra Island", Level = 1675, Args = {"StartQuest", "VenomCrewQuest", 3}},
        {Name = "Kilo Admiral", Island = "Great Tree", Level = 1750, Args = {"StartQuest", "MarineTreeIsland", 3}},
        {Name = "Captain Elephant", Island = "Floating Turtle", Level = 1875, Args = {"StartQuest", "DeepForestIsland", 3}},
        {Name = "Beautiful Pirate", Island = "Floating Turtle", Level = 1950, Args = {"StartQuest", "DeepForestIsland2", 3}},
        {Name = "Cake Queen", Island = "Sea of Treats", Level = 2175, Args = {"StartQuest", "IceCreamIslandQuest", 3}},
    }
}

-- ============================================================
--  CHARACTER ADDED
-- ============================================================
Player.CharacterAdded:Connect(function(c)
    Character        = c
    Humanoid         = c:WaitForChild("Humanoid")
    HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
    local hl = Instance.new("Highlight")
    hl.Parent    = Character
    hl.FillColor = Color3.fromRGB(99, 202, 183)
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
    pcall(function() CommF_:InvokeServer("Buso") end)
end)

-- ============================================================
--  QUESTS
-- ============================================================
local Quests = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/CFR-Executor/resources/refs/heads/main/bfquestdumpfull"
))()

local islandNames = {
    BanditQuest1   = "Windmill",  MarineQuest    = "MarineStart",
    JungleQuest    = "Jungle",    BuggyQuest1    = "Pirate",
    BuggyQuest2    = "Pirate",    DesertQuest    = "Desert",
    SnowQuest      = "Ice",       MarineQuest2   = "MarineBase",
    SkyQuest       = "Sky",       SkyQuest2      = "Sky",
    PrisonerQuest  = "Prison",    ImpelQuest     = "Prison",
    ColosseumQuest = "Colosseum", MagmaQuest     = "Magma",
    FishmanQuest   = "Fishmen",   SkyExp1Quest   = "SkyArea1",
    SkyExp2Quest   = "SkyArea2",  FountainQuest  = "Fountain",
}

-- ============================================================
--  HELPERS
-- ============================================================
local function isOnIsland(islandName)
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild(islandName)
    if not island then return false end
    for _, part in ipairs(island:GetDescendants()) do
        if part:IsA("BasePart") then
            local rel  = part.CFrame:PointToObjectSpace(HumanoidRootPart.Position)
            local half = part.Size / 2
            if math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z then
                if rel.Y >= -50 and rel.Y <= half.Y + 50 then return true end
            end
        end
    end
    return false
end

local function moveTo(position)
    if ActiveTween then 
        ActiveTween:Cancel() 
        ActiveTween = nil
    end
    local mag  = (HumanoidRootPart.Position - position).Magnitude
    local time = math.max(mag / 250, 0.05) -- Reduced speed for security
    ActiveTween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(position) }
    )
    ActiveTween:Play()
    return ActiveTween
end

local function getBossSpawn(boss)
    if not boss or not boss.Island then return nil end
    local clean = boss.Name:gsub("^The ", ""):gsub(" Admiral$", ""):lower()
    
    -- 1. Check World Origin
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    local spawns = origin and origin:FindFirstChild("EnemySpawns")
    if spawns then
        for _, s in ipairs(spawns:GetChildren()) do
            if s.Name:lower():find(clean, 1, true) then return s.Position end
        end
    end
    
    -- 2. Check for Quest NPCs or Island Center
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild(boss.Island)
    if island then
        for _, obj in ipairs(island:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Quest") or obj.Name:find("Giver")) then
                return obj:GetPivot().Position
            end
        end
        return island:GetPivot().Position
    end
    
    return nil
end

local function getBossTimer(bossName)
    local clean = bossName:gsub("^The ", ""):gsub(" Admiral$", ""):lower()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BillboardGui") and v.Enabled then
            local textLabel = v:FindFirstChildOfClass("TextLabel")
            if textLabel and (textLabel.Text:find("Respawns in") or textLabel.Text:find("Spawn in")) then
                local parentName = v.Parent.Name:lower()
                if parentName:find(clean, 1, true) or textLabel.Text:lower():find(clean, 1, true) then
                    return textLabel.Text
                end
            end
        end
    end
    return nil
end

local lastGlobalScan = 0
local function findBoss(name)
    if not name or name == "None" then return nil end
    local search = name:gsub("^The ", ""):gsub(" Admiral$", ""):lower()
    
    -- Optimized but thorough Humanoid scan
    -- We scan Enemies, then NPCs, then global descendants (throttled)
    local priorityFolders = {Workspace:FindFirstChild("Enemies"), Workspace:FindFirstChild("NPCs")}
    
    for _, folder in ipairs(priorityFolders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local modelName = obj.Name:lower()
                    local dispName = hum.DisplayName:lower()
                    if modelName:find(search, 1, true) or dispName:find(search, 1, true) then
                        return obj
                    end
                end
            end
        end
    end

    -- Global fallback: Search all humanoids
    for _, hum in ipairs(Workspace:GetDescendants()) do
        if hum:IsA("Humanoid") and hum.Health > 0 then
            local model = hum.Parent
            if model and model:IsA("Model") and model ~= Player.Character then
                local modelName = model.Name:lower()
                local dispName = hum.DisplayName:lower()
                if modelName:find(search, 1, true) or dispName:find(search, 1, true) then
                    return model
                end
            end
        end
    end
    
    return nil
end

local function loadEnemy(enemyName)
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    if not origin then return nil end
    local spawns = origin:FindFirstChild("EnemySpawns")
    if not spawns then return nil end
    for _, spawn in ipairs(spawns:GetChildren()) do
        local clean = spawn.Name:gsub("%[Lv%.%s*%d+%]%s*", ""):gsub("%s+$", "")
        if clean == enemyName then
            moveTo(spawn.Position + Vector3.new(0, 20, 0))
            return spawn
        end
    end
end

local function teleportToIsland(island)
    -- Sea 3 Portals
    local sea3Portals = {
        ["Hydra Island"] = true, ["Floating Turtle"] = true, 
        ["Castle on the Sea"] = true, ["Tiki Outpost"] = true,
        ["Port Town"] = true, ["Haunted Castle"] = true
    }
    
    if sea3Portals[island] then
        local targetLink = (island == "Floating Turtle") and "Mansion" or "Town"
        pcall(function() CommF_:InvokeServer("TPToLink", island, targetLink) end)
        task.wait(1.5)
        return nil
    end

    local m = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild(island)
    if not m then return nil end

    if island == "Fishmen" or island == "Fishman" then
        return moveTo(workspace.Map.TeleportSpawn.EntrancePoint.Position)
    elseif island == "SkyArea1" and workspace.Map:FindFirstChild("SkyArea2") then
        return moveTo(workspace.Map.SkyArea2.PathwayHouse.EntrancePoint.Position)
    elseif island == "SkyArea2" and workspace.Map:FindFirstChild("SkyArea1") then
        return moveTo(workspace.Map.SkyArea1.PathwayTemple.ExitPoint.Position)
    else
        return moveTo(m:GetPivot().Position + Vector3.new(0, 50, 0))
    end
end

local function getQuest(force)
    local lvlObj = Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Level")
    if not lvlObj then return nil end
    local level = lvlObj.Value

    local bestQuest, bestIsland
    for islandKey, questList in pairs(Quests) do
        for _, q in ipairs(questList) do
            if level >= q.LevelReq then
                if not bestQuest or q.LevelReq > bestQuest.LevelReq then
                    bestQuest  = q
                    bestIsland = islandKey
                end
            end
        end
    end
    if not bestQuest then return nil end

    local questFrame = Player.PlayerGui:WaitForChild("Main"):WaitForChild("Quest")
    local hasQuest   = questFrame.Visible
    if force or not hasQuest then
        pcall(function() CommF_:InvokeServer(unpack(bestQuest.Args)) end)
    end

    local enemyName
    if hasQuest then
        local title = questFrame.Container.QuestTitle:FindFirstChild("Title")
        if title then
            enemyName = title.Text:match("Defeat%s+%d+%s+(.+)%s+%(%d+/%d+%)")
        end
    end
    if not enemyName and bestQuest.Task then
        for name in pairs(bestQuest.Task) do enemyName = name; break end
    end

    local island = islandNames[bestIsland] or bestIsland
    if not isOnIsland(island) then
        local m = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild(island)
        if m then teleportToIsland(island) end
    end
    if enemyName then loadEnemy(enemyName) end

    return { quest = bestQuest, enemy = enemyName, island = island,
             levelReq = bestQuest.LevelReq, args = bestQuest.Args }
end

-- ============================================================
--  FRUIT HELPERS
-- ============================================================
local fruitPrices = {
    ["Rocket"]=5000,["Spin"]=7500,["Chop"]=30000,["Spring"]=60000,
    ["Bomb"]=80000,["Smoke"]=100000,["Spike"]=180000,["Flame"]=250000,
    ["Falcon"]=300000,["Ice"]=350000,["Sand"]=420000,["Dark"]=500000,
    ["Ghost"]=525000,["Diamond"]=600000,["Light"]=650000,["Rubber"]=750000,
    ["Barrier"]=800000,["Magma"]=850000,["Quake"]=1000000,["Buddha"]=1200000,
    ["Love"]=1300000,["Spider"]=1500000,["Sound"]=1700000,["Phoenix"]=1800000,
    ["Portal"]=1900000,["Rumble"]=2100000,["Pain"]=2300000,["Blizzard"]=2400000,
    ["Gravity"]=2500000,["Mammoth"]=2700000,["T-Rex"]=2700000,["Dough"]=2800000,
    ["Shadow"]=2900000,["Venom"]=3000000,["Control"]=3200000,["Spirit"]=3400000,
    ["Dragon"]=3500000,["Leopard"]=5000000,["Kitsune"]=8000000,
}

local function unstoreLowestFruit()
    local ok, inv = pcall(function() return CommF_:InvokeServer("getInventory") end)
    if not ok or not inv then return false end
    local lowestName, lowestPrice = nil, math.huge
    for _, item in pairs(inv) do
        if item.Type == "Blox Fruit" then
            local clean = item.Name:gsub(" Fruit$",""):gsub("%-.*","")
            local price = item.Price or fruitPrices[clean]
            if price and price < lowestPrice then
                lowestPrice = price
                lowestName  = item.Name
            end
        end
    end
    if lowestName then
        pcall(function() CommF_:InvokeServer("LoadFruit", lowestName) end)
        return true
    end
    return false
end

local function equipFruit()
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Demon Fruit") then
            return true
        end
    end
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Demon Fruit") then
            tool.Parent = Character
            return true
        end
    end
    return false
end

-- ============================================================
--  CHIP / RAID HELPERS
-- ============================================================
local function hasChip()
    return Player.Backpack:FindFirstChild("Special Microchip")
        or Character:FindFirstChild("Special Microchip")
end

local function raidTimerVisible()
    local gui   = Player.PlayerGui:FindFirstChild("Main")
    local timer = gui and gui:FindFirstChild("Timer")
    return timer and timer.Visible
end

local function buyChip()
    if hasChip() or isBuyingChip then return hasChip() end
    isBuyingChip = true

    if not equipFruit() then
        if unstoreLowestFruit() then
            task.wait(2)
            equipFruit()
        end
    end

    if equipFruit() then
        local wasAttacking = autoAttack
        autoAttack = false
        task.wait(0.1)

        pcall(function()
            CommF_:InvokeServer("RaidsNpc", "Select", selectedRaid)
        end)
        task.wait(2)

        if wasAttacking then autoAttack = true end
    end

    isBuyingChip = false
    return hasChip()
end

-- ============================================================
--  RAID START — finds RaidSummon2 button and clicks it
-- ============================================================
local function startRaid()
    if isStartingRaid or raidTimerVisible() then return end
    isStartingRaid = true

    local map        = workspace:FindFirstChild("Map")
    local boatCastle = map and map:FindFirstChild("Boat Castle")
    local raidSummon = boatCastle and boatCastle:FindFirstChild("RaidSummon2")

    if not raidSummon then
        warn("[FA Hub] RaidSummon2 not found under Map.Boat Castle")
        isStartingRaid = false
        return
    end

    -- Collect all ClickDetectors inside the summon model
    local detectors = {}
    for _, desc in ipairs(raidSummon:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            table.insert(detectors, desc)
        end
    end

    if #detectors == 0 then
        warn("[FA Hub] No ClickDetectors found in RaidSummon2")
        isStartingRaid = false
        return
    end

    local prevCF = HumanoidRootPart.CFrame

    for _, cd in ipairs(detectors) do
        if raidTimerVisible() then break end
        local part = cd.Parent
        if part:IsA("BasePart") then
            -- Move close to the button part
            local targetPos = part.Position + Vector3.new(0, part.Size.Y / 2 + 3, 0)
            local dist = (HumanoidRootPart.Position - targetPos).Magnitude
            if dist > 10 then
                local t = TweenService:Create(
                    HumanoidRootPart,
                    TweenInfo.new(math.max(dist / 200, 0.3), Enum.EasingStyle.Linear),
                    { CFrame = CFrame.new(targetPos) }
                )
                t:Play()
                t.Completed:Wait()
                task.wait(0.3)
            end
        end
        -- Click the detector up to 4 times
        for _ = 1, 4 do
            if raidTimerVisible() then break end
            pcall(function() fireclickdetector(cd) end)
            task.wait(0.4)
        end
    end

    -- Return to original position if raid didn't start
    if not raidTimerVisible() then
        warn("[FA Hub] Raid failed to start — check ClickDetector MaxActivationDistance")
        HumanoidRootPart.CFrame = prevCF
    else
        print("[FA Hub] Raid started!")
    end

    task.wait(3)
    isStartingRaid = false
end

-- ============================================================
--  ATTACH FLOAT (BodyVelocity + BodyGyro)
-- ============================================================
local function attachFloat()
    if not HumanoidRootPart:FindFirstChild("FloatBV") then
        local bv = Instance.new("BodyVelocity")
        bv.Name     = "FloatBV"
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Velocity = Vector3.zero
        bv.Parent   = HumanoidRootPart
    end
    if not HumanoidRootPart:FindFirstChild("StabilizerBG") then
        local bg = Instance.new("BodyGyro")
        bg.Name      = "StabilizerBG"
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.CFrame    = HumanoidRootPart.CFrame
        bg.Parent    = HumanoidRootPart
    end
end

local function removeFloat()
    if HumanoidRootPart:FindFirstChild("FloatBV")      then HumanoidRootPart.FloatBV:Destroy()      end
    if HumanoidRootPart:FindFirstChild("StabilizerBG") then HumanoidRootPart.StabilizerBG:Destroy() end
end

-- ============================================================
--  WEAPON EQUIP
-- ============================================================
local function equipWeapon()
    if not (autofarm or autoRaid or autoBossFarm or autoAttack) then return end
    
    local tool = Character:FindFirstChildOfClass("Tool")
    if tool and tool.ToolTip == selectedWeapon then return end
    
    if hasChip() or equipFruit() then return end
    
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == selectedWeapon then
            tool.Parent = Character
            return
        end
    end
end

local function unequipWeapon()
    for _, tool in ipairs(Character:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip ~= "Special Microchip" and not tool.Name:find("Fruit") then
            tool.Parent = Player.Backpack
        end
    end
end

-- ============================================================
--  AUTO ATTACK (hits NPCs only)
-- ============================================================
local RegisterAttack = Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit    = Net:FindFirstChild("RE/RegisterHit")

local function doAutoAttack()
    task.spawn(function()
        while autoAttack do
            if not HumanoidRootPart then break end
            local targets = {}
            for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum  = enemy:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    local dist = (HumanoidRootPart.Position - head.Position).Magnitude
                    if dist <= Settings.Distance then
                        table.insert(targets, { enemy, head })
                    end
                end
            end
            if #targets >= 1 then
                local primary = targets[1]
                if RegisterAttack then RegisterAttack:FireServer(0) end
                if RegisterHit then
                    if #targets >= 2 then
                        RegisterHit:FireServer(primary[2], { { targets[2][1], targets[2][2] } })
                    else
                        RegisterHit:FireServer(primary[2], {})
                    end
                end
            end
            task.wait(math.max(Settings.AttackDelay, 0))
        end
    end)
end

local function setAutoAttack(val)
    autoAttack = val
    if val then
        equipWeapon()
        doAutoAttack()
    else
        unequipWeapon()
    end
end

-- ============================================================
--  WALK ON WATER
-- ============================================================
local waterWalk = Instance.new("Part", workspace)
waterWalk.Transparency = 1
waterWalk.Name         = "FAHubWaterWalk"
waterWalk.CanCollide   = false
waterWalk.Size         = Vector3.new(1000, 1, 1000)
waterWalk.Anchored     = true

AddConnection(RunService.RenderStepped:Connect(function()
    if HumanoidRootPart then
        waterWalk.Position = Vector3.new(
            HumanoidRootPart.Position.X,
            -4.5,
            HumanoidRootPart.Position.Z
        )
    end
end))

-- ============================================================
--  HEARTBEAT
-- ============================================================
AddConnection(RunService.Heartbeat:Connect(function()
    -- Auto stats
    if autoStats then
        pcall(function() CommF_:InvokeServer("AddPoint", selectedStat, addAmount) end)
    end

    -- Keep walk speed synced
    if Humanoid and Humanoid.WalkSpeed ~= SetWalkSpeed then
        Humanoid.WalkSpeed = SetWalkSpeed
    end

    -- Remove float when no active farm
    if not (autofarm or autoRaid or autoBossFarm or chestFarmEnabled) then
        removeFloat()
        if ActiveTween then ActiveTween:Cancel(); ActiveTween = nil end
        return
    end

    attachFloat()

    local isRaidActive = autoRaid and raidTimerVisible()
    local isBossActive = autoBossFarm and currentBossTarget

    if autofarm or isRaidActive or isBossActive or chestFarmEnabled then
        -- Ensure auto attack is on
        if not (autoAttack or chestFarmEnabled) then setAutoAttack(true) end
        if not chestFarmEnabled then equipWeapon() end

        -- Disable collisions
        for _, bp in ipairs(Character:GetChildren()) do
            if bp:IsA("BasePart") then bp.CanCollide = false end
        end

        -- If it's just chest farming, we don't need the combat logic here
        if chestFarmEnabled and not (autofarm or isRaidActive or isBossActive) then
            return
        end

        local target
        if isBossActive then
            target = findBoss(currentBossTarget.Name)
            if not target then
                -- FALLBACK: Move to island/spawn to wait or trigger load
                local spawnPos = getBossSpawn(currentBossTarget)
                if spawnPos and (not ActiveTween or ActiveTween.PlaybackState ~= Enum.PlaybackState.Playing) then
                    moveTo(spawnPos + Vector3.new(0, 150, 0))
                end
                return 
            end
        elseif isRaidActive then
            -- During raid: target any alive enemy
            for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then target = enemy; break end
            end
        else
            -- During farm: target quest enemy
            if not questInfo or not questInfo.enemy then
                questInfo = getQuest(true)
                return
            end
            -- Re-get quest if it completed
            if not Player.PlayerGui.Main.Quest.Visible then
                questInfo = getQuest(true)
                return
            end
            for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                if enemy.Name == questInfo.enemy then
                    local hum = enemy:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then target = enemy; break end
                end
            end
        end

        if target and target:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.HumanoidRootPart.Position
            local dist      = (HumanoidRootPart.Position - targetPos).Magnitude

            if dist > orbitDistance then
                -- Only move if we aren't already tweening or we are too far from the tween target
                if not ActiveTween or (ActiveTween.PlaybackState ~= Enum.PlaybackState.Playing) then
                    moveTo(targetPos + Vector3.new(0, 20, 0))
                end
            else
                if ActiveTween then ActiveTween:Cancel(); ActiveTween = nil end
                if os.clock() - lastSwitch >= snapTime then
                    snapIndex  = (snapIndex % #snapOffsets) + 1
                    lastSwitch = os.clock()
                end
                local snap      = snapOffsets[snapIndex]
                local orbitPos  = targetPos + Vector3.new(snap.X, snap.Y, snap.Z)
                HumanoidRootPart.CFrame = CFrame.new(
                    HumanoidRootPart.Position:Lerp(orbitPos, 0.25)
                )
                -- Anchor target so it can't flee
                target.HumanoidRootPart.Anchored = true
            end
        end
    end
end))

-- ============================================================
--  RAID LOOP
-- ============================================================
task.spawn(function()
    while _G.FAHubLoaded and task.wait(2) do
        if not autoRaid then continue end
        if raidTimerVisible() then
            if not autoAttack then setAutoAttack(true) end
        else
            if autoAttack then setAutoAttack(false) end
            if not hasChip() and not isBuyingChip then
                task.spawn(buyChip)
            elseif hasChip() and not isStartingRaid then
                task.spawn(startRaid)
            end
        end
    end
end)

-- ============================================================
--  BOSS FARM LOGIC
-- ============================================================
local currentBossTarget = nil
local patrolState       = "IDLE" -- IDLE, MOVING, WAITING, FIGHTING

task.spawn(function()
    local islandRotationIndex = 1
    while _G.FAHubLoaded and task.wait(1) do
        if not autoBossFarm then 
            currentBossTarget = nil
            patrolState = "IDLE"
            continue 
        end
        
        local bosses = Bosses[game.PlaceId] or {}
        if #bosses == 0 then continue end
        
        if selectedBoss ~= "All" then
            -- Single Boss Mode
            local b = nil
            for _, item in ipairs(bosses) do
                if item.Name == selectedBoss then b = item; break end
            end
            if b then
                currentBossTarget = b
                local target = findBoss(b.Name)
                if target then
                    patrolState = "FIGHTING"
                    -- Wait until dead
                    while autoBossFarm and selectedBoss ~= "All" and findBoss(b.Name) do 
                        task.wait(1) 
                    end
                else
                    patrolState = "MOVING"
                    task.wait(2)
                end
            end
        elseif farmAllBosses then
            -- Farm All (Patrol Mode)
            local b = bosses[islandRotationIndex]
            currentBossTarget = b
            patrolState = "MOVING"
            
            -- 1. Travel to island
            teleportToIsland(b.Island)
            task.wait(5) -- Initial load wait
            
            -- 2. Check for boss
            local waitStart = os.clock()
            local found = nil
            repeat
                found = findBoss(b.Name)
                if not found then task.wait(1) end
            until found or (os.clock() - waitStart > 10) or not autoBossFarm or not farmAllBosses
            
            if found then
                patrolState = "FIGHTING"
                -- Stay until dead
                while autoBossFarm and farmAllBosses and findBoss(b.Name) do 
                    task.wait(1) 
                end
            end
            
            -- 3. Cycle to next
            islandRotationIndex = (islandRotationIndex % #bosses) + 1
        end
    end
end)

-- ============================================================
--  FRUIT LOOP
-- ============================================================
task.spawn(function()
    while _G.FAHubLoaded and task.wait(5) do
        if autoStoreFruit then
            for _, tool in ipairs(Player.Backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:find("Fruit") or tool.ToolTip == "Demon Fruit") then
                    pcall(function() CommF_:InvokeServer("StoreFruit", tool.Name, tool) end)
                    task.wait(0.5)
                end
            end
        end
        if autoFruitRoll then
            local res = CommF_:InvokeServer("Cousin", "Buy")
            if res and not tostring(res):find("wait") then
                notify("Auto Gacha", "Rolled: " .. tostring(res), 5)
            end
        end
    end
end)

-- ============================================================
--  INF JUMP & UI MINIMIZE
-- ============================================================
local function toggleMinimize()
    isMinimised = not isMinimised
    MinBtn.Text = isMinimised and "+" or "−"
    tween(Root, { Size = isMinimised and UDim2.new(0, 420, 0, 52) or UDim2.new(0, 420, 0, 560) })
end

AddConnection(UserInputService.InputBegan:Connect(function(input, gp)
    if not gp then
        if input.KeyCode == Enum.KeyCode.Space then
            holding = true
            task.spawn(function()
                while holding and infJumpEnabled and Player.Character do
                    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    task.wait(0.55)
                end
            end)
        elseif input.KeyCode == UIHotkey then
            toggleMinimize()
        end
    end
end))
AddConnection(UserInputService.InputEnded:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Space then holding = false end
end))

-- ============================================================
--  MISC SETUP
-- ============================================================
pcall(function()
    ReplicatedStorage.Effect.Container:FindFirstChild("Death"):Destroy()
end)

do
    local hl = Instance.new("Highlight")
    hl.Parent    = Character
    hl.FillColor = Color3.fromRGB(99, 202, 183)
    hl.DepthMode = Enum.HighlightDepthMode.Occluded
end

pcall(function() CommF_:InvokeServer("Buso") end)

-- ============================================================
--  SERVER HOP
-- ============================================================
local function getServers(placeId)
    local servers, cursor = {}, nil
    repeat
        local url = ("https://games.roblox.com/v1/games/%s/servers/Public?limit=100%s"):format(
            placeId, cursor and "&cursor=" .. HttpService:UrlEncode(cursor) or "")
        local ok, res = pcall(function() return HttpService:GetAsync(url) end)
        if not ok then break end
        local data = HttpService:JSONDecode(res)
        for _, s in ipairs(data.data or {}) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end
        cursor = data.nextPageCursor
    until not cursor
    return servers
end

-- ============================================================
--  FA HUB UI — Custom ScreenGui
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "FAHub"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset    = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Player.PlayerGui end

-- ── Colour palette ──────────────────────────────────────────
local C = {
    bg        = Color3.fromRGB(9,  12,  18),
    panel     = Color3.fromRGB(14, 19,  28),
    card      = Color3.fromRGB(20, 27,  40),
    border    = Color3.fromRGB(35, 48,  72),
    accent    = Color3.fromRGB(99, 202, 183),   -- teal
    accent2   = Color3.fromRGB(64, 140, 230),   -- blue
    text      = Color3.fromRGB(220, 230, 245),
    subtext   = Color3.fromRGB(110, 130, 165),
    toggleOn  = Color3.fromRGB(99, 202, 183),
    toggleOff = Color3.fromRGB(40,  52,  75),
    red       = Color3.fromRGB(230, 80,  80),
}

-- ── Helpers ──────────────────────────────────────────────────
local function make(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end

local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = thick or 1
    s.Parent    = parent
    return s
end

local function label(parent, text, size, color, font, xAlign)
    return make("TextLabel", {
        Parent           = parent,
        Text             = text,
        TextSize         = size or 13,
        TextColor3       = color or C.text,
        Font             = font or Enum.Font.GothamMedium,
        BackgroundTransparency = 1,
        TextXAlignment   = xAlign or Enum.TextXAlignment.Left,
        Size             = UDim2.new(1, 0, 0, size and size + 6 or 20),
    })
end

-- ── Root frame ───────────────────────────────────────────────
local Root = make("Frame", {
    Parent          = ScreenGui,
    Size            = UDim2.new(0, 420, 0, 560),
    Position        = UDim2.new(0.5, -210, 0.5, -280),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
corner(Root, 14)
stroke(Root, C.border, 1.5)

-- subtle gradient overlay
do
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 28, 44)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(9,  12, 18)),
    })
    grad.Rotation = 130
    grad.Parent   = Root
end

-- ── Drag logic ───────────────────────────────────────────────
do
    local dragging, dragStart, startPos
    AddConnection(Root.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = inp.Position
            local absPos = Root.AbsolutePosition
            local absSize = Root.AbsoluteSize
            local relX = pos.X - absPos.X
            local relY = pos.Y - absPos.Y
            local edge = 25
            
            if relX < edge or relX > absSize.X - edge or relY < edge or relY > absSize.Y - edge then
                dragging  = true
                dragStart = pos
                startPos  = Root.Position
            end
        end
    end))
    AddConnection(Root.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    AddConnection(UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            Root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

-- ── Top bar ──────────────────────────────────────────────────
local TopBar = make("Frame", {
    Parent          = Root,
    Size            = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})
corner(TopBar, 14)

-- bottom mask to square off the top bar's bottom edge
make("Frame", {
    Parent          = TopBar,
    Size            = UDim2.new(1, 0, 0, 14),
    Position        = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
})

-- Accent line under top bar
make("Frame", {
    Parent          = Root,
    Size            = UDim2.new(1, 0, 0, 1),
    Position        = UDim2.new(0, 0, 0, 52),
    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
})

-- Logo dot
do
    local dot = make("Frame", {
        Parent          = TopBar,
        Size            = UDim2.new(0, 8, 0, 8),
        Position        = UDim2.new(0, 18, 0.5, -4),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    })
    corner(dot, 4)
end

-- Title
make("TextLabel", {
    Parent               = TopBar,
    Text                 = "FA Hub",
    TextSize             = 16,
    Font                 = Enum.Font.GothamBold,
    TextColor3           = C.text,
    BackgroundTransparency = 1,
    Position             = UDim2.new(0, 34, 0, 0),
    Size                 = UDim2.new(0, 120, 1, 0),
    TextXAlignment       = Enum.TextXAlignment.Left,
})
make("TextLabel", {
    Parent               = TopBar,
    Text                 = "by Taxi",
    TextSize             = 11,
    Font                 = Enum.Font.Gotham,
    TextColor3           = C.subtext,
    BackgroundTransparency = 1,
    Position             = UDim2.new(0, 34, 0, 28),
    Size                 = UDim2.new(0, 120, 0, 16),
    TextXAlignment       = Enum.TextXAlignment.Left,
})

-- Minimise button
local MinBtn = make("TextButton", {
    Parent               = TopBar,
    Text                 = "−",
    TextSize             = 18,
    Font                 = Enum.Font.GothamBold,
    TextColor3           = C.subtext,
    BackgroundTransparency = 1,
    Size                 = UDim2.new(0, 36, 1, 0),
    Position             = UDim2.new(1, -36, 0, 0),
    AutoButtonColor      = false,
})
local isMinimised = false
local ContentArea  -- forward-declared below

MinBtn.MouseButton1Click:Connect(function()
    isMinimised = not isMinimised
    MinBtn.Text = isMinimised and "+" or "−"
    tween(Root, { Size = isMinimised and UDim2.new(0, 420, 0, 52) or UDim2.new(0, 420, 0, 560) })
end)

-- ── Tab bar ──────────────────────────────────────────────────
local TabBar = make("ScrollingFrame", {
    Parent          = Root,
    Size            = UDim2.new(1, 0, 0, 38),
    Position        = UDim2.new(0, 0, 0, 53),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize      = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ClipsDescendants = true,
})

make("UIListLayout", {
    Parent          = TabBar,
    FillDirection   = Enum.FillDirection.Horizontal,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding         = UDim.new(0, 2),
})
make("UIPadding", {
    Parent     = TabBar,
    PaddingLeft = UDim.new(0, 8),
})

-- Bottom border under tab bar
make("Frame", {
    Parent          = Root,
    Size            = UDim2.new(1, 0, 0, 1),
    Position        = UDim2.new(0, 0, 0, 91),
    BackgroundColor3 = C.border,
    BorderSizePixel = 0,
})

-- ── Content area ─────────────────────────────────────────────
ContentArea = make("Frame", {
    Parent          = Root,
    Size            = UDim2.new(1, 0, 1, -92),
    Position        = UDim2.new(0, 0, 0, 92),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
})

-- ── Tab system ───────────────────────────────────────────────
local tabs      = {}
local tabPages  = {}
local activeTab = nil

local function createTab(name, icon)
    local idx = #tabs + 1

    local btn = make("TextButton", {
        Parent               = TabBar,
        Text                 = icon .. " " .. name,
        TextSize             = 11,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.subtext,
        BackgroundColor3     = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 1,
        AutoButtonColor      = false,
        Size                 = UDim2.new(0, 74, 1, 0),
        LayoutOrder          = idx,
    })

    local indicator = make("Frame", {
        Parent          = btn,
        Size            = UDim2.new(0.7, 0, 0, 2),
        Position        = UDim2.new(0.15, 0, 1, -2),
        BackgroundColor3 = C.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    corner(indicator, 2)

    -- Scroll container for this tab's content
    local scroll = make("ScrollingFrame", {
        Parent                   = ContentArea,
        Size                     = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency   = 1,
        BorderSizePixel          = 0,
        ScrollBarThickness       = 3,
        ScrollBarImageColor3     = C.accent,
        CanvasSize               = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize      = Enum.AutomaticSize.Y,
        Visible                  = false,
        ClipsDescendants         = true,
    })
    make("UIPadding", {
        Parent       = scroll,
        PaddingLeft  = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop   = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
    })
    make("UIListLayout", {
        Parent  = scroll,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local tabEntry = { btn = btn, scroll = scroll, indicator = indicator }
    tabs[idx]      = tabEntry
    tabPages[name] = tabEntry

    btn.MouseButton1Click:Connect(function()
        if activeTab == name then return end
        -- deactivate all
        for _, t in pairs(tabs) do
            t.scroll.Visible = false
            tween(t.indicator, { BackgroundTransparency = 1 }, 0.15)
            tween(t.btn, { TextColor3 = C.subtext }, 0.15)
        end
        -- activate this
        scroll.Visible = true
        tween(indicator, { BackgroundTransparency = 0 }, 0.15)
        tween(btn, { TextColor3 = C.accent }, 0.15)
        activeTab = name
    end)

    return tabEntry
end

-- ── Widget builders ──────────────────────────────────────────
local function makeCard(parent, layoutOrder)
    local card = make("Frame", {
        Parent          = parent,
        Size            = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        LayoutOrder     = layoutOrder or 1,
        AutomaticSize   = Enum.AutomaticSize.Y,
    })
    corner(card, 8)
    stroke(card, C.border, 1)
    return card
end

local function makeSection(parent, title, order)
    local sec = make("Frame", {
        Parent          = parent,
        Size            = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder     = order or 1,
    })
    local lbl = make("TextLabel", {
        Parent               = sec,
        Text                 = title:upper(),
        TextSize             = 10,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.accent,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 1, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })
    -- underline
    make("Frame", {
        Parent          = sec,
        Size            = UDim2.new(1, 0, 0, 1),
        Position        = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.border,
        BorderSizePixel = 0,
    })
    return sec
end

local orderCounter = {}
local function nextOrder(page)
    orderCounter[page] = (orderCounter[page] or 0) + 1
    return orderCounter[page]
end

local function addToggle(page, labelText, default, onChange)
    local card = makeCard(page.scroll, nextOrder(page.scroll.Name))
    card.Size  = UDim2.new(1, 0, 0, 44)

    make("TextLabel", {
        Parent               = card,
        Text                 = labelText,
        TextSize             = 13,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -60, 1, 0),
        Position             = UDim2.new(0, 14, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    local track = make("Frame", {
        Parent          = card,
        Size            = UDim2.new(0, 40, 0, 22),
        Position        = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = default and C.toggleOn or C.toggleOff,
        BorderSizePixel = 0,
    })
    corner(track, 11)

    local knob = make("Frame", {
        Parent          = track,
        Size            = UDim2.new(0, 16, 0, 16),
        Position        = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    corner(knob, 8)

    local state = default
    local btn   = make("TextButton", {
        Parent               = card,
        Text                 = "",
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 1, 0),
        AutoButtonColor      = false,
    })
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(track, { BackgroundColor3 = state and C.toggleOn or C.toggleOff })
        tween(knob, { Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) })
        pcall(onChange, state)
    end)
    return { set = function(v)
        state = v
        tween(track, { BackgroundColor3 = v and C.toggleOn or C.toggleOff })
        tween(knob,  { Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) })
        pcall(onChange, v)
    end }
end

local function addButton(page, labelText, onClick)
    local card = makeCard(page.scroll, nextOrder(page.scroll.Name))
    card.Size  = UDim2.new(1, 0, 0, 40)

    local btn = make("TextButton", {
        Parent               = card,
        Text                 = labelText,
        TextSize             = 13,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.text,
        BackgroundColor3     = C.card,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 1, 0),
        AutoButtonColor      = false,
    })

    local arrow = make("TextLabel", {
        Parent               = card,
        Text                 = "›",
        TextSize             = 18,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.accent,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0, 24, 1, 0),
        Position             = UDim2.new(1, -28, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Center,
    })

    make("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0,14) })

    btn.MouseEnter:Connect(function()
        tween(card, { BackgroundColor3 = C.border })
    end)
    btn.MouseLeave:Connect(function()
        tween(card, { BackgroundColor3 = C.card })
    end)
    btn.MouseButton1Click:Connect(function()
        tween(card, { BackgroundColor3 = C.accent }, 0.08)
        task.delay(0.15, function() tween(card, { BackgroundColor3 = C.card }) end)
        pcall(onClick)
    end)
end

local function addSlider(page, labelText, min, max, default, suffix, onChange)
    local card = makeCard(page.scroll, nextOrder(page.scroll.Name))
    card.Size  = UDim2.new(1, 0, 0, 62)

    make("TextLabel", {
        Parent               = card,
        Text                 = labelText,
        TextSize             = 13,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.65, 0, 0, 28),
        Position             = UDim2.new(0, 14, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    local valLabel = make("TextLabel", {
        Parent               = card,
        Text                 = tostring(default) .. (suffix or ""),
        TextSize             = 12,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.accent,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.35, -14, 0, 28),
        Position             = UDim2.new(0.65, 0, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Right,
    })

    local track = make("Frame", {
        Parent          = card,
        Size            = UDim2.new(1, -28, 0, 4),
        Position        = UDim2.new(0, 14, 0, 40),
        BackgroundColor3 = C.border,
        BorderSizePixel = 0,
    })
    corner(track, 2)

    local fill = make("Frame", {
        Parent          = track,
        Size            = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    })
    corner(fill, 2)

    local knob = make("Frame", {
        Parent          = fill,
        Size            = UDim2.new(0, 12, 0, 12),
        Position        = UDim2.new(1, -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    })
    corner(knob, 6)

    local draggingSlider = false
    local function updateSlider()
        local mousePos = UserInputService:GetMouseLocation()
        local rel      = math.clamp((mousePos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value    = math.floor(min + rel * (max - min) + 0.5)
        fill.Size      = UDim2.new(rel, 0, 1, 0)
        valLabel.Text  = tostring(value) .. (suffix or "")
        pcall(onChange, value)
    end

    AddConnection(track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateSlider()
        end
    end))
    
    AddConnection(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end))

    AddConnection(RunService.RenderStepped:Connect(function()
        if draggingSlider then
            if not ScreenGui.Enabled then draggingSlider = false return end
            updateSlider()
        end
    end))
end

local function addKeybind(page, labelText, default, onChange)
    local card = makeCard(page.scroll, nextOrder(page.scroll.Name))
    card.Size  = UDim2.new(1, 0, 0, 44)

    make("TextLabel", {
        Parent               = card,
        Text                 = labelText,
        TextSize             = 13,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, -120, 1, 0),
        Position             = UDim2.new(0, 14, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    local bindBtn = make("TextButton", {
        Parent               = card,
        Text                 = default.Name,
        TextSize             = 11,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.accent,
        BackgroundColor3     = C.bg,
        AutoButtonColor      = false,
        Size                 = UDim2.new(0, 90, 0, 28),
        Position             = UDim2.new(1, -104, 0.5, -14),
    })
    corner(bindBtn, 6)
    stroke(bindBtn, C.border, 1)

    local listening = false
    bindBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        bindBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.KeyCode.Space then return end -- Skip space
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                bindBtn.Text = input.KeyCode.Name
                listening = false
                pcall(onChange, input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                conn:Disconnect()
                bindBtn.Text = default.Name
                listening = false
            end
        end)
    end)
end

local function addDropdown(page, labelText, options, default, onChange)
    local card = makeCard(page.scroll, nextOrder(page.scroll.Name))
    card.Size  = UDim2.new(1, 0, 0, 44)
    card.ClipsDescendants = false
    card.ZIndex = 10

    make("TextLabel", {
        Parent               = card,
        Text                 = labelText,
        TextSize             = 13,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.text,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(0.5, 0, 1, 0),
        Position             = UDim2.new(0, 14, 0, 0),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })

    local selected = default or options[1]

    local selBtn = make("TextButton", {
        Parent               = card,
        Text                 = selected .. " ▾",
        TextSize             = 12,
        Font                 = Enum.Font.GothamMedium,
        TextColor3           = C.accent,
        BackgroundColor3     = C.bg,
        AutoButtonColor      = false,
        Size                 = UDim2.new(0, 130, 0, 28),
        Position             = UDim2.new(1, -144, 0.5, -14),
        ZIndex               = 11,
    })
    corner(selBtn, 6)
    stroke(selBtn, C.border, 1)

    local dropFrame = make("Frame", {
        Parent          = card,
        Size            = UDim2.new(0, 130, 0, #options * 28 + 4),
        Position        = UDim2.new(1, -144, 1, 4),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Visible         = false,
        ZIndex          = 20,
        ClipsDescendants = true,
    })
    corner(dropFrame, 6)
    stroke(dropFrame, C.border, 1)

    local listLayout = make("UIListLayout", { Parent = dropFrame, Padding = UDim.new(0,0), SortOrder = Enum.SortOrder.LayoutOrder })
    make("UIPadding", { Parent = dropFrame, PaddingTop = UDim.new(0,2), PaddingBottom = UDim.new(0,2) })

    local open = false
    for i, opt in ipairs(options) do
        local optBtn = make("TextButton", {
            Parent               = dropFrame,
            Text                 = opt,
            TextSize             = 12,
            Font                 = Enum.Font.GothamMedium,
            TextColor3           = opt == selected and C.accent or C.text,
            BackgroundColor3     = C.bg,
            BackgroundTransparency = 1,
            AutoButtonColor      = false,
            Size                 = UDim2.new(1, 0, 0, 28),
            LayoutOrder          = i,
            ZIndex               = 21,
        })
        optBtn.MouseEnter:Connect(function() tween(optBtn, { TextColor3 = C.accent }) end)
        optBtn.MouseLeave:Connect(function() tween(optBtn, { TextColor3 = opt == selected and C.accent or C.text }) end)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selBtn.Text = opt .. " ▾"
            open = false
            dropFrame.Visible = false
            pcall(onChange, opt)
        end)
    end

    selBtn.MouseButton1Click:Connect(function()
        open = not open
        dropFrame.Visible = open
    end)
end

local function addLabel(page, text, order)
    local lbl = make("TextLabel", {
        Parent               = page.scroll,
        Text                 = text,
        TextSize             = 11,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.subtext,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1, 0, 0, 20),
        TextXAlignment       = Enum.TextXAlignment.Left,
        LayoutOrder          = order or nextOrder(page.scroll.Name),
        TextWrapped          = true,
    })
end

-- ── NOTIFICATION ─────────────────────────────────────────────
local notifQueue = {}
local function notify(title, msg, duration)
    local notifFrame = make("Frame", {
        Parent          = ScreenGui,
        Size            = UDim2.new(0, 260, 0, 56),
        Position        = UDim2.new(1, 10, 1, -70 - (#notifQueue * 64)),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        ZIndex          = 100,
    })
    corner(notifFrame, 10)
    stroke(notifFrame, C.accent, 1.5)

    make("Frame", {
        Parent          = notifFrame,
        Size            = UDim2.new(0, 3, 1, -16),
        Position        = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0,
    })

    make("TextLabel", {
        Parent               = notifFrame,
        Text                 = title,
        TextSize             = 12,
        Font                 = Enum.Font.GothamBold,
        TextColor3           = C.accent,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1,-16, 0, 20),
        Position             = UDim2.new(0, 12, 0, 8),
        TextXAlignment       = Enum.TextXAlignment.Left,
    })
    make("TextLabel", {
        Parent               = notifFrame,
        Text                 = msg,
        TextSize             = 11,
        Font                 = Enum.Font.Gotham,
        TextColor3           = C.subtext,
        BackgroundTransparency = 1,
        Size                 = UDim2.new(1,-16, 0, 18),
        Position             = UDim2.new(0, 12, 0, 28),
        TextXAlignment       = Enum.TextXAlignment.Left,
        TextWrapped          = true,
    })

    table.insert(notifQueue, notifFrame)
    tween(notifFrame, { Position = UDim2.new(1, -270, 1, -70 - (#notifQueue-1)*64) }, 0.3)

    task.delay(duration or 3, function()
        tween(notifFrame, { Position = UDim2.new(1, 20, 1, -70) }, 0.3)
        task.delay(0.35, function()
            for i, f in ipairs(notifQueue) do
                if f == notifFrame then table.remove(notifQueue, i); break end
            end
            notifFrame:Destroy()
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════
--  BUILD TABS
-- ══════════════════════════════════════════════════════════════

-- ── FARM TAB ─────────────────────────────────────────────────
local farmTab = createTab("Farm", "⚔")

makeSection(farmTab.scroll, "Combat", nextOrder(farmTab.scroll.Name))

addToggle(farmTab, "Auto Attack (NPCs)", false, function(v)
    setAutoAttack(v)
end)

addToggle(farmTab, "Auto Farm (Level)", false, function(v)
    autofarm = v
    if v then
        questInfo = getQuest(true)
        if not autoAttack then setAutoAttack(true) end
    else
        if ActiveTween then ActiveTween:Cancel(); ActiveTween = nil end
    end
end)

addToggle(farmTab, "Auto Farm Chests", false, function(v)
    chestFarmEnabled = v
    if v then
        task.spawn(function()
            local taken = {}
            
            local function collectLocalChests()
                local folder = Workspace:FindFirstChild("ChestModels")
                if not folder then return end
                
                local chests = {}
                for _, obj in ipairs(folder:GetChildren()) do
                    if obj:IsA("Model") and not taken[obj] then
                        table.insert(chests, obj)
                    end
                end
                
                if #chests > 0 then
                    -- Sort by distance
                    table.sort(chests, function(a, b)
                        return (HumanoidRootPart.Position - a:GetPivot().Position).Magnitude < (HumanoidRootPart.Position - b:GetPivot().Position).Magnitude
                    end)
                    
                    for _, chest in ipairs(chests) do
                        if not chestFarmEnabled then break end
                        local pos = chest:GetPivot().Position
                        local targetPos = Vector3.new(pos.X, math.max(pos.Y, 20), pos.Z)
                        local t = moveTo(targetPos)
                        if t then t.Completed:Wait() end
                        taken[chest] = true
                        task.wait(0.4) -- Reliability delay
                    end
                end
            end

            local seaIslands = {
                [27539155] = {"Windmill", "MarineStart", "Jungle", "Pirate", "Desert", "Ice", "MarineBase", "Sky", "Prison", "Colosseum", "Magma", "Fishmen", "Fountain"},
                [4442272183] = {"Kingdom of Rose", "Green Bit", "Cafe", "Graveyard", "Snow Mountain", "Hot and Cold", "Cursed Ship", "Ice Castle", "Forgotten Island"},
                [7449925010] = {"Port Town", "Hydra Island", "Floating Turtle", "Castle on the Sea", "Haunted Castle", "Sea of Treats", "Tiki Outpost"}
            }

            while _G.FAHubLoaded and chestFarmEnabled do
                local islands = seaIslands[game.PlaceId] or seaIslands[27539155]
                
                for _, islandName in ipairs(islands) do
                    if not chestFarmEnabled then break end
                    
                    -- Teleport to island using portals or tween
                    local t_move = teleportToIsland(islandName)
                    if t_move then t_move.Completed:Wait() end
                    task.wait(2.5) -- Wait for assets

                    -- Collect
                    collectLocalChests()
                    
                    -- Sweep only if island is large (Sky, Magma, Rose, Turtle, etc.)
                    local largeIslands = {Sky = true, Magma = true, ["Kingdom of Rose"] = true, ["Floating Turtle"] = true, ["Sea of Treats"] = true}
                    if largeIslands[islandName] then
                        local currentPos = HumanoidRootPart.Position
                        local offsets = {Vector3.new(800, 0, 800), Vector3.new(-800, 0, -800)}
                        for _, offset in ipairs(offsets) do
                            if not chestFarmEnabled then break end
                            local t_sweep = moveTo(currentPos + offset + Vector3.new(0, 50, 0))
                            if t_sweep then t_sweep.Completed:Wait() end
                            task.wait(1.5)
                            collectLocalChests()
                        end
                    end
                end
                
                task.wait(5)
                table.clear(taken)
            end
        end)
    end
end)

makeSection(farmTab.scroll, "Weapon", nextOrder(farmTab.scroll.Name))

addDropdown(farmTab, "Weapon Type", {"Melee","Sword"}, "Melee", function(v)
    selectedWeapon   = v
    lastEquippedType = nil
    equipWeapon()
end)

makeSection(farmTab.scroll, "Settings", nextOrder(farmTab.scroll.Name))

addSlider(farmTab, "Attack Range", 5, 100, 50, " st", function(v)
    Settings.Distance = v
end)

addSlider(farmTab, "Attack Delay", 0, 20, 0, "×0.05s", function(v)
    Settings.AttackDelay = v * 0.05
end)

-- ── RAID TAB ─────────────────────────────────────────────────
local raidTab = createTab("Raid", "🏴")

makeSection(raidTab.scroll, "Configuration", nextOrder(raidTab.scroll.Name))

addDropdown(raidTab, "Select Raid", {
    "Flame","Ice","Quake","Light","Dark","Spider",
    "Rumble","Magma","Buddha","Sand","Dough","Phoenix"
}, "Flame", function(v)
    selectedRaid = v
end)

addToggle(raidTab, "Auto Raid", false, function(v)
    autoRaid = v
end)

makeSection(raidTab.scroll, "Manual", nextOrder(raidTab.scroll.Name))

addButton(raidTab, "Buy Chip Now", function()
    notify("Chip", "Buying " .. selectedRaid .. " chip…", 2)
    task.spawn(buyChip)
end)

addButton(raidTab, "Start Raid Now", function()
    notify("Raid", "Attempting to start raid…", 2)
    task.spawn(startRaid)
end)

addButton(raidTab, "Scan Raid Remotes (F9)", function()
    local found = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            local l = obj.Name:lower()
            if l:find("raid") or l:find("start") or l:find("wave") then
                table.insert(found, obj.ClassName..": "..obj:GetFullName())
                warn("[FA Hub] "..obj.ClassName.." | "..obj:GetFullName())
            end
        end
    end
    notify("Scan", #found.." raid remote(s) — see F9", 4)
end)

-- ── BOSS TAB ─────────────────────────────────────────────────
local bossTab = createTab("Boss", "👺")
local currentBosses = Bosses[game.PlaceId] or {}
local bossNames = {"All"}
for _, b in ipairs(currentBosses) do table.insert(bossNames, b.Name) end

makeSection(bossTab.scroll, "Farming", nextOrder(bossTab.scroll.Name))

addDropdown(bossTab, "Select Boss", bossNames, "All", function(v)
    selectedBoss = v
end)

addToggle(bossTab, "Auto Farm Bosses", false, function(v)
    autoBossFarm = v
end)

addToggle(bossTab, "Farm All Bosses", false, function(v)
    farmAllBosses = v
end)

makeSection(bossTab.scroll, "Status", nextOrder(bossTab.scroll.Name))

addButton(bossTab, "Check Boss Spawns", function()
    local alive = {}
    local timers = {}
    for _, b in ipairs(currentBosses) do
        local found = findBoss(b.Name)
        if found then
            table.insert(alive, b.Name)
        else
            local timer = getBossTimer(b.Name)
            if timer then
                table.insert(timers, b.Name .. ": " .. timer)
            end
        end
    end
    
    local msg = ""
    if #alive > 0 then msg = msg .. "🟢 Alive: " .. table.concat(alive, ", ") .. "\n" end
    if #timers > 0 then msg = msg .. "🔴 Timers: \n" .. table.concat(timers, "\n") end
    
    if msg == "" then
        notify("Bosses", "No bosses found or timers visible.", 3)
    else
        notify("Bosses", msg, 6)
    end
end)

addButton(bossTab, "Debug: List All Enemies (F9)", function()
    local names = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Health > 0 then
            table.insert(names, (obj.Parent and obj.Parent.Name or "Unknown") .. " [" .. obj.DisplayName .. "]")
        end
    end
    print("[FA Hub Debug] Enemies found: \n" .. table.concat(names, "\n"))
    notify("Debug", "List printed to F9 Console", 3)
end)

-- ── FRUIT TAB ────────────────────────────────────────────────
local fruitTab = createTab("Fruit", "🍎")

makeSection(fruitTab.scroll, "Gacha", nextOrder(fruitTab.scroll.Name))

addToggle(fruitTab, "Auto Fruit Roll", false, function(v)
    autoFruitRoll = v
end)

addToggle(fruitTab, "Auto Store Fruit", false, function(v)
    autoStoreFruit = v
end)

addButton(fruitTab, "Roll Fruit Now", function()
    local res = CommF_:InvokeServer("Cousin", "Buy")
    if res then notify("Gacha", tostring(res), 5) end
end)

-- ── PLAYER TAB ───────────────────────────────────────────────
local playerTab = createTab("Player", "👤")

makeSection(playerTab.scroll, "Movement", nextOrder(playerTab.scroll.Name))

addSlider(playerTab, "Walk Speed", 16, 325, 16, " sp", function(v)
    SetWalkSpeed = v
end)

addToggle(playerTab, "Infinite Jump", false, function(v)
    infJumpEnabled = v
end)

addToggle(playerTab, "Walk on Water", false, function(v)
    waterWalk.CanCollide = v
end)

makeSection(playerTab.scroll, "Stats", nextOrder(playerTab.scroll.Name))

addDropdown(playerTab, "Stat to Add", {"Melee","Defense","Sword","Gun","Demon Fruit"}, "Melee", function(v)
    selectedStat = v
end)

addSlider(playerTab, "Stat Amount", 1, 10, 1, "", function(v)
    addAmount = v
end)

addToggle(playerTab, "Auto Stats", false, function(v)
    autoStats = v
end)

-- ── MISC TAB ─────────────────────────────────────────────────
local miscTab = createTab("Misc", "⚙")

makeSection(miscTab.scroll, "UI Settings", nextOrder(miscTab.scroll.Name))

addKeybind(miscTab, "UI Toggle Hotkey", UIHotkey, function(v)
    UIHotkey = v
end)

makeSection(miscTab.scroll, "Utilities", nextOrder(miscTab.scroll.Name))

addButton(miscTab, "Toggle Damage UI", function()
    local dc = ReplicatedStorage:FindFirstChild("Assets")
        and ReplicatedStorage.Assets:FindFirstChild("GUI")
        and ReplicatedStorage.Assets.GUI:FindFirstChild("DamageCounter")
    if dc then
        dc.Enabled = not dc.Enabled
        notify("UI", "Damage counter " .. (dc.Enabled and "enabled" or "disabled"), 2)
    end
end)

addButton(miscTab, "Toggle Notifications", function()
    local n = Player.PlayerGui:FindFirstChild("Notifications")
    if n then
        n.Enabled = not n.Enabled
        notify("UI", "Notifications " .. (n.Enabled and "enabled" or "disabled"), 2)
    end
end)

addButton(miscTab, "Redeem All Codes", function()
    notify("Codes", "Redeeming all codes…", 3)
    task.spawn(function()
        local ok, raw = pcall(function()
            return game:HttpGet("https://pastebin.com/raw/cLp2LXrs")
        end)
        if not ok then notify("Codes", "Failed to fetch code list", 3); return end
        local redeemRemote = Remotes:FindFirstChild("Redeem")
        if not redeemRemote then notify("Codes", "Redeem remote not found", 3); return end
        local count = 0
        for code in raw:gmatch("[^\r\n]+") do
            pcall(function() redeemRemote:InvokeServer(code) end)
            count += 1
        end
        notify("Codes", "Redeemed " .. count .. " code(s)!", 3)
    end)
end)

addButton(miscTab, "Fast Mode (Reduce Lag)", function()
    local Lighting = game:GetService("Lighting")
    local Terrain  = workspace:FindFirstChildOfClass("Terrain")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material    = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow  = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        end
    end
    Lighting.GlobalShadows            = false
    Lighting.FogEnd                   = 9e9
    Lighting.Brightness               = 1
    Lighting.EnvironmentSpecularScale = 0
    Lighting.EnvironmentDiffuseScale  = 0
    if Terrain then
        Terrain.WaterWaveSize     = 0
        Terrain.WaterWaveSpeed    = 0
        Terrain.WaterTransparency = 1
        Terrain.WaterReflectance  = 0
    end
    notify("Fast Mode", "Performance optimised!", 3)
end)

addToggle(miscTab, "Anti AFK", false, function(v)
    if v then
        Player.Idled:Connect(function()
            game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
        end)
    end
end)

makeSection(miscTab.scroll, "Session", nextOrder(miscTab.scroll.Name))

addButton(miscTab, "Rejoin", function()
    pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet('https://pastebin.com/raw/TAxQY7uz'))()]])
    end)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

addButton(miscTab, "Server Hop", function()
    pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet('https://pastebin.com/raw/TAxQY7uz'))()]])
    end)
    local servers = getServers(game.PlaceId)
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], Player)
    else
        TeleportService:Teleport(game.PlaceId, Player)
    end
end)

addButton(miscTab, "Unload FA Hub", function()
    autoRaid         = false
    autofarm         = false
    autoAttack       = false
    autoStats        = false
    chestFarmEnabled = false
    removeFloat()
    if ActiveTween then ActiveTween:Cancel(); ActiveTween = nil end
    if workspace:FindFirstChild("FAHubWaterWalk") then
        workspace.FAHubWaterWalk:Destroy()
    end
    for _, obj in ipairs(Character:GetChildren()) do
        if obj:IsA("Highlight") then obj:Destroy() end
    end
    _G.FAHubLoaded = nil
    DisconnectAll()
    ScreenGui:Destroy()
end)

-- ── Activate default tab ──────────────────────────────────────
tabs[1].btn.MouseButton1Click:Fire()

notify("FA Hub", "Loaded successfully!", 3)
