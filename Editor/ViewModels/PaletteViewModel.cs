using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using StarLibEditor.Models;

namespace StarLibEditor.ViewModels;

public partial class PaletteViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private int _selectedPaletteTab; // 0=Palette, 1=Assets, 2=Templates

    public ObservableCollection<PaletteGroup> Groups { get; } = new();
    public ObservableCollection<AssetEntry> Assets => _main.Project.Assets.Icons;
    public ObservableCollection<TemplateModel> Templates => _main.Project.Templates;

    public PaletteViewModel(MainWindowViewModel main)
    {
        _main = main;
        BuildPaletteGroups();
    }

    private void BuildPaletteGroups()
    {
        Groups.Clear();

        Groups.Add(new PaletteGroup("STRUCTURE", new[]
        {
            new PaletteItem(WidgetType.Section, "Section", "Header label"),
            new PaletteItem(WidgetType.Label, "Label", "Text label"),
            new PaletteItem(WidgetType.Paragraph, "Paragraph", "Title + content block"),
            new PaletteItem(WidgetType.Separator, "Separator", "Divider line"),
            new PaletteItem(WidgetType.Spacer, "Spacer", "Vertical spacing"),
        }));

        Groups.Add(new PaletteGroup("INTERACTIVE", new[]
        {
            new PaletteItem(WidgetType.Button, "Button", "Clickable button"),
            new PaletteItem(WidgetType.Toggle, "Toggle", "On/off switch"),
            new PaletteItem(WidgetType.Slider, "Slider", "Value slider"),
            new PaletteItem(WidgetType.Dropdown, "Dropdown", "Single or multi-select"),
            new PaletteItem(WidgetType.Input, "Input", "Text input field"),
            new PaletteItem(WidgetType.Keybind, "Keybind", "Key binding picker"),
            new PaletteItem(WidgetType.ColorPicker, "ColorPicker", "Color picker"),
        }));

        Groups.Add(new PaletteGroup("RAYFIELD GEN2", new[]
        {
            new PaletteItem(WidgetType.Stat, "Stat", "Live stat readout"),
            new PaletteItem(WidgetType.ProgressBar, "ProgressBar", "Progress indicator"),
            new PaletteItem(WidgetType.Table, "Table", "Data table/grid"),
            new PaletteItem(WidgetType.Badge, "Badge", "Status badge/chip"),
        }));
    }

    [RelayCommand]
    private void AddWidget(PaletteItem item)
    {
        _main.Designer.AddNodeToTab(item.Type);
    }

    [RelayCommand]
    private void InsertTemplate(TemplateModel template)
    {
        if (_main.Designer.ActiveTab == null) return;
        var nodes = template.Nodes.Select(n => n.Clone()).ToList();
        var batch = new Services.Commands.InsertTemplateCommand(_main.Designer.ActiveTab, nodes);
        _main.UndoRedo.Execute(batch);
        _main.RegenerateCode();
    }
}

public class PaletteGroup
{
    public string Name { get; }
    public PaletteItem[] Items { get; }
    public PaletteGroup(string name, PaletteItem[] items) { Name = name; Items = items; }
}

public class PaletteItem
{
    public WidgetType Type { get; }
    public string Label { get; }
    public string Tooltip { get; }
    public PaletteItem(WidgetType type, string label, string tooltip)
    {
        Type = type; Label = label; Tooltip = tooltip;
    }
}
