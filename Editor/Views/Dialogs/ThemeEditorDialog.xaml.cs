using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using StarLibEditor.Models;

namespace StarLibEditor.Views.Dialogs;

public partial class ThemeEditorDialog : Window
{
    private readonly ThemeModel _theme;

    public ThemeEditorDialog(ThemeModel theme)
    {
        InitializeComponent();
        _theme = theme;
        BuildPropertyEditors();
        UpdatePreview();
    }

    private void BuildPropertyEditors()
    {
        ThemePropsPanel.Children.Clear();

        AddColorEditor("Background", _theme.Background, c => { _theme.Background = c; UpdatePreview(); });
        AddColorEditor("TopBar", _theme.TopBar, c => { _theme.TopBar = c; UpdatePreview(); });
        AddColorEditor("Sidebar", _theme.Sidebar, c => { _theme.Sidebar = c; UpdatePreview(); });
        AddColorEditor("TabDefault", _theme.TabDefault, c => { _theme.TabDefault = c; UpdatePreview(); });
        AddColorEditor("TabActive", _theme.TabActive, c => { _theme.TabActive = c; UpdatePreview(); });
        AddColorEditor("Accent", _theme.Accent, c => { _theme.Accent = c; UpdatePreview(); });
        AddColorEditor("TextPrimary", _theme.TextPrimary, c => { _theme.TextPrimary = c; UpdatePreview(); });
        AddColorEditor("TextSecondary", _theme.TextSecondary, c => { _theme.TextSecondary = c; UpdatePreview(); });
        AddColorEditor("ElementBG", _theme.ElementBG, c => { _theme.ElementBG = c; UpdatePreview(); });
        AddColorEditor("ElementHover", _theme.ElementHover, c => { _theme.ElementHover = c; UpdatePreview(); });
        AddColorEditor("InputBG", _theme.InputBG, c => { _theme.InputBG = c; UpdatePreview(); });
        AddColorEditor("SliderTrack", _theme.SliderTrack, c => { _theme.SliderTrack = c; UpdatePreview(); });
        AddColorEditor("ToggleOff", _theme.ToggleOff, c => { _theme.ToggleOff = c; UpdatePreview(); });
        AddColorEditor("NotifBG", _theme.NotifBG, c => { _theme.NotifBG = c; UpdatePreview(); });

        AddSection("SIZING");
        AddSliderEditor("CornerRadius", _theme.CornerRadius, 0, 24, v => { _theme.CornerRadius = v; UpdatePreview(); });
        AddSliderEditor("ElementRadius", _theme.ElementRadius, 0, 12, v => { _theme.ElementRadius = v; UpdatePreview(); });
        AddSliderEditor("TweenSpeed", _theme.TweenSpeed, 0, 1, v => _theme.TweenSpeed = v);
        AddSliderEditor("TextSize", _theme.TextSize, 8, 24, v => { _theme.TextSize = v; UpdatePreview(); });
        AddSliderEditor("TitleSize", _theme.TitleSize, 10, 28, v => { _theme.TitleSize = v; UpdatePreview(); });
    }

