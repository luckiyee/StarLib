using StarLibEditor.Models;
using StarLibEditor.Services;
using Xunit;

namespace UnitTests;

public class CodeGeneratorTests
{
    private readonly CodeGeneratorService _gen = new();

    [Fact]
    public void Generate_DefaultProject_ContainsLoadstring()
    {
        var project = StarLibProject.CreateDefault();
        var lua = _gen.Generate(project);

        Assert.Contains("loadstring(readfile(", lua);
        Assert.Contains("StarLib:CreateWindow", lua);
    }

    [Fact]
    public void Generate_ContainsTabName()
    {
        var project = StarLibProject.CreateDefault();
        project.Tabs[0].Name = "Combat";
        var lua = _gen.Generate(project);

        Assert.Contains("Name = \"Combat\"", lua);
        Assert.Contains("Window:CreateTab({", lua);
    }

    [Fact]
    public void Generate_ButtonHasCallbackPlaceholder()
    {
        var project = StarLibProject.CreateDefault();
        var lua = _gen.Generate(project);

        Assert.Contains("CreateButton", lua);
        Assert.Contains("TODO: Add your callback here", lua);
    }

    [Fact]
    public void Generate_ButtonWithCallback_EmitsCode()
    {
        var project = StarLibProject.CreateDefault();
        var btn = project.Tabs[0].Nodes.First(n => n.Type == WidgetType.Button);
        btn.CallbackCode = "print(\"hello\")";
        var lua = _gen.Generate(project);

        Assert.Contains("print(\"hello\")", lua);
    }

    [Fact]
    public void Generate_Slider_UsesRangeSyntax()
    {
        var project = StarLibProject.CreateDefault();
        var tab = project.Tabs[0];
        var slider = new UINode(WidgetType.Slider);
        slider.Props["Name"] = "Speed";
        slider.Props["Min"] = 0.0;
        slider.Props["Max"] = 100.0;
        slider.Props["CurrentValue"] = 16.0;
        tab.Nodes.Add(slider);

        var lua = _gen.Generate(project);

        Assert.Contains("CreateSlider", lua);
        Assert.Contains("Range = {0, 100}", lua);
        Assert.Contains("CurrentValue = 16", lua);
    }

    [Fact]
    public void Generate_Toggle_UsesCurrentValue()
    {
        var project = StarLibProject.CreateDefault();
        var tab = project.Tabs[0];
        var toggle = new UINode(WidgetType.Toggle);
        toggle.Props["Name"] = "Fly";
        toggle.Props["CurrentValue"] = false;
        tab.Nodes.Add(toggle);

        var lua = _gen.Generate(project);

        Assert.Contains("CreateToggle", lua);
        Assert.Contains("CurrentValue = false", lua);
    }

    [Fact]
    public void Generate_Deterministic_SameInputSameOutput()
    {
        var project = StarLibProject.CreateDefault();
        var lua1 = _gen.Generate(project);
        var lua2 = _gen.Generate(project);

        // Remove timestamps (line 3) for comparison
        var lines1 = lua1.Split('\n').Where((l, i) => i != 2).ToArray();
        var lines2 = lua2.Split('\n').Where((l, i) => i != 2).ToArray();

        Assert.Equal(string.Join("\n", lines1), string.Join("\n", lines2));
    }

    [Fact]
    public void Generate_DisabledNode_Excluded()
    {
        var project = StarLibProject.CreateDefault();
        var btn = project.Tabs[0].Nodes.First(n => n.Type == WidgetType.Button);
        btn.Enabled = false;

        var lua = _gen.Generate(project);

        Assert.DoesNotContain("CreateButton", lua);
    }

    [Fact]
    public void Generate_ThemeOverrides_OnlyIncludesChanged()
    {
        var project = StarLibProject.CreateDefault();
        project.Window.Theme.Accent = System.Windows.Media.Color.FromRgb(255, 0, 0);

        var lua = _gen.Generate(project);

        Assert.Contains("ThemeOverrides = {", lua);
        Assert.Contains("Accent = Color3.fromRGB(255, 0, 0)", lua);
        Assert.DoesNotContain("Background = Color3", lua);
    }

    [Fact]
    public void Generate_Minified_NoComments()
    {
        var project = StarLibProject.CreateDefault();
        var lua = _gen.Generate(project, minify: true);

        Assert.DoesNotContain("-- Generated", lua);
        Assert.DoesNotContain("\n\n", lua);
    }

    [Fact]
    public void Generate_Dropdown_WithOptions()
    {
        var project = StarLibProject.CreateDefault();
        var tab = project.Tabs[0];
        var dd = new UINode(WidgetType.Dropdown);
        dd.Props["Name"] = "Server";
        dd.Props["Options"] = new System.Collections.ObjectModel.ObservableCollection<string> { "US", "EU", "Asia" };
        dd.Props["Default"] = "US";
        tab.Nodes.Add(dd);

        var lua = _gen.Generate(project);

        Assert.Contains("CreateDropdown", lua);
        Assert.Contains("\"US\", \"EU\", \"Asia\"", lua);
    }

    [Fact]
    public void Generate_Section_UsesStringArg()
    {
        var project = StarLibProject.CreateDefault();
        var lua = _gen.Generate(project);

        Assert.Contains("CreateSection(\"Section\")", lua);
    }
}
