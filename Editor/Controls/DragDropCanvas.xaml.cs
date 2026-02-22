using System.Windows;
using System.Windows.Controls;

namespace StarLibEditor.Controls;

public partial class DragDropCanvas : UserControl
{
    public event Action<object, Point>? ItemDropped;

    public DragDropCanvas()
    {
        InitializeComponent();
    }

    public Canvas Canvas => InnerCanvas;

    private void OnDragOver(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent("PaletteItem"))
        {
            e.Effects = DragDropEffects.Copy;
            var pos = e.GetPosition(InnerCanvas);
            InsertionLine.Visibility = Visibility.Visible;
            Canvas.SetLeft(InsertionLine, 15);
            Canvas.SetTop(InsertionLine, pos.Y);
            InsertionLine.Width = InnerCanvas.ActualWidth - 30;
        }
        else
        {
            e.Effects = DragDropEffects.None;
        }
        e.Handled = true;
    }

    private void OnDragLeave(object sender, DragEventArgs e)
    {
        InsertionLine.Visibility = Visibility.Collapsed;
    }

    private void OnDrop(object sender, DragEventArgs e)
    {
        InsertionLine.Visibility = Visibility.Collapsed;
        if (e.Data.GetDataPresent("PaletteItem"))
        {
            var item = e.Data.GetData("PaletteItem");
            var pos = e.GetPosition(InnerCanvas);
            ItemDropped?.Invoke(item, pos);
        }
        e.Handled = true;
    }
}
