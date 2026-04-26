using System;
using System.IO;
using SqlFormatter.Core;
using SqlFormatter.Core.Configuration;

namespace SqlFormatter.Cli
{
	class Program
	{
		static void Main(string[] args)
		{
			string path = args[0];

			var formatter = new ScriptDomCustomFormatterService(
				new SqlFormattingOptions());

			if (File.Exists(path))
			{
				FormatFile(formatter, path);
			}
			else if (Directory.Exists(path))
			{
				foreach (var file in Directory.GetFiles(path, "*.sql", SearchOption.AllDirectories))
				{
					FormatFile(formatter, file);
				}
			}
		}

		static void FormatFile(ScriptDomCustomFormatterService formatter, string path)
		{
			string input = File.ReadAllText(path);
			string output = formatter.Format(input);
			File.WriteAllText(path, output);
			Console.WriteLine($"Formatted: {path}");
		}
	}
}
