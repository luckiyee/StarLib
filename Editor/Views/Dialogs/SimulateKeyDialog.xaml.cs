using System.Windows;
using System.Windows.Controls;

namespace StarLibEditor.Views.Dialogs;

public partial class SimulateKeyDialog : Window
{
    public string SelectedKey { get; private set; } = "F";

    public SimulateKeyDialog()
    {
        InitializeComponent();
    }

    private void Fire_Click(object sender, RoutedEventArgs e)
    {
        SelectedKey = KeyCombo.Text;
        DialogResult = true;
        Close();
    }

    private void Cancel_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
