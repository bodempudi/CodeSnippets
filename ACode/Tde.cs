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

    int baseIndent =
        StatementIndentResolver.GetStatementIndent(
            tableDefinition,
            layoutContext);

    /*
     * Every table-definition item starts on its own line.
     */
    layoutContext.AddInstruction(
        context.Node.FirstTokenIndex,
        baseIndent + 1,
        "TableDefinitionLayoutPolicy",
        context);
}
