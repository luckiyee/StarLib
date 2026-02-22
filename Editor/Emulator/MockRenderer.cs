using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace StarLibEditor.Emulator;

/// <summary>
/// Converts MockInstance trees into WPF UIElements for the emulator canvas.
/// Maintains a mapping from MockInstance -> UIElement and updates on property changes.
/// </summary>
public class MockRenderer
{
    private readonly Canvas _canvas;
    private readonly Dictionary<MockInstance, FrameworkElement> _elementMap = new();
    private readonly MockInstanceTree _tree;
    private double _screenWidth = 1280;
    private double _screenHeight = 720;

    // Font mapping: Roblox Enum.Font -> WPF FontFamily
    private static readonly Dictionary<int, FontFamily> FontMap = new()
    {
        { 0, new FontFamily("Segoe UI") },         // Legacy
        { 1, new FontFamily("Segoe UI") },          // SourceSans
        { 2, new FontFamily("Segoe UI Bold") },     // SourceSansBold
        { 3, new FontFamily("Segoe UI") },          // Gotham
        { 4, new FontFamily("Segoe UI Semibold") }, // GothamSemibold
        { 5, new FontFamily("Segoe UI Bold") },     // GothamBold
        { 6, new FontFamily("Segoe UI Light") },    // SourceSansLight
        { 7, new FontFamily("Arial") },
        { 8, new FontFamily("Arial Bold") },
        { 9, new FontFamily("Consolas") },          // Code
        { 10, new FontFamily("Segoe UI") },         // Roboto
        { 11, new FontFamily("Consolas") },         // RobotoMono
        { 12, new FontFamily("Segoe UI") },         // Ubuntu
    };

    public MockRenderer(Canvas canvas, MockInstanceTree tree)
    {
        _canvas = canvas;
        _tree = tree;
    }

    public void SetScreenSize(double w, double h)
    {
        _screenWidth = w;
        _screenHeight = h;
    }

    public void RenderAll()
    {
        _canvas.Children.Clear();
        _elementMap.Clear();

        foreach (var gui in _tree.GetAllScreenGuis())
        {
            if (gui.GetProperty("Enabled") is false) continue;
            foreach (var child in gui.Children)
                RenderInstance(child, _canvas, _screenWidth, _screenHeight);
        }
    }

    public void UpdateAll()
    {
        Application.Current?.Dispatcher.Invoke(RenderAll);
    }

    private FrameworkElement? RenderInstance(MockInstance inst, Panel parent, double parentW, double parentH)
    {
        if (inst.GetProperty("Visible") is false) return null;

        // Skip non-visual instances
        if (inst.ClassName.StartsWith("UI") && inst.ClassName != "UICorner")
            return null;

        FrameworkElement? element = inst.ClassName switch
        {
            "Frame" => RenderFrame(inst, parentW, parentH),
            "TextLabel" => RenderTextLabel(inst, parentW, parentH),
            "TextButton" => RenderTextButton(inst, parentW, parentH),
            "TextBox" => RenderTextBox(inst, parentW, parentH),
            "ImageLabel" or "ImageButton" => RenderImagePlaceholder(inst, parentW, parentH),
            "ScrollingFrame" => RenderScrollingFrame(inst, parentW, parentH),
            "ScreenGui" => null, // ScreenGuis are handled at the top level
            _ => null
        };

        if (element == null) return null;

        _elementMap[inst] = element;
        parent.Children.Add(element);

        // Render children
        if (element is Border border && border.Child is Panel childPanel)
        {
            var hasListLayout = inst.Children.Any(c => c.ClassName == "UIListLayout");
            var hasGridLayout = inst.Children.Any(c => c.ClassName == "UIGridLayout");

            var (elW, elH) = ResolveSize(inst, parentW, parentH);

            if (hasListLayout)
            {
                var layoutInst = inst.Children.First(c => c.ClassName == "UIListLayout");
                RenderWithListLayout(inst, childPanel, layoutInst, elW, elH);
            }
            else if (hasGridLayout)
            {
                var gridInst = inst.Children.First(c => c.ClassName == "UIGridLayout");
                RenderWithGridLayout(inst, childPanel, gridInst, elW, elH);
            }
            else
            {
                foreach (var child in inst.Children)
                    RenderInstance(child, childPanel, elW, elH);
            }
        }

        return element;
    }

