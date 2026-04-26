private void FormatQuery(QuerySpecification q, int indent)
{
	_context.Writer.WriteLine(
		indent,
		_context.Keywords.Kw("SELECT"));

	for (int i = 0; i < q.SelectElements.Count; i++)
	{
		string prefix = i == 0 ? string.Empty : ",";

		_context.Writer.WriteLine(
			indent + 1,
			prefix + _context.Generator.Generate(q.SelectElements[i]));
	}

	if (q.FromClause != null && q.FromClause.TableReferences.Count > 0)
	{
		_context.Writer.WriteLine(
			indent,
			_context.Keywords.Kw("FROM"));

		for (int i = 0; i < q.FromClause.TableReferences.Count; i++)
		{
			string prefix = i == 0 ? string.Empty : ",";

			_context.Writer.WriteLine(
				indent + 1,
				prefix + _context.Generator.Generate(q.FromClause.TableReferences[i]));
		}
	}

	if (q.WhereClause != null)
	{
		_context.Writer.WriteLine(
			indent,
			_context.Keywords.Kw("WHERE"));

		_context.Writer.WriteLine(
			indent + 1,
			_context.Generator.Generate(q.WhereClause.SearchCondition));
	}
}
