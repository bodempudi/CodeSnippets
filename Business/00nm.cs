private static int GetPreviousStatementLastTokenIndex(
    AstNodeContext context)
{
    if (context == null ||
        context.Node == null)
    {
        return -1;
    }

    StatementList statementList =
        context.Parent as StatementList;

    if (statementList == null ||
        statementList.Statements == null)
    {
        return -1;
    }

    int currentFirstTokenIndex =
        context.Node.FirstTokenIndex;

    int previousLastTokenIndex = -1;

    foreach (TSqlStatement statement
        in statementList.Statements)
    {
        if (statement == null)
        {
            continue;
        }

        if (statement.FirstTokenIndex >=
            currentFirstTokenIndex)
        {
            break;
        }

        previousLastTokenIndex =
            statement.LastTokenIndex;
    }

    return previousLastTokenIndex;
}
