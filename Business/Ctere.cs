using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting.Resolver
{
    public static class CteVisualStartResolver
    {
        /*
         * Returns the visual start token for a CTE.
         *
         * Examples:
         *
         * SELECT ...;
         * WITH CTE ...
         *
         * Visual start = WITH
         *
         *
         * SELECT ...;
         * ;WITH CTE ...
         *
         * Visual start = ;
         *
         *
         * SELECT ...;
         * ;;;WITH CTE ...
         *
         * Visual start = first extra ;
         *
         *
         * IMPORTANT:
         *
         * previousStatementLastTokenIndex is an ownership boundary.
         * This method NEVER searches at or before that token.
         *
         * Therefore the terminating semicolon of the previous
         * statement can never be claimed by the CTE.
         */
        public static int GetVisualStartTokenIndex(
            LayoutContext layoutContext,
            int withIndex,
            int previousStatementLastTokenIndex)
        {
            if (layoutContext == null ||
                layoutContext.Tokens == null ||
                withIndex < 0 ||
                withIndex >= layoutContext.Tokens.Count)
            {
                return withIndex;
            }

            int immediatePrefixSemicolon =
                FindImmediatePrefixSemicolon(
                    layoutContext,
                    withIndex,
                    previousStatementLastTokenIndex);

            if (immediatePrefixSemicolon < 0)
            {
                return withIndex;
            }

            /*
             * We already proved that an actual prefix semicolon
             * exists immediately before WITH.
             *
             * Now walk backwards only inside the safe area and
             * include any additional source-written semicolons.
             *
             * Example:
             *
             * previous statement ;
             *                    ↑ boundary - never crossed
             *
             *                     ; ; ; WITH
             *                     ↑
             *                     visual start
             */
            int visualStartIndex =
                immediatePrefixSemicolon;

            for (int i = immediatePrefixSemicolon - 1;
                 i > previousStatementLastTokenIndex;
                 i--)
            {
                TSqlParserToken token =
                    layoutContext.Tokens[i];

                if (token == null)
                {
                    continue;
                }

                if (token.TokenType ==
                    TSqlTokenType.WhiteSpace)
                {
                    continue;
                }

                if (token.TokenType ==
                    TSqlTokenType.Semicolon)
                {
                    visualStartIndex = i;
                    continue;
                }

                /*
                 * A comment or any other SQL token is a hard
                 * boundary. Do not move through it.
                 */
                break;
            }

            return visualStartIndex;
        }

        /*
         * Finds only a genuine source-written semicolon prefix
         * immediately before WITH.
         *
         * The search is bounded by the previous statement.
         *
         * Examples:
         *
         * SELECT ...;
         * WITH ...
         *
         * previous statement owns ;
         * Result = -1
         *
         *
         * SELECT ...;
         * ;WITH ...
         *
         * Result = second ;
         *
         *
         * SELECT ...;
         * ;;;WITH ...
         *
         * Result = semicolon immediately before WITH.
         *
         *
         * SELECT ...;
         * ; -- developer comment
         * WITH ...
         *
         * Result = -1 because the comment breaks the relationship.
         */
        public static int FindImmediatePrefixSemicolon(
            LayoutContext layoutContext,
            int withIndex,
            int previousStatementLastTokenIndex)
        {
            if (layoutContext == null ||
                layoutContext.Tokens == null ||
                withIndex <= 0 ||
                withIndex >= layoutContext.Tokens.Count)
            {
                return -1;
            }

            for (int i = withIndex - 1;
                 i > previousStatementLastTokenIndex;
                 i--)
            {
                TSqlParserToken token =
                    layoutContext.Tokens[i];

                if (token == null)
                {
                    continue;
                }

                if (token.TokenType ==
                    TSqlTokenType.WhiteSpace)
                {
                    continue;
                }

                /*
                 * The first non-whitespace token must be a
                 * semicolon. Otherwise WITH has no source-written
                 * semicolon prefix in the current statement area.
                 *
                 * Comments naturally fail here and therefore act
                 * as hard boundaries.
                 */
                if (token.TokenType ==
                    TSqlTokenType.Semicolon)
                {
                    return i;
                }

                return -1;
            }

            return -1;
        }
    }
}
