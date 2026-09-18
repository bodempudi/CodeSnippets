/*
 * CASE WHEN rule:
 *
 * Keep AND / OR on the same line inside a searched CASE WHEN.
 *
 * Example:
 *
 * CASE
 *     WHEN @A = 1 AND @B = 2 OR @C = 3 THEN 'YES'
 *     ELSE 'NO'
 * END
 *
 * Normal WHERE / JOIN / IF / HAVING Boolean formatting
 * must remain unchanged.
 */
if (IsInsideSearchedWhenClause(
        booleanNode,
        layoutContext))
{
    layoutContext.AddSpaceInstruction(
        operatorTokenIndex,
        "BooleanLayoutPolicy",
        context);

    return;
}

int operatorIndent =
    GetBooleanIndent(
        booleanNode,
        layoutContext);

layoutContext.AddInstruction(
    operatorTokenIndex,
    operatorIndent,
    "BooleanLayoutPolicy",
    context);
