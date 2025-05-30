-- Grow-a-Garden Script Otimizado
-- Versão 2.0 - Código limpo e otimizado

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DragonSCRIPTS/Meu_jardim-_script/refs/heads/main/Code"))()
WindUI:SetNotificationLower(true)
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/notification_gui_library.lua", true))()

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Variáveis principais
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

-- Eventos do jogo
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local buySeedEvent = GameEvents:WaitForChild("BuySeedStock")
local plantSeedEvent = GameEvents:WaitForChild("Plant_RE")

-- Configurações otimizadas
local settings = {
    auto_buy_seeds = true,
    use_distance_check = true,
    collection_distance = 17,
    collect_nearest_fruit = true,
    debug_mode = false,
    plant_delay = 0.1,
    collect_delay = 0.05,
    loop_delay = 0.2
}

-- Variáveis de estado
local plant_position = nil
local selected_seed = "Carrot"
local is_auto_planting = false
local is_auto_collecting = false

-- Lista de sementes disponíveis
local AVAILABLE_SEEDS = {
    'Carrot', 'Strawberry', 'Blueberry', 'Orange Tulip', 'Tomato', 
    'Corn', 'Watermelon', 'Daffodil', 'Pumpkin', 'Apple', 'Bamboo', 
    'Coconut', 'Cactus', 'Dragon Fruit', 'Mango', 'Grape', 'Mushroom', 
    'Pepper', 'Cacao', 'Beanstalk'
}

-- Temas disponíveis
local THEMES = {'Rose', 'Indigo', 'Plant', 'Red', 'Light', 'Dark'}

-- Criação da interface otimizada
local Window = WindUI:CreateWindow({
    Title = "Grow-a-Garden Script",
    Icon = "banana",
    Folder = "GardenScript",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            local curTheme = WindUI:GetCurrentTheme()
            local themeIndex = table.find(THEMES, curTheme)
            local nextIndex = (themeIndex == #THEMES) and 1 or (themeIndex + 1)
            WindUI:SetTheme(THEMES[nextIndex])
        end,
    }
})

-- Função otimizada para encontrar a fazenda do player
local function getPlayerFarm()
    local farm = workspace.Farm:FindFirstChild(localPlayer.Name)
    if farm then return farm end
    
    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        if important then
            local data = important:FindFirstChild("Data")
            if data then
                local owner = data:FindFirstChild("Owner")
                if owner and owner.Value == localPlayer.Name then
                    return farm
                end
            end
        end
    end
    return nil
end

-- Função otimizada para comprar sementes
local function buySeed(seedName)
    local seedShop = playerGui:FindFirstChild("Seed_Shop")
    if not seedShop then return false end
    
    local frame = seedShop:FindFirstChild("Frame")
    if not frame then return false end
    
    local scrollingFrame = frame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return false end
    
    local seedButton = scrollingFrame:FindFirstChild(seedName)
    if not seedButton then return false end
    
    local mainFrame = seedButton:FindFirstChild("Main_Frame")
    if not mainFrame then return false end
    
    local costText = mainFrame:FindFirstChild("Cost_Text")
    if costText and costText.TextColor3 ~= Color3.fromRGB(255, 0, 0) then
        if settings.debug_mode then
            print("Comprando semente:", seedName)
        end
        buySeedEvent:FireServer(seedName)
        return true
    end
    return false
end

-- Função otimizada para equipar sementes
local function equipSeed(seedName)
    local character = localPlayer.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    -- Verifica se já está equipado
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if equippedTool and equippedTool:GetAttribute("ITEM_TYPE") == "Seed" and equippedTool:GetAttribute("Seed") == seedName then
        return equippedTool
    end

    -- Procura na mochila
    for _, item in ipairs(localPlayer.Backpack:GetChildren()) do
        if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == seedName then
            humanoid:EquipTool(item)
            task.wait(0.1)
            
            local newEquippedTool = character:FindFirstChildOfClass("Tool")
            if newEquippedTool and newEquippedTool:GetAttribute("ITEM_TYPE") == "Seed" and newEquippedTool:GetAttribute("Seed") == seedName then
                return newEquippedTool
            end
        end
    end
    
    return nil
end

