bool isInlineTableValuedFunction =
    ApplyInlineTableValuedFunctionReturn(
        context,
        layoutContext,
        asIndex,
        baseIndent);

if (!isInlineTableValuedFunction)
{
    ApplyBodyBoundary(
        context,
        layoutContext,
        asIndex,
        baseIndent);
}
