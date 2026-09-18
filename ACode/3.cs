private static void ApplyConvertCall(
    ConvertCall convertCall,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (convertCall == null ||
        context == null ||
        layoutContext == null)
    {
        return;
    }

    int convertIndent =
        ExpressionIndentResolver
            .GetExpressionBaseIndent(
                convertCall,
                layoutContext);

    /*
     * Target:
     *
     * SELECT
     *     CONVERT
     *     (
     *         VARCHAR(10),
     *         CASE
     *             WHEN ...
     *             ELSE ...
     *         END
     *     );
     */

    layoutContext.AddInstruction(
        convertCall.FirstTokenIndex,
        convertIndent,
        "ComplexExpressionLayoutPolicy",
        context);

    int leftParenthesisIndex =
        FindToken(
            layoutContext,
            convertCall.FirstTokenIndex,
            convertCall.LastTokenIndex,
            TSqlTokenType.LeftParenthesis);

    if (leftParenthesisIndex >= 0)
    {
        layoutContext.AddInstruction(
            leftParenthesisIndex,
            convertIndent,
            "ComplexExpressionLayoutPolicy",
            context);
    }

    int rightParenthesisIndex =
        FindLastToken(
            layoutContext,
            convertCall.FirstTokenIndex,
            convertCall.LastTokenIndex,
            TSqlTokenType.RightParenthesis);

    if (rightParenthesisIndex >= 0)
    {
        layoutContext.AddInstruction(
            rightParenthesisIndex,
            convertIndent,
            "ComplexExpressionLayoutPolicy",
            context);
    }
}
