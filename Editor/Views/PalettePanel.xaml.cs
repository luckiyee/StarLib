using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Views;

public partial class PalettePanel : UserControl
{
    public PalettePanel()
    {
        InitializeComponent();
    }

    private void PaletteItem_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is PaletteItem item)
        {
            if (e.ClickCount == 2)
            {
                if (DataContext is PaletteViewModel vm)
                    vm.AddWidgetCommand.Execute(item);
            }
            else
            {
                var data = new DataObject("PaletteItem", item);
                DragDrop.DoDragDrop(fe, data, DragDropEffects.Copy);
            }
        }
    }
}
