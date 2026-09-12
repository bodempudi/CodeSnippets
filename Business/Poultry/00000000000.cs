private static bool ContainsComment(
    BooleanExpression predicate,
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

        if (token == null)
        {
            continue;
        }

        if (token.TokenType ==
                TSqlTokenType.SingleLineComment ||
            token.TokenType ==
                TSqlTokenType.MultilineComment)
        {
            return true;
        }
    }

    return false;
}
