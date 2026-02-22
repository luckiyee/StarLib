using System.Text.RegularExpressions;
using Newtonsoft.Json;

namespace StarLibEditor.Services;

public class StarLibAdapterService
{
    public List<WidgetDefinition> Widgets { get; private set; } = new();
    public Dictionary<string, object?> DefaultTheme { get; private set; } = new();

    public void LoadFromLuaSource(string luaSource)
    {
        Widgets.Clear();
        var pattern = @"function\s+Tab:(\w+)\((\w+)\)";
        foreach (Match match in Regex.Matches(luaSource, pattern))
        {
            var methodName = match.Groups[1].Value;
            var paramName = match.Groups[2].Value;

            if (!methodName.StartsWith("Create")) continue;

            var widgetName = methodName.Replace("Create", "");
            var widget = new WidgetDefinition
            {
                Name = widgetName,
                Constructor = methodName,
                IsConfigTable = paramName != "n" && paramName != "txt" && paramName != "name",
                ParameterName = paramName
            };

            // Extract cfg.xxx accesses to find properties
            var funcBody = ExtractFunctionBody(luaSource, match.Index);
            if (widget.IsConfigTable)
            {
                var propPattern = $@"{paramName}\.(\w+)";
                foreach (Match propMatch in Regex.Matches(funcBody, propPattern))
                {
                    var propName = propMatch.Groups[1].Value;
                    if (!widget.Props.Any(p => p.Name == propName))
                        widget.Props.Add(new PropDefinition { Name = propName });
                }
            }

            // Check for return object methods
            var returnPattern = @"function\s+\w+:(\w+)\(";
            foreach (Match retMatch in Regex.Matches(funcBody, returnPattern))
            {
                widget.ReturnMethods.Add(retMatch.Groups[1].Value);
            }

            Widgets.Add(widget);
        }

        ParseDefaultTheme(luaSource);
    }

    public void LoadFromAdapterJson(string jsonPath)
    {
        if (!File.Exists(jsonPath)) return;
        var json = File.ReadAllText(jsonPath);
        var adapter = JsonConvert.DeserializeObject<AdapterJson>(json);
        if (adapter?.Widgets != null)
            Widgets = adapter.Widgets;
    }

    private void ParseDefaultTheme(string luaSource)
    {
        DefaultTheme.Clear();
        var themeBlock = Regex.Match(luaSource, @"local\s+DEFAULT_THEME\s*=\s*\{([\s\S]*?)\}", RegexOptions.Multiline);
        if (!themeBlock.Success) return;

        var lines = themeBlock.Groups[1].Value.Split('\n');
        foreach (var line in lines)
        {
            var kvMatch = Regex.Match(line.Trim(), @"(\w+)\s*=\s*(.+?),?\s*$");
            if (kvMatch.Success)
            {
                var key = kvMatch.Groups[1].Value;
                var val = kvMatch.Groups[2].Value.Trim().TrimEnd(',');
                DefaultTheme[key] = val;
            }
        }
    }

    private string ExtractFunctionBody(string source, int startIndex)
    {
        int depth = 0;
        bool started = false;
        int bodyStart = startIndex;

        for (int i = startIndex; i < source.Length; i++)
        {
            var remaining = source[i..];

            if (remaining.StartsWith("function") || remaining.StartsWith("if ") ||
                remaining.StartsWith("for ") || remaining.StartsWith("while ") ||
                remaining.StartsWith("do\n") || remaining.StartsWith("do "))
            {
                if (!started) { started = true; bodyStart = i; }
                depth++;
            }

            if (remaining.StartsWith("end"))
            {
                depth--;
                if (depth <= 0 && started)
                    return source[bodyStart..(i + 3)];
            }
        }

        return source[bodyStart..Math.Min(bodyStart + 2000, source.Length)];
    }

    public WidgetDefinition? GetWidget(string name) =>
        Widgets.FirstOrDefault(w => w.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
}

public class WidgetDefinition
{
    public string Name { get; set; } = "";
    public string Constructor { get; set; } = "";
    public bool IsConfigTable { get; set; } = true;
    public string ParameterName { get; set; } = "cfg";
    public List<PropDefinition> Props { get; set; } = new();
    public List<string> ReturnMethods { get; set; } = new();
}

public class PropDefinition
{
    public string Name { get; set; } = "";
    public string Type { get; set; } = "string";
    public bool Required { get; set; } = false;
    public object? DefaultValue { get; set; }
}

public class AdapterJson
{
    public List<WidgetDefinition>? Widgets { get; set; }
}
