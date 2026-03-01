using CommunityToolkit.Mvvm.ComponentModel;

namespace StarLibEditor.Models;

public partial class WindowConfig : ObservableObject
{
    [ObservableProperty] private string _name = "StarLib Interface";
    [ObservableProperty] private string _loadingTitle = "StarLib Interface Suite";
    [ObservableProperty] private string _loadingSubtitle = "by Sirius-inspired StarLib";
    [ObservableProperty] private string _icon = "";
    [ObservableProperty] private string _toggleKey = "RightShift";
    [ObservableProperty] private bool _resizable = true;
    [ObservableProperty] private bool _enableSearch = true;
    [ObservableProperty] private string _themePreset = "Default";
    [ObservableProperty] private ThemeModel _theme = new();
    [ObservableProperty] private ConfigurationSavingConfig _configurationSaving = new();
    [ObservableProperty] private KeySystemConfig _keySystem = new();
    [ObservableProperty] private DiscordConfig _discord = new();
    [ObservableProperty] private MonetizationConfig _monetization = new();
}

public partial class ConfigurationSavingConfig : ObservableObject
{
    [ObservableProperty] private bool _enabled = true;
    [ObservableProperty] private string _folderName = "StarLib";
    [ObservableProperty] private string _fileName = "config.json";
}

public partial class KeySystemConfig : ObservableObject
{
    [ObservableProperty] private bool _enabled = false;
    [ObservableProperty] private string _title = "StarLib Key System";
    [ObservableProperty] private string _subtitle = "Enter your access key";
    [ObservableProperty] private string _note = "Your key is never shared.";
    [ObservableProperty] private string _saveKey = "LastKey";
    [ObservableProperty] private bool _grabKeyFromSite = false;
    [ObservableProperty] private string _keyUrl = "";
    [ObservableProperty] private string _validKeysCsv = "STARDUST";
}

public partial class DiscordConfig : ObservableObject
{
    [ObservableProperty] private bool _enabled = false;
    [ObservableProperty] private string _invite = "";
    [ObservableProperty] private bool _rememberPrompt = true;
}

public partial class MonetizationConfig : ObservableObject
{
    [ObservableProperty] private bool _enabled = false;
    [ObservableProperty] private string _strategy = "Donations";
    [ObservableProperty] private string _details = "";
}
