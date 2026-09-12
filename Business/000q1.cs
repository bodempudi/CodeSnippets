int previousStatementLastTokenIndex =
    statements[statementIndex - 1]
        .Node
        .LastTokenIndex;

int groupStartTokenIndex =
    CteVisualStartResolver
        .GetVisualStartTokenIndex(
            layoutContext,
            context.Node.FirstTokenIndex,
            previousStatementLastTokenIndex);

layoutContext.AddSectionSeparatorInstruction(
    groupStartTokenIndex,
    indent,
    "StatementSpacingPolicy.GroupStart",
    context);
