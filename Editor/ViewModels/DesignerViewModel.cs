using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using StarLibEditor.Models;

namespace StarLibEditor.ViewModels;

public partial class DesignerViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private double _zoom = 1.0;
    [ObservableProperty] private TabModel? _activeTab;
    [ObservableProperty] private UINode? _selectedNode;
    [ObservableProperty] private ObservableCollection<UINode> _selectedNodes = new();

    public DesignerViewModel(MainWindowViewModel main)
    {
        _main = main;
    }

    public void OnProjectLoaded()
    {
        ActiveTab = _main.Project.Tabs.FirstOrDefault();
        SelectedNode = null;
        SelectedNodes.Clear();
    }

    partial void OnSelectedNodeChanged(UINode? value)
    {
        _main.Inspector.SelectedNode = value;
        _main.Hierarchy.SyncSelection(value);
    }

    partial void OnActiveTabChanged(TabModel? value)
    {
        SelectedNode = null;
    }

    [RelayCommand]
    private void ZoomIn()
    {
        Zoom = Math.Min(Zoom + 0.1, 3.0);
    }

    [RelayCommand]
    private void ZoomOut()
    {
        Zoom = Math.Max(Zoom - 0.1, 0.3);
    }

    [RelayCommand]
    private void ZoomReset()
    {
        Zoom = 1.0;
    }

    public void SelectNode(UINode node)
    {
        SelectedNode = node;
        if (!SelectedNodes.Contains(node))
        {
            SelectedNodes.Clear();
            SelectedNodes.Add(node);
        }
    }

    public void AddNodeToTab(WidgetType type, TabModel? tab = null, int insertIndex = -1)
    {
        tab ??= ActiveTab;
        if (tab == null) return;

        var node = new UINode(type);
        var command = new Services.Commands.AddNodeCommand(tab, node, insertIndex);
        _main.UndoRedo.Execute(command);
        SelectedNode = node;
        _main.RegenerateCode();
    }

    public void RemoveNode(UINode node)
    {
        if (ActiveTab == null) return;
        var index = ActiveTab.Nodes.IndexOf(node);
        if (index < 0) return;

        var command = new Services.Commands.RemoveNodeCommand(ActiveTab, node, index);
        _main.UndoRedo.Execute(command);
        SelectedNode = null;
        _main.RegenerateCode();
    }

    public void MoveNode(int fromIndex, int toIndex)
    {
        if (ActiveTab == null) return;
        var command = new Services.Commands.MoveNodeCommand(ActiveTab, fromIndex, toIndex);
        _main.UndoRedo.Execute(command);
        _main.RegenerateCode();
    }

    public void DuplicateNode(UINode node)
    {
        if (ActiveTab == null) return;
        var clone = node.Clone();
        var index = ActiveTab.Nodes.IndexOf(node) + 1;
        var command = new Services.Commands.AddNodeCommand(ActiveTab, clone, index);
        _main.UndoRedo.Execute(command);
        SelectedNode = clone;
        _main.RegenerateCode();
    }
}
