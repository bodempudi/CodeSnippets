using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace SqlFormatter.Core.Services
{
	public sealed class SqlGenerationService
	{
		public string Generate(TSqlFragment fragment)
		{
			var generator = new Sql160ScriptGenerator();
			generator.GenerateScript(fragment, out string sql);
			return sql.Trim();
		}
	}
}
