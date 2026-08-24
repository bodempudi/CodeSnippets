/*==============================================================================
    FINAL POC
    =========

    CATEGORY SIMULATION / EVALUATION FUNCTION

    Function:
        dbo.ufn_GetCategoryEvaluation

    Returns:
        NVARCHAR(MAX)

    Purpose:
        Evaluate ONE transaction against all configured category precedence
        sources and return one complete JSON document containing:

            1. Input
            2. SelectedCategory
            3. EvaluationTrace

    Supported Sources:
        USER
        BRAND
        MERCHANT
        MERCHANT_OTHER
        MERCHANT_CATEGORY
        TRANSACTION_TYPE
        EXPRESSION

    IMPORTANT DESIGN PRINCIPLES
    ---------------------------

    1. Category precedence is configuration/data.

       The function does NOT hard-code:

            BRAND before MERCHANT
            MERCHANT before MCC
            etc.

       dbo.CategoryPrecedence.DisplayOrder controls the winner.


    2. Candidate discovery is separate from winner selection.

       First determine:

            User Category
            Brand Category
            Merchant Category
            Merchant Other Category
            MCC Category
            Transaction Type Category
            Expression Category

       Then apply precedence.


    3. BRAND has its own resolution rule.

       BRAND precedence answers:

            "Where does BRAND sit among all category sources?"

       Brand resolution separately answers:

            "Where did the Brand come from?"

       In this POC:

            Merchant.BrandId
                    ↓
            if unavailable
                    ↓
            MerchantOther.BrandId


    4. Structured fields are the source of truth.

       Fields such as:

            SourceCode
            MerchantId
            BrandId
            CategoryId
            Status

       are authoritative.

       CategoryEvaluationPath and Reason are only diagnostic/readable text.


    5. Function is intended for ONE transaction simulation.

       It is NOT intended to be executed once per row across millions
       of production transactions.

==============================================================================*/


/*==============================================================================
    PART 1
    DROP EXISTING POC OBJECTS
==============================================================================*/

DROP FUNCTION IF EXISTS dbo.ufn_GetCategoryEvaluation;
GO

DROP TABLE IF EXISTS dbo.CategoryExpression;
DROP TABLE IF EXISTS dbo.CategoryTransactionType;
DROP TABLE IF EXISTS dbo.CategoryMerchantCategory;
DROP TABLE IF EXISTS dbo.MerchantOther;
DROP TABLE IF EXISTS dbo.Merchant;
DROP TABLE IF EXISTS dbo.Brand;
DROP TABLE IF EXISTS dbo.CategoryPrecedence;
DROP TABLE IF EXISTS dbo.Category;
GO


/*==============================================================================
    PART 2
    CATEGORY MASTER
==============================================================================*/

CREATE TABLE dbo.Category
(
    CategoryId              INT             NOT NULL,
    ParentCategoryId        INT             NULL,

    CategoryNameEnglish     VARCHAR(100)    NOT NULL,
    CategoryNameArabic      NVARCHAR(100)   NULL,

    CONSTRAINT PK_Category
        PRIMARY KEY (CategoryId)
);
GO


/*==============================================================================
    PART 3
    CATEGORY PRECEDENCE
==============================================================================*/

/*
    SourceCode
    ----------

    Stable technical identifier.

    Do not use SourceDisplayName for application logic.


    SourceDisplayName
    -----------------

    Human-readable label.

    This can change without affecting categorization logic.


    DisplayOrder
    ------------

    Lower number means HIGHER priority.

    Example:

        USER        1
        BRAND       2
        MERCHANT    3

    The function only asks:

        Which successful candidate has the lowest DisplayOrder?
*/

CREATE TABLE dbo.CategoryPrecedence
(
    SourceCode          VARCHAR(50)     NOT NULL,
    SourceDisplayName   VARCHAR(100)    NOT NULL,
    DisplayOrder        INT             NOT NULL,

    CONSTRAINT PK_CategoryPrecedence
        PRIMARY KEY (SourceCode),

    CONSTRAINT UQ_CategoryPrecedence_DisplayOrder
        UNIQUE (DisplayOrder),

    CONSTRAINT CK_CategoryPrecedence_DisplayOrder
        CHECK (DisplayOrder > 0)
);
GO


/*==============================================================================
    PART 4
    BRAND MASTER
==============================================================================*/

CREATE TABLE dbo.Brand
(
    BrandId         INT             NOT NULL,
    BrandName       VARCHAR(100)    NOT NULL,

    /*
        Category returned if BRAND becomes the winning precedence.
    */

    CategoryId      INT             NULL,

    CONSTRAINT PK_Brand
        PRIMARY KEY (BrandId)
);
GO


