using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

[MoonSharpUserData]
public class MockSignal
{
    private readonly List<SignalConnection> _connections = new();
    private readonly string _name;

    public MockSignal(string name = "Signal")
    {
        _name = name;
    }

    [MoonSharpHidden]
    public void Fire(Script script, params DynValue[] args)
    {
        foreach (var conn in _connections.ToList())
        {
            if (conn.IsConnected)
            {
                try
                {
                    script.Call(conn.Callback, args);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"Signal '{_name}' handler error: {ex.Message}");
                }
            }
        }
    }

    public SignalConnection Connect(DynValue callback)
    {
        var conn = new SignalConnection(callback, this);
        _connections.Add(conn);
        return conn;
    }

    public DynValue Wait()
    {
        // Simplified: returns immediately
        return DynValue.Nil;
    }

    [MoonSharpHidden]
    public void DisconnectAll()
    {
        foreach (var c in _connections) c.IsConnected = false;
        _connections.Clear();
    }

    [MoonSharpHidden]
    internal void RemoveConnection(SignalConnection conn)
    {
        _connections.Remove(conn);
    }
}

[MoonSharpUserData]
public class SignalConnection
{
    [MoonSharpHidden] public DynValue Callback { get; }
    [MoonSharpHidden] public bool IsConnected { get; set; } = true;
    private readonly MockSignal _signal;

    public bool Connected => IsConnected;

    public SignalConnection(DynValue callback, MockSignal signal)
    {
        Callback = callback;
        _signal = signal;
    }

    public void Disconnect()
    {
        IsConnected = false;
        _signal.RemoveConnection(this);
    }
}
