private static bool ShouldBeTight(
    TSqlParserToken previous,
    TSqlParserToken current)
{
    if (previous == null ||
        current == null)
    {
        return false;
    }

    string previousText =
        previous.Text ?? string.Empty;

    string currentText =
        current.Text ?? string.Empty;

    /*
     * No space before punctuation.
     *
     *     dbo.Customer
     *     ISNULL(@A, 0)
     *     (@A = 1)
     */
    if (currentText == "." ||
        currentText == "," ||
        currentText == ")" ||
        currentText == ";")
    {
        return true;
    }

    /*
     * No space after dot or opening parenthesis.
     */
    if (previousText == "." ||
        previousText == "(")
    {
        return true;
    }

    /*
     * Function call:
     *
     *     ISNULL(
     *     LEN(
     *     dbo.Function(
     *
     * Boolean keywords keep their normal space:
     *
     *     IN (
     *     EXISTS (
     *     NOT (
     */
    if (currentText == "(")
    {
        if (string.Equals(
                previousText,
                "IN",
                StringComparison.OrdinalIgnoreCase) ||
            string.Equals(
                previousText,
                "EXISTS",
                StringComparison.OrdinalIgnoreCase) ||
            string.Equals(
                previousText,
                "NOT",
                StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return true;
    }

    return false;
}
