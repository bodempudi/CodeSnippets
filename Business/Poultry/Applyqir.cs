QueryDerivedTable derivedTable =
    context.Node as QueryDerivedTable;

if (derivedTable != null)
{
    if (context.Parent is QualifiedJoin &&
        context.Relationship ==
            "SecondTableReference")
    {
        return;
    }

    ApplyFromDerivedTable(
        derivedTable,
        context,
        layoutContext);

    return;
}
