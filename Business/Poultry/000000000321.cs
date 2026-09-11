private static int GetWhileBooleanIndent(
    TSqlFragment node,
    LayoutContext layoutContext)
{
    if (node == null ||
        layoutContext == null ||
        layoutContext.Walker == null)
    {
        return -1;
    }

    int parenthesisDepth = 0;

    TSqlFragment current =
        layoutContext.Walker.GetParent(
            node);

    while (current != null)
    {
        /*
         * Once we reach a query, this Boolean belongs to
         * WHERE / HAVING / JOIN etc., not to WHILE.
         */
        if (current is QuerySpecification)
        {
            return -1;
        }

        if (current is BooleanParenthesisExpression)
        {
            parenthesisDepth++;
        }

        WhileStatement whileStatement =
            current as WhileStatement;

        if (whileStatement != null)
        {
            int whileIndent =
                StatementIndentResolver
                    .GetStatementIndent(
                        whileStatement,
                        layoutContext);

            return whileIndent +
                   parenthesisDepth;
        }

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    return -1;
}
