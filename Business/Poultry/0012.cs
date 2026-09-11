private static int FindImmediatePrefixSemicolon(
    LayoutContext layoutContext,
    int withIndex)
{
    if (layoutContext == null ||
        layoutContext.Tokens == null ||
        withIndex <= 0)
    {
        return -1;
    }

    for (int i = withIndex - 1;
         i >= 0;
         i--)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token == null)
        {
            continue;
        }

        if (token.TokenType ==
            TSqlTokenType.WhiteSpace)
        {
            continue;
        }

        /*
         * Only an existing semicolon immediately before
         * WITH belongs to the CTE visual prefix.
         *
         * Any comment or SQL token breaks the relationship.
         */
        if (token.TokenType ==
            TSqlTokenType.Semicolon)
        {
            return i;
        }

        return -1;
    }

    return -1;
}
