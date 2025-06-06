
using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Collections.Generic;
using System.Threading.Tasks;

class AzureDevOpsUploader
{
    static readonly string organization = "your-org";         // <-- CHANGE THIS
    static readonly string project = "your-project";           // <-- CHANGE THIS
    static readonly string repoId = "your-repo-name";          // <-- CHANGE THIS
    static readonly string branchName = "main";                // <-- CHANGE THIS
    static readonly string pat = "your-pat-token";             // <-- CHANGE THIS
    static readonly string parentFolderPath = @"C:\MyCode";    // <-- CHANGE THIS

    static async Task Main()
    {
        var files = Directory.GetFiles(parentFolderPath, "*", SearchOption.AllDirectories);
        if (files.Length == 0)
        {
            Console.WriteLine("No files found.");
            return;
        }

        var changes = new List<object>();

        foreach (var fullFilePath in files)
        {
            var relativePath = fullFilePath.Substring(parentFolderPath.Length)
                                           .Replace("\\", "/");

            // Git wants paths to start with /
            if (!relativePath.StartsWith("/"))
                relativePath = "/" + relativePath;

            var content = await File.ReadAllTextAsync(fullFilePath);

            changes.Add(new
            {
                changeType = "add",
                item = new { path = relativePath },
                newContent = new
                {
                    content = content,
                    contentType = "rawtext"
                }
            });
        }

        // Step 1: Get latest commit ID (objectId) on the branch
        string base64Auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($":{pat}"));
        string refUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repoId}/refs?filter=heads/{branchName}&api-version=7.0";

        using var client = new HttpClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", base64Auth);

        var refResponse = await client.GetAsync(refUrl);
        var refContent = await refResponse.Content.ReadAsStringAsync();

        if (!refResponse.IsSuccessStatusCode)
        {
            Console.WriteLine($"Error getting branch info: {refResponse.StatusCode}\n{refContent}");
            return;
        }

        using var refJsonDoc = JsonDocument.Parse(refContent);
        string oldObjectId = refJsonDoc.RootElement
            .GetProperty("value")[0]
            .GetProperty("objectId")
            .GetString();

        // Step 2: Push the commit
        var pushBody = new
        {
            refUpdates = new[]
            {
                new
                {
                    name = $"refs/heads/{branchName}",
                    oldObjectId = oldObjectId
                }
            },
            commits = new[]
            {
                new
                {
                    comment = "Bulk upload from local folder via REST API",
                    changes = changes
                }
            }
        };

        string pushUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repoId}/pushes?api-version=7.0";
        var json = JsonSerializer.Serialize(pushBody);
        var httpContent = new StringContent(json, Encoding.UTF8, "application/json");

        var pushResponse = await client.PostAsync(pushUrl, httpContent);
        var pushResult = await pushResponse.Content.ReadAsStringAsync();

        if (pushResponse.IsSuccessStatusCode)
        {
            Console.WriteLine("✅ Upload successful.");
        }
        else
        {
            Console.WriteLine($"❌ Upload failed: {pushResponse.StatusCode}");
            Console.WriteLine(pushResult);
        }
    }
}
