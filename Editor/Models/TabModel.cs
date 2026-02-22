using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;

namespace StarLibEditor.Models;

public partial class TabModel : ObservableObject
{
    [ObservableProperty] private string _id = Guid.NewGuid().ToString();
    [ObservableProperty] private string _name = "Tab";
    [ObservableProperty] private string? _icon;
    [ObservableProperty] private ObservableCollection<UINode> _nodes = new();
}
