using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting.Policies
{
    public sealed class StatementLayoutPolicy :
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

            /*
             * Temporary diagnostic for THROW.
             *
             * We are verifying whether ThrowStatement reaches this policy
             * and, if it does, whether Parent / Relationship are correct.
             */
            if (context.Node is ThrowStatement)
            {
                layoutContext.Diagnostics.Add(
                    "DEBUG_THROW",
                    "Reached StatementLayoutPolicy. " +
                    "Node=" +
                    context.Node.GetType().Name +
                    ", Parent=" +
                    (context.Parent == null
                        ? "NULL"
                        : context.Parent.GetType().Name) +
                    ", Relationship=" +
                    context.Relationship +
                    ", FirstTokenIndex=" +
                    context.Node.FirstTokenIndex);
            }

            /*
             * Generic statement boundary rule:
             *
             * StatementList
             *     -> Statements[n]
             *
             * We do not care whether the statement is:
             *
             * SELECT
             * INSERT
             * UPDATE
             * DELETE
             * SET
             * DECLARE
             * IF
             * WHILE
             * TRY/CATCH
             * THROW
             * etc.
             */
            if (!TokenNavigator.IsIndexedRelationship(
                    context.Relationship,
                    "Statements"))
            {
                if (context.Node is ThrowStatement)
                {
                    layoutContext.Diagnostics.Add(
                        "DEBUG_THROW",
                        "Returned from StatementLayoutPolicy: " +
                        "Relationship is not Statements[n]. " +
                        "Relationship=" +
                        context.Relationship);
                }

                return;
            }

            if (!(context.Parent is StatementList))
            {
                if (context.Node is ThrowStatement)
                {
                    layoutContext.Diagnostics.Add(
                        "DEBUG_THROW",
                        "Returned from StatementLayoutPolicy: " +
                        "Parent is not StatementList. Parent=" +
                        (context.Parent == null
                            ? "NULL"
                            : context.Parent.GetType().Name));
                }

                return;
            }

            /*
             * Important:
             *
             * Do not use EmptyStatement here.
             *
             * Some ScriptDom versions do not expose
             * an EmptyStatement type.
             *
             * Semicolon placement will be handled
             * using token/layout logic separately.
             */

            int indent =
                StatementIndentResolver
                    .GetStatementIndent(
                        context.Node,
                        layoutContext);

            if (context.Node is ThrowStatement)
            {
                layoutContext.Diagnostics.Add(
                    "DEBUG_THROW",
                    "Adding StatementLayoutPolicy instruction. " +
                    "Indent=" +
                    indent +
                    ", TokenIndex=" +
                    context.Node.FirstTokenIndex);
            }

            layoutContext.AddInstruction(
                context.Node.FirstTokenIndex,
                indent,
                "StatementLayoutPolicy",
                context);
        }
    }
}
