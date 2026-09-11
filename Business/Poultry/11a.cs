using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting.Policies
{
    public sealed class SelectLayoutPolicy :
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
             * QuerySpecification owns the SELECT keyword.
             *
             * SELECT is placed at the query base indent.
             * Individual SELECT elements are handled below
             * at query base indent + 1.
             */
            QuerySpecification querySpecification =
                context.Node as QuerySpecification;

            if (querySpecification != null)
            {
                int queryBaseIndent =
                    QueryIndentResolver.GetQueryBaseIndent(
                        querySpecification,
                        layoutContext);

                int selectIndex =
                    querySpecification.FirstTokenIndex;

                if (selectIndex >= 0 &&
                    selectIndex < layoutContext.Tokens.Count &&
                    layoutContext.Tokens[selectIndex].TokenType ==
                        TSqlTokenType.Select)
                {
                    layoutContext.AddInstruction(
                        selectIndex,
                        queryBaseIndent,
                        "SelectLayoutPolicy",
                        context);
                }

                return;
            }

            if (!TokenNavigator.IsIndexedRelationship(
                    context.Relationship,
                    "SelectElements"))
            {
                return;
            }

            int queryBaseIndent =
                QueryIndentResolver.GetQueryBaseIndent(
                    context.Node,
                    layoutContext);

            int elementIndent =
                queryBaseIndent + 1;

            int index =
                TokenNavigator.GetRelationshipIndex(
                    context.Relationship);

            if (index == 0)
            {
                layoutContext.AddInstruction(
                    context.Node.FirstTokenIndex,
                    elementIndent,
                    "SelectLayoutPolicy",
                    context);

                return;
            }

            int commaIndex =
                layoutContext.TokenNavigator
                    .FindPreviousToken(
                        context.Node.FirstTokenIndex,
                        TSqlTokenType.Comma);

            if (commaIndex < 0)
            {
                return;
            }

            bool hasCommentBetween =
                layoutContext.TokenNavigator
                    .HasCommentBetween(
                        commaIndex + 1,
                        context.Node.FirstTokenIndex - 1);

            /*
             * If a comment sits between the separator comma and the
             * next SELECT element, preserve token order and keep the
             * comma attached to the previous expression.
             *
             *     PreviousExpression;
             *     comment
             *     NextExpression
             *
             * This avoids an isolated comma line without moving the
             * comment across SQL tokens.
             */
            if (hasCommentBetween)
            {
                layoutContext.AddTightInstruction(
                    commaIndex,
                    "SelectLayoutPolicy",
                    context);

                layoutContext.AddInstruction(
                    context.Node.FirstTokenIndex,
                    elementIndent,
                    "SelectLayoutPolicy",
                    context);

                return;
            }

            /*
             * Normal leading-comma style.
             */
            layoutContext.AddInstruction(
                commaIndex,
                elementIndent,
                "SelectLayoutPolicy",
                context);

            layoutContext.AddTightInstruction(
                context.Node.FirstTokenIndex,
                "SelectLayoutPolicy",
                context);
        }
    }
}
