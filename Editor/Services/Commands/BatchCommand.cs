namespace StarLibEditor.Services.Commands;

public class BatchCommand : IUndoableCommand
{
    private readonly List<IUndoableCommand> _commands;

    public string Description { get; }

    public BatchCommand(string description, List<IUndoableCommand> commands)
    {
        Description = description;
        _commands = commands;
    }

    public void Execute()
    {
        foreach (var cmd in _commands)
            cmd.Execute();
    }

    public void Undo()
    {
        for (int i = _commands.Count - 1; i >= 0; i--)
            _commands[i].Undo();
    }
}
