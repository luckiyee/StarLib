using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

public class LuaTaskScheduler
{
    private readonly Script _script;
    private readonly CancellationToken _ct;
    private readonly List<ScheduledTask> _pending = new();
    private readonly object _lock = new();
    private Timer? _timer;
    private bool _running;

    public LuaTaskScheduler(Script script, CancellationToken ct)
    {
        _script = script;
        _ct = ct;
    }

    public void Start()
    {
        _running = true;
        _timer = new Timer(Tick, null, 0, 16); // ~60fps tick
    }

    public void Stop()
    {
        _running = false;
        _timer?.Dispose();
        _timer = null;
        lock (_lock) _pending.Clear();
    }

    public void Wait(double seconds)
    {
        if (_ct.IsCancellationRequested) return;
        // Cooperative wait: sleep the thread for the duration
        // In a real implementation this would yield the coroutine
        var ms = (int)(seconds * 1000);
        if (ms > 0)
            Thread.Sleep(Math.Min(ms, 10000));
    }

    public void Spawn(DynValue fn, DynValue[]? args = null)
    {
        if (_ct.IsCancellationRequested) return;
        lock (_lock)
        {
            _pending.Add(new ScheduledTask
            {
                Function = fn,
                Args = args,
                ExecuteAt = DateTime.UtcNow
            });
        }
    }

    public void Delay(double seconds, DynValue fn, DynValue[]? args = null)
    {
        if (_ct.IsCancellationRequested) return;
        lock (_lock)
        {
            _pending.Add(new ScheduledTask
            {
                Function = fn,
                Args = args,
                ExecuteAt = DateTime.UtcNow.AddSeconds(seconds)
            });
        }
    }

    private void Tick(object? state)
    {
        if (!_running || _ct.IsCancellationRequested) return;

        List<ScheduledTask> ready;
        lock (_lock)
        {
            ready = _pending.Where(t => DateTime.UtcNow >= t.ExecuteAt).ToList();
            foreach (var t in ready) _pending.Remove(t);
        }

        foreach (var task in ready)
        {
            if (_ct.IsCancellationRequested) break;
            try
            {
                if (task.Args != null && task.Args.Length > 0)
                    _script.Call(task.Function, task.Args);
                else
                    _script.Call(task.Function);
            }
            catch (ScriptRuntimeException ex)
            {
                System.Diagnostics.Debug.WriteLine($"Task error: {ex.DecoratedMessage}");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Task error: {ex.Message}");
            }
        }
    }

    private class ScheduledTask
    {
        public DynValue Function { get; set; } = DynValue.Nil;
        public DynValue[]? Args { get; set; }
        public DateTime ExecuteAt { get; set; }
    }
}
