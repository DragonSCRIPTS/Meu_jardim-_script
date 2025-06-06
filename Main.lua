-- Grow-a-Garden Script Ultra Compacto v2.1
-- Todas as funções mantidas - Código reduzido em 60%

local P,RS,UIS,RUN,CG,TS = game:GetService("Players"),game:GetService("ReplicatedStorage"),game:GetService("UserInputService"),game:GetService("RunService"),game:GetService("CoreGui"),game:GetService("TweenService")
local lp,pg = P.LocalPlayer,P.LocalPlayer.PlayerGui
local GE = RS:WaitForChild("GameEvents")
local buyEvent,plantEvent = GE:WaitForChild("BuySeedStock"),GE:WaitForChild("Plant_RE")

-- Config
local cfg = {auto_buy=true,use_dist=true,dist=17,near_fruit=true,debug=false,plant_delay=0.1,collect_delay=0.05,loop_delay=0.2}
local pp,ss,ap,ac = nil,"Carrot",false,false
local SEEDS = {'Carrot','Strawberry','Blueberry','Orange Tulip','Tomato','Corn','Watermelon','Daffodil','Pumpkin','Apple','Bamboo','Coconut','Cactus','Dragon Fruit','Mango','Grape','Mushroom','Pepper','Cacao','Beanstalk'}

-- Utils
local function notify(t,m,d)
    local sg = Instance.new("ScreenGui")
    sg.Name,sg.Parent = "GN",CG
    local f = Instance.new("Frame")
    f.Size,f.Position,f.BackgroundColor3,f.BorderSizePixel,f.Parent = UDim2.new(0,300,0,80),UDim2.new(1,-320,0,20),Color3.fromRGB(40,40,40),0,sg
    local c = Instance.new("UICorner")
    c.CornerRadius,c.Parent = UDim.new(0,8),f
    local tl = Instance.new("TextLabel")
    tl.Size,tl.Position,tl.BackgroundTransparency,tl.Text,tl.TextColor3,tl.TextScaled,tl.Font,tl.Parent = UDim2.new(1,-20,0,30),UDim2.new(0,10,0,5),1,t,Color3.fromRGB(255,255,255),true,Enum.Font.GothamBold,f
    local ml = Instance.new("TextLabel")
    ml.Size,ml.Position,ml.BackgroundTransparency,ml.Text,ml.TextColor3,ml.TextScaled,ml.Font,ml.Parent = UDim2.new(1,-20,0,35),UDim2.new(0,10,0,35),1,m,Color3.fromRGB(200,200,200),true,Enum.Font.Gotham,f
    f.Position = UDim2.new(1,20,0,20)
    TS:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Back),{Position=UDim2.new(1,-320,0,20)}):Play()
    task.wait(d or 2)
    local to = TS:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Position=UDim2.new(1,20,0,20)})
    to:Play()
    to.Completed:Connect(function() sg:Destroy() end)
end

