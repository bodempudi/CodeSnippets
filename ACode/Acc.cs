private static void ApplyCastCall(
    CastCall castCall,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (castCall == null ||
        context == null ||
        layoutContext == null)
    {
        return;
    }

    int castIndent =
        ExpressionIndentResolver
            .GetExpressionBaseIndent(
                castCall,
                layoutContext);

    /*
     * Target:
     *
     * SELECT
     *     CAST
     *     (
     *         CASE
     *             ...
     *         END
     *         AS VARCHAR(10)
     *     )
     */

    layoutContext.AddInstruction(
        castCall.FirstTokenIndex,
        castIndent,
        "ComplexExpressionLayoutPolicy",
        context);

    int leftParenthesisIndex =
        FindToken(
            layoutContext,
            castCall.FirstTokenIndex,
            castCall.LastTokenIndex,
            TSqlTokenType.LeftParenthesis);

    if (leftParenthesisIndex >= 0)
    {
        layoutContext.AddInstruction(
            leftParenthesisIndex,
            castIndent,
            "ComplexExpressionLayoutPolicy",
            context);
    }

    if (castCall.Parameter != null)
    {
        layoutContext.AddInstruction(
            castCall.Parameter.FirstTokenIndex,
            castIndent + 1,
            "ComplexExpressionLayoutPolicy",
            context);
    }

    int asIndex =
        FindToken(
            layoutContext,
            castCall.FirstTokenIndex,
            castCall.LastTokenIndex,
            TSqlTokenType.As);

    if (asIndex >= 0)
    {
        layoutContext.AddInstruction(
            asIndex,
            castIndent + 1,
            "ComplexExpressionLayoutPolicy",
            context);
    }

    int rightParenthesisIndex =
        FindLastToken(
            layoutContext,
            castCall.FirstTokenIndex,
            castCall.LastTokenIndex,
            TSqlTokenType.RightParenthesis);

    if (rightParenthesisIndex >= 0)
    {
        layoutContext.AddInstruction(
            rightParenthesisIndex,
            castIndent,
            "ComplexExpressionLayoutPolicy",
            context);
    }
}
