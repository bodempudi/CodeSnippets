bool containsBooleanBinary =
    ContainsBooleanBinaryExpression(
        group.Expression);

bool containsComment =
    ContainsComment(
        group,
        layoutContext);

if (!containsBooleanBinary &&
    !containsComment)
{
    return;
}
