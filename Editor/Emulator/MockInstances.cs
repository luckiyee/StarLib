using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

[MoonSharpUserData]
public class MockInstance
{
    private readonly Dictionary<string, object?> _properties = new();
    private readonly List<MockInstance> _children = new();
    private MockInstance? _parent;
    private bool _destroyed;

    public string ClassName { get; set; }
    public string Name { get => GetPropStr("Name"); set => SetProperty("Name", value); }
    public bool Visible { get => GetPropBool("Visible", true); set => SetProperty("Visible", value); }

    public MockInstance? Parent
    {
        get => _parent;
        set
        {
            if (_destroyed) return;
            var old = _parent;
            old?._children.Remove(this);
            _parent = value;
            _parent?._children.Add(this);

            old?.ChildRemoved.Fire(GetScript()!, DynValue.FromObject(GetScript()!, this));
            _parent?.ChildAdded.Fire(GetScript()!, DynValue.FromObject(GetScript()!, this));
            OnTree?.InstanceChanged?.Invoke();
        }
    }

    // Signals
    public MockSignal ChildAdded { get; } = new("ChildAdded");
    public MockSignal ChildRemoved { get; } = new("ChildRemoved");
    public MockSignal Destroying { get; } = new("Destroying");
    public MockSignal Changed { get; } = new("Changed");

    // Input/Button signals
    public MockSignal MouseButton1Click { get; } = new("MouseButton1Click");
    public MockSignal MouseButton1Down { get; } = new("MouseButton1Down");
    public MockSignal MouseButton1Up { get; } = new("MouseButton1Up");
    public MockSignal MouseEnter { get; } = new("MouseEnter");
    public MockSignal MouseLeave { get; } = new("MouseLeave");
    public MockSignal InputBegan { get; } = new("InputBegan");
    public MockSignal InputChanged { get; } = new("InputChanged");
    public MockSignal InputEnded { get; } = new("InputEnded");
    public MockSignal FocusLost { get; } = new("FocusLost");

    // Property changed signals cache
    private readonly Dictionary<string, MockSignal> _propChangedSignals = new();

    [MoonSharpHidden] public MockInstanceTree? OnTree { get; set; }
    [MoonSharpHidden] private Script? _script;
    [MoonSharpHidden] public Script? GetScript() => _script ?? OnTree?.Script;
    [MoonSharpHidden] public void SetScript(Script s) => _script = s;

    public MockInstance(string className)
    {
        ClassName = className;
        InitDefaults();
    }

