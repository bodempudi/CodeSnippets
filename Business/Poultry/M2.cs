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

    TSqlFragment current = fragment;

    while (current != null)
    {
        QuerySpecification querySpecification =
            current as QuerySpecification;

        if (querySpecification != null)
        {
            /*
             * JOIN indentation belongs to the query containing
             * the FROM clause.
             *
             * Resolve the base from the QuerySpecification's
             * FromClause instead of from a nested QualifiedJoin.
             *
             * This guarantees that:
             *
             *     JOIN 1
             *     JOIN 2
             *     JOIN 3
             *
             * all receive exactly the same base indentation.
             */
            if (querySpecification.FromClause != null)
            {
                return
                    QueryIndentResolver.GetQueryBaseIndent(
                        querySpecification.FromClause,
                        layoutContext);
            }

            return
                QueryIndentResolver.GetQueryBaseIndent(
                    querySpecification,
                    layoutContext);
        }

        current =
            layoutContext.Walker.GetParent(
                current);
    }

    return 0;
}
