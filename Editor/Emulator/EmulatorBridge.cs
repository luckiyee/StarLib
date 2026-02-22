using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

/// <summary>
/// Sets up the MoonSharp Script with custom type descriptors so that
/// MockInstance property access (indexing) works naturally in Lua.
/// </summary>
public static class EmulatorBridge
{
    public static void RegisterInstanceProxy(Script script)
    {
        // Register a custom type descriptor for MockInstance that routes
        // __index and __newindex through the instance's property system
        UserData.RegisterType<MockInstance>(InteropAccessMode.Default);
        UserData.RegisterType<MockSignal>();
        UserData.RegisterType<SignalConnection>();
        UserData.RegisterType<MockTween>();

        // Set up a metatable-based proxy for MockInstance so that
        // any property access on an Instance goes through our custom Index/NewIndex
        script.Globals.MetaTable = script.Globals.MetaTable ?? new Table(script);
    }

    /// <summary>
    /// Creates a MoonSharp proxy table for a MockInstance that routes
    /// all property reads/writes through the mock property system.
    /// </summary>
    public static DynValue CreateInstanceProxy(Script script, MockInstance instance)
    {
        var proxy = new Table(script);
        var meta = new Table(script);

        meta["__index"] = DynValue.NewCallback((ctx, args) =>
        {
            var key = args[1];
            if (key.Type != DataType.String) return DynValue.Nil;
            var name = key.String;

            // Methods
            switch (name)
            {
                case "Destroy":
                    return DynValue.NewCallback((c2, a2) => { instance.Destroy(); return DynValue.Nil; });
                case "FindFirstChild":
                    return DynValue.NewCallback((c2, a2) =>
                    {
                        var childName = a2[1].String;
                        var recursive = a2.Count > 2 && a2[2].Boolean;
                        var child = instance.FindFirstChild(childName, recursive);
                        return child == null ? DynValue.Nil : DynValue.FromObject(script, child);
                    });
                case "FindFirstChildOfClass":
                    return DynValue.NewCallback((c2, a2) =>
                    {
                        var child = instance.FindFirstChildOfClass(a2[1].String);
                        return child == null ? DynValue.Nil : DynValue.FromObject(script, child);
                    });
                case "WaitForChild":
                    return DynValue.NewCallback((c2, a2) =>
                    {
                        var child = instance.WaitForChild(a2[1].String);
                        return DynValue.FromObject(script, child);
                    });
                case "GetChildren":
                    return DynValue.NewCallback((c2, a2) =>
                    {
                        var children = instance.GetChildren();
                        var t = new Table(script);
                        foreach (var c in children)
                            t.Append(DynValue.FromObject(script, c));
                        return DynValue.NewTable(t);
                    });
                case "GetDescendants":
                    return DynValue.NewCallback((c2, a2) =>
                    {
                        var desc = instance.GetDescendants();
                        var t = new Table(script);
                        foreach (var d in desc)
                            t.Append(DynValue.FromObject(script, d));
                        return DynValue.NewTable(t);
                    });
                case "IsA":
                    return DynValue.NewCallback((c2, a2) =>
                        DynValue.NewBoolean(instance.IsA(a2[1].String)));
                case "GetPropertyChangedSignal":
                    return DynValue.NewCallback((c2, a2) =>
                        DynValue.FromObject(script, instance.GetPropertyChangedSignal(a2[1].String)));
                case "Clone":
                    return DynValue.NewCallback((c2, a2) => instance.Clone());
            }

            return instance.Index(script, key);
        });

        meta["__newindex"] = DynValue.NewCallback((ctx, args) =>
        {
            instance.NewIndex(script, args[1], args[2]);
            return DynValue.Nil;
        });

        meta["__tostring"] = DynValue.NewCallback((ctx, args) =>
            DynValue.NewString(instance.ToString()));

        proxy.MetaTable = meta;
        return DynValue.NewTable(proxy);
    }
}
