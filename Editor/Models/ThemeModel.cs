using System.Windows.Media;
using CommunityToolkit.Mvvm.ComponentModel;

namespace StarLibEditor.Models;

public partial class ThemeModel : ObservableObject
{
    [ObservableProperty] private Color _background = ColorFromRgb(24, 24, 24);
    [ObservableProperty] private Color _topBar = ColorFromRgb(30, 30, 30);
    [ObservableProperty] private Color _sidebar = ColorFromRgb(30, 30, 30);
    [ObservableProperty] private Color _tabDefault = ColorFromRgb(40, 40, 40);
    [ObservableProperty] private Color _tabActive = ColorFromRgb(60, 60, 60);
    [ObservableProperty] private Color _textPrimary = ColorFromRgb(255, 255, 255);
    [ObservableProperty] private Color _textSecondary = ColorFromRgb(255, 255, 255);
    [ObservableProperty] private Color _textMuted = ColorFromRgb(255, 255, 255);
    [ObservableProperty] private Color _accent = ColorFromRgb(0, 170, 255);
    [ObservableProperty] private Color _toggleOff = ColorFromRgb(60, 60, 60);
    [ObservableProperty] private Color _elementBG = ColorFromRgb(40, 40, 40);
    [ObservableProperty] private Color _elementHover = ColorFromRgb(50, 50, 50);
    [ObservableProperty] private Color _inputBG = ColorFromRgb(30, 30, 30);
    [ObservableProperty] private Color _sliderTrack = ColorFromRgb(60, 60, 60);
    [ObservableProperty] private Color _notifBG = ColorFromRgb(35, 35, 35);

    [ObservableProperty] private double _cornerRadius = 8;
    [ObservableProperty] private double _elementRadius = 6;

    [ObservableProperty] private string _font = "GothamSemibold";
    [ObservableProperty] private string _fontBold = "GothamBold";
    [ObservableProperty] private string _fontLight = "Gotham";

    [ObservableProperty] private double _titleSize = 16;
    [ObservableProperty] private double _textSize = 14;
    [ObservableProperty] private double _smallTextSize = 13;

    [ObservableProperty] private double _windowWidth = 600;
    [ObservableProperty] private double _windowHeight = 400;
    [ObservableProperty] private double _sidebarWidth = 150;
    [ObservableProperty] private double _topBarHeight = 40;
    [ObservableProperty] private double _elementHeight = 35;
    [ObservableProperty] private double _sliderHeight = 50;

    [ObservableProperty] private double _tweenSpeed = 0.2;
    [ObservableProperty] private double _notifDuration = 4;

    private static Color ColorFromRgb(byte r, byte g, byte b) => Color.FromRgb(r, g, b);

    public static ThemeModel Default => new();

    public string ColorToHex(Color c) => $"#{c.R:X2}{c.G:X2}{c.B:X2}";

    public static Color HexToColor(string hex)
    {
        hex = hex.TrimStart('#');
        if (hex.Length == 6)
            return Color.FromRgb(
                Convert.ToByte(hex[..2], 16),
                Convert.ToByte(hex[2..4], 16),
                Convert.ToByte(hex[4..6], 16));
        return Colors.White;
    }

    public Dictionary<string, string> GetOverrides()
    {
        var defaults = new ThemeModel();
        var overrides = new Dictionary<string, string>();
        if (Background != defaults.Background) overrides["Background"] = ColorToHex(Background);
        if (TopBar != defaults.TopBar) overrides["TopBar"] = ColorToHex(TopBar);
        if (Sidebar != defaults.Sidebar) overrides["Sidebar"] = ColorToHex(Sidebar);
        if (TabDefault != defaults.TabDefault) overrides["TabDefault"] = ColorToHex(TabDefault);
        if (TabActive != defaults.TabActive) overrides["TabActive"] = ColorToHex(TabActive);
        if (TextPrimary != defaults.TextPrimary) overrides["TextPrimary"] = ColorToHex(TextPrimary);
        if (TextSecondary != defaults.TextSecondary) overrides["TextSecondary"] = ColorToHex(TextSecondary);
        if (TextMuted != defaults.TextMuted) overrides["TextMuted"] = ColorToHex(TextMuted);
        if (Accent != defaults.Accent) overrides["Accent"] = ColorToHex(Accent);
        if (ToggleOff != defaults.ToggleOff) overrides["ToggleOff"] = ColorToHex(ToggleOff);
        if (ElementBG != defaults.ElementBG) overrides["ElementBG"] = ColorToHex(ElementBG);
        if (ElementHover != defaults.ElementHover) overrides["ElementHover"] = ColorToHex(ElementHover);
        if (InputBG != defaults.InputBG) overrides["InputBG"] = ColorToHex(InputBG);
        if (SliderTrack != defaults.SliderTrack) overrides["SliderTrack"] = ColorToHex(SliderTrack);
        if (NotifBG != defaults.NotifBG) overrides["NotifBG"] = ColorToHex(NotifBG);
        return overrides;
    }
}
