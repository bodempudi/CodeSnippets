private static int FindJoinStart(
    QualifiedJoin qualifiedJoin,
    LayoutContext layoutContext)
{
    if (qualifiedJoin == null ||
        qualifiedJoin.FirstTableReference == null ||
        qualifiedJoin.SecondTableReference == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return -1;
    }

    int start =
        qualifiedJoin.FirstTableReference.LastTokenIndex + 1;

    int end =
        qualifiedJoin.SecondTableReference.FirstTokenIndex - 1;

    if (start < 0)
    {
        start = 0;
    }

    if (end >= layoutContext.Tokens.Count)
    {
        end =
            layoutContext.Tokens.Count - 1;
    }

    if (start > end)
    {
        return -1;
    }

    int joinIndex = -1;

    /*
     * Find JOIN only inside the exact structural gap between
     * FirstTableReference and SecondTableReference.
     */
    for (int i = start;
         i <= end;
         i++)
    {
        if (layoutContext.Tokens[i].TokenType ==
            TSqlTokenType.Join)
        {
            joinIndex = i;
            break;
        }
    }

    if (joinIndex < 0)
    {
        return -1;
    }

    /*
     * Find an optional JOIN modifier immediately before JOIN.
     *
     * INNER JOIN
     * LEFT JOIN
     * RIGHT JOIN
     * FULL JOIN
     *
     * If no modifier exists, JOIN itself is the start.
     */
    for (int i = joinIndex - 1;
         i >= start;
         i--)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token.TokenType ==
            TSqlTokenType.WhiteSpace)
        {
            continue;
        }

        if (token.TokenType == TSqlTokenType.Inner ||
            token.TokenType == TSqlTokenType.Left ||
            token.TokenType == TSqlTokenType.Right ||
            token.TokenType == TSqlTokenType.Full)
        {
            return i;
        }

        break;
    }

    return joinIndex;
}
