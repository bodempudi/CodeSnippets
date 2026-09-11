private static int GetJoinQueryBaseIndent(
    TSqlFragment fragment,
    LayoutContext layoutContext)
{
    if (fragment == null ||
        layoutContext == null ||
        layoutContext.Walker == null)
    {
        return 0;
    }

    TSqlFragment current =
        fragment;

    while (current != null)
    {
        QuerySpecification querySpecification =
            current as QuerySpecification;

        if (querySpecification != null)
        {
            return
                QueryIndentResolver.GetQueryBaseIndent(
                    querySpecification,
                    layoutContext);
        }

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    return
        QueryIndentResolver.GetQueryBaseIndent(
            fragment,
            layoutContext);
}
