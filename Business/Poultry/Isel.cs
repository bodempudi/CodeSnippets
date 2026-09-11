SelectInsertSource selectSource =
    context.Node as SelectInsertSource;

if (selectSource != null)
{
    ApplySelectSource(
        selectSource,
        context,
        layoutContext);

    return;
}
