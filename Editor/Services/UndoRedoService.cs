using CommunityToolkit.Mvvm.ComponentModel;
using StarLibEditor.Services.Commands;

namespace StarLibEditor.Services;

public partial class UndoRedoService : ObservableObject
{
    private readonly Stack<IUndoableCommand> _undoStack = new();
    private readonly Stack<IUndoableCommand> _redoStack = new();
    private const int MaxStackDepth = 200;

    [ObservableProperty] private bool _canUndo;
    [ObservableProperty] private bool _canRedo;
    [ObservableProperty] private string _undoDescription = "";
    [ObservableProperty] private string _redoDescription = "";

    public void Execute(IUndoableCommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear();

        while (_undoStack.Count > MaxStackDepth)
        {
            var items = _undoStack.ToArray();
            _undoStack.Clear();
            for (int i = items.Length - 2; i >= 0; i--)
                _undoStack.Push(items[i]);
        }

        UpdateState();
    }

    public void Undo()
    {
        if (_undoStack.Count == 0) return;
        var command = _undoStack.Pop();
        command.Undo();
        _redoStack.Push(command);
        UpdateState();
    }

    public void Redo()
    {
        if (_redoStack.Count == 0) return;
        var command = _redoStack.Pop();
        command.Execute();
        _undoStack.Push(command);
        UpdateState();
    }

    public void Clear()
    {
        _undoStack.Clear();
        _redoStack.Clear();
        UpdateState();
    }

    private void UpdateState()
    {
        CanUndo = _undoStack.Count > 0;
        CanRedo = _redoStack.Count > 0;
        UndoDescription = CanUndo ? $"Undo: {_undoStack.Peek().Description}" : "";
        RedoDescription = CanRedo ? $"Redo: {_redoStack.Peek().Description}" : "";
    }
}
