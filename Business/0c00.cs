private static void ApplyBooleanComparison(
    BooleanComparisonExpression comparison,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (comparison == null ||
        context == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return;
    }

    /*
     * Do not normalize across developer comments.
     */
    if (ContainsComment(
            comparison,
            layoutContext))
    {
        return;
    }

    int previousMeaningfulIndex = -1;

    for (int i = comparison.FirstTokenIndex;
         i <= comparison.LastTokenIndex &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token == null ||
            token.TokenType == TSqlTokenType.WhiteSpace ||
            token.TokenType == TSqlTokenType.EndOfFile)
        {
            continue;
        }

        /*
         * Do NOT change the first token.
         *
         * Its newline/indentation is owned by the surrounding
         * Boolean group / AND / OR formatting.
         */
        if (previousMeaningfulIndex < 0)
        {
            previousMeaningfulIndex = i;
            continue;
        }

        TSqlParserToken previousToken =
            layoutContext.Tokens[
                previousMeaningfulIndex];

        string previousText =
            previousToken.Text ??
            string.Empty;

        string currentText =
            token.Text ??
            string.Empty;

        bool tight =
            currentText == "." ||
            currentText == "," ||
            currentText == ")" ||
            currentText == ";" ||
            previousText == "." ||
            previousText == "(";

        if (tight)
        {
            layoutContext.AddTightInstruction(
                i,
                "BooleanLayoutPolicy",
                context);
        }
        else
        {
            layoutContext.AddSpaceInstruction(
                i,
                "BooleanLayoutPolicy",
                context);
        }

        previousMeaningfulIndex = i;
    }
}
