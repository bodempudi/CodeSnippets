private static void ApplyDerivedTableParentheses(
    QueryDerivedTable derivedTable,
    int indent,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (derivedTable == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return;
    }

    int openParenthesisIndex =
        FindOpeningParenthesis(
            derivedTable,
            layoutContext);

    if (openParenthesisIndex < 0)
    {
        return;
    }

    int closeParenthesisIndex =
        FindMatchingClosingParenthesis(
            openParenthesisIndex,
            derivedTable.LastTokenIndex,
            layoutContext);

    /*
     * Opening (
     *
     *     INNER JOIN
     *     (
     */
    layoutContext.AddInstruction(
        openParenthesisIndex,
        indent,
        "JoinLayoutPolicy",
        context);

    /*
     * Inner SELECT
     *
     *     (
     *         SELECT
     *
     * Derived-table query is one level
     * inside the opening parenthesis.
     */
    int selectIndex = -1;

    int searchEnd =
        closeParenthesisIndex >= 0
            ? closeParenthesisIndex
            : derivedTable.LastTokenIndex;

    for (int i = openParenthesisIndex + 1;
         i <= searchEnd &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        if (layoutContext.Tokens[i].TokenType ==
            TSqlTokenType.Select)
        {
            selectIndex = i;
            break;
        }
    }

    if (selectIndex >= 0)
    {
        layoutContext.AddInstruction(
            selectIndex,
            indent + 1,
            "JoinLayoutPolicy",
            context);
    }

    /*
     * Closing )
     *
     *     (
     *         SELECT
     *             ...
     *     )
     */
    if (closeParenthesisIndex >= 0)
    {
        layoutContext.AddInstruction(
            closeParenthesisIndex,
            indent,
            "JoinLayoutPolicy",
            context);
    }
}
