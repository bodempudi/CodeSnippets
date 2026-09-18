private static bool IsInsideSearchedWhenClause(
    TSqlFragment node,
    LayoutContext layoutContext)
{
    if (node == null ||
        layoutContext == null ||
        layoutContext.Walker == null)
    {
        return false;
    }

    TSqlFragment current = node;

    while (current != null)
    {
        if (current is SearchedWhenClause)
        {
            return true;
        }

        /*
         * Do not escape into an outer query while looking
         * for CASE ownership.
         */
        if (current is QuerySpecification)
        {
            return false;
        }

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    return false;
}
