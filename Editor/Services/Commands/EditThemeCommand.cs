using System.Reflection;
using StarLibEditor.Models;

namespace StarLibEditor.Services.Commands;

public class EditThemeCommand : IUndoableCommand
{
    private readonly ThemeModel _theme;
    private readonly string _propertyName;
    private readonly object? _oldValue;
    private readonly object? _newValue;

    public string Description => $"Edit theme '{_propertyName}'";

    public EditThemeCommand(ThemeModel theme, string propertyName, object? oldValue, object? newValue)
    {
        _theme = theme;
        _propertyName = propertyName;
        _oldValue = oldValue;
        _newValue = newValue;
    }

    public void Execute()
    {
        SetProperty(_newValue);
    }

    public void Undo()
    {
        SetProperty(_oldValue);
    }

    private void SetProperty(object? value)
    {
        var prop = typeof(ThemeModel).GetProperty(_propertyName, BindingFlags.Public | BindingFlags.Instance);
        prop?.SetValue(_theme, value);
    }
}
