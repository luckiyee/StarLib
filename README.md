# StarLib

The most complete Roblox executor UI library ever made. StarLib is a single-file Lua module that gives you everything you need to build polished, feature-rich script GUIs — windows, tabs, many widget types, themes, animations, notifications, modals, persistence, and much more.

## Example UI:

```lua
local StarLib = loadstring(readfile("Main/StarLib.lua"))()

local Window = StarLib:CreateWindow({
    Name = "My Script",
    ThemePreset = "Midnight",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Tab = Window:CreateTab("Main")

Tab:CreateButton({
    Name = "Hello",
    Callback = function() print("Hello from StarLib!") end,
})

Tab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(value) print("God Mode:", value) end,
})

Tab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Suffix = " studs/s",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})
```

## Features

### Core
- Draggable, minimizable, closable windows with animated loading screen
- Tabbed sidebar with icon and badge support
- Toggle key to show/hide the entire UI
- Multi-window manager — run multiple windows simultaneously
- GUI protection (`syn.protect_gui` / `gethui` / CoreGui fallback)

### Widgets
- **Basics** — Button, Toggle, Slider, Dropdown (searchable), MultiDropdown, Input, Keybind, ColorPicker (full HSV)
- **Display** — Label, Paragraph, Section, Separator, Spacer, Badge, ProgressBar, CircularProgress, StatCard, ProfileCard, ImageCard
- **Data** — Table, DataTable (sortable/filterable/paginated), RadioGroup, Accordion, CodeBlock, Graph (line/bar), TreeView, Timeline, PlayerList
- **Input** — RangeSlider, NumberInput, SwitchGroup, TagInput, Rating, InlineEdit, Search, DatePicker
- **Layout** — HorizontalRow, Grid, SubTabs, Breadcrumb, Pagination, Stepper, ProgressTracker
- **Interactive** — Console, ChatLog, Kanban, CountdownTimer, CommandPalette

### Theme Engine
- 12 built-in presets: Dark, Midnight, Ocean, Forest, Crimson, Purple, Rose, Amber, Neon, Light, Dracula, Nord
- Theme builder for custom themes from accent + background colors
- Live accent color and opacity changes per window
- Color palette generators (complementary, triadic, analogous, monochromatic)

### Systems
- **Notifications** — Stacking toasts with types (info, success, warning, error), progress bars, auto-dismiss
- **Modals** — Confirm, Alert, Prompt dialogs with backdrop dimming
- **Tooltips** — Attach hover tooltips to any element
- **Context Menus** — Right-click menus with icons and separators
- **Command Palette** — Searchable command interface with keyboard shortcuts
- **Watermark / HUD** — Configurable overlay with FPS display
- **FPS Counter** — Standalone real-time FPS widget
- **Performance Monitor** — FPS, Ping, Memory, Instance count dashboard

### Persistence & Config
- Export/import window state as JSON
- AutoSave/AutoLoad for automatic state recovery
- Named config profiles (save, load, delete, list)
- Data store abstraction for key-value persistence

### Utilities
- Animation library with tweens, fades, slides, scale, pulse, shake, typewriter, count-up
- Animation presets (FadeInUp, ZoomIn, Bounce, Ripple, Glow, FlashColor)
- 15 easing functions (Quad, Cubic, Quint, Sine, Elastic, Bounce, Back)
- Signal/event bus for decoupled communication
- Hotkey manager with modifier key support (Ctrl, Shift, Alt)
- Timer/interval manager
- Keyboard navigation (Tab/Enter/Escape)
- Clipboard helpers, table serialization
- Comprehensive string, math, table, and color utility libraries
- Form builder with validation
- Plugin API for extending StarLib
- Debug mode with benchmarking

## Project Structure

```
StarLib/
└── Main/                   StarLib.lua (the library itself)
```

## License

StarLib © All Rights Reserved
