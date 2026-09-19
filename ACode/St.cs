int styleCommaIndex =
    FindLastToken(
        layoutContext,
        convertCall.Parameter.LastTokenIndex + 1,
        convertCall.Style.FirstTokenIndex - 1,
        TSqlTokenType.Comma);

if (styleCommaIndex >= 0)
{
    layoutContext.AddTightInstruction(
        styleCommaIndex,
        nameof(ComplexExpressionLayoutPolicy),
        context);
}

layoutContext.AddSpaceInstruction(
    convertCall.Style.FirstTokenIndex,
    nameof(ComplexExpressionLayoutPolicy),
    context);
