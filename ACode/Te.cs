public void Apply(
    AstNodeContext context,
    LayoutContext layoutContext)
{
    if (context == null ||
        context.Node == null ||
        context.Parent == null ||
        layoutContext == null)
    {
        return;
    }

    TableDefinition tableDefinition =
        context.Parent as TableDefinition;

    if (tableDefinition == null)
    {
        return;
    }

    bool isColumn =
        context.Node is ColumnDefinition &&
        tableDefinition.ColumnDefinitions.Contains(
            (ColumnDefinition)context.Node);

    bool isConstraint =
        context.Node is ConstraintDefinition &&
        tableDefinition.TableConstraints.Contains(
            (ConstraintDefinition)context.Node);

    bool isIndex =
        context.Node is IndexDefinition &&
        tableDefinition.Indexes.Contains(
            (IndexDefinition)context.Node);

    if (!isColumn &&
        !isConstraint &&
        !isIndex)
    {
        return;
    }

    IList<AstNodeContext> items =
        layoutContext.Walker.GetChildren(
            context.Parent)
        .Where(
            x => x != null &&
                 x.Node != null &&
                 (
                     x.Node is ColumnDefinition ||
                     x.Node is ConstraintDefinition ||
                     x.Node is IndexDefinition
                 ))
        .OrderBy(
            x => x.Node.FirstTokenIndex)
        .ToList();

    int position = -1;

    for (int i = 0; i < items.Count; i++)
    {
        if (ReferenceEquals(
                items[i].Node,
                context.Node))
        {
            position = i;
            break;
        }
    }

    if (position < 0)
    {
        return;
    }

    /*
     * Comma before every item except the first.
     */
    if (position > 0)
    {
        int commaIndex =
            layoutContext.TokenNavigator.FindPreviousToken(
                context.Node.FirstTokenIndex,
                TSqlTokenType.Comma);

        if (commaIndex >= 0)
        {
            layoutContext.AddInstruction(
                commaIndex,
                StatementIndentResolver.GetStatementIndent(
                    context.Parent,
                    layoutContext) + 1,
                "TableDefinitionLayoutPolicy",
                context);
        }
    }

    int baseIndent =
        StatementIndentResolver.GetStatementIndent(
            context.Parent,
            layoutContext);

    /*
     * First item:
     * opening parenthesis = base
     * item = base + 1
     */
    if (position == 0)
    {
        int openIndex =
            layoutContext.TokenNavigator.FindMeaningfulTokenByTextBetween(
                context.Parent.FirstTokenIndex,
                context.Node.FirstTokenIndex,
                "(");

        if (openIndex >= 0)
        {
            layoutContext.AddInstruction(
                openIndex,
                baseIndent,
                "TableDefinitionLayoutPolicy",
                context);
        }

        layoutContext.AddInstruction(
            context.Node.FirstTokenIndex,
            baseIndent + 1,
            "TableDefinitionLayoutPolicy",
            context);
    }
    else
    {
        layoutContext.AddInstruction(
            context.Node.FirstTokenIndex,
            baseIndent + 1,
            "TableDefinitionLayoutPolicy",
            context);
    }

    /*
     * Last item:
     * closing parenthesis = base
     */
    if (position == items.Count - 1)
    {
        int closeIndex =
            layoutContext.TokenNavigator.FindMeaningfulTokenByTextBetween(
                context.Node.LastTokenIndex + 1,
                context.Parent.LastTokenIndex,
                ")");

        if (closeIndex >= 0)
        {
            layoutContext.AddInstruction(
                closeIndex,
                baseIndent,
                "TableDefinitionLayoutPolicy",
                context);
        }
    }
}
