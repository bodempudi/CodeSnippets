using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting.Policies
{
    public sealed class CteLayoutPolicy :
        ILayoutPolicy
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

            CommonTableExpression cte =
                context.Node as CommonTableExpression;

            if (cte != null)
            {
                ApplyCte(
                    cte,
                    context,
                    layoutContext);

                return;
            }

            SelectStatement selectStatement =
                context.Node as SelectStatement;

            if (selectStatement != null &&
                selectStatement.WithCtesAndXmlNamespaces != null &&
                selectStatement.QueryExpression != null)
            {
                int statementIndent =
                    StatementIndentResolver
                        .GetStatementIndent(
                            selectStatement,
                            layoutContext);

                /*
                 * A CTE may already be written defensively as:
                 *
                 *     ;WITH CteName AS
                 *
                 * We do not create a semicolon.
                 * We only manage it when it already exists
                 * immediately before WITH.
                 */
                ApplyCteVisualStart(
                    selectStatement,
                    context,
                    layoutContext,
                    statementIndent);

                /*
                 * Main query following the CTE list.
                 */
                layoutContext.AddInstruction(
                    selectStatement
                        .QueryExpression
                        .FirstTokenIndex,
                    statementIndent,
                    "CteLayoutPolicy",
                    context);
            }
        }

        private static void ApplyCteVisualStart(
            SelectStatement selectStatement,
            AstNodeContext context,
            LayoutContext layoutContext,
            int statementIndent)
        {
            int withIndex =
                layoutContext.TokenNavigator
                    .FindMeaningfulTokenByTextBetween(
                        selectStatement.FirstTokenIndex,
                        selectStatement
                            .WithCtesAndXmlNamespaces
                            .FirstTokenIndex,
                        "WITH");

            if (withIndex < 0)
            {
                withIndex =
                    selectStatement.FirstTokenIndex;
            }

            /*
             * IMPORTANT:
             *
             * Do NOT search backwards for any semicolon.
             *
             * These are different:
             *
             *     ;WITH CteName AS
             *
             * and:
             *
             *     SELECT ...;
             *
             *     WITH CteName AS
             *
             * In the second example, the semicolon belongs
             * to the previous statement.
             *
             * A semicolon belongs to the CTE visual start only
             * when it is the immediately previous non-whitespace
             * token before WITH.
             *
             * A developer comment also breaks that ownership:
             *
             *     ;
             *     /* comment */
             *     WITH ...
             *
             * Therefore only whitespace is skipped here.
             */
            int semicolonIndex =
                FindImmediatePrefixSemicolon(
                    layoutContext,
                    withIndex);

            if (semicolonIndex < 0)
            {
                return;
            }

            LayoutInstruction withInstruction =
                layoutContext.Plan
                    .GetInstruction(
                        withIndex);

            /*
             * Transfer the logical statement boundary
             * from WITH to the existing prefix semicolon.
             *
             * Preserve BlankLine when already requested.
             */
            if (withInstruction != null &&
                withInstruction.Action ==
                    LayoutAction.BlankLine)
            {
                layoutContext.AddBlankLineInstruction(
                    semicolonIndex,
                    withInstruction.IndentLevel,
                    "CteLayoutPolicy",
                    context);
            }
            else
            {
                int indent =
                    withInstruction == null
                        ? statementIndent
                        : withInstruction.IndentLevel;

                layoutContext.AddInstruction(
                    semicolonIndex,
                    indent,
                    "CteLayoutPolicy",
                    context);
            }

            /*
             * For a genuine source-written ;WITH,
             * keep WITH tight to that semicolon.
             *
             * No tokens are added, removed, or reordered.
             */
            layoutContext.AddTightInstruction(
                withIndex,
                "CteLayoutPolicy",
                context);
        }

        private static int FindImmediatePrefixSemicolon(
            LayoutContext layoutContext,
            int withIndex)
        {
            if (layoutContext == null ||
                layoutContext.Tokens == null ||
                withIndex <= 0)
            {
                return -1;
            }

            /*
             * Walk backwards only through whitespace.
             *
             * The first non-whitespace token determines
             * ownership.
             *
             * If it is ';' -> genuine CTE prefix.
             *
             * If it is a comment, SQL token, previous
             * statement, etc. -> no CTE prefix semicolon.
             */
            for (int i = withIndex - 1;
                 i >= 0;
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

                return token.TokenType ==
                        TSqlTokenType.Semicolon
                    ? i
                    : -1;
            }

            return -1;
        }

        private static void ApplyCte(
            CommonTableExpression cte,
            AstNodeContext context,
            LayoutContext layoutContext)
        {
            if (cte.QueryExpression == null)
            {
                return;
            }

            int baseIndent =
                GetCteBaseIndent(
                    cte,
                    layoutContext);

            int cteIndex =
                TokenNavigator.GetRelationshipIndex(
                    context.Relationship);

            if (cteIndex > 0)
            {
                int commaIndex =
                    layoutContext.TokenNavigator
                        .FindPreviousToken(
                            cte.FirstTokenIndex,
                            TSqlTokenType.Comma);

                if (commaIndex >= 0)
                {
                    /*
                     * Leading-comma CTE style:
                     *
                     *     WITH CteA AS
                     *     (
                     *         ...
                     *     )
                     *     ,CteB AS
                     *     (
                     *         ...
                     *     )
                     */
                    layoutContext.AddInstruction(
                        commaIndex,
                        baseIndent,
                        "CteLayoutPolicy",
                        context);

                    layoutContext.AddTightInstruction(
                        cte.FirstTokenIndex,
                        "CteLayoutPolicy",
                        context);
                }
            }

            int openIndex =
                layoutContext.TokenNavigator
                    .FindMeaningfulTokenByTextBetween(
                        cte.FirstTokenIndex,
                        cte.QueryExpression.FirstTokenIndex,
                        "(");

            if (openIndex >= 0)
            {
                layoutContext.AddInstruction(
                    openIndex,
                    baseIndent,
                    "CteLayoutPolicy",
                    context);
            }

            layoutContext.AddInstruction(
                cte.QueryExpression.FirstTokenIndex,
                baseIndent + 1,
                "CteLayoutPolicy",
                context);

            int closeIndex =
                layoutContext.TokenNavigator
                    .FindMeaningfulTokenByTextBetween(
                        cte.QueryExpression.LastTokenIndex + 1,
                        cte.LastTokenIndex,
                        ")");

            if (closeIndex >= 0)
            {
                layoutContext.AddInstruction(
                    closeIndex,
                    baseIndent,
                    "CteLayoutPolicy",
                    context);
            }
        }

        private static int GetCteBaseIndent(
            TSqlFragment node,
            LayoutContext layoutContext)
        {
            TSqlFragment current =
                node;

            while (current != null)
            {
                SelectStatement selectStatement =
                    current as SelectStatement;

                if (selectStatement != null)
                {
                    return
                        StatementIndentResolver
                            .GetStatementIndent(
                                selectStatement,
                                layoutContext);
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            return 0;
        }
    }
}
