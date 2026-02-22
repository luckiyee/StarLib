using MoonSharp.Interpreter;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Emulator;

public class RobloxEmulator
{
    private readonly EmulatorViewModel _vm;
    private Script? _script;
    private LuaTaskScheduler? _taskScheduler;
    private MockInstanceTree? _instanceTree;
    private CancellationTokenSource? _cts;

    public MockInstanceTree? InstanceTree => _instanceTree;
    public Script? LuaScript => _script;
    public event Action? OnInstanceTreeChanged;

    public RobloxEmulator(EmulatorViewModel vm)
    {
        _vm = vm;
    }

    public async Task ExecuteAsync(string starLibSource, string userScript)
    {
        _cts = new CancellationTokenSource();
        _script = new Script(CoreModules.Preset_SoftSandbox | CoreModules.Coroutine | CoreModules.OS_Time);
        _instanceTree = new MockInstanceTree();
        _taskScheduler = new LuaTaskScheduler(_script, _cts.Token);

        _instanceTree.InstanceChanged += () => OnInstanceTreeChanged?.Invoke();

        RegisterDataTypes(_script);
        RegisterEnums(_script);
        RegisterGlobals(_script);
        RegisterMockServices(_script);
        RegisterExecutorGlobals(_script);

        _taskScheduler.Start();

        try
        {
            if (!string.IsNullOrWhiteSpace(starLibSource))
            {
                _vm.Log("[Emulator] Loading StarLib.lua...");
                _script.DoString(starLibSource, null, "StarLib.lua");
            }

            _vm.Log("[Emulator] Running user script...");
            await Task.Run(() => _script.DoString(userScript, null, "UserScript.lua"), _cts.Token);
            _vm.Log("[Emulator] Script execution complete.");
        }
        catch (ScriptRuntimeException ex)
        {
            _vm.LogError($"Lua Runtime Error: {ex.DecoratedMessage}");
        }
        catch (SyntaxErrorException ex)
        {
            _vm.LogError($"Lua Syntax Error: {ex.DecoratedMessage}");
        }
        catch (OperationCanceledException)
        {
            _vm.Log("[Emulator] Execution cancelled.");
        }
        catch (Exception ex)
        {
            _vm.LogError($"Emulator Error: {ex.Message}");
        }
    }

    public void Stop()
    {
        _cts?.Cancel();
        _taskScheduler?.Stop();
        _instanceTree?.DestroyAll();
        _script = null;
        _instanceTree = null;
    }

    private void RegisterDataTypes(Script script)
    {
        UserData.RegisterType<MockColor3>();
        UserData.RegisterType<MockUDim2>();
        UserData.RegisterType<MockUDim>();
        UserData.RegisterType<MockVector2>();
        UserData.RegisterType<MockVector3>();
        UserData.RegisterType<MockTweenInfo>();

        // Color3
        var color3Table = new Table(script);
        color3Table["fromRGB"] = (Func<int, int, int, MockColor3>)MockColor3.FromRGB;
        color3Table["new"] = (Func<double, double, double, MockColor3>)MockColor3.New;
        script.Globals["Color3"] = color3Table;

        // UDim2
        var udim2Table = new Table(script);
        udim2Table["new"] = (Func<double, double, double, double, MockUDim2>)MockUDim2.New;
        udim2Table["fromScale"] = (Func<double, double, MockUDim2>)((xs, ys) => MockUDim2.New(xs, 0, ys, 0));
        udim2Table["fromOffset"] = (Func<double, double, MockUDim2>)((xo, yo) => MockUDim2.New(0, xo, 0, yo));
        script.Globals["UDim2"] = udim2Table;

        // UDim
        var udimTable = new Table(script);
        udimTable["new"] = (Func<double, double, MockUDim>)MockUDim.New;
        script.Globals["UDim"] = udimTable;

        // Vector2
        var vec2Table = new Table(script);
        vec2Table["new"] = (Func<double, double, MockVector2>)MockVector2.New;
        script.Globals["Vector2"] = vec2Table;

        // Vector3
        var vec3Table = new Table(script);
        vec3Table["new"] = (Func<double, double, double, MockVector3>)MockVector3.New;
        script.Globals["Vector3"] = vec3Table;

        // TweenInfo
        var tweenInfoTable = new Table(script);
        tweenInfoTable["new"] = DynValue.NewCallback((ctx, args) =>
        {
            var time = args.Count > 0 ? args[0].Number : 1.0;
            var easingStyle = args.Count > 1 ? (int)args[1].Number : 0;
            var easingDir = args.Count > 2 ? (int)args[2].Number : 0;
            var repeatCount = args.Count > 3 ? (int)args[3].Number : 0;
            var reverses = args.Count > 4 && args[4].Boolean;
            var delay = args.Count > 5 ? args[5].Number : 0;
            return DynValue.FromObject(ctx.GetScript(),
                new MockTweenInfo(time, easingStyle, easingDir, repeatCount, reverses, delay));
        });
        script.Globals["TweenInfo"] = tweenInfoTable;
    }