/*==============================================================================
    PART 5
    MERCHANT
==============================================================================*/

/*
    Merchant can participate in TWO category paths.

    Path 1 - MERCHANT precedence

        Merchant
            ↓
        CategoryId


    Path 2 - BRAND precedence

        Merchant
            ↓
        BrandId
            ↓
        Brand
            ↓
        CategoryId
*/

CREATE TABLE dbo.Merchant
(
    MerchantId      INT             NOT NULL,
    MerchantName    VARCHAR(100)    NOT NULL,

    BrandId         INT             NULL,
    CategoryId      INT             NULL,

    CONSTRAINT PK_Merchant
        PRIMARY KEY (MerchantId)
);
GO


/*==============================================================================
    PART 6
    MERCHANT OTHER
==============================================================================*/

CREATE TABLE dbo.MerchantOther
(
    MerchantOtherId     INT             NOT NULL,
    MerchantOtherName   VARCHAR(100)    NOT NULL,

    BrandId             INT             NULL,
    CategoryId          INT             NULL,

    CONSTRAINT PK_MerchantOther
        PRIMARY KEY (MerchantOtherId)
);
GO


/*==============================================================================
    PART 7
    MERCHANT CATEGORY / MCC
==============================================================================*/

CREATE TABLE dbo.CategoryMerchantCategory
(
    CategoryMerchantCategoryId  INT NOT NULL,
    CategoryId                  INT NULL,

    CONSTRAINT PK_CategoryMerchantCategory
        PRIMARY KEY (CategoryMerchantCategoryId)
);
GO


/*==============================================================================
    PART 8
    TRANSACTION TYPE
==============================================================================*/

CREATE TABLE dbo.CategoryTransactionType
(
    CategoryTransactionTypeId   INT NOT NULL,
    CategoryId                  INT NULL,

    CONSTRAINT PK_CategoryTransactionType
        PRIMARY KEY (CategoryTransactionTypeId)
);
GO


/*==============================================================================
    PART 9
    EXPRESSION
==============================================================================*/

CREATE TABLE dbo.CategoryExpression
(
    CategoryExpressionId    INT NOT NULL,
    CategoryId              INT NULL,

    CONSTRAINT PK_CategoryExpression
        PRIMARY KEY (CategoryExpressionId)
);
GO


/*==============================================================================
    PART 10
    CATEGORY TEST DATA
==============================================================================*/

INSERT INTO dbo.Category
(
    CategoryId,
    ParentCategoryId,
    CategoryNameEnglish,
    CategoryNameArabic
)
VALUES

    /* Parent categories */

    (1, NULL, 'Shopping',        N'التسوق'),
    (2, NULL, 'Food & Dining',   N'الطعام'),
    (3, NULL, 'Transfers',       N'التحويلات'),


    /* Child categories */

    (101, 1, 'General Shopping', N'تسوق عام'),

    (102, 1, 'Sports Shopping',  N'تسوق رياضي'),

    (201, 2, 'Restaurant',       N'مطعم'),

    (202, 2, 'Fast Food',        N'وجبات سريعة'),

    (301, 3, 'Money Transfer',   N'تحويل أموال');
GO


/*==============================================================================
    PART 11
    PRECEDENCE TEST CONFIGURATION
==============================================================================*/

/*
    Current precedence:

        1 User
        2 Brand
        3 Merchant
        4 Merchant Other
        5 Merchant Category
        6 Transaction Type
        7 Expression

    IMPORTANT:

    You can change these orders later without changing the UDF.
*/

INSERT INTO dbo.CategoryPrecedence
(
    SourceCode,
    SourceDisplayName,
    DisplayOrder
)
VALUES
    ('USER',                 'User',                 1),
    ('BRAND',                'Brand',                2),
    ('MERCHANT',             'Merchant',             3),
    ('MERCHANT_OTHER',       'Merchant Other',       4),
    ('MERCHANT_CATEGORY',    'Merchant Category',    5),
    ('TRANSACTION_TYPE',     'Transaction Type',     6),
    ('EXPRESSION',           'Expression',           7);
GO


/*==============================================================================
    PART 12
    BRAND TEST DATA
==============================================================================*/

/*
    Nike belongs to Sports Shopping.
*/

INSERT INTO dbo.Brand
(
    BrandId,
    BrandName,
    CategoryId
)
VALUES
(
    50,
    'Nike',
    102
);
GO


