private static void ApplyIf(
    IfStatement ifStatement,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    int baseIndent =
        StatementIndentResolver
            .GetStatementIndent(
                ifStatement,
                layoutContext);

    ApplyInlineSimplePredicate(
        ifStatement.Predicate,
        context,
        layoutContext);

    if (ifStatement.ThenStatement != null)
    {
        int thenIndent =
            ifStatement.ThenStatement is BeginEndBlockStatement
                ? baseIndent
                : baseIndent + 1;

        layoutContext.AddInstruction(
            ifStatement
                .ThenStatement
                .FirstTokenIndex,
            thenIndent,
            "ControlFlowLayoutPolicy",
            context);
    }

    if (ifStatement.ElseStatement == null)
    {
        return;
    }

    int elseIndex =
        layoutContext.TokenNavigator
            .FindMeaningfulTokenByTextBetween(
                ifStatement
                    .ThenStatement
                    .LastTokenIndex + 1,
                ifStatement
                    .ElseStatement
                    .FirstTokenIndex,
                "ELSE");

    if (elseIndex >= 0)
    {
        layoutContext.AddInstruction(
            elseIndex,
            baseIndent,
            "ControlFlowLayoutPolicy",
            context);
    }

    int elseBodyIndent =
        ifStatement.ElseStatement is BeginEndBlockStatement
            ? baseIndent
            : baseIndent + 1;

    layoutContext.AddInstruction(
        ifStatement
            .ElseStatement
            .FirstTokenIndex,
        elseBodyIndent,
        "ControlFlowLayoutPolicy",
        context);
}
