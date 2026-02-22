using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class EditCallbackCommand : IUndoableCommand
{
    private readonly UINode _node;
    private readonly string? _oldCode;
    private readonly string? _newCode;

    public string Description => $"Edit callback on '{_node.DisplayName}'";

    public EditCallbackCommand(UINode node, string? oldCode, string? newCode)
    {
        _node = node;
        _oldCode = oldCode;
        _newCode = newCode;
    }

    public void Execute()
    {
        _node.CallbackCode = _newCode;
    }

    public void Undo()
    {
        _node.CallbackCode = _oldCode;
    }
}
