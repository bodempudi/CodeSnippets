private static bool HasNewLineBetween(
    LayoutContext layoutContext,
    int startIndex,
    int endIndex)
{
    if (layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return false;
    }

    int start =
        Math.Max(
            0,
            startIndex + 1);

    int end =
        Math.Min(
            endIndex - 1,
            layoutContext.Tokens.Count - 1);

    for (int i = start;
         i <= end;
         i++)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token == null ||
            string.IsNullOrEmpty(
                token.Text))
        {
            continue;
        }

        if (token.Text.IndexOf('\r') >= 0 ||
            token.Text.IndexOf('\n') >= 0)
        {
            return true;
        }
    }

    return false;
}
