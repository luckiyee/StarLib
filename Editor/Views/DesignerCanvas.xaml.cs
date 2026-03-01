using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using StarLibEditor.Models;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Views;

public partial class DesignerCanvas : UserControl
{
    private MainWindowViewModel? MainVM => Tag as MainWindowViewModel;

    public DesignerCanvas()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
        MouseWheel += OnMouseWheel;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (DataContext is DesignerViewModel vm)
        {
            vm.PropertyChanged += (s, args) =>
            {
                switch (args.PropertyName)
                {
                    case nameof(DesignerViewModel.ActiveTab):
                        RenderMockup();
                        break;
                    case nameof(DesignerViewModel.Zoom):
                        ZoomTransform.ScaleX = vm.Zoom;
                        ZoomTransform.ScaleY = vm.Zoom;
                        ZoomLabel.Text = $"{(int)(vm.Zoom * 100)}%";
                        break;
                    case nameof(DesignerViewModel.SelectedNode):
                        HighlightSelected();
                        break;
                }
            };
            RenderMockup();
        }
    }

    private void OnMouseWheel(object sender, MouseWheelEventArgs e)
    {
        if (Keyboard.Modifiers == ModifierKeys.Control && DataContext is DesignerViewModel vm)
        {
            if (e.Delta > 0) vm.ZoomInCommand.Execute(null);
            else vm.ZoomOutCommand.Execute(null);
            e.Handled = true;
        }
    }

    public void RenderMockup()
    {
        if (DataContext is not DesignerViewModel vm) return;

        var project = MainVM?.Project;
        if (project == null) return;

        var theme = project.Window.Theme;
        MockupFrame.Width = theme.WindowWidth;
        MockupFrame.Height = theme.WindowHeight;
        MockupTitle.Text = project.Window.Name;

        RenderSidebar(project, vm);
        RenderContent(vm);
    }

    private void RenderSidebar(StarLibProject project, DesignerViewModel vm)
    {
        SidebarPanel.Children.Clear();
        foreach (var tab in project.Tabs)
        {
            var isActive = tab == vm.ActiveTab;
            var btn = new Border
            {
                Background = new SolidColorBrush(isActive ? Color.FromRgb(60, 60, 60) : Color.FromRgb(40, 40, 40)),
                CornerRadius = new CornerRadius(6),
                Padding = new Thickness(8, 6, 8, 6),
                Margin = new Thickness(0, 0, 0, 5),
                Cursor = Cursors.Hand
            };
            var label = new TextBlock
            {
                Text = $"  {(string.IsNullOrWhiteSpace(tab.Icon) ? "" : $"[{tab.Icon}] ")}{tab.Name}",
                Foreground = new SolidColorBrush(isActive ? Colors.White : Color.FromRgb(200, 200, 200)),
                FontSize = 14,
                FontFamily = new FontFamily("Segoe UI Semibold")
            };
            btn.Child = label;
            btn.MouseLeftButtonDown += (s, e) =>
            {
                vm.ActiveTab = tab;
                e.Handled = true;
            };
            SidebarPanel.Children.Add(btn);
        }
    }

    private void RenderContent(DesignerViewModel vm)
    {
        ContentPanel.Children.Clear();
        var tab = vm.ActiveTab;
        if (tab == null) return;

        var theme = MainVM?.Project.Window.Theme ?? new ThemeModel();

        foreach (var node in tab.Nodes)
        {
            var element = CreateWidgetMockup(node, theme, vm);
            ContentPanel.Children.Add(element);
        }
    }

    private FrameworkElement CreateWidgetMockup(UINode node, ThemeModel theme, DesignerViewModel vm)
    {
        var isSelected = vm.SelectedNode == node;
        var container = new Border
        {
            Margin = new Thickness(0, 0, 0, 8),
            BorderBrush = isSelected ? (Brush)FindResource("AccentBrush") : Brushes.Transparent,
            BorderThickness = new Thickness(isSelected ? 2 : 0),
            CornerRadius = new CornerRadius(theme.ElementRadius),
            Cursor = Cursors.Hand,
            Tag = node
        };

        container.MouseLeftButtonDown += (s, e) =>
        {
            vm.SelectNode(node);
            e.Handled = true;
        };

        switch (node.Type)
        {
            case WidgetType.Section:
                container.Child = new TextBlock
                {
                    Text = node.Props["Text"]?.ToString() ?? "Section",
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    FontWeight = FontWeights.Bold,
                    FontFamily = new FontFamily("Segoe UI")
                };
                break;

            case WidgetType.Label:
                container.Child = new TextBlock
                {
                    Text = node.Props["Text"]?.ToString() ?? "Label",
                    Foreground = new SolidColorBrush(Color.FromRgb(200, 200, 200)),
                    FontSize = theme.SmallTextSize,
                    FontFamily = new FontFamily("Segoe UI")
                };
                break;

            case WidgetType.Paragraph:
                var paraPanel = new StackPanel();
                var paraBorder = new Border
                {
                    Background = new SolidColorBrush(Color.FromRgb(40, 40, 40)),
                    CornerRadius = new CornerRadius(theme.ElementRadius),
                    Padding = new Thickness(10, 5, 10, 5)
                };
                paraPanel.Children.Add(new TextBlock
                {
                    Text = node.Props["Title"]?.ToString() ?? "",
                    Foreground = Brushes.White,
                    FontWeight = FontWeights.Bold,
                    FontSize = theme.TextSize
                });
                paraPanel.Children.Add(new TextBlock
                {
                    Text = node.Props["Content"]?.ToString() ?? "",
                    Foreground = new SolidColorBrush(Color.FromRgb(200, 200, 200)),
                    FontSize = theme.SmallTextSize,
                    TextWrapping = TextWrapping.Wrap,
                    Margin = new Thickness(0, 4, 0, 0)
                });
                paraBorder.Child = paraPanel;
                container.Child = paraBorder;
                break;

            case WidgetType.Button:
                container.Child = CreateElementBorder(theme, new TextBlock
                {
                    Text = "  " + (node.Props["Name"]?.ToString() ?? "Button"),
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                }, theme.ElementHeight);
                break;

            case WidgetType.Toggle:
                var toggleGrid = new Grid();
                toggleGrid.Children.Add(new TextBlock
                {
                    Text = "  " + (node.Props["Name"]?.ToString() ?? "Toggle"),
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                });
                var isOn = node.Props["CurrentValue"] is true;
                var switchTrack = new Border
                {
                    Width = 35, Height = 20,
                    Background = new SolidColorBrush(isOn ? theme.Accent : theme.ToggleOff),
                    CornerRadius = new CornerRadius(10),
                    HorizontalAlignment = HorizontalAlignment.Right,
                    Margin = new Thickness(0, 0, 10, 0)
                };
                var switchKnob = new Ellipse
                {
                    Width = 16, Height = 16,
                    Fill = Brushes.White,
                    HorizontalAlignment = isOn ? HorizontalAlignment.Right : HorizontalAlignment.Left,
                    Margin = new Thickness(2)
                };
                switchTrack.Child = switchKnob;
                toggleGrid.Children.Add(switchTrack);
                container.Child = CreateElementBorder(theme, toggleGrid, theme.ElementHeight);
                break;

            case WidgetType.Slider:
                var sliderPanel = new StackPanel();
                var sliderMin = node.Props["Min"] is double mn ? mn : 0;
                var sliderMax = node.Props["Max"] is double mx ? mx : 100;
                var sliderVal = node.Props["CurrentValue"] is double sv ? sv : 50;
                var pct = sliderMax > sliderMin ? (sliderVal - sliderMin) / (sliderMax - sliderMin) : 0;
                var suffix = node.Props["Suffix"]?.ToString() ?? "";

                sliderPanel.Children.Add(new TextBlock
                {
                    Text = $"  {node.Props["Name"]}: {sliderVal}{suffix}",
                    Foreground = Brushes.White,
                    FontSize = theme.SmallTextSize,
                    Margin = new Thickness(0, 4, 0, 0),
                    FontFamily = new FontFamily("Segoe UI Semibold")
                });

                var trackGrid = new Grid { Margin = new Thickness(10, 4, 10, 6), Height = 8 };
                trackGrid.Children.Add(new Border
                {
                    Background = new SolidColorBrush(theme.SliderTrack),
                    CornerRadius = new CornerRadius(4)
                });
                trackGrid.Children.Add(new Border
                {
                    Background = new SolidColorBrush(theme.Accent),
                    CornerRadius = new CornerRadius(4),
                    HorizontalAlignment = HorizontalAlignment.Left,
                    Width = 0
                });
                sliderPanel.Children.Add(trackGrid);
                container.Child = CreateElementBorder(theme, sliderPanel, theme.SliderHeight);
                break;

            case WidgetType.Dropdown:
                container.Child = CreateElementBorder(theme, new TextBlock
                {
                    Text = $"  {node.Props["Name"]}: {node.Props["CurrentOption"]}",
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                }, theme.ElementHeight);
                break;

            case WidgetType.Input:
                var inputGrid = new Grid();
                inputGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.4, GridUnitType.Star) });
                inputGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.6, GridUnitType.Star) });
                var inputLabel = new TextBlock
                {
                    Text = "  " + (node.Props["Name"]?.ToString() ?? "Input"),
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                };
                Grid.SetColumn(inputLabel, 0);
                inputGrid.Children.Add(inputLabel);
                var inputBox = new Border
                {
                    Background = new SolidColorBrush(theme.InputBG),
                    CornerRadius = new CornerRadius(4),
                    Margin = new Thickness(0, 6, 10, 6),
                    Padding = new Thickness(5, 2, 5, 2)
                };
                inputBox.Child = new TextBlock
                {
                    Text = node.Props["Default"]?.ToString() ?? node.Props["PlaceholderText"]?.ToString() ?? "...",
                    Foreground = new SolidColorBrush(Color.FromRgb(150, 150, 150)),
                    FontSize = theme.SmallTextSize
                };
                Grid.SetColumn(inputBox, 1);
                inputGrid.Children.Add(inputBox);
                container.Child = CreateElementBorder(theme, inputGrid, theme.ElementHeight);
                break;

            case WidgetType.Keybind:
                var keyName = node.Props["Default"]?.ToString() ?? "F";
                container.Child = CreateElementBorder(theme, new TextBlock
                {
                    Text = $"  {node.Props["Name"]}: [{keyName}]",
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                }, theme.ElementHeight);
                break;

            case WidgetType.ColorPicker:
                var cpGrid = new Grid();
                cpGrid.Children.Add(new TextBlock
                {
                    Text = "  " + (node.Props["Name"]?.ToString() ?? "Color"),
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                });
                var colorHex = node.Props["Default"]?.ToString() ?? "#FFFFFF";
                var previewColor = ThemeModel.HexToColor(colorHex);
                cpGrid.Children.Add(new Border
                {
                    Width = 20, Height = 16,
                    Background = new SolidColorBrush(previewColor),
                    CornerRadius = new CornerRadius(4),
                    HorizontalAlignment = HorizontalAlignment.Right,
                    Margin = new Thickness(0, 0, 10, 0)
                });
                container.Child = CreateElementBorder(theme, cpGrid, theme.ElementHeight);
                break;

            case WidgetType.Separator:
                container.Child = new Border
                {
                    Height = 1,
                    Background = new SolidColorBrush(Color.FromRgb(60, 60, 60)),
                    Margin = new Thickness(0, 4, 0, 4)
                };
                break;

            case WidgetType.Spacer:
                var spacerH = node.Props["Height"] is double sh ? sh : 10;
                container.Child = new Border { Height = spacerH };
                break;

            case WidgetType.ProgressBar:
                var pbPanel = new StackPanel();
                var pbVal = node.Props["Default"] is double pbv ? pbv : 0;
                var pbMax = node.Props["Max"] is double pbm ? pbm : 100;
                var pbPct = pbMax > 0 ? pbVal / pbMax : 0;
                pbPanel.Children.Add(new TextBlock
                {
                    Text = $"  {node.Props["Name"]}: {(int)(pbPct * 100)}%",
                    Foreground = Brushes.White,
                    FontSize = theme.SmallTextSize,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                });
                var pbTrack = new Grid { Height = node.Props["Height"] is double pbh ? pbh : 12, Margin = new Thickness(10, 4, 10, 6) };
                pbTrack.Children.Add(new Border
                {
                    Background = new SolidColorBrush(theme.SliderTrack),
                    CornerRadius = new CornerRadius(3)
                });
                pbTrack.Children.Add(new Border
                {
                    Background = new SolidColorBrush(theme.Accent),
                    CornerRadius = new CornerRadius(3),
                    HorizontalAlignment = HorizontalAlignment.Left,
                    Width = 0
                });
                pbPanel.Children.Add(pbTrack);
                container.Child = CreateElementBorder(theme, pbPanel, theme.ElementHeight);
                break;

            case WidgetType.Badge:
                var badgeColor = ThemeModel.HexToColor(node.Props["Color"]?.ToString() ?? "#00C864");
                var badgeTextColor = ThemeModel.HexToColor(node.Props["TextColor"]?.ToString() ?? "#000000");
                container.Child = new Border
                {
                    Background = new SolidColorBrush(badgeColor),
                    CornerRadius = new CornerRadius(12),
                    Padding = new Thickness(12, 4, 12, 4),
                    HorizontalAlignment = HorizontalAlignment.Left,
                    Child = new TextBlock
                    {
                        Text = node.Props["Text"]?.ToString() ?? "Badge",
                        Foreground = new SolidColorBrush(badgeTextColor),
                        FontSize = theme.SmallTextSize,
                        FontWeight = FontWeights.SemiBold
                    }
                };
                break;

            case WidgetType.Stat:
                container.Child = CreateElementBorder(theme, new TextBlock
                {
                    Text = $"  {node.Props["Name"]}: {node.Props["Value"]}{node.Props["Suffix"]}",
                    Foreground = Brushes.White,
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center,
                    FontFamily = new FontFamily("Segoe UI Semibold")
                }, theme.ElementHeight);
                break;

            default:
                container.Child = CreateElementBorder(theme, new TextBlock
                {
                    Text = $"  [{node.Type}] {node.DisplayName}",
                    Foreground = new SolidColorBrush(Color.FromRgb(150, 150, 150)),
                    FontSize = theme.TextSize,
                    VerticalAlignment = VerticalAlignment.Center
                }, theme.ElementHeight);
                break;
        }

        return container;
    }

    private Border CreateElementBorder(ThemeModel theme, UIElement child, double height)
    {
        return new Border
        {
            Background = new SolidColorBrush(theme.ElementBG),
            CornerRadius = new CornerRadius(theme.ElementRadius),
            Height = height,
            Child = child
        };
    }

    private void HighlightSelected()
    {
        RenderMockup();
    }

    private void Canvas_DragOver(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent("PaletteItem"))
        {
            e.Effects = DragDropEffects.Copy;
            DropIndicator.Visibility = Visibility.Visible;
        }
        else
        {
            e.Effects = DragDropEffects.None;
        }
        e.Handled = true;
    }

    private void Canvas_Drop(object sender, DragEventArgs e)
    {
        DropIndicator.Visibility = Visibility.Collapsed;
        if (e.Data.GetDataPresent("PaletteItem") && DataContext is DesignerViewModel vm)
        {
            var item = (PaletteItem)e.Data.GetData("PaletteItem");
            vm.AddNodeToTab(item.Type);
            RenderMockup();
        }
        e.Handled = true;
    }
}
