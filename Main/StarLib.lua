--!nocheck
-- StarLib v2 - rewritten with Rayfield-style systems

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

local function new(className, props)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    return obj
end

local function hasExecutorFs()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
    if type(makefolder) == "function" and type(isfolder) == "function" then
        if not isfolder(path) then
            safeCall(makefolder, path)
        end
    end
end

local function encodeJSON(value)
    return safeCall(function()
        return HttpService:JSONEncode(value)
    end)
end

local function decodeJSON(value)
    return safeCall(function()
        return HttpService:JSONDecode(value)
    end)
end

local function deepCopy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            out[k] = deepCopy(v)
        else
            out[k] = v
        end
    end
    return out
end

local function deepMerge(base, override)
    local out = deepCopy(base)
    if type(override) ~= "table" then
        return out
    end
    for k, v in pairs(override) do
        if type(v) == "table" and type(out[k]) == "table" then
            out[k] = deepMerge(out[k], v)
        else
            out[k] = v
        end
    end
    return out
end

local function normalizeColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    return fallback
end

local Themes = {
    Default = {
        Background = Color3.fromRGB(24, 24, 24),
        Topbar = Color3.fromRGB(30, 30, 30),
        Sidebar = Color3.fromRGB(31, 31, 31),
        TabDefault = Color3.fromRGB(41, 41, 41),
        TabActive = Color3.fromRGB(57, 57, 57),
        ElementBackground = Color3.fromRGB(38, 38, 38),
        ElementHover = Color3.fromRGB(50, 50, 50),
        InputBackground = Color3.fromRGB(29, 29, 29),
        Text = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(182, 182, 182),
        Accent = Color3.fromRGB(0, 170, 255),
        ToggleOff = Color3.fromRGB(66, 66, 66),
        NotificationBackground = Color3.fromRGB(34, 34, 34),
    },
    Ocean = {
        Background = Color3.fromRGB(14, 20, 33),
        Topbar = Color3.fromRGB(18, 30, 48),
        Sidebar = Color3.fromRGB(17, 27, 44),
        TabDefault = Color3.fromRGB(23, 37, 59),
        TabActive = Color3.fromRGB(36, 57, 88),
        ElementBackground = Color3.fromRGB(27, 40, 62),
        ElementHover = Color3.fromRGB(34, 52, 80),
        InputBackground = Color3.fromRGB(17, 30, 49),
        Text = Color3.fromRGB(240, 246, 255),
        SubText = Color3.fromRGB(169, 189, 214),
        Accent = Color3.fromRGB(48, 164, 255),
        ToggleOff = Color3.fromRGB(64, 85, 118),
        NotificationBackground = Color3.fromRGB(24, 36, 56),
    },
    Forest = {
        Background = Color3.fromRGB(19, 26, 19),
        Topbar = Color3.fromRGB(27, 39, 27),
        Sidebar = Color3.fromRGB(24, 36, 24),
        TabDefault = Color3.fromRGB(30, 46, 30),
        TabActive = Color3.fromRGB(41, 63, 41),
        ElementBackground = Color3.fromRGB(33, 49, 33),
        ElementHover = Color3.fromRGB(42, 62, 42),
        InputBackground = Color3.fromRGB(23, 36, 23),
        Text = Color3.fromRGB(237, 247, 237),
        SubText = Color3.fromRGB(173, 201, 173),
        Accent = Color3.fromRGB(70, 194, 108),
        ToggleOff = Color3.fromRGB(65, 89, 65),
        NotificationBackground = Color3.fromRGB(28, 40, 28),
    },
    Crimson = {
        Background = Color3.fromRGB(24, 15, 18),
        Topbar = Color3.fromRGB(35, 18, 24),
        Sidebar = Color3.fromRGB(30, 17, 21),
        TabDefault = Color3.fromRGB(47, 24, 32),
        TabActive = Color3.fromRGB(68, 30, 43),
        ElementBackground = Color3.fromRGB(47, 24, 32),
        ElementHover = Color3.fromRGB(61, 28, 39),
        InputBackground = Color3.fromRGB(33, 19, 23),
        Text = Color3.fromRGB(255, 241, 244),
        SubText = Color3.fromRGB(217, 167, 177),
        Accent = Color3.fromRGB(228, 69, 93),
        ToggleOff = Color3.fromRGB(97, 56, 66),
        NotificationBackground = Color3.fromRGB(39, 22, 29),
    },
    Midnight = {
        Background = Color3.fromRGB(13, 14, 24),
        Topbar = Color3.fromRGB(20, 22, 36),
        Sidebar = Color3.fromRGB(18, 20, 33),
        TabDefault = Color3.fromRGB(25, 28, 44),
        TabActive = Color3.fromRGB(39, 43, 68),
        ElementBackground = Color3.fromRGB(31, 34, 52),
        ElementHover = Color3.fromRGB(39, 43, 64),
        InputBackground = Color3.fromRGB(22, 24, 39),
        Text = Color3.fromRGB(238, 240, 255),
        SubText = Color3.fromRGB(159, 167, 204),
        Accent = Color3.fromRGB(140, 122, 255),
        ToggleOff = Color3.fromRGB(74, 80, 120),
        NotificationBackground = Color3.fromRGB(25, 27, 42),
    },
    Amethyst = {
        Background = Color3.fromRGB(24, 19, 33),
        Topbar = Color3.fromRGB(33, 25, 45),
        Sidebar = Color3.fromRGB(29, 22, 40),
        TabDefault = Color3.fromRGB(40, 31, 56),
        TabActive = Color3.fromRGB(57, 43, 78),
        ElementBackground = Color3.fromRGB(43, 33, 58),
        ElementHover = Color3.fromRGB(56, 44, 73),
        InputBackground = Color3.fromRGB(33, 26, 45),
        Text = Color3.fromRGB(248, 241, 255),
        SubText = Color3.fromRGB(189, 167, 214),
        Accent = Color3.fromRGB(193, 120, 255),
        ToggleOff = Color3.fromRGB(84, 67, 106),
        NotificationBackground = Color3.fromRGB(37, 29, 50),
    },
    Light = {
        Background = Color3.fromRGB(241, 244, 248),
        Topbar = Color3.fromRGB(230, 235, 243),
        Sidebar = Color3.fromRGB(234, 239, 246),
        TabDefault = Color3.fromRGB(223, 229, 238),
        TabActive = Color3.fromRGB(206, 214, 227),
        ElementBackground = Color3.fromRGB(223, 229, 238),
        ElementHover = Color3.fromRGB(207, 216, 230),
        InputBackground = Color3.fromRGB(250, 251, 254),
        Text = Color3.fromRGB(24, 27, 36),
        SubText = Color3.fromRGB(74, 85, 105),
        Accent = Color3.fromRGB(47, 102, 224),
        ToggleOff = Color3.fromRGB(164, 176, 196),
        NotificationBackground = Color3.fromRGB(219, 226, 237),
    },
}

