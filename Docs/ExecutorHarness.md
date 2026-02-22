# Executor Harness

The executor harness is a simplified standalone environment for testing StarLib scripts outside of the full editor.

## How the Emulator Works

The emulator uses MoonSharp (Lua 5.2 interpreter for C#) to execute Lua scripts in a sandboxed environment with mock Roblox APIs.

### Supported Mock APIs

| API | Status | Notes |
|-----|--------|-------|
| game:GetService() | Full | Players, TweenService, UserInputService, CoreGui, RunService |
| Instance.new() | Full | All GUI classes supported |
| Color3.fromRGB/new | Full | |
| UDim2.new | Full | |
| UDim.new | Full | |
| Vector2.new | Full | |
| Vector3.new | Full | |
| TweenInfo.new | Full | |
| TweenService:Create | Full | Animated with easing functions |
| UserInputService signals | Full | InputBegan, InputChanged, InputEnded |
| Enum.* | Full | Font, EasingStyle, KeyCode, etc. |
| task.wait/spawn/delay | Full | Cooperative scheduler |
| pcall/xpcall | Full | |
| syn.protect_gui | No-op | |
| gethui() | Full | Returns CoreGui |
| readfile/writefile | Full | Uses local filesystem |
| loadstring | Full | Via MoonSharp |
| print/warn/error | Full | Output to console panel |

### Known Limitations

- Font rendering uses system fonts (Segoe UI) instead of Roblox fonts (Gotham)
- ImageLabel/ImageButton show placeholders for rbxasset:// URLs
- Layout calculations are approximate (80-90% visual fidelity)
- No actual game world simulation
- No networking or DataStore mocks
