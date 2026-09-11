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
             * ============================================================
             * UNQUALIFIED JOIN
             * ============================================================
             *
             * ScriptDom represents:
             *
             * CROSS JOIN
             * CROSS APPLY
             * OUTER APPLY
             *
             * as UnqualifiedJoin.
             */
            UnqualifiedJoin unqualifiedJoin =
                context.Node as UnqualifiedJoin;

            if (unqualifiedJoin != null)
            {
                ApplyUnqualifiedJoin(
                    unqualifiedJoin,
                    context,
                    layoutContext);

                return;
            }

            /*
             * ============================================================
             * QUALIFIED JOIN
             * ============================================================
             *
             * INNER JOIN
             * LEFT JOIN
             * RIGHT JOIN
             * FULL JOIN
             *
             * are represented as QualifiedJoin.
             */
            QualifiedJoin qualifiedJoin =
                context.Node as QualifiedJoin;

            if (qualifiedJoin == null)
            {
                return;
            }

            int queryBaseIndent =
                GetJoinQueryBaseIndent(
                    qualifiedJoin,
                    layoutContext);

            /*
             * ============================================================
             * JOIN
             * ============================================================
             *
             * A JOIN chain is represented by ScriptDom as nested
             * QualifiedJoin objects.
             *
             * Therefore each QualifiedJoin must format its own operator.
             */
            if (qualifiedJoin.SecondTableReference != null)
            {
                int joinStart =
                    FindTableOperatorStart(
                        qualifiedJoin.FirstTableReference,
                        qualifiedJoin.SecondTableReference,
                        layoutContext);

                if (joinStart >= 0)
                {
                    layoutContext.AddInstruction(
                        joinStart,
                        queryBaseIndent + 1,
                        "JoinLayoutPolicy",
                        context);
                }

                /*
                 * JOIN to derived table.
                 */
                QueryDerivedTable derivedTable =
                    qualifiedJoin.SecondTableReference
                        as QueryDerivedTable;

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
             * ============================================================
             * ON
             * ============================================================
             *
             * Search only AFTER this JOIN's second table.
             *
             * Do not search from QualifiedJoin.FirstTokenIndex because
             * nested QualifiedJoin structures may contain earlier ON
             * tokens.
             */
            if (qualifiedJoin.SecondTableReference != null &&
                qualifiedJoin.SearchCondition != null)
            {
                int searchStart =
                    qualifiedJoin
                        .SecondTableReference
                        .LastTokenIndex + 1;

                int searchEnd =
                    qualifiedJoin
                        .SearchCondition
                        .FirstTokenIndex;

                int onIndex =
                    layoutContext.TokenNavigator.FindTokenBetween(
                        searchStart,
                        searchEnd,
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
         * ================================================================
         * UNQUALIFIED JOIN
         * ================================================================
         */
        private static void ApplyUnqualifiedJoin(
            UnqualifiedJoin unqualifiedJoin,
            AstNodeContext context,
            LayoutContext layoutContext)
        {
            if (unqualifiedJoin == null ||
                unqualifiedJoin.FirstTableReference == null ||
                unqualifiedJoin.SecondTableReference == null ||
                layoutContext == null)
            {
                return;
            }

            int queryBaseIndent =
                GetJoinQueryBaseIndent(
                    unqualifiedJoin,
                    layoutContext);

            int operatorStart =
                FindTableOperatorStart(
                    unqualifiedJoin.FirstTableReference,
                    unqualifiedJoin.SecondTableReference,
                    layoutContext);

            if (operatorStart >= 0)
            {
                layoutContext.AddInstruction(
                    operatorStart,
                    queryBaseIndent + 1,
                    "JoinLayoutPolicy",
                    context);
            }

            /*
             * CROSS JOIN / CROSS APPLY / OUTER APPLY can also
             * use a derived table as the second table reference.
             */
            QueryDerivedTable derivedTable =
                unqualifiedJoin.SecondTableReference
                    as QueryDerivedTable;

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
         * ================================================================
         * TABLE OPERATOR START
         * ================================================================
         *
         * Generic handling for:
         *
         * JOIN
         * INNER JOIN
         * LEFT JOIN
         * LEFT OUTER JOIN
         * RIGHT JOIN
         * RIGHT OUTER JOIN
         * FULL JOIN
         * FULL OUTER JOIN
         * CROSS JOIN
         * CROSS APPLY
         * OUTER APPLY
         *
         * Search only inside the structural gap between the first and
         * second table reference.
         *
         * This is important for chained joins because ScriptDom represents
         * them as nested join objects.
         */
        private static int FindTableOperatorStart(
            TableReference firstTableReference,
            TableReference secondTableReference,
            LayoutContext layoutContext)
        {
            if (firstTableReference == null ||
                secondTableReference == null ||
                layoutContext == null ||
                layoutContext.Tokens == null)
            {
                return -1;
            }

            int start =
                firstTableReference.LastTokenIndex + 1;

            int end =
                secondTableReference.FirstTokenIndex - 1;

            if (start < 0)
            {
                start = 0;
            }

            if (end >= layoutContext.Tokens.Count)
            {
                end =
                    layoutContext.Tokens.Count - 1;
            }

            if (start > end)
            {
                return -1;
            }

            for (int i = start;
                 i <= end;
                 i++)
            {
                TSqlParserToken token =
                    layoutContext.Tokens[i];

                string text =
                    token.Text;

                if (string.Equals(
                        text,
                        "INNER",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "LEFT",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "RIGHT",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "FULL",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "CROSS",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "OUTER",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "JOIN",
                        System.StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(
                        text,
                        "APPLY",
                        System.StringComparison.OrdinalIgnoreCase))
                {
                    return i;
                }
            }

            return -1;
        }

        /*
         * ================================================================
         * JOIN QUERY BASE
         * ================================================================
         *
         * ScriptDom represents:
         *
         *     A
         *     JOIN B
         *     JOIN C
         *     JOIN D
         *
         * as nested join objects.
         *
         * Do not allow the nesting of join nodes to increase or change
         * indentation.
         *
         * Every JOIN/APPLY in one QuerySpecification resolves back to the
         * same QuerySpecification.
         */
        private static int GetJoinQueryBaseIndent(
            TSqlFragment fragment,
            LayoutContext layoutContext)
        {
            if (fragment == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return 0;
            }

            TSqlFragment current =
                fragment;

            while (current != null)
            {
                QuerySpecification querySpecification =
                    current as QuerySpecification;

                if (querySpecification != null)
                {
                    /*
                     * JOIN indentation belongs to the query containing
                     * the FROM clause.
                     *
                     * Resolve the base from the QuerySpecification's
                     * FromClause instead of from a nested join node.
                     *
                     * This guarantees JOIN 1, JOIN 2, JOIN 3, etc.
                     * receive exactly the same base indentation.
                     */
                    if (querySpecification.FromClause != null)
                    {
                        return
                            QueryIndentResolver.GetQueryBaseIndent(
                                querySpecification.FromClause,
                                layoutContext);
                    }

                    return
                        QueryIndentResolver.GetQueryBaseIndent(
                            querySpecification,
                            layoutContext);
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            return 0;
        }

        /*
         * ================================================================
         * DERIVED TABLE PARENTHESES
         * ================================================================
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
         * ================================================================
         * FIND OPENING PARENTHESIS
         * ================================================================
         */
        private static int FindOpeningParenthesis(
            QueryDerivedTable derivedTable,
            LayoutContext layoutContext)
        {
            if (derivedTable == null ||
                layoutContext == null ||
                layoutContext.Tokens == null)
            {
                return -1;
            }

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
         * ================================================================
         * FIND MATCHING CLOSING PARENTHESIS
         * ================================================================
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