local DEFAULT_CONFIG = {
    Name = "StarLib Interface",
    LoadingTitle = "StarLib",
    LoadingSubtitle = "Loading...",
    Theme = "Default",
    ThemeOverrides = nil,
    Icon = "",
    ToggleKey = Enum.KeyCode.RightShift,
    Resizable = true,
    EnableSearch = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "StarLib",
        FileName = "config.json",
    },
    KeySystem = {
        Enabled = false,
        Title = "StarLib Key System",
        Subtitle = "Enter your access key",
        Note = "",
        SaveKey = "LastKey",
        GrabKeyFromSite = false,
        KeyUrl = "",
        Keys = { "STARDUST" },
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true,
    },
    Monetization = {
        Enabled = false,
        Strategy = "Donations",
        Details = "",
    },
}

local function buildTheme(name, overrides)
    local base = Themes[name] or Themes.Default
    local out = deepCopy(base)
    if type(overrides) == "table" then
        for k, v in pairs(overrides) do
            if out[k] ~= nil then
                out[k] = normalizeColor(v, out[k])
            end
        end
    end
    return out
end

local function detectExecutor()
    local env = (type(getfenv) == "function" and getfenv()) or _G
    local candidates = {
        "identifyexecutor",
        "getexecutorname",
    }
    for _, fnName in ipairs(candidates) do
        local fn = env and rawget(env, fnName)
        if type(fn) == "function" then
            local ok, result = pcall(fn)
            if ok and result then
                return tostring(result)
            end
        end
    end
    if syn then
        return "Synapse-like"
    end
    return "Unknown"
end

local function requestText(url)
    if type(url) ~= "string" or url == "" then
        return nil
    end
    local env = (type(getfenv) == "function" and getfenv()) or _G
    local req = (env and rawget(env, "request"))
        or (env and rawget(env, "http_request"))
        or (syn and syn.request)
    if type(req) ~= "function" then
        return nil
    end
    local ok, response = pcall(req, { Url = url, Method = "GET" })
    if not ok or type(response) ~= "table" then
        return nil
    end
    if response.Success == false then
        return nil
    end
    return response.Body
end

local function isImageIcon(icon)
    if type(icon) ~= "string" then
        return false
    end
    return string.find(icon, "rbxasset", 1, true) ~= nil
        or string.find(icon, "http", 1, true) ~= nil
end

local function toSerializable(value)
    if typeof(value) == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    elseif type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = toSerializable(v)
        end
        return out
    end
    return value
end

local function fromSerializable(value)
    if type(value) == "table" and value.__type == "Color3" then
        return Color3.new(value.r, value.g, value.b)
    elseif type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            out[k] = fromSerializable(v)
        end
        return out
    end
    return value
end

local function tween(obj, info, props)
    safeCall(function()
        TweenService:Create(obj, info, props):Play()
    end)
end

local function getGuiParent()
    if type(gethui) == "function" then
        local holder = safeCall(gethui)
        if holder then
            return holder
        end
    end
    return CoreGui
end

local StarLib = {
    _windows = {},
    _analytics = {
        Sessions = 0,
        Elements = {},
    },
    ThemePresets = Themes,
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local function track(window, category, name)
    window._analytics[category] = window._analytics[category] or {}
    window._analytics[category][name] = (window._analytics[category][name] or 0) + 1
end

local function createNotificationContainer(gui)
    local holder = new("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -330, 0, 10),
        Parent = gui,
    })
    local layout = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = holder,
    })
    return holder, layout
end