    private void RegisterEnums(Script script)
    {
        var enumTable = MockEnums.BuildEnumTable(script);
        script.Globals["Enum"] = enumTable;
    }

    private void RegisterGlobals(Script script)
    {
        // print / warn / error
        script.Globals["print"] = DynValue.NewCallback((ctx, args) =>
        {
            var msg = string.Join("\t", args.GetArray().Select(a => a.ToPrintString()));
            _vm.Log(msg);
            return DynValue.Nil;
        });

        script.Globals["warn"] = DynValue.NewCallback((ctx, args) =>
        {
            var msg = string.Join("\t", args.GetArray().Select(a => a.ToPrintString()));
            _vm.LogWarning(msg);
            return DynValue.Nil;
        });

        script.Globals["error"] = DynValue.NewCallback((ctx, args) =>
        {
            var msg = args.Count > 0 ? args[0].ToPrintString() : "error";
            _vm.LogError(msg);
            throw new ScriptRuntimeException(msg);
        });

        script.Globals["printconsole"] = script.Globals["print"];
        script.Globals["typeof"] = DynValue.NewCallback((ctx, args) =>
        {
            if (args[0].UserData?.Object is MockInstance mi)
                return DynValue.NewString(mi.ClassName);
            return DynValue.NewString(args[0].Type.ToString());
        });

        // Instance.new
        var instanceTable = new Table(script);
        instanceTable["new"] = DynValue.NewCallback((ctx, args) =>
        {
            var className = args[0].String;
            MockInstance? parent = null;
            if (args.Count > 1 && args[1].UserData?.Object is MockInstance p)
                parent = p;
            var inst = _instanceTree!.CreateInstance(className, parent);
            return DynValue.FromObject(ctx.GetScript(), inst);
        });
        script.Globals["Instance"] = instanceTable;

        // task library
        var taskTable = new Table(script);
        taskTable["wait"] = DynValue.NewCallback((ctx, args) =>
        {
            var seconds = args.Count > 0 ? args[0].Number : 0;
            _taskScheduler!.Wait(seconds);
            return DynValue.NewNumber(seconds);
        });
        taskTable["spawn"] = DynValue.NewCallback((ctx, args) =>
        {
            var fn = args[0];
            var fnArgs = args.GetArray().Skip(1).ToArray();
            _taskScheduler!.Spawn(fn, fnArgs);
            return DynValue.Nil;
        });
        taskTable["delay"] = DynValue.NewCallback((ctx, args) =>
        {
            var delay = args[0].Number;
            var fn = args[1];
            _taskScheduler!.Delay(delay, fn);
            return DynValue.Nil;
        });
        taskTable["cancel"] = DynValue.NewCallback((ctx, args) =>
        {
            return DynValue.Nil;
        });
        script.Globals["task"] = taskTable;

        // wait (global)
        script.Globals["wait"] = DynValue.NewCallback((ctx, args) =>
        {
            var seconds = args.Count > 0 ? args[0].Number : 0.03;
            _taskScheduler!.Wait(seconds);
            return DynValue.NewNumber(seconds);
        });

        // pcall / xpcall
        script.Globals["pcall"] = DynValue.NewCallback((ctx, args) =>
        {
            try
            {
                var fn = args[0];
                var fnArgs = args.GetArray().Skip(1).ToArray();
                var result = ctx.GetScript().Call(fn, fnArgs);
                return DynValue.NewTuple(DynValue.True, result);
            }
            catch (Exception ex)
            {
                return DynValue.NewTuple(DynValue.False, DynValue.NewString(ex.Message));
            }
        });

        script.Globals["xpcall"] = DynValue.NewCallback((ctx, args) =>
        {
            try
            {
                var fn = args[0];
                var handler = args[1];
                var fnArgs = args.GetArray().Skip(2).ToArray();
                var result = ctx.GetScript().Call(fn, fnArgs);
                return DynValue.NewTuple(DynValue.True, result);
            }
            catch (Exception ex)
            {
                var handler = args[1];
                var errResult = ctx.GetScript().Call(handler, DynValue.NewString(ex.Message));
                return DynValue.NewTuple(DynValue.False, errResult);
            }
        });
    }

