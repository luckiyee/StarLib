using System.Collections;
using System.Windows;
using System.Windows.Controls;

namespace StarLibEditor.Controls;

public partial class VirtualizedList : UserControl
{
    public static readonly DependencyProperty ItemsSourceProperty =
        DependencyProperty.Register(nameof(ItemsSource), typeof(IEnumerable), typeof(VirtualizedList),
            new PropertyMetadata(null, OnItemsSourceChanged));

    public static readonly DependencyProperty ItemTemplateProperty =
        DependencyProperty.Register(nameof(ItemTemplate), typeof(DataTemplate), typeof(VirtualizedList),
            new PropertyMetadata(null, OnItemTemplateChanged));

    public IEnumerable? ItemsSource
    {
        get => (IEnumerable?)GetValue(ItemsSourceProperty);
        set => SetValue(ItemsSourceProperty, value);
    }

    public DataTemplate? ItemTemplate
    {
        get => (DataTemplate?)GetValue(ItemTemplateProperty);
        set => SetValue(ItemTemplateProperty, value);
    }

    public object? SelectedItem
    {
        get => InnerList.SelectedItem;
        set => InnerList.SelectedItem = value;
    }

    public event SelectionChangedEventHandler? SelectionChanged
    {
        add => InnerList.SelectionChanged += value;
        remove => InnerList.SelectionChanged -= value;
    }

    public VirtualizedList()
    {
        InitializeComponent();
    }

    private static void OnItemsSourceChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is VirtualizedList vl)
            vl.InnerList.ItemsSource = e.NewValue as IEnumerable;
    }

    private static void OnItemTemplateChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is VirtualizedList vl)
            vl.InnerList.ItemTemplate = e.NewValue as DataTemplate;
    }
}
