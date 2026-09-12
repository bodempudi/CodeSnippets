private static void ApplyWhile(
    WhileStatement whileStatement,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (whileStatement.Statement == null)
    {
        return;
    }

    int baseIndent =
        StatementIndentResolver
            .GetStatementIndent(
                whileStatement,
                layoutContext);

    ApplyInlineSimplePredicate(
        whileStatement.Predicate,
        context,
        layoutContext);

    int bodyIndent =
        whileStatement.Statement is BeginEndBlockStatement
            ? baseIndent
            : baseIndent + 1;

    layoutContext.AddInstruction(
        whileStatement
            .Statement
            .FirstTokenIndex,
        bodyIndent,
        "ControlFlowLayoutPolicy",
        context);
}
