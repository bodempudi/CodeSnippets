private static void ApplyInlineTableValuedFunctionReturn(
    AstNodeContext context,
    LayoutContext layoutContext,
    int asIndex,
    int baseIndent)
{
    if (context == null ||
        context.Node == null ||
        layoutContext == null ||
        layoutContext.Tokens == null ||
        asIndex < 0)
    {
        return;
    }

    string typeName =
        context.Node.GetType().Name;

    if (typeName.IndexOf(
            "Function",
            StringComparison.OrdinalIgnoreCase) < 0)
    {
        return;
    }

    int returnsIndex = -1;
    int tableIndex = -1;
    int returnIndex = -1;

    for (int i = context.Node.FirstTokenIndex;
         i <= context.Node.LastTokenIndex &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        string text =
            layoutContext.Tokens[i].Text;

        if (returnsIndex < 0 &&
            string.Equals(
                text,
                "RETURNS",
                StringComparison.OrdinalIgnoreCase))
        {
            returnsIndex = i;
            continue;
        }

        if (returnsIndex >= 0 &&
            tableIndex < 0 &&
            string.Equals(
                text,
                "TABLE",
                StringComparison.OrdinalIgnoreCase))
        {
            tableIndex = i;
            continue;
        }

        if (i > asIndex &&
            tableIndex >= 0 &&
            string.Equals(
                text,
                "RETURN",
                StringComparison.OrdinalIgnoreCase))
        {
            returnIndex = i;
            break;
        }
    }

    if (returnsIndex < 0 ||
        tableIndex < 0 ||
        returnIndex < 0)
    {
        return;
    }

    layoutContext.AddInstruction(
        returnIndex,
        baseIndent,
        "DefinitionLayoutPolicy",
        context);
}
