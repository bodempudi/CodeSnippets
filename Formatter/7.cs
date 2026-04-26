using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace SqlFormatter.Core.Formatting
{
	public sealed class StatementFormatter
	{
		private readonly SqlFormatterContext _context;
		private readonly QueryFormatter _query;

		public StatementFormatter(SqlFormatterContext context)
		{
			_context = context;
			_query = new QueryFormatter(context);
		}

		public void FormatStatement(TSqlStatement statement, int indent)
		{
			if (statement is SelectStatement select)
			{
				_query.FormatSelect(select, indent);
				return;
			}

			_context.Writer.WriteLine(indent,
				_context.Generator.Generate(statement));
		}
	}
}
