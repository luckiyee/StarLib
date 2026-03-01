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

    public static IReadOnlyList<string> SuperThemeNames { get; } = new[]
    {
        "Default",
        "Ocean",
        "Forest",
        "Crimson",
        "Midnight",
        "Amethyst",
        "Light"
    };

    public void ApplySuperTheme(string name)
    {
        switch (name)
        {
            case "Ocean":
                Background = ColorFromRgb(14, 20, 33);
                TopBar = ColorFromRgb(18, 30, 48);
                Sidebar = ColorFromRgb(17, 27, 44);
                Accent = ColorFromRgb(48, 164, 255);
                ElementBG = ColorFromRgb(27, 40, 62);
                SliderTrack = ColorFromRgb(44, 72, 110);
                break;
            case "Forest":
                Background = ColorFromRgb(19, 26, 19);
                TopBar = ColorFromRgb(27, 39, 27);
                Sidebar = ColorFromRgb(24, 36, 24);
                Accent = ColorFromRgb(70, 194, 108);
                ElementBG = ColorFromRgb(33, 49, 33);
                SliderTrack = ColorFromRgb(43, 74, 52);
                break;
            case "Crimson":
                Background = ColorFromRgb(24, 15, 18);
                TopBar = ColorFromRgb(35, 18, 24);
                Sidebar = ColorFromRgb(30, 17, 21);
                Accent = ColorFromRgb(228, 69, 93);
                ElementBG = ColorFromRgb(47, 24, 32);
                SliderTrack = ColorFromRgb(89, 33, 49);
                break;
            case "Midnight":
                Background = ColorFromRgb(13, 14, 24);
                TopBar = ColorFromRgb(20, 22, 36);
                Sidebar = ColorFromRgb(18, 20, 33);
                Accent = ColorFromRgb(140, 122, 255);
                ElementBG = ColorFromRgb(31, 34, 52);
                SliderTrack = ColorFromRgb(57, 60, 92);
                break;
            case "Amethyst":
                Background = ColorFromRgb(24, 19, 33);
                TopBar = ColorFromRgb(33, 25, 45);
                Sidebar = ColorFromRgb(29, 22, 40);
                Accent = ColorFromRgb(193, 120, 255);
                ElementBG = ColorFromRgb(43, 33, 58);
                SliderTrack = ColorFromRgb(73, 55, 97);
                break;
            case "Light":
                Background = ColorFromRgb(241, 244, 248);
                TopBar = ColorFromRgb(230, 235, 243);
                Sidebar = ColorFromRgb(234, 239, 246);
                Accent = ColorFromRgb(47, 102, 224);
                ElementBG = ColorFromRgb(223, 229, 238);
                SliderTrack = ColorFromRgb(191, 200, 214);
                TextPrimary = ColorFromRgb(20, 24, 34);
                TextSecondary = ColorFromRgb(45, 54, 70);
                TextMuted = ColorFromRgb(74, 85, 105);
                break;
            default:
                ApplyPreset(new ThemeModel());
                break;
        }
    }

    private void ApplyPreset(ThemeModel preset)
    {
        Background = preset.Background;
        TopBar = preset.TopBar;
        Sidebar = preset.Sidebar;
        TabDefault = preset.TabDefault;
        TabActive = preset.TabActive;
        TextPrimary = preset.TextPrimary;
        TextSecondary = preset.TextSecondary;
        TextMuted = preset.TextMuted;
        Accent = preset.Accent;
        ToggleOff = preset.ToggleOff;
        ElementBG = preset.ElementBG;
        ElementHover = preset.ElementHover;
        InputBG = preset.InputBG;
        SliderTrack = preset.SliderTrack;
        NotifBG = preset.NotifBG;
    }

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