-- Função otimizada para coletar frutas
local function autoCollectFruitsOptimized()
    while is_auto_collecting do
        if not is_auto_collecting then break end

        local character = localPlayer.Character
        local playerRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local currentFarm = getPlayerFarm()

        if not (playerRootPart and currentFarm) then
            if settings.debug_mode then
                print("Player, fazenda ou plantas não encontrados")
            end
            task.wait(0.5)
            continue
        end

        local plantsPhysical = currentFarm:FindFirstChild("Important")
        plantsPhysical = plantsPhysical and plantsPhysical:FindFirstChild("Plants_Physical")
        
        if not plantsPhysical then
            task.wait(0.5)
            continue
        end

        local collectedThisLoop = false

        if settings.collect_nearest_fruit then
            local nearestPrompt = nil
            local minDistance = math.huge

            for _, plant in ipairs(plantsPhysical:GetChildren()) do
                if not is_auto_collecting then break end
                
                for _, descendant in ipairs(plant:GetDescendants()) do
                    if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.Parent then
                        local distance = (playerRootPart.Position - descendant.Parent.Position).Magnitude
                        
                        local canCollect = not settings.use_distance_check or distance <= settings.collection_distance
                        
                        if canCollect and distance < minDistance then
                            minDistance = distance
                            nearestPrompt = descendant
                        end
                    end
                end
            end

            if nearestPrompt then
                if settings.debug_mode then
                    print("Coletando fruta mais próxima a", math.floor(minDistance), "studs")
                end
                fireproximityprompt(nearestPrompt)
                collectedThisLoop = true
                task.wait(settings.collect_delay)
            end
        else
            for _, plant in ipairs(plantsPhysical:GetChildren()) do
                if not is_auto_collecting then break end
                
                for _, fruitPrompt in ipairs(plant:GetDescendants()) do
                    if fruitPrompt:IsA("ProximityPrompt") and fruitPrompt.Enabled and fruitPrompt.Parent then
                        local canCollect = true
                        
                        if settings.use_distance_check then
                            local distance = (playerRootPart.Position - fruitPrompt.Parent.Position).Magnitude
                            canCollect = distance <= settings.collection_distance
                        end

                        if canCollect then
                            fireproximityprompt(fruitPrompt)
                            collectedThisLoop = true
                            task.wait(settings.collect_delay)
                        end
                    end
                end
            end
        end

        task.wait(collectedThisLoop and settings.loop_delay or 0.1)
    end
end

-- Função otimizada para plantar sementes
local function autoPlantSeedsOptimized(seedName)
    while is_auto_planting do
        if not is_auto_planting then break end
        
        local seedInHand = equipSeed(seedName)

        if not seedInHand and settings.auto_buy_seeds then
            if buySeed(seedName) then
                task.wait(0.2)
                seedInHand = equipSeed(seedName)
            end
        end
        
        if seedInHand and plant_position then
            local quantity = seedInHand:GetAttribute("Quantity")
            if quantity and quantity > 0 then
                if settings.debug_mode then
                    print("Plantando", seedName, "- Quantidade:", quantity)
                end
                
                plantSeedEvent:FireServer(plant_position, seedName)
                task.wait(settings.plant_delay)
            else
                if settings.debug_mode then
                    print("Sem sementes disponíveis:", seedName)
                end
                task.wait(1)
            end
        else
            if settings.debug_mode then
                print("Não foi possível equipar semente ou posição não definida")
            end
            task.wait(1)
        end
        
        task.wait(settings.loop_delay)
    end
end

-- Inicialização da posição de plantio
local function initializePlantPosition()
    local farm = getPlayerFarm()
    if farm then
        local important = farm:FindFirstChild("Important")
        if important then
            local plantLocations = important:FindFirstChild("Plant_Locations")
            if plantLocations then
                local defaultLocation = plantLocations:FindFirstChildOfClass("Part")
                if defaultLocation then
                    plant_position = defaultLocation.Position
                    return
                end
            end
        end
    end
    
    plant_position = Vector3.new(0, 0, 0)
    warn("Posição padrão de plantio não encontrada")
end

-- Inicialização
initializePlantPosition()

-- Criação das abas
local TabMain = Window:Tab({
    Title = "Principal",
    Icon = "rbxassetid://124620632231839",
    Locked = false,
})

local TabSettings = Window:Tab({
    Title = "Configurações",
    Icon = "rbxassetid://96957318452720",
    Locked = false,
})

