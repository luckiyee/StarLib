using System.Collections.ObjectModel;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Newtonsoft.Json;
using StarLibEditor.Models;

namespace StarLibEditor.Views.Dialogs;

public partial class TemplateManagerDialog : Window
{
    private readonly ObservableCollection<TemplateModel> _templates;
    public TemplateModel? SelectedTemplate { get; private set; }
    public bool ShouldInsert { get; private set; }

    public TemplateManagerDialog(ObservableCollection<TemplateModel> templates)
    {
        InitializeComponent();
        _templates = templates;
        RefreshList();
    }

    private void RefreshList()
    {
        TemplateList.Items.Clear();
        foreach (var t in _templates)
            TemplateList.Items.Add(new ListBoxItem { Content = t.Name, Tag = t });
    }

    private void TemplateList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        DetailsPanel.Children.Clear();
        if (TemplateList.SelectedItem is not ListBoxItem item) return;
        if (item.Tag is not TemplateModel template) return;

        SelectedTemplate = template;
        DetailsPanel.Children.Add(new TextBlock
        {
            Text = template.Name,
            Foreground = System.Windows.Media.Brushes.White,
            FontSize = 16, FontWeight = FontWeights.Bold, Margin = new Thickness(0, 0, 0, 8)
        });
        DetailsPanel.Children.Add(new TextBlock
        {
            Text = $"{template.Nodes.Count} node(s)",
            Foreground = System.Windows.Media.Brushes.Gray, FontSize = 12
        });

        foreach (var node in template.Nodes)
        {
            DetailsPanel.Children.Add(new TextBlock
            {
                Text = $"  [{node.Type}] {node.DisplayName}",
                Foreground = System.Windows.Media.Brushes.LightGray,
                FontSize = 11, Margin = new Thickness(8, 2, 0, 0)
            });
        }
    }

    private void InsertToTab_Click(object sender, RoutedEventArgs e)
    {
        if (SelectedTemplate != null)
        {
            ShouldInsert = true;
            DialogResult = true;
            Close();
        }
    }

    private void Delete_Click(object sender, RoutedEventArgs e)
    {
        if (SelectedTemplate != null)
        {
            _templates.Remove(SelectedTemplate);
            SelectedTemplate = null;
            RefreshList();
        }
    }

    private void Import_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "StarLib Template (*.slt)|*.slt|JSON (*.json)|*.json",
            Title = "Import Template"
        };
        if (dialog.ShowDialog() == true)
        {
            try
            {
                var json = File.ReadAllText(dialog.FileName);
                var template = JsonConvert.DeserializeObject<TemplateModel>(json);
                if (template != null)
                {
                    _templates.Add(template);
                    RefreshList();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to import: {ex.Message}", "Error");
            }
        }
    }

    private void Export_Click(object sender, RoutedEventArgs e)
    {
        if (SelectedTemplate == null) return;
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "StarLib Template (*.slt)|*.slt",
            FileName = SelectedTemplate.Name + ".slt"
        };
        if (dialog.ShowDialog() == true)
        {
            var json = JsonConvert.SerializeObject(SelectedTemplate, Formatting.Indented);
            File.WriteAllText(dialog.FileName, json);
        }
    }
}