    private void RegisterMockServices(Script script)
    {
        var coreGui = _instanceTree!.CoreGui;
        var playerGui = _instanceTree.PlayerGui;
        var localPlayer = _instanceTree.LocalPlayer;

        // game DataModel
        var gameTable = new Table(script);
        gameTable["GetService"] = DynValue.NewCallback((ctx, args) =>
        {
            var serviceName = args.Count > 1 ? args[1].String : args[0].String;
            return serviceName switch
            {
                "Players" => DynValue.FromObject(script, _instanceTree.PlayersService),
                "TweenService" => DynValue.FromObject(script, _instanceTree.TweenService),
                "UserInputService" => DynValue.FromObject(script, _instanceTree.UserInputService),
                "CoreGui" => DynValue.FromObject(script, coreGui),
                "RunService" => DynValue.FromObject(script, _instanceTree.RunService),
                _ => DynValue.Nil
            };
        });
        script.Globals["game"] = gameTable;
        script.Globals["workspace"] = new Table(script);
    }

    private void RegisterExecutorGlobals(Script script)
    {
        var synTable = new Table(script);
        synTable["protect_gui"] = DynValue.NewCallback((ctx, args) => DynValue.Nil);
        script.Globals["syn"] = synTable;

        script.Globals["gethui"] = DynValue.NewCallback((ctx, args) =>
            DynValue.FromObject(script, _instanceTree!.CoreGui));

        script.Globals["getgenv"] = DynValue.NewCallback((ctx, args) =>
            DynValue.NewTable(script));

        script.Globals["getrenv"] = DynValue.NewCallback((ctx, args) =>
            DynValue.NewTable(script));

        script.Globals["isrbxactive"] = DynValue.NewCallback((ctx, args) => DynValue.True);

        script.Globals["getrawmetatable"] = DynValue.NewCallback((ctx, args) =>
        {
            if (args[0].Table != null) return DynValue.NewTable(script);
            return DynValue.Nil;
        });

        script.Globals["isreadonly"] = DynValue.NewCallback((ctx, args) => DynValue.False);
        script.Globals["setreadonly"] = DynValue.NewCallback((ctx, args) => DynValue.Nil);
        script.Globals["getcallingscript"] = DynValue.NewCallback((ctx, args) => DynValue.Nil);

        script.Globals["firesignal"] = DynValue.NewCallback((ctx, args) =>
        {
            if (args[0].UserData?.Object is MockSignal sig)
            {
                var fireArgs = args.GetArray().Skip(1).ToArray();
                sig.Fire(script, fireArgs);
            }
            return DynValue.Nil;
        });

        // readfile / writefile
        var basePath = AppDomain.CurrentDomain.BaseDirectory;
        script.Globals["readfile"] = DynValue.NewCallback((ctx, args) =>
        {
            var path = Path.Combine(basePath, args[0].String);
            if (File.Exists(path))
                return DynValue.NewString(File.ReadAllText(path));
            _vm.LogWarning($"readfile: File not found: {args[0].String}");
            return DynValue.NewString("");
        });

        script.Globals["writefile"] = DynValue.NewCallback((ctx, args) =>
        {
            var path = Path.Combine(basePath, args[0].String);
            var dir = Path.GetDirectoryName(path);
            if (dir != null) Directory.CreateDirectory(dir);
            File.WriteAllText(path, args[1].String);
            _vm.Log($"writefile: Wrote to {args[0].String}");
            return DynValue.Nil;
        });

        script.Globals["loadstring"] = DynValue.NewCallback((ctx, args) =>
        {
            var code = args[0].String;
            return DynValue.NewCallback((ctx2, args2) =>
            {
                return ctx2.GetScript().DoString(code);
            });
        });
    }
}
