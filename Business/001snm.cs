public static int GetEffectivePreviousStatementEnd(
    LayoutContext layoutContext,
    int previousStatementLastTokenIndex,
    int withIndex)
{
    if (layoutContext == null ||
        layoutContext.Tokens == null ||
        previousStatementLastTokenIndex < 0)
    {
        return previousStatementLastTokenIndex;
    }

    for (int i = previousStatementLastTokenIndex + 1;
         i < withIndex &&
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
            TSqlTokenType.WhiteSpace)
        {
            continue;
        }

        /*
         * The first semicolon following the previous AST statement
         * is treated as that statement's source terminator.
         */
        if (token.TokenType ==
            TSqlTokenType.Semicolon)
        {
            return i;
        }

        break;
    }

    return previousStatementLastTokenIndex;
}
