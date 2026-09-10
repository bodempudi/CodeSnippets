using Microsoft.SqlServer.TransactSql.ScriptDom;

namespace NotepadPlusPlusPlugin.Formatting
{
    public static class QueryIndentResolver
    {
        public static int GetQueryBaseIndent(
            TSqlFragment node,
            LayoutContext layoutContext)
        {
            if (node == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return 0;
            }

            QuerySpecification query =
                FindOwningQuery(
                    node,
                    layoutContext);

            if (query == null)
            {
                /*
                 * DML/statement-owned clauses
                 * (for example UPDATE WHERE)
                 * do not have an owning
                 * QuerySpecification.
                 *
                 * Fall back to structural
                 * statement indentation.
                 */
                return
                    StatementIndentResolver
                        .GetStatementIndent(
                            node,
                            layoutContext);
            }

            /*
             * ==========================================================
             * FIRST CHOICE
             * USE AN ALREADY-ESTABLISHED QUERY INDENT
             * ==========================================================
             *
             * SubqueryLayoutPolicy runs on ScalarSubquery /
             * EXISTS / IN structures before the child
             * QuerySpecification is visited.
             *
             * It already creates:
             *
             *     SELECT token -> correct structural indentation
             *
             * Therefore this becomes the most reliable query base.
             *
             * Example:
             *
             *     (
             *         SELECT      <- indent 2
             *
             * Query base = 2
             *
             * CASE THEN scalar subquery:
             *
             *         THEN
             *             (
             *                 SELECT      <- indent 5
             *
             * Query base = 5
             */
            int establishedIndent =
                FindEstablishedQueryIndent(
                    query,
                    layoutContext);

            if (establishedIndent >= 0)
            {
                return establishedIndent;
            }

            /*
             * ==========================================================
             * JOIN DERIVED TABLE
             * ==========================================================
             *
             * Example:
             *
             * FROM dbo.TableA a
             *     INNER JOIN
             *     (
             *         SELECT
             *             b.Id
             *         FROM dbo.TableB b
             *     ) b
             *         ON a.Id = b.Id
             *
             * The derived-table query belongs to the JOIN.
             *
             * Outer query base : 0
             * JOIN             : 1
             * Derived SELECT   : 2
             *
             * Therefore:
             *
             *     inner query base =
             *         outer query base + 2
             */
            int derivedTableIndent =
                GetJoinDerivedTableQueryIndent(
                    query,
                    layoutContext);

            if (derivedTableIndent >= 0)
            {
                return derivedTableIndent;
            }

            /*
             * ==========================================================
             * STRUCTURAL STATEMENT INDENT
             * ==========================================================
             *
             * A query can be top-level SQL, a statement inside a
             * BEGIN/TRY/IF body, or the source of INSERT ... SELECT.
             *
             * If no subquery policy has already established SELECT's
             * indent, inherit the surrounding statement structure.
             *
             * Top-level SELECT still resolves to 0, while a SELECT
             * inside a procedure/IF/TRY or INSERT source keeps the
             * same base indentation as its owning statement.
             */
            return
                StatementIndentResolver
                    .GetStatementIndent(
                        query,
                        layoutContext);
        }

        /*
         * ==========================================================
         * FIND OWNING QUERY
         * ==========================================================
         */

        private static QuerySpecification FindOwningQuery(
            TSqlFragment node,
            LayoutContext layoutContext)
        {
            TSqlFragment current =
                node;

            while (current != null)
            {
                QuerySpecification query =
                    current as QuerySpecification;

                if (query != null)
                {
                    return query;
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            return null;
        }

        /*
         * ==========================================================
         * FIND ESTABLISHED QUERY INDENT
         * ==========================================================
         */

        private static int FindEstablishedQueryIndent(
            QuerySpecification query,
            LayoutContext layoutContext)
        {
            if (query == null ||
                layoutContext == null ||
                layoutContext.Plan == null)
            {
                return -1;
            }

            /*
             * QuerySpecification.FirstTokenIndex should represent
             * SELECT for our current query forms.
             *
             * Find an instruction already created for that token.
             */
            int queryStartTokenIndex =
                query.FirstTokenIndex;

            foreach (
                LayoutInstruction instruction
                in layoutContext.Plan.Instructions)
            {
                if (instruction.TokenIndex !=
                    queryStartTokenIndex)
                {
                    continue;
                }

                return
                    instruction.IndentLevel;
            }

            return -1;
        }

        /*
         * ==========================================================
         * JOIN DERIVED TABLE QUERY INDENT
         * ==========================================================
         *
         * Handles:
         *
         * FROM dbo.TableA a
         *     INNER JOIN
         *     (
         *         SELECT
         *             b.Id
         *         FROM dbo.TableB b
         *     ) b
         *         ON a.Id = b.Id
         *
         * This method establishes only the QUERY BASE.
         *
         * It does not format:
         *
         *     JOIN
         *     ON
         *     opening (
         *     closing )
         *
         * Those remain owned by their respective layout policies.
         * ==========================================================
         */

        private static int GetJoinDerivedTableQueryIndent(
            QuerySpecification query,
            LayoutContext layoutContext)
        {
            if (query == null ||
                layoutContext == null ||
                layoutContext.Walker == null)
            {
                return -1;
            }

            /*
             * Walk upward from the inner QuerySpecification
             * until we find its QueryDerivedTable.
             */
            TSqlFragment current =
                layoutContext.Walker.GetParent(
                    query);

            QueryDerivedTable derivedTable =
                null;

            while (current != null)
            {
                derivedTable =
                    current as QueryDerivedTable;

                if (derivedTable != null)
                {
                    break;
                }

                /*
                 * If another QuerySpecification is reached first,
                 * this query is not directly owned by the derived
                 * table we are looking for.
                 */
                if (current is QuerySpecification)
                {
                    return -1;
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            if (derivedTable == null)
            {
                return -1;
            }

            /*
             * The derived table must be the second table of a
             * QualifiedJoin.
             */
            TSqlFragment derivedTableParent =
                layoutContext.Walker.GetParent(
                    derivedTable);

            QualifiedJoin qualifiedJoin =
                derivedTableParent as QualifiedJoin;

            if (qualifiedJoin == null)
            {
                return -1;
            }

            if (!object.ReferenceEquals(
                    qualifiedJoin.SecondTableReference,
                    derivedTable))
            {
                return -1;
            }

            /*
             * Find the outer QuerySpecification that owns
             * this JOIN.
             */
            current =
                layoutContext.Walker.GetParent(
                    qualifiedJoin);

            QuerySpecification outerQuery =
                null;

            while (current != null)
            {
                outerQuery =
                    current as QuerySpecification;

                if (outerQuery != null)
                {
                    break;
                }

                current =
                    layoutContext.Walker.GetParent(
                        current);
            }

            if (outerQuery == null)
            {
                return -1;
            }

            /*
             * Resolve the real base of the outer query.
             *
             * This also allows nested JOIN-derived tables:
             *
             * JOIN
             * (
             *     SELECT
             *     ...
             *     FROM ...
             *         JOIN
             *         (
             *             SELECT ...
             *         )
             * )
             */
            int outerQueryBaseIndent =
                GetQueryBaseIndent(
                    outerQuery,
                    layoutContext);

            /*
             * Outer query:
             *
             * FROM            = base
             *     JOIN        = base + 1
             *         SELECT  = base + 2
             */
            return
                outerQueryBaseIndent + 2;
        }
    }
}
