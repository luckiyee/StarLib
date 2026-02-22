using System.Collections.ObjectModel;
using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using StarLibEditor.Models;
using StarLibEditor.Services;

namespace StarLibEditor.ViewModels;

public partial class MainWindowViewModel : ObservableObject
{
    [ObservableProperty] private StarLibProject _project = StarLibProject.CreateDefault();
    [ObservableProperty] private string _titleText = "StarLib Editor — Untitled Project";
    [ObservableProperty] private bool _isPaletteVisible = true;
    [ObservableProperty] private bool _isHierarchyVisible = true;
    [ObservableProperty] private bool _isInspectorVisible = true;
    [ObservableProperty] private bool _isCodePanelVisible = true;

    public DesignerViewModel Designer { get; }
    public HierarchyViewModel Hierarchy { get; }
    public InspectorViewModel Inspector { get; }
    public PaletteViewModel Palette { get; }
    public CodePanelViewModel CodePanel { get; }
    public UndoRedoService UndoRedo { get; }
    public ProjectService ProjectService { get; }
    public CodeGeneratorService CodeGenerator { get; }

    public MainWindowViewModel()
    {
        UndoRedo = new UndoRedoService();
        ProjectService = new ProjectService();
        CodeGenerator = new CodeGeneratorService();

        Designer = new DesignerViewModel(this);
        Hierarchy = new HierarchyViewModel(this);
        Inspector = new InspectorViewModel(this);
        Palette = new PaletteViewModel(this);
        CodePanel = new CodePanelViewModel(this);

        RegenerateCode();
    }

    public void RegenerateCode()
    {
        CodePanel.GeneratedCode = CodeGenerator.Generate(Project);
    }

    partial void OnProjectChanged(StarLibProject value)
    {
        TitleText = $"StarLib Editor — {value.Meta.ProjectName}";
        Designer.OnProjectLoaded();
        Hierarchy.OnProjectLoaded();
        RegenerateCode();
    }

    [RelayCommand]
    private void NewProject()
    {
        Project = StarLibProject.CreateDefault();
        UndoRedo.Clear();
    }

    [RelayCommand]
    private async Task OpenProject()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "StarLib Project (*.starlibproj)|*.starlibproj|All Files|*.*",
            Title = "Open StarLib Project"
        };
        if (dialog.ShowDialog() == true)
        {
            var loaded = await ProjectService.LoadAsync(dialog.FileName);
            if (loaded != null)
            {
                Project = loaded;
                UndoRedo.Clear();
            }
        }
    }

    [RelayCommand]
    private async Task SaveProject()
    {
        if (string.IsNullOrEmpty(Project.FilePath))
        {
            await SaveProjectAs();
            return;
        }
        Project.Meta.UpdatedAt = DateTime.UtcNow.ToString("o");
        await ProjectService.SaveAsync(Project, Project.FilePath);
        Project.IsDirty = false;
        TitleText = $"StarLib Editor — {Project.Meta.ProjectName}";
    }

    [RelayCommand]
    private async Task SaveProjectAs()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "StarLib Project (*.starlibproj)|*.starlibproj",
            Title = "Save StarLib Project",
            FileName = Project.Meta.ProjectName + ".starlibproj"
        };
        if (dialog.ShowDialog() == true)
        {
            Project.FilePath = dialog.FileName;
            await SaveProject();
        }
    }

    [RelayCommand]
    private void Undo()
    {
        UndoRedo.Undo();
        RegenerateCode();
    }

    [RelayCommand]
    private void Redo()
    {
        UndoRedo.Redo();
        RegenerateCode();
    }

    [RelayCommand]
    private void ExportLua()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "Lua Script (*.lua)|*.lua",
            Title = "Export Lua Script",
            FileName = Project.Meta.ProjectName + ".lua"
        };
        if (dialog.ShowDialog() == true)
        {
            File.WriteAllText(dialog.FileName, CodePanel.GeneratedCode);
        }
    }

    [RelayCommand]
    private void CopyLuaToClipboard()
    {
        Clipboard.SetText(CodePanel.GeneratedCode);
    }

    [RelayCommand]
    private void OpenEmulator()
    {
        var emulatorWindow = new Views.EmulatorWindow(this);
        emulatorWindow.Show();
    }

    [RelayCommand]
    private void TogglePalette() => IsPaletteVisible = !IsPaletteVisible;

    [RelayCommand]
    private void ToggleHierarchy() => IsHierarchyVisible = !IsHierarchyVisible;

    [RelayCommand]
    private void ToggleInspector() => IsInspectorVisible = !IsInspectorVisible;

    [RelayCommand]
    private void ToggleCodePanel() => IsCodePanelVisible = !IsCodePanelVisible;
}
