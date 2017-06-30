create PROC dbo.ErrorMessageTestProc
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @this_proc_name sysname = QUOTENAME(OBJECT_SCHEMA_NAME(@@PROCID))+'.'+QUOTENAME(OBJECT_NAME(@@PROCID))
    BEGIN TRY
        RAISERROR('I Have raised this error',21,1);
    END TRY
    BEGIN CATCH
        PRINT 'Error was raised in Stored Procedure "'+@this_proc_name+'" at line number '+CAST(ERROR_LINE() AS VARCHAR(10))+' and the error message is "'+ERROR_MESSAGE()+'"';
    END CATCH
END