local function getFarm()
    local f = workspace.Farm:FindFirstChild(lp.Name)
    if f then return f end
    for _,farm in ipairs(workspace.Farm:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        if imp then
            local d = imp:FindFirstChild("Data")
            if d then
                local o = d:FindFirstChild("Owner")
                if o and o.Value == lp.Name then return farm end
            end
        end
    end
    return nil
end

local function buySeed(sn)
    local ss = pg:FindFirstChild("Seed_Shop")
    if not ss then return false end
    local f = ss:FindFirstChild("Frame")
    if not f then return false end
    local sf = f:FindFirstChild("ScrollingFrame")
    if not sf then return false end
    local sb = sf:FindFirstChild(sn)
    if not sb then return false end
    local mf = sb:FindFirstChild("Main_Frame")
    if not mf then return false end
    local ct = mf:FindFirstChild("Cost_Text")
    if ct and ct.TextColor3 ~= Color3.fromRGB(255,0,0) then
        if cfg.debug then print("Comprando:",sn) end
        buyEvent:FireServer(sn)
        return true
    end
    return false
end

local function equipSeed(sn)
    local c = lp.Character
    if not c then return nil end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return nil end
    local et = c:FindFirstChildOfClass("Tool")
    if et and et:GetAttribute("ITEM_TYPE") == "Seed" and et:GetAttribute("Seed") == sn then return et end
    for _,item in ipairs(lp.Backpack:GetChildren()) do
        if item:GetAttribute("ITEM_TYPE") == "Seed" and item:GetAttribute("Seed") == sn then
            h:EquipTool(item)
            task.wait(0.1)
            local net = c:FindFirstChildOfClass("Tool")
            if net and net:GetAttribute("ITEM_TYPE") == "Seed" and net:GetAttribute("Seed") == sn then return net end
        end
    end
    return nil
end

function autoCollectFruitsOptimized()
    while ac do
        if not ac then break end
        local c = lp.Character
        local prp = c and c:FindFirstChild("HumanoidRootPart")
        local cf = getFarm()
        if not (prp and cf) then
            if cfg.debug then print("Player/fazenda não encontrados") end
            task.wait(0.5)
            continue
        end
        local pp = cf:FindFirstChild("Important")
        pp = pp and pp:FindFirstChild("Plants_Physical")
        if not pp then task.wait(0.5) continue end
        local collected = false
        if cfg.near_fruit then
            local np,md = nil,math.huge
            for _,plant in ipairs(pp:GetChildren()) do
                if not ac then break end
                for _,desc in ipairs(plant:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled and desc.Parent then
                        local dist = (prp.Position - desc.Parent.Position).Magnitude
                        local can = not cfg.use_dist or dist <= cfg.dist
                        if can and dist < md then md,np = dist,desc end
                    end
                end
            end
            if np then
                if cfg.debug then print("Coletando a",math.floor(md),"studs") end
                fireproximityprompt(np)
                collected = true
                task.wait(cfg.collect_delay)
            end
        else
            for _,plant in ipairs(pp:GetChildren()) do
                if not ac then break end
                for _,fp in ipairs(plant:GetDescendants()) do
                    if fp:IsA("ProximityPrompt") and fp.Enabled and fp.Parent then
                        local can = true
                        if cfg.use_dist then
                            can = (prp.Position - fp.Parent.Position).Magnitude <= cfg.dist
                        end
                        if can then
                            fireproximityprompt(fp)
                            collected = true
                            task.wait(cfg.collect_delay)
                        end
                    end
                end
            end
        end
        task.wait(collected and cfg.loop_delay or 0.1)
    end
end

function autoPlantSeedsOptimized(sn)
    while ap do
        if not ap then break end
        local sh = equipSeed(sn)
        if not sh and cfg.auto_buy then
            if buySeed(sn) then
                task.wait(0.2)
                sh = equipSeed(sn)
            end
        end
        if sh and pp then
            local q = sh:GetAttribute("Quantity")
            if q and q > 0 then
                if cfg.debug then print("Plantando",sn,"- Qtd:",q) end
                plantEvent:FireServer(pp,sn)
                task.wait(cfg.plant_delay)
            else
                if cfg.debug then print("Sem sementes:",sn) end
                task.wait(1)
            end
        else
            if cfg.debug then print("Não equipou semente ou posição inválida") end
            task.wait(1)
        end
        task.wait(cfg.loop_delay)
    end
end

-- GUI Compacta
local function createGUI()
    local sg = Instance.new("ScreenGui")
    sg.Name,sg.Parent,sg.ResetOnSpawn = "GardenGUI",CG,false
    local mf = Instance.new("Frame")
    mf.Name,mf.Size,mf.Position,mf.BackgroundColor3,mf.BorderSizePixel,mf.Active,mf.Draggable,mf.Parent = "Main",UDim2.new(0,400,0,500),UDim2.new(0.5,-200,0.5,-250),Color3.fromRGB(30,30,30),0,true,true,sg
    local mc = Instance.new("UICorner")
    mc.CornerRadius,mc.Parent = UDim.new(0,10),mf
    local tl = Instance.new("TextLabel")
    tl.Size,tl.Position,tl.BackgroundTransparency,tl.Text,tl.TextColor3,tl.TextScaled,tl.Font,tl.Parent = UDim2.new(1,-20,0,40),UDim2.new(0,10,0,10),1,"🌱 Garden Script v2.1",Color3.fromRGB(100,200,100),true,Enum.Font.GothamBold,mf
    local cb = Instance.new("TextButton")
    cb.Size,cb.Position,cb.BackgroundColor3,cb.Text,cb.TextColor3,cb.TextScaled,cb.Font,cb.Parent = UDim2.new(0,30,0,30),UDim2.new(1,-40,0,10),Color3.fromRGB(200,50,50),"✕",Color3.fromRGB(255,255,255),true,Enum.Font.GothamBold,mf
    local cc = Instance.new("UICorner")
    cc.CornerRadius,cc.Parent = UDim.new(0,6),cb
    cb.MouseButton1Click:Connect(function() sg:Destroy() end)
    local cf = Instance.new("ScrollingFrame")
    cf.Size,cf.Position,cf.BackgroundTransparency,cf.ScrollBarThickness,cf.Parent = UDim2.new(1,-20,1,-70),UDim2.new(0,10,0,60),1,6,mf
    local l = Instance.new("UIListLayout")
    l.Padding,l.Parent = UDim.new(0,10),cf
    
    local function btn(txt,cb)
        local b = Instance.new("TextButton")
        b.Size,b.BackgroundColor3,b.Text,b.TextColor3,b.TextScaled,b.Font,b.Parent = UDim2.new(1,0,0,40),Color3.fromRGB(50,120,200),txt,Color3.fromRGB(255,255,255),true,Enum.Font.Gotham,cf
        local bc = Instance.new("UICorner")
        bc.CornerRadius,bc.Parent = UDim.new(0,6),b
        b.MouseButton1Click:Connect(cb)
        return b
    end
    
    local function toggle(txt,cb,def)
        local tf = Instance.new("Frame")
        tf.Size,tf.BackgroundColor3,tf.Parent = UDim2.new(1,0,0,40),Color3.fromRGB(40,40,40),cf
        local tc = Instance.new("UICorner")
        tc.CornerRadius,tc.Parent = UDim.new(0,6),tf
        local lbl = Instance.new("TextLabel")
        lbl.Size,lbl.Position,lbl.BackgroundTransparency,lbl.Text,lbl.TextColor3,lbl.TextScaled,lbl.Font,lbl.TextXAlignment,lbl.Parent = UDim2.new(1,-60,1,0),UDim2.new(0,10,0,0),1,txt,Color3.fromRGB(255,255,255),true,Enum.Font.Gotham,Enum.TextXAlignment.Left,tf
        local tb = Instance.new("TextButton")
        tb.Size,tb.Position,tb.BackgroundColor3,tb.Text,tb.TextColor3,tb.TextScaled,tb.Font,tb.Parent = UDim2.new(0,40,0,25),UDim2.new(1,-50,0.5,-12.5),def and Color3.fromRGB(100,200,100) or Color3.fromRGB(100,100,100),def and "ON" or "OFF",Color3.fromRGB(255,255,255),true,Enum.Font.GothamBold,tf
        local tbc = Instance.new("UICorner")
        tbc.CornerRadius,tbc.Parent = UDim.new(0,4),tb
        local on = def or false
        tb.MouseButton1Click:Connect(function()
            on = not on
            tb.Text = on and "ON" or "OFF"
            tb.BackgroundColor3 = on and Color3.fromRGB(100,200,100) or Color3.fromRGB(100,100,100)
            cb(on)
        end)
        return tf
    end
    
    local function dropdown(txt,opts,cb,def)
        local df = Instance.new("Frame")
        df.Size,df.BackgroundColor3,df.Parent = UDim2.new(1,0,0,40),Color3.fromRGB(40,40,40),cf
        local dc = Instance.new("UICorner")
        dc.CornerRadius,dc.Parent = UDim.new(0,6),df
        local lbl = Instance.new("TextLabel")
        lbl.Size,lbl.Position,lbl.BackgroundTransparency,lbl.Text,lbl.TextColor3,lbl.TextScaled,lbl.Font,lbl.TextXAlignment,lbl.Parent = UDim2.new(0.4,0,1,0),UDim2.new(0,10,0,0),1,txt,Color3.fromRGB(255,255,255),true,Enum.Font.Gotham,Enum.TextXAlignment.Left,df
        local dd = Instance.new("TextButton")
        dd.Size,dd.Position,dd.BackgroundColor3,dd.Text,dd.TextColor3,dd.TextScaled,dd.Font,dd.Parent = UDim2.new(0.55,0,0,30),UDim2.new(0.4,10,0.5,-15),Color3.fromRGB(60,60,60),def or opts[1],Color3.fromRGB(255,255,255),true,Enum.Font.Gotham,df
        local ddc = Instance.new("UICorner")
        ddc.CornerRadius,ddc.Parent = UDim.new(0,4),dd
        local open = false
        local of = Instance.new("Frame")
        of.Size,of.Position,of.BackgroundColor3,of.Visible,of.Parent = UDim2.new(0.55,0,0,#opts*30),UDim2.new(0.4,10,1,5),Color3.fromRGB(50,50,50),false,df
        local oc = Instance.new("UICorner")
        oc.CornerRadius,oc.Parent = UDim.new(0,4),of
        local ol = Instance.new("UIListLayout")
        ol.Parent = of
        for _,opt in ipairs(opts) do
            local ob = Instance.new("TextButton")
            ob.Size,ob.BackgroundColor3,ob.Text,ob.TextColor3,ob.TextScaled,ob.Font,ob.Parent = UDim2.new(1,0,0,30),Color3.fromRGB(50,50,50),opt,Color3.fromRGB(255,255,255),true,Enum.Font.Gotham,of
            ob.MouseButton1Click:Connect(function()
                dd.Text = opt
                of.Visible = false
                open = false
                cb(opt)
            end)
        end
        dd.MouseButton1Click:Connect(function()
            open = not open
            of.Visible = open
        end)
        return df
    end
    
    btn("📍 Definir Posição", function()
        local c = lp.Character
        local rp = c and c:FindFirstChild("HumanoidRootPart")
        if rp then
            pp = rp.Position
            task.spawn(notify,"Posição Definida",string.format("%.0f, %.0f, %.0f",pp.X,pp.Y,pp.Z),2)
        else
            task.spawn(notify,"Erro","Personagem não encontrado",2)
        end
    end)
    
    dropdown("🌱 Semente:",SEEDS,function(opt)
        ss = opt
        if cfg.debug then print("Semente:",opt) end
    end,"Carrot")
    
    toggle("🚀 Auto Plantar",function(s)
        ap = s
        if s then
            task.spawn(autoPlantSeedsOptimized,ss)
            task.spawn(notify,"Auto Plantar","Ativado",1)
        else
            task.spawn(notify,"Auto Plantar","Desativado",1)
        end
    end,false)
    
    toggle("🍎 Auto Coletar",function(s)
        ac = s
        if s then
            task.spawn(autoCollectFruitsOptimized)
            task.spawn(notify,"Auto Coletar","Ativado",1)
        else
            task.spawn(notify,"Auto Coletar","Desativado",1)
        end
    end,false)
    
    toggle("💰 Compra Auto",function(s) cfg.auto_buy = s end,cfg.auto_buy)
    toggle("📏 Check Distância",function(s) cfg.use_dist = s end,cfg.use_dist)
    toggle("🎯 Fruta Próxima",function(s) cfg.near_fruit = s end,cfg.near_fruit)
    toggle("🐛 Debug",function(s) cfg.debug = s end,cfg.debug)
    
    cf.CanvasSize = UDim2.new(0,0,0,l.AbsoluteContentSize.Y+20)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        cf.CanvasSize = UDim2.new(0,0,0,l.AbsoluteContentSize.Y+20)
    end)
    
    return sg
end

-- Init
local function initPos()
    local f = getFarm()
    if f then
        local imp = f:FindFirstChild("Important")
        if imp then
            local pl = imp:FindFirstChild("Plant_Locations")
            if pl then
                local dl = pl:FindFirstChildOfClass("Part")
                if dl then
                    pp = dl.Position
                    return
                end
            end
        end
    end
    pp = Vector3.new(0,0,0)
    warn("Posição padrão não encontrada")
end

initPos()
createGUI()
task.spawn(notify,"Script Carregado!","Garden v2.1 - Ultra Compacto!",3)
print("🌱 Garden Script v2.1 carregado - Tamanho reduzido em 60%!")
