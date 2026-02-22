# Changelog

## [1.0.0] - 2026-02-22

### Added
- Visual designer with drag-and-drop palette, canvas mockup, hierarchy tree, inspector panel
- Live Lua code generation matching the real StarLib API
- Embedded Roblox executor emulator via MoonSharp
  - Mock Instance system (Frame, TextLabel, TextButton, TextBox, ScrollingFrame, etc.)
  - Mock Services (TweenService, UserInputService, Players, CoreGui)
  - Tween animation rendering with easing functions
  - RBXScriptSignal system with Connect/Disconnect
  - Task scheduler (task.wait, task.spawn, task.delay)
  - Executor globals (syn, gethui, readfile, writefile, loadstring)
- Undo/Redo system with command pattern (200 step history)
- Project save/load (.starlibproj JSON format)
- Theme editor with live preview and preset themes
- Template manager with import/export (.slt files)
- AvalonEdit code panel with Lua syntax highlighting
- StarLibUpgraded.lua with 15 new features:
  - Real HSV color picker
  - Modal/Dialog system (Confirm, Alert, Prompt)
  - Stacking toast notifications
  - Container widgets (HorizontalRow, VerticalStack, Grid)
  - Icons on elements
  - Searchable dropdown
  - Multi-window manager
  - State persistence (ExportState, ImportState, AutoSave, AutoLoad)
  - Keyboard navigation
  - Improved event model (OnClick, OnChanged, SetEnabled, SetVisible, etc.)
  - ProgressBar widget
  - Separator and Spacer widgets
  - Badge/Chip widget
  - Table/Grid display widget
  - Debug mode with timing and logging
- Per-Monitor DPI v2 support
- Single self-contained .exe distribution
- GitHub Actions CI pipeline
