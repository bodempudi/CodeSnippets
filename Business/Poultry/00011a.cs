private static void ApplyTrailingCommaItem(
    AstNodeContext context,
    LayoutContext layoutContext,
    int indent,
    string policyName)
{
    int index =
        TokenNavigator.GetRelationshipIndex(
            context.Relationship);

    /*
     * First item has no separating comma.
     */
    if (index <= 0)
    {
        layoutContext.AddInstruction(
            context.Node.FirstTokenIndex,
            indent,
            policyName,
            context);

        return;
    }

    int commaIndex =
        layoutContext.TokenNavigator.FindPreviousToken(
            context.Node.FirstTokenIndex,
            TSqlTokenType.Comma);

    if (commaIndex < 0)
    {
        return;
    }

    AstNodeContext previousItem = null;

    foreach (AstNodeContext sibling in
        layoutContext.Walker.GetChildren(
            context.Parent))
    {
        if (sibling == null ||
            sibling.Node == null)
        {
            continue;
        }

        int siblingIndex =
            TokenNavigator.GetRelationshipIndex(
                sibling.Relationship);

        if (siblingIndex == index - 1)
        {
            previousItem = sibling;
            break;
        }
    }

    /*
     * Preserve developer-owned comma placement.
     *
     * Trailing style:
     *
     *     @A INT,
     *     @B INT
     *
     * Leading style:
     *
     *     @A INT
     *     ,@B INT
     *
     * We only decide where the newline/indent belongs.
     * The comma token itself is never moved from one
     * parameter to another.
     */

    bool newLineBeforeComma =
        previousItem != null &&
        HasNewLineBetween(
            layoutContext,
            previousItem.Node.LastTokenIndex,
            commaIndex);

    bool newLineAfterComma =
        HasNewLineBetween(
            layoutContext,
            commaIndex,
            context.Node.FirstTokenIndex);

    /*
     * Developer used leading-comma style.
     *
     * Put the layout boundary on the comma and keep the
     * parameter attached to that comma.
     */
    if (newLineBeforeComma &&
        !newLineAfterComma)
    {
        layoutContext.AddInstruction(
            commaIndex,
            indent,
            policyName,
            context);

        layoutContext.AddTightInstruction(
            context.Node.FirstTokenIndex,
            policyName,
            context);

        return;
    }

    /*
     * Trailing-comma style, or an ambiguous same-line case.
     *
     * Do not relocate the comma. Only position the
     * current parameter.
     */
    layoutContext.AddInstruction(
        context.Node.FirstTokenIndex,
        indent,
        policyName,
        context);
}
