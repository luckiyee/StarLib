using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class RenameTabCommand : IUndoableCommand
{
    private readonly TabModel _tab;
    private readonly string _oldName;
    private readonly string _newName;

    public string Description => $"Rename tab '{_oldName}' to '{_newName}'";

    public RenameTabCommand(TabModel tab, string oldName, string newName)
    {
        _tab = tab;
        _oldName = oldName;
        _newName = newName;
    }

    public void Execute()
    {
        _tab.Name = _newName;
    }

    public void Undo()
    {
        _tab.Name = _oldName;
    }
}
