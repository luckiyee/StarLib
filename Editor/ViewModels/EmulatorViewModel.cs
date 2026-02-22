using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;

namespace StarLibEditor.ViewModels;

public partial class EmulatorViewModel : ObservableObject
{
    private readonly MainWindowViewModel _main;

    [ObservableProperty] private string _status = "Stopped";
    [ObservableProperty] private bool _isRunning = false;
    [ObservableProperty] private ObservableCollection<ConsoleEntry> _consoleOutput = new();
    [ObservableProperty] private string _playerName = "TestPlayer";
    [ObservableProperty] private int _playerId = 1;
    [ObservableProperty] private double _screenWidth = 1280;
    [ObservableProperty] private double _screenHeight = 720;

    private Emulator.RobloxEmulator? _emulator;

    public EmulatorViewModel(MainWindowViewModel main)
    {
        _main = main;
    }

    [RelayCommand]
    private async Task Run()
    {
        if (IsRunning) return;

        ConsoleOutput.Clear();
        Status = "Running";
        IsRunning = true;

        try
        {
            _emulator = new Emulator.RobloxEmulator(this);
            var starLibPath = System.IO.Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory, "StarLib", "StarLib.lua");
            var starLibSource = "";
            if (System.IO.File.Exists(starLibPath))
                starLibSource = await System.IO.File.ReadAllTextAsync(starLibPath);
            else
                starLibSource = GetEmbeddedStarLib();

            var generatedLua = _main.CodeGenerator.Generate(_main.Project);
            await _emulator.ExecuteAsync(starLibSource, generatedLua);
        }
        catch (Exception ex)
        {
            LogError($"Emulator error: {ex.Message}");
            Status = "Error";
            IsRunning = false;
        }
    }

    [RelayCommand]
    private void Stop()
    {
        _emulator?.Stop();
        _emulator = null;
        Status = "Stopped";
        IsRunning = false;
    }

    [RelayCommand]
    private void Reload()
    {
        Stop();
        _ = Run();
    }

    public void Log(string message) =>
        System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            ConsoleOutput.Add(new ConsoleEntry("Info", message)));

    public void LogWarning(string message) =>
        System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            ConsoleOutput.Add(new ConsoleEntry("Warning", message)));

    public void LogError(string message) =>
        System.Windows.Application.Current?.Dispatcher.Invoke(() =>
            ConsoleOutput.Add(new ConsoleEntry("Error", message)));

    private string GetEmbeddedStarLib()
    {
        // Fallback: try the workspace StarLib directory
        var paths = new[]
        {
            System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "StarLib", "StarLib.lua"),
            System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "StarLib.lua"),
        };
        foreach (var p in paths)
            if (System.IO.File.Exists(p)) return System.IO.File.ReadAllText(p);
        return "";
    }
}

public class ConsoleEntry
{
    public string Level { get; }
    public string Message { get; }
    public DateTime Timestamp { get; } = DateTime.Now;
    public ConsoleEntry(string level, string message) { Level = level; Message = message; }
}
