using CommunityToolkit.Mvvm.ComponentModel;

namespace StarLibEditor.Models;

public partial class WindowConfig : ObservableObject
{
    [ObservableProperty] private string _name = "My Script";
    [ObservableProperty] private string _guiName = "StarLibGui";
    [ObservableProperty] private string? _toggleKey;
    [ObservableProperty] private string? _position;
    [ObservableProperty] private ThemeModel _theme = new();
}
