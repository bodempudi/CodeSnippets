using System;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting
{
    public static class TokenSpacingResolver
    {
        public static bool ShouldBeTight(
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
             * No space after these.
             */
            if (previousText == "." ||
                previousText == "(")
            {
                return true;
            }

            /*
             * Compound comparison operators.
             *
             *     <=
             *     >=
             *     <>
             *     !=
             *     !<
             *     !>
             */
            bool compoundComparisonOperator =
                (previousText == "<" &&
                    (currentText == "=" ||
                     currentText == ">")) ||
                (previousText == ">" &&
                    currentText == "=") ||
                (previousText == "!" &&
                    (currentText == "=" ||
                     currentText == "<" ||
                     currentText == ">"));

            if (compoundComparisonOperator)
            {
                return true;
            }

            /*
             * Opening parenthesis.
             *
             * Keep Boolean keywords spaced:
             *
             *     IN (
             *     EXISTS (
             *     NOT (
             *
             * Everything else is treated as a function /
             * expression call and remains tight:
             *
             *     ISNULL(
             *     LEN(
             *     dbo.Function(
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
    }
}
