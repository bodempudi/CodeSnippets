private static void ApplyWhile(
    WhileStatement whileStatement,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (whileStatement == null ||
        whileStatement.Statement == null)
    {
        return;
    }

    int baseIndent =
        StatementIndentResolver
            .GetStatementIndent(
                whileStatement,
                layoutContext);

    /*
     * WHILE owns the control-flow level.
     *
     * WHILE ...
     * BEGIN
     *     ...
     * END
     */
    layoutContext.AddInstruction(
        whileStatement.FirstTokenIndex,
        baseIndent,
        "ControlFlowLayoutPolicy",
        context);

    int bodyIndent =
        whileStatement.Statement is BeginEndBlockStatement
            ? baseIndent
            : baseIndent + 1;

    layoutContext.AddInstruction(
        whileStatement.Statement.FirstTokenIndex,
        bodyIndent,
        "ControlFlowLayoutPolicy",
        context);
}
