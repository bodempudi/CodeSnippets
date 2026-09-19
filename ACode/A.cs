if (context != null &&
    context.Node != null)
{
    string typeName =
        context.Node.GetType().Name;

    if (typeName == "SetVariableStatement" ||
        (context.Parent != null &&
         context.Parent.GetType().Name ==
            "SetVariableStatement"))
    {
        _layoutContext.Diagnostics.Add(
            "LAYOUT_RULE",
            "DEBUG_SET: " +
            "Node=" + typeName +
            ", Parent=" +
            (context.Parent == null
                ? "NULL"
                : context.Parent.GetType().Name) +
            ", Relationship=" +
            context.Relationship +
            ", FirstTokenIndex=" +
            context.Node.FirstTokenIndex);
    }
}
