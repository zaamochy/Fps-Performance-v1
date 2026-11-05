--[[
    FPS Performance (versi buatan Claude)
    Tab Combat   : Full Bright, No Fog, No Shadow, Low Grafik
    Tab Rendering: Material Polos, Matikan Partikel/Efek/Decal
    Tab Misc     : FPS & Ping Counter, Anti AFK
    Semua toggle bisa dimatikan lagi (nilai asli dikembalikan).
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Hindari dobel GUI kalau script dijalankan 2x
pcall(function()
    if getgenv and getgenv().FPSPerfGui then
        getgenv().FPSPerfGui:Destroy()
    end
end)

local function getParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then return core end
    return LP:WaitForChild("PlayerGui")
end

local function scan(fn)
    local n = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(fn, v)
        n += 1
        if n % 400 == 0 then task.wait() end
    end
end

----------------------------------------------------------------
-- FITUR
----------------------------------------------------------------
local Features = {}
local conns = {}

-- Full Bright
do
    local orig, loop
    Features.FullBright = {
        on = function()
            orig = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            loop = true
            task.spawn(function()
                while loop do
                    Lighting.Brightness = 2
                    Lighting.ClockTime = 14
                    Lighting.Ambient = Color3.new(1, 1, 1)
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                    task.wait(1)
                end
            end)
        end,
        off = function()
            loop = false
            if orig then
                for k, v in pairs(orig) do Lighting[k] = v end
            end
        end,
    }
end

-- No Fog
do
    local orig, loop
    local atm = setmetatable({}, { __mode = "k" })
    Features.NoFog = {
        on = function()
            orig = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd }
            loop = true
            task.spawn(function()
                while loop do
                    Lighting.FogStart = 9e9
                    Lighting.FogEnd = 9e9
                    for _, a in ipairs(Lighting:GetChildren()) do
                        if a:IsA("Atmosphere") then
                            if not atm[a] then atm[a] = a.Density end
                            a.Density = 0
                        end
                    end
                    task.wait(1)
                end
            end)
        end,
        off = function()
            loop = false
            if orig then
                Lighting.FogStart = orig.FogStart
                Lighting.FogEnd = orig.FogEnd
            end
            for a, d in pairs(atm) do
                if a.Parent then a.Density = d end
            end
        end,
    }
end

-- No Shadow
do
    local orig = setmetatable({}, { __mode = "k" })
    local gs, con
    Features.NoShadow = {
        on = function()
            gs = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            local function apply(v)
                if v:IsA("BasePart") then
                    if orig[v] == nil then orig[v] = v.CastShadow end
                    v.CastShadow = false
                end
            end
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            if gs ~= nil then Lighting.GlobalShadows = gs end
            for p, v in pairs(orig) do
                if p.Parent then p.CastShadow = v end
            end
        end,
    }
end

-- Low Grafik
do
    local origQ, origE, origS
    Features.LowGrafik = {
        on = function()
            pcall(function()
                origQ = settings().Rendering.QualityLevel
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                origE = Lighting.EnvironmentDiffuseScale
                origS = Lighting.EnvironmentSpecularScale
                Lighting.EnvironmentDiffuseScale = 0
                Lighting.EnvironmentSpecularScale = 0
            end)
        end,
        off = function()
            pcall(function()
                if origQ then settings().Rendering.QualityLevel = origQ end
            end)
            pcall(function()
                if origE then Lighting.EnvironmentDiffuseScale = origE end
                if origS then Lighting.EnvironmentSpecularScale = origS end
            end)
        end,
    }
end

-- Material Polos (hapus tekstur)
do
    local mats = setmetatable({}, { __mode = "k" })
    local texs = setmetatable({}, { __mode = "k" })
    local water, con
    Features.PlainMaterial = {
        on = function()
            local function apply(v)
                if v:IsA("Terrain") then return end
                if v:IsA("BasePart") then
                    if mats[v] == nil then mats[v] = v.Material end
                    v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Texture") then
                    if texs[v] == nil then texs[v] = v.Transparency end
                    v.Transparency = 1
                end
            end
            pcall(function()
                local t = workspace.Terrain
                water = {
                    t.WaterWaveSize, t.WaterWaveSpeed,
                    t.WaterReflectance, t.WaterTransparency,
                }
                t.WaterWaveSize = 0
                t.WaterWaveSpeed = 0
                t.WaterReflectance = 0
                t.WaterTransparency = 1
            end)
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            for p, m in pairs(mats) do
                if p.Parent then p.Material = m end
            end
            for t, tr in pairs(texs) do
                if t.Parent then t.Transparency = tr end
            end
            pcall(function()
                local t = workspace.Terrain
                if water then
                    t.WaterWaveSize = water[1]
                    t.WaterWaveSpeed = water[2]
                    t.WaterReflectance = water[3]
                    t.WaterTransparency = water[4]
                end
            end)
        end,
    }
end

-- Matikan Partikel, Efek & Decal
do
    local en = setmetatable({}, { __mode = "k" })
    local dc = setmetatable({}, { __mode = "k" })
    local con
    local EFFECTS = { "ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles", "Beam" }
    Features.NoEffects = {
        on = function()
            local function apply(v)
                for _, c in ipairs(EFFECTS) do
                    if v:IsA(c) then
                        if en[v] == nil then en[v] = v.Enabled end
                        v.Enabled = false
                        return
                    end
                end
                if v:IsA("Decal") and not v:IsA("Texture") then
                    if dc[v] == nil then dc[v] = v.Transparency end
                    v.Transparency = 1
                end
            end
            con = workspace.DescendantAdded:Connect(function(v) pcall(apply, v) end)
            task.spawn(scan, apply)
        end,
        off = function()
            if con then con:Disconnect() end
            for e, v in pairs(en) do
                if e.Parent then e.Enabled = v end
            end
            for d, v in pairs(dc) do
                if d.Parent then d.Transparency = v end
            end
        end,
    }
end

-- Anti AFK
do
    local con
    Features.AntiAFK = {
        on = function()
            con = LP.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end,
        off = function()
            if con then con:Disconnect() end
        end,
    }
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "FPSPerformance"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(Gui) end end)
Gui.Parent = getParent()
pcall(function() if getgenv then getgenv().FPSPerfGui = Gui end end)

