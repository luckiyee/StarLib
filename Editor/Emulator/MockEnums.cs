using MoonSharp.Interpreter;

namespace StarLibEditor.Emulator;

public static class MockEnums
{
    public static Table BuildEnumTable(Script script)
    {
        var enumTable = new Table(script);

        // Enum.Font
        var font = new Table(script);
        font["Gotham"] = 3;
        font["GothamSemibold"] = 4;
        font["GothamBold"] = 5;
        font["SourceSans"] = 1;
        font["SourceSansBold"] = 2;
        font["SourceSansLight"] = 6;
        font["Arial"] = 7;
        font["ArialBold"] = 8;
        font["Code"] = 9;
        font["Legacy"] = 0;
        font["Roboto"] = 10;
        font["RobotoMono"] = 11;
        font["Ubuntu"] = 12;
        font["BuilderSans"] = 13;
        font["BuilderSansBold"] = 14;
        enumTable["Font"] = font;

        // Enum.EasingStyle
        var easingStyle = new Table(script);
        easingStyle["Linear"] = 0;
        easingStyle["Sine"] = 1;
        easingStyle["Quad"] = 2;
        easingStyle["Cubic"] = 3;
        easingStyle["Quart"] = 4;
        easingStyle["Quint"] = 5;
        easingStyle["Exponential"] = 6;
        easingStyle["Circular"] = 7;
        easingStyle["Back"] = 8;
        easingStyle["Bounce"] = 9;
        easingStyle["Elastic"] = 10;
        enumTable["EasingStyle"] = easingStyle;

        // Enum.EasingDirection
        var easingDir = new Table(script);
        easingDir["In"] = 0;
        easingDir["Out"] = 1;
        easingDir["InOut"] = 2;
        enumTable["EasingDirection"] = easingDir;

        // Enum.SortOrder
        var sortOrder = new Table(script);
        sortOrder["LayoutOrder"] = 0;
        sortOrder["Name"] = 1;
        enumTable["SortOrder"] = sortOrder;

        // Enum.TextXAlignment
        var textXAlign = new Table(script);
        textXAlign["Left"] = 0;
        textXAlign["Center"] = 1;
        textXAlign["Right"] = 2;
        enumTable["TextXAlignment"] = textXAlign;

        // Enum.TextYAlignment
        var textYAlign = new Table(script);
        textYAlign["Top"] = 0;
        textYAlign["Center"] = 1;
        textYAlign["Bottom"] = 2;
        enumTable["TextYAlignment"] = textYAlign;

        // Enum.UserInputType
        var inputType = new Table(script);
        inputType["MouseButton1"] = 0;
        inputType["MouseButton2"] = 1;
        inputType["MouseButton3"] = 2;
        inputType["MouseMovement"] = 3;
        inputType["MouseWheel"] = 4;
        inputType["Touch"] = 5;
        inputType["Keyboard"] = 6;
        inputType["Gamepad1"] = 7;
        enumTable["UserInputType"] = inputType;

        // Enum.UserInputState
        var inputState = new Table(script);
        inputState["Begin"] = 0;
        inputState["Change"] = 1;
        inputState["End"] = 2;
        inputState["Cancel"] = 3;
        enumTable["UserInputState"] = inputState;

        // Enum.KeyCode
        var keyCode = new Table(script);
        var allKeys = new[]
        {
            "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
            "Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine",
            "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
            "LeftShift","RightShift","LeftControl","RightControl","LeftAlt","RightAlt",
            "Tab","CapsLock","Space","Return","Backspace","Delete","Insert","Home","End",
            "PageUp","PageDown","Up","Down","Left","Right","Escape",
            "Minus","Equals","LeftBracket","RightBracket","Backslash","Semicolon",
            "Quote","Comma","Period","Slash","Tilde","BackSlash"
        };
        for (int i = 0; i < allKeys.Length; i++)
            keyCode[allKeys[i]] = BuildEnumItem(script, allKeys[i], i);
        enumTable["KeyCode"] = keyCode;

        // Enum.ZIndexBehavior
        var zBehavior = new Table(script);
        zBehavior["Sibling"] = 0;
        zBehavior["Global"] = 1;
        enumTable["ZIndexBehavior"] = zBehavior;

        // Enum.FillDirection
        var fillDir = new Table(script);
        fillDir["Horizontal"] = 0;
        fillDir["Vertical"] = 1;
        enumTable["FillDirection"] = fillDir;

        // Enum.HorizontalAlignment
        var hAlign = new Table(script);
        hAlign["Left"] = 0;
        hAlign["Center"] = 1;
        hAlign["Right"] = 2;
        enumTable["HorizontalAlignment"] = hAlign;

        // Enum.VerticalAlignment
        var vAlign = new Table(script);
        vAlign["Top"] = 0;
        vAlign["Center"] = 1;
        vAlign["Bottom"] = 2;
        enumTable["VerticalAlignment"] = vAlign;

        return enumTable;
    }

    private static Table BuildEnumItem(Script script, string name, int value)
    {
        var item = new Table(script);
        item["Name"] = name;
        item["Value"] = value;
        return item;
    }
}