    private void InitDefaults()
    {
        _properties["Name"] = ClassName;
        _properties["Visible"] = true;

        switch (ClassName)
        {
            case "Frame":
            case "TextLabel":
            case "TextButton":
            case "TextBox":
            case "ImageLabel":
            case "ImageButton":
                _properties["BackgroundColor3"] = new MockColor3(1, 1, 1);
                _properties["BackgroundTransparency"] = 0.0;
                _properties["BorderSizePixel"] = 0.0;
                _properties["Size"] = MockUDim2.New(0, 100, 0, 100);
                _properties["Position"] = MockUDim2.New(0, 0, 0, 0);
                _properties["AnchorPoint"] = MockVector2.New(0, 0);
                _properties["ZIndex"] = 1.0;
                _properties["ClipsDescendants"] = false;
                break;
            case "ScreenGui":
                _properties["Enabled"] = true;
                _properties["ZIndexBehavior"] = 0;
                _properties["ResetOnSpawn"] = true;
                break;
            case "ScrollingFrame":
                _properties["BackgroundColor3"] = new MockColor3(1, 1, 1);
                _properties["BackgroundTransparency"] = 0.0;
                _properties["Size"] = MockUDim2.New(0, 100, 0, 100);
                _properties["Position"] = MockUDim2.New(0, 0, 0, 0);
                _properties["CanvasSize"] = MockUDim2.New(0, 0, 0, 0);
                _properties["ScrollBarThickness"] = 6.0;
                _properties["CanvasPosition"] = MockVector2.New(0, 0);
                _properties["ClipsDescendants"] = true;
                break;
        }

        if (ClassName is "TextLabel" or "TextButton" or "TextBox")
        {
            _properties["Text"] = "";
            _properties["TextColor3"] = new MockColor3(0, 0, 0);
            _properties["TextSize"] = 14.0;
            _properties["Font"] = 4; // GothamSemibold enum value
            _properties["TextXAlignment"] = 1; // Center
            _properties["TextYAlignment"] = 1; // Center
            _properties["TextWrapped"] = false;
            _properties["TextTransparency"] = 0.0;
            _properties["RichText"] = false;
        }

        if (ClassName == "TextButton")
        {
            _properties["AutoButtonColor"] = true;
        }

        if (ClassName == "TextBox")
        {
            _properties["PlaceholderText"] = "";
            _properties["ClearTextOnFocus"] = true;
        }

        if (ClassName is "ImageLabel" or "ImageButton")
        {
            _properties["Image"] = "";
            _properties["ImageColor3"] = new MockColor3(1, 1, 1);
            _properties["ImageTransparency"] = 0.0;
        }

        if (ClassName == "UICorner")
            _properties["CornerRadius"] = MockUDim.New(0, 8);

        if (ClassName == "UIPadding")
        {
            _properties["PaddingLeft"] = MockUDim.New(0, 0);
            _properties["PaddingRight"] = MockUDim.New(0, 0);
            _properties["PaddingTop"] = MockUDim.New(0, 0);
            _properties["PaddingBottom"] = MockUDim.New(0, 0);
        }

        if (ClassName == "UIListLayout")
        {
            _properties["SortOrder"] = 0;
            _properties["Padding"] = MockUDim.New(0, 0);
            _properties["FillDirection"] = 1; // Vertical
            _properties["HorizontalAlignment"] = 0;
            _properties["VerticalAlignment"] = 0;
            _properties["AbsoluteContentSize"] = MockVector2.New(0, 0);
        }

        if (ClassName == "UIGridLayout")
        {
            _properties["CellSize"] = MockUDim2.New(0, 100, 0, 100);
            _properties["CellPadding"] = MockUDim2.New(0, 5, 0, 5);
            _properties["FillDirection"] = 0;
        }

        if (ClassName == "UIStroke")
        {
            _properties["Color"] = new MockColor3(0, 0, 0);
            _properties["Thickness"] = 1.0;
            _properties["Transparency"] = 0.0;
        }

        if (ClassName == "UIAspectRatioConstraint")
        {
            _properties["AspectRatio"] = 1.0;
        }
    }

    // Property access via indexer for MoonSharp
    [MoonSharpHidden]
    public void SetProperty(string name, object? value)
    {
        var old = _properties.ContainsKey(name) ? _properties[name] : null;
        _properties[name] = value;

        var script = GetScript();
        if (script != null)
        {
            Changed.Fire(script, DynValue.NewString(name));
            if (_propChangedSignals.TryGetValue(name, out var sig))
                sig.Fire(script);
        }
        OnTree?.InstanceChanged?.Invoke();
    }

    [MoonSharpHidden]
    public object? GetProperty(string name) =>
        _properties.TryGetValue(name, out var v) ? v : null;

    private string GetPropStr(string name) =>
        _properties.TryGetValue(name, out var v) && v is string s ? s : "";

    private bool GetPropBool(string name, bool def = false) =>
        _properties.TryGetValue(name, out var v) && v is bool b ? b : def;

    // Roblox-compatible property access through DynValue
    [MoonSharpHidden]
    public DynValue Index(Script script, DynValue key)
    {
        var name = key.String;

        // Check signals first
        var signal = name switch
        {
            "MouseButton1Click" => MouseButton1Click,
            "MouseButton1Down" => MouseButton1Down,
            "MouseButton1Up" => MouseButton1Up,
            "MouseEnter" => MouseEnter,
            "MouseLeave" => MouseLeave,
            "InputBegan" => InputBegan,
            "InputChanged" => InputChanged,
            "InputEnded" => InputEnded,
            "FocusLost" => FocusLost,
            "ChildAdded" => ChildAdded,
            "ChildRemoved" => ChildRemoved,
            "Destroying" => Destroying,
            "Changed" => Changed,
            _ => null
        };
        if (signal != null) return DynValue.FromObject(script, signal);

        // Check children by name
        var child = _children.FirstOrDefault(c => c.Name == name);
        if (child != null) return DynValue.FromObject(script, child);

        // Check properties
        if (_properties.TryGetValue(name, out var val))
            return val == null ? DynValue.Nil : DynValue.FromObject(script, val);

        // Special properties
        if (name == "Parent") return _parent == null ? DynValue.Nil : DynValue.FromObject(script, _parent);
        if (name == "ClassName") return DynValue.NewString(ClassName);
        if (name == "AbsoluteSize") return DynValue.FromObject(script, MockVector2.New(100, 100));
        if (name == "AbsolutePosition") return DynValue.FromObject(script, MockVector2.New(0, 0));

        return DynValue.Nil;
    }