local BLUE = Color3.fromRGB(37, 99, 235)
local LIGHT = Color3.fromRGB(96, 165, 250)
local DARK = Color3.fromRGB(12, 22, 55)

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
end

local function stroke(o, color, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = t
    s.Transparency = tr or 0
    s.Parent = o
    return s
end

local function label(parent, text, size, color, font, pos, sz, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font or Enum.Font.GothamMedium
    l.Position = pos
    l.Size = sz
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeDraggable(handle, target)
    local dragging, start, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = i.Position
            startPos = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Jendela utama
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(330, 340)
Main.Position = UDim2.new(0.5, -165, 0.5, -170)
Main.BackgroundColor3 = DARK
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.Parent = Gui
corner(Main, 20)
stroke(Main, LIGHT, 1.5, 0.2)
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(30, 58, 138), Color3.fromRGB(8, 14, 38))
grad.Rotation = 90
grad.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 62)
Header.BackgroundTransparency = 1
Header.Parent = Main
makeDraggable(Header, Main)

local logo = Instance.new("Frame")
logo.Size = UDim2.fromOffset(38, 38)
logo.Position = UDim2.fromOffset(14, 12)
logo.BackgroundColor3 = Color3.fromRGB(2, 6, 23)
logo.Parent = Header
corner(logo, 19)
stroke(logo, LIGHT, 3, 0)

label(Header, "FPS Performance", 17, Color3.new(1, 1, 1), Enum.Font.GothamBold,
    UDim2.fromOffset(62, 10), UDim2.fromOffset(170, 22))
label(Header, "by zaamochy", 12, Color3.fromRGB(165, 190, 235), Enum.Font.Gotham,
    UDim2.fromOffset(62, 31), UDim2.fromOffset(170, 18))

local function headBtn(txt, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(28, 28)
    b.Position = UDim2.new(1, x, 0, 17)
    b.BackgroundColor3 = Color3.fromRGB(40, 60, 120)
    b.BackgroundTransparency = 0.4
    b.Text = txt
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 16
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = true
    b.Parent = Header
    corner(b, 14)
    return b
end
local MinBtn = headBtn("–", -70)
local CloseBtn = headBtn("X", -36)

-- Tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 36)
TabBar.Position = UDim2.fromOffset(12, 64)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main
local tl = Instance.new("UIListLayout")
tl.FillDirection = Enum.FillDirection.Horizontal
tl.Padding = UDim.new(0, 6)
tl.Parent = TabBar

-- Area halaman
local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -24, 1, -160)
Body.Position = UDim2.fromOffset(12, 108)
Body.BackgroundTransparency = 1
Body.ClipsDescendants = true
Body.Parent = Main

local pages, tabs = {}, {}

local function newPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.fromScale(1, 1)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = LIGHT
    p.CanvasSize = UDim2.new()
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = Body
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.Parent = p
    pages[name] = p
    return p
end

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        local on = (n == name)
        b.BackgroundColor3 = on and BLUE or Color3.fromRGB(30, 45, 90)
        b.BackgroundTransparency = on and 0 or 0.45
    end
end

local function newTab(name, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / 3, -4, 1, 0)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = TabBar
    corner(b, 18)
    tabs[name] = b
    b.Activated:Connect(function() selectTab(name) end)
    newPage(name)
end

newTab("Combat", "⚔ Combat")
newTab("Rendering", "🖥 Rendering")
newTab("Misc", "⚙ Misc")

