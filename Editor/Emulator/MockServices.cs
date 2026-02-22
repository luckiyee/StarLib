using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

/// <summary>
/// Registers TweenService:Create, UserInputService signals, and Players.LocalPlayer
/// as proper MoonSharp interop objects on the Script.
/// Called from RobloxEmulator after the basic instance tree is set up.
/// </summary>
public static class MockServiceRegistrar
{
    public static void RegisterTweenServiceProxy(Script script, MockInstanceTree tree)
    {
        var tweenMeta = new Table(script);
        var indexFn = DynValue.NewCallback((ctx, args) =>
        {
            var key = args[1].String;
            if (key == "Create")
            {
                return DynValue.NewCallback((ctx2, createArgs) =>
                {
                    // TweenService:Create(instance, tweenInfo, properties)
                    var targetInst = createArgs[1].UserData?.Object as MockInstance;
                    var tweenInfo = createArgs[2].UserData?.Object as MockTweenInfo;
                    var propsTable = createArgs[3].Table;

                    var tween = new MockTween(targetInst, tweenInfo, propsTable, script, tree);
                    return DynValue.FromObject(script, tween);
                });
            }
            return DynValue.Nil;
        });
        tweenMeta["__index"] = indexFn;

        var tweenServiceTable = new Table(script);
        tweenServiceTable.MetaTable = tweenMeta;
        tree.TweenService.SetScript(script);
    }

    public static void RegisterPlayersProxy(Script script, MockInstanceTree tree)
    {
        var playersMeta = new Table(script);
        playersMeta["__index"] = DynValue.NewCallback((ctx, args) =>
        {
            var key = args[1].String;
            if (key == "LocalPlayer")
                return DynValue.FromObject(script, tree.LocalPlayer);
            return DynValue.Nil;
        });
    }
}

[MoonSharpUserData]
public class MockTween
{
    private readonly MockInstance? _target;
    private readonly MockTweenInfo? _info;
    private readonly Table? _properties;
    private readonly Script _script;
    private readonly MockInstanceTree _tree;
    private CancellationTokenSource? _cts;

    public MockSignal Completed { get; } = new("Completed");

    public MockTween(MockInstance? target, MockTweenInfo? info, Table? properties,
        Script script, MockInstanceTree tree)
    {
        _target = target;
        _info = info;
        _properties = properties;
        _script = script;
        _tree = tree;
    }

    public void Play()
    {
        if (_target == null || _info == null || _properties == null) return;

        _cts = new CancellationTokenSource();
        var duration = _info.Time;
        var easingStyle = _info.EasingStyle;
        var easingDir = _info.EasingDirection;

        // Capture start values and target values
        var animations = new List<PropertyAnimation>();
        foreach (var pair in _properties.Pairs)
        {
            var propName = pair.Key.String;
            var targetVal = pair.Value;
            var startVal = _target.GetProperty(propName);

            animations.Add(new PropertyAnimation
            {
                PropertyName = propName,
                StartValue = startVal,
                TargetDynValue = targetVal
            });
        }

        Task.Run(async () =>
        {
            var startTime = DateTime.UtcNow;
            var delayMs = (int)(_info.DelayTime * 1000);
            if (delayMs > 0) await Task.Delay(delayMs, _cts.Token);

            while (!_cts.Token.IsCancellationRequested)
            {
                var elapsed = (DateTime.UtcNow - startTime).TotalSeconds;
                var t = Math.Clamp(elapsed / Math.Max(duration, 0.001), 0, 1);
                var eased = ApplyEasing(t, easingStyle, easingDir);

                foreach (var anim in animations)
                    InterpolateProperty(_target, anim, eased);

                _tree.InstanceChanged?.Invoke();

                if (t >= 1.0) break;
                await Task.Delay(16, _cts.Token);
            }

            // Ensure final values
            foreach (var anim in animations)
                InterpolateProperty(_target, anim, 1.0);

            try { Completed.Fire(_script); } catch { }
        }, _cts.Token);
    }

    public void Cancel() => _cts?.Cancel();
    public void Pause() => _cts?.Cancel();

    private void InterpolateProperty(MockInstance target, PropertyAnimation anim, double t)
    {
        var start = anim.StartValue;
        var targetDyn = anim.TargetDynValue;

        if (start is MockColor3 startColor && targetDyn.UserData?.Object is MockColor3 endColor)
        {
            target.SetProperty(anim.PropertyName, startColor.Lerp(endColor, t));
        }
        else if (start is MockUDim2 startUdim && targetDyn.UserData?.Object is MockUDim2 endUdim)
        {
            target.SetProperty(anim.PropertyName, startUdim.Lerp(endUdim, t));
        }
        else if (start is double startNum && targetDyn.Type == DataType.Number)
        {
            target.SetProperty(anim.PropertyName, startNum + (targetDyn.Number - startNum) * t);
        }
        else if (t >= 1.0)
        {
            // At completion, just set the target value directly
            object? val = targetDyn.Type switch
            {
                DataType.Number => targetDyn.Number,
                DataType.String => targetDyn.String,
                DataType.Boolean => targetDyn.Boolean,
                DataType.UserData => targetDyn.UserData.Object,
                _ => null
            };
            if (val != null) target.SetProperty(anim.PropertyName, val);
        }
    }

    private static double ApplyEasing(double t, int style, int direction)
    {
        double EaseIn(double x) => style switch
        {
            0 => x, // Linear
            1 => 1 - Math.Cos(x * Math.PI / 2), // Sine
            2 => x * x, // Quad
            3 => x * x * x, // Cubic
            4 => x * x * x * x, // Quart
            5 => x * x * x * x * x, // Quint
            6 => x == 0 ? 0 : Math.Pow(2, 10 * x - 10), // Exponential
            8 => 2.70158 * x * x * x - 1.70158 * x * x, // Back
            9 => BounceEaseIn(x),
            10 => ElasticEaseIn(x),
            _ => x
        };

        double EaseOut(double x) => 1 - EaseIn(1 - x);

        return direction switch
        {
            0 => EaseIn(t),
            1 => EaseOut(t),
            2 => t < 0.5 ? EaseIn(t * 2) / 2 : 1 - EaseIn((1 - t) * 2) / 2,
            _ => t
        };
    }

    private static double BounceEaseIn(double t)
    {
        return 1 - BounceEaseOut(1 - t);
    }

    private static double BounceEaseOut(double t)
    {
        if (t < 1 / 2.75) return 7.5625 * t * t;
        if (t < 2 / 2.75) { t -= 1.5 / 2.75; return 7.5625 * t * t + 0.75; }
        if (t < 2.5 / 2.75) { t -= 2.25 / 2.75; return 7.5625 * t * t + 0.9375; }
        t -= 2.625 / 2.75; return 7.5625 * t * t + 0.984375;
    }

    private static double ElasticEaseIn(double t)
    {
        if (t is 0 or 1) return t;
        return -Math.Pow(2, 10 * t - 10) * Math.Sin((t * 10 - 10.75) * (2 * Math.PI / 3));
    }

    private class PropertyAnimation
    {
        public string PropertyName { get; set; } = "";
        public object? StartValue { get; set; }
        public DynValue TargetDynValue { get; set; } = DynValue.Nil;
    }
}
