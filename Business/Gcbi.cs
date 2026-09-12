public static int GetControlBodyIndent(
    TSqlFragment controlStatement,
    TSqlFragment bodyStatement,
    LayoutContext layoutContext)
{
    if (controlStatement == null ||
        bodyStatement == null ||
        layoutContext == null)
    {
        return 0;
    }

    int controlIndent =
        GetStatementIndent(
            controlStatement,
            layoutContext);

    /*
     * BEGIN / END belongs to the control statement itself.
     *
     * IF ...
     * BEGIN
     *     ...
     * END
     *
     * WHILE ...
     * BEGIN
     *     ...
     * END
     */
    if (bodyStatement is BeginEndBlockStatement)
    {
        return controlIndent;
    }

    /*
     * Single-statement body:
     *
     * IF ...
     *     SET ...
     *
     * WHILE ...
     *     SET ...
     */
    return controlIndent + 1;
}
