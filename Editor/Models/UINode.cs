using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Newtonsoft.Json;

namespace StarLibEditor.Models;

public partial class UINode : ObservableObject
{
    [ObservableProperty] private string _id = Guid.NewGuid().ToString();
    [ObservableProperty] private WidgetType _type;
    [ObservableProperty] private bool _enabled = true;
    [ObservableProperty] private bool _visible = true;
    [ObservableProperty] private string? _callbackCode;
    [ObservableProperty] private string? _bindVariable;

    [ObservableProperty]
    private ObservableDictionary _props = new();

    public UINode() { }

    public UINode(WidgetType type)
    {
        Type = type;
        Props = GetDefaultProps(type);
    }

    public string DisplayName => Props.TryGetValue("Name", out var n) && n is string s ? s
        : Props.TryGetValue("Text", out var t) && t is string ts ? ts
        : Type.ToString();

    public static ObservableDictionary GetDefaultProps(WidgetType type)
    {
        var p = new ObservableDictionary();
        switch (type)
        {
            case WidgetType.Section:
                p["Text"] = "Section";
                break;
            case WidgetType.Label:
                p["Text"] = "Label";
                break;
            case WidgetType.Paragraph:
                p["Title"] = "Title";
                p["Content"] = "Content text here.";
                break;
            case WidgetType.Button:
                p["Name"] = "Button";
                p["Description"] = "";
                p["Icon"] = "";
                break;
            case WidgetType.Toggle:
                p["Name"] = "Toggle";
                p["Description"] = "";
                p["CurrentValue"] = false;
                p["Flag"] = "ToggleFlag";
                break;
            case WidgetType.Slider:
                p["Name"] = "Slider";
                p["Description"] = "";
                p["Min"] = 0.0;
                p["Max"] = 100.0;
                p["CurrentValue"] = 50.0;
                p["Increment"] = 1.0;
                p["Suffix"] = "";
                p["Flag"] = "SliderFlag";
                break;
            case WidgetType.Dropdown:
                p["Name"] = "Dropdown";
                p["Description"] = "";
                p["Options"] = new ObservableCollection<string> { "Option 1", "Option 2", "Option 3" };
                p["CurrentOption"] = "Option 1";
                p["MultipleOptions"] = false;
                p["Flag"] = "DropdownFlag";
                break;
            case WidgetType.Input:
                p["Name"] = "Input";
                p["Description"] = "";
                p["PlaceholderText"] = "...";
                p["Default"] = "";
                p["RemoveTextAfterFocusLost"] = false;
                p["Flag"] = "InputFlag";
                break;
            case WidgetType.Keybind:
                p["Name"] = "Keybind";
                p["Default"] = "F";
                p["HoldToInteract"] = false;
                p["Flag"] = "KeybindFlag";
                break;
            case WidgetType.ColorPicker:
                p["Name"] = "Color";
                p["Default"] = "#FFFFFF";
                p["Description"] = "";
                p["Flag"] = "ColorFlag";
                break;
            case WidgetType.Stat:
                p["Name"] = "Status";
                p["Value"] = "0";
                p["Suffix"] = "";
                break;
            case WidgetType.Separator:
                break;
            case WidgetType.Spacer:
                p["Height"] = 10.0;
                break;
            case WidgetType.ProgressBar:
                p["Name"] = "Progress";
                p["Min"] = 0.0;
                p["Max"] = 100.0;
                p["Default"] = 0.0;
                p["ShowLabel"] = true;
                p["Height"] = 12.0;
                break;
            case WidgetType.Badge:
                p["Name"] = "Status";
                p["Text"] = "Online";
                p["Color"] = "#00C864";
                p["TextColor"] = "#000000";
                break;
            case WidgetType.Table:
                p["Name"] = "Table";
                p["Columns"] = new ObservableCollection<string> { "Column 1", "Column 2" };
                p["RowHeight"] = 28.0;
                p["MaxHeight"] = 200.0;
                break;
            case WidgetType.HorizontalRow:
                p["Padding"] = 4.0;
                p["Alignment"] = "Left";
                break;
            case WidgetType.VerticalStack:
                p["Padding"] = 4.0;
                break;
            case WidgetType.GridContainer:
                p["Columns"] = 2;
                p["CellPadding"] = 4.0;
                break;
        }
        return p;
    }

    public UINode Clone()
    {
        var json = JsonConvert.SerializeObject(this);
        var clone = JsonConvert.DeserializeObject<UINode>(json)!;
        clone.Id = Guid.NewGuid().ToString();
        return clone;
    }
}

public class ObservableDictionary : ObservableCollection<KeyValuePair<string, object?>>
{
    private readonly Dictionary<string, object?> _dict = new();

    public object? this[string key]
    {
        get => _dict.TryGetValue(key, out var v) ? v : null;
        set
        {
            _dict[key] = value;
            var existing = this.FirstOrDefault(kv => kv.Key == key);
            if (existing.Key != null)
            {
                var idx = IndexOf(existing);
                RemoveAt(idx);
                Insert(idx, new KeyValuePair<string, object?>(key, value));
            }
            else
            {
                Add(new KeyValuePair<string, object?>(key, value));
            }
        }
    }

    public bool TryGetValue(string key, out object? value) => _dict.TryGetValue(key, out value);
    public bool ContainsKey(string key) => _dict.ContainsKey(key);
    public ICollection<string> Keys => _dict.Keys;
    public ICollection<object?> Values => _dict.Values;
    public Dictionary<string, object?> ToDictionary() => new(_dict);
}
