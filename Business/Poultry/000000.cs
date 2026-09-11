private static bool ContainsBooleanBinaryExpression(
    BooleanExpression expression)
{
    if (expression == null)
    {
        return false;
    }

    if (expression is BooleanBinaryExpression)
    {
        return true;
    }

    BooleanParenthesisExpression parenthesis =
        expression as BooleanParenthesisExpression;

    if (parenthesis != null)
    {
        return ContainsBooleanBinaryExpression(
            parenthesis.Expression);
    }

    return false;
}
