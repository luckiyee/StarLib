using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class EditPropertyCommand : IUndoableCommand
{
    private readonly UINode _node;
    private readonly string _key;
    private readonly object? _oldValue;
    private readonly object? _newValue;

    public string Description => $"Edit {_key} on '{_node.DisplayName}'";

    public EditPropertyCommand(UINode node, string key, object? oldValue, object? newValue)
    {
        _node = node;
        _key = key;
        _oldValue = oldValue;
        _newValue = newValue;
    }

    public void Execute()
    {
        _node.Props[_key] = _newValue;
    }

    public void Undo()
    {
        _node.Props[_key] = _oldValue;
    }
}