function Window:Notify(config)
    local title = (config and config.Title) or "Notification"
    local content = (config and config.Content) or ""
    local duration = (config and config.Duration) or 4
    local notifType = (config and config.Type) or "info"

    local box = new("Frame", {
        BackgroundColor3 = self.Theme.NotificationBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 72),
        Parent = self._notificationHolder,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = box })
    new("UIStroke", { Color = self.Theme.ElementHover, Thickness = 1, Parent = box })

    local accent = self.Theme.Accent
    if notifType == "success" then
        accent = Color3.fromRGB(68, 204, 118)
    elseif notifType == "warning" then
        accent = Color3.fromRGB(240, 178, 45)
    elseif notifType == "error" then
        accent = Color3.fromRGB(235, 88, 88)
    end

    new("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 4, 1, 0),
        Parent = box,
    })

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -16, 0, 20),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = self.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
        Parent = box,
    })

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 30),
        Size = UDim2.new(1, -16, 0, 34),
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextSize = 12,
        TextColor3 = self.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = content,
        Parent = box,
    })

    local progress = new("Frame", {
        BackgroundColor3 = accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = box,
    })

    tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
    task.delay(duration, function()
        if box.Parent then
            tween(box, TweenInfo.new(0.2), { BackgroundTransparency = 1, Position = box.Position + UDim2.new(0, 20, 0, 0) })
            task.delay(0.22, function()
                if box then
                    box:Destroy()
                end
            end)
        end
    end)
end

function Window:_configPath()
    local cfg = self.Config.ConfigurationSaving
    return cfg.FolderName .. "/" .. cfg.FileName
end

function Window:SaveConfiguration()
    if not self.Config.ConfigurationSaving.Enabled or not hasExecutorFs() then
        return
    end

    ensureFolder(self.Config.ConfigurationSaving.FolderName)
    local payload = {
        Flags = toSerializable(self._flags),
    }
    local json = encodeJSON(payload)
    if json then
        safeCall(writefile, self:_configPath(), json)
    end
end

function Window:LoadConfiguration()
    if not self.Config.ConfigurationSaving.Enabled or not hasExecutorFs() then
        return {}
    end
    local path = self:_configPath()
    if not isfile(path) then
        return {}
    end
    local data = decodeJSON(readfile(path))
    if type(data) == "table" and type(data.Flags) == "table" then
        return fromSerializable(data.Flags)
    end
    return {}
end

function Window:_rememberDiscordJoin()
    if not hasExecutorFs() then
        return false
    end
    local folder = self.Config.ConfigurationSaving.FolderName
    ensureFolder(folder)
    local path = folder .. "/discord_joined.json"
    if isfile(path) then
        local decoded = decodeJSON(readfile(path))
        if type(decoded) == "table" and decoded.Invite == self.Config.Discord.Invite then
            return true
        end
    end
    local payload = encodeJSON({ Invite = self.Config.Discord.Invite, Time = os.time() })
    if payload then
        safeCall(writefile, path, payload)
    end
    return false
end

function Window:_applySearch()
    local term = string.lower(self._searchTerm or "")
    for _, tab in ipairs(self._tabs) do
        local shouldFilter = (tab == self._activeTab)
        for _, element in ipairs(tab._elements) do
            local visible = true
            if shouldFilter then
                visible = term == "" or string.find(element._search, term, 1, true) ~= nil
            end
            element._container.Visible = visible
        end
    end
end

function Window:_refreshLayout(instant)
    if not self._layoutRefs then
        return
    end
    local refs = self._layoutRefs
    local sidebarWidth = self._sidebarExpanded and self._sidebarExpandedWidth or self._sidebarCollapsedWidth
    local pageX = sidebarWidth + refs.pageGap
    local pageOffset = -(pageX + refs.pageRightPadding)

    local sidebarSize = UDim2.fromOffset(sidebarWidth, refs.bodyHeight)
    local pagePos = UDim2.fromOffset(pageX, refs.pageTopPadding)
    local pageSize = UDim2.new(1, pageOffset, 1, -(refs.pageTopPadding + refs.pageBottomPadding))

    if instant then
        refs.sidebar.Size = sidebarSize
        refs.pageHolder.Position = pagePos
        refs.pageHolder.Size = pageSize
    else
        tween(refs.sidebar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = sidebarSize })
        tween(refs.pageHolder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = pagePos,
            Size = pageSize,
        })
    end

    refs.tabButtons.Visible = self._sidebarExpanded
end

function Window:_setSidebarExpanded(expanded, instant)
    if self._sidebarExpanded == expanded then
        return
    end
    self._sidebarExpanded = expanded
    self:_refreshLayout(instant)
end

function Window:_setupSidebarAutoHide()
    if not self._layoutRefs then
        return
    end
    local refs = self._layoutRefs
    local hoverPadding = 34
    local edgePadding = 22

    self._sidebarHoverConn = RunService.RenderStepped:Connect(function()
        if not self._main.Visible then
            return
        end
        local mouse = UserInputService:GetMouseLocation()
        local mainPos = self._main.AbsolutePosition
        local mainSize = self._main.AbsoluteSize
        local inY = mouse.Y >= mainPos.Y and mouse.Y <= (mainPos.Y + mainSize.Y)
        if not inY then
            self:_setSidebarExpanded(false, false)
            return
        end

        local nearLeftEdge = mouse.X <= (mainPos.X + edgePadding)
        local overSidebarZone = mouse.X <= (mainPos.X + refs.sidebar.AbsoluteSize.X + hoverPadding)
        local shouldExpand = nearLeftEdge or overSidebarZone
        self:_setSidebarExpanded(shouldExpand, false)
    end)
