private static int GetControlFlowBooleanIndent(
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
         * If a query is reached first, this Boolean belongs
         * to WHERE / HAVING / JOIN etc.
         *
         * It must not inherit IF / WHILE indentation.
         */
        if (current is QuerySpecification)
        {
            return -1;
        }

        /*
         * Nested Boolean parenthesis adds one level.
         */
        if (current is BooleanParenthesisExpression)
        {
            parenthesisDepth++;
        }

        /*
         * Nearest IF owns the Boolean expression.
         */
        IfStatement ifStatement =
            current as IfStatement;

        if (ifStatement != null)
        {
            int ifIndent =
                StatementIndentResolver
                    .GetStatementIndent(
                        ifStatement,
                        layoutContext);

            return ifIndent +
                   parenthesisDepth;
        }

        /*
         * Nearest WHILE owns the Boolean expression.
         */
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
