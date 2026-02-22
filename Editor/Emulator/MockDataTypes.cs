using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

[MoonSharpUserData]
public class MockColor3
{
    public double R { get; set; }
    public double G { get; set; }
    public double B { get; set; }

    public MockColor3() { }
    public MockColor3(double r, double g, double b) { R = r; G = g; B = b; }

    public static MockColor3 FromRGB(int r, int g, int b) => new(r / 255.0, g / 255.0, b / 255.0);
    public static MockColor3 New(double r, double g, double b) => new(r, g, b);

    public System.Windows.Media.Color ToWpfColor() =>
        System.Windows.Media.Color.FromRgb(
            (byte)Math.Clamp(R * 255, 0, 255),
            (byte)Math.Clamp(G * 255, 0, 255),
            (byte)Math.Clamp(B * 255, 0, 255));

    public override string ToString() =>
        $"{R:F4}, {G:F4}, {B:F4}";

    public MockColor3 Lerp(MockColor3 target, double alpha) =>
        new(R + (target.R - R) * alpha, G + (target.G - G) * alpha, B + (target.B - B) * alpha);
}

[MoonSharpUserData]
public class MockUDim2
{
    public MockUDim X { get; set; } = new();
    public MockUDim Y { get; set; } = new();

    public MockUDim2() { }
    public MockUDim2(MockUDim x, MockUDim y) { X = x; Y = y; }

    public static MockUDim2 New(double xScale, double xOffset, double yScale, double yOffset) =>
        new(new MockUDim(xScale, xOffset), new MockUDim(yScale, yOffset));

    public override string ToString() =>
        $"{{{X.Scale}, {X.Offset}}}, {{{Y.Scale}, {Y.Offset}}}";

    public MockUDim2 Lerp(MockUDim2 target, double alpha) =>
        new(X.Lerp(target.X, alpha), Y.Lerp(target.Y, alpha));

    public (double width, double height) Resolve(double parentW, double parentH) =>
        (X.Scale * parentW + X.Offset, Y.Scale * parentH + Y.Offset);
}

[MoonSharpUserData]
public class MockUDim
{
    public double Scale { get; set; }
    public double Offset { get; set; }

    public MockUDim() { }
    public MockUDim(double scale, double offset) { Scale = scale; Offset = offset; }

    public static MockUDim New(double scale, double offset) => new(scale, offset);

    public MockUDim Lerp(MockUDim target, double alpha) =>
        new(Scale + (target.Scale - Scale) * alpha, Offset + (target.Offset - Offset) * alpha);

    public override string ToString() => $"{Scale}, {Offset}";
}

[MoonSharpUserData]
public class MockVector2
{
    public double X { get; set; }
    public double Y { get; set; }

    public MockVector2() { }
    public MockVector2(double x, double y) { X = x; Y = y; }

    public static MockVector2 New(double x, double y) => new(x, y);
    public double Magnitude => Math.Sqrt(X * X + Y * Y);

    public override string ToString() => $"{X}, {Y}";
}

[MoonSharpUserData]
public class MockVector3
{
    public double X { get; set; }
    public double Y { get; set; }
    public double Z { get; set; }

    public MockVector3() { }
    public MockVector3(double x, double y, double z) { X = x; Y = y; Z = z; }

    public static MockVector3 New(double x, double y, double z) => new(x, y, z);

    public override string ToString() => $"{X}, {Y}, {Z}";
}

[MoonSharpUserData]
public class MockTweenInfo
{
    public double Time { get; set; }
    public int EasingStyle { get; set; }
    public int EasingDirection { get; set; }
    public int RepeatCount { get; set; }
    public bool Reverses { get; set; }
    public double DelayTime { get; set; }

    public MockTweenInfo() { Time = 1; }

    public MockTweenInfo(double time, int easingStyle = 0, int easingDir = 0,
        int repeatCount = 0, bool reverses = false, double delay = 0)
    {
        Time = time;
        EasingStyle = easingStyle;
        EasingDirection = easingDir;
        RepeatCount = repeatCount;
        Reverses = reverses;
        DelayTime = delay;
    }
}
