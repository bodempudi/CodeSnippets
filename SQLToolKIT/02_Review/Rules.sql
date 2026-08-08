SQL CODE REVIEW RULE CATALOG
============================

CATEGORY: CODING STANDARD / READABILITY
---------------------------------------
SQLR0001 | NOLOCK missing on applicable read table references
SQLR0002 | Avoid SELECT * / Alias.*
SQLR0003 | Alias missing when JOIN is defined


CATEGORY: SQL CORRECTNESS / LOGIC RISK
--------------------------------------
SQLR0004 | Invalid NULL comparison (= NULL, <> NULL, != NULL)
SQLR0015 | NOT IN with subquery — review NULL / three-valued-logic risk


CATEGORY: DATA SAFETY
---------------------
SQLR0005 | Avoid TRUNCATE TABLE
SQLR0006 | DELETE safety rule


CATEGORY: PERFORMANCE / SARGABILITY
-----------------------------------
SQLR0007 | Function applied to a column in a WHERE predicate


CATEGORY: ENGINEERING GUIDELINES
--------------------------------
SQLR0008 | [Existing approved rule]
SQLR0009 | [Existing approved rule]
SQLR0010 | [Existing approved rule]
SQLR0011 | [Existing approved rule]
SQLR0012 | [Existing approved rule]
SQLR0013 | [Existing approved rule]
SQLR0014 | [Existing approved rule]


CATEGORY: NAMING CONVENTION
---------------------------
SQLR0016 | Local variables must start with @V_
           Example: @V_CustomerId

SQLR0017 | Input parameters must start with @I_
           Example: @I_CustomerId

SQLR0018 | Output parameters must start with @O_
           Example: @O_StatusCode


PROPOSED ADDITIONAL RULES
=========================

CATEGORY: DATA SAFETY
---------------------
Candidate | UPDATE without WHERE
          | Flag unrestricted UPDATE statements

Candidate | DELETE without WHERE
          | Flag unrestricted DELETE statements
          | Check against existing SQLR0006 before adding


CATEGORY: PERFORMANCE
---------------------
Candidate | Cursor usage
          | Review whether set-based processing can be used

Candidate | Row-by-row WHILE processing
          | Review RBAR-style processing

Candidate | Scalar UDF used in row-processing query
          | Review potential row-by-row/performance impact


CATEGORY: PERFORMANCE / DATATYPE
--------------------------------
Candidate | Implicit datatype conversion in predicates
          | Example: INT column compared with VARCHAR value
          | Detection may require datatype/metadata knowledge
