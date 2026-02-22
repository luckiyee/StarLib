using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using Newtonsoft.Json;

namespace StarLibEditor.Models;

public partial class StarLibProject : ObservableObject
{
    [ObservableProperty] private ProjectMeta _meta = new();
    [ObservableProperty] private ProjectSettings _settings = new();
    [ObservableProperty] private WindowConfig _window = new();
    [ObservableProperty] private ObservableCollection<TabModel> _tabs = new();
    [ObservableProperty] private ObservableCollection<TemplateModel> _templates = new();
    [ObservableProperty] private ProjectAssets _assets = new();

    [JsonIgnore]
    public string? FilePath { get; set; }

    [JsonIgnore]
    public bool IsDirty { get; set; }

    public static StarLibProject CreateDefault()
    {
        var project = new StarLibProject();
        project.Meta.ProjectName = "Untitled Project";
        project.Meta.SchemaVersion = "1.0";
        project.Meta.AppVersion = "1.0.0";
        project.Meta.CreatedAt = DateTime.UtcNow.ToString("o");
        project.Meta.UpdatedAt = project.Meta.CreatedAt;

        var mainTab = new TabModel { Name = "Main" };
        mainTab.Nodes.Add(new UINode(WidgetType.Section));
        mainTab.Nodes.Add(new UINode(WidgetType.Button));
        project.Tabs.Add(mainTab);

        return project;
    }
}

public partial class ProjectMeta : ObservableObject
{
    [ObservableProperty] private string _schemaVersion = "1.0";
    [ObservableProperty] private string _appVersion = "1.0.0";
    [ObservableProperty] private string _createdAt = DateTime.UtcNow.ToString("o");
    [ObservableProperty] private string _updatedAt = DateTime.UtcNow.ToString("o");
    [ObservableProperty] private string _projectName = "Untitled";
    [ObservableProperty] private string? _starLibFileHash;
}

public partial class ProjectSettings : ObservableObject
{
    [ObservableProperty] private bool _useUpgradedStarLib = false;
    [ObservableProperty] private string _starLibPath = "StarLib/StarLib.lua";
    [ObservableProperty] private bool _bundleStarLib = true;
}

public partial class ProjectAssets : ObservableObject
{
    [ObservableProperty] private ObservableCollection<AssetEntry> _icons = new();
}

public partial class AssetEntry : ObservableObject
{
    [ObservableProperty] private string _id = Guid.NewGuid().ToString();
    [ObservableProperty] private string _name = "";
    [ObservableProperty] private string _assetId = "";
}
