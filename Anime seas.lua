-- Mizzy Hub Fluent Edition by ayoei(4awty) & yslx0
-- Multi-seleção de mobs, detecção automática de mobs ao trocar de mundo/mapa, AutoFarm, AutoPunch, Killaura, GUIs, Discord, Destroy GUI

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Window = Fluent:CreateWindow({
    Title = "Mizzy Hub | Fluent",
    SubTitle = "by ayoei(4awty) & yslx0",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Auto = Window:AddTab({ Title = "Auto", Icon = "zap" }),
    GUIs = Window:AddTab({ Title = "GUIs", Icon = "layout-dashboard" }),
    Utils = Window:AddTab({ Title = "Utilidades", Icon = "tool" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

----------------------[ MOBS DINÂMICOS ]---------------------
local mobsFolderPath = {"Client", "Maps", "Demon Slayer", "Mobs"} -- Caminho padrão
local mobsFolder = nil
local mobNames = {}
local function getMobsFolder()
    local mapsFolder = workspace:FindFirstChild("Client") and workspace.Client:FindFirstChild("Maps")
    if not mapsFolder then return nil end
    for _, map in ipairs(mapsFolder:GetChildren()) do
        if map:FindFirstChild("Mobs") then
            mobsFolder = map.Mobs
            return mobsFolder, map.Name
        end
    end
    return nil
end

local function updateMobNames()
    mobNames = {}
    local folder, worldName = getMobsFolder()
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") then
                table.insert(mobNames, mob.Name)
            end
        end
        table.sort(mobNames)
    end
end

updateMobNames()
local selectedMobs = {}

----------------------[ AUTOFARM MULTI MOB ]---------------------
local autoFarmEnabled = false
local autoFarmLoop = nil

local function getMobsByNames(names)
    local folder = mobsFolder or getMobsFolder()
    local mobs = {}
    if folder then
        for _, mob in ipairs(folder:GetChildren()) do
            for _, name in ipairs(names) do
                if mob.Name == name then
                    table.insert(mobs, mob)
                end
            end
        end
    end
    return mobs
end

local function getMobMainPart(mob)
    local main = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChild("Head")
    if main and main:IsA("BasePart") then return main end
    for _, part in ipairs(mob:GetChildren()) do
        if part:IsA("BasePart") then return part end
    end
    return nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
        if autoFarmEnabled then
            autoFarmEnabled = false
            Fluent:Notify({Title="AutoFarm",Content="AutoFarm desligado pela tecla K!",Duration=3})
        end
    end
end)

local function autoFarm()
    while autoFarmEnabled do
        local mobs = getMobsByNames(selectedMobs)
        for _, mob in ipairs(mobs) do
            if not autoFarmEnabled then return end
            if mob and mob.Parent then
                local mobPart = getMobMainPart(mob)
                local humanoid = mob:FindFirstChildOfClass("Humanoid")
                while mob and mob.Parent and humanoid and humanoid.Health > 0 and autoFarmEnabled do
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and mobPart then
                        player.Character.HumanoidRootPart.CFrame = mobPart.CFrame + Vector3.new(0,5,0)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end
                    task.wait(0.12)
                    humanoid = mob:FindFirstChildOfClass("Humanoid")
                end
            end
            if not autoFarmEnabled then break end
            task.wait(0.1)
        end
        task.wait(0.2)
    end
end

local mobDropdown = Tabs.Auto:AddDropdown("MobMultiDropdown", {
    Title = "Mobs para farmar (multi-seleção)",
    Description = "Escolha um ou vários mobs para autofarm. Se mudar de mundo, clique em 'Detectar Novos Mobs'.",
    Values = mobNames,
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedMobs = {}
        if typeof(values) == "table" then
            if #values > 0 then
                selectedMobs = values
            else
                for name, state in pairs(values) do
                    if state then table.insert(selectedMobs, name) end
                end
            end
        end
    end
})

Tabs.Auto:AddButton({
    Title = "Detectar Novos Mobs",
    Description = "Atualiza a lista de mobs automaticamente para o mapa/mundo atual.",
    Callback = function()
        updateMobNames()
        mobDropdown:SetValues(mobNames)
        Fluent:Notify({Title="Mobs Atualizados",Content="Mobs recarregados para o novo mapa.",Duration=3})
    end
})

Tabs.Auto:AddToggle("AutoFarmToggle", {
    Title = "AutoFarm Mobs Selecionados",
    Default = false,
    Callback = function(state)
        autoFarmEnabled = state
        if autoFarmEnabled then
            Fluent:Notify({Title="AutoFarm",Content="AutoFarm ativado!",Duration=2})
            autoFarmLoop = task.spawn(autoFarm)
        else
            if autoFarmLoop then
                task.cancel(autoFarmLoop)
            end
            Fluent:Notify({Title="AutoFarm",Content="AutoFarm desligado!",Duration=2})
        end
    end
})

Tabs.Auto:AddParagraph({
    Title = "AutoFarm Hotkeys",
    Content = "Pressione a tecla K para desligar o AutoFarm instantaneamente.\nO AutoFarm já clica automaticamente!"
})

----------------------[ AUTOPUNCH ]---------------------
local autoPunchEnabled = false
local autoPunchLoop = nil

Tabs.Auto:AddToggle("AutoPunchToggle", {
    Title = "AutoPunch (clique automático independente de mob)",
    Default = false,
    Callback = function(state)
        autoPunchEnabled = state
        if autoPunchEnabled then
            Fluent:Notify({Title="AutoPunch", Content="AutoPunch ativado! Executando cliques automaticamente.", Duration=2})
            autoPunchLoop = task.spawn(function()
                while autoPunchEnabled do
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.12)
                end
            end)
        else
            if autoPunchLoop then
                task.cancel(autoPunchLoop)
            end
            Fluent:Notify({Title="AutoPunch", Content="AutoPunch desligado!", Duration=2})
        end
    end
})

----------------------[ KILLAURA ]---------------------
local killauraEnabled = false

Tabs.Auto:AddToggle("KillauraToggle", {
    Title = "Killaura (Pressione 5 para ativar)",
    Default = false,
    Callback = function(state)
        killauraEnabled = state
        if killauraEnabled then
            Fluent:Notify({Title="Killaura", Content="Killaura ativada! Pressione 5 para matar todos os mobs.", Duration=3})
        else
            Fluent:Notify({Title="Killaura", Content="Killaura desativada.", Duration=2})
        end
    end
})

local function killAllMobs()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") then
            local character = obj.Parent
            if character and not Players:GetPlayerFromCharacter(character) then
                obj.Health = 0
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if killauraEnabled and input.KeyCode == Enum.KeyCode.Five then
        killAllMobs()
        Fluent:Notify({Title="Killaura", Content="Todos os mobs foram mortos!", Duration=2})
    end
end)

----------------------[ DESTROY GUI ]---------------------
Tabs.Auto:AddButton({
    Title = "Destroy GUI",
    Description = "Fecha e remove completamente a interface da tela.",
    Callback = function()
        if Window and Window.Destroy then
            Window:Destroy()
        elseif Window and Window.Main and Window.Main.Parent then
            Window.Main.Parent:Destroy()
        end
    end
})

----------------------[ GUIs/TELEPORTS ]---------------------
local Interact = nil
local function findInteract()
    local mapsFolder = workspace:FindFirstChild("Client") and workspace.Client:FindFirstChild("Maps")
    if not mapsFolder then return nil end
    for _, map in ipairs(mapsFolder:GetChildren()) do
        if map:FindFirstChild("Interact") then
            return map.Interact
        end
    end
    return nil
end

Interact = findInteract()

local function teleportTo(guiObj)
    if guiObj and guiObj:IsA("BasePart") then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = guiObj.CFrame + Vector3.new(0,5,0)
        end
    end
end

local function addGuiButton(tab, name, gui)
    tab:AddButton({
        Title = name,
        Description = "Teleporta até " .. name .. " no mapa.",
        Callback = function()
            teleportTo(gui)
            if gui and gui.Visible ~= nil then
                gui.Visible = true
            elseif gui and gui.Enabled ~= nil then
                gui.Enabled = true
            end
        end
    })
end

if Interact then
    addGuiButton(Tabs.GUIs, "Missions", Interact:FindFirstChild("Missions"))
    addGuiButton(Tabs.GUIs, "Marks", Interact:FindFirstChild("Marks"))
    addGuiButton(Tabs.GUIs, "Ranks", Interact:FindFirstChild("Ranks"))
    addGuiButton(Tabs.GUIs, "Teleport", Interact:FindFirstChild("Teleport"))
    addGuiButton(Tabs.GUIs, "Verification", Interact:FindFirstChild("Verification"))
else
    Tabs.GUIs:AddParagraph({ Title = "GUIs não encontradas na Interact!", Content = "" })
end

----------------------[ DISCORD ]---------------------
local function copyToClipboard(str)
    if setclipboard then
        setclipboard(str)
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(str)
    elseif Clipboard then
        Clipboard.set(str)
    else
        Fluent:Notify({
            Title = "Discord",
            Content = "Link: " .. str .. "\nCopie manualmente!",
            Duration = 10
        })
    end
end

Tabs.GUIs:AddButton({
    Title = "Discord",
    Description = "Copia o link do Discord automaticamente para sua área de transferência.",
    Callback = function()
        local link = "https://discord.gg/rMxfgQDUNw"
        copyToClipboard(link)
        Fluent:Notify({
            Title = "Discord",
            Content = "Link copiado para a área de transferência!",
            Duration = 5
        })
    end
})

----------------------[ SETTINGS: Fluent Addons ]---------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
Fluent:Notify({
    Title = "Fluent",
    Content = "O script foi carregado.",
    Duration = 8
})
SaveManager:LoadAutoloadConfig()
