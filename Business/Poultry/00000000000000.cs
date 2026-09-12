private static bool ContainsTokenType(
    BooleanExpression predicate,
    TSqlTokenType tokenType,
    LayoutContext layoutContext)
{
    if (predicate == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return false;
    }

    for (int i = predicate.FirstTokenIndex;
         i <= predicate.LastTokenIndex &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token != null &&
            token.TokenType == tokenType)
        {
            return true;
        }
    }

    return false;
}
