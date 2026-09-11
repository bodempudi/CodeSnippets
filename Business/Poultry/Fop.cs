private static int FindOpeningParenthesis(
    QueryDerivedTable derivedTable,
    LayoutContext layoutContext)
{
    if (derivedTable == null ||
        layoutContext == null ||
        layoutContext.Tokens == null ||
        layoutContext.Tokens.Count == 0)
    {
        return -1;
    }

    int start =
        derivedTable.FirstTokenIndex;

    int end =
        derivedTable.LastTokenIndex;

    if (start < 0)
    {
        start = 0;
    }

    if (end >= layoutContext.Tokens.Count)
    {
        end =
            layoutContext.Tokens.Count - 1;
    }

    for (int i = start;
         i <= end;
         i++)
    {
        if (layoutContext.Tokens[i].Text == "(")
        {
            return i;
        }
    }

    return -1;
}

private static int FindMatchingClosingParenthesis(
    int openParenthesisIndex,
    int endIndex,
    LayoutContext layoutContext)
{
    if (layoutContext == null ||
        layoutContext.Tokens == null ||
        openParenthesisIndex < 0)
    {
        return -1;
    }

    if (endIndex >= layoutContext.Tokens.Count)
    {
        endIndex =
            layoutContext.Tokens.Count - 1;
    }

    int depth = 0;

    for (int i = openParenthesisIndex;
         i <= endIndex;
         i++)
    {
        string text =
            layoutContext.Tokens[i].Text;

        if (text == "(")
        {
            depth++;
        }
        else if (text == ")")
        {
            depth--;

            if (depth == 0)
            {
                return i;
            }
        }
    }

    return -1;
}