    private Border RenderFrame(MockInstance inst, double parentW, double parentH)
    {
        var (w, h) = ResolveSize(inst, parentW, parentH);
        var (x, y) = ResolvePosition(inst, parentW, parentH, w, h);
        var bg = GetColor(inst, "BackgroundColor3", Colors.DarkGray);
        var bgTrans = inst.GetProperty("BackgroundTransparency") is double bt ? bt : 0;
        var zIndex = inst.GetProperty("ZIndex") is double z ? (int)z : 1;
        var clips = inst.GetProperty("ClipsDescendants") is true;

        var border = new Border
        {
            Width = Math.Max(w, 0),
            Height = Math.Max(h, 0),
            Background = new SolidColorBrush(Color.FromArgb((byte)((1 - bgTrans) * 255), bg.R, bg.G, bg.B)),
            ClipToBounds = clips,
            CornerRadius = GetCornerRadius(inst),
            Child = new Canvas()
        };

        ApplyPadding(border, inst);
        Canvas.SetLeft(border, x);
        Canvas.SetTop(border, y);
        Panel.SetZIndex(border, zIndex);

        return border;
    }

    private Border RenderTextLabel(MockInstance inst, double parentW, double parentH)
    {
        var (w, h) = ResolveSize(inst, parentW, parentH);
        var (x, y) = ResolvePosition(inst, parentW, parentH, w, h);
        var bg = GetColor(inst, "BackgroundColor3", Colors.Transparent);
        var bgTrans = inst.GetProperty("BackgroundTransparency") is double bt ? bt : 1;
        var textColor = GetColor(inst, "TextColor3", Colors.White);
        var textTrans = inst.GetProperty("TextTransparency") is double tt ? tt : 0;
        var text = inst.GetProperty("Text")?.ToString() ?? "";
        var textSize = inst.GetProperty("TextSize") is double ts ? ts : 14;
        var font = GetFont(inst);
        var xAlign = inst.GetProperty("TextXAlignment") is double xa ? (int)xa : 1;
        var yAlign = inst.GetProperty("TextYAlignment") is double ya ? (int)ya : 1;
        var wrapped = inst.GetProperty("TextWrapped") is true;

        var tb = new TextBlock
        {
            Text = text,
            Foreground = new SolidColorBrush(Color.FromArgb((byte)((1 - textTrans) * 255), textColor.R, textColor.G, textColor.B)),
            FontSize = textSize,
            FontFamily = font,
            TextWrapping = wrapped ? TextWrapping.Wrap : TextWrapping.NoWrap,
            HorizontalAlignment = xAlign switch { 0 => HorizontalAlignment.Left, 2 => HorizontalAlignment.Right, _ => HorizontalAlignment.Center },
            VerticalAlignment = yAlign switch { 0 => VerticalAlignment.Top, 2 => VerticalAlignment.Bottom, _ => VerticalAlignment.Center },
        };

        var border = new Border
        {
            Width = Math.Max(w, 0),
            Height = Math.Max(h, 0),
            Background = new SolidColorBrush(Color.FromArgb((byte)((1 - bgTrans) * 255), bg.R, bg.G, bg.B)),
            CornerRadius = GetCornerRadius(inst),
            Child = tb
        };

        Canvas.SetLeft(border, x);
        Canvas.SetTop(border, y);
        Panel.SetZIndex(border, inst.GetProperty("ZIndex") is double z ? (int)z : 1);

        return border;
    }

    private Border RenderTextButton(MockInstance inst, double parentW, double parentH)
    {
        var border = RenderTextLabel(inst, parentW, parentH);

        // Make it clickable
        border.Cursor = System.Windows.Input.Cursors.Hand;
        border.MouseLeftButtonDown += (s, e) =>
        {
            inst.MouseButton1Down.Fire(_tree.Script!);
            inst.MouseButton1Click.Fire(_tree.Script!);
            e.Handled = true;
        };
        border.MouseLeftButtonUp += (s, e) =>
        {
            inst.MouseButton1Up.Fire(_tree.Script!);
            e.Handled = true;
        };
        border.MouseEnter += (s, e) =>
        {
            inst.MouseEnter.Fire(_tree.Script!);
        };
        border.MouseLeave += (s, e) =>
        {
            inst.MouseLeave.Fire(_tree.Script!);
        };

        return border;
    }

