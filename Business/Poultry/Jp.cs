using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting.Policies
{
    public sealed class JoinLayoutPolicy : ILayoutPolicy
    {
        public void Apply(
            AstNodeContext context,
            LayoutContext layoutContext)
        {
            if (context == null ||
                context.Node == null ||
                layoutContext == null)
            {
                return;
            }

            int queryBaseIndent =
                QueryIndentResolver.GetQueryBaseIndent(
                    context.Node,
                    layoutContext);

            /*
             * ==========================================================
             * JOIN
             * ==========================================================
             *
             * FROM ...
             *     INNER JOIN ...
             */
            if (context.Relationship == "SecondTableReference" &&
                context.Parent != null &&
                context.Parent.GetType().Name == "QualifiedJoin")
            {
                int joinStart =
                    layoutContext.TokenNavigator.FindJoinStart(
                        context.Parent,
                        context.Node);

                if (joinStart >= 0)
                {
                    layoutContext.AddInstruction(
                        joinStart,
                        queryBaseIndent + 1,
                        "JoinLayoutPolicy",
                        context);
                }

                /*
                 * ======================================================
                 * JOIN DERIVED TABLE
                 * ======================================================
                 *
                 * FROM dbo.TableA a
                 *     INNER JOIN
                 *     (
                 *         SELECT
                 *             b.Id
                 *         FROM dbo.TableB b
                 *     ) b
                 *         ON ...
                 *
                 * JOIN = base + 1
                 * (    = base + 1
                 * SELECT query base = base + 2
                 * )    = base + 1
                 */
                QueryDerivedTable derivedTable =
                    context.Node as QueryDerivedTable;

                if (derivedTable != null)
                {
                    ApplyDerivedTableParentheses(
                        derivedTable,
                        queryBaseIndent + 1,
                        context,
                        layoutContext);
                }
            }

            /*
             * ==========================================================
             * ON
             * ==========================================================
             *
             *     INNER JOIN ...
             *         ON ...
             */
            if (context.Relationship == "SearchCondition" &&
                context.Parent != null &&
                context.Parent.GetType().Name == "QualifiedJoin")
            {
                int onIndex =
                    layoutContext.TokenNavigator.FindTokenBetween(
                        context.Parent.FirstTokenIndex,
                        context.Node.FirstTokenIndex,
                        TSqlTokenType.On);

                if (onIndex >= 0)
                {
                    layoutContext.AddInstruction(
                        onIndex,
                        queryBaseIndent + 2,
                        "JoinLayoutPolicy",
                        context);
                }
            }
        }

        /*
         * ==============================================================
         * DERIVED TABLE PARENTHESES
         * ==============================================================
         */
        private static void ApplyDerivedTableParentheses(
            QueryDerivedTable derivedTable,
            int indent,
            AstNodeContext context,
            LayoutContext layoutContext)
        {
            if (derivedTable == null ||
                layoutContext == null ||
                layoutContext.Tokens == null)
            {
                return;
            }

            int openParenthesisIndex =
                FindOpeningParenthesis(
                    derivedTable,
                    layoutContext);

            if (openParenthesisIndex < 0)
            {
                return;
            }

            int closeParenthesisIndex =
                FindMatchingClosingParenthesis(
                    openParenthesisIndex,
                    derivedTable.LastTokenIndex,
                    layoutContext);

            /*
             * Opening (
             */
            layoutContext.AddInstruction(
                openParenthesisIndex,
                indent,
                "JoinLayoutPolicy",
                context);

            /*
             * Closing )
             */
            if (closeParenthesisIndex >= 0)
            {
                layoutContext.AddInstruction(
                    closeParenthesisIndex,
                    indent,
                    "JoinLayoutPolicy",
                    context);
            }
        }

        /*
         * ==============================================================
         * FIND OPENING PARENTHESIS
         * ==============================================================
         */
        private static int FindOpeningParenthesis(
            QueryDerivedTable derivedTable,
            LayoutContext layoutContext)
        {
            int start =
                derivedTable.FirstTokenIndex;

            int end =
                derivedTable.LastTokenIndex;

            if (start < 0)
            {
                start = 0;
            }

            if (end >= layoutContext.Tokens.Count)
            {
                end =
                    layoutContext.Tokens.Count - 1;
            }

            for (int i = start;
                 i <= end;
                 i++)
            {
                string tokenText =
                    layoutContext.Tokens[i].Text;

                if (tokenText == "(")
                {
                    return i;
                }
            }

            return -1;
        }

        /*
         * ==============================================================
         * FIND MATCHING CLOSING PARENTHESIS
         * ==============================================================
         *
         * We cannot simply use QueryDerivedTable.LastTokenIndex because
         * the alias can also belong to the QueryDerivedTable:
         *
         *     (
         *         SELECT ...
         *     ) b
         *
         * So find the ')' matching the first '('.
         * ==============================================================
         */
        private static int FindMatchingClosingParenthesis(
            int openParenthesisIndex,
            int endIndex,
            LayoutContext layoutContext)
        {
            if (openParenthesisIndex < 0 ||
                layoutContext == null ||
                layoutContext.Tokens == null)
            {
                return -1;
            }

            if (endIndex >= layoutContext.Tokens.Count)
            {
                endIndex =
                    layoutContext.Tokens.Count - 1;
            }

            int depth = 0;

            for (int i = openParenthesisIndex;
                 i <= endIndex;
                 i++)
            {
                string tokenText =
                    layoutContext.Tokens[i].Text;

                if (tokenText == "(")
                {
                    depth++;
                    continue;
                }

                if (tokenText == ")")
                {
                    depth--;

                    if (depth == 0)
                    {
                        return i;
                    }
                }
            }

            return -1;
        }
    }
}
