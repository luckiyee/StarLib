using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using System.Windows;

namespace StarLibEditor.ViewModels;

public partial class CodePanelViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private string _generatedCode = "";
    [ObservableProperty] private bool _isEditMode = false;
    [ObservableProperty] private bool _isMinified = false;
    [ObservableProperty] private ObservableCollection<DiagnosticEntry> _diagnostics = new();

    public CodePanelViewModel(MainWindowViewModel main)
    {
        _main = main;
    }

    partial void OnIsMinifiedChanged(bool value)
    {
        GeneratedCode = _main.CodeGenerator.Generate(_main.Project, value);
    }

    [RelayCommand]
    private void CopyToClipboard()
    {
        Clipboard.SetText(GeneratedCode);
    }

    [RelayCommand]
    private void ExportToFile()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "Lua Script (*.lua)|*.lua",
            FileName = _main.Project.Meta.ProjectName + ".lua"
        };
        if (dialog.ShowDialog() == true)
        {
            File.WriteAllText(dialog.FileName, GeneratedCode);
        }
    }

    [RelayCommand]
    private void ToggleEditMode()
    {
        IsEditMode = !IsEditMode;
    }

    public void RunDiagnostics()
    {
        Diagnostics.Clear();
        foreach (var tab in _main.Project.Tabs)
        {
            foreach (var node in tab.Nodes)
            {
                if (node.Type == Models.WidgetType.Button && string.IsNullOrWhiteSpace(node.CallbackCode))
                    Diagnostics.Add(new DiagnosticEntry("Warning", $"Button '{node.DisplayName}' has no callback", node.Id));
                if (node.Type == Models.WidgetType.Dropdown)
                {
                    var opts = node.Props["Options"];
                    if (opts is System.Collections.ICollection c && c.Count == 0)
                        Diagnostics.Add(new DiagnosticEntry("Error", $"Dropdown '{node.DisplayName}' has no options", node.Id));
                }
            }
        }
    }
}

public class DiagnosticEntry
{
    public string Severity { get; }
    public string Message { get; }
    public string NodeId { get; }
    public DiagnosticEntry(string severity, string message, string nodeId)
    {
        Severity = severity; Message = message; NodeId = nodeId;
    }
}
