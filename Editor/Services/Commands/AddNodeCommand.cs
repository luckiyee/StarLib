using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class AddNodeCommand : IUndoableCommand
{
    private readonly TabModel _tab;
    private readonly UINode _node;
    private readonly int _index;

    public string Description => $"Add {_node.Type} '{_node.DisplayName}'";

    public AddNodeCommand(TabModel tab, UINode node, int index = -1)
    {
        _tab = tab;
        _node = node;
        _index = index;
    }

    public void Execute()
    {
        if (_index >= 0 && _index <= _tab.Nodes.Count)
            _tab.Nodes.Insert(_index, _node);
        else
            _tab.Nodes.Add(_node);
    }

    public void Undo()
    {
        _tab.Nodes.Remove(_node);
    }
}
