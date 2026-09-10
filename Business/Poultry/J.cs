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

            /*
             * Do not resolve JOIN indentation from the current child node.
             *
             * Multiple JOINs are represented by ScriptDom as nested
             * QualifiedJoin nodes.
             *
             * All JOINs belonging to the same query must therefore use
             * the SAME owning QuerySpecification base indentation.
             */
            int queryBaseIndent =
                GetJoinQueryBaseIndent(
                    context,
                    layoutContext);

            /*
             * ==========================================================
             * JOIN
             * ==========================================================
             *
             * FROM ...
             *     INNER JOIN ...
             *         ON ...
             *     LEFT JOIN ...
             *         ON ...
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
         * JOIN QUERY BASE
         * ==============================================================
         *
         * ScriptDom represents:
         *
         *     A
         *     JOIN B
         *     JOIN C
         *     JOIN D
         *
         * as nested QualifiedJoin objects.
         *
         * Do not allow the nesting of QualifiedJoin nodes to increase
         * or change indentation.
         *
         * Every JOIN in one query resolves back to the same
         * QuerySpecification.
         * ==============================================================
         */
        private static int GetJoinQueryBaseIndent(
            AstNodeContext context,
            LayoutContext layoutContext)
        {
            if (context == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return 0;
            }

            TSqlFragment current =
                context.Parent != null
                    ? context.Parent
                    : context.Node;

            while (current != null)
            {
                QuerySpecification query =
                    current as QuerySpecification;

                if (query != null)
                {
                    return
                        QueryIndentResolver
                            .GetQueryBaseIndent(
                                query,
                                layoutContext);
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            /*
             * Fallback only.
             */
            return
                QueryIndentResolver
                    .GetQueryBaseIndent(
                        context.Node,
                        layoutContext);
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
             * Inner SELECT
             */
            int selectIndex = -1;

            int searchEnd =
                closeParenthesisIndex >= 0
                    ? closeParenthesisIndex
                    : derivedTable.LastTokenIndex;

            for (int i = openParenthesisIndex + 1;
                 i <= searchEnd &&
                 i < layoutContext.Tokens.Count;
                 i++)
            {
                if (layoutContext.Tokens[i].TokenType ==
                    TSqlTokenType.Select)
                {
                    selectIndex = i;
                    break;
                }
            }

            if (selectIndex >= 0)
            {
                layoutContext.AddInstruction(
                    selectIndex,
                    indent + 1,
                    "JoinLayoutPolicy",
                    context);
            }

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
                if (layoutContext.Tokens[i].Text == "(")
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
