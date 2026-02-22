using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class MoveNodeCommand : IUndoableCommand
{
    private readonly TabModel _tab;
    private readonly int _fromIndex;
    private readonly int _toIndex;

    public string Description => $"Move node from {_fromIndex} to {_toIndex}";

    public MoveNodeCommand(TabModel tab, int fromIndex, int toIndex)
    {
        _tab = tab;
        _fromIndex = fromIndex;
        _toIndex = toIndex;
    }

    public void Execute()
    {
        _tab.Nodes.Move(_fromIndex, _toIndex);
    }

    public void Undo()
    {
        _tab.Nodes.Move(_toIndex, _fromIndex);
    }
}