end

function Window:_setFlag(flag, value)
    if flag and flag ~= "" then
        self._flags[flag] = value
        if self.Config.ConfigurationSaving.Enabled then
            self:SaveConfiguration()
        end
    end
end

function Window:Show()
    self._main.Visible = true
end

function Window:Hide()
    self._main.Visible = false
end

function Window:Toggle()
    self._main.Visible = not self._main.Visible
end

function Window:Destroy()
    if self._toggleConn then
        self._toggleConn:Disconnect()
    end
    if self._inputConn then
        self._inputConn:Disconnect()
    end
    if self._sidebarHoverConn then
        self._sidebarHoverConn:Disconnect()
    end
    self.Gui:Destroy()
end

function Window:GetAnalyticsSnapshot()
    return deepCopy(self._analytics)
end

function Window:OpenAnalyticsDashboard()
    local tab = self:CreateTab({ Name = "Analytics", Icon = "bar-chart-3" })
    tab:CreateParagraph({
        Title = "Developer Analytics",
        Content = "Per-element interactions this session:",
    })
    for category, bucket in pairs(self._analytics) do
        if type(bucket) == "table" then
            for name, count in pairs(bucket) do
                tab:CreateStat({ Name = category .. " / " .. name, Value = tostring(count) })
            end
        else
            tab:CreateStat({ Name = category, Value = tostring(bucket) })
        end
    end
    return tab
end

function Window:SetTheme(themeName, overrides)
    local nextTheme = buildTheme(themeName, overrides or self.Config.ThemeOverrides)
    self.Theme = nextTheme
    self.Config.Theme = themeName
    if overrides then
        self.Config.ThemeOverrides = overrides
    end
    if self._themeRefs then
        local refs = self._themeRefs
        refs.main.BackgroundColor3 = nextTheme.Background
        refs.topbar.BackgroundColor3 = nextTheme.Topbar
        refs.sidebar.BackgroundColor3 = nextTheme.Sidebar
        refs.title.TextColor3 = nextTheme.Text
        if refs.search then
            refs.search.BackgroundColor3 = nextTheme.InputBackground
            refs.search.TextColor3 = nextTheme.Text
            refs.search.PlaceholderColor3 = nextTheme.SubText
        end
        for _, tab in ipairs(self._tabs) do
            tab._button.BackgroundColor3 = (self._activeTab == tab) and nextTheme.TabActive or nextTheme.TabDefault
            tab._button.TextColor3 = nextTheme.Text
        end
    end
    self:Notify({
        Title = "Theme Changed",
        Content = "Theme switched to " .. tostring(themeName),
        Type = "info",
    })
end

local function createKeySystemGate(window)
    local ks = window.Config.KeySystem
    if not ks.Enabled then
        return true
    end

    local gate = new("Frame", {
        BackgroundColor3 = window.Theme.Background,
        Size = UDim2.fromScale(1, 1),
        Parent = window.Gui,
    })

    local box = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 210),
        BackgroundColor3 = window.Theme.Topbar,
        BorderSizePixel = 0,
        Parent = gate,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = box })
    new("UIStroke", { Color = window.Theme.ElementHover, Thickness = 1, Parent = box })

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.fromOffset(328, 26),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Text = ks.Title,
        TextColor3 = window.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 42),
        Size = UDim2.fromOffset(328, 20),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = ks.Subtitle,
        TextColor3 = window.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })

    local input = new("TextBox", {
        Position = UDim2.fromOffset(16, 76),
        Size = UDim2.fromOffset(328, 34),
        BackgroundColor3 = window.Theme.InputBackground,
        TextColor3 = window.Theme.Text,
        PlaceholderText = "Enter key here",
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        Parent = box,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = input })

    local status = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 154),
        Size = UDim2.fromOffset(328, 20),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Text = ks.Note,
        TextColor3 = window.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })

    local submit = new("TextButton", {
        Position = UDim2.fromOffset(16, 118),
        Size = UDim2.fromOffset(328, 30),
        BackgroundColor3 = window.Theme.Accent,
        Text = "Unlock",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Parent = box,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = submit })

    local function isValid(inputKey)
        for _, k in ipairs(ks.Keys) do
            if tostring(k) == tostring(inputKey) then
                return true
            end
        end
        return false
    end

    local unlocked = false

    local savedKey = nil
    if ks.SaveKey and ks.SaveKey ~= "" then
        savedKey = window._loadedFlags[ks.SaveKey]
    end
    if savedKey and isValid(savedKey) then
        gate:Destroy()
        return true
    end

    if ks.GrabKeyFromSite and ks.KeyUrl ~= "" then
        local body = requestText(ks.KeyUrl)
        if body then
            local firstLine = tostring(body):match("([^\r\n]+)")
            if firstLine and isValid(firstLine) then
                input.Text = firstLine
            end
        end
    end
    submit.MouseButton1Click:Connect(function()
        if isValid(input.Text) then
            unlocked = true
            if ks.SaveKey ~= "" then
                window:_setFlag(ks.SaveKey, input.Text)
            end
            gate:Destroy()
        else
            status.TextColor3 = Color3.fromRGB(235, 88, 88)
            status.Text = "Invalid key. Please try again."
        end
    end)

    while not unlocked and gate.Parent do
        task.wait(0.05)
    end
    return unlocked
end

