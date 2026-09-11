private static void ApplyCteVisualStart(
    SelectStatement selectStatement,
    AstNodeContext context,
    LayoutContext layoutContext,
    int statementIndent)
{
    int withIndex =
        layoutContext.TokenNavigator
            .FindMeaningfulTokenByTextBetween(
                selectStatement.FirstTokenIndex,
                selectStatement
                    .WithCtesAndXmlNamespaces
                    .FirstTokenIndex,
                "WITH");

    if (withIndex < 0)
    {
        withIndex =
            selectStatement.FirstTokenIndex;
    }

    int semicolonIndex =
        layoutContext.TokenNavigator
            .FindPreviousNonWhitespaceToken(
                withIndex - 1);

    if (semicolonIndex < 0 ||
        layoutContext.Tokens[semicolonIndex].TokenType !=
            TSqlTokenType.Semicolon)
    {
        return;
    }

    LayoutInstruction withInstruction =
        layoutContext.Plan
            .GetInstruction(
                withIndex);

    /*
     * The semicolon already exists in the source.
     * We are only transferring the visual statement
     * boundary from WITH to that existing semicolon.
     */
    if (withInstruction != null &&
        withInstruction.Action ==
            LayoutAction.BlankLine)
    {
        layoutContext.AddBlankLineInstruction(
            semicolonIndex,
            withInstruction.IndentLevel,
            "CteLayoutPolicy",
            context);
    }
    else
    {
        int indent =
            withInstruction == null
                ? statementIndent
                : withInstruction.IndentLevel;

        layoutContext.AddInstruction(
            semicolonIndex,
            indent,
            "CteLayoutPolicy",
            context);
    }

    /*
     * Existing source-written ;WITH should stay together.
     */
    layoutContext.AddTightInstruction(
        withIndex,
        "CteLayoutPolicy",
        context);
}
