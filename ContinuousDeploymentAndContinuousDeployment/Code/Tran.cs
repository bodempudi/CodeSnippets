using System;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting
{
    public static class StatementIndentResolver
    {
        public static int GetStatementIndent(
            TSqlFragment node,
            LayoutContext layoutContext)
        {
            if (node == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return 0;
            }

            int indent = 0;

            TSqlFragment current =
                layoutContext.Walker.GetParent(
                    node);

            while (current != null)
            {
                if (current is BeginEndBlockStatement)
                {
                    indent++;
                }

                /*
                 * TRY/CATCH owns a statement-list body even though
                 * it is not represented by BeginEndBlockStatement.
                 */
                if (current is TryCatchStatement)
                {
                    indent++;
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            /*
             * BEGIN TRAN is not an AST container.
             *
             * ScriptDom represents:
             *
             *     BEGIN TRAN
             *     IF ...
             *     UPDATE ...
             *     COMMIT TRAN
             *
             * as sibling statements in the same StatementList.
             *
             * Add one visual indentation level while a transaction
             * is active. COMMIT / ROLLBACK aligns back with
             * BEGIN TRAN.
             */
            indent += GetTransactionScopeIndent(
                node,
                layoutContext);

            return indent;
        }

        private static int GetTransactionScopeIndent(
            TSqlFragment node,
            LayoutContext layoutContext)
        {
            if (node == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return 0;
            }

            int transactionIndent = 0;

            TSqlFragment current = node;

            TSqlFragment parent =
                layoutContext.Walker.GetParent(
                    current);

            /*
             * Walk upward because a statement may be inside:
             *
             * BEGIN TRAN
             *     IF ...
             *     BEGIN
             *         WHILE ...
             *         BEGIN
             *             UPDATE ...
             *         END
             *     END
             * COMMIT TRAN
             *
             * The UPDATE must still inherit the transaction
             * indentation from the outer StatementList.
             */
            while (parent != null)
            {
                StatementList statementList =
                    parent as StatementList;

                TSqlStatement currentStatement =
                    current as TSqlStatement;

                if (statementList != null &&
                    currentStatement != null)
                {
                    transactionIndent +=
                        GetActiveTransactionDepth(
                            statementList,
                            currentStatement);
                }

                current = parent;

                parent =
                    layoutContext.Walker.GetParent(
                        current);
            }

            return transactionIndent;
        }

        private static int GetActiveTransactionDepth(
            StatementList statementList,
            TSqlStatement currentStatement)
        {
            if (statementList == null ||
                currentStatement == null)
            {
                return 0;
            }

            int depth = 0;

            foreach (TSqlStatement statement
                in statementList.Statements)
            {
                /*
                 * Stop when we reach the statement whose
                 * indentation is being calculated.
                 *
                 * COMMIT / ROLLBACK closes the visual scope,
                 * therefore it aligns with BEGIN TRAN.
                 */
                if (ReferenceEquals(
                    statement,
                    currentStatement))
                {
                    if (currentStatement
                            is CommitTransactionStatement ||
                        currentStatement
                            is RollbackTransactionStatement)
                    {
                        return Math.Max(
                            0,
                            depth - 1);
                    }

                    return depth;
                }

                if (statement
                    is BeginTransactionStatement)
                {
                    depth++;

                    continue;
                }

                if (statement
                        is CommitTransactionStatement ||
                    statement
                        is RollbackTransactionStatement)
                {
                    depth =
                        Math.Max(
                            0,
                            depth - 1);
                }
            }

            return 0;
        }

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
            if (bodyStatement
                is BeginEndBlockStatement)
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
    }
}
