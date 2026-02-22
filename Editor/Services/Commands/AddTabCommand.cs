using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class AddTabCommand : IUndoableCommand
{
    private readonly StarLibProject _project;
    private readonly TabModel _tab;

    public string Description => $"Add tab '{_tab.Name}'";

    public AddTabCommand(StarLibProject project, TabModel tab)
    {
        _project = project;
        _tab = tab;
    }

    public void Execute()
    {
        _project.Tabs.Add(_tab);
    }

    public void Undo()
    {
        _project.Tabs.Remove(_tab);
    }
}
