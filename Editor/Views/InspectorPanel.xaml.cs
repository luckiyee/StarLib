using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using StarLibEditor.Models;
using StarLibEditor.ViewModels;
using System.Collections.ObjectModel;

namespace StarLibEditor.Views;

public partial class InspectorPanel : UserControl
{
    public InspectorPanel()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (DataContext is InspectorViewModel vm)
        {
            vm.PropertyChanged += (s, args) =>
            {
                if (args.PropertyName == nameof(InspectorViewModel.SelectedNode))
                    BuildPropertyEditor(vm.SelectedNode, vm);
            };
        }
    }

    private void BuildPropertyEditor(UINode? node, InspectorViewModel vm)
    {
        PropertiesPanel.Children.Clear();
        if (node == null) return;

        AddSection("ELEMENT");
        AddStringProperty("Type", node.Type.ToString(), null, true);
        AddBoolProperty("Enabled", node.Enabled, v => { node.Enabled = v; GetMainVM()?.RegenerateCode(); });
        AddBoolProperty("Visible", node.Visible, v => { node.Visible = v; GetMainVM()?.RegenerateCode(); });

        AddSection("PROPERTIES");
        foreach (var kv in node.Props.ToDictionary())
        {
            var key = kv.Key;
            var val = kv.Value;

            if (val is string s)
                AddStringProperty(key, s, newVal => vm.UpdateProperty(key, s, newVal));
            else if (val is double d)
                AddNumberProperty(key, d, newVal => vm.UpdateProperty(key, d, newVal));
            else if (val is int i)
                AddNumberProperty(key, i, newVal => vm.UpdateProperty(key, (double)i, newVal));
            else if (val is bool b)
                AddBoolProperty(key, b, newVal => vm.UpdateProperty(key, b, newVal));
            else if (val is ObservableCollection<string> options)
                AddStringProperty(key, string.Join(", ", options), newVal =>
                {
                    var items = newVal?.Split(',').Select(x => x.Trim()).Where(x => !string.IsNullOrEmpty(x)).ToList();
                    vm.UpdateProperty(key, options, new ObservableCollection<string>(items ?? new()));
                });
        }

        AddSection("CALLBACK");
        AddCodeProperty("Callback", node.CallbackCode ?? "", newVal => vm.UpdateCallback(node.CallbackCode, newVal));

        AddSection("BINDING");
        AddStringProperty("Variable Name", node.BindVariable ?? "", newVal => vm.UpdateBindVariable(node.BindVariable, newVal));
    }

    private MainWindowViewModel? GetMainVM() => Tag as MainWindowViewModel;

    private void AddSection(string title)
    {
        PropertiesPanel.Children.Add(new TextBlock
        {
            Text = title,
            Foreground = (Brush)FindResource("TextMuted"),
            FontSize = 10,
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(0, 10, 0, 4)
        });
        PropertiesPanel.Children.Add(new Border
        {
            Height = 1,
            Background = (Brush)FindResource("PanelBorder"),
            Margin = new Thickness(0, 0, 0, 6)
        });
    }

    private void AddStringProperty(string label, string value, Action<string>? onChange, bool readOnly = false)
    {
        var row = new Grid { Margin = new Thickness(0, 2, 0, 2) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.4, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.6, GridUnitType.Star) });

        var lbl = new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("TextForeground"),
            FontSize = 11,
            VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(lbl, 0);
        row.Children.Add(lbl);

        var tb = new TextBox
        {
            Text = value,
            Background = (Brush)FindResource("InputBackground"),
            Foreground = (Brush)FindResource("TextForeground"),
            BorderThickness = new Thickness(1),
            BorderBrush = (Brush)FindResource("PanelBorder"),
            FontSize = 11,
            Padding = new Thickness(4, 2, 4, 2),
            IsReadOnly = readOnly
        };
        if (onChange != null)
            tb.LostFocus += (s, e) => onChange(tb.Text);
        Grid.SetColumn(tb, 1);
        row.Children.Add(tb);

        PropertiesPanel.Children.Add(row);
    }

    private void AddNumberProperty(string label, double value, Action<double>? onChange)
    {
        var row = new Grid { Margin = new Thickness(0, 2, 0, 2) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.4, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.6, GridUnitType.Star) });

        var lbl = new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("TextForeground"),
            FontSize = 11,
            VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(lbl, 0);
        row.Children.Add(lbl);

        var tb = new TextBox
        {
            Text = value.ToString("G"),
            Background = (Brush)FindResource("InputBackground"),
            Foreground = (Brush)FindResource("TextForeground"),
            BorderThickness = new Thickness(1),
            BorderBrush = (Brush)FindResource("PanelBorder"),
            FontSize = 11,
            Padding = new Thickness(4, 2, 4, 2)
        };
        tb.LostFocus += (s, e) =>
        {
            if (double.TryParse(tb.Text, out var v))
                onChange?.Invoke(v);
            else
                tb.BorderBrush = Brushes.Red;
        };
        Grid.SetColumn(tb, 1);
        row.Children.Add(tb);

        PropertiesPanel.Children.Add(row);
    }

    private void AddBoolProperty(string label, bool value, Action<bool>? onChange)
    {
        var row = new Grid { Margin = new Thickness(0, 2, 0, 2) };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.4, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(0.6, GridUnitType.Star) });

        var lbl = new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("TextForeground"),
            FontSize = 11,
            VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(lbl, 0);
        row.Children.Add(lbl);

        var cb = new CheckBox
        {
            IsChecked = value,
            VerticalAlignment = VerticalAlignment.Center
        };
        cb.Checked += (s, e) => onChange?.Invoke(true);
        cb.Unchecked += (s, e) => onChange?.Invoke(false);
        Grid.SetColumn(cb, 1);
        row.Children.Add(cb);

        PropertiesPanel.Children.Add(row);
    }

    private void AddCodeProperty(string label, string value, Action<string>? onChange)
    {
        PropertiesPanel.Children.Add(new TextBlock
        {
            Text = label,
            Foreground = (Brush)FindResource("TextForeground"),
            FontSize = 11,
            Margin = new Thickness(0, 4, 0, 2)
        });

        var tb = new TextBox
        {
            Text = value,
            Background = (Brush)FindResource("InputBackground"),
            Foreground = new SolidColorBrush(Color.FromRgb(0xCE, 0xD4, 0xDA)),
            BorderThickness = new Thickness(1),
            BorderBrush = (Brush)FindResource("PanelBorder"),
            FontFamily = new FontFamily("Consolas"),
            FontSize = 11,
            Padding = new Thickness(4),
            AcceptsReturn = true,
            AcceptsTab = true,
            TextWrapping = TextWrapping.Wrap,
            MinHeight = 60,
            MaxHeight = 200,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto
        };
        tb.LostFocus += (s, e) => onChange?.Invoke(tb.Text);
        PropertiesPanel.Children.Add(tb);
    }
}
