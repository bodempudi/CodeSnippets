using Microsoft.SqlServer.TransactSql.ScriptDom;
using System.Collections.Generic;
using System.IO;
using SqlFormatter.Core.Configuration;
using SqlFormatter.Core.Formatting;

namespace SqlFormatter.Core
{
	public sealed class ScriptDomCustomFormatterService
	{
		private readonly SqlFormattingOptions _options;

		public ScriptDomCustomFormatterService(SqlFormattingOptions options)
		{
			_options = options;
		}

		public string Format(string sql)
		{
			var parser = new TSql160Parser(false);

			using var reader = new StringReader(sql);
			IList<ParseError> errors;

			var fragment = parser.Parse(reader, out errors);

			var script = fragment as TSqlScript;

			var context = new SqlFormatterContext(_options);
			var formatter = new StatementFormatter(context);

			foreach (var batch in script.Batches)
			{
				foreach (var stmt in batch.Statements)
				{
					formatter.FormatStatement(stmt, 0);
					context.Writer.WriteBlankLine();
				}
			}

			return context.Writer.ToString();
		}
	}
}
