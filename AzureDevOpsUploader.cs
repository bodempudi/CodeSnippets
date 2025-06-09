using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Collections.Generic;
using System.Threading.Tasks;
using Newtonsoft.Json;

public class Program
{
    static readonly string organization = "PowerBIProPOCs";
    static readonly string project = "POCs";
    static readonly string repoId = "POCs";
    static readonly string branchName = "main";
    static readonly string pat = "AWpkO6f1Pno2ZuZKgPpuyNPxiuX5sPx5SwQliuqIIHHqp9a38XtgJQQJ99BFACAAAAAAAAAAAAASAZDO1roR";
    static readonly string parentFolderPath = @"C:\Users\bodempudi\source\repos\UploadDemo\";


    public static void Main()
    {
        MainAsync().GetAwaiter().GetResult();
    }

    static async Task MainAsync()
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

            if (!relativePath.StartsWith("/"))
                relativePath = "/" + relativePath;

            var content = File.ReadAllText(fullFilePath);

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

        string base64Auth = Convert.ToBase64String(Encoding.ASCII.GetBytes($":{pat}"));
        string refUrl = $"https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repoId}/refs?filter=heads/{branchName}&api-version=7.0";

        using (var client = new HttpClient())
        {
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", base64Auth);

            var refResponse = await client.GetAsync(refUrl);
            var refContent = await refResponse.Content.ReadAsStringAsync();

            if (!refResponse.IsSuccessStatusCode)
            {
                Console.WriteLine($"Error getting branch info: {refResponse.StatusCode}\n{refContent}");
                return;
            }

            string oldObjectId = GetObjectIdFromRefJson(refContent);
            if (string.IsNullOrEmpty(oldObjectId))
            {
                Console.WriteLine("Failed to retrieve objectId.");
                return;
            }

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
            var json = JsonConvert.SerializeObject(pushBody);
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

    static string GetObjectIdFromRefJson(string json)
    {
        try
        {
            dynamic parsed = JsonConvert.DeserializeObject(json);
            return parsed?.value?[0]?.objectId;
        }
        catch
        {
            return null;
        }
    }
}
