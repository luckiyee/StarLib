using System.Runtime.InteropServices;
using System.Windows;

namespace StarLibEditor;

public partial class App : Application
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SetProcessDpiAwarenessContext(IntPtr value);

    private static readonly IntPtr DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = new(-4);

    protected override void OnStartup(StartupEventArgs e)
    {
        try
        {
            SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
        }
        catch
        {
            // Fallback for older Windows versions
        }

        base.OnStartup(e);
    }
}
