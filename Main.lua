-- Grow-a-Garden Script Otimizado - Versão Reduzida
-- Sem carregamentos externos - Interface nativa
-- Todas as funções mantidas

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

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

-- Sistema de Notificação Simples
local function createNotification(title, message, duration)
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "GardenNotification"
    notifGui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = frame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 35)
    messageLabel.Position = UDim2.new(0, 10, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextScaled = true
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.Parent = frame
    
    -- Animação de entrada
    frame.Position = UDim2.new(1, 20, 0, 20)
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(1, -320, 0, 20)})
    tweenIn:Play()
    
    -- Remover após duração
    task.wait(duration or 2)
    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 20, 0, 20)})
    tweenOut:Play()
    tweenOut.Completed:Connect(function()
        notifGui:Destroy()
    end)
end

-- Interface Principal
local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GardenScriptGUI"
    screenGui.Parent = CoreGui
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 40)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌱 Grow-a-Garden Script v2.0"
    titleLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- Botão Fechar
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Container principal
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -70)
    contentFrame.Position = UDim2.new(0, 10, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 6
    contentFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = contentFrame
    
    -- Função para criar botões
    local function createButton(text, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.Gotham
        button.Parent = contentFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(callback)
        return button
    end
    
    -- Função para criar toggle
    local function createToggle(text, callback, default)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 40)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        toggleFrame.Parent = contentFrame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggleFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 40, 0, 25)
        toggleButton.Position = UDim2.new(1, -50, 0.5, -12.5)
        toggleButton.BackgroundColor3 = default and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
        toggleButton.Text = default and "ON" or "OFF"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.TextScaled = true
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.Parent = toggleFrame
        
        local toggleButtonCorner = Instance.new("UICorner")
        toggleButtonCorner.CornerRadius = UDim.new(0, 4)
        toggleButtonCorner.Parent = toggleButton
        
        local isOn = default or false
        toggleButton.MouseButton1Click:Connect(function()
            isOn = not isOn
            toggleButton.Text = isOn and "ON" or "OFF"
            toggleButton.BackgroundColor3 = isOn and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
            callback(isOn)
        end)
        
        return toggleFrame
    end
    
    -- Função para criar dropdown
    local function createDropdown(text, options, callback, default)
        local dropdownFrame = Instance.new("Frame")
        dropdownFrame.Size = UDim2.new(1, 0, 0, 40)
        dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownFrame.Parent = contentFrame
        
        local dropdownCorner = Instance.new("UICorner")
        dropdownCorner.CornerRadius = UDim.new(0, 6)
        dropdownCorner.Parent = dropdownFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = dropdownFrame
        
        local dropdown = Instance.new("TextButton")
        dropdown.Size = UDim2.new(0.55, 0, 0, 30)
        dropdown.Position = UDim2.new(0.4, 10, 0.5, -15)
        dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        dropdown.Text = default or options[1]
        dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdown.TextScaled = true
        dropdown.Font = Enum.Font.Gotham
        dropdown.Parent = dropdownFrame
        
        local dropdownButtonCorner = Instance.new("UICorner")
        dropdownButtonCorner.CornerRadius = UDim.new(0, 4)
        dropdownButtonCorner.Parent = dropdown
        
        local isOpen = false
        local optionsFrame = Instance.new("Frame")
        optionsFrame.Size = UDim2.new(0.55, 0, 0, #options * 30)
        optionsFrame.Position = UDim2.new(0.4, 10, 1, 5)
        optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        optionsFrame.Visible = false
        optionsFrame.Parent = dropdownFrame
        
        local optionsCorner = Instance.new("UICorner")
        optionsCorner.CornerRadius = UDim.new(0, 4)
        optionsCorner.Parent = optionsFrame
        
        local optionsLayout = Instance.new("UIListLayout")
        optionsLayout.Parent = optionsFrame
        
        for _, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, 0, 0, 30)
            optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.TextScaled = true
            optionButton.Font = Enum.Font.Gotham
            optionButton.Parent = optionsFrame
            
            optionButton.MouseButton1Click:Connect(function()
                dropdown.Text = option
                optionsFrame.Visible = false
                isOpen = false
                callback(option)
            end)
        end
        
        dropdown.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            optionsFrame.Visible = isOpen
        end)
        
        return dropdownFrame
    end
    
    -- Criar elementos da interface
    createButton("📍 Definir Posição de Plantio", function()
        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            plant_position = rootPart.Position
            local posStr = string.format("%.0f, %.0f, %.0f", plant_position.X, plant_position.Y, plant_position.Z)
            task.spawn(createNotification, "Posição Definida", "Nova posição: " .. posStr, 2)
        else
            task.spawn(createNotification, "Erro", "Personagem não encontrado", 2)
        end
    end)
    
    createDropdown("🌱 Seleção de Semente:", AVAILABLE_SEEDS, function(option)
        selected_seed = option
        if settings.debug_mode then
            print("Semente selecionada:", option)
        end
    end, "Carrot")
    
    createToggle("🚀 Auto Plantar", function(state)
        is_auto_planting = state
        if state then
            task.spawn(autoPlantSeedsOptimized, selected_seed)
            task.spawn(createNotification, "Auto Plantar", "Ativado", 1)
        else
            task.spawn(createNotification, "Auto Plantar", "Desativado", 1)
        end
    end, false)
    
    createToggle("🍎 Auto Coletar", function(state)
        is_auto_collecting = state
        if state then
            task.spawn(autoCollectFruitsOptimized)
            task.spawn(createNotification, "Auto Coletar", "Ativado", 1)
        else
            task.spawn(createNotification, "Auto Coletar", "Desativado", 1)
        end
    end, false)
    
    createToggle("💰 Compra Automática", function(state)
        settings.auto_buy_seeds = state
    end, settings.auto_buy_seeds)
    
    createToggle("📏 Verificação de Distância", function(state)
        settings.use_distance_check = state
    end, settings.use_distance_check)
    
    createToggle("🎯 Coletar Fruta Mais Próxima", function(state)
        settings.collect_nearest_fruit = state
    end, settings.collect_nearest_fruit)
    
    createToggle("🐛 Modo Debug", function(state)
        settings.debug_mode = state
    end, settings.debug_mode)
    
    -- Ajustar tamanho do scroll
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    
    return screenGui
end

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
function autoCollectFruitsOptimized()
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
function autoPlantSeedsOptimized(seedName)
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

-- Criar interface
local gui = createMainGUI()

-- Notificação de carregamento
task.spawn(createNotification, "Script Carregado!", "Grow-a-Garden v2.0 - Versão Otimizada!", 3)

print("🌱 Grow-a-Garden Script v2.0 carregado com sucesso!")
print("📋 Todas as funções mantidas sem carregamentos externos")
print("🚀 Interface nativa do Roblox para melhor performance")
