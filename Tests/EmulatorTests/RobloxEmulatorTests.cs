using StarLibEditor.Emulator;
using Xunit;

namespace EmulatorTests;

public class RobloxEmulatorTests
{
    [Fact]
    public void MockColor3_FromRGB_CorrectValues()
    {
        var c = MockColor3.FromRGB(255, 128, 0);
        Assert.Equal(1.0, c.R, 2);
        Assert.Equal(128 / 255.0, c.G, 2);
        Assert.Equal(0.0, c.B, 2);
    }

    [Fact]
    public void MockColor3_Lerp_Midpoint()
    {
        var a = MockColor3.FromRGB(0, 0, 0);
        var b = MockColor3.FromRGB(255, 255, 255);
        var mid = a.Lerp(b, 0.5);

        Assert.Equal(0.5, mid.R, 1);
        Assert.Equal(0.5, mid.G, 1);
        Assert.Equal(0.5, mid.B, 1);
    }

    [Fact]
    public void MockColor3_ToWpfColor_Correct()
    {
        var c = MockColor3.FromRGB(100, 200, 50);
        var wpf = c.ToWpfColor();

        Assert.Equal(100, wpf.R);
        Assert.Equal(200, wpf.G);
        Assert.Equal(50, wpf.B);
    }

    [Fact]
    public void MockUDim2_Resolve_ScaleAndOffset()
    {
        var udim = MockUDim2.New(0.5, 10, 0.25, 20);
        var (w, h) = udim.Resolve(800, 600);

        Assert.Equal(410, w); // 0.5*800 + 10
        Assert.Equal(170, h); // 0.25*600 + 20
    }

    [Fact]
    public void MockUDim2_Lerp_Correct()
    {
        var a = MockUDim2.New(0, 0, 0, 0);
        var b = MockUDim2.New(1, 100, 1, 200);
        var mid = a.Lerp(b, 0.5);

        Assert.Equal(0.5, mid.X.Scale, 2);
        Assert.Equal(50, mid.X.Offset, 2);
        Assert.Equal(0.5, mid.Y.Scale, 2);
        Assert.Equal(100, mid.Y.Offset, 2);
    }

    [Fact]
    public void MockInstance_Create_HasClassName()
    {
        var inst = new MockInstance("Frame");
        Assert.Equal("Frame", inst.ClassName);
    }

    [Fact]
    public void MockInstance_ParentChild_Relationship()
    {
        var parent = new MockInstance("Frame");
        var child = new MockInstance("TextLabel");
        child.Parent = parent;

        Assert.Single(parent.Children);
        Assert.Equal(parent, child.Parent);
    }

    [Fact]
    public void MockInstance_FindFirstChild_Works()
    {
        var parent = new MockInstance("Frame");
        var child = new MockInstance("TextLabel");
        child.SetProperty("Name", "MyLabel");
        child.Parent = parent;

        var found = parent.FindFirstChild("MyLabel");
        Assert.NotNull(found);
        Assert.Equal("TextLabel", found!.ClassName);
    }

    [Fact]
    public void MockInstance_FindFirstChild_ReturnsNull_WhenNotFound()
    {
        var parent = new MockInstance("Frame");
        Assert.Null(parent.FindFirstChild("NonExistent"));
    }

    [Fact]
    public void MockInstance_Destroy_RemovesFromParent()
    {
        var parent = new MockInstance("Frame");
        var child = new MockInstance("TextLabel");
        child.Parent = parent;

        child.Destroy();
        Assert.Empty(parent.Children);
    }

    [Fact]
    public void MockInstance_IsA_BaseClasses()
    {
        var frame = new MockInstance("Frame");
        Assert.True(frame.IsA("Frame"));
        Assert.True(frame.IsA("GuiObject"));
        Assert.True(frame.IsA("Instance"));
        Assert.False(frame.IsA("TextLabel"));
    }

    [Fact]
    public void MockInstance_SetGetProperty()
    {
        var inst = new MockInstance("Frame");
        inst.SetProperty("BackgroundColor3", MockColor3.FromRGB(255, 0, 0));

        var color = inst.GetProperty("BackgroundColor3") as MockColor3;
        Assert.NotNull(color);
        Assert.Equal(1.0, color!.R, 2);
    }

    [Fact]
    public void MockSignal_ConnectAndFire()
    {
        var signal = new MockSignal("TestSignal");
        int callCount = 0;

        var script = new MoonSharp.Interpreter.Script();
        MoonSharp.Interpreter.UserData.RegisterType<MockSignal>();
        MoonSharp.Interpreter.UserData.RegisterType<SignalConnection>();

        var callback = MoonSharp.Interpreter.DynValue.NewCallback((ctx, args) =>
        {
            callCount++;
            return MoonSharp.Interpreter.DynValue.Nil;
        });

        signal.Connect(callback);
        signal.Fire(script);

        Assert.Equal(1, callCount);
    }

    [Fact]
    public void MockSignal_Disconnect_StopsFiring()
    {
        var signal = new MockSignal("TestSignal");
        int callCount = 0;

        var script = new MoonSharp.Interpreter.Script();
        MoonSharp.Interpreter.UserData.RegisterType<MockSignal>();
        MoonSharp.Interpreter.UserData.RegisterType<SignalConnection>();

        var callback = MoonSharp.Interpreter.DynValue.NewCallback((ctx, args) =>
        {
            callCount++;
            return MoonSharp.Interpreter.DynValue.Nil;
        });

        var conn = signal.Connect(callback);
        signal.Fire(script);
        Assert.Equal(1, callCount);

        conn.Disconnect();
        signal.Fire(script);
        Assert.Equal(1, callCount);
    }

    [Fact]
    public void MockInstanceTree_CreateInstance_AddsToTree()
    {
        var tree = new MockInstanceTree();
        var inst = tree.CreateInstance("Frame");

        Assert.NotNull(inst);
        Assert.Equal("Frame", inst.ClassName);
    }

    [Fact]
    public void MockInstanceTree_CoreGui_Exists()
    {
        var tree = new MockInstanceTree();
        Assert.NotNull(tree.CoreGui);
        Assert.Equal("CoreGui", tree.CoreGui.Name);
    }

    [Fact]
    public void MockInstanceTree_LocalPlayer_HasProperties()
    {
        var tree = new MockInstanceTree();
        Assert.Equal("TestPlayer", tree.LocalPlayer.GetProperty("Name"));
        Assert.Equal(1.0, tree.LocalPlayer.GetProperty("UserId"));
    }

    [Fact]
    public void MockVector2_Properties()
    {
        var v = MockVector2.New(3, 4);
        Assert.Equal(3, v.X);
        Assert.Equal(4, v.Y);
        Assert.Equal(5, v.Magnitude, 5);
    }

    [Fact]
    public void MockTweenInfo_Defaults()
    {
        var ti = new MockTweenInfo();
        Assert.Equal(1.0, ti.Time);
        Assert.Equal(0, ti.EasingStyle);
        Assert.Equal(0, ti.RepeatCount);
        Assert.False(ti.Reverses);
    }
}
