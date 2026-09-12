int groupStartTokenIndex =
    context.Node.FirstTokenIndex;

StatementWithCtesAndXmlNamespaces cteStatement =
    context.Node as StatementWithCtesAndXmlNamespaces;

if (cteStatement != null &&
    cteStatement.WithCtesAndXmlNamespaces != null)
{
    int cteStartTokenIndex =
        cteStatement
            .WithCtesAndXmlNamespaces
            .FirstTokenIndex;

    int semicolonIndex =
        layoutContext.TokenNavigator
            .FindPreviousNonWhitespaceToken(
                cteStartTokenIndex - 1);

    if (semicolonIndex >= 0 &&
        layoutContext.Tokens[semicolonIndex]
            .TokenType ==
            TSqlTokenType.Semicolon)
    {
        groupStartTokenIndex =
            semicolonIndex;
    }
}

layoutContext.AddSectionSeparatorInstruction(
    groupStartTokenIndex,
    indent,
    "StatementSpacingPolicy.GroupStart",
    context);
