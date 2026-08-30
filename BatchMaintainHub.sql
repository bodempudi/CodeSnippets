CREATE OR ALTER PROCEDURE dbo.usp_UpdateTransactionHub_BANCS
(
    @ExecutionMode VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ---------------------------------------------------------------
    -- Maximum only 1000 IDs
    ---------------------------------------------------------------
    DECLARE @Batch TABLE
    (
        StageID BIGINT NOT NULL PRIMARY KEY
    );

    DECLARE @BatchCount INT;


    WHILE 1 = 1
    BEGIN
        BEGIN TRY

            BEGIN TRAN;


            -------------------------------------------------------
            -- 1. Pick exactly the next 1000 U records
            -------------------------------------------------------
            DELETE FROM @Batch;

            INSERT INTO @Batch
            (
                StageID
            )
            SELECT TOP (1000)
                   S.StageID
            FROM dbo.Stage_TransactionHub_BANCS AS S
            WHERE S.DinarwiseHealingType = 'U'
            ORDER BY S.StageID;


            SET @BatchCount = @@ROWCOUNT;


            -------------------------------------------------------
            -- Nothing left
            -------------------------------------------------------
            IF @BatchCount = 0
            BEGIN
                COMMIT;
                BREAK;
            END;


            -------------------------------------------------------
            -- 2. EOD / ADHOC
            --    Update all mutable columns
            -------------------------------------------------------
            IF @ExecutionMode IN ('EOD', 'ADHOC')
            BEGIN

                UPDATE TH
                SET
                      TH.TransactionDate =
                          S.TransactionDate

                    , TH.TransactionDateTime =
                          S.TransactionDateTime

                    , TH.TransactionAmount =
                          S.TransactionAmount

                    , TH.TransactionAmountLCY =
                          S.TransactionAmountLCY

                    , TH.DebitCreditIndicator =
                          S.DebitCreditIndicator

                    , TH.CurrencyCode =
                          S.CurrencyCode

                    , TH.TransactionDescription =
                          S.TransactionDescription

                    , TH.MerchantName =
                          S.MerchantName

                    , TH.CategoryID =
                          S.CategoryID

                    , TH.MerchantID =
                          S.MerchantID

                    , TH.MerchantExpressionID =
                          S.MerchantExpressionID

                    , TH.CategoryExpressionID =
                          S.CategoryExpressionID

                    , TH.UserCategoryID =
                          S.UserCategoryID

                    -- ProductNumber intentionally not updated

                FROM @Batch AS B

                INNER JOIN dbo.Stage_TransactionHub_BANCS AS S
                    ON S.StageID = B.StageID

                INNER JOIN dbo.TransactionHub AS TH
                    ON  TH.TransactionHubDate =
                            S.TransactionHubDate

                    AND TH.LineOfBusinessID =
                            S.LineOfBusinessID

                    AND TH.TransactionIdentifier =
                            S.TransactionIdentifier;

            END;


            -------------------------------------------------------
            -- 3. RECATEGORY
            --    Only update category fields that actually changed
            -------------------------------------------------------
            ELSE IF @ExecutionMode = 'RECATEGORY'
            BEGIN

                UPDATE TH
                SET
                      TH.CategoryID =
                          S.CategoryID

                    , TH.MerchantID =
                          S.MerchantID

                    , TH.MerchantExpressionID =
                          S.MerchantExpressionID

                    , TH.CategoryExpressionID =
                          S.CategoryExpressionID

                    , TH.UserCategoryID =
                          S.UserCategoryID

                FROM @Batch AS B

                INNER JOIN dbo.Stage_TransactionHub_BANCS AS S
                    ON S.StageID = B.StageID

                INNER JOIN dbo.TransactionHub AS TH
                    ON  TH.TransactionHubDate =
                            S.TransactionHubDate

                    AND TH.LineOfBusinessID =
                            S.LineOfBusinessID

                    AND TH.TransactionIdentifier =
                            S.TransactionIdentifier

                ---------------------------------------------------
                -- NULL-safe change detection
                ---------------------------------------------------
                WHERE EXISTS
                (
                    SELECT
                          S.CategoryID
                        , S.MerchantID
                        , S.MerchantExpressionID
                        , S.CategoryExpressionID
                        , S.UserCategoryID

                    EXCEPT

                    SELECT
                          TH.CategoryID
                        , TH.MerchantID
                        , TH.MerchantExpressionID
                        , TH.CategoryExpressionID
                        , TH.UserCategoryID
                );

            END;
            ELSE
            BEGIN
                THROW 50001, 'Invalid ExecutionMode.', 1;
            END;


            -------------------------------------------------------
            -- 4. Mark EXACTLY those 1000 stage rows processed
            --
            -- Important:
            -- Even RECATEGORY rows where values were already same
            -- become X because we have evaluated them successfully.
            -------------------------------------------------------
            UPDATE S
            SET S.DinarwiseHealingType = 'X'
            FROM dbo.Stage_TransactionHub_BANCS AS S
            INNER JOIN @Batch AS B
                ON B.StageID = S.StageID
            WHERE S.DinarwiseHealingType = 'U';


            -------------------------------------------------------
            -- 5. Commit this small batch
            -------------------------------------------------------
            COMMIT;

        END TRY

        BEGIN CATCH

            IF @@TRANCOUNT > 0
                ROLLBACK;

            THROW;

        END CATCH;
    END;
END;
GO
