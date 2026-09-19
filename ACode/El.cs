else
{
    int leftParenthesisIndex =
        FindToken(
            layoutContext,
            convertCall.FirstTokenIndex,
            convertCall.LastTokenIndex,
            TSqlTokenType.LeftParenthesis);

    if (leftParenthesisIndex >= 0)
    {
        layoutContext.AddTightInstruction(
            leftParenthesisIndex,
            nameof(ComplexExpressionLayoutPolicy),
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
        layoutContext.AddTightInstruction(
            rightParenthesisIndex,
            nameof(ComplexExpressionLayoutPolicy),
            context);
    }
}
