using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using StarLibEditor.Models;

namespace StarLibEditor.ViewModels;

public partial class HierarchyViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private string _searchFilter = "";
    [ObservableProperty] private UINode? _selectedHierarchyNode;

    public HierarchyViewModel(MainWindowViewModel main)
    {
        _main = main;
    }

    public void OnProjectLoaded()
    {
        SelectedHierarchyNode = null;
    }

    public void SyncSelection(UINode? node)
    {
        SelectedHierarchyNode = node;
    }

    partial void OnSelectedHierarchyNodeChanged(UINode? value)
    {
        if (value != null && value != _main.Designer.SelectedNode)
        {
            _main.Designer.SelectNode(value);
        }
    }

    [RelayCommand]
    private void AddTab()
    {
        var tab = new TabModel { Name = $"Tab {_main.Project.Tabs.Count + 1}" };
        var command = new Services.Commands.AddTabCommand(_main.Project, tab);
        _main.UndoRedo.Execute(command);
        _main.Designer.ActiveTab = tab;
        _main.RegenerateCode();
    }

    [RelayCommand]
    private void RemoveTab(TabModel tab)
    {
        if (_main.Project.Tabs.Count <= 1) return;
        var command = new Services.Commands.RemoveTabCommand(_main.Project, tab);
        _main.UndoRedo.Execute(command);
        _main.Designer.ActiveTab = _main.Project.Tabs.FirstOrDefault();
        _main.RegenerateCode();
    }

    [RelayCommand]
    private void DuplicateNode(UINode node)
    {
        _main.Designer.DuplicateNode(node);
    }

    [RelayCommand]
    private void DeleteNode(UINode node)
    {
        _main.Designer.RemoveNode(node);
    }

    public bool MatchesFilter(UINode node)
    {
        if (string.IsNullOrWhiteSpace(SearchFilter)) return true;
        return node.DisplayName.Contains(SearchFilter, StringComparison.OrdinalIgnoreCase)
            || node.Type.ToString().Contains(SearchFilter, StringComparison.OrdinalIgnoreCase);
    }
}
