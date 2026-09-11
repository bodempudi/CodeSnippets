private static bool HasNewLineBetween(
    IList<TSqlParserToken> tokens,
    int startIndex,
    int endIndex)
{
    if (tokens == null ||
        startIndex < 0 ||
        endIndex < startIndex)
    {
        return false;
    }

    if (endIndex >= tokens.Count)
    {
        endIndex =
            tokens.Count - 1;
    }

    for (int i = startIndex;
         i <= endIndex;
         i++)
    {
        TSqlParserToken token =
            tokens[i];

        if (token != null &&
            token.TokenType ==
                TSqlTokenType.WhiteSpace &&
            ContainsNewLine(
                token.Text))
        {
            return true;
        }
    }

    return false;
}
