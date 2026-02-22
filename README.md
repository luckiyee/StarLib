# StarLib

The most complete Roblox executor UI library ever made. StarLib is a single-file Lua module that gives you everything you need to build polished, feature-rich script GUIs — windows, tabs, 40+ widget types, themes, animations, notifications, modals, persistence, and much more.

## Quick Start

```lua
local StarLib = loadstring(readfile("StarLib/StarLib.lua"))()

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

### Widgets (40+)
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

## Visual Editor

The repo also includes a **StarLib Visual Editor** — a WPF desktop app for designing StarLib UIs with drag & drop, then exporting clean Lua code.

### Editor Features
- Visual designer with palette, canvas, hierarchy tree, and property inspector
- Live Lua code generation matching the StarLib API
- Embedded Roblox emulator (MoonSharp) for testing without Roblox Studio
- Theme editor with live preview
- Template system for reusable UI fragments
- Full undo/redo

### Building the Editor

Requires [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0).

```bash
cd Editor
dotnet build StarLibEditor.csproj
dotnet run --project StarLibEditor.csproj
```

To publish a single `.exe`:

```bash
dotnet publish StarLibEditor.csproj -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true /p:EnableCompressionInSingleFile=true -o ./dist
```

## Project Structure

```
StarLib/
├── Main/                   StarLib.lua (the library itself)
├── Editor/                 Visual Editor (WPF application)
│   ├── Models/             Data models
│   ├── ViewModels/         MVVM ViewModels
│   ├── Views/              XAML views and dialogs
│   ├── Services/           Business logic and code generation
│   ├── Emulator/           MoonSharp-based Roblox emulator
│   ├── Controls/           Reusable WPF controls
│   └── Assets/             Icons, default templates
├── ExecutorHarness/        Standalone executor examples
├── Docs/                   User and developer documentation
└── Tests/                  Unit and emulator tests
```

## License

StarLib © All Rights Reserved