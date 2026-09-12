private static int GetIfBooleanIndent(
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
         * If we reach a query first, this Boolean belongs
         * to WHERE / HAVING / JOIN etc.
         *
         * It must not inherit IF indentation.
         */
        if (current is QuerySpecification)
        {
            return -1;
        }

        /*
         * Every enclosing Boolean parenthesis represents
         * one nested Boolean level.
         */
        if (current is BooleanParenthesisExpression)
        {
            parenthesisDepth++;
        }

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

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    return -1;
}