/*==============================================================================
    PART 13
    MERCHANT TEST DATA
==============================================================================*/

/*
    Merchant 1001 has:

        BrandId     = 50
        CategoryId  = 201

    Therefore TWO category candidates exist.


    BRAND path:

        Merchant 1001
            ↓
        Nike
            ↓
        Sports Shopping (102)


    MERCHANT path:

        Merchant 1001
            ↓
        Restaurant (201)


    Since configured precedence is:

        BRAND       = 2
        MERCHANT    = 3

    Category 102 should win.
*/

INSERT INTO dbo.Merchant
(
    MerchantId,
    MerchantName,
    BrandId,
    CategoryId
)
VALUES
(
    1001,
    'Demo Merchant',
    50,
    201
);
GO


/*==============================================================================
    PART 14
    MERCHANT OTHER TEST DATA
==============================================================================*/

INSERT INTO dbo.MerchantOther
(
    MerchantOtherId,
    MerchantOtherName,
    BrandId,
    CategoryId
)
VALUES
(
    2001,
    'Demo Merchant Other',
    NULL,
    202
);
GO


/*==============================================================================
    PART 15
    REMAINING TEST DATA
==============================================================================*/

INSERT INTO dbo.CategoryMerchantCategory
(
    CategoryMerchantCategoryId,
    CategoryId
)
VALUES
(
    3001,
    202
);


INSERT INTO dbo.CategoryTransactionType
(
    CategoryTransactionTypeId,
    CategoryId
)
VALUES
(
    4001,
    301
);


INSERT INTO dbo.CategoryExpression
(
    CategoryExpressionId,
    CategoryId
)
VALUES
(
    5001,
    101
);
GO


/*==============================================================================
    PART 16
    CREATE SCALAR FUNCTION
==============================================================================*/

