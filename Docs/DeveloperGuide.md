# Developer Guide

## Architecture

StarLib Editor uses MVVM (Model-View-ViewModel) with CommunityToolkit.Mvvm.

### Layers

```
Views (XAML)  →  ViewModels (C#)  →  Services (C#)  →  Models (C#)
                                  →  Emulator (C#/MoonSharp)
```

### Key Services

- **UndoRedoService**: Command pattern with undo/redo stacks. All edits go through this.
- **CodeGeneratorService**: Converts project model to deterministic Lua output.
- **ProjectService**: JSON serialization/deserialization of .starlibproj files.
- **StarLibAdapterService**: Parses StarLib.lua to build API metadata.

### Emulator Architecture

```
RobloxEmulator
  ├── MoonSharp Script (Lua VM)
  ├── MockInstanceTree (instance hierarchy)
  │   ├── CoreGui, PlayerGui, LocalPlayer
  │   ├── TweenService, UserInputService, Players, RunService
  │   └── All created Instance.new() objects
  ├── MockRenderer (Instance → WPF mapping)
  │   ├── Layout engine (UDim2 → pixel)
  │   ├── Tween animation
  │   └── Mouse interaction forwarding
  └── LuaTaskScheduler (cooperative async)
```

## Adding a New Widget Type

1. Add to `WidgetType` enum in `Models/WidgetType.cs`
2. Add default props in `UINode.GetDefaultProps()`
3. Add palette entry in `PaletteViewModel.BuildPaletteGroups()`
4. Add canvas rendering in `DesignerCanvas.CreateWidgetMockup()`
5. Add code generation in `CodeGeneratorService.GenerateNode()`
6. Add to `StarLibAdapter.json`
7. Implement in `Main/StarLib.lua`

## Building

```bash
dotnet build StarLibEditor/StarLibEditor.csproj
dotnet test Tests/UnitTests/UnitTests.csproj
dotnet publish StarLibEditor/StarLibEditor.csproj -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true -o ./dist
```

## Project File Schema

See `Docs/ProjectFileSchema.md` for the complete .starlibproj JSON schema.
