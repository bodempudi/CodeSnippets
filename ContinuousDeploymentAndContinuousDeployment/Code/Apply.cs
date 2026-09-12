public void Apply(
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (!EnableSectionSeparators)
    {
        return;
    }

    if (context == null ||
        context.Node == null ||
        context.Parent == null ||
        layoutContext == null)
    {
        return;
    }

    /*
     * Only direct children of a StatementList participate
     * in logical section separation.
     *
     * JOIN, WHERE, CASE, CTE, subqueries, expressions, etc.
     * do not create separators here.
     */
    if (!(context.Parent is StatementList) ||
        !TokenNavigator.IsIndexedRelationship(
            context.Relationship,
            "Statements"))
    {
        return;
    }

    int statementIndex =
        TokenNavigator.GetRelationshipIndex(
            context.Relationship);

    if (statementIndex < 0)
    {
        return;
    }

    IList<AstNodeContext> statements =
        GetStatements(
            context.Parent,
            layoutContext);

    if (statements.Count == 0 ||
        statementIndex >= statements.Count)
    {
        return;
    }

    /*
     * Determine whether the current statement starts
     * a new logical group.
     *
     * Only consecutive DECLARE statements and consecutive
     * SET statements are allowed to share a group.
     */
    bool startsGroup =
        IsGroupStart(
            statements,
            statementIndex);

    if (!startsGroup ||
        statementIndex == 0)
    {
        return;
    }

    int groupCount =
        CountGroups(
            statements);

    bool isNestedStatementList =
        IsNestedStatementList(
            context.Parent,
            layoutContext);

    /*
     * Container rule:
     *
     * A nested StatementList containing only one logical
     * group does not receive internal separators.
     *
     * Example:
     *
     * WHILE ...
     * BEGIN
     *     SET @A = @A + 1;
     * END
     */
    if (isNestedStatementList &&
        groupCount <= 1)
    {
        return;
    }

    int indent =
        StatementIndentResolver
            .GetStatementIndent(
                context.Node,
                layoutContext);

    /*
     * Normally the separator is placed before the first
     * token of the current statement.
     *
     * However, a standalone semicolon may exist between
     * the previous statement and the current statement.
     *
     * Example:
     *
     * SELECT ...;
     *
     * ;WITH ...
     *
     * In that case the semicolon belongs to the CURRENT
     * statement boundary, so the separator must be placed
     * before the semicolon:
     *
     * --------------------------------
     * ;WITH ...
     *
     * and never:
     *
     * ;
     * --------------------------------
     * WITH ...
     *
     * This is token/statement based. It is not tied to
     * SELECT, WITH, INSERT, UPDATE, DELETE or MERGE.
     */
    int groupStartTokenIndex =
        context.Node.FirstTokenIndex;

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

    /*
     * Every logical group receives a separator before it.
     *
     * This naturally creates:
     *
     *     opening boundary
     *     group 1
     *
     *     boundary
     *     group 2
     *
     *     boundary
     *     group 3
     */
    layoutContext.AddSectionSeparatorInstruction(
        groupStartTokenIndex,
        indent,
        "StatementSpacingPolicy.GroupStart",
        context);

    /*
     * Nested containers containing 2+ logical groups also
     * receive a closing boundary.
     *
     * Only the LAST group owns this instruction.
     */
    if (isNestedStatementList &&
        IsLastGroup(
            statements,
            statementIndex))
    {
        int nextToken =
            layoutContext.TokenNavigator
                .FindNextMeaningfulToken(
                    context.Node.LastTokenIndex + 1,
                    layoutContext.Tokens.Count - 1);

        if (nextToken >= 0)
        {
            layoutContext.AddSectionSeparatorInstruction(
                nextToken,
                Math.Max(0, indent - 1),
                "StatementSpacingPolicy.ContainerEnd",
                context);
        }
    }
}
