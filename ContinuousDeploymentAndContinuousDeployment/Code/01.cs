int groupStartTokenIndex =
    context.Node.FirstTokenIndex;

/*
 * If a source-written semicolon exists between the previous
 * statement and this statement, it belongs visually with WITH.
 *
 * Put the separator before that semicolon so we keep:
 *
 *     --------------------------------
 *     ;WITH ...
 *
 * and never:
 *
 *     ;
 *     --------------------------------
 *     WITH ...
 */
int previousStatementLastTokenIndex =
    statements[statementIndex - 1]
        .Node
        .LastTokenIndex;

int previousTokenIndex =
    layoutContext.TokenNavigator
        .FindPreviousNonWhitespaceToken(
            context.Node.FirstTokenIndex - 1);

if (previousTokenIndex >
        previousStatementLastTokenIndex &&
    layoutContext.Tokens[previousTokenIndex]
        .TokenType ==
        TSqlTokenType.Semicolon)
{
    groupStartTokenIndex =
        previousTokenIndex;
}

layoutContext.AddSectionSeparatorInstruction(
    groupStartTokenIndex,
    indent,
    "StatementSpacingPolicy.GroupStart",
    context);
