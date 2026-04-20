using ScriptDOM;
using SqlFormatter.Core.Formatting; 
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace ScriptDOM
{
    internal class Program
    {
        static void Main(string[] args)
        {
            try
            {


                string filePath = @"D:\Learning\sample.sql"; ;

                if (string.IsNullOrWhiteSpace(filePath))
                {
                    System.Console.WriteLine("File path is empty.");
                     
                }

                if (!File.Exists(filePath))
                {
                    System.Console.WriteLine("File not found: " + filePath);
                     
                }

                string extension = Path.GetExtension(filePath);
                if (!string.Equals(extension, ".sql", StringComparison.OrdinalIgnoreCase))
                {
                    System.Console.WriteLine("Only .sql files are supported.");
                     
                }

                string inputSql = File.ReadAllText(filePath);

                var formatter = new ScriptDomCustomFormatterService();
                string formattedSql = formatter.Format(inputSql);

                File.WriteAllText(filePath, formattedSql);

                System.Console.WriteLine("SQL formatted successfully.");
                System.Console.WriteLine("Updated file: " + filePath);

                
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("Error while formatting SQL file.");
                System.Console.WriteLine(ex.Message);
                 
            }
        }
    }
}
