using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class InsertTemplateCommand : IUndoableCommand
{
    private readonly TabModel _tab;
    private readonly List<UINode> _nodes;

    public string Description => $"Insert template ({_nodes.Count} nodes)";

    public InsertTemplateCommand(TabModel tab, List<UINode> nodes)
    {
        _tab = tab;
        _nodes = nodes;
    }

    public void Execute()
    {
        foreach (var node in _nodes)
            _tab.Nodes.Add(node);
    }

    public void Undo()
    {
        foreach (var node in _nodes)
            _tab.Nodes.Remove(node);
    }
}
