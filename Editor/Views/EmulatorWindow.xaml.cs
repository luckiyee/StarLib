using System.Windows;
using System.Windows.Media;
using StarLibEditor.Emulator;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Views;

public partial class EmulatorWindow : Window
{
    private readonly MainWindowViewModel _mainVm;
    private readonly EmulatorViewModel _emulatorVm;
    private RobloxEmulator? _emulator;
    private MockRenderer? _renderer;

    public EmulatorWindow(MainWindowViewModel mainVm)
    {
        InitializeComponent();
        _mainVm = mainVm;
        _emulatorVm = new EmulatorViewModel(mainVm);

        ConsoleList.ItemsSource = _emulatorVm.ConsoleOutput;

        _emulatorVm.PropertyChanged += (s, e) =>
        {
            if (e.PropertyName == nameof(EmulatorViewModel.Status))
            {
                Dispatcher.Invoke(() =>
                {
                    StatusText.Text = _emulatorVm.Status;
                    StatusDot.Fill = _emulatorVm.Status switch
                    {
                        "Running" => new SolidColorBrush(Color.FromRgb(0, 200, 100)),
                        "Error" => new SolidColorBrush(Color.FromRgb(255, 68, 68)),
                        _ => new SolidColorBrush(Color.FromRgb(136, 136, 136))
                    };
                });
            }
        };

        _emulatorVm.ConsoleOutput.CollectionChanged += (s, e) =>
        {
            Dispatcher.Invoke(() => ConsoleScroll.ScrollToEnd());
        };
    }

    private async void RunButton_Click(object sender, RoutedEventArgs e)
    {
        if (_emulatorVm.IsRunning) return;

        EmulatorCanvas.Children.Clear();
        _emulatorVm.ConsoleOutput.Clear();
        _emulatorVm.Status = "Running";
        _emulatorVm.IsRunning = true;
        _emulatorVm.PlayerName = PlayerNameBox.Text;

        try
        {
            _emulator = new RobloxEmulator(_emulatorVm);
            _renderer = new MockRenderer(EmulatorCanvas, _emulator.InstanceTree!);
            _renderer.SetScreenSize(1280, 720);

            _emulator.OnInstanceTreeChanged += () =>
            {
                Dispatcher.Invoke(() => _renderer?.RenderAll());
            };

            var starLibSource = LoadStarLib();
            var generatedLua = _mainVm.CodeGenerator.Generate(_mainVm.Project);

            _emulatorVm.Log("[Emulator] Starting execution...");
            await _emulator.ExecuteAsync(starLibSource, generatedLua);

            // Render after execution completes
            Dispatcher.Invoke(() => _renderer?.RenderAll());
        }
        catch (Exception ex)
        {
            _emulatorVm.LogError($"Failed to start emulator: {ex.Message}");
            _emulatorVm.Status = "Error";
            _emulatorVm.IsRunning = false;
        }
    }

    private void StopButton_Click(object sender, RoutedEventArgs e)
    {
        _emulator?.Stop();
        _emulator = null;
        _renderer = null;
        EmulatorCanvas.Children.Clear();
        _emulatorVm.Status = "Stopped";
        _emulatorVm.IsRunning = false;
    }

    private void ReloadButton_Click(object sender, RoutedEventArgs e)
    {
        StopButton_Click(sender, e);
        RunButton_Click(sender, e);
    }

    private void SimulateKeyButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Dialogs.SimulateKeyDialog();
        if (dialog.ShowDialog() == true && _emulator?.InstanceTree != null)
        {
            var keyName = dialog.SelectedKey;
            _emulatorVm.Log($"[Input] Simulated key press: {keyName}");

            // Fire InputBegan on UserInputService
            if (_emulator.LuaScript != null)
            {
                var inputObj = new MoonSharp.Interpreter.Table(_emulator.LuaScript);
                inputObj["UserInputType"] = 6; // Keyboard
                inputObj["KeyCode"] = new MoonSharp.Interpreter.Table(_emulator.LuaScript)
                {
                    ["Name"] = keyName,
                    ["Value"] = 0
                };

                var dynInput = MoonSharp.Interpreter.DynValue.NewTable(inputObj);
                _emulator.InstanceTree.UserInputService.InputBegan.Fire(
                    _emulator.LuaScript, dynInput, MoonSharp.Interpreter.DynValue.False);
            }
        }
    }

    private void ClearConsole_Click(object sender, RoutedEventArgs e)
    {
        _emulatorVm.ConsoleOutput.Clear();
    }

    private string LoadStarLib()
    {
        var paths = new[]
        {
            System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "StarLib", "StarLib.lua"),
            System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "StarLib", "StarLib.lua"),
            @"e:\usb\madness\Lua scripts\StarLib\StarLib.lua"
        };

        foreach (var path in paths)
        {
            if (System.IO.File.Exists(path))
            {
                _emulatorVm.Log($"[Emulator] Loaded StarLib from: {path}");
                return System.IO.File.ReadAllText(path);
            }
        }

        _emulatorVm.LogWarning("[Emulator] StarLib.lua not found, running without it.");
        return "";
    }

    protected override void OnClosed(EventArgs e)
    {
        _emulator?.Stop();
        base.OnClosed(e);
    }
}
