using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

public class MockInstanceTree
{
    private readonly List<MockInstance> _allInstances = new();

    public MockInstance CoreGui { get; }
    public MockInstance PlayerGui { get; }
    public MockInstance LocalPlayer { get; }
    public MockInstance PlayersService { get; }
    public MockInstance TweenService { get; }
    public MockInstance UserInputService { get; }
    public MockInstance RunService { get; }

    public Script? Script { get; set; }
    public Action? InstanceChanged { get; set; }

    public MockInstanceTree()
    {
        CoreGui = CreateRoot("CoreGui", "ScreenGui");
        PlayerGui = CreateRoot("PlayerGui", "Folder");

        LocalPlayer = CreateRoot("LocalPlayer", "Player");
        LocalPlayer.SetProperty("Name", "TestPlayer");
        LocalPlayer.SetProperty("UserId", 1.0);

        PlayersService = CreateRoot("Players", "Players");
        TweenService = CreateRoot("TweenService", "TweenService");
        UserInputService = CreateRoot("UserInputService", "UserInputService");
        RunService = CreateRoot("RunService", "RunService");

        SetupPlayersService();
        SetupTweenService();
        SetupUserInputService();
        SetupRunService();
    }

    private MockInstance CreateRoot(string name, string className)
    {
        var inst = new MockInstance(className) { OnTree = this };
        inst.SetProperty("Name", name);
        _allInstances.Add(inst);
        return inst;
    }

    public MockInstance CreateInstance(string className, MockInstance? parent = null)
    {
        var inst = new MockInstance(className) { OnTree = this };
        _allInstances.Add(inst);
        if (parent != null) inst.Parent = parent;
        return inst;
    }

    public void RemoveInstance(MockInstance inst)
    {
        _allInstances.Remove(inst);
    }

    public void DestroyAll()
    {
        foreach (var inst in _allInstances.ToList())
            inst.Destroy();
        _allInstances.Clear();
    }

    private void SetupPlayersService()
    {
        // Players.LocalPlayer -> LocalPlayer
        PlayersService.SetProperty("LocalPlayer", LocalPlayer);

        // Make LocalPlayer:WaitForChild("PlayerGui") return PlayerGui
        PlayerGui.Parent = LocalPlayer;
    }

    private void SetupTweenService()
    {
        // TweenService:Create() handled via MoonSharp proxy in RobloxEmulator
    }

    private void SetupUserInputService()
    {
        // InputBegan/InputChanged/InputEnded signals are on the UserInputService mock
    }

    private void SetupRunService()
    {
        // Simplified: no game loop
    }

    public List<MockInstance> GetAllScreenGuis()
    {
        var result = new List<MockInstance>();
        CollectScreenGuis(CoreGui, result);
        CollectScreenGuis(PlayerGui, result);
        foreach (var inst in _allInstances)
        {
            if (inst.ClassName == "ScreenGui" && !result.Contains(inst))
                result.Add(inst);
        }
        return result;
    }

    private void CollectScreenGuis(MockInstance parent, List<MockInstance> result)
    {
        foreach (var child in parent.Children)
        {
            if (child.ClassName == "ScreenGui")
                result.Add(child);
            CollectScreenGuis(child, result);
        }
    }
}