function Window:CreateTab(config)
    config = config or {}
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Name = config.Name or "Tab"
    tab.Icon = config.Icon or "square"
    tab._elements = {}

    local tabText = tab.Name
    if tab.Icon ~= "" and not isImageIcon(tab.Icon) then
        tabText = "[" .. tab.Icon .. "] " .. tab.Name
    end
    local button = new("TextButton", {
        BackgroundColor3 = self.Theme.TabDefault,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -12, 0, 32),
        Text = tabText,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = self.Theme.Text,
        Parent = self._tabButtonHolder,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = button })
    if tab.Icon ~= "" and isImageIcon(tab.Icon) then
        new("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(16, 16),
            Image = tab.Icon,
            Parent = button,
        })
        new("UIPadding", { PaddingLeft = UDim.new(0, 26), Parent = button })
    end

    local page = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self._pageHolder,
    })
    local list = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
    end)

    tab._button = button
    tab._page = page

    local function activate()
        for _, t in ipairs(self._tabs) do
            t._page.Visible = false
            t._button.BackgroundColor3 = self.Theme.TabDefault
        end
        page.Visible = true
        button.BackgroundColor3 = self.Theme.TabActive
        self._activeTab = tab
        self:_applySearch()
    end
    button.MouseButton1Click:Connect(activate)

    table.insert(self._tabs, tab)
    if not self._activeTab then
        activate()
    end
    return tab
end

function Tab:_baseElement(config, baseHeight)
    config = config or {}
    local frame = new("Frame", {
        BackgroundColor3 = self.Window.Theme.ElementBackground,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, baseHeight or 36),
        Parent = self._page,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 7), Parent = frame })
    new("UIStroke", { Color = self.Window.Theme.ElementHover, Thickness = 1, Parent = frame })

    local title = config.Name or config.Text or "Element"
    local prefix = ""
    if config.Icon and config.Icon ~= "" and not isImageIcon(config.Icon) then
        prefix = "[" .. config.Icon .. "] "
    end

    local titleLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = self.Window.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = prefix .. title,
        Parent = frame,
    })
    if config.Icon and config.Icon ~= "" and isImageIcon(config.Icon) then
        new("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 7),
            Size = UDim2.fromOffset(14, 14),
            Image = config.Icon,
            Parent = frame,
        })
        titleLabel.Position = UDim2.fromOffset(30, 6)
        titleLabel.Size = UDim2.new(1, -42, 0, 16)
    end

    if config.Description and config.Description ~= "" then
        frame.Size = UDim2.new(1, 0, 0, (baseHeight or 36) + 16)
        new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 22),
            Size = UDim2.new(1, -24, 0, 14),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = self.Window.Theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = config.Description,
            Parent = frame,
        })
    end

    local search = string.lower((title or "") .. " " .. (config.Description or ""))
    local elementInfo = { _container = frame, _search = search }
    table.insert(self._elements, elementInfo)
    self.Window:_applySearch()
    return frame, elementInfo
end

function Tab:CreateSection(text)
    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = self.Window.Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(text or "Section"),
        Parent = self._page,
    })
    table.insert(self._elements, { _container = label, _search = string.lower(tostring(text or "")) })
    return label
end

function Tab:CreateLabel(text)
    local f = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = self.Window.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(text or ""),
        Parent = self._page,
    })
    return {
        Set = function(_, value) f.Text = tostring(value) end,
        Destroy = function() f:Destroy() end,
    }
end

function Tab:CreateParagraph(config)
    local frame = self:_baseElement({ Name = config.Title, Description = config.Content }, 44)
    return frame
end

function Tab:CreateButton(config)
    local frame = self:_baseElement(config, 36)
    local button = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = frame,
    })
    button.MouseButton1Click:Connect(function()
        track(self.Window, "Elements", "Button:" .. (config.Name or "Button"))
        if type(config.Callback) == "function" then
            config.Callback()
        end
    end)
    return { Destroy = function() frame:Destroy() end }
end

function Tab:CreateToggle(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local state = config.CurrentValue == true
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        state = self.Window._loadedFlags[config.Flag]
    end

    local trackBg = new("Frame", {
        Size = UDim2.fromOffset(36, 20),
        Position = UDim2.new(1, -48, 0, 8),
        BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBg })
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(state and 18 or 2, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = trackBg,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local function set(v, fire)
        state = v == true
        trackBg.BackgroundColor3 = state and self.Window.Theme.Accent or self.Window.Theme.ToggleOff
        knob.Position = UDim2.fromOffset(state and 18 or 2, 2)
        self.Window:_setFlag(config.Flag, state)
        if fire and type(config.Callback) == "function" then
            config.Callback(state)
        end
    end

    local click = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = frame,
    })
    click.MouseButton1Click:Connect(function()
        track(self.Window, "Elements", "Toggle:" .. (config.Name or "Toggle"))
        set(not state, true)
    end)

    set(state, false)
    return { Set = function(_, v) set(v, true) end, Get = function() return state end }
end