CREATE FUNCTION dbo.ufn_GetCategoryEvaluation
(
    @UserCategoryId                 INT,

    @MerchantId                     INT,

    @MerchantOtherId                INT,

    @CategoryMerchantCategoryId     INT,

    @CategoryTransactionTypeId      INT,

    @CategoryExpressionId           INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN

    /*==========================================================================
        RESULT VARIABLE

        Final JSON is assigned here and returned at the end.
    ==========================================================================*/

    DECLARE @Result NVARCHAR(MAX);



    /*==========================================================================
        PHASE 1
        RESOLVE MERCHANT

        Resolve once.

        We need:

            MerchantName
            Merchant BrandId
            Merchant CategoryId
    ==========================================================================*/

    DECLARE
        @MerchantName          VARCHAR(100),
        @MerchantBrandId       INT,
        @MerchantCategoryId    INT;


    SELECT
        @MerchantName          = M.MerchantName,
        @MerchantBrandId       = M.BrandId,
        @MerchantCategoryId    = M.CategoryId
    FROM dbo.Merchant M
    WHERE M.MerchantId = @MerchantId;



    /*==========================================================================
        PHASE 2
        RESOLVE MERCHANT OTHER
    ==========================================================================*/

    DECLARE
        @MerchantOtherName         VARCHAR(100),
        @MerchantOtherBrandId      INT,
        @MerchantOtherCategoryId   INT;


    SELECT
        @MerchantOtherName         = MO.MerchantOtherName,
        @MerchantOtherBrandId      = MO.BrandId,
        @MerchantOtherCategoryId   = MO.CategoryId
    FROM dbo.MerchantOther MO
    WHERE MO.MerchantOtherId = @MerchantOtherId;



    /*==========================================================================
        PHASE 3
        RESOLVE BRAND

        IMPORTANT:

        This is INTERNAL Brand resolution.

        It does NOT determine whether Brand wins category precedence.


        Current Brand resolution rule:

            1. Merchant.BrandId

            2. If Merchant has no BrandId,
               MerchantOther.BrandId


        This can be changed independently of CategoryPrecedence.
    ==========================================================================*/

    DECLARE
        @BrandId                    INT,
        @BrandName                  VARCHAR(100),
        @BrandCategoryId            INT,

        @BrandResolutionSource      VARCHAR(50),
        @BrandResolutionSourceId    INT;


    IF @MerchantBrandId IS NOT NULL
    BEGIN

        SET @BrandId =
            @MerchantBrandId;

        SET @BrandResolutionSource =
            'MERCHANT';

        SET @BrandResolutionSourceId =
            @MerchantId;

    END

    ELSE IF @MerchantOtherBrandId IS NOT NULL
    BEGIN

        SET @BrandId =
            @MerchantOtherBrandId;

        SET @BrandResolutionSource =
            'MERCHANT_OTHER';

        SET @BrandResolutionSourceId =
            @MerchantOtherId;

    END;



    /*--------------------------------------------------------------------------
        Resolve selected Brand information.

        Brand itself may exist without CategoryId.

        In that case BRAND candidate will exist conceptually,
        but it cannot win because CategoryId is NULL.
    --------------------------------------------------------------------------*/

    SELECT
        @BrandName          = B.BrandName,
        @BrandCategoryId    = B.CategoryId
    FROM dbo.Brand B
    WHERE B.BrandId = @BrandId;



    /*==========================================================================
        PHASE 4
        RESOLVE OTHER CATEGORY CANDIDATES

        Candidate discovery happens BEFORE precedence selection.
    ==========================================================================*/

    DECLARE
        @MerchantCategoryCategoryId   INT,
        @TransactionTypeCategoryId    INT,
        @ExpressionCategoryId         INT;



    /* Merchant Category / MCC */

    SELECT
        @MerchantCategoryCategoryId =
            CMC.CategoryId
    FROM dbo.CategoryMerchantCategory CMC
    WHERE CMC.CategoryMerchantCategoryId =
          @CategoryMerchantCategoryId;



    /* Transaction Type */

    SELECT
        @TransactionTypeCategoryId =
            CTT.CategoryId
    FROM dbo.CategoryTransactionType CTT
    WHERE CTT.CategoryTransactionTypeId =
          @CategoryTransactionTypeId;



    /* Expression */

    SELECT
        @ExpressionCategoryId =
            CE.CategoryId
    FROM dbo.CategoryExpression CE
    WHERE CE.CategoryExpressionId =
          @CategoryExpressionId;



    /*==========================================================================
        PHASE 5
        BUILD CATEGORY EVALUATION DATA

        Temp tables are not used inside the UDF.

        A table variable is used instead.

        This table holds STRUCTURED diagnostic information.

        It does NOT hold final human-readable Reason text.

        That text will be generated only while constructing JSON.
    ==========================================================================*/

    DECLARE @CategoryEvaluation TABLE
    (
        /*--------------------------------------------------------------
            Configured precedence
        --------------------------------------------------------------*/

        DisplayOrder                    INT             NOT NULL,

        SourceCode                      VARCHAR(50)     NOT NULL,

        SourceDisplayName               VARCHAR(100)    NOT NULL,


        /*--------------------------------------------------------------
            Explicit source IDs
        --------------------------------------------------------------*/

        UserCategoryId                  INT             NULL,

        MerchantId                      INT             NULL,

        MerchantOtherId                 INT             NULL,

        BrandId                         INT             NULL,

        CategoryMerchantCategoryId      INT             NULL,

        CategoryTransactionTypeId       INT             NULL,

        CategoryExpressionId            INT             NULL,


        /*--------------------------------------------------------------
            Source names
        --------------------------------------------------------------*/

        MerchantName                    VARCHAR(100)    NULL,

        MerchantOtherName               VARCHAR(100)    NULL,

        BrandName                       VARCHAR(100)    NULL,


        /*--------------------------------------------------------------
            Brand diagnostic information
        --------------------------------------------------------------*/

        BrandResolutionSource           VARCHAR(50)     NULL,

        BrandResolutionSourceId         INT             NULL,


        /*--------------------------------------------------------------
            Candidate category
        --------------------------------------------------------------*/

        CategoryId                      INT             NULL
    );



    /*==========================================================================
        PHASE 6
        BUILD ONE ROW FOR EVERY CONFIGURED PRECEDENCE

        dbo.CategoryPrecedence drives this query.

        This means DisplayOrder changes do NOT require changes here.
    ==========================================================================*/

    INSERT INTO @CategoryEvaluation
    (
        DisplayOrder,
        SourceCode,
        SourceDisplayName,

        UserCategoryId,

        MerchantId,
        MerchantOtherId,

        BrandId,

        CategoryMerchantCategoryId,
        CategoryTransactionTypeId,
        CategoryExpressionId,

        MerchantName,
        MerchantOtherName,
        BrandName,

        BrandResolutionSource,
        BrandResolutionSourceId,

        CategoryId
    )
    SELECT
        CP.DisplayOrder,

        CP.SourceCode,

        CP.SourceDisplayName,


        /*======================================================================
            USER INPUT
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'USER'
                THEN @UserCategoryId
        END,


        /*======================================================================
            MERCHANT ID

            BRAND also receives MerchantId when its Brand was resolved
            through Merchant.
        ======================================================================*/

        CASE

            WHEN CP.SourceCode = 'MERCHANT'
                THEN @MerchantId

            WHEN CP.SourceCode = 'BRAND'
                 AND @BrandResolutionSource = 'MERCHANT'
                THEN @MerchantId

        END,


        /*======================================================================
            MERCHANT OTHER ID
        ======================================================================*/

        CASE

            WHEN CP.SourceCode = 'MERCHANT_OTHER'
                THEN @MerchantOtherId

            WHEN CP.SourceCode = 'BRAND'
                 AND @BrandResolutionSource = 'MERCHANT_OTHER'
                THEN @MerchantOtherId

        END,


        /*======================================================================
            BRAND ID
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'BRAND'
                THEN @BrandId
        END,


        /*======================================================================
            MERCHANT CATEGORY / MCC ID
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'MERCHANT_CATEGORY'
                THEN @CategoryMerchantCategoryId
        END,


        /*======================================================================
            TRANSACTION TYPE ID
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'TRANSACTION_TYPE'
                THEN @CategoryTransactionTypeId
        END,


        /*======================================================================
            EXPRESSION ID
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'EXPRESSION'
                THEN @CategoryExpressionId
        END,


        /*======================================================================
            MERCHANT NAME
        ======================================================================*/

        CASE

            WHEN CP.SourceCode = 'MERCHANT'
                THEN @MerchantName

            WHEN CP.SourceCode = 'BRAND'
                 AND @BrandResolutionSource = 'MERCHANT'
                THEN @MerchantName

        END,


        /*======================================================================
            MERCHANT OTHER NAME
        ======================================================================*/

        CASE

            WHEN CP.SourceCode = 'MERCHANT_OTHER'
                THEN @MerchantOtherName

            WHEN CP.SourceCode = 'BRAND'
                 AND @BrandResolutionSource = 'MERCHANT_OTHER'
                THEN @MerchantOtherName

        END,


        /*======================================================================
            BRAND NAME
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'BRAND'
                THEN @BrandName
        END,


        /*======================================================================
            BRAND RESOLUTION SOURCE
        ======================================================================*/

        CASE
            WHEN CP.SourceCode = 'BRAND'
                THEN @BrandResolutionSource
        END,


        CASE
            WHEN CP.SourceCode = 'BRAND'
                THEN @BrandResolutionSourceId
        END,


        /*======================================================================
            CATEGORY CANDIDATE

            THIS IS IMPORTANT.

            This CASE only says:

                "What CategoryId did this source produce?"

            It does NOT decide whether it wins.
        ======================================================================*/

        CASE CP.SourceCode

            WHEN 'USER'
                THEN @UserCategoryId

            WHEN 'BRAND'
                THEN @BrandCategoryId

            WHEN 'MERCHANT'
                THEN @MerchantCategoryId

            WHEN 'MERCHANT_OTHER'
                THEN @MerchantOtherCategoryId

            WHEN 'MERCHANT_CATEGORY'
                THEN @MerchantCategoryCategoryId

            WHEN 'TRANSACTION_TYPE'
                THEN @TransactionTypeCategoryId

            WHEN 'EXPRESSION'
                THEN @ExpressionCategoryId

        END


    FROM dbo.CategoryPrecedence CP;



    /*==========================================================================
        PHASE 7
        DETERMINE WINNER

        The first successful category according to configured DisplayOrder wins.

        Example:

            USER        1   NULL
            BRAND       2   102
            MERCHANT    3   201

        Result:

            WinningDisplayOrder = 2
    ==========================================================================*/

    DECLARE @WinningDisplayOrder INT;


    SELECT
        @WinningDisplayOrder =
            MIN(E.DisplayOrder)
    FROM @CategoryEvaluation E
    WHERE E.CategoryId IS NOT NULL;



    /*==========================================================================
        PHASE 8
        BUILD FINAL JSON

        JSON structure:

        {
            "Input": {...},

            "SelectedCategory": {...},

            "EvaluationTrace": [...]
        }
    ==========================================================================*/

    SELECT
        @Result =
        (
            SELECT


                /*================================================================
                    SECTION 1
                    INPUT

                    Useful in simulation mode.

                    The returned JSON itself shows exactly what was simulated.
                ================================================================*/

                JSON_QUERY
                (
                    (
                        SELECT
                            @UserCategoryId
                                AS UserCategoryId,

                            @MerchantId
                                AS MerchantId,

                            @MerchantOtherId
                                AS MerchantOtherId,

                            @CategoryMerchantCategoryId
                                AS CategoryMerchantCategoryId,

                            @CategoryTransactionTypeId
                                AS CategoryTransactionTypeId,

                            @CategoryExpressionId
                                AS CategoryExpressionId

                        FOR JSON PATH,
                                 WITHOUT_ARRAY_WRAPPER,
                                 INCLUDE_NULL_VALUES
                    )
                ) AS Input,


                /*================================================================
                    SECTION 2
                    SELECTED CATEGORY
                ================================================================*/

                JSON_QUERY
                (
                    (
                        SELECT

                            /* Category */

                            E.CategoryId,

                            C.CategoryNameEnglish,

                            C.CategoryNameArabic,


                            /* Parent Category */

                            C.ParentCategoryId,

                            PC.CategoryNameEnglish
                                AS ParentCategoryNameEnglish,

                            PC.CategoryNameArabic
                                AS ParentCategoryNameArabic,


                            /* Decision information */

                            E.DisplayOrder
                                AS SelectedPrecedence,

                            E.SourceCode
                                AS SelectedBy,

                            E.SourceDisplayName
                                AS SelectedByDisplayName,


                            /*====================================================
                                CATEGORY EVALUATION PATH

                                Diagnostic only.

                                DO NOT parse this value later to drive
                                business logic.
                            ====================================================*/

                            CASE E.SourceCode


                                /*----------------------------------------------
                                    USER
                                ----------------------------------------------*/

                                WHEN 'USER'
                                THEN
                                    CONCAT
                                    (
                                        'USER',

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    BRAND

                                    Example:

                                    MERCHANT:1001 [Demo Merchant]
                                    -> BRAND:50 [Nike]
                                    -> CATEGORY:102 [Sports Shopping]
                                ----------------------------------------------*/

                                WHEN 'BRAND'
                                THEN
                                    CONCAT
                                    (
                                        E.BrandResolutionSource,

                                        ':',
                                        E.BrandResolutionSourceId,


                                        CASE

                                            WHEN E.BrandResolutionSource =
                                                 'MERCHANT'
                                            THEN
                                                CONCAT
                                                (
                                                    ' [',
                                                    E.MerchantName,
                                                    ']'
                                                )


                                            WHEN E.BrandResolutionSource =
                                                 'MERCHANT_OTHER'
                                            THEN
                                                CONCAT
                                                (
                                                    ' [',
                                                    E.MerchantOtherName,
                                                    ']'
                                                )

                                        END,


                                        ' -> BRAND:',
                                        E.BrandId,

                                        ' [',
                                        E.BrandName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    MERCHANT
                                ----------------------------------------------*/

                                WHEN 'MERCHANT'
                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT:',
                                        E.MerchantId,

                                        ' [',
                                        E.MerchantName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    MERCHANT OTHER
                                ----------------------------------------------*/

                                WHEN 'MERCHANT_OTHER'
                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT_OTHER:',
                                        E.MerchantOtherId,

                                        ' [',
                                        E.MerchantOtherName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    MERCHANT CATEGORY / MCC
                                ----------------------------------------------*/

                                WHEN 'MERCHANT_CATEGORY'
                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT_CATEGORY:',
                                        E.CategoryMerchantCategoryId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    TRANSACTION TYPE
                                ----------------------------------------------*/

                                WHEN 'TRANSACTION_TYPE'
                                THEN
                                    CONCAT
                                    (
                                        'TRANSACTION_TYPE:',
                                        E.CategoryTransactionTypeId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /*----------------------------------------------
                                    EXPRESSION
                                ----------------------------------------------*/

                                WHEN 'EXPRESSION'
                                THEN
                                    CONCAT
                                    (
                                        'EXPRESSION:',
                                        E.CategoryExpressionId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )

                            END AS CategoryEvaluationPath


                        FROM @CategoryEvaluation E


                        INNER JOIN dbo.Category C
                            ON C.CategoryId = E.CategoryId


                        LEFT JOIN dbo.Category PC
                            ON PC.CategoryId = C.ParentCategoryId


                        WHERE
                            E.DisplayOrder =
                            @WinningDisplayOrder


                        FOR JSON PATH,
                                 WITHOUT_ARRAY_WRAPPER
                    )
                ) AS SelectedCategory,


                /*================================================================
                    SECTION 3
                    COMPLETE EVALUATION TRACE
                ================================================================*/

                JSON_QUERY
                (
                    (
                        SELECT

                            /*--------------------------------------------------
                                Configuration
                            --------------------------------------------------*/

                            E.DisplayOrder
                                AS Precedence,

                            E.SourceCode
                                AS Source,

                            E.SourceDisplayName,


                            /*--------------------------------------------------
                                USER CATEGORY
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.UserCategoryId

                            END AS UserCategoryId,


                            /*--------------------------------------------------
                                MERCHANT
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.MerchantId

                            END AS MerchantId,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.MerchantName

                            END AS MerchantName,


                            /*--------------------------------------------------
                                MERCHANT OTHER
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.MerchantOtherId

                            END AS MerchantOtherId,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.MerchantOtherName

                            END AS MerchantOtherName,


                            /*--------------------------------------------------
                                BRAND
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.BrandId

                            END AS BrandId,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.BrandName

                            END AS BrandName,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.BrandResolutionSource

                            END AS BrandResolutionSource,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.BrandResolutionSourceId

                            END AS BrandResolutionSourceId,


                            /*--------------------------------------------------
                                MCC
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.CategoryMerchantCategoryId

                            END AS CategoryMerchantCategoryId,


                            /*--------------------------------------------------
                                TRANSACTION TYPE
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.CategoryTransactionTypeId

                            END AS CategoryTransactionTypeId,


                            /*--------------------------------------------------
                                EXPRESSION
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.CategoryExpressionId

                            END AS CategoryExpressionId,


                            /*--------------------------------------------------
                                CATEGORY
                            --------------------------------------------------*/

                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN E.CategoryId

                            END AS CategoryId,


                            CASE

                                WHEN @WinningDisplayOrder IS NULL
                                     OR
                                     E.DisplayOrder <= @WinningDisplayOrder

                                THEN C.CategoryNameEnglish

                            END AS CategoryNameEnglish,


                            /*==================================================
                                STATUS
                            ==================================================*/

                            CASE


                                /*----------------------------------------------
                                    No source produced any category.

                                    Therefore every configured precedence
                                    was effectively checked.
                                ----------------------------------------------*/

                                WHEN @WinningDisplayOrder IS NULL
                                THEN
                                    'NOT_FOUND'


                                /*----------------------------------------------
                                    This precedence was before the winner.

                                    Therefore it was evaluated but did not
                                    identify CategoryId.
                                ----------------------------------------------*/

                                WHEN E.DisplayOrder < @WinningDisplayOrder
                                THEN
                                    'NOT_FOUND'


                                /*----------------------------------------------
                                    First successful precedence.
                                ----------------------------------------------*/

                                WHEN E.DisplayOrder = @WinningDisplayOrder
                                THEN
                                    'SELECTED'


                                /*----------------------------------------------
                                    Lower precedence.

                                    Categorization decision already finished.
                                ----------------------------------------------*/

                                ELSE
                                    'NOT_EVALUATED'

                            END AS Status,


                            /*==================================================
                                CATEGORY EVALUATION PATH

                                Only generated when a category was actually
                                found at an evaluated precedence.
                            ==================================================*/

                            CASE


                                /* Lower precedence was never logically reached */

                                WHEN @WinningDisplayOrder IS NOT NULL
                                     AND
                                     E.DisplayOrder > @WinningDisplayOrder

                                THEN NULL


                                /* Evaluated, but no CategoryId */

                                WHEN E.CategoryId IS NULL

                                THEN NULL


                                /* USER */

                                WHEN E.SourceCode = 'USER'

                                THEN
                                    CONCAT
                                    (
                                        'USER',

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* BRAND */

                                WHEN E.SourceCode = 'BRAND'

                                THEN
                                    CONCAT
                                    (
                                        E.BrandResolutionSource,

                                        ':',
                                        E.BrandResolutionSourceId,


                                        CASE

                                            WHEN E.BrandResolutionSource =
                                                 'MERCHANT'
                                            THEN
                                                CONCAT
                                                (
                                                    ' [',
                                                    E.MerchantName,
                                                    ']'
                                                )


                                            WHEN E.BrandResolutionSource =
                                                 'MERCHANT_OTHER'
                                            THEN
                                                CONCAT
                                                (
                                                    ' [',
                                                    E.MerchantOtherName,
                                                    ']'
                                                )

                                        END,


                                        ' -> BRAND:',
                                        E.BrandId,

                                        ' [',
                                        E.BrandName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* MERCHANT */

                                WHEN E.SourceCode = 'MERCHANT'

                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT:',
                                        E.MerchantId,

                                        ' [',
                                        E.MerchantName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* MERCHANT OTHER */

                                WHEN E.SourceCode = 'MERCHANT_OTHER'

                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT_OTHER:',
                                        E.MerchantOtherId,

                                        ' [',
                                        E.MerchantOtherName,
                                        ']',


                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* MCC */

                                WHEN E.SourceCode = 'MERCHANT_CATEGORY'

                                THEN
                                    CONCAT
                                    (
                                        'MERCHANT_CATEGORY:',
                                        E.CategoryMerchantCategoryId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* Transaction Type */

                                WHEN E.SourceCode = 'TRANSACTION_TYPE'

                                THEN
                                    CONCAT
                                    (
                                        'TRANSACTION_TYPE:',
                                        E.CategoryTransactionTypeId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )


                                /* Expression */

                                WHEN E.SourceCode = 'EXPRESSION'

                                THEN
                                    CONCAT
                                    (
                                        'EXPRESSION:',
                                        E.CategoryExpressionId,

                                        ' -> CATEGORY:',
                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,
                                        ']'
                                    )

                            END AS CategoryEvaluationPath,


                            /*==================================================
                                HUMAN-READABLE REASON

                                Diagnostic presentation only.

                                Never parse this field to make decisions.
                            ==================================================*/

                            CASE


                                /*----------------------------------------------
                                    No winner anywhere
                                ----------------------------------------------*/

                                WHEN @WinningDisplayOrder IS NULL

                                THEN
                                    CONCAT
                                    (
                                        E.SourceDisplayName,

                                        ' was evaluated but no category ',
                                        'was identified.'
                                    )


                                /*----------------------------------------------
                                    Evaluated but unsuccessful
                                ----------------------------------------------*/

                                WHEN E.DisplayOrder < @WinningDisplayOrder

                                THEN
                                    CONCAT
                                    (
                                        E.SourceDisplayName,

                                        ' was evaluated but no category ',
                                        'was identified.'
                                    )


                                /*----------------------------------------------
                                    BRAND won
                                ----------------------------------------------*/

                                WHEN E.DisplayOrder = @WinningDisplayOrder
                                     AND
                                     E.SourceCode = 'BRAND'

                                THEN
                                    CONCAT
                                    (
                                        'Brand was resolved through ',

                                        E.BrandResolutionSource,

                                        ' ',

                                        E.BrandResolutionSourceId,

                                        '. BrandId ',

                                        E.BrandId,

                                        ' [',
                                        E.BrandName,
                                        '] identified CategoryId ',

                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,

                                        '] and was selected based on ',
                                        'configured precedence.'
                                    )


                                /*----------------------------------------------
                                    Any other source won
                                ----------------------------------------------*/

                                WHEN E.DisplayOrder = @WinningDisplayOrder

                                THEN
                                    CONCAT
                                    (
                                        E.SourceDisplayName,

                                        ' identified CategoryId ',

                                        E.CategoryId,

                                        ' [',
                                        C.CategoryNameEnglish,

                                        '] and was selected based on ',
                                        'configured precedence.'
                                    )


                                /*----------------------------------------------
                                    Lower precedence
                                ----------------------------------------------*/

                                ELSE
                                    CONCAT
                                    (
                                        E.SourceDisplayName,

                                        ' was not evaluated because a category ',
                                        'had already been selected by a higher ',
                                        'precedence.'
                                    )

                            END AS Reason


                        FROM @CategoryEvaluation E


                        LEFT JOIN dbo.Category C
                            ON C.CategoryId = E.CategoryId


                        ORDER BY
                            E.DisplayOrder


                        FOR JSON PATH,
                                 INCLUDE_NULL_VALUES
                    )
                ) AS EvaluationTrace


            FOR JSON PATH,
                     WITHOUT_ARRAY_WRAPPER
        );


    /*==========================================================================
        PHASE 9
        RETURN JSON
    ==========================================================================*/

    RETURN @Result;

END;
GO


/*==============================================================================
    PART 17
    TEST FUNCTION
==============================================================================*/

/*
    Expected:

        USER
            NOT_FOUND

        BRAND
            SELECTED

        MERCHANT onward
            NOT_EVALUATED

    Selected Category:

        102 - Sports Shopping

    because:

        Merchant 1001
            ↓
        Brand 50 / Nike
            ↓
        Category 102

    and BRAND precedence is currently 2.
*/

SELECT
    dbo.ufn_GetCategoryEvaluation
    (
        NULL,       -- UserCategoryId

        1001,       -- MerchantId

        2001,       -- MerchantOtherId

        3001,       -- CategoryMerchantCategoryId

        4001,       -- CategoryTransactionTypeId

        5001        -- CategoryExpressionId
    ) AS CategoryEvaluationJson;
GO
