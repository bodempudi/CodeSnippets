private static bool ApplyInlineTableValuedFunctionReturn(
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
        return false;
    }

    string typeName =
        context.Node.GetType().Name;

    if (typeName.IndexOf(
            "Function",
            StringComparison.OrdinalIgnoreCase) < 0)
    {
        return false;
    }

    int returnsIndex = -1;
    int tableIndex = -1;

    /*
     * Inline TVF must contain:
     *
     * RETURNS TABLE
     *
     * before AS.
     */
    for (int i = context.Node.FirstTokenIndex;
         i < asIndex &&
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
            string.Equals(
                text,
                "TABLE",
                StringComparison.OrdinalIgnoreCase))
        {
            tableIndex = i;
            break;
        }
    }

    if (returnsIndex < 0 ||
        tableIndex < 0)
    {
        return false;
    }

    /*
     * For an inline TVF, RETURN must be the first
     * meaningful token after AS.
     */
    int returnIndex = -1;

    for (int i = asIndex + 1;
         i <= context.Node.LastTokenIndex &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token.TokenType ==
            TSqlTokenType.WhiteSpace)
        {
            continue;
        }

        if (!string.Equals(
                token.Text,
                "RETURN",
                StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        returnIndex = i;
        break;
    }

    if (returnIndex < 0)
    {
        return false;
    }

    /*
     * Inline TVF shape:
     *
     * RETURN
     * (
     *     SELECT ...
     * )
     */
    int openParenthesisIndex = -1;

    for (int i = returnIndex + 1;
         i <= context.Node.LastTokenIndex &&
         i < layoutContext.Tokens.Count;
         i++)
    {
        TSqlParserToken token =
            layoutContext.Tokens[i];

        if (token.TokenType ==
            TSqlTokenType.WhiteSpace)
        {
            continue;
        }

        if (token.Text != "(")
        {
            return false;
        }

        openParenthesisIndex = i;
        break;
    }

    if (openParenthesisIndex < 0)
    {
        return false;
    }

    /*
     * RETURN starts on its own line.
     */
    layoutContext.AddInstruction(
        returnIndex,
        baseIndent,
        "DefinitionLayoutPolicy",
        context);

    /*
     * Opening parenthesis also starts on its own line
     * and aligns with RETURN.
     */
    layoutContext.AddInstruction(
        openParenthesisIndex,
        baseIndent,
        "DefinitionLayoutPolicy",
        context);

    return true;
}
