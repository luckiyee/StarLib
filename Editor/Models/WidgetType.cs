namespace StarLibEditor.Models;

public enum WidgetType
{
    // Core Rayfield-style widgets
    Section,
    Label,
    Paragraph,
    Button,
    Toggle,
    Slider,
    Dropdown,
    Input,
    Keybind,
    ColorPicker,
    Stat,

    // Extra layout/display widgets retained for compatibility
    Separator,
    Spacer,
    ProgressBar,
    Badge,
    Table,
    HorizontalRow,
    VerticalStack,
    GridContainer,
    ImageCard,
    RichTextLabel,
    CodeBlock
}
