CREATE PROCEDURE dbo.TestCommentFormatting
AS
BEGIN
------------------------------------------------------------
    -- Comment one

        -- Comment two with developer indentation

    DECLARE @A INT; -- Inline comment

    /*
        Multiline developer comment
    */

    SET @A = 1;
END;
