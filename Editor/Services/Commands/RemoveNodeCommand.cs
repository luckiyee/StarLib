using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class RemoveNodeCommand : IUndoableCommand
{
    private readonly TabModel _tab;
    private readonly UINode _node;
    private readonly int _index;

    public string Description => $"Remove {_node.Type} '{_node.DisplayName}'";

    public RemoveNodeCommand(TabModel tab, UINode node, int index)
    {
        _tab = tab;
        _node = node;
        _index = index;
    }

    public void Execute()
    {
        _tab.Nodes.Remove(_node);
    }

    public void Undo()
    {
        if (_index <= _tab.Nodes.Count)
            _tab.Nodes.Insert(_index, _node);
        else
            _tab.Nodes.Add(_node);
    }
}