    private void AddSection(string title)
    {
        ThemePropsPanel.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = new SolidColorBrush(Color.FromRgb(136, 136, 136)),
            FontSize = 10,
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(0, 12, 0, 4)
        });
    }

    private void AddColorEditor(string label, Color current, Action<Color> onChange)
    {
        var row = new Grid { Margin = new Thickness(0, 3, 0, 3) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.45, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.55, GridUnitType.Star) });

        var lbl = new TextBlock
        {
            Text = label, Foreground = Brushes.White, FontSize = 11, VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(lbl, 0);
        row.Children.Add(lbl);

        var swatch = new Border
        {
            Width = 28, Height = 20, CornerRadius = new CornerRadius(4),
            Background = new SolidColorBrush(current),
            Margin = new Thickness(0, 0, 4, 0),
            Cursor = System.Windows.Input.Cursors.Hand,
            HorizontalAlignment = HorizontalAlignment.Left
        };

        var hexBox = new TextBox
        {
            Text = $"#{current.R:X2}{current.G:X2}{current.B:X2}",
            Background = new SolidColorBrush(Color.FromRgb(45, 45, 45)),
            Foreground = Brushes.White, FontSize = 11, BorderThickness = new Thickness(0),
            Padding = new Thickness(4, 2, 4, 2), Width = 80,
            HorizontalAlignment = HorizontalAlignment.Left
        };

        hexBox.LostFocus += (s, e) =>
        {
            var c = ThemeModel.HexToColor(hexBox.Text);
            swatch.Background = new SolidColorBrush(c);
            onChange(c);
        };

        var panel = new StackPanel { Orientation = Orientation.Horizontal };
        panel.Children.Add(swatch);
        panel.Children.Add(hexBox);
        Grid.SetColumn(panel, 1);
        row.Children.Add(panel);

        ThemePropsPanel.Children.Add(row);
    }

    private void AddSliderEditor(string label, double current, double min, double max, Action<double> onChange)
    {
        var row = new Grid { Margin = new Thickness(0, 3, 0, 3) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.45, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.55, GridUnitType.Star) });

        var lbl = new TextBlock
        {
            Text = label, Foreground = Brushes.White, FontSize = 11, VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(lbl, 0);
        row.Children.Add(lbl);

        var slider = new Slider
        {
            Minimum = min, Maximum = max, Value = current,
            Width = 140, VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Left
        };
        var valLabel = new TextBlock
        {
            Text = current.ToString("F1"), Foreground = Brushes.Gray, FontSize = 10,
            Margin = new Thickness(4, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center
        };
        slider.ValueChanged += (s, e) =>
        {
            valLabel.Text = e.NewValue.ToString("F1");
            onChange(e.NewValue);
        };

        var panel = new StackPanel { Orientation = Orientation.Horizontal };
        panel.Children.Add(slider);
        panel.Children.Add(valLabel);
        Grid.SetColumn(panel, 1);
        row.Children.Add(panel);

        ThemePropsPanel.Children.Add(row);
    }

    private void UpdatePreview()
    {
        PreviewContent.Children.Clear();
        PreviewFrame.Background = new SolidColorBrush(_theme.Background);

        var grid = new Grid();
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(32) });
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        // Topbar
        var topbar = new Border
        {
            Background = new SolidColorBrush(_theme.TopBar),
            Child = new TextBlock
            {
                Text = "Preview Window",
                Foreground = new SolidColorBrush(_theme.TextPrimary),
                FontWeight = FontWeights.Bold, FontSize = _theme.TitleSize,
                Margin = new Thickness(12, 0, 0, 0),
                VerticalAlignment = VerticalAlignment.Center
            }
        };
        Grid.SetRow(topbar, 0);
        grid.Children.Add(topbar);

        // Content
        var contentGrid = new Grid();
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(100) });
        contentGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var sidebar = new Border { Background = new SolidColorBrush(_theme.Sidebar) };
        var tabBtn = new Border
        {
            Background = new SolidColorBrush(_theme.TabActive),
            CornerRadius = new CornerRadius(_theme.ElementRadius),
            Margin = new Thickness(8, 8, 8, 0), Padding = new Thickness(8, 4, 8, 4),
            Child = new TextBlock
            {
                Text = "Main", Foreground = new SolidColorBrush(_theme.TextPrimary), FontSize = 12
            }
        };
        sidebar.Child = new StackPanel { Children = { tabBtn } };
        Grid.SetColumn(sidebar, 0);
        contentGrid.Children.Add(sidebar);

        var elements = new StackPanel { Margin = new Thickness(12) };
        elements.Children.Add(new TextBlock
        {
            Text = "Section", Foreground = new SolidColorBrush(_theme.TextPrimary),
            FontWeight = FontWeights.Bold, FontSize = _theme.TextSize, Margin = new Thickness(0, 0, 0, 6)
        });
        elements.Children.Add(new Border
        {
            Background = new SolidColorBrush(_theme.ElementBG),
            CornerRadius = new CornerRadius(_theme.ElementRadius),
            Height = 28, Margin = new Thickness(0, 0, 0, 6),
            Child = new TextBlock
            {
                Text = "  Button", Foreground = new SolidColorBrush(_theme.TextPrimary),
                FontSize = 12, VerticalAlignment = VerticalAlignment.Center
            }
        });

        var toggleRow = new Grid { Height = 28, Margin = new Thickness(0, 0, 0, 6) };
        toggleRow.Children.Add(new Border
        {
            Background = new SolidColorBrush(_theme.ElementBG),
            CornerRadius = new CornerRadius(_theme.ElementRadius),
            Child = new TextBlock
            {
                Text = "  Toggle", Foreground = new SolidColorBrush(_theme.TextPrimary),
                FontSize = 12, VerticalAlignment = VerticalAlignment.Center
            }
        });
        toggleRow.Children.Add(new Border
        {
            Width = 28, Height = 16,
            Background = new SolidColorBrush(_theme.Accent),
            CornerRadius = new CornerRadius(8),
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(0, 0, 8, 0)
        });
        elements.Children.Add(toggleRow);

        Grid.SetColumn(elements, 1);
        contentGrid.Children.Add(elements);

        Grid.SetRow(contentGrid, 1);
        grid.Children.Add(contentGrid);

        PreviewContent.Children.Add(grid);
    }

    private void PresetChanged(object sender, SelectionChangedEventArgs e)
    {
        if (PresetCombo.SelectedItem is not ComboBoxItem item) return;
        var preset = item.Content.ToString();

        switch (preset)
        {
            case "Dark (Default)":
                ApplyPreset(new ThemeModel());
                break;
            case "Light":
                _theme.Background = Color.FromRgb(240, 240, 240);
                _theme.TopBar = Color.FromRgb(220, 220, 220);
                _theme.Sidebar = Color.FromRgb(225, 225, 225);
                _theme.TabDefault = Color.FromRgb(210, 210, 210);
                _theme.TabActive = Color.FromRgb(190, 190, 190);
                _theme.TextPrimary = Color.FromRgb(30, 30, 30);
                _theme.TextSecondary = Color.FromRgb(60, 60, 60);
                _theme.ElementBG = Color.FromRgb(230, 230, 230);
                _theme.ElementHover = Color.FromRgb(215, 215, 215);
                _theme.InputBG = Color.FromRgb(245, 245, 245);
                break;
            case "Midnight Blue":
                _theme.Background = Color.FromRgb(15, 20, 40);
                _theme.TopBar = Color.FromRgb(20, 30, 55);
                _theme.Sidebar = Color.FromRgb(18, 25, 50);
                _theme.Accent = Color.FromRgb(60, 120, 255);
                _theme.ElementBG = Color.FromRgb(25, 35, 65);
                break;
            case "Blood Red":
                _theme.Accent = Color.FromRgb(200, 30, 30);
                _theme.ElementBG = Color.FromRgb(45, 25, 25);
                _theme.TopBar = Color.FromRgb(40, 20, 20);
                break;
            case "Neon Green":
                _theme.Accent = Color.FromRgb(0, 255, 100);
                _theme.ElementBG = Color.FromRgb(20, 40, 25);
                _theme.TopBar = Color.FromRgb(15, 30, 18);
                break;
            case "Rose Gold":
                _theme.Accent = Color.FromRgb(230, 150, 140);
                _theme.Background = Color.FromRgb(35, 25, 28);
                _theme.TopBar = Color.FromRgb(45, 30, 35);
                _theme.ElementBG = Color.FromRgb(55, 38, 42);
                break;
        }

        BuildPropertyEditors();
        UpdatePreview();
    }

    private void ApplyPreset(ThemeModel preset)
    {
        _theme.Background = preset.Background;
        _theme.TopBar = preset.TopBar;
        _theme.Sidebar = preset.Sidebar;
        _theme.TabDefault = preset.TabDefault;
        _theme.TabActive = preset.TabActive;
        _theme.TextPrimary = preset.TextPrimary;
        _theme.TextSecondary = preset.TextSecondary;
        _theme.TextMuted = preset.TextMuted;
        _theme.Accent = preset.Accent;
        _theme.ToggleOff = preset.ToggleOff;
        _theme.ElementBG = preset.ElementBG;
        _theme.ElementHover = preset.ElementHover;
        _theme.InputBG = preset.InputBG;
        _theme.SliderTrack = preset.SliderTrack;
        _theme.NotifBG = preset.NotifBG;
        _theme.CornerRadius = preset.CornerRadius;
        _theme.ElementRadius = preset.ElementRadius;
    }
}