    private Border RenderTextBox(MockInstance inst, double parentW, double parentH)
    {
        var (w, h) = ResolveSize(inst, parentW, parentH);
        var (x, y) = ResolvePosition(inst, parentW, parentH, w, h);
        var bg = GetColor(inst, "BackgroundColor3", Colors.DarkGray);
        var bgTrans = inst.GetProperty("BackgroundTransparency") is double bt ? bt : 0;
        var textColor = GetColor(inst, "TextColor3", Colors.White);
        var text = inst.GetProperty("Text")?.ToString() ?? "";
        var placeholder = inst.GetProperty("PlaceholderText")?.ToString() ?? "";
        var textSize = inst.GetProperty("TextSize") is double ts ? ts : 14;
        var font = GetFont(inst);

        var textBox = new TextBox
        {
            Text = text,
            Foreground = new SolidColorBrush(textColor),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            FontSize = textSize,
            FontFamily = font,
            VerticalContentAlignment = VerticalAlignment.Center
        };

        textBox.KeyDown += (s, e) =>
        {
            if (e.Key == System.Windows.Input.Key.Enter)
            {
                inst.SetProperty("Text", textBox.Text);
                inst.FocusLost.Fire(_tree.Script!, MoonSharp.Interpreter.DynValue.True);
            }
        };

        textBox.LostFocus += (s, e) =>
        {
            inst.SetProperty("Text", textBox.Text);
            inst.FocusLost.Fire(_tree.Script!, MoonSharp.Interpreter.DynValue.False);
        };

        var border = new Border
        {
            Width = Math.Max(w, 0),
            Height = Math.Max(h, 0),
            Background = new SolidColorBrush(Color.FromArgb((byte)((1 - bgTrans) * 255), bg.R, bg.G, bg.B)),
            CornerRadius = GetCornerRadius(inst),
            Child = textBox
        };

        Canvas.SetLeft(border, x);
        Canvas.SetTop(border, y);
        Panel.SetZIndex(border, inst.GetProperty("ZIndex") is double z ? (int)z : 1);

        return border;
    }

    private Border RenderImagePlaceholder(MockInstance inst, double parentW, double parentH)
    {
        var (w, h) = ResolveSize(inst, parentW, parentH);
        var (x, y) = ResolvePosition(inst, parentW, parentH, w, h);
        var bg = GetColor(inst, "BackgroundColor3", Colors.Gray);
        var bgTrans = inst.GetProperty("BackgroundTransparency") is double bt ? bt : 0;

        var border = new Border
        {
            Width = Math.Max(w, 0),
            Height = Math.Max(h, 0),
            Background = new SolidColorBrush(Color.FromArgb((byte)((1 - bgTrans) * 255), bg.R, bg.G, bg.B)),
            CornerRadius = GetCornerRadius(inst),
            Child = new TextBlock
            {
                Text = "[Image]",
                Foreground = Brushes.Gray,
                FontSize = 10,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            }
        };

        Canvas.SetLeft(border, x);
        Canvas.SetTop(border, y);

        return border;
    }

    private Border RenderScrollingFrame(MockInstance inst, double parentW, double parentH)
    {
        var (w, h) = ResolveSize(inst, parentW, parentH);
        var (x, y) = ResolvePosition(inst, parentW, parentH, w, h);
        var bg = GetColor(inst, "BackgroundColor3", Colors.DarkGray);
        var bgTrans = inst.GetProperty("BackgroundTransparency") is double bt ? bt : 0;
        var scrollBarThickness = inst.GetProperty("ScrollBarThickness") is double sbt ? sbt : 6;

        var canvasSize = inst.GetProperty("CanvasSize") as MockUDim2 ?? MockUDim2.New(0, 0, 0, 0);
        var (canvasW, canvasH) = canvasSize.Resolve(w, h);

        var innerCanvas = new Canvas
        {
            Width = Math.Max(canvasW, w),
            Height = Math.Max(canvasH, h)
        };

        var scrollViewer = new ScrollViewer
        {
            HorizontalScrollBarVisibility = ScrollBarVisibility.Auto,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            Content = innerCanvas
        };

        var border = new Border
        {
            Width = Math.Max(w, 0),
            Height = Math.Max(h, 0),
            Background = new SolidColorBrush(Color.FromArgb((byte)((1 - bgTrans) * 255), bg.R, bg.G, bg.B)),
            CornerRadius = GetCornerRadius(inst),
            ClipToBounds = true,
            Child = scrollViewer
        };

        Canvas.SetLeft(border, x);
        Canvas.SetTop(border, y);

        // Render children into the inner canvas
        foreach (var child in inst.Children)
            RenderInstance(child, innerCanvas, Math.Max(canvasW, w), Math.Max(canvasH, h));

        return border;
    }

