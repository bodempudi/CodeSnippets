
using System;
using System.Data;
using System.Data.SqlClient;
using OracleConn; // Namespace from Interop.OracleConn.dll

namespace OracleToSqlLoader
{
    public class OracleToSqlLoader
    {
        public static void Main(string[] args)
        {
            try
            {
                // Oracle Connection Manager instance
                ConnectionManagerOracleClass oracleManager = new ConnectionManagerOracleClass();

                // Configure Oracle properties
                oracleManager.ConnectionString = "Data Source=ORCL;User Id=scott;Password=tiger;";
                oracleManager.ServerName = "ORCL";
                oracleManager.UserName = "scott";
                oracleManager.Password = "tiger";

                // Acquire Oracle connection
                dynamic oracleConn = oracleManager.AcquireConnection(null);
                Console.WriteLine("✅ Oracle connection acquired successfully.");

                // Load data from Oracle table into DataTable
                DataTable oracleData = LoadOracleData(oracleConn, "SELECT * FROM EMP");

                // Push data to SQL Server
                string sqlServerConnStr = "Server=SQLSERVERNAME;Database=TargetDB;Integrated Security=True;";
                BulkInsertToSql(oracleData, sqlServerConnStr, "dbo.EmpTarget");

                // Release Oracle connection
                oracleManager.ReleaseConnection(oracleConn);
                Console.WriteLine("✅ Data load completed successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Error: " + ex.Message);
            }
        }

        /// <summary>
        /// Reads data from Oracle using dynamic COM connection
        /// </summary>
        private static DataTable LoadOracleData(dynamic oracleConn, string query)
        {
            DataTable dt = new DataTable();
            using (var cmd = oracleConn.CreateCommand())
            {
                cmd.CommandText = query;
                using (var reader = cmd.ExecuteReader())
                {
                    dt.Load(reader);
                }
            }
            return dt;
        }

        /// <summary>
        /// Bulk insert into SQL Server using SqlBulkCopy
        /// </summary>
        private static void BulkInsertToSql(DataTable data, string sqlConnStr, string targetTable)
        {
            using (SqlConnection sqlConn = new SqlConnection(sqlConnStr))
            {
                sqlConn.Open();
                using (SqlBulkCopy bulkCopy = new SqlBulkCopy(sqlConn))
                {
                    bulkCopy.DestinationTableName = targetTable;
                    bulkCopy.WriteToServer(data);
                }
            }
        }
    }
}
