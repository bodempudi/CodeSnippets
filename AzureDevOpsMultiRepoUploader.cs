// AzureDevOpsMultiRepoUploader.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

class AzureDevOpsMultiRepoUploader
{
    static readonly string organization = "your-org";         // <-- CHANGE THIS
    static readonly string project = "your-project";           // <-- CHANGE THIS
    static readonly string branchName = "main";                // <-- CHANGE THIS
    static readonly string pat = "your-pat-token";             // <-- CHANGE THIS
    static readonly string parentFolderPath = @"C:\MyCode";    // <-- CHANGE THIS

    static void Main()
    {
        var task = RunAsync();
        task.Wait();
    }

    static async System.Threading.Tasks.Task RunAsync()
    {
        var base64Auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($":{pat}"));
        var httpClient = new HttpClient();
        httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", base64Auth);

        string repoListUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories?api-version=7.0";
        var repoResponse = await httpClient.GetAsync(repoListUrl);
        var repoJson = await repoResponse.Content.ReadAsStringAsync();

        if (!repoResponse.IsSuccessStatusCode)
        {
            Console.WriteLine("❌ Failed to fetch repositories.");
            Console.WriteLine(repoJson);
            return;
        }

        var repoList = JObject.Parse(repoJson)["value"].ToList();

        Console.WriteLine("Found the following repositories:");
        for (int i = 0; i < repoList.Count; i++)
        {
            Console.WriteLine($"{i + 1}. {repoList[i]["name"]} ({repoList[i]["id"]})");
        }

        Console.Write("Enter repo number to upload files to (or 'all' to upload to all): ");
        var input = Console.ReadLine();

        List<JToken> targetRepos;
        if (input.Trim().ToLower() == "all")
        {
            targetRepos = repoList;
        }
        else if (int.TryParse(input, out int index) && index >= 1 && index <= repoList.Count)
        {
            targetRepos = new List<JToken> { repoList[index - 1] };
        }
        else
        {
            Console.WriteLine("Invalid input.");
            return;
        }

        foreach (var repo in targetRepos)
        {
            string repoName = repo["name"].ToString();
            string repoId = repo["id"].ToString();
            Console.WriteLine($"
📦 Uploading to repo: {repoName}");

            var files = Directory.GetFiles(parentFolderPath, "*", SearchOption.AllDirectories);
            if (files.Length == 0)
            {
                Console.WriteLine("No files found.");
                return;
            }

            var changes = new List<object>();
            foreach (var filePath in files)
            {
                var relativePath = filePath.Substring(parentFolderPath.Length).Replace("\", "/");
                if (!relativePath.StartsWith("/")) relativePath = "/" + relativePath;

                var content = File.ReadAllText(filePath);
                changes.Add(new
                {
                    changeType = "add",
                    item = new { path = relativePath },
                    newContent = new { content = content, contentType = "rawtext" }
                });
            }

            // Get latest commit ID
            string refUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repoId}/refs?filter=heads/{branchName}&api-version=7.0";
            var refResponse = await httpClient.GetAsync(refUrl);
            var refJson = await refResponse.Content.ReadAsStringAsync();

            if (!refResponse.IsSuccessStatusCode)
            {
                Console.WriteLine($"❌ Failed to get ref for {repoName}:
{refJson}");
                continue;
            }

            var oldObjectId = JObject.Parse(refJson)["value"][0]["objectId"].ToString();

            var pushBody = new
            {
                refUpdates = new[]
                {
                    new { name = $"refs/heads/{branchName}", oldObjectId = oldObjectId }
                },
                commits = new[]
                {
                    new
                    {
                        comment = "Bulk upload via MultiRepoUploader",
                        changes = changes
                    }
                }
            };

            var pushUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repoId}/pushes?api-version=7.0";
            var jsonBody = JsonConvert.SerializeObject(pushBody);
            var contentBody = new StringContent(jsonBody, Encoding.UTF8, "application/json");

            var pushResponse = await httpClient.PostAsync(pushUrl, contentBody);
            var pushResult = await pushResponse.Content.ReadAsStringAsync();

            if (pushResponse.IsSuccessStatusCode)
                Console.WriteLine("✅ Upload successful.");
            else
                Console.WriteLine($"❌ Upload failed for {repoName}: {pushResponse.StatusCode}
{pushResult}");
        }
    }
}
