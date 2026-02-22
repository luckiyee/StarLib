using Newtonsoft.Json;
using StarLibEditor.Models;
using Xunit;

namespace UnitTests;

public class ProjectSerializationTests
{
    [Fact]
    public void Roundtrip_DefaultProject_Preserved()
    {
        var project = StarLibProject.CreateDefault();
        project.Meta.ProjectName = "Test Project";
        project.Window.Name = "My Script";
        project.Window.ToggleKey = "RightShift";

        var json = JsonConvert.SerializeObject(project, Formatting.Indented,
            new JsonSerializerSettings { Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() } });

        var loaded = JsonConvert.DeserializeObject<StarLibProject>(json,
            new JsonSerializerSettings { Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() } });

        Assert.NotNull(loaded);
        Assert.Equal("Test Project", loaded!.Meta.ProjectName);
        Assert.Equal("My Script", loaded.Window.Name);
        Assert.Equal("RightShift", loaded.Window.ToggleKey);
        Assert.Single(loaded.Tabs);
    }

    [Fact]
    public void Serialize_WidgetType_AsString()
    {
        var node = new UINode(WidgetType.Button);
        var json = JsonConvert.SerializeObject(node,
            new JsonSerializerSettings { Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() } });

        Assert.Contains("\"Button\"", json);
    }

    [Fact]
    public void Deserialize_HandlesAllWidgetTypes()
    {
        foreach (WidgetType wt in Enum.GetValues<WidgetType>())
        {
            var node = new UINode(wt);
            var json = JsonConvert.SerializeObject(node,
                new JsonSerializerSettings { Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() } });
            var loaded = JsonConvert.DeserializeObject<UINode>(json,
                new JsonSerializerSettings { Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() } });

            Assert.NotNull(loaded);
            Assert.Equal(wt, loaded!.Type);
        }
    }

    [Fact]
    public void Project_SchemaVersion_IsSet()
    {
        var project = StarLibProject.CreateDefault();
        Assert.Equal("1.0", project.Meta.SchemaVersion);
        Assert.Equal("1.0.0", project.Meta.AppVersion);
    }

    [Fact]
    public void Project_TabHasNodes()
    {
        var project = StarLibProject.CreateDefault();
        Assert.NotEmpty(project.Tabs);
        Assert.NotEmpty(project.Tabs[0].Nodes);
    }

    [Fact]
    public void Node_Clone_HasNewId()
    {
        var original = new UINode(WidgetType.Button);
        original.Props["Name"] = "Original";
        original.CallbackCode = "print('test')";

        var clone = original.Clone();

        Assert.NotEqual(original.Id, clone.Id);
        Assert.Equal(original.Type, clone.Type);
    }
}
