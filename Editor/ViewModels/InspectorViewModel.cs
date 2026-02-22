using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using StarLibEditor.Models;
using StarLibEditor.Services.Commands;

namespace StarLibEditor.ViewModels;

public partial class InspectorViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private UINode? _selectedNode;
    [ObservableProperty] private string _headerText = "No Selection";

    public InspectorViewModel(MainWindowViewModel main)
    {
        _main = main;
    }

    partial void OnSelectedNodeChanged(UINode? value)
    {
        HeaderText = value != null ? $"{value.Type}: {value.DisplayName}" : "No Selection";
    }

    public void UpdateProperty(string key, object? oldValue, object? newValue)
    {
        if (SelectedNode == null) return;
        var command = new EditPropertyCommand(SelectedNode, key, oldValue, newValue);
        _main.UndoRedo.Execute(command);
        _main.Project.IsDirty = true;
        _main.RegenerateCode();
    }

    public void UpdateCallback(string? oldCode, string? newCode)
    {
        if (SelectedNode == null) return;
        var command = new EditCallbackCommand(SelectedNode, oldCode, newCode);
        _main.UndoRedo.Execute(command);
        _main.Project.IsDirty = true;
        _main.RegenerateCode();
    }

    public void UpdateBindVariable(string? oldVar, string? newVar)
    {
        if (SelectedNode == null) return;
        SelectedNode.BindVariable = newVar;
        _main.Project.IsDirty = true;
        _main.RegenerateCode();
    }

    [RelayCommand]
    private void ToggleEnabled()
    {
        if (SelectedNode == null) return;
        SelectedNode.Enabled = !SelectedNode.Enabled;
        _main.RegenerateCode();
    }

    [RelayCommand]
    private void ToggleVisible()
    {
        if (SelectedNode == null) return;
        SelectedNode.Visible = !SelectedNode.Visible;
        _main.RegenerateCode();
    }
}
