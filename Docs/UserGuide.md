# StarLib Editor — User Guide

## Getting Started

1. **Launch** `StarLibEditor.exe` by double-clicking it. No installation needed.
2. A new project with a default window, one tab, and sample widgets is created automatically.

## Interface Overview

### Main Window Layout

```
┌──────────────────────────────────────────────────────────────┐
│ MENU BAR + TOOLBAR                                           │
├──────────┬─────────────────────────────────┬─────────────────┤
│ PALETTE  │                                 │  INSPECTOR      │
│ (widgets)│    DESIGNER CANVAS              │  (properties)   │
├──────────┤    (StarLib window mockup)      │                 │
│ HIERARCHY│                                 │                 │
│ (tree)   │                                 │                 │
├──────────┴─────────────────────────────────┴─────────────────┤
│ CODE PANEL (generated Lua output)                            │
└──────────────────────────────────────────────────────────────┘
```

### Palette Panel (left top)
Contains draggable widgets organized in groups:
- **Structure**: Section, Label, Paragraph
- **Elements**: Button, Toggle, Slider, Dropdown, Input, Keybind, ColorPicker
- **Layout**: Separator, Spacer
- **Containers**: HorizontalRow, VerticalStack, GridContainer
- **Advanced**: ProgressBar, Table, Badge

**Adding widgets**: Double-click a palette item to add it to the current tab, or drag it onto the canvas.

### Designer Canvas (center)
Shows a live visual mockup of your StarLib window. Click elements to select them. Use the sidebar tabs to switch between tabs.

**Zoom**: Ctrl+scroll to zoom. Ctrl+0 to reset.

### Hierarchy Panel (left bottom)
Shows the tree structure of your project. Click nodes to select them. Right-click for context menu (duplicate, delete, rename).

### Inspector Panel (right)
Edit properties of the selected widget. Changes update the canvas and code in real time.

### Code Panel (bottom)
Shows the generated Lua code. Features:
- Syntax highlighting for Lua
- Copy to clipboard button
- Export to .lua file
- Edit Mode toggle for manual tweaks
- Minify toggle

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+N | New Project |
| Ctrl+O | Open Project |
| Ctrl+S | Save Project |
| Ctrl+Shift+S | Save As |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Delete | Delete selected node |

## Using the Emulator

1. Click **Run > Open Emulator** or the "Run Emulator" toolbar button.
2. The emulator window opens with a 1280×720 canvas.
3. Click **Run** to execute your generated Lua with the embedded StarLib.
4. Interact with the rendered UI: click buttons, toggle switches, adjust sliders.
5. The console panel shows print/warn/error output.
6. Click **Simulate Key** to fire keyboard input events.
7. Click **Stop** to halt execution, **Reload** to restart.

## Themes

Open the theme editor via the Inspector panel when "Window Settings" is selected. Choose from preset themes or customize individual colors. Only changed values are included in the generated Lua output.

## Templates

Save reusable UI fragments:
1. Select nodes in the hierarchy.
2. Right-click > "Save as Template".
3. Access saved templates from the Palette panel's Templates tab.
4. Import/export templates as `.slt` files.

## Project Files

Projects are saved as `.starlibproj` files (JSON format). They contain all window settings, tabs, widgets, theme overrides, templates, and asset references.

## Advanced Features

All widgets (ProgressBar, Badge, Table, Separator, Spacer, Containers, and 30+ more) are included in the single `StarLib.lua` file. No separate files are needed.