    private void RenderWithListLayout(MockInstance parent, Panel container, MockInstance layout, double parentW, double parentH)
    {
        if (container is not Canvas canvas) return;

        var padding = layout.GetProperty("Padding") as MockUDim ?? MockUDim.New(0, 0);
        var fillDir = layout.GetProperty("FillDirection") is double fd ? (int)fd : 1; // default Vertical
        var gap = padding.Offset;

        double offset = 0;
        double maxCross = 0;

        foreach (var child in parent.Children.Where(c => !c.ClassName.StartsWith("UI")))
        {
            var el = RenderInstance(child, canvas, parentW, parentH);
            if (el == null) continue;

            if (fillDir == 1) // Vertical
            {
                Canvas.SetLeft(el, 0);
                Canvas.SetTop(el, offset);
                offset += el.Height + gap;
                if (el.Width > maxCross) maxCross = el.Width;
            }
            else // Horizontal
            {
                Canvas.SetLeft(el, offset);
                Canvas.SetTop(el, 0);
                offset += el.Width + gap;
                if (el.Height > maxCross) maxCross = el.Height;
            }
        }

        // Update AbsoluteContentSize
        if (fillDir == 1)
            layout.SetProperty("AbsoluteContentSize", MockVector2.New(maxCross, offset));
        else
            layout.SetProperty("AbsoluteContentSize", MockVector2.New(offset, maxCross));
    }

    private void RenderWithGridLayout(MockInstance parent, Panel container, MockInstance grid, double parentW, double parentH)
    {
        if (container is not Canvas canvas) return;

        var cellSize = grid.GetProperty("CellSize") as MockUDim2 ?? MockUDim2.New(0, 100, 0, 100);
        var cellPadding = grid.GetProperty("CellPadding") as MockUDim2 ?? MockUDim2.New(0, 5, 0, 5);

        var (cellW, cellH) = cellSize.Resolve(parentW, parentH);
        var (padW, padH) = cellPadding.Resolve(parentW, parentH);

        int col = 0;
        int row = 0;
        var maxCols = Math.Max(1, (int)(parentW / (cellW + padW)));

        foreach (var child in parent.Children.Where(c => !c.ClassName.StartsWith("UI")))
        {
            var el = RenderInstance(child, canvas, cellW, cellH);
            if (el == null) continue;

            el.Width = cellW;
            el.Height = cellH;
            Canvas.SetLeft(el, col * (cellW + padW));
            Canvas.SetTop(el, row * (cellH + padH));

            col++;
            if (col >= maxCols) { col = 0; row++; }
        }
    }

    // Helpers
    private (double w, double h) ResolveSize(MockInstance inst, double parentW, double parentH)
    {
        var size = inst.GetProperty("Size") as MockUDim2 ?? MockUDim2.New(0, 100, 0, 100);
        return size.Resolve(parentW, parentH);
    }

    private (double x, double y) ResolvePosition(MockInstance inst, double parentW, double parentH, double selfW, double selfH)
    {
        var pos = inst.GetProperty("Position") as MockUDim2 ?? MockUDim2.New(0, 0, 0, 0);
        var (px, py) = pos.Resolve(parentW, parentH);

        var anchor = inst.GetProperty("AnchorPoint") as MockVector2;
        if (anchor != null)
        {
            px -= anchor.X * selfW;
            py -= anchor.Y * selfH;
        }

        return (px, py);
    }

    private Color GetColor(MockInstance inst, string prop, Color fallback)
    {
        if (inst.GetProperty(prop) is MockColor3 c)
            return c.ToWpfColor();
        return fallback;
    }

    private FontFamily GetFont(MockInstance inst)
    {
        var fontVal = inst.GetProperty("Font");
        int fontId = fontVal is double d ? (int)d : 4;
        return FontMap.TryGetValue(fontId, out var f) ? f : new FontFamily("Segoe UI");
    }

    private CornerRadius GetCornerRadius(MockInstance inst)
    {
        var corner = inst.Children.FirstOrDefault(c => c.ClassName == "UICorner");
        if (corner == null) return new CornerRadius(0);
        var cr = corner.GetProperty("CornerRadius") as MockUDim;
        if (cr == null) return new CornerRadius(0);
        return new CornerRadius(cr.Offset);
    }

    private void ApplyPadding(Border border, MockInstance inst)
    {
        var padding = inst.Children.FirstOrDefault(c => c.ClassName == "UIPadding");
        if (padding == null) return;

        var pl = padding.GetProperty("PaddingLeft") as MockUDim;
        var pr = padding.GetProperty("PaddingRight") as MockUDim;
        var pt = padding.GetProperty("PaddingTop") as MockUDim;
        var pb = padding.GetProperty("PaddingBottom") as MockUDim;

        border.Padding = new Thickness(
            pl?.Offset ?? 0,
            pt?.Offset ?? 0,
            pr?.Offset ?? 0,
            pb?.Offset ?? 0);
    }
}
