TSqlFragment p1 =
    layoutContext.Walker.GetParent(query);

TSqlFragment p2 =
    p1 != null
        ? layoutContext.Walker.GetParent(p1)
        : null;

TSqlFragment p3 =
    p2 != null
        ? layoutContext.Walker.GetParent(p2)
        : null;

TSqlFragment p4 =
    p3 != null
        ? layoutContext.Walker.GetParent(p3)
        : null;

layoutContext.Diagnostics.Add(
    "QUERY-AST",
    "Query=" + query.GetType().Name +
    ", P1=" + (p1 == null ? "NULL" : p1.GetType().Name) +
    ", P2=" + (p2 == null ? "NULL" : p2.GetType().Name) +
    ", P3=" + (p3 == null ? "NULL" : p3.GetType().Name) +
    ", P4=" + (p4 == null ? "NULL" : p4.GetType().Name));
