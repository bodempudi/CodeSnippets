private static bool ContainsComment(
    TSqlFragment fragment,
    LayoutContext layoutContext)
{
    if (fragment == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return false;
    }

    for (int i = fragment.FirstTokenIndex;
         i <= fragment.LastTokenIndex &&
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