function Tab:CreateSlider(config)
    config = config or {}
    local frame = self:_baseElement(config, 52)
    local min = (config.Range and config.Range[1]) or 0
    local max = (config.Range and config.Range[2]) or 100
    local increment = config.Increment or 1
    local suffix = config.Suffix or ""
    local value = config.CurrentValue or min
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        value = self.Window._loadedFlags[config.Flag]
    end

    local valueLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -88, 0, 6),
        Size = UDim2.fromOffset(76, 16),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = self.Window.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value) .. suffix,
        Parent = frame,
    })
    local bar = new("Frame", {
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -24, 0, 8),
        BackgroundColor3 = self.Window.Theme.ToggleOff,
        BorderSizePixel = 0,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = self.Window.Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local dragging = false
    local function setFromAlpha(alpha, fire)
        alpha = math.clamp(alpha, 0, 1)
        local raw = min + ((max - min) * alpha)
        local snapped = math.floor((raw / increment) + 0.5) * increment
        value = math.clamp(snapped, min, max)
        fill.Size = UDim2.fromScale((value - min) / (max - min), 1)
        valueLabel.Text = tostring(value) .. suffix
        self.Window:_setFlag(config.Flag, value)
        if fire and type(config.Callback) == "function" then
            config.Callback(value)
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            track(self.Window, "Elements", "Slider:" .. (config.Name or "Slider"))
            setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromAlpha((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, true)
        end
    end)

    setFromAlpha((value - min) / (max - min), false)
    return { Set = function(_, v) setFromAlpha((v - min) / (max - min), true) end, Get = function() return value end }
end

function Tab:CreateDropdown(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local options = config.Options or {}
    local multi = config.MultipleOptions == true
    local selected = config.CurrentOption or (options[1] or "")
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        selected = self.Window._loadedFlags[config.Flag]
    end

    local label = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -210, 0, 6),
        Size = UDim2.fromOffset(200, 16),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = self.Window.Theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = multi and "multi-select" or tostring(selected),
        Parent = frame,
    })

    local dropdownFrame = new("Frame", {
        Position = UDim2.new(0, 10, 1, 2),
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = self.Window.Theme.InputBackground,
        BorderSizePixel = 0,
        Visible = false,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = dropdownFrame })
    local ddLayout = new("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = dropdownFrame,
    })

    local selectedSet = {}
    if multi then
        if type(selected) ~= "table" then
            selected = {}
        end
        for _, item in ipairs(selected) do
            selectedSet[tostring(item)] = true
        end
    end

    local function renderLabel()
        if multi then
            local picked = {}
            for _, option in ipairs(options) do
                if selectedSet[tostring(option)] then
                    table.insert(picked, tostring(option))
                end
            end
            label.Text = #picked > 0 and table.concat(picked, ", ") or "multi-select"
        else
            label.Text = tostring(selected)
        end
    end

    local function emitCallback()
        if type(config.Callback) == "function" then
            if multi then
                local out = {}
                for _, option in ipairs(options) do
                    if selectedSet[tostring(option)] then
                        table.insert(out, tostring(option))
                    end
                end
                config.Callback(out)
            else
                config.Callback(selected)
            end
        end
    end

    local function syncFlag()
        if multi then
            local out = {}
            for _, option in ipairs(options) do
                if selectedSet[tostring(option)] then
                    table.insert(out, tostring(option))
                end
            end
            self.Window:_setFlag(config.Flag, out)
        else
            self.Window:_setFlag(config.Flag, selected)
        end
    end

    local function rebuildOptions()
        for _, child in ipairs(dropdownFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        for _, option in ipairs(options) do
            local optionText = tostring(option)
            local row = new("TextButton", {
                BackgroundColor3 = self.Window.Theme.ElementBackground,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -6, 0, 24),
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  " .. optionText,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = self.Window.Theme.Text,
                Parent = dropdownFrame,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = row })
            local function updateRowColor()
                local on = multi and selectedSet[optionText] or selected == optionText
                row.BackgroundColor3 = on and self.Window.Theme.TabActive or self.Window.Theme.ElementBackground
            end
            updateRowColor()
            row.MouseButton1Click:Connect(function()
                if multi then
                    selectedSet[optionText] = not selectedSet[optionText]
                    updateRowColor()
                else
                    selected = optionText
                    dropdownFrame.Visible = false
                end
                renderLabel()
                emitCallback()
                syncFlag()
            end)
        end
        dropdownFrame.Size = UDim2.new(1, -20, 0, math.min(140, (#options * 27) + 4))
    end
    rebuildOptions()
    renderLabel()

    local button = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = frame,
    })
    button.MouseButton1Click:Connect(function()
        track(self.Window, "Elements", "Dropdown:" .. (config.Name or "Dropdown"))
        dropdownFrame.Visible = not dropdownFrame.Visible
    end)

    return {
        Set = function(_, value)
            if multi and type(value) == "table" then
                selectedSet = {}
                for _, v in ipairs(value) do
                    selectedSet[tostring(v)] = true
                end
            else
                selected = value
            end
            renderLabel()
            syncFlag()
        end,
        Get = function()
            if multi then
                local out = {}
                for _, option in ipairs(options) do
                    if selectedSet[tostring(option)] then
                        table.insert(out, tostring(option))
                    end
                end
                return out
            end
            return selected
        end,
        Refresh = function(_, newOptions)
            options = newOptions or options
            rebuildOptions()
            renderLabel()
        end,
    }
end

function Tab:CreateInput(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local value = config.Default or ""
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        value = self.Window._loadedFlags[config.Flag]
    end

    local box = new("TextBox", {
        Position = UDim2.new(1, -190, 0, 6),
        Size = UDim2.fromOffset(178, 24),
        BackgroundColor3 = self.Window.Theme.InputBackground,
        TextColor3 = self.Window.Theme.Text,
        PlaceholderColor3 = self.Window.Theme.SubText,
        PlaceholderText = config.PlaceholderText or "...",
        Text = tostring(value),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
    box.FocusLost:Connect(function()
        local text = box.Text
        self.Window:_setFlag(config.Flag, text)
        track(self.Window, "Elements", "Input:" .. (config.Name or "Input"))
        if type(config.Callback) == "function" then
            config.Callback(text)
        end
        if config.RemoveTextAfterFocusLost then
            box.Text = ""
        end
    end)
    return { Set = function(_, t) box.Text = tostring(t) end, Get = function() return box.Text end }
end

function Tab:CreateKeybind(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local keyName = config.CurrentKeybind or "F"
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        keyName = self.Window._loadedFlags[config.Flag]
    end

    local bindButton = new("TextButton", {
        Position = UDim2.new(1, -140, 0, 6),
        Size = UDim2.fromOffset(128, 24),
        BackgroundColor3 = self.Window.Theme.InputBackground,
        TextColor3 = self.Window.Theme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        Text = "[" .. tostring(keyName) .. "]",
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = bindButton })

    local listening = false
    bindButton.MouseButton1Click:Connect(function()
        listening = true
        bindButton.Text = "[press key]"
    end)

    local isHeld = false
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
            keyName = input.KeyCode.Name
            bindButton.Text = "[" .. keyName .. "]"
            listening = false
            self.Window:_setFlag(config.Flag, keyName)
        elseif input.KeyCode.Name == keyName then
            track(self.Window, "Elements", "Keybind:" .. (config.Name or "Keybind"))
            if type(config.Callback) == "function" then
                config.Callback(input.KeyCode)
            end
            if config.HoldToInteract then
                isHeld = true
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if config.HoldToInteract and isHeld and input.KeyCode.Name == keyName then
            isHeld = false
            if type(config.ReleasedCallback) == "function" then
                config.ReleasedCallback(input.KeyCode)
            end
        end
    end)

    return { Set = function(_, k) keyName = tostring(k) bindButton.Text = "[" .. keyName .. "]" end, Get = function() return keyName end }
end

function Tab:CreateColorPicker(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local color = config.Color or Color3.fromRGB(255, 255, 255)
    if config.Flag and self.Window._loadedFlags[config.Flag] ~= nil then
        color = self.Window._loadedFlags[config.Flag]
    end

    local preview = new("Frame", {
        Position = UDim2.new(1, -42, 0, 8),
        Size = UDim2.fromOffset(24, 20),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = preview })
    local button = new("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = frame,
    })
    button.MouseButton1Click:Connect(function()
        track(self.Window, "Elements", "ColorPicker:" .. (config.Name or "Color"))
        -- Lightweight behavior: cycle through preset accents.
        if color == Color3.fromRGB(255, 255, 255) then
            color = self.Window.Theme.Accent
        else
            color = Color3.fromRGB(255, 255, 255)
        end
        preview.BackgroundColor3 = color
        self.Window:_setFlag(config.Flag, color)
        if type(config.Callback) == "function" then
            config.Callback(color)
        end
    end)
    return { Set = function(_, c) color = c preview.BackgroundColor3 = c end, Get = function() return color end }
end

function Tab:CreateStat(config)
    config = config or {}
    local frame = self:_baseElement(config, 36)
    local suffix = config.Suffix or ""
    local valueText = tostring(config.Value or "0")
    local valueLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -160, 0, 6),
        Size = UDim2.fromOffset(148, 16),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = self.Window.Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = valueText .. suffix,
        Parent = frame,
    })
    return {
        Set = function(_, value)
            valueText = tostring(value)
            valueLabel.Text = valueText .. suffix
        end,
    }
end

function Tab:CreateSeparator()
    local sep = new("Frame", {
        BackgroundColor3 = self.Window.Theme.ElementHover,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self._page,
    })
    table.insert(self._elements, { _container = sep, _search = "" })
    return sep
end

function Tab:CreateSpacer(config)
    local h = (config and config.Height) or 8
    local space = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), Parent = self._page })
    table.insert(self._elements, { _container = space, _search = "" })
    return space
