using System.Windows;
using System.Windows.Controls;
using StarLibEditor.Models;
using StarLibEditor.ViewModels;

namespace StarLibEditor.Views;

public partial class HierarchyPanel : UserControl
{
    public HierarchyPanel()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (DataContext is HierarchyViewModel vm)
        {
            vm.PropertyChanged += (s, args) =>
            {
                if (args.PropertyName == nameof(HierarchyViewModel.SearchFilter))
                    RebuildTree();
            };
            RebuildTree();
        }
    }

    private MainWindowViewModel? GetMainVM() => Tag as MainWindowViewModel;

    public void RebuildTree()
    {
        var mainVm = GetMainVM();
        if (mainVm == null) return;

        HierarchyTree.Items.Clear();

        var windowItem = new TreeViewItem
        {
            Header = $"Window: {mainVm.Project.Window.Name}",
            IsExpanded = true,
            FontWeight = FontWeights.SemiBold
        };
        HierarchyTree.Items.Add(windowItem);

        foreach (var tab in mainVm.Project.Tabs)
        {
            var tabItem = new TreeViewItem
            {
                Header = $"Tab: {tab.Name}",
                IsExpanded = true,
                Tag = tab
            };

            tabItem.MouseLeftButtonUp += (s, e) =>
            {
                mainVm.Designer.ActiveTab = tab;
                e.Handled = true;
            };

            foreach (var node in tab.Nodes)
            {
                if (DataContext is HierarchyViewModel hvm && !hvm.MatchesFilter(node))
                    continue;

                var nodeItem = new TreeViewItem
                {
                    Header = $"[{node.Type}] {node.DisplayName}",
                    Tag = node
                };

                nodeItem.Selected += (s, e) =>
                {
                    mainVm.Designer.ActiveTab = tab;
                    mainVm.Designer.SelectNode(node);
                    e.Handled = true;
                };

                nodeItem.ContextMenu = BuildNodeContextMenu(node, tab, mainVm);
                tabItem.Items.Add(nodeItem);
            }

            tabItem.ContextMenu = BuildTabContextMenu(tab, mainVm);
            windowItem.Items.Add(tabItem);
        }
    }

    private ContextMenu BuildNodeContextMenu(UINode node, TabModel tab, MainWindowViewModel mainVm)
    {
        var menu = new ContextMenu();
        var dup = new MenuItem { Header = "Duplicate" };
        dup.Click += (s, e) => mainVm.Designer.DuplicateNode(node);
        menu.Items.Add(dup);

        var del = new MenuItem { Header = "Delete" };
        del.Click += (s, e) => mainVm.Designer.RemoveNode(node);
        menu.Items.Add(del);

        return menu;
    }

    private ContextMenu BuildTabContextMenu(TabModel tab, MainWindowViewModel mainVm)
    {
        var menu = new ContextMenu();
        var rename = new MenuItem { Header = "Rename..." };
        rename.Click += (s, e) =>
        {
            var dlg = new Dialogs.InputDialog("New tab name:", "Rename Tab", tab.Name);
            dlg.Owner = Window.GetWindow(this);
            if (dlg.ShowDialog() == true && !string.IsNullOrWhiteSpace(dlg.InputValue))
            {
                var cmd = new Services.Commands.RenameTabCommand(tab, tab.Name, dlg.InputValue);
                mainVm.UndoRedo.Execute(cmd);
                mainVm.RegenerateCode();
                RebuildTree();
            }
        };
        menu.Items.Add(rename);

        if (mainVm.Project.Tabs.Count > 1)
        {
            var del = new MenuItem { Header = "Delete Tab" };
            del.Click += (s, e) =>
            {
                var cmd = new Services.Commands.RemoveTabCommand(mainVm.Project, tab);
                mainVm.UndoRedo.Execute(cmd);
                mainVm.Designer.ActiveTab = mainVm.Project.Tabs.FirstOrDefault();
                mainVm.RegenerateCode();
                RebuildTree();
            };
            menu.Items.Add(del);
        }

        return menu;
    }
}
