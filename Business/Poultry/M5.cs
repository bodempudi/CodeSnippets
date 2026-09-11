private static int FindJoinStart(
    QualifiedJoin qualifiedJoin,
    LayoutContext layoutContext)
{
    if (qualifiedJoin == null ||
        qualifiedJoin.SecondTableReference == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return -1;
    }

    int secondTableStart =
        qualifiedJoin.SecondTableReference.FirstTokenIndex;

    if (secondTableStart < 0)
    {
        return -1;
    }

    /*
     * Search backwards from the second table.
     *
     * The JOIN keyword immediately preceding SecondTableReference
     * belongs to this QualifiedJoin.
     *
     * For:
     *
     *     INNER JOIN TableB
     *
     * we first find JOIN and then continue backwards to INNER.
     *
     * For:
     *
     *     JOIN TableB
     *
     * JOIN itself is the start.
     */
    int joinIndex = -1;

    for (int i = secondTableStart - 1;
         i >= qualifiedJoin.FirstTokenIndex &&
         i >= 0;
         i--)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token.TokenType == TSqlTokenType.Join)
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
     * Check for JOIN modifiers immediately before JOIN.
     *
     * INNER JOIN
     * LEFT JOIN
     * RIGHT JOIN
     * FULL JOIN
     */
    for (int i = joinIndex - 1;
         i >= qualifiedJoin.FirstTokenIndex &&
         i >= 0;
         i--)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token.TokenType == TSqlTokenType.WhiteSpace)
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
