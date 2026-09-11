public void Apply(
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (context == null ||
        context.Node == null ||
        layoutContext == null)
    {
        return;
    }

    QualifiedJoin qualifiedJoin =
        context.Node as QualifiedJoin;

    if (qualifiedJoin == null)
    {
        return;
    }

    int queryBaseIndent =
        GetJoinQueryBaseIndent(
            qualifiedJoin,
            layoutContext);

    /*
     * ==========================================================
     * JOIN
     * ==========================================================
     *
     * Important:
     *
     * A JOIN chain is represented by ScriptDom as nested
     * QualifiedJoin objects.
     *
     * Therefore each QualifiedJoin must format its own JOIN token.
     */
    if (qualifiedJoin.SecondTableReference != null)
    {
        int joinStart =
            layoutContext.TokenNavigator.FindJoinStart(
                qualifiedJoin,
                qualifiedJoin.SecondTableReference);

        if (joinStart >= 0)
        {
            layoutContext.AddInstruction(
                joinStart,
                queryBaseIndent + 1,
                "JoinLayoutPolicy",
                context);
        }

        /*
         * JOIN to derived table.
         */
        QueryDerivedTable derivedTable =
            qualifiedJoin.SecondTableReference
                as QueryDerivedTable;

        if (derivedTable != null)
        {
            ApplyDerivedTableParentheses(
                derivedTable,
                queryBaseIndent + 1,
                context,
                layoutContext);
        }
    }

    /*
     * ==========================================================
     * ON
     * ==========================================================
     *
     * Search only AFTER this JOIN's second table.
     *
     * Do not search from QualifiedJoin.FirstTokenIndex because
     * nested QualifiedJoin structures may contain earlier ON
     * tokens.
     */
    if (qualifiedJoin.SecondTableReference != null &&
        qualifiedJoin.SearchCondition != null)
    {
        int searchStart =
            qualifiedJoin.SecondTableReference.LastTokenIndex + 1;

        int searchEnd =
            qualifiedJoin.SearchCondition.FirstTokenIndex;

        int onIndex =
            layoutContext.TokenNavigator.FindTokenBetween(
                searchStart,
                searchEnd,
                TSqlTokenType.On);

        if (onIndex >= 0)
        {
            layoutContext.AddInstruction(
                onIndex,
                queryBaseIndent + 2,
                "JoinLayoutPolicy",
                context);
        }
    }
}