-- Baris toggle
local function addRow(page, icon, title, desc, onFn, offFn)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(30, 45, 95)
    row.BackgroundTransparency = 0.45
    row.Parent = page
    corner(row, 14)

    label(row, icon, 22, Color3.new(1, 1, 1), Enum.Font.GothamMedium,
        UDim2.fromOffset(8, 0), UDim2.fromOffset(36, 54), Enum.TextXAlignment.Center)
    label(row, title, 14, Color3.new(1, 1, 1), Enum.Font.GothamBold,
        UDim2.fromOffset(48, 8), UDim2.new(1, -120, 0, 18))
    label(row, desc, 11, Color3.fromRGB(165, 190, 235), Enum.Font.Gotham,
        UDim2.fromOffset(48, 27), UDim2.new(1, -120, 0, 16))

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.fromOffset(46, 24)
    sw.Position = UDim2.new(1, -58, 0.5, -12)
    sw.BackgroundColor3 = Color3.fromRGB(55, 65, 100)
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row
    corner(sw, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = sw
    corner(knob, 9)

    local state = false
    local function set(v)
        if v == state then return end
        state = v
        TweenService:Create(sw, TweenInfo.new(0.15), {
            BackgroundColor3 = v and BLUE or Color3.fromRGB(55, 65, 100),
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        }):Play()
        task.spawn(function() pcall(v and onFn or offFn) end)
    end
    sw.Activated:Connect(function() set(not state) end)
    return set
end

local setters = {}
local C, R, M = pages.Combat, pages.Rendering, pages.Misc

setters[#setters + 1] = addRow(C, "☀", "Full Bright", "Make the game brighter",
    Features.FullBright.on, Features.FullBright.off)
setters[#setters + 1] = addRow(C, "🌫", "No Fog", "Remove fog effect",
    Features.NoFog.on, Features.NoFog.off)
setters[#setters + 1] = addRow(C, "◐", "No Shadow", "Disable shadows",
    Features.NoShadow.on, Features.NoShadow.off)
setters[#setters + 1] = addRow(C, "🎨", "Low Grafik", "Reduce graphic quality",
    Features.LowGrafik.on, Features.LowGrafik.off)

setters[#setters + 1] = addRow(R, "🧱", "Material Polos", "Hapus tekstur, jadi polos",
    Features.PlainMaterial.on, Features.PlainMaterial.off)
setters[#setters + 1] = addRow(R, "✨", "No Efek", "Matikan partikel, efek & decal",
    Features.NoEffects.on, Features.NoEffects.off)

-- FPS & Ping counter
local Counter = Instance.new("Frame")
Counter.Size = UDim2.fromOffset(150, 34)
Counter.Position = UDim2.fromOffset(12, 12)
Counter.BackgroundColor3 = DARK
Counter.BackgroundTransparency = 0.2
Counter.Visible = false
Counter.Parent = Gui
corner(Counter, 17)
stroke(Counter, LIGHT, 1.2, 0.2)
local CounterText = label(Counter, "-- FPS | --ms", 14, Color3.new(1, 1, 1),
    Enum.Font.GothamBold, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1),
    Enum.TextXAlignment.Center)
makeDraggable(Counter, Counter)

local counterConn
local function counterOn()
    Counter.Visible = true
    local frames, t0 = 0, os.clock()
    counterConn = RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - t0 >= 0.5 then
            local fps = math.floor(frames / (now - t0) + 0.5)
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
            end)
            CounterText.Text = fps .. " FPS | " .. ping .. "ms"
            frames, t0 = 0, now
        end
    end)
end
local function counterOff()
    Counter.Visible = false
    if counterConn then counterConn:Disconnect() end
end

setters[#setters + 1] = addRow(M, "📊", "FPS & Ping", "Counter di pojok layar", counterOn, counterOff)
setters[#setters + 1] = addRow(M, "🛡", "Anti AFK", "Cegah kick karena diam",
    Features.AntiAFK.on, Features.AntiAFK.off)

-- Footer
local Footer = label(Main, "📶  Optimized for maximum FPS", 11, Color3.fromRGB(165, 190, 235),
    Enum.Font.GothamMedium, UDim2.new(0, 16, 1, -40), UDim2.new(1, -120, 0, 30))
Footer.TextWrapped = true
local Tag = label(Main, "by zaamochy", 11, Color3.new(1, 1, 1), Enum.Font.GothamBold,
    UDim2.new(1, -104, 1, -36), UDim2.fromOffset(92, 24), Enum.TextXAlignment.Center)
Tag.BackgroundTransparency = 0.5
Tag.BackgroundColor3 = Color3.fromRGB(30, 58, 138)
corner(Tag, 12)

-- Tombol bulat buka/tutup menu
local Orb = Instance.new("TextButton")
Orb.Size = UDim2.fromOffset(46, 46)
Orb.Position = UDim2.new(1, -62, 0.4, 0)
Orb.BackgroundColor3 = Color3.fromRGB(2, 6, 23)
Orb.Text = ""
Orb.AutoButtonColor = false
Orb.Parent = Gui
corner(Orb, 23)
stroke(Orb, LIGHT, 3, 0)
makeDraggable(Orb, Orb)
Orb.Activated:Connect(function() Main.Visible = not Main.Visible end)
MinBtn.Activated:Connect(function() Main.Visible = false end)

CloseBtn.Activated:Connect(function()
    for _, s in ipairs(setters) do pcall(s, false) end
    task.wait(0.3)
    Gui:Destroy()
end)

selectTab("Combat")
