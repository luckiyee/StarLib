--[[
     _____ __             __    _ __  
    / ___// /_____ ______/ /   (_) /_ 
    \__ \/ __/ __ `/ ___/ /   / / __ \
   ___/ / /_/ /_/ / /  / /___/ / /_/ /
  /____/\__/\__,_/_/  /_____/_/_.___/ 

  StarLib v3.0.0 — Ultimate Roblox UI Library
  The most complete executor UI library ever made.

  Load with:
    local StarLib = loadstring(readfile("StarLib/StarLib.lua"))()
  
  Quick start:
    local Window = StarLib:CreateWindow({ Name = "My Script" })
    local Tab = Window:CreateTab("Main")
    Tab:CreateButton({ Name = "Click Me", Callback = function() print("Hi!") end })

  Features:
    Core: Window, Tabs, Sidebar, Draggable, Minimize, Toggle Key
    Widgets: Button, Toggle, Slider, RangeSlider, Dropdown, MultiDropdown,
             Input, Keybind, ColorPicker (full HSV), ProgressBar, CircularProgress,
             Section, Label, Paragraph, Separator, Spacer, Badge, Table, RadioGroup,
             Accordion, CodeBlock, ImageCard, ProfileCard, PlayerList, Graph,
             CountdownTimer, TreeView, Pagination, Stepper, Calendar
    Layout: HorizontalRow, VerticalStack, GridContainer
    Systems: Stacking Notifications, Modal Dialogs, Tooltips, Context Menus,
             Command Palette, Watermark/HUD, Loading Screen, FPS Counter,
             Status Bar, State Persistence, Config Profiles, Keyboard Navigation,
             Multi-Window Manager, Plugin API, Debug Mode, Event Bus,
             Theme Engine with 12 presets, Animation Library
]]

-- =========================================================================
-- SERVICES
-- =========================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================================
-- VERSION & METADATA
-- =========================================================================
local STARLIB_VERSION = "3.0.0"
local STARLIB_BUILD = "2026.02.22"

-- =========================================================================
-- SECTION 1: UTILITY FUNCTIONS
-- =========================================================================

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[deepCopy(k)] = deepCopy(v) end
    return setmetatable(copy, getmetatable(t))
end

local function generateId()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 16 do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return id
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor3(c1, c2, t)
    return Color3.new(
        lerp(c1.R, c2.R, t),
        lerp(c1.G, c2.G, t),
        lerp(c1.B, c2.B, t)
    )
end

local function clamp(val, mn, mx)
    return math.max(mn, math.min(mx, val))
end

local function round(val, places)
    local mult = 10 ^ (places or 0)
    return math.floor(val * mult + 0.5) / mult
end

local function truncate(str, maxLen)
    if #str <= maxLen then return str end
    return str:sub(1, maxLen - 3) .. "..."
end

local function safeCallback(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[StarLib] Callback error: " .. tostring(err))
    end
    return ok, err
end

local function formatNumber(n)
    if n >= 1e9 then return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(n) end
end

local function formatTime(seconds)
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hrs > 0 then
        return string.format("%dh %dm %ds", hrs, mins, secs)
    elseif mins > 0 then
        return string.format("%dm %ds", mins, secs)
    else
        return string.format("%ds", secs)
    end
end

local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end

local function tableRemove(tbl, val)
    for i = #tbl, 1, -1 do
        if tbl[i] == val then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

local function tableKeys(tbl)
    local keys = {}
    for k in pairs(tbl) do keys[#keys + 1] = k end
    return keys
end

local function mergeTable(base, override)
    local result = {}
    for k, v in pairs(base) do result[k] = v end
    if override then
        for k, v in pairs(override) do result[k] = v end
    end
    return result
end

-- =========================================================================
-- SECTION 2: COLOR UTILITIES
-- =========================================================================

local function HSVtoRGB(h, s, v)
    if s == 0 then return v, v, v end
    local hh = (h % 1) * 6
    local i = math.floor(hh)
    local ff = hh - i
    local p = v * (1 - s)
    local q = v * (1 - s * ff)
    local t = v * (1 - s * (1 - ff))
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

local function RGBtoHSV(r, g, b)
    local mx = math.max(r, g, b)
    local mn = math.min(r, g, b)
    local d = mx - mn
    local hue, sat, val
    val = mx
    if mx == 0 then sat = 0 else sat = d / mx end
    if d == 0 then
        hue = 0
    else
        if mx == r then
            hue = (g - b) / d
            if hue < 0 then hue = hue + 6 end
        elseif mx == g then
            hue = (b - r) / d + 2
        else
            hue = (r - g) / d + 4
        end
        hue = hue / 6
    end
    return hue, sat, val
end

local function Color3ToHex(c)
    return string.format("#%02X%02X%02X",
        clamp(math.floor(c.R * 255 + 0.5), 0, 255),
        clamp(math.floor(c.G * 255 + 0.5), 0, 255),
        clamp(math.floor(c.B * 255 + 0.5), 0, 255))
end

local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r, g, b)
end

local function darkenColor(c, amount)
    return Color3.new(
        clamp(c.R - amount, 0, 1),
        clamp(c.G - amount, 0, 1),
        clamp(c.B - amount, 0, 1)
    )
end

local function lightenColor(c, amount)
    return Color3.new(
        clamp(c.R + amount, 0, 1),
        clamp(c.G + amount, 0, 1),
        clamp(c.B + amount, 0, 1)
    )
end

local function getContrastColor(c)
    local luminance = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    if luminance > 0.5 then
        return Color3.fromRGB(0, 0, 0)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end

-- =========================================================================
-- SECTION 3: EASING FUNCTIONS
-- =========================================================================

local Easing = {}

function Easing.Linear(t) return t end

function Easing.QuadIn(t) return t * t end
function Easing.QuadOut(t) return t * (2 - t) end
function Easing.QuadInOut(t)
    if t < 0.5 then return 2 * t * t end
    return -1 + (4 - 2 * t) * t
end

function Easing.CubicIn(t) return t * t * t end
function Easing.CubicOut(t) local t1 = t - 1; return t1 * t1 * t1 + 1 end
function Easing.CubicInOut(t)
    if t < 0.5 then return 4 * t * t * t end
    return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
end

function Easing.QuintIn(t) return t * t * t * t * t end
function Easing.QuintOut(t) local t1 = t - 1; return 1 + t1 * t1 * t1 * t1 * t1 end

function Easing.SineIn(t) return 1 - math.cos(t * math.pi / 2) end
function Easing.SineOut(t) return math.sin(t * math.pi / 2) end
function Easing.SineInOut(t) return -(math.cos(math.pi * t) - 1) / 2 end

function Easing.ElasticOut(t)
    if t == 0 or t == 1 then return t end
    return math.pow(2, -10 * t) * math.sin((t - 0.075) * (2 * math.pi) / 0.3) + 1
end

function Easing.BounceOut(t)
    if t < 1/2.75 then return 7.5625 * t * t
    elseif t < 2/2.75 then t = t - 1.5/2.75; return 7.5625 * t * t + 0.75
    elseif t < 2.5/2.75 then t = t - 2.25/2.75; return 7.5625 * t * t + 0.9375
    else t = t - 2.625/2.75; return 7.5625 * t * t + 0.984375 end
end

function Easing.BackOut(t)
    local s = 1.70158
    t = t - 1
    return t * t * ((s + 1) * t + s) + 1
end

-- =========================================================================
-- SECTION 4: SIGNAL / EVENT BUS SYSTEM
-- =========================================================================

local function createSignal()
    local connections = {}
    local signal = {}

    function signal:Connect(fn)
        local conn = { Callback = fn, Connected = true }
        function conn:Disconnect()
            conn.Connected = false
            for i = #connections, 1, -1 do
                if connections[i] == conn then
                    table.remove(connections, i)
                    break
                end
            end
        end
        connections[#connections + 1] = conn
        return conn
    end

    function signal:Fire(...)
        for i = 1, #connections do
            local conn = connections[i]
            if conn and conn.Connected then
                task.spawn(conn.Callback, ...)
            end
        end
    end

    function signal:Wait()
        local thread = coroutine.running()
        local conn
        conn = signal:Connect(function(...)
            conn:Disconnect()
            task.spawn(thread, ...)
        end)
        return coroutine.yield()
    end

    function signal:Once(fn)
        local conn
        conn = signal:Connect(function(...)
            conn:Disconnect()
            fn(...)
        end)
        return conn
    end

    function signal:DisconnectAll()
        for _, conn in ipairs(connections) do conn.Connected = false end
        connections = {}
    end

    return signal
end

local EventBus = {
    _channels = {}
}

function EventBus:on(event, fn)
    if not self._channels[event] then
        self._channels[event] = createSignal()
    end
    return self._channels[event]:Connect(fn)
end

function EventBus:emit(event, ...)
    if self._channels[event] then
        self._channels[event]:Fire(...)
    end
end

function EventBus:off(event)
    if self._channels[event] then
        self._channels[event]:DisconnectAll()
        self._channels[event] = nil
    end
end

-- =========================================================================
-- SECTION 5: ANIMATION LIBRARY
-- =========================================================================

local Animate = {}

function Animate.tween(obj, tweenInfo, props)
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

function Animate.fadeIn(obj, duration, from)
    if obj:IsA("GuiObject") then
        obj.BackgroundTransparency = from or 1
        return Animate.tween(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 0
        })
    end
end

function Animate.fadeOut(obj, duration, to)
    if obj:IsA("GuiObject") then
        return Animate.tween(obj, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quint), {
            BackgroundTransparency = to or 1
        })
    end
end

function Animate.slideIn(obj, direction, duration)
    duration = duration or 0.3
    local target = obj.Position
    local offscreen
    if direction == "left" then
        offscreen = UDim2.new(target.X.Scale - 1, target.X.Offset, target.Y.Scale, target.Y.Offset)
    elseif direction == "right" then
        offscreen = UDim2.new(target.X.Scale + 1, target.X.Offset, target.Y.Scale, target.Y.Offset)
    elseif direction == "up" then
        offscreen = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale - 1, target.Y.Offset)
    else
        offscreen = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale + 1, target.Y.Offset)
    end
    obj.Position = offscreen
    return Animate.tween(obj, TweenInfo.new(duration, Enum.EasingStyle.Quint), { Position = target })
end

function Animate.slideOut(obj, direction, duration)
    duration = duration or 0.3
    local current = obj.Position
    local offscreen
    if direction == "left" then
        offscreen = UDim2.new(current.X.Scale - 1, current.X.Offset, current.Y.Scale, current.Y.Offset)
    elseif direction == "right" then
        offscreen = UDim2.new(current.X.Scale + 1, current.X.Offset, current.Y.Scale, current.Y.Offset)
    elseif direction == "up" then
        offscreen = UDim2.new(current.X.Scale, current.X.Offset, current.Y.Scale - 1, current.Y.Offset)
    else
        offscreen = UDim2.new(current.X.Scale, current.X.Offset, current.Y.Scale + 1, current.Y.Offset)
    end
    return Animate.tween(obj, TweenInfo.new(duration, Enum.EasingStyle.Quint), { Position = offscreen })
end

function Animate.scaleIn(obj, duration)
    duration = duration or 0.3
    local targetSize = obj.Size
    obj.Size = UDim2.new(0, 0, 0, 0)
    return Animate.tween(obj, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize
    })
end

function Animate.pulse(obj, duration, scale)
    duration = duration or 0.5
    scale = scale or 1.05
    local origSize = obj.Size
    local bigSize = UDim2.new(
        origSize.X.Scale * scale, origSize.X.Offset * scale,
        origSize.Y.Scale * scale, origSize.Y.Offset * scale
    )
    local tw1 = TweenService:Create(obj, TweenInfo.new(duration/2, Enum.EasingStyle.Sine), { Size = bigSize })
    tw1:Play()
    tw1.Completed:Connect(function()
        TweenService:Create(obj, TweenInfo.new(duration/2, Enum.EasingStyle.Sine), { Size = origSize }):Play()
    end)
    return tw1
end

function Animate.shake(obj, intensity, duration)
    intensity = intensity or 5
    duration = duration or 0.3
    local origPos = obj.Position
    local steps = math.floor(duration / 0.03)
    task.spawn(function()
        for i = 1, steps do
            local ox = math.random(-intensity, intensity)
            local oy = math.random(-intensity, intensity)
            obj.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + ox, origPos.Y.Scale, origPos.Y.Offset + oy)
            task.wait(0.03)
        end
        obj.Position = origPos
    end)
end

function Animate.typewriter(label, text, charDelay)
    charDelay = charDelay or 0.03
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            label.Text = text:sub(1, i)
            task.wait(charDelay)
        end
    end)
end

function Animate.countUp(label, startVal, endVal, duration, prefix, suffix)
    prefix = prefix or ""
    suffix = suffix or ""
    duration = duration or 1
    task.spawn(function()
        local startTime = tick()
        while true do
            local elapsed = tick() - startTime
            local progress = clamp(elapsed / duration, 0, 1)
            local current = math.floor(lerp(startVal, endVal, Easing.QuintOut(progress)))
            label.Text = prefix .. tostring(current) .. suffix
            if progress >= 1 then break end
            task.wait(0.016)
        end
    end)
end

-- =========================================================================
-- SECTION 6: DEFAULT THEME
-- =========================================================================

local DEFAULT_THEME = {
    Background       = Color3.fromRGB(24, 24, 24),
    TopBar           = Color3.fromRGB(30, 30, 30),
    Sidebar          = Color3.fromRGB(30, 30, 30),
    TabDefault       = Color3.fromRGB(40, 40, 40),
    TabActive        = Color3.fromRGB(60, 60, 60),
    TabHover         = Color3.fromRGB(50, 50, 50),
    TextPrimary      = Color3.fromRGB(255, 255, 255),
    TextSecondary    = Color3.fromRGB(200, 200, 200),
    TextMuted        = Color3.fromRGB(140, 140, 140),
    TextDisabled     = Color3.fromRGB(80, 80, 80),
    Accent           = Color3.fromRGB(0, 170, 255),
    AccentDark       = Color3.fromRGB(0, 120, 200),
    AccentLight      = Color3.fromRGB(60, 200, 255),
    Success          = Color3.fromRGB(50, 200, 100),
    Warning          = Color3.fromRGB(255, 180, 0),
    Error            = Color3.fromRGB(255, 70, 70),
    Info             = Color3.fromRGB(0, 170, 255),
    ToggleOff        = Color3.fromRGB(60, 60, 60),
    ElementBG        = Color3.fromRGB(40, 40, 40),
    ElementHover     = Color3.fromRGB(50, 50, 50),
    ElementActive    = Color3.fromRGB(55, 55, 55),
    ElementDisabled  = Color3.fromRGB(35, 35, 35),
    InputBG          = Color3.fromRGB(30, 30, 30),
    InputBorder      = Color3.fromRGB(60, 60, 60),
    InputFocus       = Color3.fromRGB(0, 170, 255),
    SliderTrack      = Color3.fromRGB(60, 60, 60),
    SliderKnob       = Color3.fromRGB(255, 255, 255),
    NotifBG          = Color3.fromRGB(35, 35, 35),
    ModalOverlay     = Color3.fromRGB(0, 0, 0),
    ModalOverlayAlpha = 0.5,
    TooltipBG        = Color3.fromRGB(50, 50, 50),
    ContextBG        = Color3.fromRGB(40, 40, 40),
    ContextHover     = Color3.fromRGB(55, 55, 55),
    ContextBorder    = Color3.fromRGB(60, 60, 60),
    ScrollBar        = Color3.fromRGB(80, 80, 80),
    Divider          = Color3.fromRGB(50, 50, 50),
    Shadow           = Color3.fromRGB(0, 0, 0),
    CornerRadius     = UDim.new(0, 8),
    ElementRadius    = UDim.new(0, 6),
    SmallRadius      = UDim.new(0, 4),
    Font             = Enum.Font.GothamSemibold,
    FontBold         = Enum.Font.GothamBold,
    FontLight        = Enum.Font.Gotham,
    FontMono         = Enum.Font.Code,
    TitleSize        = 16,
    TextSize         = 14,
    SmallTextSize    = 13,
    TinyTextSize     = 11,
    HeaderSize       = 18,
    WindowSize       = UDim2.new(0, 620, 0, 420),
    SidebarWidth     = 155,
    TopBarHeight     = 42,
    ElementHeight    = 36,
    SliderHeight     = 52,
    StatusBarHeight  = 24,
    TweenSpeed       = 0.2,
    FastTween        = 0.1,
    SlowTween        = 0.4,
    NotifDuration    = 4,
    MaxNotifs        = 5,
    AnimationsEnabled = true,
}

-- =========================================================================
-- SECTION 7: THEME PRESETS
-- =========================================================================

local THEME_PRESETS = {
    Dark = {},
    
    Midnight = {
        Background = Color3.fromRGB(15, 15, 35),
        TopBar = Color3.fromRGB(20, 20, 45),
        Sidebar = Color3.fromRGB(20, 20, 45),
        TabDefault = Color3.fromRGB(30, 30, 55),
        TabActive = Color3.fromRGB(45, 45, 75),
        ElementBG = Color3.fromRGB(30, 30, 55),
        ElementHover = Color3.fromRGB(40, 40, 65),
        InputBG = Color3.fromRGB(20, 20, 40),
        SliderTrack = Color3.fromRGB(40, 40, 65),
        NotifBG = Color3.fromRGB(25, 25, 50),
        Accent = Color3.fromRGB(100, 100, 255),
        ContextBG = Color3.fromRGB(25, 25, 50),
        Divider = Color3.fromRGB(40, 40, 65),
    },

    Ocean = {
        Background = Color3.fromRGB(15, 25, 35),
        TopBar = Color3.fromRGB(18, 30, 42),
        Sidebar = Color3.fromRGB(18, 30, 42),
        TabDefault = Color3.fromRGB(25, 40, 55),
        TabActive = Color3.fromRGB(35, 55, 75),
        ElementBG = Color3.fromRGB(25, 40, 55),
        ElementHover = Color3.fromRGB(30, 50, 65),
        InputBG = Color3.fromRGB(15, 28, 38),
        SliderTrack = Color3.fromRGB(35, 55, 70),
        NotifBG = Color3.fromRGB(20, 35, 50),
        Accent = Color3.fromRGB(0, 200, 200),
        ContextBG = Color3.fromRGB(20, 35, 50),
        Divider = Color3.fromRGB(30, 50, 65),
    },

    Forest = {
        Background = Color3.fromRGB(20, 28, 20),
        TopBar = Color3.fromRGB(25, 35, 25),
        Sidebar = Color3.fromRGB(25, 35, 25),
        TabDefault = Color3.fromRGB(35, 48, 35),
        TabActive = Color3.fromRGB(50, 65, 50),
        ElementBG = Color3.fromRGB(35, 48, 35),
        ElementHover = Color3.fromRGB(42, 55, 42),
        InputBG = Color3.fromRGB(22, 32, 22),
        SliderTrack = Color3.fromRGB(40, 55, 40),
        NotifBG = Color3.fromRGB(28, 40, 28),
        Accent = Color3.fromRGB(80, 200, 80),
        ContextBG = Color3.fromRGB(28, 40, 28),
        Divider = Color3.fromRGB(40, 55, 40),
    },

    Crimson = {
        Background = Color3.fromRGB(30, 18, 18),
        TopBar = Color3.fromRGB(38, 22, 22),
        Sidebar = Color3.fromRGB(38, 22, 22),
        TabDefault = Color3.fromRGB(50, 30, 30),
        TabActive = Color3.fromRGB(70, 40, 40),
        ElementBG = Color3.fromRGB(50, 30, 30),
        ElementHover = Color3.fromRGB(60, 38, 38),
        InputBG = Color3.fromRGB(35, 20, 20),
        SliderTrack = Color3.fromRGB(60, 35, 35),
        NotifBG = Color3.fromRGB(40, 25, 25),
        Accent = Color3.fromRGB(255, 60, 60),
        ContextBG = Color3.fromRGB(40, 25, 25),
        Divider = Color3.fromRGB(55, 35, 35),
    },

    Purple = {
        Background = Color3.fromRGB(25, 18, 35),
        TopBar = Color3.fromRGB(32, 22, 45),
        Sidebar = Color3.fromRGB(32, 22, 45),
        TabDefault = Color3.fromRGB(42, 30, 58),
        TabActive = Color3.fromRGB(60, 42, 80),
        ElementBG = Color3.fromRGB(42, 30, 58),
        ElementHover = Color3.fromRGB(52, 38, 68),
        InputBG = Color3.fromRGB(28, 18, 40),
        SliderTrack = Color3.fromRGB(50, 35, 65),
        NotifBG = Color3.fromRGB(35, 25, 50),
        Accent = Color3.fromRGB(180, 80, 255),
        ContextBG = Color3.fromRGB(35, 25, 50),
        Divider = Color3.fromRGB(48, 34, 62),
    },

    Rose = {
        Background = Color3.fromRGB(30, 20, 25),
        TopBar = Color3.fromRGB(38, 25, 32),
        Sidebar = Color3.fromRGB(38, 25, 32),
        TabDefault = Color3.fromRGB(50, 33, 42),
        TabActive = Color3.fromRGB(68, 45, 58),
        ElementBG = Color3.fromRGB(50, 33, 42),
        ElementHover = Color3.fromRGB(60, 40, 50),
        InputBG = Color3.fromRGB(32, 22, 28),
        SliderTrack = Color3.fromRGB(55, 38, 48),
        NotifBG = Color3.fromRGB(40, 28, 35),
        Accent = Color3.fromRGB(255, 100, 150),
        ContextBG = Color3.fromRGB(40, 28, 35),
        Divider = Color3.fromRGB(55, 38, 48),
    },

    Amber = {
        Background = Color3.fromRGB(28, 24, 18),
        TopBar = Color3.fromRGB(35, 30, 22),
        Sidebar = Color3.fromRGB(35, 30, 22),
        TabDefault = Color3.fromRGB(48, 40, 28),
        TabActive = Color3.fromRGB(65, 55, 38),
        ElementBG = Color3.fromRGB(48, 40, 28),
        ElementHover = Color3.fromRGB(58, 48, 35),
        InputBG = Color3.fromRGB(30, 26, 18),
        SliderTrack = Color3.fromRGB(55, 45, 32),
        NotifBG = Color3.fromRGB(40, 34, 25),
        Accent = Color3.fromRGB(255, 180, 0),
        ContextBG = Color3.fromRGB(40, 34, 25),
        Divider = Color3.fromRGB(55, 46, 32),
    },

    Neon = {
        Background = Color3.fromRGB(10, 10, 15),
        TopBar = Color3.fromRGB(12, 12, 18),
        Sidebar = Color3.fromRGB(12, 12, 18),
        TabDefault = Color3.fromRGB(18, 18, 25),
        TabActive = Color3.fromRGB(25, 25, 35),
        ElementBG = Color3.fromRGB(18, 18, 25),
        ElementHover = Color3.fromRGB(22, 22, 32),
        InputBG = Color3.fromRGB(10, 10, 16),
        SliderTrack = Color3.fromRGB(20, 20, 30),
        NotifBG = Color3.fromRGB(15, 15, 22),
        Accent = Color3.fromRGB(0, 255, 180),
        AccentLight = Color3.fromRGB(80, 255, 210),
        ContextBG = Color3.fromRGB(15, 15, 22),
        Divider = Color3.fromRGB(20, 20, 30),
    },

    Light = {
        Background = Color3.fromRGB(240, 240, 245),
        TopBar = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(248, 248, 250),
        TabDefault = Color3.fromRGB(230, 230, 235),
        TabActive = Color3.fromRGB(215, 215, 225),
        TabHover = Color3.fromRGB(220, 220, 228),
        TextPrimary = Color3.fromRGB(20, 20, 30),
        TextSecondary = Color3.fromRGB(60, 60, 70),
        TextMuted = Color3.fromRGB(120, 120, 130),
        TextDisabled = Color3.fromRGB(180, 180, 190),
        ElementBG = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(240, 240, 245),
        ElementActive = Color3.fromRGB(235, 235, 240),
        ElementDisabled = Color3.fromRGB(245, 245, 248),
        InputBG = Color3.fromRGB(255, 255, 255),
        InputBorder = Color3.fromRGB(200, 200, 210),
        SliderTrack = Color3.fromRGB(210, 210, 220),
        SliderKnob = Color3.fromRGB(255, 255, 255),
        NotifBG = Color3.fromRGB(255, 255, 255),
        ContextBG = Color3.fromRGB(255, 255, 255),
        ContextHover = Color3.fromRGB(240, 240, 245),
        ContextBorder = Color3.fromRGB(210, 210, 220),
        TooltipBG = Color3.fromRGB(40, 40, 50),
        Divider = Color3.fromRGB(220, 220, 228),
        ScrollBar = Color3.fromRGB(190, 190, 200),
        Accent = Color3.fromRGB(0, 120, 255),
    },

    Dracula = {
        Background = Color3.fromRGB(40, 42, 54),
        TopBar = Color3.fromRGB(48, 50, 64),
        Sidebar = Color3.fromRGB(48, 50, 64),
        TabDefault = Color3.fromRGB(55, 58, 72),
        TabActive = Color3.fromRGB(68, 71, 90),
        ElementBG = Color3.fromRGB(55, 58, 72),
        ElementHover = Color3.fromRGB(62, 65, 80),
        InputBG = Color3.fromRGB(44, 46, 58),
        SliderTrack = Color3.fromRGB(62, 65, 80),
        NotifBG = Color3.fromRGB(50, 52, 66),
        Accent = Color3.fromRGB(189, 147, 249),
        Success = Color3.fromRGB(80, 250, 123),
        Warning = Color3.fromRGB(255, 184, 108),
        Error = Color3.fromRGB(255, 85, 85),
        Info = Color3.fromRGB(139, 233, 253),
        ContextBG = Color3.fromRGB(50, 52, 66),
        Divider = Color3.fromRGB(62, 65, 80),
        TextPrimary = Color3.fromRGB(248, 248, 242),
        TextSecondary = Color3.fromRGB(200, 200, 210),
    },

    Nord = {
        Background = Color3.fromRGB(46, 52, 64),
        TopBar = Color3.fromRGB(59, 66, 82),
        Sidebar = Color3.fromRGB(59, 66, 82),
        TabDefault = Color3.fromRGB(67, 76, 94),
        TabActive = Color3.fromRGB(76, 86, 106),
        ElementBG = Color3.fromRGB(67, 76, 94),
        ElementHover = Color3.fromRGB(76, 86, 106),
        InputBG = Color3.fromRGB(59, 66, 82),
        SliderTrack = Color3.fromRGB(76, 86, 106),
        NotifBG = Color3.fromRGB(59, 66, 82),
        Accent = Color3.fromRGB(136, 192, 208),
        Success = Color3.fromRGB(163, 190, 140),
        Warning = Color3.fromRGB(235, 203, 139),
        Error = Color3.fromRGB(191, 97, 106),
        Info = Color3.fromRGB(129, 161, 193),
        ContextBG = Color3.fromRGB(59, 66, 82),
        Divider = Color3.fromRGB(76, 86, 106),
        TextPrimary = Color3.fromRGB(236, 239, 244),
        TextSecondary = Color3.fromRGB(216, 222, 233),
    },
}

-- =========================================================================
-- SECTION 8: STARLIB MODULE
-- =========================================================================

local StarLib = {
    Version = STARLIB_VERSION,
    Build = STARLIB_BUILD,
    DebugMode = false,
    Windows = {},
    Themes = THEME_PRESETS,
    Easing = Easing,
    Animate = Animate,
    EventBus = EventBus,
    Signal = createSignal,
    Utils = {
        deepCopy = deepCopy,
        generateId = generateId,
        lerp = lerp,
        lerpColor3 = lerpColor3,
        clamp = clamp,
        round = round,
        truncate = truncate,
        formatNumber = formatNumber,
        formatTime = formatTime,
        HSVtoRGB = HSVtoRGB,
        RGBtoHSV = RGBtoHSV,
        Color3ToHex = Color3ToHex,
        HexToColor3 = HexToColor3,
        darkenColor = darkenColor,
        lightenColor = lightenColor,
        getContrastColor = getContrastColor,
    },
    _plugins = {},
    _debugLog = {},
}

local function debugLog(msg)
    if StarLib.DebugMode then
        local entry = "[StarLib " .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
        table.insert(StarLib._debugLog, entry)
        print(entry)
    end
end

-- =========================================================================
-- SECTION 9: PLUGIN API
-- =========================================================================

function StarLib:RegisterPlugin(name, plugin)
    if self._plugins[name] then
        warn("[StarLib] Plugin '" .. name .. "' already registered, overwriting.")
    end
    self._plugins[name] = plugin
    debugLog("Plugin registered: " .. name)
    if type(plugin.Init) == "function" then
        plugin:Init(self)
    end
end

function StarLib:GetPlugin(name)
    return self._plugins[name]
end

function StarLib:ListPlugins()
    return tableKeys(self._plugins)
end

-- =========================================================================
-- SECTION 10: GUI PROTECTION
-- =========================================================================

local function protectGui(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        elseif gethui then
            gui.Parent = gethui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- =========================================================================
-- SECTION 11: MAKE DRAGGABLE
-- =========================================================================

local function MakeDraggable(topbar, obj, tweenSpeed)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local d = input.Position - dragStart
        if tweenSpeed and tweenSpeed > 0 then
            TweenService:Create(obj, TweenInfo.new(tweenSpeed, Enum.EasingStyle.Quint), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            }):Play()
        else
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = obj.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then update(i) end
    end)
end

-- =========================================================================
-- SECTION 12: TOOLTIP SYSTEM
-- =========================================================================

local tooltipGui = nil
local tooltipFrame = nil
local tooltipLabel = nil
local tooltipVisible = false

local function ensureTooltipGui()
    if tooltipGui and tooltipGui.Parent then return end
    tooltipGui = Instance.new("ScreenGui")
    tooltipGui.Name = "StarLib_Tooltips"
    tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    tooltipGui.DisplayOrder = 100
    protectGui(tooltipGui)

    tooltipFrame = Instance.new("Frame")
    tooltipFrame.Parent = tooltipGui
    tooltipFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Size = UDim2.new(0, 100, 0, 28)
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 9999
    Instance.new("UICorner", tooltipFrame).CornerRadius = UDim.new(0, 4)
    local pad = Instance.new("UIPadding", tooltipFrame)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)

    tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Parent = tooltipFrame
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.Size = UDim2.new(1, 0, 1, 0)
    tooltipLabel.Font = Enum.Font.Gotham
    tooltipLabel.TextSize = 12
    tooltipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tooltipLabel.ZIndex = 9999
end

local function showTooltip(text, x, y, theme)
    ensureTooltipGui()
    if theme then
        tooltipFrame.BackgroundColor3 = theme.TooltipBG or Color3.fromRGB(50, 50, 50)
    end
    tooltipLabel.Text = text
    local textWidth = tooltipLabel.TextBounds.X + 20
    tooltipFrame.Size = UDim2.new(0, math.max(textWidth, 50), 0, 28)
    tooltipFrame.Position = UDim2.new(0, x + 12, 0, y + 12)
    tooltipFrame.Visible = true
    tooltipVisible = true
end

local function hideTooltip()
    if tooltipFrame then
        tooltipFrame.Visible = false
        tooltipVisible = false
    end
end

local function attachTooltip(guiObj, text, theme)
    if not text or text == "" then return end
    local hoverDelay = 0.5
    local hoverThread = nil

    guiObj.MouseEnter:Connect(function()
        hoverThread = task.delay(hoverDelay, function()
            local mouse = UserInputService:GetMouseLocation()
            showTooltip(text, mouse.X, mouse.Y, theme)
        end)
    end)

    guiObj.MouseMoved:Connect(function()
        if tooltipVisible then
            local mouse = UserInputService:GetMouseLocation()
            if tooltipFrame then
                tooltipFrame.Position = UDim2.new(0, mouse.X + 12, 0, mouse.Y + 12)
            end
        end
    end)

    guiObj.MouseLeave:Connect(function()
        if hoverThread then
            pcall(function() task.cancel(hoverThread) end)
            hoverThread = nil
        end
        hideTooltip()
    end)
end

-- =========================================================================
-- SECTION 13: CONTEXT MENU SYSTEM
-- =========================================================================

local contextGui = nil
local activeContextMenu = nil

local function ensureContextGui()
    if contextGui and contextGui.Parent then return end
    contextGui = Instance.new("ScreenGui")
    contextGui.Name = "StarLib_ContextMenu"
    contextGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    contextGui.DisplayOrder = 99
    protectGui(contextGui)
end

local function closeContextMenu()
    if activeContextMenu and activeContextMenu.Parent then
        activeContextMenu:Destroy()
    end
    activeContextMenu = nil
end

local function openContextMenu(x, y, items, theme)
    closeContextMenu()
    ensureContextGui()
    local T = theme or DEFAULT_THEME

    local menu = Instance.new("Frame")
    menu.Parent = contextGui
    menu.BackgroundColor3 = T.ContextBG or T.ElementBG
    menu.BorderSizePixel = 0
    menu.Position = UDim2.new(0, x, 0, y)
    menu.Size = UDim2.new(0, 180, 0, 0)
    menu.ClipsDescendants = true
    menu.ZIndex = 9990
    Instance.new("UICorner", menu).CornerRadius = T.SmallRadius or UDim.new(0, 4)

    local stroke = Instance.new("UIStroke")
    stroke.Parent = menu
    stroke.Color = T.ContextBorder or T.Divider
    stroke.Thickness = 1

    local layout = Instance.new("UIListLayout", menu)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 1)

    local menuPad = Instance.new("UIPadding", menu)
    menuPad.PaddingTop = UDim.new(0, 4)
    menuPad.PaddingBottom = UDim.new(0, 4)

    local totalHeight = 8
    for idx, item in ipairs(items) do
        if item.Separator then
            local sep = Instance.new("Frame")
            sep.Parent = menu
            sep.BackgroundColor3 = T.Divider
            sep.Size = UDim2.new(1, -16, 0, 1)
            sep.Position = UDim2.new(0, 8, 0, 0)
            sep.BorderSizePixel = 0
            sep.LayoutOrder = idx
            sep.ZIndex = 9991
            totalHeight = totalHeight + 2
        else
            local btn = Instance.new("TextButton")
            btn.Parent = menu
            btn.BackgroundTransparency = 1
            btn.Size = UDim2.new(1, 0, 0, 28)
            btn.Font = T.FontLight or Enum.Font.Gotham
            btn.Text = "  " .. (item.Icon or "") .. (item.Icon and "  " or "") .. item.Name
            btn.TextColor3 = item.Disabled and (T.TextDisabled or Color3.fromRGB(80, 80, 80)) or (item.Color or T.TextPrimary)
            btn.TextSize = T.SmallTextSize or 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            btn.LayoutOrder = idx
            btn.ZIndex = 9991

            if not item.Disabled then
                btn.MouseEnter:Connect(function()
                    btn.BackgroundTransparency = 0
                    btn.BackgroundColor3 = T.ContextHover or T.ElementHover
                end)
                btn.MouseLeave:Connect(function()
                    btn.BackgroundTransparency = 1
                end)
                btn.MouseButton1Click:Connect(function()
                    closeContextMenu()
                    if item.Callback then
                        safeCallback(item.Callback)
                    end
                end)
            end
            totalHeight = totalHeight + 29
        end
    end

    menu.Size = UDim2.new(0, 180, 0, totalHeight)
    activeContextMenu = menu

    local dismiss = Instance.new("TextButton")
    dismiss.Parent = contextGui
    dismiss.BackgroundTransparency = 1
    dismiss.Size = UDim2.new(1, 0, 1, 0)
    dismiss.Text = ""
    dismiss.ZIndex = 9989
    dismiss.MouseButton1Click:Connect(function()
        closeContextMenu()
        dismiss:Destroy()
    end)

    return menu
end

-- =========================================================================
-- SECTION 14: WATERMARK / HUD OVERLAY
-- =========================================================================

function StarLib:CreateWatermark(config)
    config = config or {}
    local wmGui = Instance.new("ScreenGui")
    wmGui.Name = "StarLib_Watermark"
    wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    wmGui.DisplayOrder = 50
    protectGui(wmGui)

    local frame = Instance.new("Frame")
    frame.Parent = wmGui
    frame.BackgroundColor3 = config.BackgroundColor or Color3.fromRGB(24, 24, 24)
    frame.BackgroundTransparency = config.Transparency or 0.3
    frame.Position = config.Position or UDim2.new(1, -220, 0, 10)
    frame.Size = UDim2.new(0, 210, 0, 26)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local accentBar = Instance.new("Frame")
    accentBar.Parent = frame
    accentBar.BackgroundColor3 = config.AccentColor or Color3.fromRGB(0, 170, 255)
    accentBar.Size = UDim2.new(0, 3, 1, -6)
    accentBar.Position = UDim2.new(0, 3, 0, 3)
    accentBar.BorderSizePixel = 0
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Font = config.Font or Enum.Font.GothamSemibold
    label.TextColor3 = config.TextColor or Color3.fromRGB(255, 255, 255)
    label.TextSize = config.TextSize or 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = config.Text or "StarLib v" .. STARLIB_VERSION

    MakeDraggable(frame, frame, 0.15)

    local wm = {}
    function wm:SetText(t) label.Text = t end
    function wm:Show() wmGui.Enabled = true end
    function wm:Hide() wmGui.Enabled = false end
    function wm:Toggle() wmGui.Enabled = not wmGui.Enabled end
    function wm:Destroy() wmGui:Destroy() end
    function wm:SetAccent(c) accentBar.BackgroundColor3 = c end

    if config.FPS then
        task.spawn(function()
            while wmGui.Parent do
                local fps = math.floor(1 / RunService.RenderStepped:Wait())
                local base = config.Text or "StarLib v" .. STARLIB_VERSION
                label.Text = base .. " | " .. fps .. " FPS"
            end
        end)
    end

    if config.ToggleKey then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.ToggleKey then
                wm:Toggle()
            end
        end)
    end

    return wm
end

-- =========================================================================
-- SECTION 15: FPS COUNTER
-- =========================================================================

function StarLib:CreateFPSCounter(config)
    config = config or {}
    local fpsGui = Instance.new("ScreenGui")
    fpsGui.Name = "StarLib_FPS"
    fpsGui.DisplayOrder = 50
    protectGui(fpsGui)

    local label = Instance.new("TextLabel")
    label.Parent = fpsGui
    label.BackgroundColor3 = config.BackgroundColor or Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = config.Transparency or 0.5
    label.Position = config.Position or UDim2.new(0, 10, 0, 10)
    label.Size = UDim2.new(0, 70, 0, 24)
    label.Font = Enum.Font.Code
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextSize = 14
    label.Text = "0 FPS"
    label.BorderSizePixel = 0
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 4)

    local frameCount = 0
    local lastTime = tick()

    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            local fps = math.floor(frameCount / (now - lastTime))
            label.Text = fps .. " FPS"
            if fps >= 55 then label.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif fps >= 30 then label.TextColor3 = Color3.fromRGB(255, 255, 0)
            else label.TextColor3 = Color3.fromRGB(255, 0, 0) end
            frameCount = 0
            lastTime = now
        end
    end)

    local obj = {}
    function obj:Show() fpsGui.Enabled = true end
    function obj:Hide() fpsGui.Enabled = false end
    function obj:Toggle() fpsGui.Enabled = not fpsGui.Enabled end
    function obj:Destroy() fpsGui:Destroy() end
    return obj
end

-- =========================================================================
-- SECTION 16: MULTI-WINDOW MANAGER
-- =========================================================================

function StarLib:GetWindow(name)
    for _, w in ipairs(self.Windows) do
        if w._name == name then return w end
    end
    return nil
end

function StarLib:DestroyAll()
    for i = #self.Windows, 1, -1 do
        pcall(function() self.Windows[i]:Destroy() end)
        table.remove(self.Windows, i)
    end
end

function StarLib:HideAll()
    for _, w in ipairs(self.Windows) do
        pcall(function() w:Hide() end)
    end
end

function StarLib:ShowAll()
    for _, w in ipairs(self.Windows) do
        pcall(function() w:Show() end)
    end
end

function StarLib:ListWindows()
    local list = {}
    for _, w in ipairs(self.Windows) do
        table.insert(list, { name = w._name, enabled = w._gui and w._gui.Enabled or false })
    end
    return list
end

-- =========================================================================
-- SECTION 17: CREATE WINDOW (Main Entry Point)
-- =========================================================================

function StarLib:CreateWindow(config)
    config = config or {}
    local startTime = tick()

    local T = deepCopy(DEFAULT_THEME)
    if config.ThemePreset and THEME_PRESETS[config.ThemePreset] then
        for k, v in pairs(THEME_PRESETS[config.ThemePreset]) do T[k] = v end
    end
    if config.Theme then
        for k, v in pairs(config.Theme) do T[k] = v end
    end

    local guiName = config.GuiName or "StarLibGui_" .. generateId()
    local windowName = config.Name or "StarLib"

    -- Create main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    protectGui(gui)

    -- =====================================================================
    -- LOADING SCREEN
    -- =====================================================================
    local loadingTitle = config.LoadingTitle or config.Name or "StarLib"
    local loadingSubtitle = config.LoadingSubtitle or "Loading..."
    local showLoading = config.Loading ~= false

    if showLoading then
        local loadBg = Instance.new("Frame")
        loadBg.Parent = gui
        loadBg.BackgroundColor3 = T.Background
        loadBg.Size = UDim2.new(1, 0, 1, 0)
        loadBg.ZIndex = 100
        loadBg.BorderSizePixel = 0

        local loadCenter = Instance.new("Frame")
        loadCenter.Parent = loadBg
        loadCenter.BackgroundTransparency = 1
        loadCenter.AnchorPoint = Vector2.new(0.5, 0.5)
        loadCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
        loadCenter.Size = UDim2.new(0, 300, 0, 120)

        local loadTitle = Instance.new("TextLabel")
        loadTitle.Parent = loadCenter
        loadTitle.BackgroundTransparency = 1
        loadTitle.Size = UDim2.new(1, 0, 0, 36)
        loadTitle.Position = UDim2.new(0, 0, 0, 0)
        loadTitle.Font = T.FontBold
        loadTitle.TextSize = 24
        loadTitle.TextColor3 = T.TextPrimary
        loadTitle.Text = loadingTitle

        local loadSub = Instance.new("TextLabel")
        loadSub.Parent = loadCenter
        loadSub.BackgroundTransparency = 1
        loadSub.Size = UDim2.new(1, 0, 0, 20)
        loadSub.Position = UDim2.new(0, 0, 0, 40)
        loadSub.Font = T.FontLight
        loadSub.TextSize = 14
        loadSub.TextColor3 = T.TextMuted
        loadSub.Text = loadingSubtitle

        local trackBg = Instance.new("Frame")
        trackBg.Parent = loadCenter
        trackBg.BackgroundColor3 = T.SliderTrack
        trackBg.Position = UDim2.new(0, 20, 0, 75)
        trackBg.Size = UDim2.new(1, -40, 0, 4)
        trackBg.BorderSizePixel = 0
        Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

        local trackFill = Instance.new("Frame")
        trackFill.Parent = trackBg
        trackFill.BackgroundColor3 = T.Accent
        trackFill.Size = UDim2.new(0, 0, 1, 0)
        trackFill.BorderSizePixel = 0
        Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1, 0)

        local versionLabel = Instance.new("TextLabel")
        versionLabel.Parent = loadCenter
        versionLabel.BackgroundTransparency = 1
        versionLabel.Size = UDim2.new(1, 0, 0, 16)
        versionLabel.Position = UDim2.new(0, 0, 0, 95)
        versionLabel.Font = T.FontLight
        versionLabel.TextSize = 11
        versionLabel.TextColor3 = T.TextMuted
        versionLabel.Text = "StarLib v" .. STARLIB_VERSION

        task.spawn(function()
            local steps = 20
            for i = 1, steps do
                TweenService:Create(trackFill, TweenInfo.new(0.08), {
                    Size = UDim2.new(i / steps, 0, 1, 0)
                }):Play()
                task.wait(0.05 + math.random() * 0.04)
            end
            task.wait(0.3)
            TweenService:Create(loadBg, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(loadTitle, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            TweenService:Create(loadSub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            TweenService:Create(versionLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
            task.wait(0.5)
            loadBg:Destroy()
        end)
    end

    -- =====================================================================
    -- MAIN FRAME
    -- =====================================================================
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Parent = gui
    main.BackgroundColor3 = T.Background
    main.Position = config.Position or UDim2.new(0.5, -T.WindowSize.X.Offset / 2, 0.5, -T.WindowSize.Y.Offset / 2)
    main.Size = T.WindowSize
    main.ClipsDescendants = true
    Instance.new("UICorner", main).CornerRadius = T.CornerRadius

    local shadow = Instance.new("ImageLabel")
    shadow.Parent = main
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = -1
    shadow.ImageTransparency = 0.6
    shadow.Image = "rbxassetid://5554236805"
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)

    -- =====================================================================
    -- TOP BAR
    -- =====================================================================
    local topbar = Instance.new("Frame")
    topbar.Name = "TopBar"
    topbar.Parent = main
    topbar.BackgroundColor3 = T.TopBar
    topbar.Size = UDim2.new(1, 0, 0, T.TopBarHeight)
    topbar.BorderSizePixel = 0

    local title = Instance.new("TextLabel")
    title.Parent = topbar
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 15, 0, 0)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Font = T.FontBold
    title.Text = windowName
    title.TextColor3 = T.TextPrimary
    title.TextSize = T.TitleSize
    title.TextXAlignment = Enum.TextXAlignment.Left

    MakeDraggable(topbar, main, T.TweenSpeed)

    local minimized = false
    local savedSize = T.WindowSize

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = topbar
    closeBtn.BackgroundTransparency = 1
    closeBtn.Position = UDim2.new(1, -40, 0, 0)
    closeBtn.Size = UDim2.new(0, 40, 1, 0)
    closeBtn.Font = T.FontBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = T.TextMuted
    closeBtn.TextSize = 22
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = T.Error }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = T.TextMuted }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Parent = topbar
    minBtn.BackgroundTransparency = 1
    minBtn.Position = UDim2.new(1, -75, 0, 0)
    minBtn.Size = UDim2.new(0, 35, 1, 0)
    minBtn.Font = T.FontBold
    minBtn.Text = "—"
    minBtn.TextColor3 = T.TextMuted
    minBtn.TextSize = 16
    minBtn.MouseEnter:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), { TextColor3 = T.TextPrimary }):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        TweenService:Create(minBtn, TweenInfo.new(0.15), { TextColor3 = T.TextMuted }):Play()
    end)
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(main, TweenInfo.new(T.TweenSpeed, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, T.WindowSize.X.Offset, 0, T.TopBarHeight)
            }):Play()
            minBtn.Text = "+"
        else
            TweenService:Create(main, TweenInfo.new(T.TweenSpeed, Enum.EasingStyle.Quint), {
                Size = T.WindowSize
            }):Play()
            minBtn.Text = "—"
        end
    end)

    -- Top bar divider
    local topDivider = Instance.new("Frame")
    topDivider.Parent = topbar
    topDivider.BackgroundColor3 = T.Divider
    topDivider.Position = UDim2.new(0, 0, 1, -1)
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.BorderSizePixel = 0

    -- =====================================================================
    -- SIDEBAR
    -- =====================================================================
    local sidebar = Instance.new("Frame")
    sidebar.Parent = main
    sidebar.BackgroundColor3 = T.Sidebar
    sidebar.Position = UDim2.new(0, 0, 0, T.TopBarHeight)
    sidebar.Size = UDim2.new(0, T.SidebarWidth, 1, -T.TopBarHeight)
    sidebar.BorderSizePixel = 0

    local sideList = Instance.new("ScrollingFrame")
    sideList.Parent = sidebar
    sideList.BackgroundTransparency = 1
    sideList.Size = UDim2.new(1, 0, 1, 0)
    sideList.ScrollBarThickness = 2
    sideList.ScrollBarImageColor3 = T.ScrollBar
    sideList.CanvasSize = UDim2.new(0, 0, 0, 0)
    sideList.BorderSizePixel = 0

    local sideLayout = Instance.new("UIListLayout", sideList)
    sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sideLayout.Padding = UDim.new(0, 4)

    local sidePad = Instance.new("UIPadding", sideList)
    sidePad.PaddingLeft = UDim.new(0, 8)
    sidePad.PaddingTop = UDim.new(0, 8)
    sidePad.PaddingRight = UDim.new(0, 8)
    sidePad.PaddingBottom = UDim.new(0, 8)

    -- Sidebar divider
    local sideDivider = Instance.new("Frame")
    sideDivider.Parent = sidebar
    sideDivider.BackgroundColor3 = T.Divider
    sideDivider.Position = UDim2.new(1, -1, 0, 0)
    sideDivider.Size = UDim2.new(0, 1, 1, 0)
    sideDivider.BorderSizePixel = 0

    -- =====================================================================
    -- CONTENT AREA
    -- =====================================================================
    local content = Instance.new("Frame")
    content.Parent = main
    content.BackgroundColor3 = T.Background
    content.Position = UDim2.new(0, T.SidebarWidth, 0, T.TopBarHeight)
    content.Size = UDim2.new(1, -T.SidebarWidth, 1, -T.TopBarHeight)
    content.BorderSizePixel = 0

    -- =====================================================================
    -- WINDOW OBJECT
    -- =====================================================================
    local W = {
        CurrentTab = nil,
        Tabs = {},
        GUI = gui,
        Theme = T,
        _name = windowName,
        _gui = gui,
        _main = main,
        _content = content,
        _widgetRegistry = {},
        _tabOrder = {},
        _connections = {},
        _destroyed = false,
        OnDestroyed = createSignal(),
        OnTabChanged = createSignal(),
        OnMinimized = createSignal(),
    }

    table.insert(StarLib.Windows, W)

    -- Toggle keybind
    if config.ToggleKey then
        local conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.ToggleKey then
                gui.Enabled = not gui.Enabled
            end
        end)
        table.insert(W._connections, conn)
    end

    -- =================================================================
    -- NOTIFICATION SYSTEM (Stacking, Typed, Progress)
    -- =================================================================
    local notifContainer = nil
    local activeNotifs = {}

    local function ensureNotifContainer()
        if notifContainer and notifContainer.Parent then return notifContainer end
        local nGui = Instance.new("ScreenGui")
        nGui.Name = guiName .. "_Notifs"
        nGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        nGui.DisplayOrder = 80
        protectGui(nGui)

        notifContainer = Instance.new("Frame")
        notifContainer.Parent = nGui
        notifContainer.BackgroundTransparency = 1
        notifContainer.AnchorPoint = Vector2.new(1, 1)
        notifContainer.Position = UDim2.new(1, -15, 1, -15)
        notifContainer.Size = UDim2.new(0, 280, 1, -30)
        notifContainer.ClipsDescendants = false

        local nLayout = Instance.new("UIListLayout", notifContainer)
        nLayout.SortOrder = Enum.SortOrder.LayoutOrder
        nLayout.Padding = UDim.new(0, 8)
        nLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

        return notifContainer
    end

    local function getNotifTypeColor(ntype)
        ntype = ntype and ntype:lower() or "info"
        if ntype == "success" then return T.Success
        elseif ntype == "warning" then return T.Warning
        elseif ntype == "error" then return T.Error
        else return T.Info end
    end

    local function getNotifTypeIcon(ntype)
        ntype = ntype and ntype:lower() or "info"
        if ntype == "success" then return "✓"
        elseif ntype == "warning" then return "⚠"
        elseif ntype == "error" then return "✗"
        else return "ℹ" end
    end

    function W:Notify(cfg)
        if W._destroyed then return end
        ensureNotifContainer()

        while #activeNotifs >= (T.MaxNotifs or 5) do
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then
                oldest:Destroy()
            end
        end

        local duration = cfg.Duration or T.NotifDuration or 4
        local ntype = cfg.Type or "info"
        local typeColor = getNotifTypeColor(ntype)
        local typeIcon = getNotifTypeIcon(ntype)

        local nf = Instance.new("Frame")
        nf.Parent = notifContainer
        nf.BackgroundColor3 = T.NotifBG
        nf.Size = UDim2.new(0, 270, 0, 0)
        nf.ClipsDescendants = true
        nf.BorderSizePixel = 0
        nf.LayoutOrder = tick() * 1000
        Instance.new("UICorner", nf).CornerRadius = T.CornerRadius

        local accentLine = Instance.new("Frame")
        accentLine.Parent = nf
        accentLine.BackgroundColor3 = typeColor
        accentLine.Size = UDim2.new(0, 3, 1, -8)
        accentLine.Position = UDim2.new(0, 4, 0, 4)
        accentLine.BorderSizePixel = 0
        Instance.new("UICorner", accentLine).CornerRadius = UDim.new(0, 2)

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Parent = nf
        iconLabel.BackgroundTransparency = 1
        iconLabel.Position = UDim2.new(0, 14, 0, 8)
        iconLabel.Size = UDim2.new(0, 20, 0, 20)
        iconLabel.Text = typeIcon
        iconLabel.TextColor3 = typeColor
        iconLabel.Font = T.FontBold
        iconLabel.TextSize = 16

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = nf
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 38, 0, 6)
        titleLabel.Size = UDim2.new(1, -75, 0, 20)
        titleLabel.Font = T.FontBold
        titleLabel.Text = cfg.Title or "Notification"
        titleLabel.TextColor3 = T.TextPrimary
        titleLabel.TextSize = T.TextSize
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local contentLabel = Instance.new("TextLabel")
        contentLabel.Parent = nf
        contentLabel.BackgroundTransparency = 1
        contentLabel.Position = UDim2.new(0, 38, 0, 26)
        contentLabel.Size = UDim2.new(1, -50, 0, 40)
        contentLabel.Font = T.FontLight
        contentLabel.Text = cfg.Content or ""
        contentLabel.TextColor3 = T.TextSecondary
        contentLabel.TextSize = T.SmallTextSize
        contentLabel.TextXAlignment = Enum.TextXAlignment.Left
        contentLabel.TextYAlignment = Enum.TextYAlignment.Top
        contentLabel.TextWrapped = true

        local closeNotifBtn = Instance.new("TextButton")
        closeNotifBtn.Parent = nf
        closeNotifBtn.BackgroundTransparency = 1
        closeNotifBtn.Position = UDim2.new(1, -28, 0, 4)
        closeNotifBtn.Size = UDim2.new(0, 24, 0, 24)
        closeNotifBtn.Text = "×"
        closeNotifBtn.TextColor3 = T.TextMuted
        closeNotifBtn.Font = T.FontBold
        closeNotifBtn.TextSize = 16

        local progressTrack = Instance.new("Frame")
        progressTrack.Parent = nf
        progressTrack.BackgroundColor3 = T.SliderTrack
        progressTrack.Position = UDim2.new(0, 12, 1, -10)
        progressTrack.Size = UDim2.new(1, -24, 0, 3)
        progressTrack.BorderSizePixel = 0
        Instance.new("UICorner", progressTrack).CornerRadius = UDim.new(1, 0)

        local progressFill = Instance.new("Frame")
        progressFill.Parent = progressTrack
        progressFill.BackgroundColor3 = typeColor
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BorderSizePixel = 0
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

        local totalHeight = 80
        nf.Size = UDim2.new(0, 270, 0, 0)
        TweenService:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 270, 0, totalHeight)
        }):Play()

        table.insert(activeNotifs, nf)

        local dismissed = false
        local function dismiss()
            if dismissed then return end
            dismissed = true
            tableRemove(activeNotifs, nf)
            TweenService:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 270, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.35, function()
                if nf.Parent then nf:Destroy() end
            end)
            if cfg.OnClose then safeCallback(cfg.OnClose) end
        end

        closeNotifBtn.MouseButton1Click:Connect(dismiss)

        task.spawn(function()
            TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            }):Play()
            task.wait(duration)
            dismiss()
        end)
    end

    -- =================================================================
    -- MODAL / DIALOG SYSTEM
    -- =================================================================

    local modalOverlay = nil
    local modalActive = false

    local function createModalOverlay()
        if modalOverlay and modalOverlay.Parent then return modalOverlay end
        modalOverlay = Instance.new("Frame")
        modalOverlay.Parent = gui
        modalOverlay.BackgroundColor3 = T.ModalOverlay
        modalOverlay.BackgroundTransparency = 1
        modalOverlay.Size = UDim2.new(1, 0, 1, 0)
        modalOverlay.ZIndex = 50
        modalOverlay.Visible = false
        modalOverlay.BorderSizePixel = 0
        return modalOverlay
    end

    local function showModal(dialogFrame)
        if modalActive then return end
        modalActive = true
        local overlay = createModalOverlay()
        overlay.Visible = true
        TweenService:Create(overlay, TweenInfo.new(0.2), {
            BackgroundTransparency = T.ModalOverlayAlpha
        }):Play()
        dialogFrame.Parent = gui
        dialogFrame.Visible = true
        dialogFrame.Size = UDim2.new(0, 0, 0, 0)
        dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        local targetSize = dialogFrame:GetAttribute("TargetSize") or UDim2.new(0, 350, 0, 180)
        TweenService:Create(dialogFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize
        }):Play()
    end

    local function hideModal(dialogFrame)
        if not modalActive then return end
        TweenService:Create(dialogFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        if modalOverlay then
            TweenService:Create(modalOverlay, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
        end
        task.delay(0.25, function()
            if dialogFrame.Parent then dialogFrame:Destroy() end
            if modalOverlay then modalOverlay.Visible = false end
            modalActive = false
        end)
    end

    function W:Confirm(cfg)
        local dialog = Instance.new("Frame")
        dialog.BackgroundColor3 = T.ElementBG
        dialog.ZIndex = 55
        dialog.ClipsDescendants = true
        dialog.BorderSizePixel = 0
        dialog:SetAttribute("TargetSize", UDim2.new(0, 360, 0, 175))
        Instance.new("UICorner", dialog).CornerRadius = T.CornerRadius

        local dTitle = Instance.new("TextLabel")
        dTitle.Parent = dialog
        dTitle.BackgroundTransparency = 1
        dTitle.Position = UDim2.new(0, 20, 0, 15)
        dTitle.Size = UDim2.new(1, -40, 0, 24)
        dTitle.Font = T.FontBold
        dTitle.Text = cfg.Title or "Confirm"
        dTitle.TextColor3 = T.TextPrimary
        dTitle.TextSize = T.TitleSize
        dTitle.TextXAlignment = Enum.TextXAlignment.Left
        dTitle.ZIndex = 56

        local dContent = Instance.new("TextLabel")
        dContent.Parent = dialog
        dContent.BackgroundTransparency = 1
        dContent.Position = UDim2.new(0, 20, 0, 45)
        dContent.Size = UDim2.new(1, -40, 0, 60)
        dContent.Font = T.FontLight
        dContent.Text = cfg.Content or "Are you sure?"
        dContent.TextColor3 = T.TextSecondary
        dContent.TextSize = T.TextSize
        dContent.TextXAlignment = Enum.TextXAlignment.Left
        dContent.TextYAlignment = Enum.TextYAlignment.Top
        dContent.TextWrapped = true
        dContent.ZIndex = 56

        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Parent = dialog
        confirmBtn.BackgroundColor3 = T.Accent
        confirmBtn.Position = UDim2.new(0.5, 5, 1, -50)
        confirmBtn.Size = UDim2.new(0.5, -25, 0, 36)
        confirmBtn.Font = T.Font
        confirmBtn.Text = cfg.ConfirmText or "Confirm"
        confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmBtn.TextSize = T.TextSize
        confirmBtn.AutoButtonColor = false
        confirmBtn.ZIndex = 56
        Instance.new("UICorner", confirmBtn).CornerRadius = T.ElementRadius

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Parent = dialog
        cancelBtn.BackgroundColor3 = T.SliderTrack
        cancelBtn.Position = UDim2.new(0, 20, 1, -50)
        cancelBtn.Size = UDim2.new(0.5, -25, 0, 36)
        cancelBtn.Font = T.Font
        cancelBtn.Text = cfg.CancelText or "Cancel"
        cancelBtn.TextColor3 = T.TextPrimary
        cancelBtn.TextSize = T.TextSize
        cancelBtn.AutoButtonColor = false
        cancelBtn.ZIndex = 56
        Instance.new("UICorner", cancelBtn).CornerRadius = T.ElementRadius

        confirmBtn.MouseButton1Click:Connect(function()
            hideModal(dialog)
            if cfg.Callback then safeCallback(cfg.Callback, true) end
        end)
        cancelBtn.MouseButton1Click:Connect(function()
            hideModal(dialog)
            if cfg.Callback then safeCallback(cfg.Callback, false) end
        end)

        showModal(dialog)
    end

    function W:Alert(cfg)
        local dialog = Instance.new("Frame")
        dialog.BackgroundColor3 = T.ElementBG
        dialog.ZIndex = 55
        dialog.ClipsDescendants = true
        dialog.BorderSizePixel = 0
        dialog:SetAttribute("TargetSize", UDim2.new(0, 340, 0, 155))
        Instance.new("UICorner", dialog).CornerRadius = T.CornerRadius

        local dTitle = Instance.new("TextLabel")
        dTitle.Parent = dialog
        dTitle.BackgroundTransparency = 1
        dTitle.Position = UDim2.new(0, 20, 0, 15)
        dTitle.Size = UDim2.new(1, -40, 0, 24)
        dTitle.Font = T.FontBold
        dTitle.Text = cfg.Title or "Alert"
        dTitle.TextColor3 = T.TextPrimary
        dTitle.TextSize = T.TitleSize
        dTitle.TextXAlignment = Enum.TextXAlignment.Left
        dTitle.ZIndex = 56

        local dContent = Instance.new("TextLabel")
        dContent.Parent = dialog
        dContent.BackgroundTransparency = 1
        dContent.Position = UDim2.new(0, 20, 0, 45)
        dContent.Size = UDim2.new(1, -40, 0, 50)
        dContent.Font = T.FontLight
        dContent.Text = cfg.Content or ""
        dContent.TextColor3 = T.TextSecondary
        dContent.TextSize = T.TextSize
        dContent.TextXAlignment = Enum.TextXAlignment.Left
        dContent.TextYAlignment = Enum.TextYAlignment.Top
        dContent.TextWrapped = true
        dContent.ZIndex = 56

        local okBtn = Instance.new("TextButton")
        okBtn.Parent = dialog
        okBtn.BackgroundColor3 = T.Accent
        okBtn.Position = UDim2.new(0.5, -60, 1, -48)
        okBtn.Size = UDim2.new(0, 120, 0, 36)
        okBtn.Font = T.Font
        okBtn.Text = cfg.ButtonText or "OK"
        okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        okBtn.TextSize = T.TextSize
        okBtn.AutoButtonColor = false
        okBtn.ZIndex = 56
        Instance.new("UICorner", okBtn).CornerRadius = T.ElementRadius

        okBtn.MouseButton1Click:Connect(function()
            hideModal(dialog)
            if cfg.Callback then safeCallback(cfg.Callback) end
        end)

        showModal(dialog)
    end

    function W:Prompt(cfg)
        local dialog = Instance.new("Frame")
        dialog.BackgroundColor3 = T.ElementBG
        dialog.ZIndex = 55
        dialog.ClipsDescendants = true
        dialog.BorderSizePixel = 0
        dialog:SetAttribute("TargetSize", UDim2.new(0, 360, 0, 200))
        Instance.new("UICorner", dialog).CornerRadius = T.CornerRadius

        local dTitle = Instance.new("TextLabel")
        dTitle.Parent = dialog
        dTitle.BackgroundTransparency = 1
        dTitle.Position = UDim2.new(0, 20, 0, 15)
        dTitle.Size = UDim2.new(1, -40, 0, 24)
        dTitle.Font = T.FontBold
        dTitle.Text = cfg.Title or "Input"
        dTitle.TextColor3 = T.TextPrimary
        dTitle.TextSize = T.TitleSize
        dTitle.TextXAlignment = Enum.TextXAlignment.Left
        dTitle.ZIndex = 56

        local inputBg = Instance.new("Frame")
        inputBg.Parent = dialog
        inputBg.BackgroundColor3 = T.InputBG
        inputBg.Position = UDim2.new(0, 20, 0, 55)
        inputBg.Size = UDim2.new(1, -40, 0, 36)
        inputBg.ZIndex = 56
        inputBg.BorderSizePixel = 0
        Instance.new("UICorner", inputBg).CornerRadius = T.ElementRadius

        local inputBox = Instance.new("TextBox")
        inputBox.Parent = inputBg
        inputBox.BackgroundTransparency = 1
        inputBox.Size = UDim2.new(1, -16, 1, 0)
        inputBox.Position = UDim2.new(0, 8, 0, 0)
        inputBox.Font = T.FontLight
        inputBox.PlaceholderText = cfg.Placeholder or "Type here..."
        inputBox.Text = cfg.Default or ""
        inputBox.TextColor3 = T.TextPrimary
        inputBox.TextSize = T.TextSize
        inputBox.ClearTextOnFocus = false
        inputBox.TextXAlignment = Enum.TextXAlignment.Left
        inputBox.ZIndex = 57

        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Parent = dialog
        confirmBtn.BackgroundColor3 = T.Accent
        confirmBtn.Position = UDim2.new(0.5, 5, 1, -50)
        confirmBtn.Size = UDim2.new(0.5, -25, 0, 36)
        confirmBtn.Font = T.Font
        confirmBtn.Text = cfg.ConfirmText or "Submit"
        confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmBtn.TextSize = T.TextSize
        confirmBtn.AutoButtonColor = false
        confirmBtn.ZIndex = 56
        Instance.new("UICorner", confirmBtn).CornerRadius = T.ElementRadius

        local cancelBtn = Instance.new("TextButton")
        cancelBtn.Parent = dialog
        cancelBtn.BackgroundColor3 = T.SliderTrack
        cancelBtn.Position = UDim2.new(0, 20, 1, -50)
        cancelBtn.Size = UDim2.new(0.5, -25, 0, 36)
        cancelBtn.Font = T.Font
        cancelBtn.Text = cfg.CancelText or "Cancel"
        cancelBtn.TextColor3 = T.TextPrimary
        cancelBtn.TextSize = T.TextSize
        cancelBtn.AutoButtonColor = false
        cancelBtn.ZIndex = 56
        Instance.new("UICorner", cancelBtn).CornerRadius = T.ElementRadius

        confirmBtn.MouseButton1Click:Connect(function()
            local text = inputBox.Text
            hideModal(dialog)
            if cfg.Callback then safeCallback(cfg.Callback, text) end
        end)
        cancelBtn.MouseButton1Click:Connect(function()
            hideModal(dialog)
            if cfg.Callback then safeCallback(cfg.Callback, nil) end
        end)

        inputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local text = inputBox.Text
                hideModal(dialog)
                if cfg.Callback then safeCallback(cfg.Callback, text) end
            end
        end)

        showModal(dialog)
        task.defer(function() inputBox:CaptureFocus() end)
    end

    -- =================================================================
    -- COMMAND PALETTE
    -- =================================================================

    local commandPaletteOpen = false
    local commandPaletteItems = {}

    function W:RegisterCommand(cfg)
        table.insert(commandPaletteItems, {
            Name = cfg.Name or "Command",
            Description = cfg.Description or "",
            Callback = cfg.Callback,
            Shortcut = cfg.Shortcut or "",
        })
    end

    function W:OpenCommandPalette()
        if commandPaletteOpen then return end
        commandPaletteOpen = true

        local overlay = Instance.new("Frame")
        overlay.Parent = gui
        overlay.BackgroundColor3 = T.ModalOverlay
        overlay.BackgroundTransparency = 0.4
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.ZIndex = 60
        overlay.BorderSizePixel = 0

        local paletteFrame = Instance.new("Frame")
        paletteFrame.Parent = gui
        paletteFrame.BackgroundColor3 = T.ElementBG
        paletteFrame.AnchorPoint = Vector2.new(0.5, 0)
        paletteFrame.Position = UDim2.new(0.5, 0, 0, 80)
        paletteFrame.Size = UDim2.new(0, 420, 0, 50)
        paletteFrame.ZIndex = 61
        paletteFrame.ClipsDescendants = true
        paletteFrame.BorderSizePixel = 0
        Instance.new("UICorner", paletteFrame).CornerRadius = T.CornerRadius

        local searchBox = Instance.new("TextBox")
        searchBox.Parent = paletteFrame
        searchBox.BackgroundTransparency = 1
        searchBox.Position = UDim2.new(0, 15, 0, 0)
        searchBox.Size = UDim2.new(1, -30, 0, 44)
        searchBox.Font = T.Font
        searchBox.PlaceholderText = "Type a command..."
        searchBox.Text = ""
        searchBox.TextColor3 = T.TextPrimary
        searchBox.PlaceholderColor3 = T.TextMuted
        searchBox.TextSize = T.TextSize
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.ZIndex = 62

        local resultsList = Instance.new("ScrollingFrame")
        resultsList.Parent = paletteFrame
        resultsList.BackgroundTransparency = 1
        resultsList.Position = UDim2.new(0, 0, 0, 44)
        resultsList.Size = UDim2.new(1, 0, 1, -44)
        resultsList.ScrollBarThickness = 2
        resultsList.ScrollBarImageColor3 = T.ScrollBar
        resultsList.CanvasSize = UDim2.new(0, 0, 0, 0)
        resultsList.BorderSizePixel = 0
        resultsList.ZIndex = 62

        local rLayout = Instance.new("UIListLayout", resultsList)
        rLayout.Padding = UDim.new(0, 1)

        local function buildResults(filter)
            for _, ch in ipairs(resultsList:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            local count = 0
            for _, cmd in ipairs(commandPaletteItems) do
                local nameMatch = filter == "" or cmd.Name:lower():find(filter:lower(), 1, true)
                local descMatch = filter == "" or cmd.Description:lower():find(filter:lower(), 1, true)
                if nameMatch or descMatch then
                    count = count + 1
                    local btn = Instance.new("TextButton")
                    btn.Parent = resultsList
                    btn.BackgroundTransparency = 1
                    btn.Size = UDim2.new(1, 0, 0, 34)
                    btn.Font = T.Font
                    btn.Text = "  " .. cmd.Name
                    btn.TextColor3 = T.TextPrimary
                    btn.TextSize = T.SmallTextSize
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    btn.AutoButtonColor = false
                    btn.ZIndex = 63

                    if cmd.Shortcut ~= "" then
                        local shortLabel = Instance.new("TextLabel")
                        shortLabel.Parent = btn
                        shortLabel.BackgroundTransparency = 1
                        shortLabel.Position = UDim2.new(1, -80, 0, 0)
                        shortLabel.Size = UDim2.new(0, 70, 1, 0)
                        shortLabel.Font = T.FontMono
                        shortLabel.Text = cmd.Shortcut
                        shortLabel.TextColor3 = T.TextMuted
                        shortLabel.TextSize = T.TinyTextSize
                        shortLabel.TextXAlignment = Enum.TextXAlignment.Right
                        shortLabel.ZIndex = 63
                    end

                    btn.MouseEnter:Connect(function()
                        btn.BackgroundTransparency = 0
                        btn.BackgroundColor3 = T.ElementHover
                    end)
                    btn.MouseLeave:Connect(function()
                        btn.BackgroundTransparency = 1
                    end)
                    btn.MouseButton1Click:Connect(function()
                        commandPaletteOpen = false
                        overlay:Destroy()
                        paletteFrame:Destroy()
                        if cmd.Callback then safeCallback(cmd.Callback) end
                    end)

                    if count >= 10 then break end
                end
            end
            resultsList.CanvasSize = UDim2.new(0, 0, 0, count * 35)
            paletteFrame.Size = UDim2.new(0, 420, 0, 50 + math.min(count, 8) * 35)
        end

        buildResults("")

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            buildResults(searchBox.Text)
        end)

        overlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                commandPaletteOpen = false
                overlay:Destroy()
                paletteFrame:Destroy()
            end
        end)

        task.defer(function() searchBox:CaptureFocus() end)

        searchBox.FocusLost:Connect(function(enterPressed)
            if not enterPressed then
                task.delay(0.1, function()
                    if commandPaletteOpen then
                        commandPaletteOpen = false
                        if overlay.Parent then overlay:Destroy() end
                        if paletteFrame.Parent then paletteFrame:Destroy() end
                    end
                end)
            end
        end)
    end

    -- =================================================================
    -- WINDOW METHODS
    -- =================================================================

    function W:SetTitle(txt) title.Text = txt; W._name = txt end

    function W:Destroy()
        W._destroyed = true
        for _, conn in ipairs(W._connections) do
            pcall(function() conn:Disconnect() end)
        end
        gui:Destroy()
        W.OnDestroyed:Fire()
        for i = #StarLib.Windows, 1, -1 do
            if StarLib.Windows[i] == W then
                table.remove(StarLib.Windows, i)
                break
            end
        end
    end

    function W:Hide() gui.Enabled = false end
    function W:Show() gui.Enabled = true end
    function W:Toggle() gui.Enabled = not gui.Enabled end
    function W:IsVisible() return gui.Enabled end

    function W:Rename(newName)
        title.Text = newName
        W._name = newName
    end

    function W:SetAccent(color)
        T.Accent = color
        EventBus:emit("accent_changed", color)
    end

    function W:SetOpacity(alpha)
        main.BackgroundTransparency = 1 - alpha
    end

    function W:SetTheme(themeOverrides)
        for k, v in pairs(themeOverrides) do T[k] = v end
        main.BackgroundColor3 = T.Background
        topbar.BackgroundColor3 = T.TopBar
        sidebar.BackgroundColor3 = T.Sidebar
        content.BackgroundColor3 = T.Background
    end

    function W:ApplyPreset(presetName)
        local preset = THEME_PRESETS[presetName]
        if preset then
            W:SetTheme(preset)
        end
    end

    -- =================================================================
    -- STATE PERSISTENCE
    -- =================================================================

    function W:ExportState()
        local state = { toggles = {}, sliders = {}, dropdowns = {}, inputs = {}, keybinds = {} }
        for name, widget in pairs(W._widgetRegistry) do
            if widget._type == "toggle" then
                state.toggles[name] = widget:Get()
            elseif widget._type == "slider" then
                state.sliders[name] = widget:Get()
            elseif widget._type == "dropdown" then
                state.dropdowns[name] = widget:GetValue()
            elseif widget._type == "input" then
                state.inputs[name] = widget:Get()
            elseif widget._type == "keybind" then
                state.keybinds[name] = widget:GetKey()
            end
        end
        return state
    end

    function W:ImportState(stateTable)
        if not stateTable then return end
        if stateTable.toggles then
            for name, val in pairs(stateTable.toggles) do
                local w = W._widgetRegistry[name]
                if w and w._type == "toggle" then pcall(function() w:Set(val) end) end
            end
        end
        if stateTable.sliders then
            for name, val in pairs(stateTable.sliders) do
                local w = W._widgetRegistry[name]
                if w and w._type == "slider" then pcall(function() w:Set(val) end) end
            end
        end
        if stateTable.dropdowns then
            for name, val in pairs(stateTable.dropdowns) do
                local w = W._widgetRegistry[name]
                if w and w._type == "dropdown" then pcall(function() w:SetValue(val) end) end
            end
        end
        if stateTable.inputs then
            for name, val in pairs(stateTable.inputs) do
                local w = W._widgetRegistry[name]
                if w and w._type == "input" then pcall(function() w:Set(val) end) end
            end
        end
        if stateTable.keybinds then
            for name, val in pairs(stateTable.keybinds) do
                local w = W._widgetRegistry[name]
                if w and w._type == "keybind" then pcall(function() w:SetKey(val) end) end
            end
        end
    end

    function W:AutoSave(key)
        task.spawn(function()
            while not W._destroyed do
                task.wait(5)
                pcall(function()
                    local state = W:ExportState()
                    local json = HttpService:JSONEncode(state)
                    if writefile then writefile(key .. ".json", json) end
                end)
            end
        end)
    end

    function W:AutoLoad(key)
        pcall(function()
            if readfile and isfile and isfile(key .. ".json") then
                local json = readfile(key .. ".json")
                local state = HttpService:JSONDecode(json)
                W:ImportState(state)
                debugLog("Auto-loaded state from " .. key)
            end
        end)
    end

    -- =================================================================
    -- TAB SYSTEM
    -- =================================================================

    local tabLayoutOrder = 0

    function W:CreateTab(name, cfg)
        cfg = cfg or {}
        tabLayoutOrder = tabLayoutOrder + 1

        local btn = Instance.new("TextButton")
        btn.Parent = sideList
        btn.BackgroundColor3 = T.TabDefault
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.Font = T.Font
        btn.Text = "  " .. (cfg.Icon and (cfg.Icon .. "  ") or "") .. name
        btn.TextColor3 = T.TextSecondary
        btn.TextSize = T.TextSize
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.LayoutOrder = tabLayoutOrder
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = T.ElementRadius

        local badgeLabel = nil
        if cfg.Badge then
            badgeLabel = Instance.new("TextLabel")
            badgeLabel.Parent = btn
            badgeLabel.BackgroundColor3 = T.Error
            badgeLabel.Position = UDim2.new(1, -28, 0.5, -9)
            badgeLabel.Size = UDim2.new(0, 18, 0, 18)
            badgeLabel.Font = T.FontBold
            badgeLabel.TextSize = 10
            badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            badgeLabel.Text = tostring(cfg.Badge)
            Instance.new("UICorner", badgeLabel).CornerRadius = UDim.new(1, 0)
        end

        -- Hover effects
        btn.MouseEnter:Connect(function()
            if W.CurrentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(T.FastTween), {
                    BackgroundColor3 = T.TabHover
                }):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if W.CurrentTab ~= name then
                TweenService:Create(btn, TweenInfo.new(T.FastTween), {
                    BackgroundColor3 = T.TabDefault
                }):Play()
            end
        end)

        local container = Instance.new("ScrollingFrame")
        container.Parent = content
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.ScrollBarThickness = 3
        container.ScrollBarImageColor3 = T.ScrollBar
        container.Visible = false
        container.CanvasSize = UDim2.new(0, 0, 0, 0)
        container.BorderSizePixel = 0

        local cl = Instance.new("UIListLayout", container)
        cl.SortOrder = Enum.SortOrder.LayoutOrder
        cl.Padding = UDim.new(0, 6)

        local cp = Instance.new("UIPadding", container)
        cp.PaddingLeft = UDim.new(0, 15)
        cp.PaddingTop = UDim.new(0, 12)
        cp.PaddingRight = UDim.new(0, 15)
        cp.PaddingBottom = UDim.new(0, 15)

        cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            container.CanvasSize = UDim2.new(0, 0, 0, cl.AbsoluteContentSize.Y + 30)
        end)
        sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            sideList.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 16)
        end)

        local function selectTab()
            for tName, tab in pairs(W.Tabs) do
                tab.Container.Visible = false
                TweenService:Create(tab.Button, TweenInfo.new(T.FastTween), {
                    BackgroundColor3 = T.TabDefault,
                    TextColor3 = T.TextSecondary
                }):Play()
            end
            container.Visible = true
            TweenService:Create(btn, TweenInfo.new(T.FastTween), {
                BackgroundColor3 = T.TabActive,
                TextColor3 = T.TextPrimary
            }):Play()
            W.CurrentTab = name
            W.OnTabChanged:Fire(name)
        end

        btn.MouseButton1Click:Connect(selectTab)

        if not W.CurrentTab then
            container.Visible = true
            btn.BackgroundColor3 = T.TabActive
            btn.TextColor3 = T.TextPrimary
            W.CurrentTab = name
        end

        local Tab = {
            Button = btn,
            Container = container,
            Name = name,
            _layoutOrder = 0,
        }
        W.Tabs[name] = Tab
        table.insert(W._tabOrder, name)

        local function nextOrder()
            Tab._layoutOrder = Tab._layoutOrder + 1
            return Tab._layoutOrder
        end

        function Tab:Select()
            selectTab()
        end

        function Tab:SetBadge(val)
            if badgeLabel then
                if val and val > 0 then
                    badgeLabel.Visible = true
                    badgeLabel.Text = val > 99 and "99+" or tostring(val)
                else
                    badgeLabel.Visible = false
                end
            end
        end

        -- =============================================================
        -- WIDGET: Section
        -- =============================================================
        function Tab:CreateSection(n)
            local l = Instance.new("TextLabel")
            l.Parent = container
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, 0, 0, 24)
            l.Font = T.FontBold
            l.Text = n
            l.TextColor3 = T.TextPrimary
            l.TextSize = T.TextSize
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.LayoutOrder = nextOrder()

            local obj = {}
            function obj:SetText(t) l.Text = t end
            function obj:Destroy() l:Destroy() end
            return obj
        end

        -- =============================================================
        -- WIDGET: Label
        -- =============================================================
        function Tab:CreateLabel(txt)
            local l = Instance.new("TextLabel")
            l.Parent = container
            l.BackgroundTransparency = 1
            l.Size = UDim2.new(1, 0, 0, 18)
            l.Font = T.FontLight
            l.Text = txt
            l.TextColor3 = T.TextSecondary
            l.TextSize = T.SmallTextSize
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextWrapped = true
            l.LayoutOrder = nextOrder()

            local obj = {}
            function obj:Set(t) l.Text = t end
            function obj:Get() return l.Text end
            function obj:SetColor(c) l.TextColor3 = c end
            function obj:Destroy() l:Destroy() end
            return obj
        end

        -- =============================================================
        -- WIDGET: Paragraph
        -- =============================================================
        function Tab:CreateParagraph(cfg2)
            local p = Instance.new("Frame")
            p.Parent = container
            p.BackgroundColor3 = T.ElementBG
            p.Size = UDim2.new(1, 0, 0, 0)
            p.AutomaticSize = Enum.AutomaticSize.Y
            p.BorderSizePixel = 0
            p.LayoutOrder = nextOrder()
            Instance.new("UICorner", p).CornerRadius = T.ElementRadius

            local pPad = Instance.new("UIPadding", p)
            pPad.PaddingLeft = UDim.new(0, 12)
            pPad.PaddingRight = UDim.new(0, 12)
            pPad.PaddingTop = UDim.new(0, 10)
            pPad.PaddingBottom = UDim.new(0, 10)

            local pLayout = Instance.new("UIListLayout", p)
            pLayout.Padding = UDim.new(0, 4)

            local pt = Instance.new("TextLabel")
            pt.Parent = p
            pt.BackgroundTransparency = 1
            pt.Size = UDim2.new(1, 0, 0, 20)
            pt.Font = T.FontBold
            pt.Text = cfg2.Title or ""
            pt.TextColor3 = T.TextPrimary
            pt.TextSize = T.TextSize
            pt.TextXAlignment = Enum.TextXAlignment.Left

            local pc = Instance.new("TextLabel")
            pc.Parent = p
            pc.BackgroundTransparency = 1
            pc.Size = UDim2.new(1, 0, 0, 0)
            pc.AutomaticSize = Enum.AutomaticSize.Y
            pc.Font = T.FontLight
            pc.Text = cfg2.Content or ""
            pc.TextColor3 = T.TextSecondary
            pc.TextSize = T.SmallTextSize
            pc.TextXAlignment = Enum.TextXAlignment.Left
            pc.TextYAlignment = Enum.TextYAlignment.Top
            pc.TextWrapped = true

            local obj = {}
            function obj:SetTitle(t) pt.Text = t end
            function obj:SetContent(t) pc.Text = t end
            function obj:Destroy() p:Destroy() end
            return obj
        end

        -- =============================================================
        -- WIDGET: Separator
        -- =============================================================
        function Tab:CreateSeparator()
            local sep = Instance.new("Frame")
            sep.Parent = container
            sep.BackgroundColor3 = T.Divider
            sep.Size = UDim2.new(1, 0, 0, 1)
            sep.BorderSizePixel = 0
            sep.LayoutOrder = nextOrder()
            return sep
        end

        -- =============================================================
        -- WIDGET: Spacer
        -- =============================================================
        function Tab:CreateSpacer(cfg2)
            local sp = Instance.new("Frame")
            sp.Parent = container
            sp.BackgroundTransparency = 1
            sp.Size = UDim2.new(1, 0, 0, (cfg2 and cfg2.Height) or 10)
            sp.LayoutOrder = nextOrder()
            return sp
        end

        -- =============================================================
        -- WIDGET: Button
        -- =============================================================
        function Tab:CreateButton(cfg2)
            local b = Instance.new("TextButton")
            b.Parent = container
            b.BackgroundColor3 = T.ElementBG
            b.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            b.Font = T.Font
            b.Text = "  " .. (cfg2.Name or "Button")
            b.TextColor3 = T.TextPrimary
            b.TextSize = T.TextSize
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.AutoButtonColor = false
            b.LayoutOrder = nextOrder()
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = T.ElementRadius

            local enabled = true
            local extraCallbacks = {}

            b.MouseEnter:Connect(function()
                if enabled then
                    TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementHover }):Play()
                end
            end)
            b.MouseLeave:Connect(function()
                if enabled then
                    TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementBG }):Play()
                end
            end)
            b.MouseButton1Click:Connect(function()
                if not enabled then return end
                if cfg2.Callback then safeCallback(cfg2.Callback) end
                for _, fn in ipairs(extraCallbacks) do safeCallback(fn) end
            end)

            if cfg2.Tooltip then attachTooltip(b, cfg2.Tooltip, T) end

            local obj = { _type = "button" }

            function obj:OnClick(fn)
                table.insert(extraCallbacks, fn)
            end

            function obj:SetEnabled(val)
                enabled = val
                if val then
                    b.BackgroundColor3 = T.ElementBG
                    b.TextColor3 = T.TextPrimary
                else
                    b.BackgroundColor3 = T.ElementDisabled
                    b.TextColor3 = T.TextDisabled
                end
            end

            function obj:SetVisible(val) b.Visible = val end
            function obj:SetText(t) b.Text = "  " .. t end
            function obj:SetTooltip(t) attachTooltip(b, t, T) end
            function obj:Destroy() b:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = obj end
            return obj
        end

        -- =============================================================
        -- WIDGET: Toggle
        -- =============================================================
        function Tab:CreateToggle(cfg2)
            local state = cfg2.CurrentValue or cfg2.Default or false
            local enabled = true
            local extraCallbacks = {}

            local tgl = Instance.new("TextButton")
            tgl.Parent = container
            tgl.BackgroundColor3 = T.ElementBG
            tgl.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            tgl.Font = T.Font
            tgl.Text = "  " .. (cfg2.Name or "Toggle")
            tgl.TextColor3 = T.TextPrimary
            tgl.TextSize = T.TextSize
            tgl.TextXAlignment = Enum.TextXAlignment.Left
            tgl.AutoButtonColor = false
            tgl.LayoutOrder = nextOrder()
            tgl.BorderSizePixel = 0
            Instance.new("UICorner", tgl).CornerRadius = T.ElementRadius

            local sw = Instance.new("Frame")
            sw.Parent = tgl
            sw.BackgroundColor3 = state and T.Accent or T.ToggleOff
            sw.Position = UDim2.new(1, -50, 0.5, -10)
            sw.Size = UDim2.new(0, 38, 0, 20)
            sw.BorderSizePixel = 0
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

            local c = Instance.new("Frame")
            c.Parent = sw
            c.BackgroundColor3 = T.TextPrimary
            c.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            c.Size = UDim2.new(0, 16, 0, 16)
            c.BorderSizePixel = 0
            Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)

            tgl.MouseEnter:Connect(function()
                if enabled then
                    TweenService:Create(tgl, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementHover }):Play()
                end
            end)
            tgl.MouseLeave:Connect(function()
                if enabled then
                    TweenService:Create(tgl, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementBG }):Play()
                end
            end)

            if cfg2.Tooltip then attachTooltip(tgl, cfg2.Tooltip, T) end

            local toggleObj = { _type = "toggle" }

            function toggleObj:Set(val)
                state = val
                TweenService:Create(sw, TweenInfo.new(T.TweenSpeed), {
                    BackgroundColor3 = state and T.Accent or T.ToggleOff
                }):Play()
                TweenService:Create(c, TweenInfo.new(T.TweenSpeed), {
                    Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                }):Play()
            end

            function toggleObj:Get() return state end

            function toggleObj:OnChanged(fn) table.insert(extraCallbacks, fn) end

            function toggleObj:SetEnabled(val)
                enabled = val
                tgl.BackgroundColor3 = val and T.ElementBG or T.ElementDisabled
                tgl.TextColor3 = val and T.TextPrimary or T.TextDisabled
            end

            function toggleObj:SetVisible(val) tgl.Visible = val end
            function toggleObj:SetTooltip(t) attachTooltip(tgl, t, T) end
            function toggleObj:Destroy() tgl:Destroy() end

            tgl.MouseButton1Click:Connect(function()
                if not enabled then return end
                state = not state
                toggleObj:Set(state)
                if cfg2.Callback then safeCallback(cfg2.Callback, state) end
                for _, fn in ipairs(extraCallbacks) do safeCallback(fn, state) end
            end)

            if cfg2.Flag then
                toggleObj._flag = cfg2.Flag
            end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = toggleObj end
            return toggleObj
        end

        -- =============================================================
        -- WIDGET: Slider
        -- =============================================================
        function Tab:CreateSlider(cfg2)
            local val = cfg2.CurrentValue or cfg2.Default or (cfg2.Range and cfg2.Range[1]) or 0
            local min = (cfg2.Range and cfg2.Range[1]) or cfg2.Min or 0
            local max = (cfg2.Range and cfg2.Range[2]) or cfg2.Max or 100
            local inc = cfg2.Increment or 1
            local suffix = cfg2.Suffix or ""
            local enabled = true
            local extraCallbacks = {}

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.SliderHeight)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.Size = UDim2.new(1, -24, 0, 18)
            lbl.Font = T.Font
            lbl.TextSize = T.SmallTextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextColor3 = T.TextPrimary
            lbl.Text = (cfg2.Name or "Slider") .. ": " .. val .. suffix

            local valLabel = Instance.new("TextLabel")
            valLabel.Parent = frame
            valLabel.BackgroundTransparency = 1
            valLabel.Position = UDim2.new(0, 12, 0, 4)
            valLabel.Size = UDim2.new(1, -24, 0, 18)
            valLabel.Font = T.FontBold
            valLabel.TextSize = T.SmallTextSize
            valLabel.TextXAlignment = Enum.TextXAlignment.Right
            valLabel.TextColor3 = T.Accent
            valLabel.Text = tostring(val) .. suffix

            local track = Instance.new("Frame")
            track.Parent = frame
            track.BackgroundColor3 = T.SliderTrack
            track.Position = UDim2.new(0, 12, 0, 32)
            track.Size = UDim2.new(1, -24, 0, 6)
            track.BorderSizePixel = 0
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Parent = track
            fill.BackgroundColor3 = T.Accent
            fill.Size = UDim2.new((val - min) / math.max(max - min, 1), 0, 1, 0)
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local knob = Instance.new("Frame")
            knob.Parent = track
            knob.BackgroundColor3 = T.SliderKnob
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((val - min) / math.max(max - min, 1), 0, 0.5, 0)
            knob.Size = UDim2.new(0, 14, 0, 14)
            knob.BorderSizePixel = 0
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

            local sliding = false

            local sliderObj = { _type = "slider" }

            local function updateVisual()
                local pct = (val - min) / math.max(max - min, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                lbl.Text = (cfg2.Name or "Slider") .. ": " .. val .. suffix
                valLabel.Text = tostring(val) .. suffix
            end

            local function setValFromInput(input)
                if not enabled then return end
                local rel = clamp(
                    (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1),
                    0, 1
                )
                val = clamp(math.floor((min + (max - min) * rel) / inc + 0.5) * inc, min, max)
                updateVisual()
                if cfg2.Callback then safeCallback(cfg2.Callback, val) end
                for _, fn in ipairs(extraCallbacks) do safeCallback(fn, val) end
            end

            function sliderObj:Set(v)
                val = clamp(v, min, max)
                updateVisual()
            end

            function sliderObj:Get() return val end

            function sliderObj:SetRange(newMin, newMax)
                min = newMin
                max = newMax
                val = clamp(val, min, max)
                updateVisual()
            end

            function sliderObj:SetIncrement(newInc) inc = newInc end

            function sliderObj:OnChanged(fn) table.insert(extraCallbacks, fn) end

            function sliderObj:SetEnabled(val2)
                enabled = val2
                frame.BackgroundColor3 = val2 and T.ElementBG or T.ElementDisabled
                lbl.TextColor3 = val2 and T.TextPrimary or T.TextDisabled
            end

            function sliderObj:SetVisible(val2) frame.Visible = val2 end
            function sliderObj:Destroy() frame:Destroy() end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    setValFromInput(i)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    setValFromInput(i)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)

            if cfg2.Tooltip then attachTooltip(frame, cfg2.Tooltip, T) end
            if cfg2.Name then W._widgetRegistry[cfg2.Name] = sliderObj end
            return sliderObj
        end

        -- =============================================================
        -- WIDGET: Dropdown (Searchable)
        -- =============================================================
        function Tab:CreateDropdown(cfg2)
            local selected = cfg2.Default or ""
            local open = false
            local options = cfg2.Options or {}
            local searchable = cfg2.Searchable or false
            local enabled = true
            local extraCallbacks = {}

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            frame.ClipsDescendants = true
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local dbtn = Instance.new("TextButton")
            dbtn.Parent = frame
            dbtn.BackgroundTransparency = 1
            dbtn.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            dbtn.Font = T.Font
            dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. selected
            dbtn.TextColor3 = T.TextPrimary
            dbtn.TextSize = T.TextSize
            dbtn.TextXAlignment = Enum.TextXAlignment.Left
            dbtn.AutoButtonColor = false
            dbtn.BorderSizePixel = 0

            local arrow = Instance.new("TextLabel")
            arrow.Parent = dbtn
            arrow.BackgroundTransparency = 1
            arrow.Position = UDim2.new(1, -30, 0, 0)
            arrow.Size = UDim2.new(0, 20, 1, 0)
            arrow.Font = T.FontBold
            arrow.Text = "▼"
            arrow.TextColor3 = T.TextMuted
            arrow.TextSize = 10

            local searchFrame = nil
            local searchBox = nil

            local optC = Instance.new("Frame")
            optC.Parent = frame
            optC.BackgroundTransparency = 1
            optC.Position = UDim2.new(0, 0, 0, T.ElementHeight)
            optC.Size = UDim2.new(1, 0, 0, 0)
            optC.BorderSizePixel = 0

            local optScroll = Instance.new("ScrollingFrame")
            optScroll.Parent = optC
            optScroll.BackgroundTransparency = 1
            optScroll.Size = UDim2.new(1, 0, 1, 0)
            optScroll.ScrollBarThickness = 2
            optScroll.ScrollBarImageColor3 = T.ScrollBar
            optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            optScroll.BorderSizePixel = 0

            local optLayout = Instance.new("UIListLayout", optScroll)
            optLayout.Padding = UDim.new(0, 2)

            if searchable then
                searchFrame = Instance.new("Frame")
                searchFrame.Parent = optC
                searchFrame.BackgroundColor3 = T.InputBG
                searchFrame.Size = UDim2.new(1, -10, 0, 28)
                searchFrame.Position = UDim2.new(0, 5, 0, 2)
                searchFrame.BorderSizePixel = 0
                Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 4)

                searchBox = Instance.new("TextBox")
                searchBox.Parent = searchFrame
                searchBox.BackgroundTransparency = 1
                searchBox.Size = UDim2.new(1, -10, 1, 0)
                searchBox.Position = UDim2.new(0, 5, 0, 0)
                searchBox.Font = T.FontLight
                searchBox.PlaceholderText = "Search..."
                searchBox.Text = ""
                searchBox.TextColor3 = T.TextPrimary
                searchBox.PlaceholderColor3 = T.TextMuted
                searchBox.TextSize = T.SmallTextSize
                searchBox.ClearTextOnFocus = false
                searchBox.TextXAlignment = Enum.TextXAlignment.Left

                optScroll.Position = UDim2.new(0, 0, 0, 32)
                optScroll.Size = UDim2.new(1, 0, 1, -32)
            end

            local dd = { _type = "dropdown" }

            local function buildOpts(opts, filter)
                for _, ch in ipairs(optScroll:GetChildren()) do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end
                local filteredOpts = opts or {}
                if filter and filter ~= "" then
                    filteredOpts = {}
                    for _, opt in ipairs(opts) do
                        if tostring(opt):lower():find(filter:lower(), 1, true) then
                            table.insert(filteredOpts, opt)
                        end
                    end
                end
                for _, opt in ipairs(filteredOpts) do
                    local ob = Instance.new("TextButton")
                    ob.Parent = optScroll
                    ob.BackgroundColor3 = (tostring(opt) == tostring(selected)) and T.Accent or T.ElementHover
                    ob.Size = UDim2.new(1, -10, 0, 28)
                    ob.Position = UDim2.new(0, 5, 0, 0)
                    ob.Font = T.FontLight
                    ob.Text = "  " .. tostring(opt)
                    ob.TextColor3 = (tostring(opt) == tostring(selected)) and Color3.fromRGB(255, 255, 255) or T.TextSecondary
                    ob.TextSize = T.SmallTextSize
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.AutoButtonColor = false
                    ob.BorderSizePixel = 0
                    Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)

                    ob.MouseEnter:Connect(function()
                        if tostring(opt) ~= tostring(selected) then
                            TweenService:Create(ob, TweenInfo.new(0.1), { BackgroundColor3 = T.ElementActive }):Play()
                        end
                    end)
                    ob.MouseLeave:Connect(function()
                        if tostring(opt) ~= tostring(selected) then
                            TweenService:Create(ob, TweenInfo.new(0.1), { BackgroundColor3 = T.ElementHover }):Play()
                        end
                    end)
                    ob.MouseButton1Click:Connect(function()
                        selected = opt
                        dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. tostring(selected)
                        open = false
                        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
                        arrow.Text = "▼"
                        if cfg2.Callback then safeCallback(cfg2.Callback, selected) end
                        for _, fn in ipairs(extraCallbacks) do safeCallback(fn, selected) end
                    end)
                end
                local visCount = math.min(#filteredOpts, 6)
                local searchH = searchable and 34 or 0
                optScroll.CanvasSize = UDim2.new(0, 0, 0, #filteredOpts * 30)
                return visCount, searchH
            end

            dbtn.MouseButton1Click:Connect(function()
                if not enabled then return end
                open = not open
                if open then
                    local visCount, searchH = buildOpts(options, searchBox and searchBox.Text or nil)
                    local dropH = searchH + visCount * 30 + 6
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + dropH)
                    optC.Size = UDim2.new(1, 0, 0, dropH)
                    arrow.Text = "▲"
                    if searchBox then
                        task.defer(function() searchBox:CaptureFocus() end)
                    end
                else
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
                    arrow.Text = "▼"
                end
            end)

            if searchBox then
                searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    if open then
                        local visCount, searchH = buildOpts(options, searchBox.Text)
                        local dropH = searchH + visCount * 30 + 6
                        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + dropH)
                        optC.Size = UDim2.new(1, 0, 0, dropH)
                    end
                end)
            end

            function dd:SetOptions(o)
                options = o
                if open then
                    buildOpts(options, searchBox and searchBox.Text or nil)
                end
            end

            function dd:GetValue() return selected end

            function dd:SetValue(v)
                selected = v
                dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. tostring(v)
            end

            function dd:OnChanged(fn) table.insert(extraCallbacks, fn) end

            function dd:SetEnabled(val)
                enabled = val
                frame.BackgroundColor3 = val and T.ElementBG or T.ElementDisabled
                dbtn.TextColor3 = val and T.TextPrimary or T.TextDisabled
            end

            function dd:SetVisible(val) frame.Visible = val end
            function dd:Destroy() frame:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = dd end
            return dd
        end

        -- =============================================================
        -- WIDGET: Multi-Select Dropdown
        -- =============================================================
        function Tab:CreateMultiDropdown(cfg2)
            local selectedItems = cfg2.Default or {}
            local open = false
            local options = cfg2.Options or {}
            local enabled = true
            local extraCallbacks = {}

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            frame.ClipsDescendants = true
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local function getDisplayText()
                if #selectedItems == 0 then return "None" end
                if #selectedItems <= 2 then return table.concat(selectedItems, ", ") end
                return selectedItems[1] .. ", " .. selectedItems[2] .. " +" .. (#selectedItems - 2)
            end

            local dbtn = Instance.new("TextButton")
            dbtn.Parent = frame
            dbtn.BackgroundTransparency = 1
            dbtn.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            dbtn.Font = T.Font
            dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. getDisplayText()
            dbtn.TextColor3 = T.TextPrimary
            dbtn.TextSize = T.TextSize
            dbtn.TextXAlignment = Enum.TextXAlignment.Left
            dbtn.AutoButtonColor = false
            dbtn.BorderSizePixel = 0

            local optC = Instance.new("Frame")
            optC.Parent = frame
            optC.BackgroundTransparency = 1
            optC.Position = UDim2.new(0, 0, 0, T.ElementHeight)
            optC.Size = UDim2.new(1, 0, 0, 0)
            optC.BorderSizePixel = 0

            local optScroll = Instance.new("ScrollingFrame")
            optScroll.Parent = optC
            optScroll.BackgroundTransparency = 1
            optScroll.Size = UDim2.new(1, 0, 1, 0)
            optScroll.ScrollBarThickness = 2
            optScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            optScroll.BorderSizePixel = 0
            Instance.new("UIListLayout", optScroll).Padding = UDim.new(0, 2)

            local mdd = { _type = "multidropdown" }

            local function buildOpts(opts)
                for _, ch in ipairs(optScroll:GetChildren()) do
                    if ch:IsA("TextButton") then ch:Destroy() end
                end
                for _, opt in ipairs(opts) do
                    local isSelected = tableContains(selectedItems, opt)
                    local ob = Instance.new("TextButton")
                    ob.Parent = optScroll
                    ob.BackgroundColor3 = isSelected and T.Accent or T.ElementHover
                    ob.Size = UDim2.new(1, -10, 0, 28)
                    ob.Position = UDim2.new(0, 5, 0, 0)
                    ob.Font = T.FontLight
                    ob.Text = (isSelected and "  ✓ " or "    ") .. tostring(opt)
                    ob.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or T.TextSecondary
                    ob.TextSize = T.SmallTextSize
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.AutoButtonColor = false
                    ob.BorderSizePixel = 0
                    Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)

                    ob.MouseButton1Click:Connect(function()
                        if tableContains(selectedItems, opt) then
                            tableRemove(selectedItems, opt)
                        else
                            table.insert(selectedItems, opt)
                        end
                        dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. getDisplayText()
                        buildOpts(opts)
                        if cfg2.Callback then safeCallback(cfg2.Callback, selectedItems) end
                        for _, fn in ipairs(extraCallbacks) do safeCallback(fn, selectedItems) end
                    end)
                end
                optScroll.CanvasSize = UDim2.new(0, 0, 0, #opts * 30)
            end

            dbtn.MouseButton1Click:Connect(function()
                if not enabled then return end
                open = not open
                if open then
                    buildOpts(options)
                    local visCount = math.min(#options, 6)
                    local dropH = visCount * 30 + 6
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + dropH)
                    optC.Size = UDim2.new(1, 0, 0, dropH)
                else
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
                end
            end)

            function mdd:GetValue() return selectedItems end
            function mdd:SetValue(items) selectedItems = items; dbtn.Text = "  " .. (cfg2.Name or "Select") .. ": " .. getDisplayText() end
            function mdd:SetOptions(o) options = o end
            function mdd:OnChanged(fn) table.insert(extraCallbacks, fn) end
            function mdd:SetVisible(val) frame.Visible = val end
            function mdd:Destroy() frame:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = mdd end
            return mdd
        end

        -- =============================================================
        -- WIDGET: Input
        -- =============================================================
        function Tab:CreateInput(cfg2)
            local enabled = true
            local extraCallbacks = {}

            local bg = Instance.new("Frame")
            bg.Parent = container
            bg.BackgroundColor3 = T.ElementBG
            bg.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            bg.LayoutOrder = nextOrder()
            bg.BorderSizePixel = 0
            Instance.new("UICorner", bg).CornerRadius = T.ElementRadius

            local l = Instance.new("TextLabel")
            l.Parent = bg
            l.BackgroundTransparency = 1
            l.Position = UDim2.new(0, 12, 0, 0)
            l.Size = UDim2.new(0.4, -12, 1, 0)
            l.Font = T.Font
            l.Text = cfg2.Name or "Input"
            l.TextColor3 = T.TextPrimary
            l.TextSize = T.TextSize
            l.TextXAlignment = Enum.TextXAlignment.Left

            local bb = Instance.new("Frame")
            bb.Parent = bg
            bb.BackgroundColor3 = T.InputBG
            bb.Position = UDim2.new(0.4, 0, 0.5, -13)
            bb.Size = UDim2.new(0.6, -12, 0, 26)
            bb.BorderSizePixel = 0
            Instance.new("UICorner", bb).CornerRadius = UDim.new(0, 4)

            local inputStroke = Instance.new("UIStroke")
            inputStroke.Parent = bb
            inputStroke.Color = T.InputBorder
            inputStroke.Thickness = 1

            local box = Instance.new("TextBox")
            box.Parent = bb
            box.BackgroundTransparency = 1
            box.Size = UDim2.new(1, -10, 1, 0)
            box.Position = UDim2.new(0, 5, 0, 0)
            box.Font = T.FontLight
            box.PlaceholderText = cfg2.PlaceholderText or "..."
            box.Text = cfg2.Default or ""
            box.TextColor3 = T.TextPrimary
            box.PlaceholderColor3 = T.TextMuted
            box.TextSize = T.SmallTextSize
            box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left

            box.Focused:Connect(function()
                TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = T.InputFocus }):Play()
            end)
            box.FocusLost:Connect(function(ep)
                TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = T.InputBorder }):Play()
                if ep and box.Text ~= "" then
                    if cfg2.Callback then safeCallback(cfg2.Callback, box.Text) end
                    for _, fn in ipairs(extraCallbacks) do safeCallback(fn, box.Text) end
                end
                if cfg2.RemoveTextAfterFocusLost or cfg2.ClearOnEnter then
                    box.Text = ""
                end
            end)

            if cfg2.Tooltip then attachTooltip(bg, cfg2.Tooltip, T) end

            local inputObj = { _type = "input" }
            function inputObj:Get() return box.Text end
            function inputObj:Set(v) box.Text = v end
            function inputObj:Focus() box:CaptureFocus() end
            function inputObj:OnChanged(fn) table.insert(extraCallbacks, fn) end
            function inputObj:SetEnabled(val)
                enabled = val
                bg.BackgroundColor3 = val and T.ElementBG or T.ElementDisabled
                l.TextColor3 = val and T.TextPrimary or T.TextDisabled
                box.TextEditable = val
            end
            function inputObj:SetVisible(val) bg.Visible = val end
            function inputObj:SetTooltip(t) attachTooltip(bg, t, T) end
            function inputObj:Destroy() bg:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = inputObj end
            return inputObj
        end

        -- =============================================================
        -- WIDGET: Keybind
        -- =============================================================
        function Tab:CreateKeybind(cfg2)
            local key = cfg2.Default or Enum.KeyCode.F
            local listening = false
            local extraCallbacks = {}

            local b = Instance.new("TextButton")
            b.Parent = container
            b.BackgroundColor3 = T.ElementBG
            b.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            b.Font = T.Font
            b.TextColor3 = T.TextPrimary
            b.TextSize = T.TextSize
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.AutoButtonColor = false
            b.Text = "  " .. (cfg2.Name or "Keybind") .. ": [" .. key.Name .. "]"
            b.LayoutOrder = nextOrder()
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = T.ElementRadius

            local keyDisplay = Instance.new("TextLabel")
            keyDisplay.Parent = b
            keyDisplay.BackgroundColor3 = T.InputBG
            keyDisplay.Position = UDim2.new(1, -65, 0.5, -12)
            keyDisplay.Size = UDim2.new(0, 55, 0, 24)
            keyDisplay.Font = T.FontMono
            keyDisplay.TextSize = T.SmallTextSize
            keyDisplay.TextColor3 = T.TextSecondary
            keyDisplay.Text = key.Name
            keyDisplay.BorderSizePixel = 0
            Instance.new("UICorner", keyDisplay).CornerRadius = UDim.new(0, 4)

            b.MouseEnter:Connect(function()
                TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementHover }):Play()
            end)
            b.MouseLeave:Connect(function()
                TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementBG }):Play()
            end)

            b.MouseButton1Click:Connect(function()
                listening = true
                keyDisplay.Text = "..."
                keyDisplay.TextColor3 = T.Accent
                b.Text = "  " .. (cfg2.Name or "Keybind") .. ": [...]"
            end)

            local kbObj = { _type = "keybind" }

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    key = input.KeyCode
                    listening = false
                    keyDisplay.Text = key.Name
                    keyDisplay.TextColor3 = T.TextSecondary
                    b.Text = "  " .. (cfg2.Name or "Keybind") .. ": [" .. key.Name .. "]"
                    if cfg2.Callback then safeCallback(cfg2.Callback, key) end
                    for _, fn in ipairs(extraCallbacks) do safeCallback(fn, key) end
                elseif not gpe and input.KeyCode == key and not listening then
                    if cfg2.OnPress then safeCallback(cfg2.OnPress) end
                end
            end)

            function kbObj:GetKey() return key end
            function kbObj:SetKey(k)
                if type(k) == "string" then k = Enum.KeyCode[k] end
                key = k
                keyDisplay.Text = key.Name
                b.Text = "  " .. (cfg2.Name or "Keybind") .. ": [" .. key.Name .. "]"
            end
            function kbObj:OnChanged(fn) table.insert(extraCallbacks, fn) end
            function kbObj:SetVisible(val) b.Visible = val end
            function kbObj:Destroy() b:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = kbObj end
            return kbObj
        end

        -- =============================================================
        -- WIDGET: ColorPicker (Full HSV)
        -- =============================================================
        function Tab:CreateColorPicker(cfg2)
            local color = cfg2.Default or Color3.fromRGB(255, 255, 255)
            local extraCallbacks = {}
            local pickerOpen = false

            local b = Instance.new("TextButton")
            b.Parent = container
            b.BackgroundColor3 = T.ElementBG
            b.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            b.Font = T.Font
            b.Text = "  " .. (cfg2.Name or "Color")
            b.TextColor3 = T.TextPrimary
            b.TextSize = T.TextSize
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.AutoButtonColor = false
            b.LayoutOrder = nextOrder()
            b.BorderSizePixel = 0
            Instance.new("UICorner", b).CornerRadius = T.ElementRadius

            local preview = Instance.new("Frame")
            preview.Parent = b
            preview.BackgroundColor3 = color
            preview.Position = UDim2.new(1, -40, 0.5, -9)
            preview.Size = UDim2.new(0, 24, 0, 18)
            preview.BorderSizePixel = 0
            Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)
            local previewStroke = Instance.new("UIStroke", preview)
            previewStroke.Color = T.Divider
            previewStroke.Thickness = 1

            b.MouseEnter:Connect(function()
                TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementHover }):Play()
            end)
            b.MouseLeave:Connect(function()
                TweenService:Create(b, TweenInfo.new(T.FastTween), { BackgroundColor3 = T.ElementBG }):Play()
            end)

            local cpObj = { _type = "colorpicker" }

            function cpObj:Set(c) color = c; preview.BackgroundColor3 = c end
            function cpObj:Get() return color end
            function cpObj:OnChanged(fn) table.insert(extraCallbacks, fn) end
            function cpObj:Destroy() b:Destroy() end

            b.MouseButton1Click:Connect(function()
                if pickerOpen then return end
                pickerOpen = true

                local pickerGui = Instance.new("ScreenGui")
                pickerGui.Name = "StarLib_ColorPicker"
                pickerGui.DisplayOrder = 90
                protectGui(pickerGui)

                local overlay = Instance.new("TextButton")
                overlay.Parent = pickerGui
                overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                overlay.BackgroundTransparency = 0.5
                overlay.Size = UDim2.new(1, 0, 1, 0)
                overlay.Text = ""
                overlay.BorderSizePixel = 0

                local pickerFrame = Instance.new("Frame")
                pickerFrame.Parent = pickerGui
                pickerFrame.BackgroundColor3 = T.ElementBG
                pickerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                pickerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                pickerFrame.Size = UDim2.new(0, 320, 0, 340)
                pickerFrame.BorderSizePixel = 0
                Instance.new("UICorner", pickerFrame).CornerRadius = T.CornerRadius

                MakeDraggable(pickerFrame, pickerFrame, 0.15)

                local pickerTitle = Instance.new("TextLabel")
                pickerTitle.Parent = pickerFrame
                pickerTitle.BackgroundTransparency = 1
                pickerTitle.Position = UDim2.new(0, 15, 0, 8)
                pickerTitle.Size = UDim2.new(1, -30, 0, 24)
                pickerTitle.Font = T.FontBold
                pickerTitle.Text = cfg2.Name or "Color Picker"
                pickerTitle.TextColor3 = T.TextPrimary
                pickerTitle.TextSize = T.TitleSize
                pickerTitle.TextXAlignment = Enum.TextXAlignment.Left

                local h, s, v = RGBtoHSV(color.R, color.G, color.B)

                -- SV square
                local svFrame = Instance.new("Frame")
                svFrame.Parent = pickerFrame
                svFrame.Position = UDim2.new(0, 15, 0, 42)
                svFrame.Size = UDim2.new(0, 220, 0, 180)
                svFrame.BorderSizePixel = 0
                Instance.new("UICorner", svFrame).CornerRadius = UDim.new(0, 4)

                local function updateSVGradient()
                    local hueColor = Color3.fromHSV(h, 1, 1)
                    svFrame.BackgroundColor3 = hueColor
                end
                updateSVGradient()

                local satGradient = Instance.new("UIGradient")
                satGradient.Parent = svFrame
                satGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
                satGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                })

                local valOverlay = Instance.new("Frame")
                valOverlay.Parent = svFrame
                valOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
                valOverlay.Size = UDim2.new(1, 0, 1, 0)
                valOverlay.BorderSizePixel = 0
                Instance.new("UICorner", valOverlay).CornerRadius = UDim.new(0, 4)
                local valGradient = Instance.new("UIGradient")
                valGradient.Parent = valOverlay
                valGradient.Rotation = 90
                valGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                })

                local svCursor = Instance.new("Frame")
                svCursor.Parent = svFrame
                svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
                svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                svCursor.Size = UDim2.new(0, 12, 0, 12)
                svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                svCursor.BorderSizePixel = 0
                svCursor.ZIndex = 5
                Instance.new("UICorner", svCursor).CornerRadius = UDim.new(1, 0)
                local svStroke = Instance.new("UIStroke", svCursor)
                svStroke.Color = Color3.new(0, 0, 0)
                svStroke.Thickness = 2

                -- Hue bar
                local hueBar = Instance.new("Frame")
                hueBar.Parent = pickerFrame
                hueBar.Position = UDim2.new(0, 250, 0, 42)
                hueBar.Size = UDim2.new(0, 20, 0, 180)
                hueBar.BorderSizePixel = 0
                Instance.new("UICorner", hueBar).CornerRadius = UDim.new(0, 4)

                local hueGradient = Instance.new("UIGradient")
                hueGradient.Parent = hueBar
                hueGradient.Rotation = 90
                hueGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                })

                local hueCursor = Instance.new("Frame")
                hueCursor.Parent = hueBar
                hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
                hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                hueCursor.Size = UDim2.new(1, 6, 0, 6)
                hueCursor.Position = UDim2.new(0.5, 0, h, 0)
                hueCursor.BorderSizePixel = 0
                hueCursor.ZIndex = 5
                Instance.new("UICorner", hueCursor).CornerRadius = UDim.new(1, 0)
                Instance.new("UIStroke", hueCursor).Thickness = 1

                -- Preview swatch
                local previewSwatch = Instance.new("Frame")
                previewSwatch.Parent = pickerFrame
                previewSwatch.Position = UDim2.new(0, 282, 0, 42)
                previewSwatch.Size = UDim2.new(0, 24, 0, 24)
                previewSwatch.BackgroundColor3 = color
                previewSwatch.BorderSizePixel = 0
                Instance.new("UICorner", previewSwatch).CornerRadius = UDim.new(0, 4)

                -- Hex input
                local hexLabel = Instance.new("TextLabel")
                hexLabel.Parent = pickerFrame
                hexLabel.BackgroundTransparency = 1
                hexLabel.Position = UDim2.new(0, 15, 0, 232)
                hexLabel.Size = UDim2.new(0, 35, 0, 24)
                hexLabel.Font = T.FontBold
                hexLabel.Text = "HEX"
                hexLabel.TextColor3 = T.TextMuted
                hexLabel.TextSize = 11

                local hexInputBg = Instance.new("Frame")
                hexInputBg.Parent = pickerFrame
                hexInputBg.BackgroundColor3 = T.InputBG
                hexInputBg.Position = UDim2.new(0, 52, 0, 232)
                hexInputBg.Size = UDim2.new(0, 90, 0, 26)
                hexInputBg.BorderSizePixel = 0
                Instance.new("UICorner", hexInputBg).CornerRadius = UDim.new(0, 4)

                local hexInput = Instance.new("TextBox")
                hexInput.Parent = hexInputBg
                hexInput.BackgroundTransparency = 1
                hexInput.Size = UDim2.new(1, -8, 1, 0)
                hexInput.Position = UDim2.new(0, 4, 0, 0)
                hexInput.Font = T.FontMono
                hexInput.Text = Color3ToHex(color)
                hexInput.TextColor3 = T.TextPrimary
                hexInput.TextSize = 12
                hexInput.ClearTextOnFocus = true

                -- R G B inputs
                local rgbLabels = {"R", "G", "B"}
                local rgbInputs = {}
                for i, label in ipairs(rgbLabels) do
                    local rgbLbl = Instance.new("TextLabel")
                    rgbLbl.Parent = pickerFrame
                    rgbLbl.BackgroundTransparency = 1
                    rgbLbl.Position = UDim2.new(0, 15 + (i-1) * 70, 0, 268)
                    rgbLbl.Size = UDim2.new(0, 12, 0, 24)
                    rgbLbl.Font = T.FontBold
                    rgbLbl.Text = label
                    rgbLbl.TextColor3 = T.TextMuted
                    rgbLbl.TextSize = 11

                    local rgbBg = Instance.new("Frame")
                    rgbBg.Parent = pickerFrame
                    rgbBg.BackgroundColor3 = T.InputBG
                    rgbBg.Position = UDim2.new(0, 28 + (i-1) * 70, 0, 268)
                    rgbBg.Size = UDim2.new(0, 48, 0, 24)
                    rgbBg.BorderSizePixel = 0
                    Instance.new("UICorner", rgbBg).CornerRadius = UDim.new(0, 4)

                    local rgbBox = Instance.new("TextBox")
                    rgbBox.Parent = rgbBg
                    rgbBox.BackgroundTransparency = 1
                    rgbBox.Size = UDim2.new(1, -6, 1, 0)
                    rgbBox.Position = UDim2.new(0, 3, 0, 0)
                    rgbBox.Font = T.FontMono
                    rgbBox.TextSize = 11
                    rgbBox.TextColor3 = T.TextPrimary
                    rgbBox.ClearTextOnFocus = true

                    rgbInputs[i] = rgbBox
                end
                rgbInputs[1].Text = tostring(math.floor(color.R * 255))
                rgbInputs[2].Text = tostring(math.floor(color.G * 255))
                rgbInputs[3].Text = tostring(math.floor(color.B * 255))

                local function updateFromHSV()
                    local r, g, bl = HSVtoRGB(h, s, v)
                    color = Color3.new(r, g, bl)
                    previewSwatch.BackgroundColor3 = color
                    preview.BackgroundColor3 = color
                    hexInput.Text = Color3ToHex(color)
                    rgbInputs[1].Text = tostring(math.floor(r * 255))
                    rgbInputs[2].Text = tostring(math.floor(g * 255))
                    rgbInputs[3].Text = tostring(math.floor(bl * 255))
                    updateSVGradient()
                    svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueCursor.Position = UDim2.new(0.5, 0, h, 0)
                    if cfg2.LivePreview then
                        if cfg2.Callback then safeCallback(cfg2.Callback, color) end
                    end
                end

                -- SV interaction
                local svDragging = false
                svFrame.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDragging = true
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if svDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.MouseButton1) then
                        local relX = clamp((i.Position.X - svFrame.AbsolutePosition.X) / svFrame.AbsoluteSize.X, 0, 1)
                        local relY = clamp((i.Position.Y - svFrame.AbsolutePosition.Y) / svFrame.AbsoluteSize.Y, 0, 1)
                        s = relX
                        v = 1 - relY
                        updateFromHSV()
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false end
                end)

                -- Hue interaction
                local hueDragging = false
                hueBar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDragging = true
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if hueDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.MouseButton1) then
                        h = clamp((i.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 0.999)
                        updateFromHSV()
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = false end
                end)

                -- Hex input
                hexInput.FocusLost:Connect(function()
                    local c = HexToColor3(hexInput.Text)
                    if c then
                        color = c
                        h, s, v = RGBtoHSV(c.R, c.G, c.B)
                        updateFromHSV()
                    end
                end)

                -- RGB inputs
                for i, box in ipairs(rgbInputs) do
                    box.FocusLost:Connect(function()
                        local val = tonumber(box.Text)
                        if val then
                            val = clamp(val, 0, 255)
                            local r = tonumber(rgbInputs[1].Text) or 0
                            local g = tonumber(rgbInputs[2].Text) or 0
                            local bl = tonumber(rgbInputs[3].Text) or 0
                            color = Color3.fromRGB(r, g, bl)
                            h, s, v = RGBtoHSV(color.R, color.G, color.B)
                            updateFromHSV()
                        end
                    end)
                end

                -- Confirm / Cancel buttons
                local confirmBtn = Instance.new("TextButton")
                confirmBtn.Parent = pickerFrame
                confirmBtn.BackgroundColor3 = T.Accent
                confirmBtn.Position = UDim2.new(0.5, 5, 1, -44)
                confirmBtn.Size = UDim2.new(0.5, -20, 0, 32)
                confirmBtn.Font = T.Font
                confirmBtn.Text = "Confirm"
                confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                confirmBtn.TextSize = T.SmallTextSize
                confirmBtn.AutoButtonColor = false
                confirmBtn.BorderSizePixel = 0
                Instance.new("UICorner", confirmBtn).CornerRadius = T.ElementRadius

                local cancelBtn = Instance.new("TextButton")
                cancelBtn.Parent = pickerFrame
                cancelBtn.BackgroundColor3 = T.SliderTrack
                cancelBtn.Position = UDim2.new(0, 15, 1, -44)
                cancelBtn.Size = UDim2.new(0.5, -20, 0, 32)
                cancelBtn.Font = T.Font
                cancelBtn.Text = "Cancel"
                cancelBtn.TextColor3 = T.TextPrimary
                cancelBtn.TextSize = T.SmallTextSize
                cancelBtn.AutoButtonColor = false
                cancelBtn.BorderSizePixel = 0
                Instance.new("UICorner", cancelBtn).CornerRadius = T.ElementRadius

                confirmBtn.MouseButton1Click:Connect(function()
                    pickerOpen = false
                    preview.BackgroundColor3 = color
                    pickerGui:Destroy()
                    if cfg2.Callback then safeCallback(cfg2.Callback, color) end
                    for _, fn in ipairs(extraCallbacks) do safeCallback(fn, color) end
                end)

                cancelBtn.MouseButton1Click:Connect(function()
                    pickerOpen = false
                    pickerGui:Destroy()
                end)

                overlay.MouseButton1Click:Connect(function()
                    pickerOpen = false
                    pickerGui:Destroy()
                end)
            end)

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = cpObj end
            return cpObj
        end

        -- =============================================================
        -- WIDGET: Progress Bar
        -- =============================================================
        function Tab:CreateProgressBar(cfg2)
            local min = cfg2.Min or 0
            local max = cfg2.Max or 100
            local val = cfg2.Default or min
            local barColor = cfg2.Color or T.Accent
            local showLabel = cfg2.ShowLabel ~= false
            local barHeight = cfg2.Height or 12

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, showLabel and 44 or 28)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local lbl = nil
            if showLabel then
                lbl = Instance.new("TextLabel")
                lbl.Parent = frame
                lbl.BackgroundTransparency = 1
                lbl.Position = UDim2.new(0, 12, 0, 4)
                lbl.Size = UDim2.new(1, -24, 0, 18)
                lbl.Font = T.Font
                lbl.TextSize = T.SmallTextSize
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextColor3 = T.TextPrimary
                lbl.Text = (cfg2.Name or "Progress") .. ": " .. math.floor(val) .. "%"
            end

            local trackY = showLabel and 26 or 8
            local track = Instance.new("Frame")
            track.Parent = frame
            track.BackgroundColor3 = T.SliderTrack
            track.Position = UDim2.new(0, 12, 0, trackY)
            track.Size = UDim2.new(1, -24, 0, barHeight)
            track.BorderSizePixel = 0
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Parent = track
            fill.BackgroundColor3 = barColor
            fill.Size = UDim2.new((val - min) / math.max(max - min, 1), 0, 1, 0)
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local pbObj = { _type = "progressbar" }

            function pbObj:Set(v)
                val = clamp(v, min, max)
                local pct = (val - min) / math.max(max - min, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                if lbl then
                    lbl.Text = (cfg2.Name or "Progress") .. ": " .. math.floor(val) .. "%"
                end
            end

            function pbObj:Get() return val end

            function pbObj:Animate(targetVal, duration)
                duration = duration or 1
                local startVal = val
                task.spawn(function()
                    local startTime = tick()
                    while true do
                        local elapsed = tick() - startTime
                        local progress = clamp(elapsed / duration, 0, 1)
                        local eased = Easing.QuintOut(progress)
                        pbObj:Set(lerp(startVal, targetVal, eased))
                        if progress >= 1 then break end
                        task.wait(0.016)
                    end
                end)
            end

            function pbObj:SetColor(c) barColor = c; fill.BackgroundColor3 = c end
            function pbObj:SetVisible(v2) frame.Visible = v2 end
            function pbObj:Destroy() frame:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = pbObj end
            return pbObj
        end

        -- =============================================================
        -- WIDGET: Badge / Chip
        -- =============================================================
        function Tab:CreateBadge(cfg2)
            local badgeFrame = Instance.new("Frame")
            badgeFrame.Parent = container
            badgeFrame.BackgroundTransparency = 1
            badgeFrame.Size = UDim2.new(1, 0, 0, 30)
            badgeFrame.LayoutOrder = nextOrder()

            local badge = Instance.new("TextLabel")
            badge.Parent = badgeFrame
            badge.BackgroundColor3 = cfg2.Color or T.Accent
            badge.Size = UDim2.new(0, 0, 0, 24)
            badge.AutomaticSize = Enum.AutomaticSize.X
            badge.Font = T.FontBold
            badge.Text = cfg2.Text or cfg2.Name or "Badge"
            badge.TextColor3 = cfg2.TextColor or Color3.fromRGB(255, 255, 255)
            badge.TextSize = T.SmallTextSize
            badge.BorderSizePixel = 0
            Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 12)
            local badgePad = Instance.new("UIPadding", badge)
            badgePad.PaddingLeft = UDim.new(0, 12)
            badgePad.PaddingRight = UDim.new(0, 12)

            local bdgObj = {}
            function bdgObj:SetText(t) badge.Text = t end
            function bdgObj:SetColor(c) badge.BackgroundColor3 = c end
            function bdgObj:SetVisible(v) badgeFrame.Visible = v end
            function bdgObj:Destroy() badgeFrame:Destroy() end
            return bdgObj
        end

        -- =============================================================
        -- WIDGET: Table / Grid Display
        -- =============================================================
        function Tab:CreateTable(cfg2)
            local columns = cfg2.Columns or {}
            local rows = cfg2.Rows or {}
            local rowHeight = cfg2.RowHeight or 28
            local maxHeight = cfg2.MaxHeight or 200

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, math.min(rowHeight * (#rows + 1) + 10, maxHeight + rowHeight + 10))
            frame.ClipsDescendants = true
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            -- Header
            local headerFrame = Instance.new("Frame")
            headerFrame.Parent = frame
            headerFrame.BackgroundColor3 = darkenColor(T.ElementBG, 0.03)
            headerFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            headerFrame.BorderSizePixel = 0

            local colWidth = 1 / math.max(#columns, 1)
            for i, col in ipairs(columns) do
                local hLabel = Instance.new("TextLabel")
                hLabel.Parent = headerFrame
                hLabel.BackgroundTransparency = 1
                hLabel.Position = UDim2.new(colWidth * (i - 1), 8, 0, 0)
                hLabel.Size = UDim2.new(colWidth, -16, 1, 0)
                hLabel.Font = T.FontBold
                hLabel.Text = col
                hLabel.TextColor3 = T.TextPrimary
                hLabel.TextSize = T.SmallTextSize
                hLabel.TextXAlignment = Enum.TextXAlignment.Left
                hLabel.TextTruncate = Enum.TextTruncate.AtEnd
            end

            -- Body
            local bodyScroll = Instance.new("ScrollingFrame")
            bodyScroll.Parent = frame
            bodyScroll.BackgroundTransparency = 1
            bodyScroll.Position = UDim2.new(0, 0, 0, rowHeight)
            bodyScroll.Size = UDim2.new(1, 0, 1, -rowHeight)
            bodyScroll.ScrollBarThickness = 2
            bodyScroll.ScrollBarImageColor3 = T.ScrollBar
            bodyScroll.CanvasSize = UDim2.new(0, 0, 0, #rows * rowHeight)
            bodyScroll.BorderSizePixel = 0

            local bodyLayout = Instance.new("UIListLayout", bodyScroll)
            bodyLayout.Padding = UDim.new(0, 0)

            local function buildRows(rowData)
                for _, ch in ipairs(bodyScroll:GetChildren()) do
                    if ch:IsA("Frame") then ch:Destroy() end
                end
                for rowIdx, row in ipairs(rowData) do
                    local rowFrame = Instance.new("Frame")
                    rowFrame.Parent = bodyScroll
                    rowFrame.BackgroundColor3 = rowIdx % 2 == 0 and T.ElementBG or lightenColor(T.ElementBG, 0.02)
                    rowFrame.BackgroundTransparency = rowIdx % 2 == 0 and 0 or 0
                    rowFrame.Size = UDim2.new(1, 0, 0, rowHeight)
                    rowFrame.BorderSizePixel = 0

                    for colIdx, cellVal in ipairs(row) do
                        local cellLabel = Instance.new("TextLabel")
                        cellLabel.Parent = rowFrame
                        cellLabel.BackgroundTransparency = 1
                        cellLabel.Position = UDim2.new(colWidth * (colIdx - 1), 8, 0, 0)
                        cellLabel.Size = UDim2.new(colWidth, -16, 1, 0)
                        cellLabel.Font = T.FontLight
                        cellLabel.Text = tostring(cellVal)
                        cellLabel.TextColor3 = T.TextSecondary
                        cellLabel.TextSize = T.SmallTextSize
                        cellLabel.TextXAlignment = Enum.TextXAlignment.Left
                        cellLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    end

                    if cfg2.OnRowClick then
                        local rowBtn = Instance.new("TextButton")
                        rowBtn.Parent = rowFrame
                        rowBtn.BackgroundTransparency = 1
                        rowBtn.Size = UDim2.new(1, 0, 1, 0)
                        rowBtn.Text = ""
                        rowBtn.ZIndex = 2
                        rowBtn.MouseEnter:Connect(function()
                            rowFrame.BackgroundColor3 = T.ElementHover
                        end)
                        rowBtn.MouseLeave:Connect(function()
                            rowFrame.BackgroundColor3 = rowIdx % 2 == 0 and T.ElementBG or lightenColor(T.ElementBG, 0.02)
                        end)
                        rowBtn.MouseButton1Click:Connect(function()
                            safeCallback(cfg2.OnRowClick, rowIdx, row)
                        end)
                    end
                end
                bodyScroll.CanvasSize = UDim2.new(0, 0, 0, #rowData * rowHeight)
                frame.Size = UDim2.new(1, 0, 0, math.min(rowHeight * (#rowData + 1) + 10, maxHeight + rowHeight + 10))
            end

            buildRows(rows)

            local tblObj = {}
            function tblObj:SetRows(r) rows = r; buildRows(rows) end
            function tblObj:AddRow(r) table.insert(rows, r); buildRows(rows) end
            function tblObj:RemoveRow(idx) table.remove(rows, idx); buildRows(rows) end
            function tblObj:Clear() rows = {}; buildRows(rows) end
            function tblObj:GetRows() return rows end
            function tblObj:SetVisible(v) frame.Visible = v end
            function tblObj:Destroy() frame:Destroy() end
            return tblObj
        end

        -- =============================================================
        -- WIDGET: Radio Group
        -- =============================================================
        function Tab:CreateRadioGroup(cfg2)
            local options = cfg2.Options or {}
            local selected = cfg2.Default or (options[1] or "")
            local extraCallbacks = {}

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local rPad = Instance.new("UIPadding", frame)
            rPad.PaddingLeft = UDim.new(0, 12)
            rPad.PaddingRight = UDim.new(0, 12)
            rPad.PaddingTop = UDim.new(0, 8)
            rPad.PaddingBottom = UDim.new(0, 8)

            local rLayout = Instance.new("UIListLayout", frame)
            rLayout.Padding = UDim.new(0, 4)

            if cfg2.Name then
                local radioTitle = Instance.new("TextLabel")
                radioTitle.Parent = frame
                radioTitle.BackgroundTransparency = 1
                radioTitle.Size = UDim2.new(1, 0, 0, 20)
                radioTitle.Font = T.FontBold
                radioTitle.Text = cfg2.Name
                radioTitle.TextColor3 = T.TextPrimary
                radioTitle.TextSize = T.SmallTextSize
                radioTitle.TextXAlignment = Enum.TextXAlignment.Left
            end

            local radioButtons = {}
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = frame
                optBtn.BackgroundTransparency = 1
                optBtn.Size = UDim2.new(1, 0, 0, 26)
                optBtn.Font = T.FontLight
                optBtn.TextSize = T.SmallTextSize
                optBtn.TextColor3 = T.TextSecondary
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.BorderSizePixel = 0

                local circle = Instance.new("Frame")
                circle.Parent = optBtn
                circle.BackgroundColor3 = T.ToggleOff
                circle.Position = UDim2.new(0, 0, 0.5, -8)
                circle.Size = UDim2.new(0, 16, 0, 16)
                circle.BorderSizePixel = 0
                Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

                local dot = Instance.new("Frame")
                dot.Parent = circle
                dot.BackgroundColor3 = T.TextPrimary
                dot.AnchorPoint = Vector2.new(0.5, 0.5)
                dot.Position = UDim2.new(0.5, 0, 0.5, 0)
                dot.Size = opt == selected and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 0, 0, 0)
                dot.BorderSizePixel = 0
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                optBtn.Text = "      " .. opt
                radioButtons[opt] = { button = optBtn, circle = circle, dot = dot }

                if opt == selected then
                    circle.BackgroundColor3 = T.Accent
                end

                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    for o, rb in pairs(radioButtons) do
                        local isSel = o == selected
                        TweenService:Create(rb.circle, TweenInfo.new(0.15), {
                            BackgroundColor3 = isSel and T.Accent or T.ToggleOff
                        }):Play()
                        TweenService:Create(rb.dot, TweenInfo.new(0.15), {
                            Size = isSel and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 0, 0, 0)
                        }):Play()
                    end
                    if cfg2.Callback then safeCallback(cfg2.Callback, selected) end
                    for _, fn in ipairs(extraCallbacks) do safeCallback(fn, selected) end
                end)
            end

            local rgObj = {}
            function rgObj:Get() return selected end
            function rgObj:Set(val)
                selected = val
                for o, rb in pairs(radioButtons) do
                    local isSel = o == selected
                    rb.circle.BackgroundColor3 = isSel and T.Accent or T.ToggleOff
                    rb.dot.Size = isSel and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 0, 0, 0)
                end
            end
            function rgObj:OnChanged(fn) table.insert(extraCallbacks, fn) end
            function rgObj:SetVisible(v) frame.Visible = v end
            function rgObj:Destroy() frame:Destroy() end

            if cfg2.Name then W._widgetRegistry[cfg2.Name] = rgObj end
            return rgObj
        end

        -- =============================================================
        -- WIDGET: Accordion / Collapsible
        -- =============================================================
        function Tab:CreateAccordion(cfg2)
            local isOpen = cfg2.DefaultOpen or false

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            frame.ClipsDescendants = true
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local header = Instance.new("TextButton")
            header.Parent = frame
            header.BackgroundTransparency = 1
            header.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            header.Font = T.Font
            header.Text = "  " .. (cfg2.Name or "Section")
            header.TextColor3 = T.TextPrimary
            header.TextSize = T.TextSize
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.AutoButtonColor = false
            header.BorderSizePixel = 0

            local arrowLabel = Instance.new("TextLabel")
            arrowLabel.Parent = header
            arrowLabel.BackgroundTransparency = 1
            arrowLabel.Position = UDim2.new(1, -30, 0, 0)
            arrowLabel.Size = UDim2.new(0, 20, 1, 0)
            arrowLabel.Font = T.FontBold
            arrowLabel.Text = isOpen and "▲" or "▼"
            arrowLabel.TextColor3 = T.TextMuted
            arrowLabel.TextSize = 10

            local innerContainer = Instance.new("Frame")
            innerContainer.Parent = frame
            innerContainer.BackgroundTransparency = 1
            innerContainer.Position = UDim2.new(0, 0, 0, T.ElementHeight)
            innerContainer.Size = UDim2.new(1, 0, 0, 0)
            innerContainer.AutomaticSize = Enum.AutomaticSize.Y
            innerContainer.BorderSizePixel = 0

            local innerLayout = Instance.new("UIListLayout", innerContainer)
            innerLayout.Padding = UDim.new(0, 4)
            local innerPad = Instance.new("UIPadding", innerContainer)
            innerPad.PaddingLeft = UDim.new(0, 10)
            innerPad.PaddingRight = UDim.new(0, 10)
            innerPad.PaddingBottom = UDim.new(0, 8)

            local function updateSize()
                if isOpen then
                    local contentH = innerLayout.AbsoluteContentSize.Y + 12
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + contentH)
                    arrowLabel.Text = "▲"
                else
                    frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
                    arrowLabel.Text = "▼"
                end
            end

            innerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isOpen then updateSize() end
            end)

            header.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                updateSize()
            end)

            if isOpen then
                task.defer(updateSize)
            end

            local accObj = { Container = innerContainer }
            function accObj:Toggle() isOpen = not isOpen; updateSize() end
            function accObj:Open() isOpen = true; updateSize() end
            function accObj:Close() isOpen = false; updateSize() end
            function accObj:Destroy() frame:Destroy() end
            return accObj
        end

        -- =============================================================
        -- WIDGET: Code Block
        -- =============================================================
        function Tab:CreateCodeBlock(cfg2)
            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
            frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 120)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            if cfg2.Title then
                local cbTitle = Instance.new("TextLabel")
                cbTitle.Parent = frame
                cbTitle.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
                cbTitle.Size = UDim2.new(1, 0, 0, 24)
                cbTitle.Font = T.FontMono
                cbTitle.Text = "  " .. cfg2.Title
                cbTitle.TextColor3 = T.TextMuted
                cbTitle.TextSize = 11
                cbTitle.TextXAlignment = Enum.TextXAlignment.Left
                cbTitle.BorderSizePixel = 0
            end

            local codeScroll = Instance.new("ScrollingFrame")
            codeScroll.Parent = frame
            codeScroll.BackgroundTransparency = 1
            codeScroll.Position = UDim2.new(0, 0, 0, cfg2.Title and 24 or 0)
            codeScroll.Size = UDim2.new(1, 0, 1, cfg2.Title and -24 or 0)
            codeScroll.ScrollBarThickness = 3
            codeScroll.BorderSizePixel = 0

            local codeLabel = Instance.new("TextLabel")
            codeLabel.Parent = codeScroll
            codeLabel.BackgroundTransparency = 1
            codeLabel.Size = UDim2.new(1, -20, 0, 0)
            codeLabel.AutomaticSize = Enum.AutomaticSize.Y
            codeLabel.Position = UDim2.new(0, 10, 0, 6)
            codeLabel.Font = Enum.Font.Code
            codeLabel.Text = cfg2.Code or cfg2.Content or ""
            codeLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
            codeLabel.TextSize = 12
            codeLabel.TextXAlignment = Enum.TextXAlignment.Left
            codeLabel.TextYAlignment = Enum.TextYAlignment.Top
            codeLabel.TextWrapped = true

            codeLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                codeScroll.CanvasSize = UDim2.new(0, 0, 0, codeLabel.TextBounds.Y + 16)
            end)

            local cbObj = {}
            function cbObj:SetCode(c) codeLabel.Text = c end
            function cbObj:GetCode() return codeLabel.Text end
            function cbObj:SetVisible(v) frame.Visible = v end
            function cbObj:Destroy() frame:Destroy() end
            return cbObj
        end

        -- =============================================================
        -- WIDGET: Countdown Timer
        -- =============================================================
        function Tab:CreateCountdown(cfg2)
            local duration = cfg2.Duration or 60
            local remaining = duration
            local running = false
            local extraCallbacks = {}

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + 10)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.Size = UDim2.new(0.6, -12, 0, 20)
            lbl.Font = T.FontBold
            lbl.Text = cfg2.Name or "Countdown"
            lbl.TextColor3 = T.TextPrimary
            lbl.TextSize = T.TextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left

            local timeLabel = Instance.new("TextLabel")
            timeLabel.Parent = frame
            timeLabel.BackgroundTransparency = 1
            timeLabel.Position = UDim2.new(0.6, 0, 0, 4)
            timeLabel.Size = UDim2.new(0.4, -12, 0, 20)
            timeLabel.Font = T.FontMono
            timeLabel.Text = formatTime(remaining)
            timeLabel.TextColor3 = T.Accent
            timeLabel.TextSize = T.TextSize
            timeLabel.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame")
            track.Parent = frame
            track.BackgroundColor3 = T.SliderTrack
            track.Position = UDim2.new(0, 12, 0, 30)
            track.Size = UDim2.new(1, -24, 0, 4)
            track.BorderSizePixel = 0
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            fill.Parent = track
            fill.BackgroundColor3 = T.Accent
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local cdObj = {}

            function cdObj:Start()
                if running then return end
                running = true
                task.spawn(function()
                    while running and remaining > 0 do
                        task.wait(1)
                        if not running then break end
                        remaining = remaining - 1
                        timeLabel.Text = formatTime(remaining)
                        fill.Size = UDim2.new(remaining / math.max(duration, 1), 0, 1, 0)
                        if remaining <= 10 then
                            timeLabel.TextColor3 = T.Error
                        end
                    end
                    if remaining <= 0 then
                        running = false
                        if cfg2.OnComplete then safeCallback(cfg2.OnComplete) end
                        for _, fn in ipairs(extraCallbacks) do safeCallback(fn) end
                    end
                end)
            end

            function cdObj:Stop() running = false end
            function cdObj:Reset(newDuration)
                running = false
                duration = newDuration or duration
                remaining = duration
                timeLabel.Text = formatTime(remaining)
                timeLabel.TextColor3 = T.Accent
                fill.Size = UDim2.new(1, 0, 1, 0)
            end
            function cdObj:GetRemaining() return remaining end
            function cdObj:OnComplete(fn) table.insert(extraCallbacks, fn) end
            function cdObj:SetVisible(v) frame.Visible = v end
            function cdObj:Destroy() running = false; frame:Destroy() end
            return cdObj
        end

        -- =============================================================
        -- WIDGET: Profile Card
        -- =============================================================
        function Tab:CreateProfileCard(cfg2)
            local player = cfg2.Player or LocalPlayer

            local card = Instance.new("Frame")
            card.Parent = container
            card.BackgroundColor3 = T.ElementBG
            card.Size = UDim2.new(1, 0, 0, 90)
            card.LayoutOrder = nextOrder()
            card.BorderSizePixel = 0
            Instance.new("UICorner", card).CornerRadius = T.ElementRadius

            local avatar = Instance.new("ImageLabel")
            avatar.Parent = card
            avatar.BackgroundColor3 = T.InputBG
            avatar.Position = UDim2.new(0, 12, 0, 12)
            avatar.Size = UDim2.new(0, 66, 0, 66)
            avatar.BorderSizePixel = 0
            Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
            pcall(function()
                avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=150&h=150"
            end)

            local displayName = Instance.new("TextLabel")
            displayName.Parent = card
            displayName.BackgroundTransparency = 1
            displayName.Position = UDim2.new(0, 90, 0, 14)
            displayName.Size = UDim2.new(1, -100, 0, 22)
            displayName.Font = T.FontBold
            displayName.Text = (cfg2.DisplayName or player.DisplayName)
            displayName.TextColor3 = T.TextPrimary
            displayName.TextSize = 18
            displayName.TextXAlignment = Enum.TextXAlignment.Left

            local username = Instance.new("TextLabel")
            username.Parent = card
            username.BackgroundTransparency = 1
            username.Position = UDim2.new(0, 90, 0, 38)
            username.Size = UDim2.new(1, -100, 0, 16)
            username.Font = T.FontLight
            username.Text = "@" .. (cfg2.Username or player.Name)
            username.TextColor3 = T.TextSecondary
            username.TextSize = 13
            username.TextXAlignment = Enum.TextXAlignment.Left

            local idLabel = Instance.new("TextLabel")
            idLabel.Parent = card
            idLabel.BackgroundTransparency = 1
            idLabel.Position = UDim2.new(0, 90, 0, 56)
            idLabel.Size = UDim2.new(1, -100, 0, 16)
            idLabel.Font = T.FontLight
            idLabel.Text = cfg2.Subtitle or ("ID: " .. tostring(player.UserId))
            idLabel.TextColor3 = T.TextMuted
            idLabel.TextSize = 12
            idLabel.TextXAlignment = Enum.TextXAlignment.Left

            local pcObj = {}
            function pcObj:SetDisplayName(t) displayName.Text = t end
            function pcObj:SetUsername(t) username.Text = "@" .. t end
            function pcObj:SetSubtitle(t) idLabel.Text = t end
            function pcObj:SetVisible(v) card.Visible = v end
            function pcObj:Destroy() card:Destroy() end
            return pcObj
        end

        -- =============================================================
        -- WIDGET: Graph / Chart
        -- =============================================================
        function Tab:CreateGraph(cfg2)
            local graphType = cfg2.Type or "line"
            local data = cfg2.Data or {}
            local graphWidth = cfg2.Width
            local graphHeight = cfg2.Height or 150

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, graphHeight + 40)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            if cfg2.Name then
                local gTitle = Instance.new("TextLabel")
                gTitle.Parent = frame
                gTitle.BackgroundTransparency = 1
                gTitle.Position = UDim2.new(0, 12, 0, 6)
                gTitle.Size = UDim2.new(1, -24, 0, 20)
                gTitle.Font = T.FontBold
                gTitle.Text = cfg2.Name
                gTitle.TextColor3 = T.TextPrimary
                gTitle.TextSize = T.SmallTextSize
                gTitle.TextXAlignment = Enum.TextXAlignment.Left
            end

            local graphCanvas = Instance.new("Frame")
            graphCanvas.Parent = frame
            graphCanvas.BackgroundTransparency = 1
            graphCanvas.Position = UDim2.new(0, 12, 0, 28)
            graphCanvas.Size = UDim2.new(1, -24, 0, graphHeight)
            graphCanvas.ClipsDescendants = true

            local function drawBarChart(d)
                for _, ch in ipairs(graphCanvas:GetChildren()) do ch:Destroy() end
                if #d == 0 then return end
                local maxVal = 0
                for _, item in ipairs(d) do
                    if item.Value > maxVal then maxVal = item.Value end
                end
                if maxVal == 0 then maxVal = 1 end
                local barWidth = 1 / #d
                for i, item in ipairs(d) do
                    local barHeight2 = (item.Value / maxVal)
                    local bar = Instance.new("Frame")
                    bar.Parent = graphCanvas
                    bar.BackgroundColor3 = item.Color or T.Accent
                    bar.AnchorPoint = Vector2.new(0, 1)
                    bar.Position = UDim2.new(barWidth * (i - 1), 2, 1, 0)
                    bar.Size = UDim2.new(barWidth, -4, 0, 0)
                    bar.BorderSizePixel = 0
                    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

                    TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                        Size = UDim2.new(barWidth, -4, barHeight2, 0)
                    }):Play()

                    if item.Label then
                        local lbl2 = Instance.new("TextLabel")
                        lbl2.Parent = bar
                        lbl2.BackgroundTransparency = 1
                        lbl2.Position = UDim2.new(0, 0, 1, 2)
                        lbl2.Size = UDim2.new(1, 0, 0, 14)
                        lbl2.Font = T.FontLight
                        lbl2.Text = item.Label
                        lbl2.TextColor3 = T.TextMuted
                        lbl2.TextSize = 9
                    end
                end
            end

            local function drawLineChart(d)
                for _, ch in ipairs(graphCanvas:GetChildren()) do ch:Destroy() end
                if #d < 2 then return end
                local maxVal, minVal = -math.huge, math.huge
                for _, item in ipairs(d) do
                    if item.Value > maxVal then maxVal = item.Value end
                    if item.Value < minVal then minVal = item.Value end
                end
                if maxVal == minVal then maxVal = minVal + 1 end
                local range = maxVal - minVal
                for i, item in ipairs(d) do
                    local x = (i - 1) / (#d - 1)
                    local y = 1 - (item.Value - minVal) / range
                    local dot = Instance.new("Frame")
                    dot.Parent = graphCanvas
                    dot.BackgroundColor3 = item.Color or T.Accent
                    dot.AnchorPoint = Vector2.new(0.5, 0.5)
                    dot.Position = UDim2.new(x, 0, y, 0)
                    dot.Size = UDim2.new(0, 6, 0, 6)
                    dot.BorderSizePixel = 0
                    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                    if i < #d then
                        local nextItem = d[i + 1]
                        local nx = i / (#d - 1)
                        local ny = 1 - (nextItem.Value - minVal) / range
                        local line = Instance.new("Frame")
                        line.Parent = graphCanvas
                        line.BackgroundColor3 = T.Accent
                        line.BackgroundTransparency = 0.3
                        local midX = (x + nx) / 2
                        local midY = (y + ny) / 2
                        line.AnchorPoint = Vector2.new(0.5, 0.5)
                        local dx2 = (nx - x) * graphCanvas.AbsoluteSize.X
                        local dy2 = (ny - y) * graphCanvas.AbsoluteSize.Y
                        local dist = math.sqrt(dx2 * dx2 + dy2 * dy2)
                        local angle = math.atan2(dy2, dx2)
                        line.Position = UDim2.new(midX, 0, midY, 0)
                        line.Size = UDim2.new(0, dist, 0, 2)
                        line.Rotation = math.deg(angle)
                        line.BorderSizePixel = 0
                    end
                end
            end

            if graphType == "bar" then
                drawBarChart(data)
            else
                drawLineChart(data)
            end

            local gObj = {}
            function gObj:SetData(d)
                data = d
                if graphType == "bar" then drawBarChart(data)
                else drawLineChart(data) end
            end
            function gObj:AddPoint(point)
                table.insert(data, point)
                if graphType == "bar" then drawBarChart(data)
                else drawLineChart(data) end
            end
            function gObj:SetVisible(v) frame.Visible = v end
            function gObj:Destroy() frame:Destroy() end
            return gObj
        end

        -- =============================================================
        -- WIDGET: Range Slider (Dual Thumb)
        -- =============================================================
        function Tab:CreateRangeSlider(cfg2)
            local min = cfg2.Min or 0
            local max = cfg2.Max or 100
            local inc = cfg2.Increment or 1
            local suffix = cfg2.Suffix or ""
            local lowVal = cfg2.DefaultLow or min
            local highVal = cfg2.DefaultHigh or max

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundColor3 = T.ElementBG
            frame.Size = UDim2.new(1, 0, 0, T.SliderHeight)
            frame.LayoutOrder = nextOrder()
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.BackgroundTransparency = 1
            lbl.Position = UDim2.new(0, 12, 0, 4)
            lbl.Size = UDim2.new(1, -24, 0, 18)
            lbl.Font = T.Font
            lbl.TextSize = T.SmallTextSize
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextColor3 = T.TextPrimary
            lbl.Text = (cfg2.Name or "Range") .. ": " .. lowVal .. suffix .. " - " .. highVal .. suffix

            local track = Instance.new("Frame")
            track.Parent = frame
            track.BackgroundColor3 = T.SliderTrack
            track.Position = UDim2.new(0, 12, 0, 32)
            track.Size = UDim2.new(1, -24, 0, 6)
            track.BorderSizePixel = 0
            Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

            local function valToPct(v) return (v - min) / math.max(max - min, 1) end

            local fill = Instance.new("Frame")
            fill.Parent = track
            fill.BackgroundColor3 = T.Accent
            fill.Position = UDim2.new(valToPct(lowVal), 0, 0, 0)
            fill.Size = UDim2.new(valToPct(highVal) - valToPct(lowVal), 0, 1, 0)
            fill.BorderSizePixel = 0
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local lowKnob = Instance.new("Frame")
            lowKnob.Parent = track
            lowKnob.BackgroundColor3 = T.SliderKnob
            lowKnob.AnchorPoint = Vector2.new(0.5, 0.5)
            lowKnob.Position = UDim2.new(valToPct(lowVal), 0, 0.5, 0)
            lowKnob.Size = UDim2.new(0, 14, 0, 14)
            lowKnob.BorderSizePixel = 0
            lowKnob.ZIndex = 3
            Instance.new("UICorner", lowKnob).CornerRadius = UDim.new(1, 0)

            local highKnob = Instance.new("Frame")
            highKnob.Parent = track
            highKnob.BackgroundColor3 = T.SliderKnob
            highKnob.AnchorPoint = Vector2.new(0.5, 0.5)
            highKnob.Position = UDim2.new(valToPct(highVal), 0, 0.5, 0)
            highKnob.Size = UDim2.new(0, 14, 0, 14)
            highKnob.BorderSizePixel = 0
            highKnob.ZIndex = 3
            Instance.new("UICorner", highKnob).CornerRadius = UDim.new(1, 0)

            local draggingLow = false
            local draggingHigh = false

            local function updateVisual()
                local lowPct = valToPct(lowVal)
                local highPct = valToPct(highVal)
                lowKnob.Position = UDim2.new(lowPct, 0, 0.5, 0)
                highKnob.Position = UDim2.new(highPct, 0, 0.5, 0)
                fill.Position = UDim2.new(lowPct, 0, 0, 0)
                fill.Size = UDim2.new(highPct - lowPct, 0, 1, 0)
                lbl.Text = (cfg2.Name or "Range") .. ": " .. lowVal .. suffix .. " - " .. highVal .. suffix
            end

            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    local rel = clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local rawVal = min + (max - min) * rel
                    if math.abs(rawVal - lowVal) < math.abs(rawVal - highVal) then
                        draggingLow = true
                    else
                        draggingHigh = true
                    end
                end
            end)

            UserInputService.InputChanged:Connect(function(i)
                if (draggingLow or draggingHigh) and
                   (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local rel = clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    local rawVal = clamp(math.floor((min + (max - min) * rel) / inc + 0.5) * inc, min, max)
                    if draggingLow then
                        lowVal = math.min(rawVal, highVal)
                    elseif draggingHigh then
                        highVal = math.max(rawVal, lowVal)
                    end
                    updateVisual()
                    if cfg2.Callback then safeCallback(cfg2.Callback, lowVal, highVal) end
                end
            end)

            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingLow = false
                    draggingHigh = false
                end
            end)

            local rsObj = {}
            function rsObj:GetLow() return lowVal end
            function rsObj:GetHigh() return highVal end
            function rsObj:Set(low, high) lowVal = low; highVal = high; updateVisual() end
            function rsObj:SetVisible(v) frame.Visible = v end
            function rsObj:Destroy() frame:Destroy() end
            return rsObj
        end

        -- =============================================================
        -- CONTAINER: Horizontal Row
        -- =============================================================
        function Tab:CreateHorizontalRow(cfg2)
            cfg2 = cfg2 or {}
            local row = Instance.new("Frame")
            row.Parent = container
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, cfg2.Height or T.ElementHeight)
            row.LayoutOrder = nextOrder()
            row.BorderSizePixel = 0

            local layout = Instance.new("UIListLayout", row)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.Padding = UDim.new(0, cfg2.Padding or 8)
            layout.VerticalAlignment = Enum.VerticalAlignment.Center
            if cfg2.Alignment == "Center" then
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            elseif cfg2.Alignment == "Right" then
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            end

            local hRow = { Container = row }

            function hRow:AddButton(btnCfg)
                local btn = Instance.new("TextButton")
                btn.Parent = row
                btn.BackgroundColor3 = btnCfg.Color or T.Accent
                btn.Size = UDim2.new(0, btnCfg.Width or 100, 1, -4)
                btn.Font = T.Font
                btn.Text = btnCfg.Name or "Button"
                btn.TextColor3 = btnCfg.TextColor or Color3.fromRGB(255, 255, 255)
                btn.TextSize = T.SmallTextSize
                btn.AutoButtonColor = false
                btn.BorderSizePixel = 0
                Instance.new("UICorner", btn).CornerRadius = T.ElementRadius
                btn.MouseButton1Click:Connect(function()
                    if btnCfg.Callback then safeCallback(btnCfg.Callback) end
                end)
                return btn
            end

            function hRow:AddLabel(text)
                local lbl2 = Instance.new("TextLabel")
                lbl2.Parent = row
                lbl2.BackgroundTransparency = 1
                lbl2.Size = UDim2.new(0, 0, 1, 0)
                lbl2.AutomaticSize = Enum.AutomaticSize.X
                lbl2.Font = T.FontLight
                lbl2.Text = text
                lbl2.TextColor3 = T.TextSecondary
                lbl2.TextSize = T.SmallTextSize
                return lbl2
            end

            function hRow:Destroy() row:Destroy() end
            return hRow
        end

        -- =============================================================
        -- CONTAINER: Grid
        -- =============================================================
        function Tab:CreateGrid(cfg2)
            cfg2 = cfg2 or {}
            local grid = Instance.new("Frame")
            grid.Parent = container
            grid.BackgroundTransparency = 1
            grid.Size = UDim2.new(1, 0, 0, 0)
            grid.AutomaticSize = Enum.AutomaticSize.Y
            grid.LayoutOrder = nextOrder()
            grid.BorderSizePixel = 0

            local gridLayout = Instance.new("UIGridLayout", grid)
            gridLayout.CellSize = cfg2.CellSize or UDim2.new(0, 120, 0, 80)
            gridLayout.CellPadding = cfg2.CellPadding or UDim2.new(0, 8, 0, 8)
            gridLayout.FillDirection = Enum.FillDirection.Horizontal
            gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local gridObj = { Container = grid }

            function gridObj:AddCard(cardCfg)
                local card = Instance.new("TextButton")
                card.Parent = grid
                card.BackgroundColor3 = cardCfg.Color or T.ElementBG
                card.Font = T.Font
                card.Text = cardCfg.Name or ""
                card.TextColor3 = T.TextPrimary
                card.TextSize = T.SmallTextSize
                card.AutoButtonColor = false
                card.BorderSizePixel = 0
                Instance.new("UICorner", card).CornerRadius = T.ElementRadius
                card.MouseEnter:Connect(function()
                    TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = T.ElementHover }):Play()
                end)
                card.MouseLeave:Connect(function()
                    TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = cardCfg.Color or T.ElementBG }):Play()
                end)
                if cardCfg.Callback then
                    card.MouseButton1Click:Connect(function() safeCallback(cardCfg.Callback) end)
                end
                return card
            end

            function gridObj:SetCellSize(size) gridLayout.CellSize = size end
            function gridObj:Destroy() grid:Destroy() end
            return gridObj
        end

        -- =============================================================
        -- WIDGET: Pagination
        -- =============================================================
        function Tab:CreatePagination(cfg2)
            local currentPage = cfg2.CurrentPage or 1
            local totalPages = cfg2.TotalPages or 1

            local frame = Instance.new("Frame")
            frame.Parent = container
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.new(1, 0, 0, 32)
            frame.LayoutOrder = nextOrder()

            local layout = Instance.new("UIListLayout", frame)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.Padding = UDim.new(0, 4)
            layout.VerticalAlignment = Enum.VerticalAlignment.Center

            local prevBtn = Instance.new("TextButton")
            prevBtn.Parent = frame
            prevBtn.BackgroundColor3 = T.ElementBG
            prevBtn.Size = UDim2.new(0, 32, 0, 28)
            prevBtn.Font = T.FontBold
            prevBtn.Text = "‹"
            prevBtn.TextColor3 = T.TextPrimary
            prevBtn.TextSize = 18
            prevBtn.AutoButtonColor = false
            prevBtn.BorderSizePixel = 0
            Instance.new("UICorner", prevBtn).CornerRadius = T.SmallRadius

            local pageLabel = Instance.new("TextLabel")
            pageLabel.Parent = frame
            pageLabel.BackgroundColor3 = T.Accent
            pageLabel.Size = UDim2.new(0, 60, 0, 28)
            pageLabel.Font = T.FontBold
            pageLabel.Text = currentPage .. "/" .. totalPages
            pageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            pageLabel.TextSize = T.SmallTextSize
            pageLabel.BorderSizePixel = 0
            Instance.new("UICorner", pageLabel).CornerRadius = T.SmallRadius

            local nextBtn = Instance.new("TextButton")
            nextBtn.Parent = frame
            nextBtn.BackgroundColor3 = T.ElementBG
            nextBtn.Size = UDim2.new(0, 32, 0, 28)
            nextBtn.Font = T.FontBold
            nextBtn.Text = "›"
            nextBtn.TextColor3 = T.TextPrimary
            nextBtn.TextSize = 18
            nextBtn.AutoButtonColor = false
            nextBtn.BorderSizePixel = 0
            Instance.new("UICorner", nextBtn).CornerRadius = T.SmallRadius

            local function updateLabel()
                pageLabel.Text = currentPage .. "/" .. totalPages
            end

            prevBtn.MouseButton1Click:Connect(function()
                if currentPage > 1 then
                    currentPage = currentPage - 1
                    updateLabel()
                    if cfg2.Callback then safeCallback(cfg2.Callback, currentPage) end
                end
            end)

            nextBtn.MouseButton1Click:Connect(function()
                if currentPage < totalPages then
                    currentPage = currentPage + 1
                    updateLabel()
                    if cfg2.Callback then safeCallback(cfg2.Callback, currentPage) end
                end
            end)

            local pgObj = {}
            function pgObj:SetPage(p) currentPage = clamp(p, 1, totalPages); updateLabel() end
            function pgObj:GetPage() return currentPage end
            function pgObj:SetTotalPages(tp) totalPages = tp; currentPage = clamp(currentPage, 1, tp); updateLabel() end
            function pgObj:Destroy() frame:Destroy() end
            return pgObj
        end

        -- =============================================================
        -- WIDGET: Image Card
        -- =============================================================
        function Tab:CreateImageCard(cfg2)
            local card = Instance.new("Frame")
            card.Parent = container
            card.BackgroundColor3 = T.ElementBG
            card.Size = UDim2.new(1, 0, 0, cfg2.Height or 120)
            card.LayoutOrder = nextOrder()
            card.BorderSizePixel = 0
            Instance.new("UICorner", card).CornerRadius = T.ElementRadius

            local img = Instance.new("ImageLabel")
            img.Parent = card
            img.BackgroundTransparency = 1
            img.Size = UDim2.new(1, 0, 1, cfg2.Caption and -24 or 0)
            img.Image = cfg2.Image or ""
            img.ScaleType = cfg2.ScaleType or Enum.ScaleType.Fit
            img.BorderSizePixel = 0
            Instance.new("UICorner", img).CornerRadius = T.ElementRadius

            if cfg2.Caption then
                local caption = Instance.new("TextLabel")
                caption.Parent = card
                caption.BackgroundTransparency = 1
                caption.Position = UDim2.new(0, 10, 1, -22)
                caption.Size = UDim2.new(1, -20, 0, 18)
                caption.Font = T.FontLight
                caption.Text = cfg2.Caption
                caption.TextColor3 = T.TextMuted
                caption.TextSize = T.TinyTextSize
                caption.TextXAlignment = Enum.TextXAlignment.Left
            end

            local icObj = {}
            function icObj:SetImage(i) img.Image = i end
            function icObj:SetCaption(c) end
            function icObj:SetVisible(v) card.Visible = v end
            function icObj:Destroy() card:Destroy() end
            return icObj
        end

        -- =============================================================
        -- Context Menu on Tab Container
        -- =============================================================
        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                local mouse = UserInputService:GetMouseLocation()
                openContextMenu(mouse.X, mouse.Y, {
                    { Name = "Scroll to Top", Callback = function() container.CanvasPosition = Vector2.new(0, 0) end },
                    { Name = "Scroll to Bottom", Callback = function()
                        container.CanvasPosition = Vector2.new(0, container.CanvasSize.Y.Offset)
                    end },
                    { Separator = true },
                    { Name = "Collapse All", Callback = function() end },
                }, T)
            end
        end)

        return Tab
    end

    -- =================================================================
    -- STATUS BAR
    -- =================================================================
    if config.StatusBar then
        local statusBar = Instance.new("Frame")
        statusBar.Parent = main
        statusBar.BackgroundColor3 = T.TopBar
        statusBar.Position = UDim2.new(0, 0, 1, -T.StatusBarHeight)
        statusBar.Size = UDim2.new(1, 0, 0, T.StatusBarHeight)
        statusBar.BorderSizePixel = 0
        statusBar.ZIndex = 5

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Parent = statusBar
        statusLabel.BackgroundTransparency = 1
        statusLabel.Position = UDim2.new(0, 10, 0, 0)
        statusLabel.Size = UDim2.new(0.5, -10, 1, 0)
        statusLabel.Font = T.FontLight
        statusLabel.TextSize = T.TinyTextSize
        statusLabel.TextColor3 = T.TextMuted
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Text = "Ready"

        local statusRight = Instance.new("TextLabel")
        statusRight.Parent = statusBar
        statusRight.BackgroundTransparency = 1
        statusRight.Position = UDim2.new(0.5, 0, 0, 0)
        statusRight.Size = UDim2.new(0.5, -10, 1, 0)
        statusRight.Font = T.FontLight
        statusRight.TextSize = T.TinyTextSize
        statusRight.TextColor3 = T.TextMuted
        statusRight.TextXAlignment = Enum.TextXAlignment.Right
        statusRight.Text = "StarLib v" .. STARLIB_VERSION

        content.Size = UDim2.new(1, -T.SidebarWidth, 1, -T.TopBarHeight - T.StatusBarHeight)

        function W:SetStatus(text) statusLabel.Text = text end
        function W:SetStatusRight(text) statusRight.Text = text end
    end

    debugLog("Window '" .. windowName .. "' created in " .. string.format("%.2f", (tick() - startTime) * 1000) .. "ms")

    return W
end

-- =========================================================================
-- SECTION 18: STANDALONE WIDGETS (Outside CreateWindow)
-- =========================================================================

-- These are utility widgets that can be used independently

function StarLib:CreateNotificationManager(config)
    config = config or {}
    local maxNotifs = config.MaxNotifs or 5
    local position = config.Position or "BottomRight"
    local nGui = Instance.new("ScreenGui")
    nGui.Name = "StarLib_StandaloneNotifs"
    nGui.DisplayOrder = 80
    nGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    protectGui(nGui)

    local container = Instance.new("Frame")
    container.Parent = nGui
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(0, 290, 1, -30)
    container.BorderSizePixel = 0

    if position == "BottomRight" then
        container.AnchorPoint = Vector2.new(1, 1)
        container.Position = UDim2.new(1, -15, 1, -15)
    elseif position == "TopRight" then
        container.AnchorPoint = Vector2.new(1, 0)
        container.Position = UDim2.new(1, -15, 0, 15)
    elseif position == "BottomLeft" then
        container.AnchorPoint = Vector2.new(0, 1)
        container.Position = UDim2.new(0, 15, 1, -15)
    else
        container.AnchorPoint = Vector2.new(0, 0)
        container.Position = UDim2.new(0, 15, 0, 15)
    end

    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    if position:find("Bottom") then
        layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end

    local activeNotifs = {}
    local T = mergeTable(DEFAULT_THEME, config.Theme or {})

    local mgr = {}

    function mgr:Notify(cfg)
        while #activeNotifs >= maxNotifs do
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then oldest:Destroy() end
        end

        local typeColors = {
            success = T.Success,
            warning = T.Warning,
            error = T.Error,
            info = T.Info,
        }
        local typeIcons = {
            success = "✓",
            warning = "⚠",
            error = "✗",
            info = "ℹ",
        }

        local ntype = cfg.Type and cfg.Type:lower() or "info"
        local typeColor = typeColors[ntype] or T.Info
        local typeIcon = typeIcons[ntype] or "ℹ"
        local duration = cfg.Duration or T.NotifDuration

        local nf = Instance.new("Frame")
        nf.Parent = container
        nf.BackgroundColor3 = T.NotifBG
        nf.Size = UDim2.new(1, 0, 0, 0)
        nf.ClipsDescendants = true
        nf.BorderSizePixel = 0
        nf.LayoutOrder = tick() * 1000
        Instance.new("UICorner", nf).CornerRadius = T.CornerRadius

        local accent = Instance.new("Frame")
        accent.Parent = nf
        accent.BackgroundColor3 = typeColor
        accent.Size = UDim2.new(0, 3, 1, -8)
        accent.Position = UDim2.new(0, 4, 0, 4)
        accent.BorderSizePixel = 0
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

        local icon = Instance.new("TextLabel")
        icon.Parent = nf
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(0, 14, 0, 10)
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Text = typeIcon
        icon.TextColor3 = typeColor
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 16

        local nTitle = Instance.new("TextLabel")
        nTitle.Parent = nf
        nTitle.BackgroundTransparency = 1
        nTitle.Position = UDim2.new(0, 38, 0, 8)
        nTitle.Size = UDim2.new(1, -75, 0, 20)
        nTitle.Font = T.FontBold
        nTitle.Text = cfg.Title or "Notification"
        nTitle.TextColor3 = T.TextPrimary
        nTitle.TextSize = T.TextSize
        nTitle.TextXAlignment = Enum.TextXAlignment.Left
        nTitle.TextTruncate = Enum.TextTruncate.AtEnd

        local nContent = Instance.new("TextLabel")
        nContent.Parent = nf
        nContent.BackgroundTransparency = 1
        nContent.Position = UDim2.new(0, 38, 0, 28)
        nContent.Size = UDim2.new(1, -50, 0, 36)
        nContent.Font = T.FontLight
        nContent.Text = cfg.Content or ""
        nContent.TextColor3 = T.TextSecondary
        nContent.TextSize = T.SmallTextSize
        nContent.TextXAlignment = Enum.TextXAlignment.Left
        nContent.TextYAlignment = Enum.TextYAlignment.Top
        nContent.TextWrapped = true

        local closeBtn = Instance.new("TextButton")
        closeBtn.Parent = nf
        closeBtn.BackgroundTransparency = 1
        closeBtn.Position = UDim2.new(1, -28, 0, 4)
        closeBtn.Size = UDim2.new(0, 24, 0, 24)
        closeBtn.Text = "×"
        closeBtn.TextColor3 = T.TextMuted
        closeBtn.Font = T.FontBold
        closeBtn.TextSize = 16

        local progress = Instance.new("Frame")
        progress.Parent = nf
        progress.BackgroundColor3 = T.SliderTrack
        progress.Position = UDim2.new(0, 12, 1, -10)
        progress.Size = UDim2.new(1, -24, 0, 3)
        progress.BorderSizePixel = 0
        Instance.new("UICorner", progress).CornerRadius = UDim.new(1, 0)

        local progressFill = Instance.new("Frame")
        progressFill.Parent = progress
        progressFill.BackgroundColor3 = typeColor
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        progressFill.BorderSizePixel = 0
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

        TweenService:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(1, 0, 0, 78)
        }):Play()

        table.insert(activeNotifs, nf)

        local dismissed = false
        local function dismiss()
            if dismissed then return end
            dismissed = true
            tableRemove(activeNotifs, nf)
            TweenService:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.3, function()
                if nf.Parent then nf:Destroy() end
            end)
        end

        closeBtn.MouseButton1Click:Connect(dismiss)

        task.spawn(function()
            TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Size = UDim2.new(0, 0, 1, 0)
            }):Play()
            task.wait(duration)
            dismiss()
        end)
    end

    function mgr:ClearAll()
        for _, nf in ipairs(activeNotifs) do
            if nf.Parent then nf:Destroy() end
        end
        activeNotifs = {}
    end

    function mgr:Destroy() nGui:Destroy() end

    return mgr
end

-- =========================================================================
-- SECTION 19: EXTENDED WIDGET CONSTRUCTORS (Added to Tab)
-- =========================================================================

-- These are registered as additional constructors during CreateTab.
-- Since Tab methods are defined inside CreateWindow/CreateTab closure,
-- we extend them via a post-creation hook pattern.

local _tabExtensions = {}

function StarLib:RegisterTabExtension(name, constructor)
    _tabExtensions[name] = constructor
end

-- Tree View Extension
StarLib:RegisterTabExtension("CreateTreeView", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 200)
        frame.ClipsDescendants = true
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        if cfg2.Name then
            local tvTitle = Instance.new("TextLabel")
            tvTitle.Parent = frame
            tvTitle.BackgroundTransparency = 1
            tvTitle.Position = UDim2.new(0, 12, 0, 4)
            tvTitle.Size = UDim2.new(1, -24, 0, 22)
            tvTitle.Font = T.FontBold
            tvTitle.Text = cfg2.Name
            tvTitle.TextColor3 = T.TextPrimary
            tvTitle.TextSize = T.SmallTextSize
            tvTitle.TextXAlignment = Enum.TextXAlignment.Left
        end

        local treeScroll = Instance.new("ScrollingFrame")
        treeScroll.Parent = frame
        treeScroll.BackgroundTransparency = 1
        treeScroll.Position = UDim2.new(0, 0, 0, cfg2.Name and 26 or 0)
        treeScroll.Size = UDim2.new(1, 0, 1, cfg2.Name and -26 or 0)
        treeScroll.ScrollBarThickness = 2
        treeScroll.ScrollBarImageColor3 = T.ScrollBar
        treeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        treeScroll.BorderSizePixel = 0

        local treeLayout = Instance.new("UIListLayout", treeScroll)
        treeLayout.Padding = UDim.new(0, 1)

        local treeData = cfg2.Data or {}
        local expandedNodes = {}
        local selectedNode = nil

        local function renderNode(node, depth, parentKey)
            local nodeKey = (parentKey or "") .. "/" .. (node.Name or "node")
            local hasChildren = node.Children and #node.Children > 0
            local isExpanded = expandedNodes[nodeKey]

            local nodeBtn = Instance.new("TextButton")
            nodeBtn.Parent = treeScroll
            nodeBtn.BackgroundTransparency = 1
            nodeBtn.Size = UDim2.new(1, 0, 0, 24)
            nodeBtn.Font = T.FontLight
            nodeBtn.TextColor3 = selectedNode == nodeKey and T.Accent or T.TextSecondary
            nodeBtn.TextSize = T.SmallTextSize
            nodeBtn.TextXAlignment = Enum.TextXAlignment.Left
            nodeBtn.AutoButtonColor = false
            nodeBtn.BorderSizePixel = 0

            local indent = depth * 20
            local prefix = hasChildren and (isExpanded and "▼ " or "▶ ") or "   "
            local icon = node.Icon or ""
            nodeBtn.Text = string.rep(" ", depth * 3) .. prefix .. icon .. (icon ~= "" and " " or "") .. (node.Name or "")

            nodeBtn.MouseEnter:Connect(function()
                if selectedNode ~= nodeKey then
                    nodeBtn.BackgroundTransparency = 0
                    nodeBtn.BackgroundColor3 = T.ElementHover
                end
            end)
            nodeBtn.MouseLeave:Connect(function()
                if selectedNode ~= nodeKey then
                    nodeBtn.BackgroundTransparency = 1
                end
            end)

            nodeBtn.MouseButton1Click:Connect(function()
                if hasChildren then
                    expandedNodes[nodeKey] = not expandedNodes[nodeKey]
                end
                selectedNode = nodeKey
                if cfg2.OnSelect then
                    safeCallback(cfg2.OnSelect, node, nodeKey)
                end
                renderTree()
            end)

            if hasChildren and isExpanded then
                for _, child in ipairs(node.Children) do
                    renderNode(child, depth + 1, nodeKey)
                end
            end
        end

        function renderTree()
            for _, ch in ipairs(treeScroll:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            for _, node in ipairs(treeData) do
                renderNode(node, 0, "")
            end
            local count = 0
            for _, ch in ipairs(treeScroll:GetChildren()) do
                if ch:IsA("TextButton") then count = count + 1 end
            end
            treeScroll.CanvasSize = UDim2.new(0, 0, 0, count * 25)
        end

        renderTree()

        local tvObj = {}
        function tvObj:SetData(d) treeData = d; renderTree() end
        function tvObj:ExpandAll()
            local function expandAll(nodes, parentKey)
                for _, node in ipairs(nodes) do
                    local key = (parentKey or "") .. "/" .. (node.Name or "node")
                    expandedNodes[key] = true
                    if node.Children then expandAll(node.Children, key) end
                end
            end
            expandAll(treeData, "")
            renderTree()
        end
        function tvObj:CollapseAll() expandedNodes = {}; renderTree() end
        function tvObj:Refresh() renderTree() end
        function tvObj:SetVisible(v) frame.Visible = v end
        function tvObj:Destroy() frame:Destroy() end
        return tvObj
    end
end)

-- Stepper / Wizard Extension
StarLib:RegisterTabExtension("CreateStepper", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local steps = cfg2.Steps or {}
        local currentStep = cfg2.StartStep or 1

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 60)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local stepContainer = Instance.new("Frame")
        stepContainer.Parent = frame
        stepContainer.BackgroundTransparency = 1
        stepContainer.Size = UDim2.new(1, -20, 0, 36)
        stepContainer.Position = UDim2.new(0, 10, 0, 8)

        local stepIndicators = {}
        local stepWidth = 1 / math.max(#steps, 1)

        local function updateSteps()
            for i, indicator in ipairs(stepIndicators) do
                local isComplete = i < currentStep
                local isCurrent = i == currentStep
                local color = isComplete and T.Success or (isCurrent and T.Accent or T.SliderTrack)
                indicator.circle.BackgroundColor3 = color
                indicator.label.TextColor3 = isCurrent and T.TextPrimary or T.TextMuted
                indicator.numLabel.TextColor3 = (isComplete or isCurrent) and Color3.fromRGB(255, 255, 255) or T.TextMuted
                indicator.numLabel.Text = isComplete and "✓" or tostring(i)
                if indicator.line then
                    indicator.line.BackgroundColor3 = isComplete and T.Success or T.SliderTrack
                end
            end
        end

        for i, step in ipairs(steps) do
            local circle = Instance.new("Frame")
            circle.Parent = stepContainer
            circle.BackgroundColor3 = i == 1 and T.Accent or T.SliderTrack
            circle.AnchorPoint = Vector2.new(0.5, 0)
            circle.Position = UDim2.new(stepWidth * (i - 0.5), 0, 0, 0)
            circle.Size = UDim2.new(0, 24, 0, 24)
            circle.BorderSizePixel = 0
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

            local numLabel = Instance.new("TextLabel")
            numLabel.Parent = circle
            numLabel.BackgroundTransparency = 1
            numLabel.Size = UDim2.new(1, 0, 1, 0)
            numLabel.Font = T.FontBold
            numLabel.Text = tostring(i)
            numLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            numLabel.TextSize = 11

            local stepLabel = Instance.new("TextLabel")
            stepLabel.Parent = stepContainer
            stepLabel.BackgroundTransparency = 1
            stepLabel.AnchorPoint = Vector2.new(0.5, 0)
            stepLabel.Position = UDim2.new(stepWidth * (i - 0.5), 0, 0, 26)
            stepLabel.Size = UDim2.new(stepWidth, 0, 0, 14)
            stepLabel.Font = T.FontLight
            stepLabel.Text = step
            stepLabel.TextColor3 = i == 1 and T.TextPrimary or T.TextMuted
            stepLabel.TextSize = T.TinyTextSize
            stepLabel.TextTruncate = Enum.TextTruncate.AtEnd

            local line = nil
            if i < #steps then
                line = Instance.new("Frame")
                line.Parent = stepContainer
                line.BackgroundColor3 = T.SliderTrack
                line.Position = UDim2.new(stepWidth * (i - 0.5), 12, 0, 11)
                line.Size = UDim2.new(stepWidth, -24, 0, 2)
                line.BorderSizePixel = 0
            end

            table.insert(stepIndicators, {
                circle = circle,
                numLabel = numLabel,
                label = stepLabel,
                line = line,
            })
        end

        local stpObj = {}
        function stpObj:Next()
            if currentStep < #steps then
                currentStep = currentStep + 1
                updateSteps()
                if cfg2.OnStepChanged then safeCallback(cfg2.OnStepChanged, currentStep) end
            end
        end
        function stpObj:Previous()
            if currentStep > 1 then
                currentStep = currentStep - 1
                updateSteps()
                if cfg2.OnStepChanged then safeCallback(cfg2.OnStepChanged, currentStep) end
            end
        end
        function stpObj:SetStep(s) currentStep = clamp(s, 1, #steps); updateSteps() end
        function stpObj:GetStep() return currentStep end
        function stpObj:SetVisible(v) frame.Visible = v end
        function stpObj:Destroy() frame:Destroy() end
        return stpObj
    end
end)

-- Number Input with +/- buttons
StarLib:RegisterTabExtension("CreateNumberInput", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local val = cfg2.Default or 0
        local min = cfg2.Min or -math.huge
        local max = cfg2.Max or math.huge
        local step = cfg2.Step or 1
        local suffix = cfg2.Suffix or ""

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local lbl = Instance.new("TextLabel")
        lbl.Parent = frame
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.Size = UDim2.new(0.5, -12, 1, 0)
        lbl.Font = T.Font
        lbl.Text = cfg2.Name or "Number"
        lbl.TextColor3 = T.TextPrimary
        lbl.TextSize = T.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local controlFrame = Instance.new("Frame")
        controlFrame.Parent = frame
        controlFrame.BackgroundColor3 = T.InputBG
        controlFrame.Position = UDim2.new(0.5, 5, 0.5, -14)
        controlFrame.Size = UDim2.new(0.5, -17, 0, 28)
        controlFrame.BorderSizePixel = 0
        Instance.new("UICorner", controlFrame).CornerRadius = UDim.new(0, 4)

        local decBtn = Instance.new("TextButton")
        decBtn.Parent = controlFrame
        decBtn.BackgroundColor3 = T.ElementHover
        decBtn.Size = UDim2.new(0, 28, 1, 0)
        decBtn.Font = T.FontBold
        decBtn.Text = "−"
        decBtn.TextColor3 = T.TextPrimary
        decBtn.TextSize = 16
        decBtn.AutoButtonColor = false
        decBtn.BorderSizePixel = 0
        Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, 4)

        local valBox = Instance.new("TextBox")
        valBox.Parent = controlFrame
        valBox.BackgroundTransparency = 1
        valBox.Position = UDim2.new(0, 30, 0, 0)
        valBox.Size = UDim2.new(1, -60, 1, 0)
        valBox.Font = T.FontMono
        valBox.Text = tostring(val) .. suffix
        valBox.TextColor3 = T.TextPrimary
        valBox.TextSize = T.SmallTextSize
        valBox.ClearTextOnFocus = true

        local incBtn = Instance.new("TextButton")
        incBtn.Parent = controlFrame
        incBtn.BackgroundColor3 = T.ElementHover
        incBtn.Position = UDim2.new(1, -28, 0, 0)
        incBtn.Size = UDim2.new(0, 28, 1, 0)
        incBtn.Font = T.FontBold
        incBtn.Text = "+"
        incBtn.TextColor3 = T.TextPrimary
        incBtn.TextSize = 16
        incBtn.AutoButtonColor = false
        incBtn.BorderSizePixel = 0
        Instance.new("UICorner", incBtn).CornerRadius = UDim.new(0, 4)

        local function updateVal(newVal)
            val = clamp(newVal, min, max)
            valBox.Text = tostring(val) .. suffix
            if cfg2.Callback then safeCallback(cfg2.Callback, val) end
        end

        decBtn.MouseButton1Click:Connect(function() updateVal(val - step) end)
        incBtn.MouseButton1Click:Connect(function() updateVal(val + step) end)
        valBox.FocusLost:Connect(function()
            local num = tonumber(valBox.Text:gsub(suffix, ""))
            if num then updateVal(num)
            else valBox.Text = tostring(val) .. suffix end
        end)

        local niObj = { _type = "numberinput" }
        function niObj:Get() return val end
        function niObj:Set(v) updateVal(v) end
        function niObj:SetVisible(v) frame.Visible = v end
        function niObj:Destroy() frame:Destroy() end

        if cfg2.Name then W._widgetRegistry[cfg2.Name] = niObj end
        return niObj
    end
end)

-- Switch Group (multiple toggles in a group)
StarLib:RegisterTabExtension("CreateSwitchGroup", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local switches = cfg2.Switches or {}
        local states = {}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0, 4)

        if cfg2.Name then
            local groupTitle = Instance.new("TextLabel")
            groupTitle.Parent = frame
            groupTitle.BackgroundTransparency = 1
            groupTitle.Size = UDim2.new(1, 0, 0, 22)
            groupTitle.Font = T.FontBold
            groupTitle.Text = cfg2.Name
            groupTitle.TextColor3 = T.TextPrimary
            groupTitle.TextSize = T.SmallTextSize
            groupTitle.TextXAlignment = Enum.TextXAlignment.Left
        end

        for _, sw in ipairs(switches) do
            states[sw.Name] = sw.Default or false

            local row = Instance.new("TextButton")
            row.Parent = frame
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 28)
            row.Font = T.FontLight
            row.Text = "  " .. sw.Name
            row.TextColor3 = T.TextSecondary
            row.TextSize = T.SmallTextSize
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.AutoButtonColor = false
            row.BorderSizePixel = 0

            local swBg = Instance.new("Frame")
            swBg.Parent = row
            swBg.BackgroundColor3 = states[sw.Name] and T.Accent or T.ToggleOff
            swBg.Position = UDim2.new(1, -40, 0.5, -9)
            swBg.Size = UDim2.new(0, 32, 0, 18)
            swBg.BorderSizePixel = 0
            Instance.new("UICorner", swBg).CornerRadius = UDim.new(1, 0)

            local swDot = Instance.new("Frame")
            swDot.Parent = swBg
            swDot.BackgroundColor3 = T.TextPrimary
            swDot.Position = states[sw.Name] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            swDot.Size = UDim2.new(0, 14, 0, 14)
            swDot.BorderSizePixel = 0
            Instance.new("UICorner", swDot).CornerRadius = UDim.new(1, 0)

            row.MouseButton1Click:Connect(function()
                states[sw.Name] = not states[sw.Name]
                TweenService:Create(swBg, TweenInfo.new(0.15), {
                    BackgroundColor3 = states[sw.Name] and T.Accent or T.ToggleOff
                }):Play()
                TweenService:Create(swDot, TweenInfo.new(0.15), {
                    Position = states[sw.Name] and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                }):Play()
                if sw.Callback then safeCallback(sw.Callback, states[sw.Name]) end
                if cfg2.Callback then safeCallback(cfg2.Callback, sw.Name, states[sw.Name], states) end
            end)
        end

        local sgObj = {}
        function sgObj:GetStates() return deepCopy(states) end
        function sgObj:GetState(name) return states[name] end
        function sgObj:SetVisible(v) frame.Visible = v end
        function sgObj:Destroy() frame:Destroy() end
        return sgObj
    end
end)

-- Stat Card
StarLib:RegisterTabExtension("CreateStatCard", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 75)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local accentLine = Instance.new("Frame")
        accentLine.Parent = frame
        accentLine.BackgroundColor3 = cfg2.Color or T.Accent
        accentLine.Size = UDim2.new(0, 3, 1, -16)
        accentLine.Position = UDim2.new(0, 6, 0, 8)
        accentLine.BorderSizePixel = 0
        Instance.new("UICorner", accentLine).CornerRadius = UDim.new(0, 2)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = frame
        titleLabel.BackgroundTransparency = 1
        titleLabel.Position = UDim2.new(0, 18, 0, 8)
        titleLabel.Size = UDim2.new(1, -28, 0, 18)
        titleLabel.Font = T.FontLight
        titleLabel.Text = cfg2.Name or "Stat"
        titleLabel.TextColor3 = T.TextMuted
        titleLabel.TextSize = T.SmallTextSize
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Parent = frame
        valueLabel.BackgroundTransparency = 1
        valueLabel.Position = UDim2.new(0, 18, 0, 28)
        valueLabel.Size = UDim2.new(1, -28, 0, 28)
        valueLabel.Font = T.FontBold
        valueLabel.Text = tostring(cfg2.Value or 0)
        valueLabel.TextColor3 = T.TextPrimary
        valueLabel.TextSize = 22
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left

        local subLabel = Instance.new("TextLabel")
        subLabel.Parent = frame
        subLabel.BackgroundTransparency = 1
        subLabel.Position = UDim2.new(0, 18, 0, 55)
        subLabel.Size = UDim2.new(1, -28, 0, 14)
        subLabel.Font = T.FontLight
        subLabel.Text = cfg2.Subtitle or ""
        subLabel.TextColor3 = cfg2.SubtitleColor or T.TextMuted
        subLabel.TextSize = T.TinyTextSize
        subLabel.TextXAlignment = Enum.TextXAlignment.Left

        local scObj = {}
        function scObj:SetValue(v) valueLabel.Text = tostring(v) end
        function scObj:AnimateValue(from, to, dur)
            Animate.countUp(valueLabel, from, to, dur or 1)
        end
        function scObj:SetSubtitle(t) subLabel.Text = t end
        function scObj:SetColor(c) accentLine.BackgroundColor3 = c end
        function scObj:SetVisible(v) frame.Visible = v end
        function scObj:Destroy() frame:Destroy() end
        return scObj
    end
end)

-- Timeline Widget
StarLib:RegisterTabExtension("CreateTimeline", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local events = cfg2.Events or {}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0, 0)

        if cfg2.Name then
            local tlTitle = Instance.new("TextLabel")
            tlTitle.Parent = frame
            tlTitle.BackgroundTransparency = 1
            tlTitle.Size = UDim2.new(1, 0, 0, 22)
            tlTitle.Font = T.FontBold
            tlTitle.Text = cfg2.Name
            tlTitle.TextColor3 = T.TextPrimary
            tlTitle.TextSize = T.SmallTextSize
            tlTitle.TextXAlignment = Enum.TextXAlignment.Left
        end

        local function buildTimeline(evts)
            for _, ch in ipairs(frame:GetChildren()) do
                if ch:IsA("Frame") and ch.Name == "TimelineEvent" then ch:Destroy() end
            end

            for i, evt in ipairs(evts) do
                local eventFrame = Instance.new("Frame")
                eventFrame.Parent = frame
                eventFrame.Name = "TimelineEvent"
                eventFrame.BackgroundTransparency = 1
                eventFrame.Size = UDim2.new(1, 0, 0, 50)

                local dot = Instance.new("Frame")
                dot.Parent = eventFrame
                dot.BackgroundColor3 = evt.Color or T.Accent
                dot.Position = UDim2.new(0, 0, 0, 6)
                dot.Size = UDim2.new(0, 10, 0, 10)
                dot.BorderSizePixel = 0
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

                if i < #evts then
                    local line = Instance.new("Frame")
                    line.Parent = eventFrame
                    line.BackgroundColor3 = T.Divider
                    line.Position = UDim2.new(0, 4, 0, 18)
                    line.Size = UDim2.new(0, 2, 0, 32)
                    line.BorderSizePixel = 0
                end

                local evtTitle = Instance.new("TextLabel")
                evtTitle.Parent = eventFrame
                evtTitle.BackgroundTransparency = 1
                evtTitle.Position = UDim2.new(0, 20, 0, 2)
                evtTitle.Size = UDim2.new(1, -20, 0, 18)
                evtTitle.Font = T.FontBold
                evtTitle.Text = evt.Title or ""
                evtTitle.TextColor3 = T.TextPrimary
                evtTitle.TextSize = T.SmallTextSize
                evtTitle.TextXAlignment = Enum.TextXAlignment.Left

                local evtTime = Instance.new("TextLabel")
                evtTime.Parent = eventFrame
                evtTime.BackgroundTransparency = 1
                evtTime.Position = UDim2.new(0, 20, 0, 20)
                evtTime.Size = UDim2.new(1, -20, 0, 14)
                evtTime.Font = T.FontLight
                evtTime.Text = evt.Time or ""
                evtTime.TextColor3 = T.TextMuted
                evtTime.TextSize = T.TinyTextSize
                evtTime.TextXAlignment = Enum.TextXAlignment.Left

                if evt.Description then
                    eventFrame.Size = UDim2.new(1, 0, 0, 64)
                    local evtDesc = Instance.new("TextLabel")
                    evtDesc.Parent = eventFrame
                    evtDesc.BackgroundTransparency = 1
                    evtDesc.Position = UDim2.new(0, 20, 0, 34)
                    evtDesc.Size = UDim2.new(1, -20, 0, 16)
                    evtDesc.Font = T.FontLight
                    evtDesc.Text = evt.Description
                    evtDesc.TextColor3 = T.TextSecondary
                    evtDesc.TextSize = T.TinyTextSize
                    evtDesc.TextXAlignment = Enum.TextXAlignment.Left
                    evtDesc.TextWrapped = true
                end
            end
        end

        buildTimeline(events)

        local tlObj = {}
        function tlObj:SetEvents(evts) events = evts; buildTimeline(events) end
        function tlObj:AddEvent(evt) table.insert(events, evt); buildTimeline(events) end
        function tlObj:SetVisible(v) frame.Visible = v end
        function tlObj:Destroy() frame:Destroy() end
        return tlObj
    end
end)

-- Player List Widget
StarLib:RegisterTabExtension("CreatePlayerList", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 200)
        frame.ClipsDescendants = true
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local headerFrame = Instance.new("Frame")
        headerFrame.Parent = frame
        headerFrame.BackgroundTransparency = 1
        headerFrame.Size = UDim2.new(1, 0, 0, 28)
        headerFrame.BorderSizePixel = 0

        local headerTitle = Instance.new("TextLabel")
        headerTitle.Parent = headerFrame
        headerTitle.BackgroundTransparency = 1
        headerTitle.Position = UDim2.new(0, 12, 0, 4)
        headerTitle.Size = UDim2.new(0.5, -12, 0, 20)
        headerTitle.Font = T.FontBold
        headerTitle.Text = cfg2.Name or "Players"
        headerTitle.TextColor3 = T.TextPrimary
        headerTitle.TextSize = T.SmallTextSize
        headerTitle.TextXAlignment = Enum.TextXAlignment.Left

        local countLabel = Instance.new("TextLabel")
        countLabel.Parent = headerFrame
        countLabel.BackgroundTransparency = 1
        countLabel.Position = UDim2.new(0.5, 0, 0, 4)
        countLabel.Size = UDim2.new(0.5, -12, 0, 20)
        countLabel.Font = T.FontLight
        countLabel.Text = ""
        countLabel.TextColor3 = T.TextMuted
        countLabel.TextSize = T.TinyTextSize
        countLabel.TextXAlignment = Enum.TextXAlignment.Right

        local listScroll = Instance.new("ScrollingFrame")
        listScroll.Parent = frame
        listScroll.BackgroundTransparency = 1
        listScroll.Position = UDim2.new(0, 0, 0, 28)
        listScroll.Size = UDim2.new(1, 0, 1, -28)
        listScroll.ScrollBarThickness = 2
        listScroll.ScrollBarImageColor3 = T.ScrollBar
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        listScroll.BorderSizePixel = 0

        local listLayout = Instance.new("UIListLayout", listScroll)
        listLayout.Padding = UDim.new(0, 2)

        local function refresh()
            for _, ch in ipairs(listScroll:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end

            local players = Players:GetPlayers()
            countLabel.Text = #players .. "/" .. Players.MaxPlayers

            for _, player in ipairs(players) do
                local row = Instance.new("Frame")
                row.Parent = listScroll
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 32)
                row.BorderSizePixel = 0

                local avatar = Instance.new("ImageLabel")
                avatar.Parent = row
                avatar.BackgroundColor3 = T.InputBG
                avatar.Position = UDim2.new(0, 8, 0, 4)
                avatar.Size = UDim2.new(0, 24, 0, 24)
                avatar.BorderSizePixel = 0
                Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)
                pcall(function()
                    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
                end)

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Parent = row
                nameLabel.BackgroundTransparency = 1
                nameLabel.Position = UDim2.new(0, 40, 0, 2)
                nameLabel.Size = UDim2.new(1, -100, 0, 16)
                nameLabel.Font = T.Font
                nameLabel.Text = player.DisplayName
                nameLabel.TextColor3 = player == LocalPlayer and T.Accent or T.TextPrimary
                nameLabel.TextSize = T.SmallTextSize
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

                local userLabel = Instance.new("TextLabel")
                userLabel.Parent = row
                userLabel.BackgroundTransparency = 1
                userLabel.Position = UDim2.new(0, 40, 0, 17)
                userLabel.Size = UDim2.new(1, -100, 0, 14)
                userLabel.Font = T.FontLight
                userLabel.Text = "@" .. player.Name
                userLabel.TextColor3 = T.TextMuted
                userLabel.TextSize = T.TinyTextSize
                userLabel.TextXAlignment = Enum.TextXAlignment.Left

                if cfg2.OnPlayerClick then
                    local clickBtn = Instance.new("TextButton")
                    clickBtn.Parent = row
                    clickBtn.BackgroundTransparency = 1
                    clickBtn.Size = UDim2.new(1, 0, 1, 0)
                    clickBtn.Text = ""
                    clickBtn.ZIndex = 2
                    clickBtn.MouseEnter:Connect(function()
                        row.BackgroundTransparency = 0
                        row.BackgroundColor3 = T.ElementHover
                    end)
                    clickBtn.MouseLeave:Connect(function()
                        row.BackgroundTransparency = 1
                    end)
                    clickBtn.MouseButton1Click:Connect(function()
                        safeCallback(cfg2.OnPlayerClick, player)
                    end)
                end
            end

            listScroll.CanvasSize = UDim2.new(0, 0, 0, #players * 34)
        end

        refresh()

        if cfg2.AutoRefresh ~= false then
            local addedConn = Players.PlayerAdded:Connect(function() task.wait(0.5); refresh() end)
            local removedConn = Players.PlayerRemoving:Connect(function() task.wait(0.5); refresh() end)
            table.insert(W._connections, addedConn)
            table.insert(W._connections, removedConn)
        end

        local plObj = {}
        function plObj:Refresh() refresh() end
        function plObj:SetVisible(v) frame.Visible = v end
        function plObj:Destroy() frame:Destroy() end
        return plObj
    end
end)

-- Console / Log Viewer
StarLib:RegisterTabExtension("CreateConsole", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local maxLines = cfg2.MaxLines or 200
        local lines = {}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 180)
        frame.ClipsDescendants = true
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local headerBar = Instance.new("Frame")
        headerBar.Parent = frame
        headerBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        headerBar.Size = UDim2.new(1, 0, 0, 24)
        headerBar.BorderSizePixel = 0

        local headerTitle = Instance.new("TextLabel")
        headerTitle.Parent = headerBar
        headerTitle.BackgroundTransparency = 1
        headerTitle.Position = UDim2.new(0, 10, 0, 0)
        headerTitle.Size = UDim2.new(0.5, -10, 1, 0)
        headerTitle.Font = T.FontMono
        headerTitle.Text = cfg2.Name or "Console"
        headerTitle.TextColor3 = T.TextMuted
        headerTitle.TextSize = T.TinyTextSize
        headerTitle.TextXAlignment = Enum.TextXAlignment.Left

        local clearBtn = Instance.new("TextButton")
        clearBtn.Parent = headerBar
        clearBtn.BackgroundTransparency = 1
        clearBtn.Position = UDim2.new(1, -50, 0, 0)
        clearBtn.Size = UDim2.new(0, 45, 1, 0)
        clearBtn.Font = T.FontLight
        clearBtn.Text = "Clear"
        clearBtn.TextColor3 = T.TextMuted
        clearBtn.TextSize = T.TinyTextSize

        local consoleScroll = Instance.new("ScrollingFrame")
        consoleScroll.Parent = frame
        consoleScroll.BackgroundTransparency = 1
        consoleScroll.Position = UDim2.new(0, 0, 0, 24)
        consoleScroll.Size = UDim2.new(1, 0, 1, -24)
        consoleScroll.ScrollBarThickness = 3
        consoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        consoleScroll.BorderSizePixel = 0

        local consoleLabel = Instance.new("TextLabel")
        consoleLabel.Parent = consoleScroll
        consoleLabel.BackgroundTransparency = 1
        consoleLabel.Size = UDim2.new(1, -16, 0, 0)
        consoleLabel.AutomaticSize = Enum.AutomaticSize.Y
        consoleLabel.Position = UDim2.new(0, 8, 0, 4)
        consoleLabel.Font = Enum.Font.Code
        consoleLabel.Text = ""
        consoleLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
        consoleLabel.TextSize = 11
        consoleLabel.TextXAlignment = Enum.TextXAlignment.Left
        consoleLabel.TextYAlignment = Enum.TextYAlignment.Top
        consoleLabel.TextWrapped = true
        consoleLabel.RichText = true

        local function updateDisplay()
            local display = table.concat(lines, "\n")
            consoleLabel.Text = display
            task.defer(function()
                consoleScroll.CanvasSize = UDim2.new(0, 0, 0, consoleLabel.TextBounds.Y + 12)
                consoleScroll.CanvasPosition = Vector2.new(0, math.max(0, consoleLabel.TextBounds.Y - consoleScroll.AbsoluteSize.Y))
            end)
        end

        local typeColors = {
            info = "rgb(180,200,255)",
            success = "rgb(80,200,100)",
            warning = "rgb(255,200,80)",
            error = "rgb(255,80,80)",
            debug = "rgb(160,160,160)",
        }

        local conObj = {}

        function conObj:Log(msg, msgType)
            msgType = msgType or "info"
            local color = typeColors[msgType] or typeColors.info
            local timestamp = os.date("%H:%M:%S")
            local formatted = '<font color="' .. color .. '">[' .. timestamp .. '] ' .. tostring(msg) .. '</font>'
            table.insert(lines, formatted)
            while #lines > maxLines do table.remove(lines, 1) end
            updateDisplay()
        end

        function conObj:Info(msg) conObj:Log(msg, "info") end
        function conObj:Success(msg) conObj:Log(msg, "success") end
        function conObj:Warn(msg) conObj:Log(msg, "warning") end
        function conObj:Error(msg) conObj:Log(msg, "error") end
        function conObj:Debug(msg) conObj:Log(msg, "debug") end

        function conObj:Clear()
            lines = {}
            updateDisplay()
        end

        clearBtn.MouseButton1Click:Connect(function() conObj:Clear() end)

        function conObj:GetLines() return lines end
        function conObj:SetVisible(v) frame.Visible = v end
        function conObj:Destroy() frame:Destroy() end
        return conObj
    end
end)

-- Circular Progress
StarLib:RegisterTabExtension("CreateCircularProgress", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local val = cfg2.Default or 0
        local max = cfg2.Max or 100
        local size = cfg2.Size or 80

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, size + 24)
        frame.LayoutOrder = nextOrder()

        local circleFrame = Instance.new("Frame")
        circleFrame.Parent = frame
        circleFrame.BackgroundTransparency = 1
        circleFrame.AnchorPoint = Vector2.new(0.5, 0)
        circleFrame.Position = UDim2.new(0.5, 0, 0, 0)
        circleFrame.Size = UDim2.new(0, size, 0, size)

        local bgCircle = Instance.new("Frame")
        bgCircle.Parent = circleFrame
        bgCircle.BackgroundColor3 = T.SliderTrack
        bgCircle.Size = UDim2.new(1, 0, 1, 0)
        bgCircle.BorderSizePixel = 0
        Instance.new("UICorner", bgCircle).CornerRadius = UDim.new(1, 0)

        local innerCircle = Instance.new("Frame")
        innerCircle.Parent = circleFrame
        innerCircle.BackgroundColor3 = T.ElementBG
        innerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
        innerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
        innerCircle.Size = UDim2.new(1, -12, 1, -12)
        innerCircle.BorderSizePixel = 0
        Instance.new("UICorner", innerCircle).CornerRadius = UDim.new(1, 0)

        local percentLabel = Instance.new("TextLabel")
        percentLabel.Parent = innerCircle
        percentLabel.BackgroundTransparency = 1
        percentLabel.Size = UDim2.new(1, 0, 1, 0)
        percentLabel.Font = T.FontBold
        percentLabel.Text = math.floor(val / max * 100) .. "%"
        percentLabel.TextColor3 = T.TextPrimary
        percentLabel.TextSize = math.floor(size / 4.5)

        local nameLabel = nil
        if cfg2.Name then
            nameLabel = Instance.new("TextLabel")
            nameLabel.Parent = frame
            nameLabel.BackgroundTransparency = 1
            nameLabel.Position = UDim2.new(0, 0, 0, size + 4)
            nameLabel.Size = UDim2.new(1, 0, 0, 18)
            nameLabel.Font = T.FontLight
            nameLabel.Text = cfg2.Name
            nameLabel.TextColor3 = T.TextMuted
            nameLabel.TextSize = T.SmallTextSize
        end

        local segments = 12
        local segAngle = 360 / segments

        local segFrames = {}
        for i = 1, segments do
            local seg = Instance.new("Frame")
            seg.Parent = circleFrame
            seg.BackgroundColor3 = T.SliderTrack
            seg.AnchorPoint = Vector2.new(0.5, 1)
            seg.Position = UDim2.new(0.5, 0, 0.5, 0)
            seg.Size = UDim2.new(0, 6, 0.5, -2)
            seg.Rotation = (i - 1) * segAngle
            seg.BorderSizePixel = 0
            seg.ZIndex = 0
            seg.Visible = false
            segFrames[i] = seg
        end

        local function updateVisual()
            local pct = clamp(val / max, 0, 1)
            percentLabel.Text = math.floor(pct * 100) .. "%"
            bgCircle.BackgroundColor3 = lerpColor3(T.SliderTrack, cfg2.Color or T.Accent, pct)
        end

        updateVisual()

        local cpObj = { _type = "circularprogress" }
        function cpObj:Set(v) val = clamp(v, 0, max); updateVisual() end
        function cpObj:Get() return val end
        function cpObj:Animate(target, dur)
            local startVal = val
            task.spawn(function()
                local startTime = tick()
                while true do
                    local elapsed = tick() - startTime
                    local progress = clamp(elapsed / (dur or 1), 0, 1)
                    cpObj:Set(lerp(startVal, target, Easing.QuintOut(progress)))
                    if progress >= 1 then break end
                    task.wait(0.016)
                end
            end)
        end
        function cpObj:SetVisible(v) frame.Visible = v end
        function cpObj:Destroy() frame:Destroy() end
        return cpObj
    end
end)

-- Calendar / Date Picker
StarLib:RegisterTabExtension("CreateDatePicker", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local now = os.date("*t")
        local selectedYear = cfg2.DefaultYear or now.year
        local selectedMonth = cfg2.DefaultMonth or now.month
        local selectedDay = cfg2.DefaultDay or now.day

        local monthNames = {"January", "February", "March", "April", "May", "June",
                           "July", "August", "September", "October", "November", "December"}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
        frame.ClipsDescendants = true
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local dateBtn = Instance.new("TextButton")
        dateBtn.Parent = frame
        dateBtn.BackgroundTransparency = 1
        dateBtn.Size = UDim2.new(1, 0, 0, T.ElementHeight)
        dateBtn.Font = T.Font
        dateBtn.Text = string.format("  %s: %s %d, %d", cfg2.Name or "Date", monthNames[selectedMonth], selectedDay, selectedYear)
        dateBtn.TextColor3 = T.TextPrimary
        dateBtn.TextSize = T.TextSize
        dateBtn.TextXAlignment = Enum.TextXAlignment.Left
        dateBtn.AutoButtonColor = false
        dateBtn.BorderSizePixel = 0

        local calendarFrame = Instance.new("Frame")
        calendarFrame.Parent = frame
        calendarFrame.BackgroundColor3 = T.ElementBG
        calendarFrame.Position = UDim2.new(0, 0, 0, T.ElementHeight)
        calendarFrame.Size = UDim2.new(1, 0, 0, 240)
        calendarFrame.BorderSizePixel = 0

        local calOpen = false

        local function daysInMonth(month, year)
            local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
            if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
                return 29
            end
            return days[month]
        end

        local function firstDayOfMonth(month, year)
            local t = os.time({year = year, month = month, day = 1})
            return tonumber(os.date("%w", t))
        end

        local function buildCalendar()
            for _, ch in ipairs(calendarFrame:GetChildren()) do ch:Destroy() end

            local navFrame = Instance.new("Frame")
            navFrame.Parent = calendarFrame
            navFrame.BackgroundTransparency = 1
            navFrame.Size = UDim2.new(1, 0, 0, 28)

            local prevMonthBtn = Instance.new("TextButton")
            prevMonthBtn.Parent = navFrame
            prevMonthBtn.BackgroundTransparency = 1
            prevMonthBtn.Size = UDim2.new(0, 30, 1, 0)
            prevMonthBtn.Font = T.FontBold
            prevMonthBtn.Text = "‹"
            prevMonthBtn.TextColor3 = T.TextPrimary
            prevMonthBtn.TextSize = 18

            local monthLabel = Instance.new("TextLabel")
            monthLabel.Parent = navFrame
            monthLabel.BackgroundTransparency = 1
            monthLabel.Position = UDim2.new(0, 30, 0, 0)
            monthLabel.Size = UDim2.new(1, -60, 1, 0)
            monthLabel.Font = T.FontBold
            monthLabel.Text = monthNames[selectedMonth] .. " " .. selectedYear
            monthLabel.TextColor3 = T.TextPrimary
            monthLabel.TextSize = T.SmallTextSize

            local nextMonthBtn = Instance.new("TextButton")
            nextMonthBtn.Parent = navFrame
            nextMonthBtn.BackgroundTransparency = 1
            nextMonthBtn.Position = UDim2.new(1, -30, 0, 0)
            nextMonthBtn.Size = UDim2.new(0, 30, 1, 0)
            nextMonthBtn.Font = T.FontBold
            nextMonthBtn.Text = "›"
            nextMonthBtn.TextColor3 = T.TextPrimary
            nextMonthBtn.TextSize = 18

            prevMonthBtn.MouseButton1Click:Connect(function()
                selectedMonth = selectedMonth - 1
                if selectedMonth < 1 then selectedMonth = 12; selectedYear = selectedYear - 1 end
                buildCalendar()
            end)
            nextMonthBtn.MouseButton1Click:Connect(function()
                selectedMonth = selectedMonth + 1
                if selectedMonth > 12 then selectedMonth = 1; selectedYear = selectedYear + 1 end
                buildCalendar()
            end)

            local dayHeaders = {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}
            local headerFrame = Instance.new("Frame")
            headerFrame.Parent = calendarFrame
            headerFrame.BackgroundTransparency = 1
            headerFrame.Position = UDim2.new(0, 0, 0, 28)
            headerFrame.Size = UDim2.new(1, 0, 0, 20)

            for i, dh in ipairs(dayHeaders) do
                local dhLabel = Instance.new("TextLabel")
                dhLabel.Parent = headerFrame
                dhLabel.BackgroundTransparency = 1
                dhLabel.Position = UDim2.new((i-1)/7, 0, 0, 0)
                dhLabel.Size = UDim2.new(1/7, 0, 1, 0)
                dhLabel.Font = T.FontBold
                dhLabel.Text = dh
                dhLabel.TextColor3 = T.TextMuted
                dhLabel.TextSize = T.TinyTextSize
            end

            local totalDays = daysInMonth(selectedMonth, selectedYear)
            local startDay = firstDayOfMonth(selectedMonth, selectedYear)

            local gridFrame = Instance.new("Frame")
            gridFrame.Parent = calendarFrame
            gridFrame.BackgroundTransparency = 1
            gridFrame.Position = UDim2.new(0, 4, 0, 50)
            gridFrame.Size = UDim2.new(1, -8, 0, 180)

            local cellW = 1 / 7
            local cellH = 28
            local row = 0
            local col = startDay

            for day = 1, totalDays do
                local isSelected = day == selectedDay
                local isToday = day == now.day and selectedMonth == now.month and selectedYear == now.year

                local dayBtn = Instance.new("TextButton")
                dayBtn.Parent = gridFrame
                dayBtn.Position = UDim2.new(col * cellW, 2, 0, row * cellH)
                dayBtn.Size = UDim2.new(cellW, -4, 0, cellH - 4)
                dayBtn.Font = isToday and T.FontBold or T.FontLight
                dayBtn.Text = tostring(day)
                dayBtn.TextSize = T.SmallTextSize
                dayBtn.AutoButtonColor = false
                dayBtn.BorderSizePixel = 0

                if isSelected then
                    dayBtn.BackgroundColor3 = T.Accent
                    dayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                elseif isToday then
                    dayBtn.BackgroundColor3 = T.ElementHover
                    dayBtn.TextColor3 = T.Accent
                else
                    dayBtn.BackgroundTransparency = 1
                    dayBtn.TextColor3 = T.TextSecondary
                end
                Instance.new("UICorner", dayBtn).CornerRadius = UDim.new(0, 4)

                dayBtn.MouseButton1Click:Connect(function()
                    selectedDay = day
                    dateBtn.Text = string.format("  %s: %s %d, %d", cfg2.Name or "Date", monthNames[selectedMonth], selectedDay, selectedYear)
                    buildCalendar()
                    if cfg2.Callback then
                        safeCallback(cfg2.Callback, {
                            Year = selectedYear,
                            Month = selectedMonth,
                            Day = selectedDay,
                        })
                    end
                end)

                col = col + 1
                if col >= 7 then col = 0; row = row + 1 end
            end
        end

        buildCalendar()

        dateBtn.MouseButton1Click:Connect(function()
            calOpen = not calOpen
            if calOpen then
                frame.Size = UDim2.new(1, 0, 0, T.ElementHeight + 240)
            else
                frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
            end
        end)

        local dpObj = {}
        function dpObj:GetDate() return { Year = selectedYear, Month = selectedMonth, Day = selectedDay } end
        function dpObj:SetDate(y, m, d) selectedYear = y; selectedMonth = m; selectedDay = d; buildCalendar()
            dateBtn.Text = string.format("  %s: %s %d, %d", cfg2.Name or "Date", monthNames[selectedMonth], selectedDay, selectedYear)
        end
        function dpObj:SetVisible(v) frame.Visible = v end
        function dpObj:Destroy() frame:Destroy() end
        return dpObj
    end
end)

-- =========================================================================
-- SECTION 20: KEYBOARD NAVIGATION SYSTEM
-- =========================================================================

function StarLib:EnableKeyboardNav(window, config)
    config = config or {}
    local focusIndex = 0
    local focusable = {}

    local function collectFocusable()
        focusable = {}
        for _, tabName in ipairs(window._tabOrder) do
            local tab = window.Tabs[tabName]
            if tab and tab.Container.Visible then
                for _, child in ipairs(tab.Container:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") then
                        table.insert(focusable, child)
                    end
                end
            end
        end
    end

    local focusHighlight = Instance.new("UIStroke")
    focusHighlight.Color = window.Theme.Accent
    focusHighlight.Thickness = 2
    focusHighlight.Transparency = 1

    local function setFocus(idx)
        if focusHighlight.Parent then
            focusHighlight.Parent = nil
        end
        focusIndex = idx
        if focusIndex >= 1 and focusIndex <= #focusable then
            local target = focusable[focusIndex]
            focusHighlight.Parent = target
            focusHighlight.Transparency = 0
        end
    end

    local conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            collectFocusable()
            if #focusable == 0 then return end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                focusIndex = focusIndex - 1
                if focusIndex < 1 then focusIndex = #focusable end
            else
                focusIndex = focusIndex + 1
                if focusIndex > #focusable then focusIndex = 1 end
            end
            setFocus(focusIndex)
        elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
            if focusIndex >= 1 and focusIndex <= #focusable then
                local target = focusable[focusIndex]
                if target:IsA("TextButton") then
                    pcall(function() target.MouseButton1Click:Fire() end)
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            focusHighlight.Transparency = 1
            focusIndex = 0
        end
    end)

    table.insert(window._connections, conn)
end

-- =========================================================================
-- SECTION 21: CONFIG PROFILES
-- =========================================================================

function StarLib:CreateConfigManager(config)
    config = config or {}
    local folder = config.Folder or "StarLib"
    local prefix = config.Prefix or "config_"

    local mgr = {}

    local function ensureFolder()
        pcall(function()
            if isfolder and not isfolder(folder) then makefolder(folder) end
        end)
    end

    function mgr:SaveProfile(name, window)
        ensureFolder()
        pcall(function()
            if writefile then
                local state = window:ExportState()
                local json = HttpService:JSONEncode(state)
                writefile(folder .. "/" .. prefix .. name .. ".json", json)
                debugLog("Config saved: " .. name)
            end
        end)
    end

    function mgr:LoadProfile(name, window)
        pcall(function()
            if readfile and isfile then
                local path = folder .. "/" .. prefix .. name .. ".json"
                if isfile(path) then
                    local json = readfile(path)
                    local state = HttpService:JSONDecode(json)
                    window:ImportState(state)
                    debugLog("Config loaded: " .. name)
                end
            end
        end)
    end

    function mgr:DeleteProfile(name)
        pcall(function()
            if delfile and isfile then
                local path = folder .. "/" .. prefix .. name .. ".json"
                if isfile(path) then
                    delfile(path)
                    debugLog("Config deleted: " .. name)
                end
            end
        end)
    end

    function mgr:ListProfiles()
        local profiles = {}
        pcall(function()
            if listfiles then
                local files = listfiles(folder)
                for _, file in ipairs(files) do
                    local name = file:match(prefix .. "(.+)%.json$")
                    if name then table.insert(profiles, name) end
                end
            end
        end)
        return profiles
    end

    return mgr
end

-- =========================================================================
-- SECTION 22: THEME BUILDER
-- =========================================================================

function StarLib:BuildTheme(config)
    local base = config.Base and THEME_PRESETS[config.Base] or {}
    local theme = deepCopy(DEFAULT_THEME)
    for k, v in pairs(base) do theme[k] = v end

    if config.Accent then
        theme.Accent = config.Accent
        theme.AccentDark = darkenColor(config.Accent, 0.15)
        theme.AccentLight = lightenColor(config.Accent, 0.15)
        theme.InputFocus = config.Accent
        theme.Info = config.Accent
    end

    if config.Background then
        theme.Background = config.Background
        theme.TopBar = lightenColor(config.Background, 0.025)
        theme.Sidebar = lightenColor(config.Background, 0.025)
        theme.TabDefault = lightenColor(config.Background, 0.06)
        theme.TabActive = lightenColor(config.Background, 0.14)
        theme.TabHover = lightenColor(config.Background, 0.1)
        theme.ElementBG = lightenColor(config.Background, 0.06)
        theme.ElementHover = lightenColor(config.Background, 0.1)
        theme.ElementActive = lightenColor(config.Background, 0.12)
        theme.InputBG = lightenColor(config.Background, 0.02)
        theme.SliderTrack = lightenColor(config.Background, 0.14)
        theme.NotifBG = lightenColor(config.Background, 0.04)
        theme.ContextBG = lightenColor(config.Background, 0.06)
        theme.Divider = lightenColor(config.Background, 0.1)
    end

    if config.CornerRadius then
        theme.CornerRadius = UDim.new(0, config.CornerRadius)
        theme.ElementRadius = UDim.new(0, math.max(config.CornerRadius - 2, 0))
        theme.SmallRadius = UDim.new(0, math.max(config.CornerRadius - 4, 0))
    end

    for k, v in pairs(config) do
        if k ~= "Base" and k ~= "Accent" and k ~= "Background" and k ~= "CornerRadius" then
            theme[k] = v
        end
    end

    return theme
end

-- =========================================================================
-- SECTION 23: EXTENDED GLOBAL UTILITIES
-- =========================================================================

function StarLib:Delay(seconds, fn)
    task.delay(seconds, function()
        safeCallback(fn)
    end)
end

function StarLib:Loop(interval, fn)
    local running = true
    task.spawn(function()
        while running do
            task.wait(interval)
            if not running then break end
            local result = fn()
            if result == false then running = false end
        end
    end)
    return {
        Stop = function() running = false end,
        IsRunning = function() return running end,
    }
end

function StarLib:Throttle(fn, cooldown)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= cooldown then
            lastCall = now
            return fn(...)
        end
    end
end

function StarLib:Debounce(fn, delay)
    local timer = nil
    return function(...)
        local args = {...}
        if timer then pcall(function() task.cancel(timer) end) end
        timer = task.delay(delay, function()
            fn(unpack(args))
        end)
    end
end

function StarLib:Chain(...)
    local fns = {...}
    return function(...)
        local result = {...}
        for _, fn in ipairs(fns) do
            result = {fn(unpack(result))}
        end
        return unpack(result)
    end
end

-- =========================================================================
-- SECTION 24: PERFORMANCE MONITOR
-- =========================================================================

function StarLib:CreatePerformanceMonitor(config)
    config = config or {}
    local pmGui = Instance.new("ScreenGui")
    pmGui.Name = "StarLib_PerfMon"
    pmGui.DisplayOrder = 95
    protectGui(pmGui)

    local pmFrame = Instance.new("Frame")
    pmFrame.Parent = pmGui
    pmFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    pmFrame.BackgroundTransparency = 0.2
    pmFrame.Position = config.Position or UDim2.new(0, 10, 0, 10)
    pmFrame.Size = UDim2.new(0, 180, 0, 90)
    pmFrame.BorderSizePixel = 0
    Instance.new("UICorner", pmFrame).CornerRadius = UDim.new(0, 6)

    MakeDraggable(pmFrame, pmFrame, 0.1)

    local pad = Instance.new("UIPadding", pmFrame)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 6)

    local layout = Instance.new("UIListLayout", pmFrame)
    layout.Padding = UDim.new(0, 2)

    local labels = {}
    local function addLine(name)
        local lbl = Instance.new("TextLabel")
        lbl.Parent = pmFrame
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, -8, 0, 14)
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(200, 255, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = name .. ": --"
        labels[name] = lbl
        return lbl
    end

    addLine("FPS")
    addLine("Ping")
    addLine("Memory")
    addLine("Instances")
    addLine("Heartbeat")

    local frameCount = 0
    local lastTime = tick()

    local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        frameCount = frameCount + 1
        local now = tick()
        if now - lastTime >= 0.5 then
            local fps = math.floor(frameCount / (now - lastTime))
            labels["FPS"].Text = "FPS: " .. fps
            if fps >= 55 then labels["FPS"].TextColor3 = Color3.fromRGB(100, 255, 100)
            elseif fps >= 30 then labels["FPS"].TextColor3 = Color3.fromRGB(255, 255, 100)
            else labels["FPS"].TextColor3 = Color3.fromRGB(255, 100, 100) end

            pcall(function()
                local stats = game:GetService("Stats")
                local ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                labels["Ping"].Text = "Ping: " .. ping .. "ms"
            end)

            pcall(function()
                local mem = math.floor(collectgarbage("count") / 1024 * 10) / 10
                labels["Memory"].Text = "Memory: " .. mem .. " MB"
            end)

            pcall(function()
                labels["Heartbeat"].Text = "dT: " .. string.format("%.1f", dt * 1000) .. "ms"
            end)

            pcall(function()
                labels["Instances"].Text = "Windows: " .. #StarLib.Windows
            end)

            frameCount = 0
            lastTime = now
        end
    end)

    local pmObj = {}
    function pmObj:Show() pmGui.Enabled = true end
    function pmObj:Hide() pmGui.Enabled = false end
    function pmObj:Toggle() pmGui.Enabled = not pmGui.Enabled end
    function pmObj:Destroy() heartbeatConn:Disconnect(); pmGui:Destroy() end
    return pmObj
end

-- =========================================================================
-- SECTION 25: QUICK ACTIONS API
-- =========================================================================

function StarLib:QuickToggle(config)
    local state = config.Default or false
    local T = mergeTable(DEFAULT_THEME, config.Theme or {})

    local gui = Instance.new("ScreenGui")
    gui.Name = "StarLib_QuickToggle_" .. generateId()
    gui.DisplayOrder = 40
    protectGui(gui)

    local btn = Instance.new("TextButton")
    btn.Parent = gui
    btn.BackgroundColor3 = state and T.Accent or T.ElementBG
    btn.Position = config.Position or UDim2.new(0, 10, 0.5, -20)
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Font = T.FontBold
    btn.Text = config.Icon or "⚡"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 18
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    MakeDraggable(btn, btn, 0.1)

    if config.Tooltip then attachTooltip(btn, config.Tooltip) end

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = state and T.Accent or T.ElementBG
        }):Play()
        if config.Callback then safeCallback(config.Callback, state) end
    end)

    local obj = {}
    function obj:Get() return state end
    function obj:Set(v)
        state = v
        btn.BackgroundColor3 = state and T.Accent or T.ElementBG
    end
    function obj:Destroy() gui:Destroy() end
    return obj
end

-- =========================================================================
-- SECTION 26: RUNTIME EXTENSION HOOK
-- =========================================================================

local originalCreateTab = nil

local _originalCreateWindow = StarLib.CreateWindow
function StarLib:CreateWindow(config)
    local W = _originalCreateWindow(self, config)
    
    local _originalCreateTab = W.CreateTab
    function W:CreateTab(name, cfg)
        local Tab = _originalCreateTab(self, name, cfg)
        
        for extName, extConstructor in pairs(_tabExtensions) do
            local constructor = extConstructor(Tab, Tab.Container, W.Theme, W, function()
                Tab._layoutOrder = Tab._layoutOrder + 1
                return Tab._layoutOrder
            end)
            Tab[extName] = constructor
        end
        
        return Tab
    end
    
    return W
end

-- =========================================================================
-- SECTION 27: DEBUG & PERFORMANCE
-- =========================================================================

function StarLib:GetDebugLog()
    return self._debugLog
end

function StarLib:ClearDebugLog()
    self._debugLog = {}
end

function StarLib:PrintDebugLog()
    for _, entry in ipairs(self._debugLog) do
        print(entry)
    end
end

function StarLib:Benchmark(name, fn)
    local start = tick()
    fn()
    local elapsed = (tick() - start) * 1000
    debugLog(name .. " took " .. string.format("%.2f", elapsed) .. "ms")
    return elapsed
end

-- =========================================================================
-- SECTION 28: FORM BUILDER
-- =========================================================================

function StarLib:CreateForm(tab, config)
    config = config or {}
    local fields = config.Fields or {}
    local formValues = {}
    local fieldObjects = {}
    local validationErrors = {}

    if config.Title then
        tab:CreateSection(config.Title)
    end

    for _, field in ipairs(fields) do
        local fType = field.Type or "input"
        formValues[field.Name] = field.Default

        if fType == "input" or fType == "text" then
            local obj = tab:CreateInput({
                Name = field.Label or field.Name,
                PlaceholderText = field.Placeholder or "",
                Default = field.Default or "",
                Callback = function(val)
                    formValues[field.Name] = val
                    if field.Validate then
                        local ok, err = field.Validate(val)
                        validationErrors[field.Name] = ok and nil or err
                    end
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "number" then
            local obj = tab:CreateNumberInput({
                Name = field.Label or field.Name,
                Default = field.Default or 0,
                Min = field.Min or 0,
                Max = field.Max or 999999,
                Step = field.Step or 1,
                Suffix = field.Suffix or "",
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "toggle" or fType == "boolean" then
            local obj = tab:CreateToggle({
                Name = field.Label or field.Name,
                CurrentValue = field.Default or false,
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "slider" then
            local obj = tab:CreateSlider({
                Name = field.Label or field.Name,
                Range = field.Range or {0, 100},
                Increment = field.Increment or 1,
                CurrentValue = field.Default or 0,
                Suffix = field.Suffix or "",
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "dropdown" or fType == "select" then
            local obj = tab:CreateDropdown({
                Name = field.Label or field.Name,
                Options = field.Options or {},
                Default = field.Default or "",
                Searchable = field.Searchable,
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "radio" then
            local obj = tab:CreateRadioGroup({
                Name = field.Label or field.Name,
                Options = field.Options or {},
                Default = field.Default,
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "color" then
            local obj = tab:CreateColorPicker({
                Name = field.Label or field.Name,
                Default = field.Default or Color3.fromRGB(255, 255, 255),
                LivePreview = field.LivePreview,
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj

        elseif fType == "date" then
            local obj = tab:CreateDatePicker({
                Name = field.Label or field.Name,
                Callback = function(val)
                    formValues[field.Name] = val
                end,
            })
            fieldObjects[field.Name] = obj
        end
    end

    if config.SubmitButton ~= false then
        tab:CreateSpacer({ Height = 8 })
        tab:CreateButton({
            Name = config.SubmitText or "Submit",
            Callback = function()
                local hasErrors = false
                for name, err in pairs(validationErrors) do
                    if err then hasErrors = true; break end
                end
                if hasErrors and config.OnValidationError then
                    safeCallback(config.OnValidationError, validationErrors)
                    return
                end
                if config.OnSubmit then
                    safeCallback(config.OnSubmit, deepCopy(formValues))
                end
            end,
        })
    end

    local form = {}
    function form:GetValues() return deepCopy(formValues) end
    function form:GetValue(name) return formValues[name] end
    function form:SetValue(name, val)
        formValues[name] = val
        if fieldObjects[name] and fieldObjects[name].Set then
            fieldObjects[name]:Set(val)
        end
    end
    function form:GetErrors() return validationErrors end
    function form:Reset()
        for _, field in ipairs(fields) do
            formValues[field.Name] = field.Default
            if fieldObjects[field.Name] and fieldObjects[field.Name].Set then
                fieldObjects[field.Name]:Set(field.Default or "")
            end
        end
    end
    return form
end

-- =========================================================================
-- SECTION 29: VALIDATION HELPERS
-- =========================================================================

StarLib.Validate = {}

function StarLib.Validate.required(val)
    if val == nil or val == "" then
        return false, "This field is required"
    end
    return true
end

function StarLib.Validate.minLength(min)
    return function(val)
        if type(val) ~= "string" or #val < min then
            return false, "Must be at least " .. min .. " characters"
        end
        return true
    end
end

function StarLib.Validate.maxLength(max)
    return function(val)
        if type(val) ~= "string" or #val > max then
            return false, "Must be at most " .. max .. " characters"
        end
        return true
    end
end

function StarLib.Validate.pattern(pat, msg)
    return function(val)
        if type(val) ~= "string" or not val:match(pat) then
            return false, msg or "Invalid format"
        end
        return true
    end
end

function StarLib.Validate.range(min, max)
    return function(val)
        local num = tonumber(val)
        if not num or num < min or num > max then
            return false, "Must be between " .. min .. " and " .. max
        end
        return true
    end
end

function StarLib.Validate.oneOf(options)
    return function(val)
        for _, opt in ipairs(options) do
            if val == opt then return true end
        end
        return false, "Must be one of: " .. table.concat(options, ", ")
    end
end

function StarLib.Validate.compose(...)
    local validators = {...}
    return function(val)
        for _, validator in ipairs(validators) do
            local ok, err = validator(val)
            if not ok then return false, err end
        end
        return true
    end
end

-- =========================================================================
-- SECTION 30: ICON LIBRARY
-- =========================================================================

StarLib.Icons = {
    Home = "🏠",
    Settings = "⚙",
    User = "👤",
    Users = "👥",
    Search = "🔍",
    Star = "⭐",
    Heart = "❤",
    Bell = "🔔",
    Lock = "🔒",
    Unlock = "🔓",
    Check = "✓",
    Cross = "✗",
    Plus = "+",
    Minus = "−",
    Arrow = {
        Up = "▲",
        Down = "▼",
        Left = "◄",
        Right = "►",
    },
    Warning = "⚠",
    Info = "ℹ",
    Error = "✗",
    Success = "✓",
    Edit = "✎",
    Delete = "🗑",
    Save = "💾",
    Copy = "📋",
    Folder = "📁",
    File = "📄",
    Download = "⬇",
    Upload = "⬆",
    Refresh = "↻",
    Power = "⏻",
    Play = "▶",
    Pause = "⏸",
    Stop = "⏹",
    Skip = "⏭",
    Rewind = "⏮",
    Eye = "👁",
    EyeOff = "🙈",
    Link = "🔗",
    Unlink = "🔗",
    Clock = "🕐",
    Calendar = "📅",
    Map = "🗺",
    Pin = "📌",
    Flag = "🚩",
    Bookmark = "🔖",
    Tag = "🏷",
    Gift = "🎁",
    Trophy = "🏆",
    Zap = "⚡",
    Shield = "🛡",
    Sword = "⚔",
    Fire = "🔥",
    Snow = "❄",
    Sun = "☀",
    Moon = "🌙",
    Cloud = "☁",
    Thunder = "⛈",
    Rocket = "🚀",
    Car = "🚗",
    Plane = "✈",
    Ship = "🚢",
    Phone = "📱",
    Monitor = "🖥",
    Keyboard = "⌨",
    Mouse = "🖱",
    Gamepad = "🎮",
    Music = "🎵",
    Camera = "📷",
    Terminal = ">_",
    Code = "</>",
    Bug = "🐛",
    Wrench = "🔧",
    Hammer = "🔨",
    Gem = "💎",
    Crown = "👑",
    Skull = "💀",
    Ghost = "👻",
    Robot = "🤖",
    Alien = "👾",
    Cat = "🐱",
    Dog = "🐶",
    Tree = "🌳",
    Mountain = "⛰",
    Wave = "🌊",
    Sparkles = "✨",
    Rainbow = "🌈",
}

-- =========================================================================
-- SECTION 31: PRESET WINDOW TEMPLATES
-- =========================================================================

function StarLib:CreateSettingsWindow(config)
    config = config or {}
    config.Name = config.Name or "Settings"
    config.ThemePreset = config.ThemePreset or "Dark"

    local Window = self:CreateWindow(config)
    
    local generalTab = Window:CreateTab("General", { Icon = StarLib.Icons.Settings })
    local themeTab = Window:CreateTab("Theme", { Icon = StarLib.Icons.Edit })
    local aboutTab = Window:CreateTab("About", { Icon = StarLib.Icons.Info })

    generalTab:CreateSection("Application")

    if config.GeneralSettings then
        for _, setting in ipairs(config.GeneralSettings) do
            if setting.Type == "toggle" then
                generalTab:CreateToggle({
                    Name = setting.Name,
                    CurrentValue = setting.Default,
                    Callback = setting.Callback,
                })
            elseif setting.Type == "slider" then
                generalTab:CreateSlider({
                    Name = setting.Name,
                    Range = setting.Range or {0, 100},
                    CurrentValue = setting.Default,
                    Increment = setting.Increment or 1,
                    Suffix = setting.Suffix or "",
                    Callback = setting.Callback,
                })
            elseif setting.Type == "dropdown" then
                generalTab:CreateDropdown({
                    Name = setting.Name,
                    Options = setting.Options,
                    Default = setting.Default,
                    Callback = setting.Callback,
                })
            end
        end
    end

    themeTab:CreateSection("Theme Selection")
    themeTab:CreateDropdown({
        Name = "Preset",
        Options = tableKeys(THEME_PRESETS),
        Default = config.ThemePreset or "Dark",
        Searchable = true,
        Callback = function(preset)
            Window:ApplyPreset(preset)
            if config.OnThemeChanged then
                safeCallback(config.OnThemeChanged, preset)
            end
        end,
    })

    themeTab:CreateSection("Custom Colors")
    themeTab:CreateColorPicker({
        Name = "Accent Color",
        Default = config.Theme and config.Theme.Accent or DEFAULT_THEME.Accent,
        LivePreview = true,
        Callback = function(color)
            Window:SetAccent(color)
        end,
    })

    aboutTab:CreateSection("Information")
    aboutTab:CreateParagraph({
        Title = config.Name or "Application",
        Content = config.Description or "Built with StarLib v" .. STARLIB_VERSION,
    })
    aboutTab:CreateLabel("Version: " .. (config.AppVersion or "1.0.0"))
    aboutTab:CreateLabel("StarLib: v" .. STARLIB_VERSION)
    aboutTab:CreateLabel("Build: " .. STARLIB_BUILD)

    if config.Credits then
        aboutTab:CreateSection("Credits")
        aboutTab:CreateParagraph({
            Title = "Credits",
            Content = config.Credits,
        })
    end

    if config.Changelog then
        aboutTab:CreateSection("Changelog")
        for _, entry in ipairs(config.Changelog) do
            aboutTab:CreateParagraph({
                Title = entry.Version or "",
                Content = entry.Changes or "",
            })
        end
    end

    return Window
end

-- =========================================================================
-- SECTION 32: QUICK MENU BUILDER
-- =========================================================================

function StarLib:CreateQuickMenu(config)
    config = config or {}
    local items = config.Items or {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "StarLib_QuickMenu_" .. generateId()
    gui.DisplayOrder = 85
    protectGui(gui)

    local T = mergeTable(DEFAULT_THEME, config.Theme or {})

    local frame = Instance.new("Frame")
    frame.Parent = gui
    frame.BackgroundColor3 = T.ElementBG
    frame.Position = config.Position or UDim2.new(0.5, -100, 0.5, -150)
    frame.Size = UDim2.new(0, 200, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = true
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = T.CornerRadius

    MakeDraggable(frame, frame, 0.15)

    local pad = Instance.new("UIPadding", frame)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 4)

    if config.Title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = frame
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, 0, 0, 22)
        titleLabel.Font = T.FontBold
        titleLabel.Text = config.Title
        titleLabel.TextColor3 = T.TextPrimary
        titleLabel.TextSize = T.TextSize
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    for _, item in ipairs(items) do
        if item.Separator then
            local sep = Instance.new("Frame")
            sep.Parent = frame
            sep.BackgroundColor3 = T.Divider
            sep.Size = UDim2.new(1, 0, 0, 1)
            sep.BorderSizePixel = 0
        else
            local btn = Instance.new("TextButton")
            btn.Parent = frame
            btn.BackgroundColor3 = item.Color or T.ElementBG
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Font = T.Font
            btn.Text = (item.Icon and (item.Icon .. "  ") or "") .. (item.Name or "")
            btn.TextColor3 = T.TextPrimary
            btn.TextSize = T.SmallTextSize
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = T.ElementRadius

            local btnPad = Instance.new("UIPadding", btn)
            btnPad.PaddingLeft = UDim.new(0, 8)

            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = T.ElementHover }):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = item.Color or T.ElementBG }):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                if item.Callback then safeCallback(item.Callback) end
            end)
        end
    end

    if config.ToggleKey then
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == config.ToggleKey then
                gui.Enabled = not gui.Enabled
            end
        end)
    end

    local obj = {}
    function obj:Show() gui.Enabled = true end
    function obj:Hide() gui.Enabled = false end
    function obj:Toggle() gui.Enabled = not gui.Enabled end
    function obj:Destroy() gui:Destroy() end
    return obj
end

-- =========================================================================
-- SECTION 33: TAB SEARCH WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateSearch", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local searchFrame = Instance.new("Frame")
        searchFrame.Parent = container
        searchFrame.BackgroundColor3 = T.InputBG
        searchFrame.Size = UDim2.new(1, 0, 0, 34)
        searchFrame.LayoutOrder = nextOrder()
        searchFrame.BorderSizePixel = 0
        Instance.new("UICorner", searchFrame).CornerRadius = T.ElementRadius

        local searchIcon = Instance.new("TextLabel")
        searchIcon.Parent = searchFrame
        searchIcon.BackgroundTransparency = 1
        searchIcon.Position = UDim2.new(0, 10, 0, 0)
        searchIcon.Size = UDim2.new(0, 20, 1, 0)
        searchIcon.Font = T.FontLight
        searchIcon.Text = "🔍"
        searchIcon.TextColor3 = T.TextMuted
        searchIcon.TextSize = 14

        local searchStroke = Instance.new("UIStroke")
        searchStroke.Parent = searchFrame
        searchStroke.Color = T.InputBorder
        searchStroke.Thickness = 1

        local searchBox = Instance.new("TextBox")
        searchBox.Parent = searchFrame
        searchBox.BackgroundTransparency = 1
        searchBox.Position = UDim2.new(0, 32, 0, 0)
        searchBox.Size = UDim2.new(1, -42, 1, 0)
        searchBox.Font = T.FontLight
        searchBox.PlaceholderText = cfg2.Placeholder or "Search..."
        searchBox.Text = ""
        searchBox.TextColor3 = T.TextPrimary
        searchBox.PlaceholderColor3 = T.TextMuted
        searchBox.TextSize = T.TextSize
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = Enum.TextXAlignment.Left

        local resultsFrame = Instance.new("Frame")
        resultsFrame.Parent = container
        resultsFrame.BackgroundTransparency = 1
        resultsFrame.Size = UDim2.new(1, 0, 0, 0)
        resultsFrame.AutomaticSize = Enum.AutomaticSize.Y
        resultsFrame.LayoutOrder = nextOrder()
        resultsFrame.ClipsDescendants = true

        local resultsLayout = Instance.new("UIListLayout", resultsFrame)
        resultsLayout.Padding = UDim.new(0, 2)

        searchBox.Focused:Connect(function()
            TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = T.Accent }):Play()
        end)
        searchBox.FocusLost:Connect(function()
            TweenService:Create(searchStroke, TweenInfo.new(0.15), { Color = T.InputBorder }):Play()
        end)

        local searchItems = cfg2.Items or {}

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local filter = searchBox.Text:lower()
            for _, ch in ipairs(resultsFrame:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end

            if filter == "" then return end

            local count = 0
            for _, item in ipairs(searchItems) do
                if item.Name:lower():find(filter, 1, true) then
                    count = count + 1
                    if count > 8 then break end

                    local resultBtn = Instance.new("TextButton")
                    resultBtn.Parent = resultsFrame
                    resultBtn.BackgroundColor3 = T.ElementBG
                    resultBtn.Size = UDim2.new(1, 0, 0, 30)
                    resultBtn.Font = T.FontLight
                    resultBtn.Text = "  " .. item.Name
                    resultBtn.TextColor3 = T.TextPrimary
                    resultBtn.TextSize = T.SmallTextSize
                    resultBtn.TextXAlignment = Enum.TextXAlignment.Left
                    resultBtn.AutoButtonColor = false
                    resultBtn.BorderSizePixel = 0
                    Instance.new("UICorner", resultBtn).CornerRadius = T.SmallRadius

                    resultBtn.MouseEnter:Connect(function()
                        resultBtn.BackgroundColor3 = T.ElementHover
                    end)
                    resultBtn.MouseLeave:Connect(function()
                        resultBtn.BackgroundColor3 = T.ElementBG
                    end)
                    resultBtn.MouseButton1Click:Connect(function()
                        searchBox.Text = ""
                        for _, ch in ipairs(resultsFrame:GetChildren()) do
                            if ch:IsA("TextButton") then ch:Destroy() end
                        end
                        if item.Callback then safeCallback(item.Callback) end
                    end)
                end
            end
        end)

        local sObj = {}
        function sObj:SetItems(items) searchItems = items end
        function sObj:Clear() searchBox.Text = "" end
        function sObj:Focus() searchBox:CaptureFocus() end
        function sObj:SetVisible(v) searchFrame.Visible = v; resultsFrame.Visible = v end
        function sObj:Destroy() searchFrame:Destroy(); resultsFrame:Destroy() end
        return sObj
    end
end)

-- =========================================================================
-- SECTION 34: INLINE EDITOR WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateInlineEdit", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local value = cfg2.Default or ""
        local editing = false

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = frame
        nameLabel.BackgroundTransparency = 1
        nameLabel.Position = UDim2.new(0, 12, 0, 0)
        nameLabel.Size = UDim2.new(0.35, -12, 1, 0)
        nameLabel.Font = T.Font
        nameLabel.Text = cfg2.Name or "Value"
        nameLabel.TextColor3 = T.TextPrimary
        nameLabel.TextSize = T.TextSize
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local valueDisplay = Instance.new("TextButton")
        valueDisplay.Parent = frame
        valueDisplay.BackgroundTransparency = 1
        valueDisplay.Position = UDim2.new(0.35, 0, 0, 0)
        valueDisplay.Size = UDim2.new(0.55, 0, 1, 0)
        valueDisplay.Font = T.FontLight
        valueDisplay.Text = tostring(value)
        valueDisplay.TextColor3 = T.TextSecondary
        valueDisplay.TextSize = T.SmallTextSize
        valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
        valueDisplay.AutoButtonColor = false
        valueDisplay.BorderSizePixel = 0

        local editIcon = Instance.new("TextLabel")
        editIcon.Parent = frame
        editIcon.BackgroundTransparency = 1
        editIcon.Position = UDim2.new(1, -28, 0, 0)
        editIcon.Size = UDim2.new(0, 20, 1, 0)
        editIcon.Font = T.FontLight
        editIcon.Text = "✎"
        editIcon.TextColor3 = T.TextMuted
        editIcon.TextSize = 14

        local editBox = Instance.new("TextBox")
        editBox.Parent = frame
        editBox.BackgroundColor3 = T.InputBG
        editBox.Position = UDim2.new(0.35, 0, 0.5, -13)
        editBox.Size = UDim2.new(0.55, 0, 0, 26)
        editBox.Font = T.FontLight
        editBox.Text = tostring(value)
        editBox.TextColor3 = T.TextPrimary
        editBox.TextSize = T.SmallTextSize
        editBox.ClearTextOnFocus = false
        editBox.TextXAlignment = Enum.TextXAlignment.Right
        editBox.Visible = false
        editBox.BorderSizePixel = 0
        Instance.new("UICorner", editBox).CornerRadius = UDim.new(0, 4)

        valueDisplay.MouseButton1Click:Connect(function()
            editing = true
            valueDisplay.Visible = false
            editBox.Visible = true
            editBox.Text = tostring(value)
            editBox:CaptureFocus()
        end)

        editBox.FocusLost:Connect(function(enterPressed)
            editing = false
            editBox.Visible = false
            valueDisplay.Visible = true
            if enterPressed then
                value = editBox.Text
                valueDisplay.Text = value
                if cfg2.Callback then safeCallback(cfg2.Callback, value) end
            end
        end)

        local ieObj = {}
        function ieObj:Get() return value end
        function ieObj:Set(v) value = v; valueDisplay.Text = tostring(v) end
        function ieObj:SetVisible(v) frame.Visible = v end
        function ieObj:Destroy() frame:Destroy() end
        return ieObj
    end
end)

-- =========================================================================
-- SECTION 35: TAG INPUT WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateTagInput", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local tags = cfg2.Default or {}
        local maxTags = cfg2.MaxTags or 10

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local pad = Instance.new("UIPadding", frame)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)

        local layout = Instance.new("UIListLayout", frame)
        layout.Padding = UDim.new(0, 6)

        if cfg2.Name then
            local tagTitle = Instance.new("TextLabel")
            tagTitle.Parent = frame
            tagTitle.BackgroundTransparency = 1
            tagTitle.Size = UDim2.new(1, 0, 0, 18)
            tagTitle.Font = T.Font
            tagTitle.Text = cfg2.Name
            tagTitle.TextColor3 = T.TextPrimary
            tagTitle.TextSize = T.SmallTextSize
            tagTitle.TextXAlignment = Enum.TextXAlignment.Left
        end

        local tagContainer = Instance.new("Frame")
        tagContainer.Parent = frame
        tagContainer.BackgroundTransparency = 1
        tagContainer.Size = UDim2.new(1, 0, 0, 0)
        tagContainer.AutomaticSize = Enum.AutomaticSize.Y

        local tagFlowLayout = Instance.new("UIListLayout", tagContainer)
        tagFlowLayout.FillDirection = Enum.FillDirection.Horizontal
        tagFlowLayout.Padding = UDim.new(0, 4)
        tagFlowLayout.Wraps = true

        local function renderTags()
            for _, ch in ipairs(tagContainer:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end
            for i, tag in ipairs(tags) do
                local tagFrame = Instance.new("Frame")
                tagFrame.Parent = tagContainer
                tagFrame.BackgroundColor3 = T.Accent
                tagFrame.Size = UDim2.new(0, 0, 0, 22)
                tagFrame.AutomaticSize = Enum.AutomaticSize.X
                tagFrame.BorderSizePixel = 0
                Instance.new("UICorner", tagFrame).CornerRadius = UDim.new(0, 11)

                local tPad = Instance.new("UIPadding", tagFrame)
                tPad.PaddingLeft = UDim.new(0, 8)
                tPad.PaddingRight = UDim.new(0, 4)

                local tLayout = Instance.new("UIListLayout", tagFrame)
                tLayout.FillDirection = Enum.FillDirection.Horizontal
                tLayout.Padding = UDim.new(0, 4)
                tLayout.VerticalAlignment = Enum.VerticalAlignment.Center

                local tagLabel = Instance.new("TextLabel")
                tagLabel.Parent = tagFrame
                tagLabel.BackgroundTransparency = 1
                tagLabel.Size = UDim2.new(0, 0, 0, 18)
                tagLabel.AutomaticSize = Enum.AutomaticSize.X
                tagLabel.Font = T.FontLight
                tagLabel.Text = tag
                tagLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                tagLabel.TextSize = T.TinyTextSize

                local removeBtn = Instance.new("TextButton")
                removeBtn.Parent = tagFrame
                removeBtn.BackgroundTransparency = 1
                removeBtn.Size = UDim2.new(0, 16, 0, 16)
                removeBtn.Font = T.FontBold
                removeBtn.Text = "×"
                removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                removeBtn.TextSize = 12

                removeBtn.MouseButton1Click:Connect(function()
                    table.remove(tags, i)
                    renderTags()
                    if cfg2.Callback then safeCallback(cfg2.Callback, tags) end
                end)
            end
        end

        local inputBg = Instance.new("Frame")
        inputBg.Parent = frame
        inputBg.BackgroundColor3 = T.InputBG
        inputBg.Size = UDim2.new(1, 0, 0, 28)
        inputBg.BorderSizePixel = 0
        Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 4)

        local tagInput = Instance.new("TextBox")
        tagInput.Parent = inputBg
        tagInput.BackgroundTransparency = 1
        tagInput.Size = UDim2.new(1, -10, 1, 0)
        tagInput.Position = UDim2.new(0, 5, 0, 0)
        tagInput.Font = T.FontLight
        tagInput.PlaceholderText = cfg2.Placeholder or "Add tag..."
        tagInput.Text = ""
        tagInput.TextColor3 = T.TextPrimary
        tagInput.PlaceholderColor3 = T.TextMuted
        tagInput.TextSize = T.SmallTextSize
        tagInput.ClearTextOnFocus = false
        tagInput.TextXAlignment = Enum.TextXAlignment.Left

        tagInput.FocusLost:Connect(function(enterPressed)
            if enterPressed and tagInput.Text ~= "" and #tags < maxTags then
                if not tableContains(tags, tagInput.Text) then
                    table.insert(tags, tagInput.Text)
                    renderTags()
                    if cfg2.Callback then safeCallback(cfg2.Callback, tags) end
                end
                tagInput.Text = ""
            end
        end)

        renderTags()

        local tiObj = {}
        function tiObj:GetTags() return tags end
        function tiObj:SetTags(t) tags = t; renderTags() end
        function tiObj:AddTag(t)
            if #tags < maxTags and not tableContains(tags, t) then
                table.insert(tags, t)
                renderTags()
            end
        end
        function tiObj:SetVisible(v) frame.Visible = v end
        function tiObj:Destroy() frame:Destroy() end
        return tiObj
    end
end)

-- =========================================================================
-- SECTION 36: RATING WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateRating", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local maxStars = cfg2.MaxStars or 5
        local currentRating = cfg2.Default or 0

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, T.ElementHeight)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local lbl = Instance.new("TextLabel")
        lbl.Parent = frame
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.Size = UDim2.new(0.5, -12, 1, 0)
        lbl.Font = T.Font
        lbl.Text = cfg2.Name or "Rating"
        lbl.TextColor3 = T.TextPrimary
        lbl.TextSize = T.TextSize
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local starsFrame = Instance.new("Frame")
        starsFrame.Parent = frame
        starsFrame.BackgroundTransparency = 1
        starsFrame.Position = UDim2.new(0.5, 0, 0, 0)
        starsFrame.Size = UDim2.new(0.5, -12, 1, 0)

        local starLayout = Instance.new("UIListLayout", starsFrame)
        starLayout.FillDirection = Enum.FillDirection.Horizontal
        starLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        starLayout.Padding = UDim.new(0, 2)
        starLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local starButtons = {}

        local function updateStars()
            for i, btn in ipairs(starButtons) do
                btn.TextColor3 = i <= currentRating and Color3.fromRGB(255, 200, 0) or T.TextMuted
            end
        end

        for i = 1, maxStars do
            local starBtn = Instance.new("TextButton")
            starBtn.Parent = starsFrame
            starBtn.BackgroundTransparency = 1
            starBtn.Size = UDim2.new(0, 24, 0, 24)
            starBtn.Font = T.FontBold
            starBtn.Text = "★"
            starBtn.TextColor3 = i <= currentRating and Color3.fromRGB(255, 200, 0) or T.TextMuted
            starBtn.TextSize = 18
            starBtn.AutoButtonColor = false
            starBtn.BorderSizePixel = 0

            starBtn.MouseButton1Click:Connect(function()
                currentRating = i
                updateStars()
                if cfg2.Callback then safeCallback(cfg2.Callback, currentRating) end
            end)

            starBtn.MouseEnter:Connect(function()
                for j = 1, maxStars do
                    starButtons[j].TextColor3 = j <= i and Color3.fromRGB(255, 220, 60) or T.TextMuted
                end
            end)

            starBtn.MouseLeave:Connect(function()
                updateStars()
            end)

            starButtons[i] = starBtn
        end

        local rObj = {}
        function rObj:Get() return currentRating end
        function rObj:Set(v) currentRating = clamp(v, 0, maxStars); updateStars() end
        function rObj:SetVisible(v) frame.Visible = v end
        function rObj:Destroy() frame:Destroy() end
        return rObj
    end
end)

-- =========================================================================
-- SECTION 37: NOTIFICATION PRESETS
-- =========================================================================

function StarLib:NotifySuccess(window, title, content, duration)
    window:Notify({ Title = title or "Success", Content = content or "", Type = "success", Duration = duration })
end

function StarLib:NotifyError(window, title, content, duration)
    window:Notify({ Title = title or "Error", Content = content or "", Type = "error", Duration = duration })
end

function StarLib:NotifyWarning(window, title, content, duration)
    window:Notify({ Title = title or "Warning", Content = content or "", Type = "warning", Duration = duration })
end

function StarLib:NotifyInfo(window, title, content, duration)
    window:Notify({ Title = title or "Info", Content = content or "", Type = "info", Duration = duration })
end

-- =========================================================================
-- SECTION 38: ANIMATION PRESETS
-- =========================================================================

StarLib.AnimationPresets = {
    FadeInUp = function(obj, duration)
        duration = duration or 0.4
        local targetPos = obj.Position
        obj.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset + 20)
        obj.BackgroundTransparency = 1
        TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quint), {
            Position = targetPos,
            BackgroundTransparency = 0,
        }):Play()
    end,

    FadeInDown = function(obj, duration)
        duration = duration or 0.4
        local targetPos = obj.Position
        obj.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 20)
        obj.BackgroundTransparency = 1
        TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quint), {
            Position = targetPos,
            BackgroundTransparency = 0,
        }):Play()
    end,

    ZoomIn = function(obj, duration)
        duration = duration or 0.3
        local targetSize = obj.Size
        obj.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize,
        }):Play()
    end,

    Bounce = function(obj, duration)
        duration = duration or 0.6
        local origPos = obj.Position
        local upPos = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale, origPos.Y.Offset - 15)
        local tw1 = TweenService:Create(obj, TweenInfo.new(duration * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = upPos
        })
        tw1:Play()
        tw1.Completed:Connect(function()
            TweenService:Create(obj, TweenInfo.new(duration * 0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                Position = origPos
            }):Play()
        end)
    end,

    FlashColor = function(obj, color, duration)
        duration = duration or 0.3
        local origColor = obj.BackgroundColor3
        TweenService:Create(obj, TweenInfo.new(duration / 2), { BackgroundColor3 = color }):Play()
        task.delay(duration / 2, function()
            TweenService:Create(obj, TweenInfo.new(duration / 2), { BackgroundColor3 = origColor }):Play()
        end)
    end,

    Ripple = function(obj, duration)
        duration = duration or 0.5
        local size = obj.AbsoluteSize
        local ripple = Instance.new("Frame")
        ripple.Parent = obj
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.7
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.BorderSizePixel = 0
        Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

        local maxSize = math.max(size.X, size.Y) * 2
        TweenService:Create(ripple, TweenInfo.new(duration), {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1,
        }):Play()
        task.delay(duration, function()
            if ripple.Parent then ripple:Destroy() end
        end)
    end,

    Glow = function(obj, color, duration)
        duration = duration or 1
        color = color or Color3.fromRGB(0, 170, 255)
        local glow = Instance.new("UIStroke")
        glow.Parent = obj
        glow.Color = color
        glow.Thickness = 0
        glow.Transparency = 0.5

        TweenService:Create(glow, TweenInfo.new(duration / 2, Enum.EasingStyle.Sine), {
            Thickness = 3,
            Transparency = 0,
        }):Play()
        task.delay(duration / 2, function()
            TweenService:Create(glow, TweenInfo.new(duration / 2, Enum.EasingStyle.Sine), {
                Thickness = 0,
                Transparency = 1,
            }):Play()
            task.delay(duration / 2, function()
                if glow.Parent then glow:Destroy() end
            end)
        end)
    end,
}

-- =========================================================================
-- SECTION 39: SHORTCUT / HOTKEY MANAGER
-- =========================================================================

function StarLib:CreateHotkeyManager()
    local hotkeys = {}
    local enabled = true

    local conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not enabled then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)

        for _, hk in ipairs(hotkeys) do
            if input.KeyCode == hk.Key then
                local modMatch = true
                if hk.Ctrl and not ctrl then modMatch = false end
                if hk.Shift and not shift then modMatch = false end
                if hk.Alt and not alt then modMatch = false end
                if not hk.Ctrl and ctrl then modMatch = false end
                if not hk.Shift and shift then modMatch = false end
                if not hk.Alt and alt then modMatch = false end

                if modMatch then
                    safeCallback(hk.Callback)
                end
            end
        end
    end)

    local mgr = {}

    function mgr:Register(config)
        table.insert(hotkeys, {
            Name = config.Name or "",
            Key = config.Key,
            Ctrl = config.Ctrl or false,
            Shift = config.Shift or false,
            Alt = config.Alt or false,
            Callback = config.Callback,
        })
    end

    function mgr:Unregister(name)
        for i = #hotkeys, 1, -1 do
            if hotkeys[i].Name == name then
                table.remove(hotkeys, i)
            end
        end
    end

    function mgr:Enable() enabled = true end
    function mgr:Disable() enabled = false end
    function mgr:List() return hotkeys end

    function mgr:Destroy()
        conn:Disconnect()
        hotkeys = {}
    end

    return mgr
end

-- =========================================================================
-- SECTION 40: CLIPBOARD HELPERS
-- =========================================================================

function StarLib:CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toclipboard then
            toclipboard(text)
        end
    end)
end

function StarLib:SerializeTable(tbl, indent)
    indent = indent or 0
    local result = "{\n"
    local prefix = string.rep("    ", indent + 1)
    local endPrefix = string.rep("    ", indent)
    local entries = {}
    
    for k, v in pairs(tbl) do
        local keyStr
        if type(k) == "number" then
            keyStr = ""
        elseif type(k) == "string" then
            if k:match("^[%a_][%w_]*$") then
                keyStr = k .. " = "
            else
                keyStr = '["' .. k .. '"] = '
            end
        else
            keyStr = "[" .. tostring(k) .. "] = "
        end

        local valStr
        if type(v) == "string" then
            valStr = '"' .. v:gsub('"', '\\"'):gsub("\n", "\\n") .. '"'
        elseif type(v) == "number" or type(v) == "boolean" then
            valStr = tostring(v)
        elseif type(v) == "table" then
            valStr = StarLib:SerializeTable(v, indent + 1)
        else
            valStr = '"' .. tostring(v) .. '"'
        end

        table.insert(entries, prefix .. keyStr .. valStr)
    end

    result = result .. table.concat(entries, ",\n") .. "\n" .. endPrefix .. "}"
    return result
end

-- =========================================================================
-- SECTION 41: AUTO UPDATER STUB
-- =========================================================================

function StarLib:CheckForUpdates(config)
    config = config or {}
    local currentVersion = config.CurrentVersion or STARLIB_VERSION
    local url = config.URL

    if not url then
        debugLog("No update URL provided")
        return { UpToDate = true, CurrentVersion = currentVersion }
    end

    local result = { UpToDate = true, CurrentVersion = currentVersion }

    pcall(function()
        local response = game:HttpGet(url)
        if response then
            local data = HttpService:JSONDecode(response)
            if data and data.version and data.version ~= currentVersion then
                result.UpToDate = false
                result.LatestVersion = data.version
                result.Changelog = data.changelog
                result.DownloadURL = data.download
            end
        end
    end)

    return result
end

-- =========================================================================
-- SECTION 42: COMPREHENSIVE DEBUG LOG
-- =========================================================================

function StarLib:EnableDebugMode()
    self.DebugMode = true
    debugLog("Debug mode enabled")
    debugLog("StarLib v" .. STARLIB_VERSION .. " | Build " .. STARLIB_BUILD)
    debugLog("Lua version: " .. (_VERSION or "unknown"))
    debugLog("Platform: Roblox executor environment")

    pcall(function()
        if identifyexecutor then
            local name, ver = identifyexecutor()
            debugLog("Executor: " .. tostring(name) .. " v" .. tostring(ver))
        end
    end)

    debugLog("Windows active: " .. #self.Windows)
    debugLog("Plugins loaded: " .. #tableKeys(self._plugins))
    debugLog("Tab extensions: " .. #tableKeys(_tabExtensions))
    debugLog("Theme presets: " .. #tableKeys(THEME_PRESETS))
end

function StarLib:DisableDebugMode()
    debugLog("Debug mode disabled")
    self.DebugMode = false
end

function StarLib:DumpState()
    local state = {
        version = STARLIB_VERSION,
        build = STARLIB_BUILD,
        debugMode = self.DebugMode,
        windowCount = #self.Windows,
        windows = {},
        plugins = tableKeys(self._plugins),
        extensions = tableKeys(_tabExtensions),
    }

    for _, w in ipairs(self.Windows) do
        table.insert(state.windows, {
            name = w._name,
            visible = w._gui and w._gui.Enabled or false,
            tabs = tableKeys(w.Tabs),
            widgets = tableKeys(w._widgetRegistry),
        })
    end

    return state
end

-- =========================================================================
-- SECTION 43: DATA STORE ABSTRACTION
-- =========================================================================

function StarLib:CreateDataStore(name)
    local storeName = "StarLib_DataStore_" .. (name or "default")
    local data = {}

    pcall(function()
        if readfile then
            local raw = readfile(storeName .. ".json")
            if raw and raw ~= "" then
                data = HttpService:JSONDecode(raw)
            end
        end
    end)

    local store = {}

    function store:Get(key, default)
        if data[key] ~= nil then return data[key] end
        return default
    end

    function store:Set(key, value)
        data[key] = value
        self:_save()
    end

    function store:Remove(key)
        data[key] = nil
        self:_save()
    end

    function store:GetAll()
        return deepCopy(data)
    end

    function store:Clear()
        data = {}
        self:_save()
    end

    function store:Has(key)
        return data[key] ~= nil
    end

    function store:Keys()
        return tableKeys(data)
    end

    function store:Count()
        local c = 0
        for _ in pairs(data) do c = c + 1 end
        return c
    end

    function store:Increment(key, amount)
        amount = amount or 1
        data[key] = (tonumber(data[key]) or 0) + amount
        self:_save()
        return data[key]
    end

    function store:Push(key, value)
        if type(data[key]) ~= "table" then data[key] = {} end
        table.insert(data[key], value)
        self:_save()
    end

    function store:Pop(key)
        if type(data[key]) == "table" and #data[key] > 0 then
            local val = table.remove(data[key])
            self:_save()
            return val
        end
        return nil
    end

    function store:_save()
        pcall(function()
            if writefile then
                writefile(storeName .. ".json", HttpService:JSONEncode(data))
            end
        end)
    end

    return store
end

-- =========================================================================
-- SECTION 44: ADVANCED TABLE WITH SORT/FILTER
-- =========================================================================

StarLib:RegisterTabExtension("CreateDataTable", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local columns = cfg2.Columns or {}
        local rows = cfg2.Rows or {}
        local sortColumn = nil
        local sortAsc = true
        local filterText = ""
        local pageSize = cfg2.PageSize or 10
        local currentPage = 1
        local selectedRows = {}

        local wrapper = Instance.new("Frame")
        wrapper.Parent = container
        wrapper.BackgroundColor3 = T.ElementBG
        wrapper.Size = UDim2.new(1, 0, 0, 0)
        wrapper.AutomaticSize = Enum.AutomaticSize.Y
        wrapper.LayoutOrder = nextOrder()
        wrapper.BorderSizePixel = 0
        Instance.new("UICorner", wrapper).CornerRadius = T.ElementRadius

        local wPad = Instance.new("UIPadding", wrapper)
        wPad.PaddingLeft = UDim.new(0, 8)
        wPad.PaddingRight = UDim.new(0, 8)
        wPad.PaddingTop = UDim.new(0, 8)
        wPad.PaddingBottom = UDim.new(0, 8)

        local wLayout = Instance.new("UIListLayout", wrapper)
        wLayout.Padding = UDim.new(0, 4)

        if cfg2.Name then
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = wrapper
            titleLabel.BackgroundTransparency = 1
            titleLabel.Size = UDim2.new(1, 0, 0, 22)
            titleLabel.Font = T.FontBold
            titleLabel.Text = cfg2.Name
            titleLabel.TextColor3 = T.TextPrimary
            titleLabel.TextSize = T.TextSize
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        local toolbarFrame = Instance.new("Frame")
        toolbarFrame.Parent = wrapper
        toolbarFrame.BackgroundTransparency = 1
        toolbarFrame.Size = UDim2.new(1, 0, 0, 28)

        local filterBox = Instance.new("TextBox")
        filterBox.Parent = toolbarFrame
        filterBox.BackgroundColor3 = T.InputBG
        filterBox.Size = UDim2.new(0.5, -4, 1, 0)
        filterBox.Font = T.FontLight
        filterBox.PlaceholderText = "Filter..."
        filterBox.Text = ""
        filterBox.TextColor3 = T.TextPrimary
        filterBox.PlaceholderColor3 = T.TextMuted
        filterBox.TextSize = T.SmallTextSize
        filterBox.ClearTextOnFocus = false
        filterBox.TextXAlignment = Enum.TextXAlignment.Left
        filterBox.BorderSizePixel = 0
        Instance.new("UICorner", filterBox).CornerRadius = UDim.new(0, 4)
        local fbPad = Instance.new("UIPadding", filterBox)
        fbPad.PaddingLeft = UDim.new(0, 6)

        local countLabel = Instance.new("TextLabel")
        countLabel.Parent = toolbarFrame
        countLabel.BackgroundTransparency = 1
        countLabel.Position = UDim2.new(0.5, 4, 0, 0)
        countLabel.Size = UDim2.new(0.5, -4, 1, 0)
        countLabel.Font = T.FontLight
        countLabel.Text = #rows .. " rows"
        countLabel.TextColor3 = T.TextMuted
        countLabel.TextSize = T.TinyTextSize
        countLabel.TextXAlignment = Enum.TextXAlignment.Right

        local headerRow = Instance.new("Frame")
        headerRow.Parent = wrapper
        headerRow.BackgroundColor3 = darkenColor(T.ElementBG, 0.05)
        headerRow.Size = UDim2.new(1, 0, 0, 26)
        headerRow.BorderSizePixel = 0
        Instance.new("UICorner", headerRow).CornerRadius = UDim.new(0, 3)

        local hLayout = Instance.new("UIListLayout", headerRow)
        hLayout.FillDirection = Enum.FillDirection.Horizontal

        local colWidth = 1 / math.max(#columns, 1)
        for _, col in ipairs(columns) do
            local colBtn = Instance.new("TextButton")
            colBtn.Parent = headerRow
            colBtn.BackgroundTransparency = 1
            colBtn.Size = UDim2.new(col.Width or colWidth, 0, 1, 0)
            colBtn.Font = T.FontBold
            colBtn.Text = (col.Name or col) .. "  ▼"
            colBtn.TextColor3 = T.TextPrimary
            colBtn.TextSize = T.TinyTextSize
            colBtn.TextXAlignment = Enum.TextXAlignment.Left
            colBtn.AutoButtonColor = false
            colBtn.BorderSizePixel = 0

            local cPad = Instance.new("UIPadding", colBtn)
            cPad.PaddingLeft = UDim.new(0, 6)

            colBtn.MouseButton1Click:Connect(function()
                local colName = type(col) == "table" and col.Key or col
                if sortColumn == colName then
                    sortAsc = not sortAsc
                else
                    sortColumn = colName
                    sortAsc = true
                end
                colBtn.Text = (col.Name or col) .. (sortAsc and "  ▲" or "  ▼")
                renderTable()
            end)
        end

        local bodyFrame = Instance.new("ScrollingFrame")
        bodyFrame.Parent = wrapper
        bodyFrame.BackgroundTransparency = 1
        bodyFrame.Size = UDim2.new(1, 0, 0, math.min(pageSize * 24, 240))
        bodyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        bodyFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        bodyFrame.ScrollBarThickness = 3
        bodyFrame.ScrollBarImageColor3 = T.Accent
        bodyFrame.BorderSizePixel = 0
        local bLayout = Instance.new("UIListLayout", bodyFrame)
        bLayout.Padding = UDim.new(0, 1)

        local pageFrame = Instance.new("Frame")
        pageFrame.Parent = wrapper
        pageFrame.BackgroundTransparency = 1
        pageFrame.Size = UDim2.new(1, 0, 0, 24)

        local pageLabel = Instance.new("TextLabel")
        pageLabel.Parent = pageFrame
        pageLabel.BackgroundTransparency = 1
        pageLabel.Size = UDim2.new(1, 0, 1, 0)
        pageLabel.Font = T.FontLight
        pageLabel.Text = "Page 1"
        pageLabel.TextColor3 = T.TextMuted
        pageLabel.TextSize = T.TinyTextSize

        local prevBtn = Instance.new("TextButton")
        prevBtn.Parent = pageFrame
        prevBtn.BackgroundTransparency = 1
        prevBtn.Position = UDim2.new(0, 0, 0, 0)
        prevBtn.Size = UDim2.new(0, 30, 1, 0)
        prevBtn.Font = T.FontBold
        prevBtn.Text = "◄"
        prevBtn.TextColor3 = T.Accent
        prevBtn.TextSize = 14
        prevBtn.AutoButtonColor = false
        prevBtn.BorderSizePixel = 0

        local nextBtn = Instance.new("TextButton")
        nextBtn.Parent = pageFrame
        nextBtn.BackgroundTransparency = 1
        nextBtn.Position = UDim2.new(1, -30, 0, 0)
        nextBtn.Size = UDim2.new(0, 30, 1, 0)
        nextBtn.Font = T.FontBold
        nextBtn.Text = "►"
        nextBtn.TextColor3 = T.Accent
        nextBtn.TextSize = 14
        nextBtn.AutoButtonColor = false
        nextBtn.BorderSizePixel = 0

        function renderTable()
            for _, ch in ipairs(bodyFrame:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end

            local filtered = {}
            for _, row in ipairs(rows) do
                if filterText == "" then
                    table.insert(filtered, row)
                else
                    local match = false
                    for _, v in pairs(row) do
                        if tostring(v):lower():find(filterText:lower(), 1, true) then
                            match = true; break
                        end
                    end
                    if match then table.insert(filtered, row) end
                end
            end

            if sortColumn then
                table.sort(filtered, function(a, b)
                    local va = a[sortColumn]
                    local vb = b[sortColumn]
                    if va == nil then return false end
                    if vb == nil then return true end
                    if type(va) == "number" and type(vb) == "number" then
                        return sortAsc and va < vb or va > vb
                    end
                    return sortAsc and tostring(va) < tostring(vb) or tostring(va) > tostring(vb)
                end)
            end

            local totalPages = math.max(1, math.ceil(#filtered / pageSize))
            currentPage = clamp(currentPage, 1, totalPages)
            local startIdx = (currentPage - 1) * pageSize + 1
            local endIdx = math.min(startIdx + pageSize - 1, #filtered)

            countLabel.Text = #filtered .. " of " .. #rows .. " rows"
            pageLabel.Text = "Page " .. currentPage .. " of " .. totalPages

            for idx = startIdx, endIdx do
                local rowData = filtered[idx]
                local rowFrame = Instance.new("Frame")
                rowFrame.Parent = bodyFrame
                rowFrame.BackgroundColor3 = idx % 2 == 0 and T.ElementBG or darkenColor(T.ElementBG, 0.03)
                rowFrame.Size = UDim2.new(1, 0, 0, 24)
                rowFrame.BorderSizePixel = 0

                local rLayout = Instance.new("UIListLayout", rowFrame)
                rLayout.FillDirection = Enum.FillDirection.Horizontal

                for _, col in ipairs(columns) do
                    local colKey = type(col) == "table" and col.Key or col
                    local cellLabel = Instance.new("TextLabel")
                    cellLabel.Parent = rowFrame
                    cellLabel.BackgroundTransparency = 1
                    cellLabel.Size = UDim2.new(col.Width or colWidth, 0, 1, 0)
                    cellLabel.Font = T.FontLight
                    cellLabel.Text = tostring(rowData[colKey] or "")
                    cellLabel.TextColor3 = T.TextSecondary
                    cellLabel.TextSize = T.TinyTextSize
                    cellLabel.TextXAlignment = Enum.TextXAlignment.Left
                    cellLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    local cPad2 = Instance.new("UIPadding", cellLabel)
                    cPad2.PaddingLeft = UDim.new(0, 6)
                end

                if cfg2.OnRowClick then
                    local clickBtn = Instance.new("TextButton")
                    clickBtn.Parent = rowFrame
                    clickBtn.BackgroundTransparency = 1
                    clickBtn.Size = UDim2.new(1, 0, 1, 0)
                    clickBtn.Text = ""
                    clickBtn.ZIndex = 5
                    clickBtn.BorderSizePixel = 0
                    clickBtn.MouseButton1Click:Connect(function()
                        safeCallback(cfg2.OnRowClick, rowData, idx)
                    end)
                end
            end
        end

        filterBox:GetPropertyChangedSignal("Text"):Connect(function()
            filterText = filterBox.Text
            currentPage = 1
            renderTable()
        end)

        prevBtn.MouseButton1Click:Connect(function()
            currentPage = currentPage - 1
            renderTable()
        end)

        nextBtn.MouseButton1Click:Connect(function()
            currentPage = currentPage + 1
            renderTable()
        end)

        renderTable()

        local dtObj = {}
        function dtObj:SetRows(r) rows = r; renderTable() end
        function dtObj:AddRow(r) table.insert(rows, r); renderTable() end
        function dtObj:RemoveRow(idx) table.remove(rows, idx); renderTable() end
        function dtObj:Clear() rows = {}; renderTable() end
        function dtObj:GetRows() return rows end
        function dtObj:SetFilter(f) filterText = f; filterBox.Text = f; renderTable() end
        function dtObj:SetPage(p) currentPage = p; renderTable() end
        function dtObj:Refresh() renderTable() end
        function dtObj:SetVisible(v) wrapper.Visible = v end
        function dtObj:Destroy() wrapper:Destroy() end
        return dtObj
    end
end)

-- =========================================================================
-- SECTION 45: BREADCRUMB NAVIGATION
-- =========================================================================

StarLib:RegisterTabExtension("CreateBreadcrumb", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local items = cfg2.Items or {}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 24)
        frame.LayoutOrder = nextOrder()

        local bLayout = Instance.new("UIListLayout", frame)
        bLayout.FillDirection = Enum.FillDirection.Horizontal
        bLayout.Padding = UDim.new(0, 0)
        bLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        local function render()
            for _, ch in ipairs(frame:GetChildren()) do
                if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
            end

            for i, item in ipairs(items) do
                local isLast = i == #items

                local breadBtn = Instance.new(isLast and "TextLabel" or "TextButton")
                breadBtn.Parent = frame
                breadBtn.BackgroundTransparency = 1
                breadBtn.Size = UDim2.new(0, 0, 0, 20)
                breadBtn.AutomaticSize = Enum.AutomaticSize.X
                breadBtn.Font = isLast and T.FontBold or T.FontLight
                breadBtn.Text = item.Name or ""
                breadBtn.TextColor3 = isLast and T.TextPrimary or T.Accent
                breadBtn.TextSize = T.SmallTextSize
                if not isLast then
                    breadBtn.AutoButtonColor = false
                    breadBtn.BorderSizePixel = 0
                end

                if not isLast then
                    breadBtn.MouseEnter:Connect(function()
                        breadBtn.TextColor3 = lightenColor(T.Accent, 0.2)
                    end)
                    breadBtn.MouseLeave:Connect(function()
                        breadBtn.TextColor3 = T.Accent
                    end)
                    breadBtn.MouseButton1Click:Connect(function()
                        if item.Callback then safeCallback(item.Callback, item) end
                    end)

                    local sep = Instance.new("TextLabel")
                    sep.Parent = frame
                    sep.BackgroundTransparency = 1
                    sep.Size = UDim2.new(0, 20, 0, 20)
                    sep.Font = T.FontLight
                    sep.Text = cfg2.Separator or " ► "
                    sep.TextColor3 = T.TextMuted
                    sep.TextSize = T.TinyTextSize
                end
            end
        end

        render()

        local bcObj = {}
        function bcObj:SetItems(newItems) items = newItems; render() end
        function bcObj:Push(item) table.insert(items, item); render() end
        function bcObj:Pop()
            if #items > 1 then table.remove(items); render() end
        end
        function bcObj:SetVisible(v) frame.Visible = v end
        function bcObj:Destroy() frame:Destroy() end
        return bcObj
    end
end)

-- =========================================================================
-- SECTION 46: CHAT / LOG WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateChatLog", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local messages = {}
        local maxMessages = cfg2.MaxMessages or 100

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = darkenColor(T.ElementBG, 0.05)
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 200)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local fLayout = Instance.new("UIListLayout", frame)
        fLayout.Padding = UDim.new(0, 0)

        if cfg2.Name then
            local titleBar = Instance.new("Frame")
            titleBar.Parent = frame
            titleBar.BackgroundColor3 = darkenColor(T.ElementBG, 0.1)
            titleBar.Size = UDim2.new(1, 0, 0, 26)
            titleBar.BorderSizePixel = 0

            local tLabel = Instance.new("TextLabel")
            tLabel.Parent = titleBar
            tLabel.BackgroundTransparency = 1
            tLabel.Position = UDim2.new(0, 10, 0, 0)
            tLabel.Size = UDim2.new(1, -10, 1, 0)
            tLabel.Font = T.FontBold
            tLabel.Text = cfg2.Name
            tLabel.TextColor3 = T.TextPrimary
            tLabel.TextSize = T.SmallTextSize
            tLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Parent = frame
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.Size = UDim2.new(1, 0, 1, cfg2.Name and -52 or -30)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scrollFrame.ScrollBarThickness = 3
        scrollFrame.ScrollBarImageColor3 = T.Accent
        scrollFrame.BorderSizePixel = 0

        local sLayout = Instance.new("UIListLayout", scrollFrame)
        sLayout.Padding = UDim.new(0, 2)
        local sPad = Instance.new("UIPadding", scrollFrame)
        sPad.PaddingLeft = UDim.new(0, 6)
        sPad.PaddingRight = UDim.new(0, 6)
        sPad.PaddingTop = UDim.new(0, 4)
        sPad.PaddingBottom = UDim.new(0, 4)

        local inputBar = Instance.new("Frame")
        inputBar.Parent = frame
        inputBar.BackgroundColor3 = darkenColor(T.ElementBG, 0.08)
        inputBar.Size = UDim2.new(1, 0, 0, 30)
        inputBar.BorderSizePixel = 0

        local inputBox = Instance.new("TextBox")
        inputBox.Parent = inputBar
        inputBox.BackgroundColor3 = T.InputBG
        inputBox.Position = UDim2.new(0, 6, 0.5, -11)
        inputBox.Size = UDim2.new(1, -52, 0, 22)
        inputBox.Font = T.FontLight
        inputBox.PlaceholderText = cfg2.Placeholder or "Type a message..."
        inputBox.Text = ""
        inputBox.TextColor3 = T.TextPrimary
        inputBox.PlaceholderColor3 = T.TextMuted
        inputBox.TextSize = T.SmallTextSize
        inputBox.ClearTextOnFocus = false
        inputBox.TextXAlignment = Enum.TextXAlignment.Left
        inputBox.BorderSizePixel = 0
        Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
        local ibPad = Instance.new("UIPadding", inputBox)
        ibPad.PaddingLeft = UDim.new(0, 6)

        local sendBtn = Instance.new("TextButton")
        sendBtn.Parent = inputBar
        sendBtn.BackgroundColor3 = T.Accent
        sendBtn.Position = UDim2.new(1, -40, 0.5, -11)
        sendBtn.Size = UDim2.new(0, 34, 0, 22)
        sendBtn.Font = T.FontBold
        sendBtn.Text = "►"
        sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        sendBtn.TextSize = 12
        sendBtn.AutoButtonColor = false
        sendBtn.BorderSizePixel = 0
        Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 4)

        local typeColors = {
            system = T.TextMuted,
            error = T.Error,
            warning = T.Warning,
            success = T.Success,
            info = T.Info,
            user = T.TextPrimary,
        }

        local function addMessageUI(msg)
            local msgFrame = Instance.new("Frame")
            msgFrame.Parent = scrollFrame
            msgFrame.BackgroundTransparency = 1
            msgFrame.Size = UDim2.new(1, 0, 0, 0)
            msgFrame.AutomaticSize = Enum.AutomaticSize.Y

            local timeStr = ""
            if cfg2.ShowTimestamp ~= false then
                timeStr = os.date("[%H:%M] ")
            end

            local prefix = msg.Author and (msg.Author .. ": ") or ""
            local color = typeColors[msg.Type or "user"] or T.TextPrimary

            local msgLabel = Instance.new("TextLabel")
            msgLabel.Parent = msgFrame
            msgLabel.BackgroundTransparency = 1
            msgLabel.Size = UDim2.new(1, 0, 0, 0)
            msgLabel.AutomaticSize = Enum.AutomaticSize.Y
            msgLabel.Font = T.FontLight
            msgLabel.Text = timeStr .. prefix .. (msg.Text or "")
            msgLabel.TextColor3 = color
            msgLabel.TextSize = T.TinyTextSize
            msgLabel.TextXAlignment = Enum.TextXAlignment.Left
            msgLabel.TextWrapped = true
            msgLabel.RichText = cfg2.RichText or false

            scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
        end

        local function sendMessage(text, msgType, author)
            if text == "" then return end
            if #messages >= maxMessages then
                table.remove(messages, 1)
                local first = scrollFrame:FindFirstChildWhichIsA("Frame")
                if first then first:Destroy() end
            end

            local msg = { Text = text, Type = msgType or "user", Author = author, Time = os.time() }
            table.insert(messages, msg)
            addMessageUI(msg)

            if cfg2.OnMessage then
                safeCallback(cfg2.OnMessage, msg)
            end
        end

        sendBtn.MouseButton1Click:Connect(function()
            if inputBox.Text ~= "" then
                sendMessage(inputBox.Text, "user", cfg2.Username or "You")
                inputBox.Text = ""
            end
        end)

        inputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed and inputBox.Text ~= "" then
                sendMessage(inputBox.Text, "user", cfg2.Username or "You")
                inputBox.Text = ""
            end
        end)

        local clObj = {}
        function clObj:AddMessage(text, msgType, author) sendMessage(text, msgType, author) end
        function clObj:AddSystem(text) sendMessage(text, "system", "System") end
        function clObj:AddError(text) sendMessage(text, "error", "Error") end
        function clObj:AddSuccess(text) sendMessage(text, "success", nil) end
        function clObj:Clear()
            messages = {}
            for _, ch in ipairs(scrollFrame:GetChildren()) do
                if ch:IsA("Frame") then ch:Destroy() end
            end
        end
        function clObj:GetMessages() return messages end
        function clObj:SetVisible(v) frame.Visible = v end
        function clObj:Destroy() frame:Destroy() end
        return clObj
    end
end)

-- =========================================================================
-- SECTION 47: KANBAN BOARD
-- =========================================================================

StarLib:RegisterTabExtension("CreateKanban", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local columnDefs = cfg2.Columns or { "To Do", "In Progress", "Done" }
        local cardData = cfg2.Cards or {}

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 280)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local fPad = Instance.new("UIPadding", frame)
        fPad.PaddingLeft = UDim.new(0, 6)
        fPad.PaddingRight = UDim.new(0, 6)
        fPad.PaddingTop = UDim.new(0, 6)
        fPad.PaddingBottom = UDim.new(0, 6)

        local fLayout = Instance.new("UIListLayout", frame)
        fLayout.Padding = UDim.new(0, 4)

        if cfg2.Name then
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Parent = frame
            titleLabel.BackgroundTransparency = 1
            titleLabel.Size = UDim2.new(1, 0, 0, 22)
            titleLabel.Font = T.FontBold
            titleLabel.Text = cfg2.Name
            titleLabel.TextColor3 = T.TextPrimary
            titleLabel.TextSize = T.TextSize
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        local columnsFrame = Instance.new("Frame")
        columnsFrame.Parent = frame
        columnsFrame.BackgroundTransparency = 1
        columnsFrame.Size = UDim2.new(1, 0, 1, cfg2.Name and -26 or 0)

        local cLayout = Instance.new("UIListLayout", columnsFrame)
        cLayout.FillDirection = Enum.FillDirection.Horizontal
        cLayout.Padding = UDim.new(0, 6)

        local columnScrolls = {}
        local colWidth = 1 / #columnDefs

        for _, colName in ipairs(columnDefs) do
            local colFrame = Instance.new("Frame")
            colFrame.Parent = columnsFrame
            colFrame.BackgroundColor3 = darkenColor(T.ElementBG, 0.05)
            colFrame.Size = UDim2.new(colWidth, -6, 1, 0)
            colFrame.BorderSizePixel = 0
            Instance.new("UICorner", colFrame).CornerRadius = UDim.new(0, 4)

            local colHeader = Instance.new("TextLabel")
            colHeader.Parent = colFrame
            colHeader.BackgroundTransparency = 1
            colHeader.Position = UDim2.new(0, 6, 0, 0)
            colHeader.Size = UDim2.new(1, -6, 0, 24)
            colHeader.Font = T.FontBold
            colHeader.Text = colName
            colHeader.TextColor3 = T.Accent
            colHeader.TextSize = T.SmallTextSize
            colHeader.TextXAlignment = Enum.TextXAlignment.Left

            local scroll = Instance.new("ScrollingFrame")
            scroll.Parent = colFrame
            scroll.BackgroundTransparency = 1
            scroll.Position = UDim2.new(0, 0, 0, 26)
            scroll.Size = UDim2.new(1, 0, 1, -26)
            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.ScrollBarThickness = 2
            scroll.ScrollBarImageColor3 = T.Accent
            scroll.BorderSizePixel = 0
            local sLay = Instance.new("UIListLayout", scroll)
            sLay.Padding = UDim.new(0, 4)
            local sPd = Instance.new("UIPadding", scroll)
            sPd.PaddingLeft = UDim.new(0, 4)
            sPd.PaddingRight = UDim.new(0, 4)
            sPd.PaddingTop = UDim.new(0, 4)

            columnScrolls[colName] = scroll
        end

        local function renderCards()
            for _, scroll in pairs(columnScrolls) do
                for _, ch in ipairs(scroll:GetChildren()) do
                    if ch:IsA("Frame") then ch:Destroy() end
                end
            end

            for _, card in ipairs(cardData) do
                local colScroll = columnScrolls[card.Column or columnDefs[1]]
                if not colScroll then colScroll = columnScrolls[columnDefs[1]] end

                local cardFrame = Instance.new("Frame")
                cardFrame.Parent = colScroll
                cardFrame.BackgroundColor3 = T.ElementBG
                cardFrame.Size = UDim2.new(1, 0, 0, 0)
                cardFrame.AutomaticSize = Enum.AutomaticSize.Y
                cardFrame.BorderSizePixel = 0
                Instance.new("UICorner", cardFrame).CornerRadius = UDim.new(0, 4)

                local cPad = Instance.new("UIPadding", cardFrame)
                cPad.PaddingLeft = UDim.new(0, 6)
                cPad.PaddingRight = UDim.new(0, 6)
                cPad.PaddingTop = UDim.new(0, 4)
                cPad.PaddingBottom = UDim.new(0, 4)

                local cLay = Instance.new("UIListLayout", cardFrame)
                cLay.Padding = UDim.new(0, 2)

                if card.Color then
                    local accentBar = Instance.new("Frame")
                    accentBar.Parent = cardFrame
                    accentBar.BackgroundColor3 = card.Color
                    accentBar.Size = UDim2.new(1, 0, 0, 2)
                    accentBar.BorderSizePixel = 0
                end

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Parent = cardFrame
                titleLbl.BackgroundTransparency = 1
                titleLbl.Size = UDim2.new(1, 0, 0, 16)
                titleLbl.Font = T.Font
                titleLbl.Text = card.Title or ""
                titleLbl.TextColor3 = T.TextPrimary
                titleLbl.TextSize = T.SmallTextSize
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left

                if card.Description then
                    local descLbl = Instance.new("TextLabel")
                    descLbl.Parent = cardFrame
                    descLbl.BackgroundTransparency = 1
                    descLbl.Size = UDim2.new(1, 0, 0, 0)
                    descLbl.AutomaticSize = Enum.AutomaticSize.Y
                    descLbl.Font = T.FontLight
                    descLbl.Text = card.Description
                    descLbl.TextColor3 = T.TextMuted
                    descLbl.TextSize = T.TinyTextSize
                    descLbl.TextXAlignment = Enum.TextXAlignment.Left
                    descLbl.TextWrapped = true
                end

                if card.Tags then
                    local tagRow = Instance.new("Frame")
                    tagRow.Parent = cardFrame
                    tagRow.BackgroundTransparency = 1
                    tagRow.Size = UDim2.new(1, 0, 0, 16)
                    local tLay = Instance.new("UIListLayout", tagRow)
                    tLay.FillDirection = Enum.FillDirection.Horizontal
                    tLay.Padding = UDim.new(0, 3)

                    for _, tagName in ipairs(card.Tags) do
                        local tagLbl = Instance.new("TextLabel")
                        tagLbl.Parent = tagRow
                        tagLbl.BackgroundColor3 = T.Accent
                        tagLbl.Size = UDim2.new(0, 0, 0, 14)
                        tagLbl.AutomaticSize = Enum.AutomaticSize.X
                        tagLbl.Font = T.FontLight
                        tagLbl.Text = " " .. tagName .. " "
                        tagLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        tagLbl.TextSize = 9
                        Instance.new("UICorner", tagLbl).CornerRadius = UDim.new(0, 7)
                    end
                end
            end
        end

        renderCards()

        local kObj = {}
        function kObj:AddCard(card) table.insert(cardData, card); renderCards() end
        function kObj:RemoveCard(title)
            for i = #cardData, 1, -1 do
                if cardData[i].Title == title then table.remove(cardData, i); break end
            end
            renderCards()
        end
        function kObj:MoveCard(title, newColumn)
            for _, card in ipairs(cardData) do
                if card.Title == title then card.Column = newColumn; break end
            end
            renderCards()
        end
        function kObj:GetCards() return cardData end
        function kObj:SetVisible(v) frame.Visible = v end
        function kObj:Destroy() frame:Destroy() end
        return kObj
    end
end)

-- =========================================================================
-- SECTION 48: TABS WITHIN TABS (SUB-TAB SYSTEM)
-- =========================================================================

StarLib:RegisterTabExtension("CreateSubTabs", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local tabNames = cfg2.Tabs or {}
        local tabContents = {}
        local activeTab = 1

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, cfg2.Height or 250)
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local tabBar = Instance.new("Frame")
        tabBar.Parent = frame
        tabBar.BackgroundColor3 = darkenColor(T.ElementBG, 0.06)
        tabBar.Size = UDim2.new(1, 0, 0, 28)
        tabBar.BorderSizePixel = 0

        local tbLayout = Instance.new("UIListLayout", tabBar)
        tbLayout.FillDirection = Enum.FillDirection.Horizontal

        local tabButtons = {}
        local contentFrames = {}

        for i, tabName in ipairs(tabNames) do
            local contentFrame = Instance.new("ScrollingFrame")
            contentFrame.Parent = frame
            contentFrame.BackgroundTransparency = 1
            contentFrame.Position = UDim2.new(0, 0, 0, 28)
            contentFrame.Size = UDim2.new(1, 0, 1, -28)
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
            contentFrame.ScrollBarThickness = 3
            contentFrame.ScrollBarImageColor3 = T.Accent
            contentFrame.Visible = i == 1
            contentFrame.BorderSizePixel = 0

            local cLay = Instance.new("UIListLayout", contentFrame)
            cLay.Padding = UDim.new(0, 4)
            local cPd = Instance.new("UIPadding", contentFrame)
            cPd.PaddingLeft = UDim.new(0, 8)
            cPd.PaddingRight = UDim.new(0, 8)
            cPd.PaddingTop = UDim.new(0, 6)
            cPd.PaddingBottom = UDim.new(0, 6)

            contentFrames[i] = contentFrame

            local tabBtn = Instance.new("TextButton")
            tabBtn.Parent = tabBar
            tabBtn.BackgroundColor3 = i == 1 and T.Accent or Color3.fromRGB(0, 0, 0)
            tabBtn.BackgroundTransparency = i == 1 and 0 or 1
            tabBtn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
            tabBtn.Font = i == 1 and T.FontBold or T.FontLight
            tabBtn.Text = tabName
            tabBtn.TextColor3 = i == 1 and Color3.fromRGB(255, 255, 255) or T.TextMuted
            tabBtn.TextSize = T.SmallTextSize
            tabBtn.AutoButtonColor = false
            tabBtn.BorderSizePixel = 0

            tabBtn.MouseButton1Click:Connect(function()
                activeTab = i
                for j, btn in ipairs(tabButtons) do
                    contentFrames[j].Visible = j == i
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundTransparency = j == i and 0 or 1,
                        BackgroundColor3 = j == i and T.Accent or Color3.fromRGB(0, 0, 0),
                        TextColor3 = j == i and Color3.fromRGB(255, 255, 255) or T.TextMuted,
                    }):Play()
                    btn.Font = j == i and T.FontBold or T.FontLight
                end
                if cfg2.OnTabChanged then safeCallback(cfg2.OnTabChanged, tabName, i) end
            end)

            tabButtons[i] = tabBtn

            local localOrder = 0
            local subTab = {}
            setmetatable(subTab, { __index = Tab })
            function subTab:_nextOrder()
                localOrder = localOrder + 1
                return localOrder
            end

            tabContents[tabName] = { Frame = contentFrame, Tab = subTab }

            local stWidgetOrder = 0
            local function stNextOrder()
                stWidgetOrder = stWidgetOrder + 1
                return stWidgetOrder
            end

            subTab.CreateSection = function(_, name2)
                local secLabel = Instance.new("TextLabel")
                secLabel.Parent = contentFrame
                secLabel.BackgroundTransparency = 1
                secLabel.Size = UDim2.new(1, 0, 0, 20)
                secLabel.LayoutOrder = stNextOrder()
                secLabel.Font = T.FontBold
                secLabel.Text = name2 or ""
                secLabel.TextColor3 = T.Accent
                secLabel.TextSize = T.SmallTextSize
                secLabel.TextXAlignment = Enum.TextXAlignment.Left
            end

            subTab.CreateLabel = function(_, text2)
                local lbl = Instance.new("TextLabel")
                lbl.Parent = contentFrame
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0, 18)
                lbl.LayoutOrder = stNextOrder()
                lbl.Font = T.FontLight
                lbl.Text = text2 or ""
                lbl.TextColor3 = T.TextSecondary
                lbl.TextSize = T.SmallTextSize
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                local stObj = {}
                function stObj:SetText(t) lbl.Text = t end
                function stObj:SetVisible(v) lbl.Visible = v end
                return stObj
            end

            subTab.CreateButton = function(_, cfg3)
                local btn = Instance.new("TextButton")
                btn.Parent = contentFrame
                btn.BackgroundColor3 = T.Accent
                btn.Size = UDim2.new(1, 0, 0, 30)
                btn.LayoutOrder = stNextOrder()
                btn.Font = T.Font
                btn.Text = cfg3.Name or "Button"
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextSize = T.SmallTextSize
                btn.AutoButtonColor = false
                btn.BorderSizePixel = 0
                Instance.new("UICorner", btn).CornerRadius = T.ElementRadius
                btn.MouseButton1Click:Connect(function()
                    if cfg3.Callback then safeCallback(cfg3.Callback) end
                end)
                local bObj = {}
                function bObj:SetText(t) btn.Text = t end
                function bObj:SetVisible(v) btn.Visible = v end
                return bObj
            end

            subTab.CreateToggle = function(_, cfg3)
                local togValue = cfg3.CurrentValue or false

                local togFrame = Instance.new("Frame")
                togFrame.Parent = contentFrame
                togFrame.BackgroundColor3 = T.ElementBG
                togFrame.Size = UDim2.new(1, 0, 0, 30)
                togFrame.LayoutOrder = stNextOrder()
                togFrame.BorderSizePixel = 0
                Instance.new("UICorner", togFrame).CornerRadius = T.ElementRadius

                local togLabel = Instance.new("TextLabel")
                togLabel.Parent = togFrame
                togLabel.BackgroundTransparency = 1
                togLabel.Position = UDim2.new(0, 10, 0, 0)
                togLabel.Size = UDim2.new(0.7, 0, 1, 0)
                togLabel.Font = T.Font
                togLabel.Text = cfg3.Name or "Toggle"
                togLabel.TextColor3 = T.TextPrimary
                togLabel.TextSize = T.SmallTextSize
                togLabel.TextXAlignment = Enum.TextXAlignment.Left

                local togBtn = Instance.new("TextButton")
                togBtn.Parent = togFrame
                togBtn.BackgroundColor3 = togValue and T.Accent or T.ElementHover
                togBtn.Position = UDim2.new(1, -48, 0.5, -8)
                togBtn.Size = UDim2.new(0, 38, 0, 16)
                togBtn.Text = ""
                togBtn.AutoButtonColor = false
                togBtn.BorderSizePixel = 0
                Instance.new("UICorner", togBtn).CornerRadius = UDim.new(1, 0)

                local circle = Instance.new("Frame")
                circle.Parent = togBtn
                circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                circle.Position = togValue and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                circle.Size = UDim2.new(0, 12, 0, 12)
                circle.BorderSizePixel = 0
                Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

                togBtn.MouseButton1Click:Connect(function()
                    togValue = not togValue
                    TweenService:Create(togBtn, TweenInfo.new(0.15), {
                        BackgroundColor3 = togValue and T.Accent or T.ElementHover
                    }):Play()
                    TweenService:Create(circle, TweenInfo.new(0.15), {
                        Position = togValue and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                    }):Play()
                    if cfg3.Callback then safeCallback(cfg3.Callback, togValue) end
                end)

                local stObj = {}
                function stObj:Get() return togValue end
                function stObj:Set(v) togValue = v; togBtn.BackgroundColor3 = v and T.Accent or T.ElementHover; circle.Position = v and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) end
                function stObj:SetVisible(v2) togFrame.Visible = v2 end
                return stObj
            end
        end

        local stObj = {}
        function stObj:GetTab(name)
            return tabContents[name] and tabContents[name].Tab or nil
        end
        function stObj:SwitchTo(idx)
            if tabButtons[idx] then
                for j, btn in ipairs(tabButtons) do
                    contentFrames[j].Visible = j == idx
                    btn.Font = j == idx and T.FontBold or T.FontLight
                    btn.BackgroundTransparency = j == idx and 0 or 1
                    btn.TextColor3 = j == idx and Color3.fromRGB(255, 255, 255) or T.TextMuted
                end
                activeTab = idx
            end
        end
        function stObj:GetActive() return activeTab end
        function stObj:SetVisible(v) frame.Visible = v end
        function stObj:Destroy() frame:Destroy() end
        return stObj
    end
end)

-- =========================================================================
-- SECTION 49: RESPONSIVE HELPERS
-- =========================================================================

function StarLib:GetScreenSize()
    local cam = workspace.CurrentCamera
    if cam then
        return cam.ViewportSize
    end
    return Vector2.new(1920, 1080)
end

function StarLib:IsMobile()
    local size = self:GetScreenSize()
    return size.X < 800 or UserInputService.TouchEnabled
end

function StarLib:IsTablet()
    local size = self:GetScreenSize()
    return size.X >= 800 and size.X < 1200
end

function StarLib:GetScaleFactor()
    local size = self:GetScreenSize()
    if size.X < 800 then return 0.75 end
    if size.X < 1200 then return 0.85 end
    return 1
end

-- =========================================================================
-- SECTION 50: SOUND HELPERS (STUB)
-- =========================================================================

function StarLib:PlaySound(soundId, volume, pitch)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Volume = volume or 0.5
        if pitch then sound.PlaybackSpeed = pitch end
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
end

StarLib.Sounds = {
    Click = 6895079853,
    Toggle = 6895079853,
    Notification = 6895079853,
    Success = 6895079853,
    Error = 6895079853,
    Warning = 6895079853,
}

function StarLib:EnableSounds(enabled)
    self._soundsEnabled = enabled
end

-- =========================================================================
-- SECTION 51: LAYOUT POSITION HELPERS
-- =========================================================================

function StarLib:CenterPosition(width, height)
    return UDim2.new(0.5, -width/2, 0.5, -height/2)
end

function StarLib:TopRight(width, height, margin)
    margin = margin or 10
    return UDim2.new(1, -width - margin, 0, margin)
end

function StarLib:TopLeft(width, height, margin)
    margin = margin or 10
    return UDim2.new(0, margin, 0, margin)
end

function StarLib:BottomRight(width, height, margin)
    margin = margin or 10
    return UDim2.new(1, -width - margin, 1, -height - margin)
end

function StarLib:BottomLeft(width, height, margin)
    margin = margin or 10
    return UDim2.new(0, margin, 1, -height - margin)
end

-- =========================================================================
-- SECTION 52: COLOR PALETTE GENERATORS
-- =========================================================================

function StarLib:GeneratePalette(baseColor, count)
    count = count or 5
    local palette = {}
    local h, s, v = Color3.toHSV(baseColor)

    for i = 1, count do
        local factor = (i - 1) / (count - 1)
        local newV = clamp(0.3 + factor * 0.7, 0, 1)
        table.insert(palette, Color3.fromHSV(h, s, newV))
    end

    return palette
end

function StarLib:GenerateComplementary(baseColor)
    local h, s, v = Color3.toHSV(baseColor)
    return Color3.fromHSV((h + 0.5) % 1, s, v)
end

function StarLib:GenerateTriadic(baseColor)
    local h, s, v = Color3.toHSV(baseColor)
    return {
        baseColor,
        Color3.fromHSV((h + 1/3) % 1, s, v),
        Color3.fromHSV((h + 2/3) % 1, s, v),
    }
end

function StarLib:GenerateAnalogous(baseColor, spread)
    spread = spread or 0.08
    local h, s, v = Color3.toHSV(baseColor)
    return {
        Color3.fromHSV((h - spread) % 1, s, v),
        baseColor,
        Color3.fromHSV((h + spread) % 1, s, v),
    }
end

function StarLib:GenerateMonochromatic(baseColor, count)
    count = count or 5
    local h, s, v = Color3.toHSV(baseColor)
    local colors = {}
    for i = 1, count do
        local factor = (i - 1) / (count - 1)
        table.insert(colors, Color3.fromHSV(h, s * (0.3 + factor * 0.7), v))
    end
    return colors
end

-- =========================================================================
-- SECTION 53: STRING UTILS
-- =========================================================================

StarLib.StringUtils = {}

function StarLib.StringUtils.capitalize(s)
    return s:sub(1, 1):upper() .. s:sub(2)
end

function StarLib.StringUtils.camelCase(s)
    local result = s:gsub("(%a)(%w*)", function(first, rest)
        return first:upper() .. rest:lower()
    end):gsub("%s+", "")
    return result:sub(1, 1):lower() .. result:sub(2)
end

function StarLib.StringUtils.snakeCase(s)
    return s:gsub("%s+", "_"):gsub("(%u)", function(c)
        return "_" .. c:lower()
    end):gsub("^_", ""):lower()
end

function StarLib.StringUtils.kebabCase(s)
    return s:gsub("%s+", "-"):gsub("(%u)", function(c)
        return "-" .. c:lower()
    end):gsub("^-", ""):lower()
end

function StarLib.StringUtils.truncate(s, maxLen, suffix)
    suffix = suffix or "..."
    if #s <= maxLen then return s end
    return s:sub(1, maxLen - #suffix) .. suffix
end

function StarLib.StringUtils.pad(s, len, char, direction)
    char = char or " "
    direction = direction or "right"
    local needed = len - #s
    if needed <= 0 then return s end
    local padding = string.rep(char, needed)
    if direction == "left" then return padding .. s end
    if direction == "center" then
        local left = math.floor(needed / 2)
        return string.rep(char, left) .. s .. string.rep(char, needed - left)
    end
    return s .. padding
end

function StarLib.StringUtils.split(s, delimiter)
    delimiter = delimiter or ","
    local result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

function StarLib.StringUtils.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function StarLib.StringUtils.startsWith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

function StarLib.StringUtils.endsWith(s, suffix)
    return s:sub(-#suffix) == suffix
end

function StarLib.StringUtils.contains(s, substring)
    return s:find(substring, 1, true) ~= nil
end

function StarLib.StringUtils.repeat_(s, n, separator)
    separator = separator or ""
    local parts = {}
    for i = 1, n do parts[i] = s end
    return table.concat(parts, separator)
end

function StarLib.StringUtils.reverse(s)
    return s:reverse()
end

function StarLib.StringUtils.count(s, pattern)
    local c = 0
    for _ in s:gmatch(pattern) do c = c + 1 end
    return c
end

-- =========================================================================
-- SECTION 54: MATH UTILS
-- =========================================================================

StarLib.MathUtils = {}

function StarLib.MathUtils.map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

function StarLib.MathUtils.normalize(value, min, max)
    if max == min then return 0 end
    return (value - min) / (max - min)
end

function StarLib.MathUtils.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function StarLib.MathUtils.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

function StarLib.MathUtils.randomRange(min, max)
    return min + math.random() * (max - min)
end

function StarLib.MathUtils.randomInt(min, max)
    return math.random(min, max)
end

function StarLib.MathUtils.smoothStep(edge0, edge1, x)
    local t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)
end

function StarLib.MathUtils.smootherStep(edge0, edge1, x)
    local t = clamp((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function StarLib.MathUtils.wrap(value, min, max)
    local range = max - min
    return min + ((value - min) % range)
end

function StarLib.MathUtils.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

function StarLib.MathUtils.average(...)
    local values = {...}
    if type(values[1]) == "table" then values = values[1] end
    local sum = 0
    for _, v in ipairs(values) do sum = sum + v end
    return sum / #values
end

function StarLib.MathUtils.median(values)
    local sorted = {}
    for _, v in ipairs(values) do table.insert(sorted, v) end
    table.sort(sorted)
    local n = #sorted
    if n % 2 == 1 then return sorted[math.ceil(n / 2)] end
    return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

function StarLib.MathUtils.sum(values)
    local s = 0
    for _, v in ipairs(values) do s = s + v end
    return s
end

function StarLib.MathUtils.min(values)
    local m = values[1]
    for _, v in ipairs(values) do if v < m then m = v end end
    return m
end

function StarLib.MathUtils.max(values)
    local m = values[1]
    for _, v in ipairs(values) do if v > m then m = v end end
    return m
end

function StarLib.MathUtils.fibonacci(n)
    if n <= 0 then return 0 end
    if n == 1 then return 1 end
    local a, b = 0, 1
    for _ = 2, n do a, b = b, a + b end
    return b
end

function StarLib.MathUtils.factorial(n)
    if n <= 1 then return 1 end
    local result = 1
    for i = 2, n do result = result * i end
    return result
end

function StarLib.MathUtils.isPrime(n)
    if n < 2 then return false end
    if n < 4 then return true end
    if n % 2 == 0 or n % 3 == 0 then return false end
    local i = 5
    while i * i <= n do
        if n % i == 0 or n % (i + 2) == 0 then return false end
        i = i + 6
    end
    return true
end

-- =========================================================================
-- SECTION 55: TABLE UTILS EXTENDED
-- =========================================================================

StarLib.TableUtils = {}

function StarLib.TableUtils.map(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v, i)
    end
    return result
end

function StarLib.TableUtils.filter(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        if fn(v, i) then table.insert(result, v) end
    end
    return result
end

function StarLib.TableUtils.reduce(tbl, fn, initial)
    local acc = initial
    for i, v in ipairs(tbl) do
        if acc == nil and i == 1 then
            acc = v
        else
            acc = fn(acc, v, i)
        end
    end
    return acc
end

function StarLib.TableUtils.find(tbl, fn)
    for i, v in ipairs(tbl) do
        if fn(v, i) then return v, i end
    end
    return nil
end

function StarLib.TableUtils.findIndex(tbl, fn)
    for i, v in ipairs(tbl) do
        if fn(v, i) then return i end
    end
    return nil
end

function StarLib.TableUtils.every(tbl, fn)
    for i, v in ipairs(tbl) do
        if not fn(v, i) then return false end
    end
    return true
end

function StarLib.TableUtils.some(tbl, fn)
    for i, v in ipairs(tbl) do
        if fn(v, i) then return true end
    end
    return false
end

function StarLib.TableUtils.flatten(tbl, depth)
    depth = depth or 1
    local result = {}
    for _, v in ipairs(tbl) do
        if type(v) == "table" and depth > 0 then
            for _, inner in ipairs(StarLib.TableUtils.flatten(v, depth - 1)) do
                table.insert(result, inner)
            end
        else
            table.insert(result, v)
        end
    end
    return result
end

function StarLib.TableUtils.unique(tbl)
    local seen = {}
    local result = {}
    for _, v in ipairs(tbl) do
        local key = tostring(v)
        if not seen[key] then
            seen[key] = true
            table.insert(result, v)
        end
    end
    return result
end

function StarLib.TableUtils.groupBy(tbl, fn)
    local groups = {}
    for _, v in ipairs(tbl) do
        local key = fn(v)
        if not groups[key] then groups[key] = {} end
        table.insert(groups[key], v)
    end
    return groups
end

function StarLib.TableUtils.sortBy(tbl, key, ascending)
    ascending = ascending ~= false
    local copy = {}
    for _, v in ipairs(tbl) do table.insert(copy, v) end
    table.sort(copy, function(a, b)
        local va = type(key) == "function" and key(a) or a[key]
        local vb = type(key) == "function" and key(b) or b[key]
        if ascending then return va < vb end
        return va > vb
    end)
    return copy
end

function StarLib.TableUtils.chunk(tbl, size)
    local chunks = {}
    for i = 1, #tbl, size do
        local chunk = {}
        for j = i, math.min(i + size - 1, #tbl) do
            table.insert(chunk, tbl[j])
        end
        table.insert(chunks, chunk)
    end
    return chunks
end

function StarLib.TableUtils.zip(...)
    local arrays = {...}
    local result = {}
    local maxLen = 0
    for _, arr in ipairs(arrays) do
        maxLen = math.max(maxLen, #arr)
    end
    for i = 1, maxLen do
        local entry = {}
        for _, arr in ipairs(arrays) do
            table.insert(entry, arr[i])
        end
        table.insert(result, entry)
    end
    return result
end

function StarLib.TableUtils.reverse(tbl)
    local result = {}
    for i = #tbl, 1, -1 do
        table.insert(result, tbl[i])
    end
    return result
end

function StarLib.TableUtils.shuffle(tbl)
    local result = {}
    for _, v in ipairs(tbl) do table.insert(result, v) end
    for i = #result, 2, -1 do
        local j = math.random(1, i)
        result[i], result[j] = result[j], result[i]
    end
    return result
end

function StarLib.TableUtils.count(tbl, fn)
    local c = 0
    for i, v in ipairs(tbl) do
        if fn(v, i) then c = c + 1 end
    end
    return c
end

function StarLib.TableUtils.sample(tbl, n)
    n = n or 1
    local shuffled = StarLib.TableUtils.shuffle(tbl)
    local result = {}
    for i = 1, math.min(n, #shuffled) do
        table.insert(result, shuffled[i])
    end
    return result
end

function StarLib.TableUtils.difference(tbl1, tbl2)
    local set = {}
    for _, v in ipairs(tbl2) do set[tostring(v)] = true end
    return StarLib.TableUtils.filter(tbl1, function(v)
        return not set[tostring(v)]
    end)
end

function StarLib.TableUtils.intersection(tbl1, tbl2)
    local set = {}
    for _, v in ipairs(tbl2) do set[tostring(v)] = true end
    return StarLib.TableUtils.filter(tbl1, function(v)
        return set[tostring(v)]
    end)
end

function StarLib.TableUtils.union(tbl1, tbl2)
    local result = {}
    local seen = {}
    for _, v in ipairs(tbl1) do
        if not seen[tostring(v)] then
            seen[tostring(v)] = true
            table.insert(result, v)
        end
    end
    for _, v in ipairs(tbl2) do
        if not seen[tostring(v)] then
            seen[tostring(v)] = true
            table.insert(result, v)
        end
    end
    return result
end

-- =========================================================================
-- SECTION 56: WINDOW PRESET SHORTCUTS
-- =========================================================================

function StarLib:CreateMinimalWindow(config)
    config = config or {}
    config.Size = config.Size or UDim2.new(0, 350, 0, 300)
    config.ShowMinimize = config.ShowMinimize ~= false
    config.ShowClose = config.ShowClose ~= false
    return self:CreateWindow(config)
end

function StarLib:CreateFullWindow(config)
    config = config or {}
    config.Size = config.Size or UDim2.new(0, 650, 0, 500)
    config.ShowMinimize = true
    config.ShowClose = true
    return self:CreateWindow(config)
end

function StarLib:CreateCompactWindow(config)
    config = config or {}
    config.Size = config.Size or UDim2.new(0, 280, 0, 200)
    config.ShowMinimize = true
    config.ShowClose = true
    return self:CreateWindow(config)
end

-- =========================================================================
-- SECTION 57: TIMER / INTERVAL MANAGER
-- =========================================================================

function StarLib:CreateTimerManager()
    local timers = {}
    local nextId = 0

    local mgr = {}

    function mgr:SetTimeout(callback, delayMs)
        nextId = nextId + 1
        local id = nextId
        local cancelled = false
        timers[id] = { type = "timeout", cancelled = false }

        task.delay(delayMs / 1000, function()
            if not cancelled and timers[id] and not timers[id].cancelled then
                safeCallback(callback)
                timers[id] = nil
            end
        end)

        return id
    end

    function mgr:SetInterval(callback, intervalMs)
        nextId = nextId + 1
        local id = nextId
        timers[id] = { type = "interval", cancelled = false }

        task.spawn(function()
            while timers[id] and not timers[id].cancelled do
                task.wait(intervalMs / 1000)
                if timers[id] and not timers[id].cancelled then
                    safeCallback(callback)
                end
            end
        end)

        return id
    end

    function mgr:Clear(id)
        if timers[id] then
            timers[id].cancelled = true
            timers[id] = nil
        end
    end

    function mgr:ClearAll()
        for id, timer in pairs(timers) do
            timer.cancelled = true
        end
        timers = {}
    end

    function mgr:GetActive()
        local count = 0
        for _ in pairs(timers) do count = count + 1 end
        return count
    end

    return mgr
end

-- =========================================================================
-- SECTION 58: SPRITE SHEET / IMAGE HELPERS
-- =========================================================================

function StarLib:CreateImageLabel(parent, config)
    config = config or {}
    local img = Instance.new("ImageLabel")
    img.Parent = parent
    img.BackgroundTransparency = config.BackgroundTransparency or 1
    img.Image = config.Image or ""
    img.Size = config.Size or UDim2.new(0, 32, 0, 32)
    img.Position = config.Position or UDim2.new(0, 0, 0, 0)
    img.ImageColor3 = config.Color or Color3.fromRGB(255, 255, 255)
    img.ImageTransparency = config.Transparency or 0
    img.ScaleType = config.ScaleType or Enum.ScaleType.Fit
    img.BorderSizePixel = 0

    if config.CornerRadius then
        Instance.new("UICorner", img).CornerRadius = config.CornerRadius
    end

    return img
end

function StarLib:CreateImageButton(parent, config)
    config = config or {}
    local btn = Instance.new("ImageButton")
    btn.Parent = parent
    btn.BackgroundTransparency = config.BackgroundTransparency or 1
    btn.Image = config.Image or ""
    btn.Size = config.Size or UDim2.new(0, 32, 0, 32)
    btn.Position = config.Position or UDim2.new(0, 0, 0, 0)
    btn.ImageColor3 = config.Color or Color3.fromRGB(255, 255, 255)
    btn.ScaleType = config.ScaleType or Enum.ScaleType.Fit
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0

    if config.CornerRadius then
        Instance.new("UICorner", btn).CornerRadius = config.CornerRadius
    end

    if config.HoverImage then
        btn.MouseEnter:Connect(function() btn.Image = config.HoverImage end)
        btn.MouseLeave:Connect(function() btn.Image = config.Image or "" end)
    end

    if config.Callback then
        btn.MouseButton1Click:Connect(function()
            safeCallback(config.Callback)
        end)
    end

    return btn
end

-- =========================================================================
-- SECTION 59: PROGRESS TRACKER WIDGET
-- =========================================================================

StarLib:RegisterTabExtension("CreateProgressTracker", function(Tab, container, T, W, nextOrder)
    return function(self, cfg2)
        local steps = cfg2.Steps or {}
        local currentStep = cfg2.CurrentStep or 1

        local frame = Instance.new("Frame")
        frame.Parent = container
        frame.BackgroundColor3 = T.ElementBG
        frame.Size = UDim2.new(1, 0, 0, 0)
        frame.AutomaticSize = Enum.AutomaticSize.Y
        frame.LayoutOrder = nextOrder()
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = T.ElementRadius

        local fPad = Instance.new("UIPadding", frame)
        fPad.PaddingLeft = UDim.new(0, 12)
        fPad.PaddingRight = UDim.new(0, 12)
        fPad.PaddingTop = UDim.new(0, 10)
        fPad.PaddingBottom = UDim.new(0, 10)

        local fLayout = Instance.new("UIListLayout", frame)
        fLayout.Padding = UDim.new(0, 0)

        if cfg2.Name then
            local titleLbl = Instance.new("TextLabel")
            titleLbl.Parent = frame
            titleLbl.BackgroundTransparency = 1
            titleLbl.Size = UDim2.new(1, 0, 0, 22)
            titleLbl.Font = T.FontBold
            titleLbl.Text = cfg2.Name
            titleLbl.TextColor3 = T.TextPrimary
            titleLbl.TextSize = T.TextSize
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        local progressBar = Instance.new("Frame")
        progressBar.Parent = frame
        progressBar.BackgroundColor3 = T.ElementHover
        progressBar.Size = UDim2.new(1, 0, 0, 4)
        progressBar.BorderSizePixel = 0
        Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 2)

        local progressFill = Instance.new("Frame")
        progressFill.Parent = progressBar
        progressFill.BackgroundColor3 = T.Accent
        progressFill.Size = UDim2.new(math.max(0, (currentStep - 1) / math.max(#steps - 1, 1)), 0, 1, 0)
        progressFill.BorderSizePixel = 0
        Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 2)

        local stepsContainer = Instance.new("Frame")
        stepsContainer.Parent = frame
        stepsContainer.BackgroundTransparency = 1
        stepsContainer.Size = UDim2.new(1, 0, 0, 0)
        stepsContainer.AutomaticSize = Enum.AutomaticSize.Y

        local scLayout = Instance.new("UIListLayout", stepsContainer)
        scLayout.Padding = UDim.new(0, 4)
        local scPad = Instance.new("UIPadding", stepsContainer)
        scPad.PaddingTop = UDim.new(0, 8)

        local stepLabels = {}

        for i, stepName in ipairs(steps) do
            local stepFrame = Instance.new("Frame")
            stepFrame.Parent = stepsContainer
            stepFrame.BackgroundTransparency = 1
            stepFrame.Size = UDim2.new(1, 0, 0, 22)

            local indicator = Instance.new("Frame")
            indicator.Parent = stepFrame
            indicator.Size = UDim2.new(0, 16, 0, 16)
            indicator.Position = UDim2.new(0, 0, 0.5, -8)
            indicator.BorderSizePixel = 0
            if i < currentStep then
                indicator.BackgroundColor3 = T.Success
            elseif i == currentStep then
                indicator.BackgroundColor3 = T.Accent
            else
                indicator.BackgroundColor3 = T.ElementHover
            end
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

            if i < currentStep then
                local checkLbl = Instance.new("TextLabel")
                checkLbl.Parent = indicator
                checkLbl.BackgroundTransparency = 1
                checkLbl.Size = UDim2.new(1, 0, 1, 0)
                checkLbl.Font = T.FontBold
                checkLbl.Text = "✓"
                checkLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                checkLbl.TextSize = 10
            elseif i == currentStep then
                local dotLbl = Instance.new("Frame")
                dotLbl.Parent = indicator
                dotLbl.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                dotLbl.AnchorPoint = Vector2.new(0.5, 0.5)
                dotLbl.Position = UDim2.new(0.5, 0, 0.5, 0)
                dotLbl.Size = UDim2.new(0, 6, 0, 6)
                dotLbl.BorderSizePixel = 0
                Instance.new("UICorner", dotLbl).CornerRadius = UDim.new(1, 0)
            end

            local stepLbl = Instance.new("TextLabel")
            stepLbl.Parent = stepFrame
            stepLbl.BackgroundTransparency = 1
            stepLbl.Position = UDim2.new(0, 24, 0, 0)
            stepLbl.Size = UDim2.new(1, -24, 1, 0)
            stepLbl.Font = i == currentStep and T.FontBold or T.FontLight
            stepLbl.Text = stepName
            stepLbl.TextColor3 = i <= currentStep and T.TextPrimary or T.TextMuted
            stepLbl.TextSize = T.SmallTextSize
            stepLbl.TextXAlignment = Enum.TextXAlignment.Left

            stepLabels[i] = { frame = stepFrame, indicator = indicator, label = stepLbl }
        end

        local percentLabel = Instance.new("TextLabel")
        percentLabel.Parent = frame
        percentLabel.BackgroundTransparency = 1
        percentLabel.Size = UDim2.new(1, 0, 0, 18)
        percentLabel.Font = T.FontLight
        percentLabel.Text = math.floor((currentStep - 1) / math.max(#steps - 1, 1) * 100) .. "% complete"
        percentLabel.TextColor3 = T.TextMuted
        percentLabel.TextSize = T.TinyTextSize
        percentLabel.TextXAlignment = Enum.TextXAlignment.Right

        local ptObj = {}
        function ptObj:SetStep(step)
            currentStep = clamp(step, 1, #steps)
            local progress = math.max(0, (currentStep - 1) / math.max(#steps - 1, 1))
            TweenService:Create(progressFill, TweenInfo.new(0.3), {
                Size = UDim2.new(progress, 0, 1, 0)
            }):Play()
            percentLabel.Text = math.floor(progress * 100) .. "% complete"

            for i, data in ipairs(stepLabels) do
                if i < currentStep then
                    data.indicator.BackgroundColor3 = T.Success
                elseif i == currentStep then
                    data.indicator.BackgroundColor3 = T.Accent
                else
                    data.indicator.BackgroundColor3 = T.ElementHover
                end
                data.label.Font = i == currentStep and T.FontBold or T.FontLight
                data.label.TextColor3 = i <= currentStep and T.TextPrimary or T.TextMuted
            end

            if cfg2.OnStepChanged then safeCallback(cfg2.OnStepChanged, currentStep, steps[currentStep]) end
        end
        function ptObj:Next()
            if currentStep < #steps then ptObj:SetStep(currentStep + 1) end
        end
        function ptObj:Previous()
            if currentStep > 1 then ptObj:SetStep(currentStep - 1) end
        end
        function ptObj:Complete() ptObj:SetStep(#steps) end
        function ptObj:Reset() ptObj:SetStep(1) end
        function ptObj:GetStep() return currentStep end
        function ptObj:SetVisible(v) frame.Visible = v end
        function ptObj:Destroy() frame:Destroy() end
        return ptObj
    end
end)

-- =========================================================================
-- SECTION 60: FINALIZE & RETURN
-- =========================================================================

debugLog("StarLib v" .. STARLIB_VERSION .. " loaded successfully")
debugLog("Loaded " .. #tableKeys(_tabExtensions) .. " tab extensions")
debugLog("Available theme presets: " .. table.concat(tableKeys(THEME_PRESETS), ", "))

return StarLib