    [MoonSharpHidden]
    public void NewIndex(Script script, DynValue key, DynValue value)
    {
        var name = key.String;
        if (name == "Parent")
        {
            Parent = value.IsNil() ? null : value.UserData?.Object as MockInstance;
            return;
        }

        object? converted = value.Type switch
        {
            DataType.Number => value.Number,
            DataType.String => value.String,
            DataType.Boolean => value.Boolean,
            DataType.UserData => value.UserData.Object,
            DataType.Nil => null,
            _ => value
        };
        SetProperty(name, converted);
    }

    // Methods
    public void Destroy()
    {
        _destroyed = true;
        var script = GetScript();
        if (script != null) Destroying.Fire(script);

        foreach (var child in _children.ToList())
            child.Destroy();

        Parent = null;
        ChildAdded.DisconnectAll();
        ChildRemoved.DisconnectAll();
        Changed.DisconnectAll();
        Destroying.DisconnectAll();
        OnTree?.RemoveInstance(this);
    }

    public MockInstance? FindFirstChild(string name, bool recursive = false)
    {
        foreach (var c in _children)
        {
            if (c.Name == name) return c;
            if (recursive)
            {
                var found = c.FindFirstChild(name, true);
                if (found != null) return found;
            }
        }
        return null;
    }

    public MockInstance? FindFirstChildOfClass(string className)
    {
        return _children.FirstOrDefault(c => c.ClassName == className);
    }

    public MockInstance WaitForChild(string name, double? timeout = null)
    {
        var child = FindFirstChild(name);
        if (child != null) return child;
        // In emulator, create a placeholder if not found
        child = new MockInstance("Folder") { OnTree = OnTree };
        child.SetProperty("Name", name);
        child.Parent = this;
        return child;
    }

    public List<MockInstance> GetChildren() => new(_children);

    public List<MockInstance> GetDescendants()
    {
        var result = new List<MockInstance>();
        foreach (var c in _children)
        {
            result.Add(c);
            result.AddRange(c.GetDescendants());
        }
        return result;
    }

    public bool IsA(string className) => ClassName == className || IsBaseClass(className);

    private bool IsBaseClass(string className) => className switch
    {
        "GuiObject" => ClassName is "Frame" or "TextLabel" or "TextButton" or "TextBox"
                        or "ImageLabel" or "ImageButton" or "ScrollingFrame",
        "GuiBase2d" => IsBaseClass("GuiObject") || ClassName == "ScreenGui",
        "GuiButton" => ClassName is "TextButton" or "ImageButton",
        "GuiLabel" => ClassName is "TextLabel" or "ImageLabel",
        "Instance" => true,
        "UIComponent" => ClassName.StartsWith("UI"),
        "UILayout" => ClassName is "UIListLayout" or "UIGridLayout",
        _ => false
    };

    public MockSignal GetPropertyChangedSignal(string propertyName)
    {
        if (!_propChangedSignals.ContainsKey(propertyName))
            _propChangedSignals[propertyName] = new MockSignal($"PropertyChanged:{propertyName}");
        return _propChangedSignals[propertyName];
    }

    public DynValue Clone()
    {
        var clone = new MockInstance(ClassName) { OnTree = OnTree };
        foreach (var kv in _properties)
            clone._properties[kv.Key] = kv.Value;
        clone.Name = Name + "_Clone";
        return DynValue.FromObject(GetScript()!, clone);
    }

    [MoonSharpHidden]
    public IReadOnlyList<MockInstance> Children => _children;

    [MoonSharpHidden]
    public Dictionary<string, object?> Properties => _properties;

    public override string ToString() => $"{ClassName} \"{Name}\"";
}
