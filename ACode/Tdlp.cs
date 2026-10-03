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

    int baseIndent =
        StatementIndentResolver.GetStatementIndent(
            context.Parent,
            layoutContext);

    /*
     * First item:
     *
     * CREATE TABLE #CUSTOMER
     * (
     *     ID INT,
     */
    if (position == 0)
    {
        int openIndex =
            layoutContext.TokenNavigator
                .FindMeaningfulTokenByTextBetween(
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
    }

    /*
     * Every column / constraint / index starts
     * on its own line.
     *
     * IMPORTANT:
     * Do NOT add the instruction to the comma.
     * The comma must remain attached to the
     * previous item.
     */
    layoutContext.AddInstruction(
        context.Node.FirstTokenIndex,
        baseIndent + 1,
        "TableDefinitionLayoutPolicy",
        context);

    /*
     * Last item:
     * closing parenthesis returns to base indent.
     */
    if (position == items.Count - 1)
    {
        int closeIndex =
            layoutContext.TokenNavigator
                .FindMeaningfulTokenByTextBetween(
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