end

function Tab:CreateProgressBar(config)
    config = config or {}
    local stat = self:CreateStat({ Name = config.Name or "Progress", Value = config.Default or 0, Suffix = "%" })
    return stat
end

function Tab:CreateBadge(config)
    local frame = self:_baseElement({ Name = config.Name or "Badge", Description = config.Text or "" }, 36)
    frame.BackgroundColor3 = config.Color or self.Window.Theme.Accent
    return frame
end

function Tab:CreateTable(config)
    return self:CreateParagraph({
        Title = config.Name or "Table",
        Content = "Columns: " .. table.concat(config.Columns or {}, ", "),
    })
end

function StarLib:CreateWindow(config)
    self._analytics.Sessions = self._analytics.Sessions + 1
    config = deepMerge(DEFAULT_CONFIG, config or {})
    local theme = buildTheme(config.Theme, config.ThemeOverrides)

    local gui = new("ScreenGui", {
        Name = "StarLibGui_" .. tostring(math.random(1000, 9999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getGuiParent(),
    })
    if syn and type(syn.protect_gui) == "function" then
        safeCall(syn.protect_gui, gui)
    end

    local loading = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = theme.Background,
        Parent = gui,
    })
    new("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.45),
        Size = UDim2.fromOffset(460, 32),
        Text = config.LoadingTitle,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = theme.Text,
        Parent = loading,
    })
    new("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.52),
        Size = UDim2.fromOffset(460, 22),
        Text = config.LoadingSubtitle,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = theme.SubText,
        Parent = loading,
    })
    task.wait(0.2)
    loading:Destroy()

    local main = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(700, 460),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = main })
    new("UIStroke", { Color = theme.ElementHover, Thickness = 1, Parent = main })

    local topbar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = theme.Topbar,
        BorderSizePixel = 0,
        Parent = main,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = topbar })

    local title = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.fromOffset(330, 42),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = config.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = theme.Text,
        Parent = topbar,
    })

    if config.Icon and config.Icon ~= "" then
        local iconLabel = new("ImageLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.fromOffset(22, 22),
            Image = config.Icon,
            Parent = topbar,
        })
        title.Position = UDim2.fromOffset(38, 0)
    end

    local searchBox = nil
    if config.EnableSearch then
        searchBox = new("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(180, 26),
            BackgroundColor3 = theme.InputBackground,
            BorderSizePixel = 0,
            PlaceholderText = "Search command in tab...",
            PlaceholderColor3 = theme.SubText,
            TextColor3 = theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = topbar,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchBox })
    end

    local body = new("Frame", {
        Position = UDim2.fromOffset(0, 42),
        Size = UDim2.new(1, 0, 1, -42),
        BackgroundTransparency = 1,
        Parent = main,
    })
    local sidebar = new("Frame", {
        Size = UDim2.fromOffset(170, 418),
        BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0,
        Parent = body,
    })
    local tabButtons = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 8),
        Size = UDim2.new(1, -12, 1, -16),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        Parent = sidebar,
    })
    local tabsLayout = new("UIListLayout", { Padding = UDim.new(0, 6), Parent = tabButtons })
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabButtons.CanvasSize = UDim2.new(0, 0, 0, tabsLayout.AbsoluteContentSize.Y + 8)
    end)

    local pageHolder = new("Frame", {
        Position = UDim2.fromOffset(178, 8),
        Size = UDim2.new(1, -186, 1, -16),
        BackgroundTransparency = 1,
        Parent = body,
    })

    if config.Resizable then
        local grip = new("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(18, 18),
            Text = "◢",
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            BackgroundTransparency = 1,
            TextColor3 = theme.SubText,
            Parent = main,
        })
        local resizing = false
        grip.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local pos = main.AbsolutePosition
                main.Size = UDim2.fromOffset(math.max(560, mouse.X - pos.X), math.max(360, mouse.Y - pos.Y))
            end
        end)
    end

    local window = setmetatable({
        Gui = gui,
        Config = config,
        Theme = theme,
        _main = main,
        _tabs = {},
        _activeTab = nil,
        _tabButtonHolder = tabButtons,
        _pageHolder = pageHolder,
        _searchTerm = "",
        _flags = {},
        _loadedFlags = {},
        _analytics = {
            Elements = {},
            Executor = detectExecutor(),
            CreatedAt = os.time(),
            SessionIndex = self._analytics.Sessions,
        },
        _sidebarExpanded = true,
        _sidebarExpandedWidth = 170,
        _sidebarCollapsedWidth = 18,
    }, Window)
    window._layoutRefs = {
        sidebar = sidebar,
        tabButtons = tabButtons,
        pageHolder = pageHolder,
        bodyHeight = 418,
        pageGap = 8,
        pageTopPadding = 8,
        pageBottomPadding = 8,
        pageRightPadding = 8,
    }
    window._themeRefs = {
        main = main,
        topbar = topbar,
        sidebar = sidebar,
        title = title,
        search = searchBox,
    }

    window._notificationHolder = createNotificationContainer(gui)
    window._loadedFlags = window:LoadConfiguration()
    window:_refreshLayout(true)
    window:_setupSidebarAutoHide()

    local dragging, dragStart, startPos = false, nil, nil
    topbar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
        end
    end)

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            window._searchTerm = string.lower(searchBox.Text or "")
            window:_applySearch()
        end)
    end

    window._toggleConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if input.KeyCode == config.ToggleKey then
            window:Toggle()
        end
    end)

    if not createKeySystemGate(window) then
        window:Destroy()
        return nil
    end

    if config.Discord.Enabled and config.Discord.Invite ~= "" then
        local shouldPrompt = true
        if config.Discord.RememberJoins then
            shouldPrompt = not window:_rememberDiscordJoin()
        end
        if shouldPrompt then
            if type(setclipboard) == "function" then
                safeCall(setclipboard, "https://discord.gg/" .. config.Discord.Invite)
            end
            window:Notify({
                Title = "Discord Invite",
                Content = "Invite copied to clipboard: discord.gg/" .. config.Discord.Invite,
                Type = "success",
            })
        end
    end

    if config.Monetization.Enabled then
        local mon = window:CreateTab({ Name = "Support", Icon = "gem" })
        mon:CreateParagraph({
            Title = config.Monetization.Strategy,
            Content = config.Monetization.Details ~= "" and config.Monetization.Details or "Support the developer to keep updates coming.",
        })
    end

    table.insert(self._windows, window)
    return window
end

function StarLib:Notify(config)
    local win = self._windows[#self._windows]
    if win then
        win:Notify(config)
    end
end

return StarLib
