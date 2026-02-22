using StarLibEditor.Models;
using StarLibEditor.Services;
using StarLibEditor.Services.Commands;
using Xunit;

namespace UnitTests;

public class UndoRedoTests
{
    [Fact]
    public void Execute_PushesToUndoStack()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        var node = new UINode(WidgetType.Button);

        service.Execute(new AddNodeCommand(tab, node));

        Assert.True(service.CanUndo);
        Assert.False(service.CanRedo);
        Assert.Single(tab.Nodes);
    }

    [Fact]
    public void Undo_RestoresPreviousState()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        var node = new UINode(WidgetType.Button);

        service.Execute(new AddNodeCommand(tab, node));
        Assert.Single(tab.Nodes);

        service.Undo();
        Assert.Empty(tab.Nodes);
        Assert.False(service.CanUndo);
        Assert.True(service.CanRedo);
    }

    [Fact]
    public void Redo_ReappliesCommand()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        var node = new UINode(WidgetType.Button);

        service.Execute(new AddNodeCommand(tab, node));
        service.Undo();
        service.Redo();

        Assert.Single(tab.Nodes);
        Assert.True(service.CanUndo);
        Assert.False(service.CanRedo);
    }

    [Fact]
    public void Execute_ClearsRedoStack()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();

        service.Execute(new AddNodeCommand(tab, new UINode(WidgetType.Button)));
        service.Undo();

        service.Execute(new AddNodeCommand(tab, new UINode(WidgetType.Toggle)));

        Assert.False(service.CanRedo);
    }

    [Fact]
    public void EditProperty_UndoRestoresOldValue()
    {
        var service = new UndoRedoService();
        var node = new UINode(WidgetType.Button);
        node.Props["Name"] = "Original";

        service.Execute(new EditPropertyCommand(node, "Name", "Original", "Changed"));
        Assert.Equal("Changed", node.Props["Name"]);

        service.Undo();
        Assert.Equal("Original", node.Props["Name"]);
    }

    [Fact]
    public void MoveNode_UndoRestoresPosition()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        tab.Nodes.Add(new UINode(WidgetType.Button) { });
        tab.Nodes.Add(new UINode(WidgetType.Toggle) { });

        var firstId = tab.Nodes[0].Id;
        var secondId = tab.Nodes[1].Id;

        service.Execute(new MoveNodeCommand(tab, 0, 1));
        Assert.Equal(secondId, tab.Nodes[0].Id);

        service.Undo();
        Assert.Equal(firstId, tab.Nodes[0].Id);
    }

    [Fact]
    public void BatchCommand_UndoAllAtOnce()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        var commands = new List<IUndoableCommand>
        {
            new AddNodeCommand(tab, new UINode(WidgetType.Button)),
            new AddNodeCommand(tab, new UINode(WidgetType.Toggle)),
            new AddNodeCommand(tab, new UINode(WidgetType.Slider)),
        };

        service.Execute(new BatchCommand("Add 3 nodes", commands));
        Assert.Equal(3, tab.Nodes.Count);

        service.Undo();
        Assert.Empty(tab.Nodes);
    }

    [Fact]
    public void Clear_EmptiesBothStacks()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();

        service.Execute(new AddNodeCommand(tab, new UINode(WidgetType.Button)));
        service.Undo();

        Assert.True(service.CanRedo);

        service.Clear();
        Assert.False(service.CanUndo);
        Assert.False(service.CanRedo);
    }

    [Fact]
    public void Description_ReflectsAction()
    {
        var service = new UndoRedoService();
        var tab = new TabModel();
        var node = new UINode(WidgetType.Button);
        node.Props["Name"] = "Teleport";

        service.Execute(new AddNodeCommand(tab, node));
        Assert.Contains("Teleport", service.UndoDescription);
    }

    [Fact]
    public void AddTab_RemoveTab_UndoRedo()
    {
        var service = new UndoRedoService();
        var project = StarLibProject.CreateDefault();
        var newTab = new TabModel { Name = "Settings" };

        service.Execute(new AddTabCommand(project, newTab));
        Assert.Equal(2, project.Tabs.Count);

        service.Execute(new RemoveTabCommand(project, newTab));
        Assert.Single(project.Tabs);

        service.Undo();
        Assert.Equal(2, project.Tabs.Count);
    }
}
