private static int GetInlineTableValuedFunctionQueryIndent(
    QuerySpecification query,
    LayoutContext layoutContext)
{
    if (query == null ||
        layoutContext == null ||
        layoutContext.Walker == null ||
        layoutContext.Tokens == null)
    {
        return -1;
    }

    TSqlFragment current =
        layoutContext.Walker.GetParent(
            query);

    TSqlFragment functionDefinition =
        null;

    while (current != null)
    {
        string typeName =
            current.GetType().Name;

        if (typeName.IndexOf(
                "Function",
                System.StringComparison.OrdinalIgnoreCase) >= 0 &&
            (typeName.StartsWith(
                 "Create",
                 System.StringComparison.Ordinal) ||
             typeName.StartsWith(
                 "Alter",
                 System.StringComparison.Ordinal)))
        {
            functionDefinition =
                current;

            break;
        }

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    if (functionDefinition == null)
    {
        return -1;
    }

    int returnsIndex = -1;
    int tableIndex = -1;
    int returnIndex = -1;

    int searchEnd =
        query.FirstTokenIndex;

    for (int i = functionDefinition.FirstTokenIndex;
         i < searchEnd &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        string text =
            layoutContext.Tokens[i].Text;

        if (returnsIndex < 0 &&
            string.Equals(
                text,
                "RETURNS",
                System.StringComparison.OrdinalIgnoreCase))
        {
            returnsIndex = i;
            continue;
        }

        if (returnsIndex >= 0 &&
            tableIndex < 0 &&
            string.Equals(
                text,
                "TABLE",
                System.StringComparison.OrdinalIgnoreCase))
        {
            tableIndex = i;
            continue;
        }

        if (tableIndex >= 0 &&
            string.Equals(
                text,
                "RETURN",
                System.StringComparison.OrdinalIgnoreCase))
        {
            returnIndex = i;
        }
    }

    if (returnsIndex < 0 ||
        tableIndex < 0 ||
        returnIndex < 0)
    {
        return -1;
    }

    int definitionIndent =
        StatementIndentResolver.GetStatementIndent(
            functionDefinition,
            layoutContext);

    return definitionIndent + 1;
}
