using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace SqlFormatter.Core.Formatting
{
    public sealed class ScriptDomCustomFormatterService
    {
        public string Format(string sql)
        {
            if (string.IsNullOrWhiteSpace(sql))
            {
                return string.Empty;
            }

            TSqlFragment fragment = Parse(sql);
            TSqlScript script = GetScript(fragment);

            var sb = new StringBuilder();

            FormatScript(sb, script);

            return sb.ToString().TrimEnd();
        }

        private static TSqlFragment Parse(string sql)
        {
            var parser = new TSql160Parser(false);

            IList<ParseError> errors;
            using (var reader = new StringReader(sql))
            {
                var fragment = parser.Parse(reader, out errors);

                if (errors.Count > 0)
                {
                    var sb = new StringBuilder();

                    foreach (var err in errors)
                    {
                        sb.AppendLine(
                            string.Format(
                                "{0} (Line {1}, Column {2})",
                                err.Message,
                                err.Line,
                                err.Column));
                    }

                    throw new Exception(sb.ToString());
                }

                return fragment;
            }
        }

        private static TSqlScript GetScript(TSqlFragment fragment)
        {
            var script = fragment as TSqlScript;
            if (script == null)
            {
                throw new Exception("Parsed fragment is not a TSqlScript.");
            }

            return script;
        }

        private void FormatScript(StringBuilder sb, TSqlScript script)
        {
            bool first = true;

            foreach (var batch in script.Batches)
            {
                foreach (var stmt in batch.Statements)
                {
                    if (!first)
                    {
                        sb.AppendLine();
                    }

                    FormatStatement(sb, stmt, 0);
                    first = false;
                }
            }
        }

        private void FormatStatement(StringBuilder sb, TSqlStatement stmt, int indent)
        {
            var selectStatement = stmt as SelectStatement;
            if (selectStatement != null)
            {
                FormatSelectStatement(sb, selectStatement, indent);
                return;
            }

            var createView = stmt as CreateViewStatement;
            if (createView != null)
            {
                FormatCreateView(sb, createView, indent);
                return;
            }

            var createProcedure = stmt as CreateProcedureStatement;
            if (createProcedure != null)
            {
                FormatCreateProcedure(sb, createProcedure, indent);
                return;
            }

            var createOrAlterProcedure = stmt as CreateOrAlterProcedureStatement;
            if (createOrAlterProcedure != null)
            {
                FormatCreateOrAlterProcedure(sb, createOrAlterProcedure, indent);
                return;
            }

            var beginEnd = stmt as BeginEndBlockStatement;
            if (beginEnd != null)
            {
                FormatBeginEnd(sb, beginEnd, indent);
                return;
            }

            var ifStatement = stmt as IfStatement;
            if (ifStatement != null)
            {
                FormatIf(sb, ifStatement, indent);
                return;
            }

            var whileStatement = stmt as WhileStatement;
            if (whileStatement != null)
            {
                FormatWhile(sb, whileStatement, indent);
                return;
            }

            var tryCatchStatement = stmt as TryCatchStatement;
            if (tryCatchStatement != null)
            {
                FormatTryCatch(sb, tryCatchStatement, indent);
                return;
            }

            var beginTran = stmt as BeginTransactionStatement;
            if (beginTran != null)
            {
                AppendLine(sb, indent, GenerateSql(beginTran));
                return;
            }

            var commitTran = stmt as CommitTransactionStatement;
            if (commitTran != null)
            {
                AppendLine(sb, indent, GenerateSql(commitTran));
                return;
            }

            var rollbackTran = stmt as RollbackTransactionStatement;
            if (rollbackTran != null)
            {
                AppendLine(sb, indent, GenerateSql(rollbackTran));
                return;
            }

            AppendLine(sb, indent, GenerateSql(stmt));
        }

        private void FormatCreateView(StringBuilder sb, CreateViewStatement stmt, int indent)
        {
            AppendLine(sb, indent, "CREATE VIEW " + GenerateSql(stmt.SchemaObjectName));
            AppendLine(sb, indent, "AS");

            if (stmt.SelectStatement != null)
            {
                FormatSelectStatement(sb, stmt.SelectStatement, indent);
            }
        }

        private void FormatCreateProcedure(StringBuilder sb, CreateProcedureStatement stmt, int indent)
        {
            AppendLine(sb, indent, "CREATE PROCEDURE " + GenerateSql(stmt.ProcedureReference.Name));
            FormatProcedureParameters(sb, stmt.Parameters, indent);
            AppendLine(sb, indent, "AS");

            if (stmt.StatementList != null)
            {
                FormatStatementListWithTransactionScope(sb, stmt.StatementList.Statements, indent);
            }
        }

        private void FormatCreateOrAlterProcedure(StringBuilder sb, CreateOrAlterProcedureStatement stmt, int indent)
        {
            AppendLine(sb, indent, "CREATE OR ALTER PROCEDURE " + GenerateSql(stmt.ProcedureReference.Name));
            FormatProcedureParameters(sb, stmt.Parameters, indent);
            AppendLine(sb, indent, "AS");

            if (stmt.StatementList != null)
            {
                FormatStatementListWithTransactionScope(sb, stmt.StatementList.Statements, indent);
            }
        }

        private void FormatProcedureParameters(StringBuilder sb, IList<ProcedureParameter> parameters, int indent)
        {
            if (parameters == null || parameters.Count == 0)
            {
                return;
            }

            for (int i = 0; i < parameters.Count; i++)
            {
                string prefix = i == 0 ? string.Empty : ",";
                AppendLine(sb, indent + 1, prefix + GenerateSql(parameters[i]));
            }
        }

        private void FormatStatementListWithTransactionScope(
            StringBuilder sb,
            IList<TSqlStatement> statements,
            int indent)
        {
            if (statements == null)
            {
                return;
            }

            int currentIndent = indent;

            foreach (var stmt in statements)
            {
                if (stmt is CommitTransactionStatement || stmt is RollbackTransactionStatement)
                {
                    currentIndent--;

                    if (currentIndent < indent)
                    {
                        currentIndent = indent;
                    }
                }

                FormatStatement(sb, stmt, currentIndent);

                if (stmt is BeginTransactionStatement)
                {
                    currentIndent++;
                }
            }
        }

        private void FormatBeginEnd(StringBuilder sb, BeginEndBlockStatement stmt, int indent)
        {
            AppendLine(sb, indent, "BEGIN");

            if (stmt.StatementList != null)
            {
                FormatStatementListWithTransactionScope(
                    sb,
                    stmt.StatementList.Statements,
                    indent + 1);
            }

            AppendLine(sb, indent, "END");
        }

        private void FormatIf(StringBuilder sb, IfStatement stmt, int indent)
        {
            AppendLine(sb, indent, "IF " + GenerateSql(stmt.Predicate));

            if (stmt.ThenStatement != null)
            {
                FormatStatement(sb, stmt.ThenStatement, indent);
            }

            if (stmt.ElseStatement != null)
            {
                AppendLine(sb, indent, "ELSE");
                FormatStatement(sb, stmt.ElseStatement, indent);
            }
        }

        private void FormatWhile(StringBuilder sb, WhileStatement stmt, int indent)
        {
            AppendLine(sb, indent, "WHILE " + GenerateSql(stmt.Predicate));

            if (stmt.Statement != null)
            {
                FormatStatement(sb, stmt.Statement, indent);
            }
        }

        private void FormatTryCatch(StringBuilder sb, TryCatchStatement stmt, int indent)
        {
            AppendLine(sb, indent, "BEGIN TRY");

            if (stmt.TryStatements != null)
            {
                FormatStatementListWithTransactionScope(
                    sb,
                    stmt.TryStatements.Statements,
                    indent + 1);
            }

            AppendLine(sb, indent, "END TRY");
            AppendLine(sb, indent, "BEGIN CATCH");

            if (stmt.CatchStatements != null)
            {
                FormatStatementListWithTransactionScope(
                    sb,
                    stmt.CatchStatements.Statements,
                    indent + 1);
            }

            AppendLine(sb, indent, "END CATCH");
        }

        private void FormatSelectStatement(StringBuilder sb, SelectStatement stmt, int indent)
        {
            if (stmt.WithCtesAndXmlNamespaces != null &&
                stmt.WithCtesAndXmlNamespaces.CommonTableExpressions.Count > 0)
            {
                FormatWithClause(sb, stmt.WithCtesAndXmlNamespaces, indent);
            }

            var query = stmt.QueryExpression as QuerySpecification;
            if (query == null)
            {
                AppendLine(sb, indent, GenerateSql(stmt));
                return;
            }

            FormatQuerySpecification(sb, query, indent);
        }

        private void FormatWithClause(StringBuilder sb, WithCtesAndXmlNamespaces withClause, int indent)
        {
            for (int i = 0; i < withClause.CommonTableExpressions.Count; i++)
            {
                var cte = withClause.CommonTableExpressions[i];

                if (i == 0)
                {
                    AppendLine(sb, indent, "WITH " + cte.ExpressionName.Value + " AS");
                }
                else
                {
                    AppendLine(sb, indent, ", " + cte.ExpressionName.Value + " AS");
                }

                AppendLine(sb, indent, "(");

                var query = cte.QueryExpression as QuerySpecification;
                if (query != null)
                {
                    FormatQuerySpecification(sb, query, indent + 1);
                }
                else
                {
                    AppendLine(sb, indent + 1, GenerateSql(cte.QueryExpression));
                }

                AppendLine(sb, indent, ")");
            }
        }

        private void FormatQuerySpecification(StringBuilder sb, QuerySpecification query, int indent)
        {
            FormatSelectClause(sb, query, indent);
            FormatFromClause(sb, query, indent);
            FormatWhereClause(sb, query, indent);
            FormatGroupByClause(sb, query, indent);
            FormatHavingClause(sb, query, indent);
            FormatOrderByClause(sb, query, indent);
        }

        private void FormatSelectClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            AppendLine(sb, indent, "SELECT");

            for (int i = 0; i < query.SelectElements.Count; i++)
            {
                string prefix = i == 0 ? string.Empty : ",";
                var scalar = query.SelectElements[i] as SelectScalarExpression;

                if (scalar != null && IsCaseExpression(scalar.Expression))
                {
                    AppendCaseSelectElement(sb, scalar, indent + 1, prefix);
                }
                else
                {
                    AppendLine(sb, indent + 1, prefix + GetSelectElementText(query.SelectElements[i]));
                }
            }
        }

        private void AppendCaseSelectElement(
            StringBuilder sb,
            SelectScalarExpression scalar,
            int indent,
            string prefix)
        {
            if (!string.IsNullOrEmpty(prefix))
            {
                AppendLine(sb, indent, prefix);
            }

            var searchedCase = scalar.Expression as SearchedCaseExpression;
            if (searchedCase != null)
            {
                AppendLine(sb, indent, "CASE");

                foreach (var whenClause in searchedCase.WhenClauses)
                {
                    AppendLine(sb, indent + 1, "WHEN " + GenerateSql(whenClause.WhenExpression));
                    AppendLine(sb, indent + 2, "THEN " + GenerateSql(whenClause.ThenExpression));
                }

                if (searchedCase.ElseExpression != null)
                {
                    AppendLine(sb, indent + 1, "ELSE");
                    AppendLine(sb, indent + 2, GenerateSql(searchedCase.ElseExpression));
                }

                string endLine = "END";
                if (scalar.ColumnName != null)
                {
                    endLine += " AS " + GenerateSql(scalar.ColumnName);
                }

                AppendLine(sb, indent, endLine);
                return;
            }

            var simpleCase = scalar.Expression as SimpleCaseExpression;
            if (simpleCase != null)
            {
                AppendLine(sb, indent, "CASE " + GenerateSql(simpleCase.InputExpression));

                foreach (var whenClause in simpleCase.WhenClauses)
                {
                    AppendLine(sb, indent + 1, "WHEN " + GenerateSql(whenClause.WhenExpression));
                    AppendLine(sb, indent + 2, "THEN " + GenerateSql(whenClause.ThenExpression));
                }

                if (simpleCase.ElseExpression != null)
                {
                    AppendLine(sb, indent + 1, "ELSE");
                    AppendLine(sb, indent + 2, GenerateSql(simpleCase.ElseExpression));
                }

                string endLine = "END";
                if (scalar.ColumnName != null)
                {
                    endLine += " AS " + GenerateSql(scalar.ColumnName);
                }

                AppendLine(sb, indent, endLine);
                return;
            }

            AppendLine(sb, indent, GetSelectElementText(scalar));
        }

        private void FormatFromClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            if (query.FromClause == null || query.FromClause.TableReferences.Count == 0)
            {
                return;
            }

            TableReference root = query.FromClause.TableReferences[0];

            var joins = new List<QualifiedJoin>();
            TableReference firstTable = ExtractFirstTableAndCollectJoins(root, joins);

            var firstDerived = firstTable as QueryDerivedTable;
            if (firstDerived != null)
            {
                AppendLine(sb, indent, "FROM");
                AppendDerivedTableBlock(sb, firstDerived, indent);
            }
            else
            {
                AppendLine(sb, indent, "FROM " + GetTableReferenceInlineText(firstTable));
            }

            foreach (var join in joins)
            {
                FormatJoinNode(sb, join, indent + 1);
            }

            for (int i = 1; i < query.FromClause.TableReferences.Count; i++)
            {
                FormatAdditionalTableReference(sb, query.FromClause.TableReferences[i], indent + 1);
            }
        }

        private TableReference ExtractFirstTableAndCollectJoins(
            TableReference tableReference,
            List<QualifiedJoin> joins)
        {
            var join = tableReference as QualifiedJoin;
            if (join != null)
            {
                TableReference first = ExtractFirstTableAndCollectJoins(join.FirstTableReference, joins);
                joins.Add(join);
                return first;
            }

            return tableReference;
        }

        private void FormatJoinNode(StringBuilder sb, QualifiedJoin join, int indent)
        {
            var derived = join.SecondTableReference as QueryDerivedTable;
            if (derived != null)
            {
                AppendLine(sb, indent, GetJoinKeyword(join.QualifiedJoinType));
                AppendDerivedTableBlock(sb, derived, indent);
            }
            else
            {
                AppendLine(
                    sb,
                    indent,
                    GetJoinKeyword(join.QualifiedJoinType) + " " + GetTableReferenceInlineText(join.SecondTableReference));
            }

            FormatOnClause(sb, join.SearchCondition, indent + 1);
        }

        private void FormatAdditionalTableReference(StringBuilder sb, TableReference table, int indent)
        {
            var derived = table as QueryDerivedTable;
            if (derived != null)
            {
                AppendDerivedTableBlock(sb, derived, indent);
                return;
            }

            AppendLine(sb, indent, GetTableReferenceInlineText(table));
        }

        private void AppendDerivedTableBlock(StringBuilder sb, QueryDerivedTable derived, int indent)
        {
            AppendLine(sb, indent, "(");

            var innerQuery = derived.QueryExpression as QuerySpecification;
            if (innerQuery != null)
            {
                FormatQuerySpecification(sb, innerQuery, indent + 1);
            }
            else
            {
                AppendLine(sb, indent + 1, GenerateSql(derived.QueryExpression));
            }

            AppendIndent(sb, indent);
            sb.Append(")");

            if (derived.Alias != null)
            {
                sb.Append(" " + derived.Alias.Value);
            }

            sb.AppendLine();
        }

        private void FormatOnClause(StringBuilder sb, BooleanExpression expression, int indent)
        {
            var binary = expression as BooleanBinaryExpression;
            if (binary != null)
            {
                string first = GetBooleanExpressionInlineText(binary.FirstExpression);
                AppendLine(sb, indent, "ON " + first);
                FormatBooleanOperatorChain(sb, binary.SecondExpression, indent, binary.BinaryExpressionType);
                return;
            }

            AppendLine(sb, indent, "ON " + GetBooleanExpressionInlineText(expression));
        }

        private void FormatBooleanOperatorChain(
            StringBuilder sb,
            BooleanExpression expression,
            int indent,
            BooleanBinaryExpressionType currentOperator)
        {
            var binary = expression as BooleanBinaryExpression;
            if (binary != null && binary.BinaryExpressionType == currentOperator)
            {
                string op = GetBooleanOperatorText(currentOperator);
                string left = GetBooleanExpressionInlineText(binary.FirstExpression);

                AppendLine(sb, indent, op + " " + left);
                FormatBooleanOperatorChain(sb, binary.SecondExpression, indent, currentOperator);
                return;
            }

            string finalOp = GetBooleanOperatorText(currentOperator);
            AppendLine(sb, indent, finalOp + " " + GetBooleanExpressionInlineText(expression));
        }

        private void FormatWhereClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            if (query.WhereClause == null)
            {
                return;
            }

            AppendLine(sb, indent, "WHERE");
            FormatBooleanExpressionIndented(sb, query.WhereClause.SearchCondition, indent + 1);
        }

        private void FormatHavingClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            if (query.HavingClause == null)
            {
                return;
            }

            AppendLine(sb, indent, "HAVING");
            FormatBooleanExpressionIndented(sb, query.HavingClause.SearchCondition, indent + 1);
        }

        private void FormatBooleanExpressionIndented(StringBuilder sb, BooleanExpression expression, int indent)
        {
            var binary = expression as BooleanBinaryExpression;
            if (binary != null)
            {
                FormatBooleanExpressionIndented(sb, binary.FirstExpression, indent);

                string op = GetBooleanOperatorText(binary.BinaryExpressionType);

                var rightParenthesis = binary.SecondExpression as BooleanParenthesisExpression;
                if (rightParenthesis != null)
                {
                    AppendLine(sb, indent, op);
                    FormatBooleanExpressionIndented(sb, rightParenthesis, indent);
                    return;
                }

                string rightText = GetBooleanExpressionInlineText(binary.SecondExpression);
                AppendLine(sb, indent, op + " " + rightText);
                return;
            }

            var parenthesis = expression as BooleanParenthesisExpression;
            if (parenthesis != null)
            {
                AppendLine(sb, indent, "(");
                FormatBooleanExpressionIndented(sb, parenthesis.Expression, indent + 1);
                AppendLine(sb, indent, ")");
                return;
            }

            AppendLine(sb, indent, GenerateSql(expression));
        }

        private void FormatGroupByClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            if (query.GroupByClause == null || query.GroupByClause.GroupingSpecifications.Count == 0)
            {
                return;
            }

            AppendLine(sb, indent, "GROUP BY");

            for (int i = 0; i < query.GroupByClause.GroupingSpecifications.Count; i++)
            {
                string prefix = i == 0 ? string.Empty : ",";
                AppendLine(sb, indent + 1, prefix + GenerateSql(query.GroupByClause.GroupingSpecifications[i]));
            }
        }

        private void FormatOrderByClause(StringBuilder sb, QuerySpecification query, int indent)
        {
            if (query.OrderByClause == null || query.OrderByClause.OrderByElements.Count == 0)
            {
                return;
            }

            AppendLine(sb, indent, "ORDER BY");

            for (int i = 0; i < query.OrderByClause.OrderByElements.Count; i++)
            {
                string prefix = i == 0 ? string.Empty : ",";
                AppendLine(sb, indent + 1, prefix + GenerateSql(query.OrderByClause.OrderByElements[i]));
            }
        }

        private static bool IsCaseExpression(ScalarExpression expression)
        {
            return expression is SearchedCaseExpression || expression is SimpleCaseExpression;
        }

        private static string GetJoinKeyword(QualifiedJoinType joinType)
        {
            switch (joinType)
            {
                case QualifiedJoinType.Inner:
                    return "INNER JOIN";
                case QualifiedJoinType.LeftOuter:
                    return "LEFT JOIN";
                case QualifiedJoinType.RightOuter:
                    return "RIGHT JOIN";
                case QualifiedJoinType.FullOuter:
                    return "FULL JOIN";
                default:
                    return "JOIN";
            }
        }

        private static string GetBooleanOperatorText(BooleanBinaryExpressionType type)
        {
            switch (type)
            {
                case BooleanBinaryExpressionType.And:
                    return "AND";
                case BooleanBinaryExpressionType.Or:
                    return "OR";
                default:
                    return type.ToString().ToUpperInvariant();
            }
        }

        private string GetBooleanExpressionInlineText(BooleanExpression expression)
        {
            var binary = expression as BooleanBinaryExpression;
            if (binary != null)
            {
                string left = GetBooleanExpressionInlineText(binary.FirstExpression);
                string op = GetBooleanOperatorText(binary.BinaryExpressionType);
                string right = GetBooleanExpressionInlineText(binary.SecondExpression);

                return left + " " + op + " " + right;
            }

            var parenthesis = expression as BooleanParenthesisExpression;
            if (parenthesis != null)
            {
                return "(" + GetBooleanExpressionInlineText(parenthesis.Expression) + ")";
            }

            return GenerateSql(expression);
        }

        private static string GetSelectElementText(SelectElement element)
        {
            var scalar = element as SelectScalarExpression;
            if (scalar != null)
            {
                string expr = GenerateSql(scalar.Expression);

                if (scalar.ColumnName != null)
                {
                    return expr + " AS " + GenerateSql(scalar.ColumnName);
                }

                return expr;
            }

            return GenerateSql(element);
        }

        private static string GetTableReferenceInlineText(TableReference table)
        {
            return GenerateSql(table);
        }

        private static string GenerateSql(TSqlFragment fragment)
        {
            var generator = new Sql160ScriptGenerator();
            string sql;
            generator.GenerateScript(fragment, out sql);
            return Normalize(sql).Trim();
        }

        private static string Normalize(string input)
        {
            string normalized = input.Replace("\r\n", "\n");
            string[] lines = normalized.Split('\n');

            var sb = new StringBuilder();

            foreach (string line in lines)
            {
                int leadingSpaces = 0;

                while (leadingSpaces < line.Length && line[leadingSpaces] == ' ')
                {
                    leadingSpaces++;
                }

                int tabCount = leadingSpaces / 4;
                string remainder = line.Substring(leadingSpaces);

                for (int i = 0; i < tabCount; i++)
                {
                    sb.Append('\t');
                }

                sb.AppendLine(remainder);
            }

            return sb.ToString();
        }

        private static void AppendIndent(StringBuilder sb, int indent)
        {
            for (int i = 0; i < indent; i++)
            {
                sb.Append('\t');
            }
        }

        private static void AppendLine(StringBuilder sb, int indent, string text)
        {
            AppendIndent(sb, indent);
            sb.AppendLine(text);
        }
    }
}
