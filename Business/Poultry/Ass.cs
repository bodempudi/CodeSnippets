private static void ApplySelectSource(
    SelectInsertSource selectSource,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (selectSource == null ||
        selectSource.Select == null)
    {
        return;
    }

    int statementIndent =
        StatementIndentResolver.GetStatementIndent(
            selectSource,
            layoutContext);

    int selectIndex =
        layoutContext.TokenNavigator.FindMeaningfulTokenByTextBetween(
            selectSource.FirstTokenIndex,
            selectSource.LastTokenIndex,
            "SELECT");

    if (selectIndex < 0)
    {
        return;
    }

    layoutContext.AddInstruction(
        selectIndex,
        statementIndent,
        "DmlLayoutPolicy",
        context);
}
