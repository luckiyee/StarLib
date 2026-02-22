using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;

namespace StarLibEditor.Controls;

public partial class ColorPickerControl : UserControl
{
    private double _hue;
    private double _saturation = 1;
    private double _value = 1;
    private bool _draggingSV;
    private bool _draggingHue;

    public event Action<Color>? ColorConfirmed;
    public event Action? ColorCancelled;
    public event Action<Color>? ColorPreview;

    public Color SelectedColor { get; private set; } = Colors.Red;

    public ColorPickerControl()
    {
        InitializeComponent();
    }

    public void SetColor(Color color)
    {
        SelectedColor = color;
        RGBToHSV(color.R / 255.0, color.G / 255.0, color.B / 255.0, out _hue, out _saturation, out _value);
        UpdateUI();
    }

    private void UpdateUI()
    {
        var hueColor = HSVToColor(_hue, 1, 1);
        SVSquare.Background = new SolidColorBrush(hueColor);

        SelectedColor = HSVToColor(_hue, _saturation, _value);
        PreviewSwatch.Background = new SolidColorBrush(SelectedColor);

        HexInput.Text = $"#{SelectedColor.R:X2}{SelectedColor.G:X2}{SelectedColor.B:X2}";
        RInput.Text = SelectedColor.R.ToString();
        GInput.Text = SelectedColor.G.ToString();
        BInput.Text = SelectedColor.B.ToString();

        // Position SV cursor
        if (SVSquare.ActualWidth > 0)
        {
            var margin = new Thickness(
                _saturation * SVSquare.ActualWidth - 6,
                (1 - _value) * SVSquare.ActualHeight - 6, 0, 0);
            SVCursor.Margin = margin;
        }

        // Position Hue cursor
        if (HueBar.ActualHeight > 0)
        {
            Canvas.SetTop(HueCursor, _hue * HueBar.ActualHeight);
        }
    }

    // SV Square interaction
    private void SV_MouseDown(object sender, MouseButtonEventArgs e)
    {
        _draggingSV = true;
        SVSquare.CaptureMouse();
        UpdateSV(e.GetPosition(SVSquare));
    }

    private void SV_MouseMove(object sender, MouseEventArgs e)
    {
        if (_draggingSV) UpdateSV(e.GetPosition(SVSquare));
    }

    private void SV_MouseUp(object sender, MouseButtonEventArgs e)
    {
        _draggingSV = false;
        SVSquare.ReleaseMouseCapture();
    }

    private void UpdateSV(Point pos)
    {
        _saturation = Math.Clamp(pos.X / SVSquare.ActualWidth, 0, 1);
        _value = Math.Clamp(1 - pos.Y / SVSquare.ActualHeight, 0, 1);
        UpdateUI();
        ColorPreview?.Invoke(SelectedColor);
    }

    // Hue bar interaction
    private void Hue_MouseDown(object sender, MouseButtonEventArgs e)
    {
        _draggingHue = true;
        HueBar.CaptureMouse();
        UpdateHue(e.GetPosition(HueBar));
    }

    private void Hue_MouseMove(object sender, MouseEventArgs e)
    {
        if (_draggingHue) UpdateHue(e.GetPosition(HueBar));
    }

    private void Hue_MouseUp(object sender, MouseButtonEventArgs e)
    {
        _draggingHue = false;
        HueBar.ReleaseMouseCapture();
    }

    private void UpdateHue(Point pos)
    {
        _hue = Math.Clamp(pos.Y / HueBar.ActualHeight, 0, 0.9999);
        UpdateUI();
        ColorPreview?.Invoke(SelectedColor);
    }

    // Hex input
    private void HexInput_LostFocus(object sender, RoutedEventArgs e)
    {
        try
        {
            var hex = HexInput.Text.TrimStart('#');
            if (hex.Length == 6)
            {
                var r = Convert.ToByte(hex[..2], 16);
                var g = Convert.ToByte(hex[2..4], 16);
                var b = Convert.ToByte(hex[4..6], 16);
                RGBToHSV(r / 255.0, g / 255.0, b / 255.0, out _hue, out _saturation, out _value);
                UpdateUI();
            }
        }
        catch { }
    }

    // RGB inputs
    private void RGB_LostFocus(object sender, RoutedEventArgs e)
    {
        if (byte.TryParse(RInput.Text, out var r) &&
            byte.TryParse(GInput.Text, out var g) &&
            byte.TryParse(BInput.Text, out var b))
        {
            RGBToHSV(r / 255.0, g / 255.0, b / 255.0, out _hue, out _saturation, out _value);
            UpdateUI();
        }
    }

    private void Confirm_Click(object sender, RoutedEventArgs e) => ColorConfirmed?.Invoke(SelectedColor);
    private void Cancel_Click(object sender, RoutedEventArgs e) => ColorCancelled?.Invoke();

    // HSV <-> RGB
    private static Color HSVToColor(double h, double s, double v)
    {
        double r, g, b;
        if (s == 0) { r = g = b = v; }
        else
        {
            var hh = (h % 1.0) * 6.0;
            var i = (int)Math.Floor(hh);
            var f = hh - i;
            var p = v * (1 - s);
            var q = v * (1 - s * f);
            var t = v * (1 - s * (1 - f));
            (r, g, b) = i switch
            {
                0 => (v, t, p),
                1 => (q, v, p),
                2 => (p, v, t),
                3 => (p, q, v),
                4 => (t, p, v),
                _ => (v, p, q)
            };
        }
        return Color.FromRgb((byte)(r * 255), (byte)(g * 255), (byte)(b * 255));
    }

    private static void RGBToHSV(double r, double g, double b, out double h, out double s, out double v)
    {
        var max = Math.Max(r, Math.Max(g, b));
        var min = Math.Min(r, Math.Min(g, b));
        var delta = max - min;
        v = max;
        s = max == 0 ? 0 : delta / max;

        if (delta == 0) { h = 0; return; }

        if (max == r) h = (g - b) / delta + (g < b ? 6 : 0);
        else if (max == g) h = (b - r) / delta + 2;
        else h = (r - g) / delta + 4;
        h /= 6;
    }
}