Window:SelectTab(1)

-- Interface Principal
local ButtonSetPos = TabMain:Button({
    Title = "Definir Posição de Plantio",
    Desc = "Define a posição onde as sementes serão plantadas",
    Locked = false,
    Callback = function()
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            plant_position = rootPart.Position
            local posStr = string.format("%.0f, %.0f, %.0f", plant_position.X, plant_position.Y, plant_position.Z)
            Notification.new("info", "Posição Definida", "Nova posição: " .. posStr):deleteTimeout(2)
        else
            Notification.new("error", "Erro", "Personagem não encontrado"):deleteTimeout(2)
        end
    end
})

local DropdownSeed = TabMain:Dropdown({
    Title = "Seleção de Semente",
    Values = AVAILABLE_SEEDS,
    Value = "Carrot",
    Multi = false,
    AllowNone = false,
    Callback = function(option) 
        selected_seed = option
        if settings.debug_mode then
            print("Semente selecionada:", option)
        end
    end
})

local ToggleAutoPlant = TabMain:Toggle({
    Title = "Auto Plantar",
    Desc = "Planta automaticamente as sementes selecionadas",
    Default = false,
    Callback = function(state) 
        is_auto_planting = state
        if state then
            task.spawn(autoPlantSeedsOptimized, selected_seed)
            Notification.new("success", "Auto Plantar", "Ativado"):deleteTimeout(1)
        else
            Notification.new("info", "Auto Plantar", "Desativado"):deleteTimeout(1)
        end
    end
})

local ToggleAutoCollect = TabMain:Toggle({
    Title = "Auto Coletar",
    Desc = "Coleta automaticamente frutas das plantas",
    Default = false,
    Callback = function(state) 
        is_auto_collecting = state
        if state then
            task.spawn(autoCollectFruitsOptimized)
            Notification.new("success", "Auto Coletar", "Ativado"):deleteTimeout(1)
        else
            Notification.new("info", "Auto Coletar", "Desativado"):deleteTimeout(1)
        end
    end
})

-- Interface de Configurações
local ToggleAutoBuy = TabSettings:Toggle({
    Title = "Compra Automática",
    Desc = "Compra automaticamente sementes quando acabarem",
    Default = settings.auto_buy_seeds,
    Callback = function(state) 
        settings.auto_buy_seeds = state
    end
})

local ToggleDistCheck = TabSettings:Toggle({
    Title = "Verificação de Distância",
    Desc = "Coleta apenas frutas dentro de uma distância específica",
    Default = settings.use_distance_check,
    Callback = function(state) 
        settings.use_distance_check = state
    end
})

local ToggleNearestFruit = TabSettings:Toggle({
    Title = "Coletar Fruta Mais Próxima",
    Desc = "Prioriza a coleta da fruta mais próxima",
    Default = settings.collect_nearest_fruit,
    Callback = function(state) 
        settings.collect_nearest_fruit = state
    end
})

local SliderDistance = TabSettings:Slider({
    Title = "Distância de Coleta",
    Desc = "Distância máxima para coletar frutas",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 50,
        Default = settings.collection_distance,
    },
    Callback = function(value)
        settings.collection_distance = value
    end
})

local SliderPlantDelay = TabSettings:Slider({
    Title = "Delay de Plantio",
    Desc = "Tempo de espera entre plantios (em segundos)",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 1,
        Default = settings.plant_delay,
    },
    Callback = function(value)
        settings.plant_delay = value
    end
})

local SliderCollectDelay = TabSettings:Slider({
    Title = "Delay de Coleta",
    Desc = "Tempo de espera entre coletas (em segundos)",
    Step = 0.01,
    Value = {
        Min = 0.01,
        Max = 0.5,
        Default = settings.collect_delay,
    },
    Callback = function(value)
        settings.collect_delay = value
    end
})

local ToggleDebug = TabSettings:Toggle({
    Title = "Modo Debug",
    Desc = "Ativa logs de debug no console",
    Icon = "bug",
    Default = settings.debug_mode,
    Callback = function(state) 
        settings.debug_mode = state
    end
})

-- Notificação de carregamento
Notification.new("success", "Script Carregado!", "Grow-a-Garden v2.0 - Otimizado e pronto para uso!"):deleteTimeout(3)
