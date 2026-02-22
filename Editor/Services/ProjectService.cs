using Newtonsoft.Json;
using StarLibEditor.Models;

namespace StarLibEditor.Services;

public class ProjectService
{
    private static readonly string AppDataDir =
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "StarLibEditor");

    private static readonly string RecentProjectsFile =
        Path.Combine(AppDataDir, "recent_projects.json");

    public ProjectService()
    {
        Directory.CreateDirectory(AppDataDir);
    }

    public async Task<StarLibProject?> LoadAsync(string filePath)
    {
        try
        {
            var json = await File.ReadAllTextAsync(filePath);
            var project = JsonConvert.DeserializeObject<StarLibProject>(json, GetSettings());
            if (project != null)
            {
                project.FilePath = filePath;
                project.IsDirty = false;
                AddToRecentProjects(filePath);
            }
            return project;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Failed to load project: {ex.Message}");
            return null;
        }
    }

    public async Task SaveAsync(StarLibProject project, string filePath)
    {
        project.Meta.UpdatedAt = DateTime.UtcNow.ToString("o");
        var json = JsonConvert.SerializeObject(project, Formatting.Indented, GetSettings());
        await File.WriteAllTextAsync(filePath, json);
        project.FilePath = filePath;
        project.IsDirty = false;
        AddToRecentProjects(filePath);
    }

    public List<string> GetRecentProjects()
    {
        try
        {
            if (File.Exists(RecentProjectsFile))
                return JsonConvert.DeserializeObject<List<string>>(File.ReadAllText(RecentProjectsFile)) ?? new();
        }
        catch { }
        return new();
    }

    private void AddToRecentProjects(string filePath)
    {
        var recent = GetRecentProjects();
        recent.Remove(filePath);
        recent.Insert(0, filePath);
        if (recent.Count > 10) recent = recent.Take(10).ToList();
        try
        {
            File.WriteAllText(RecentProjectsFile, JsonConvert.SerializeObject(recent));
        }
        catch { }
    }

    private static JsonSerializerSettings GetSettings() => new()
    {
        NullValueHandling = NullValueHandling.Ignore,
        TypeNameHandling = TypeNameHandling.Auto,
        Formatting = Formatting.Indented,
        Converters = { new Newtonsoft.Json.Converters.StringEnumConverter() }
    };
}
