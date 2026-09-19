private static bool ContainsCaseExpression(
    ScalarExpression expression)
{
    if (expression == null)
    {
        return false;
    }

    if (expression is SimpleCaseExpression ||
        expression is SearchedCaseExpression)
    {
        return true;
    }

    ParenthesisExpression parenthesisExpression =
        expression as ParenthesisExpression;

    if (parenthesisExpression != null)
    {
        return ContainsCaseExpression(
            parenthesisExpression.Expression);
    }

    return false;
}
