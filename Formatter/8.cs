using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace SqlFormatter.Core.Formatting
{
	public sealed class QueryFormatter
	{
		private readonly SqlFormatterContext _context;

		public QueryFormatter(SqlFormatterContext context)
		{
			_context = context;
		}

		public void FormatSelect(SelectStatement stmt, int indent)
		{
			if (stmt.QueryExpression is QuerySpecification qs)
			{
				FormatQuery(qs, indent);
			}
		}

		private void FormatQuery(QuerySpecification q, int indent)
		{
			_context.Writer.WriteLine(indent,
				_context.Keywords.Kw("SELECT"));

			foreach (var col in q.SelectElements)
			{
				_context.Writer.WriteLine(indent + 1,
					_context.Generator.Generate(col));
			}

			if (q.FromClause != null)
			{
				_context.Writer.WriteLine(indent,
					_context.Keywords.Kw("FROM") + " " +
					_context.Generator.Generate(q.FromClause));
			}

			if (q.WhereClause != null)
			{
				_context.Writer.WriteLine(indent,
					_context.Keywords.Kw("WHERE"));

				_context.Writer.WriteLine(indent + 1,
					_context.Generator.Generate(q.WhereClause.SearchCondition));
			}
		}
  }
