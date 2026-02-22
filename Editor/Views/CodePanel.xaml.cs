using System.Windows;
using System.Windows.Controls;
using System.Xml;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Views;

public partial class CodePanel : UserControl
{
    public CodePanel()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;

        SetupLuaHighlighting();
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (DataContext is CodePanelViewModel vm)
        {
            vm.PropertyChanged += (s, args) =>
            {
                if (args.PropertyName == nameof(CodePanelViewModel.GeneratedCode))
                {
                    Dispatcher.Invoke(() =>
                    {
                        if (!CodeEditor.IsFocused || !vm.IsEditMode)
                            CodeEditor.Text = vm.GeneratedCode;
                    });
                }
            };
            CodeEditor.Text = vm.GeneratedCode;
        }
    }

    private void SetupLuaHighlighting()
    {
        var luaXshd = @"<?xml version=""1.0""?>
<SyntaxDefinition name=""Lua"" xmlns=""http://icsharpcode.net/sharpdevelop/syntaxdefinition/2008"">
  <Color name=""Comment"" foreground=""#6A9955"" />
  <Color name=""String"" foreground=""#CE9178"" />
  <Color name=""Keyword"" foreground=""#569CD6"" fontWeight=""bold"" />
  <Color name=""Number"" foreground=""#B5CEA8"" />
  <Color name=""Function"" foreground=""#DCDCAA"" />
  <Color name=""Operator"" foreground=""#D4D4D4"" />
  <Color name=""GlobalVar"" foreground=""#4EC9B0"" />

  <RuleSet>
    <Span color=""Comment"" begin=""--\[\["" end=""\]\]"" multiline=""true"" />
    <Span color=""Comment"" begin=""--"" />
    <Span color=""String"" begin=""&quot;"" end=""&quot;"" escapeCharacter=""\\"" />
    <Span color=""String"" begin=""'"" end=""'"" escapeCharacter=""\\"" />
    <Span color=""String"" begin=""\[\["" end=""\]\]"" multiline=""true"" />

    <Keywords color=""Keyword"">
      <Word>and</Word><Word>break</Word><Word>do</Word><Word>else</Word>
      <Word>elseif</Word><Word>end</Word><Word>false</Word><Word>for</Word>
      <Word>function</Word><Word>if</Word><Word>in</Word><Word>local</Word>
      <Word>nil</Word><Word>not</Word><Word>or</Word><Word>repeat</Word>
      <Word>return</Word><Word>then</Word><Word>true</Word><Word>until</Word>
      <Word>while</Word>
    </Keywords>

    <Keywords color=""GlobalVar"">
      <Word>game</Word><Word>workspace</Word><Word>script</Word>
      <Word>print</Word><Word>warn</Word><Word>error</Word>
      <Word>pcall</Word><Word>xpcall</Word><Word>require</Word>
      <Word>loadstring</Word><Word>readfile</Word><Word>writefile</Word>
      <Word>task</Word><Word>coroutine</Word><Word>math</Word>
      <Word>string</Word><Word>table</Word><Word>pairs</Word><Word>ipairs</Word>
      <Word>tostring</Word><Word>tonumber</Word><Word>type</Word>
      <Word>select</Word><Word>unpack</Word><Word>rawget</Word><Word>rawset</Word>
    </Keywords>

    <Keywords color=""Function"">
      <Word>CreateWindow</Word><Word>CreateTab</Word><Word>CreateButton</Word>
      <Word>CreateToggle</Word><Word>CreateSlider</Word><Word>CreateDropdown</Word>
      <Word>CreateInput</Word><Word>CreateKeybind</Word><Word>CreateColorPicker</Word>
      <Word>CreateSection</Word><Word>CreateLabel</Word><Word>CreateParagraph</Word>
      <Word>Notify</Word><Word>Destroy</Word><Word>Hide</Word><Word>Show</Word>
    </Keywords>

    <Rule color=""Number"">\b\d+(\.\d+)?\b</Rule>
  </RuleSet>
</SyntaxDefinition>";

        using var reader = new XmlTextReader(new System.IO.StringReader(luaXshd));
        var highlighting = HighlightingLoader.Load(reader, HighlightingManager.Instance);
        CodeEditor.SyntaxHighlighting = highlighting;
    }
}
