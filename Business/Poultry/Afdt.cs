private static void ApplyFromDerivedTable(
    QueryDerivedTable derivedTable,
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

    if (closeParenthesisIndex < 0)
    {
        return;
    }

    int baseIndent =
        QueryIndentResolver.GetQueryBaseIndent(
            derivedTable,
            layoutContext);

    layoutContext.AddInstruction(
        openParenthesisIndex,
        baseIndent,
        "SubqueryLayoutPolicy",
        context);

    int selectIndex =
        FindToken(
            layoutContext,
            openParenthesisIndex + 1,
            closeParenthesisIndex - 1,
            TSqlTokenType.Select);

    if (selectIndex >= 0)
    {
        layoutContext.AddInstruction(
            selectIndex,
            baseIndent + 1,
            "SubqueryLayoutPolicy",
            context);
    }

    layoutContext.AddInstruction(
        closeParenthesisIndex,
        baseIndent,
        "SubqueryLayoutPolicy",
        context);

    layoutContext.Diagnostics.Add(
        "SUBQUERY",
        "Derived table layout created. " +
        "OpenIndex=" +
        openParenthesisIndex +
        ", SelectIndex=" +
        selectIndex +
        ", CloseIndex=" +
        closeParenthesisIndex +
        ", BaseIndent=" +
        baseIndent +
        ".");
}
