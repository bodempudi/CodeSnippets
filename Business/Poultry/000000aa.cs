private static void ApplyInlineSimplePredicate(
    BooleanExpression predicate,
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (predicate == null ||
        context == null ||
        layoutContext == null ||
        layoutContext.Tokens == null)
    {
        return;
    }

    /*
     * Multiple Boolean conditions such as AND / OR
     * continue to use the existing multiline formatting.
     */
    if (ContainsBooleanBinaryExpression(
            predicate))
    {
        return;
    }

    /*
     * Do not inline predicates that contain SELECT.
     *
     * Example:
     *
     * IF EXISTS
     * (
     *     SELECT ...
     * )
     */
    if (ContainsTokenType(
            predicate,
            TSqlTokenType.Select,
            layoutContext))
    {
        return;
    }

    /*
     * Never collapse across developer comments.
     */
    if (ContainsComment(
            predicate,
            layoutContext))
    {
        return;
    }

    int previousMeaningfulIndex = -1;

    for (int i = predicate.FirstTokenIndex;
         i <= predicate.LastTokenIndex &&
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
         * First predicate token:
         *
         * IF @A = 1
         * IF (@A = 1)
         *
         * Keep one space after IF / WHILE.
         */
        if (previousMeaningfulIndex < 0)
        {
            layoutContext.AddSpaceInstruction(
                i,
                "ControlFlowLayoutPolicy",
                context);

            previousMeaningfulIndex = i;

            continue;
        }

        TSqlParserToken previousToken =
            layoutContext.Tokens[
                previousMeaningfulIndex];

        if (ShouldBeTight(
                previousToken,
                token))
        {
            layoutContext.AddTightInstruction(
                i,
                "ControlFlowLayoutPolicy",
                context);
        }
        else
        {
            layoutContext.AddSpaceInstruction(
                i,
                "ControlFlowLayoutPolicy",
                context);
        }

        previousMeaningfulIndex = i;
    }
}
