using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class RemoveTabCommand : IUndoableCommand
{
    private readonly StarLibProject _project;
    private readonly TabModel _tab;
    private int _index;

    public string Description => $"Remove tab '{_tab.Name}'";

    public RemoveTabCommand(StarLibProject project, TabModel tab)
    {
        _project = project;
        _tab = tab;
    }

    public void Execute()
    {
        _index = _project.Tabs.IndexOf(_tab);
        _project.Tabs.Remove(_tab);
    }

    public void Undo()
    {
        if (_index <= _project.Tabs.Count)
            _project.Tabs.Insert(_index, _tab);
        else
            _project.Tabs.Add(_tab);
    }
}
