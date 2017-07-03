CREATE TABLE dbo.SETExactAbortTest(
id int primary key,
name varchar(50),
sal int
);

SET XACT_ABORT ON;
SET XACT_ABORT OFF;

BEGIN TRY
    BEGIN TRAN 
        INSERT INTO dbo.SETExactAbortTest values(2,'venkat',1000);
        INSERT INTO dbo.SETExactAbortTest values(1,'venkat',1000);
    COMMIT TRAN
END TRY
BEGIN CATCH
    ROLLBACK TRAN
END CATCH

SELECT * FROM dbo.SETExactAbortTest;


RAISERROR('This is raise error demonstration, severity 16',16,1);


RAISERROR('This is raise error demonstration, severity 10',10,1);


RAISERROR('This is raise error demonstration, severity 11',11,1);


RAISERROR('This is raise error demonstration, severity 19',19,1) WITH LOG;


RAISERROR('This is raise error demonstration, severity 20',20,1) WITH LOG;


DECLARE @ErrorMsg VARCHAR(100)='This is raise error demonstration, severity 11';
--maximum error mesage length should be 2047 characters
RAISERROR(@ErrorMsg,11,1);

-- character substituion
-- d or i for signed integer
-- o for unsighed octal
-- s for string
-- u for unsigned integer
-- x or X for unsigned hexa decimal

RAISERROR('Could not find object "%s"',13,1,'dbo.SETExactAbortTest');


INSERT INTO dbo.SETExactAbortTest VALUES(1,'NANI',4000);



SELECT * FROM sys.messages a where a.text like '%PRIMARY KEY%' ;
SELECT * FROM sys.messages a where a.message_id=2627;

Violation of %ls constraint '%.*ls'. Cannot insert duplicate key in object '%.*ls'. The duplicate key value is %ls.
Violation of PRIMARY KEY constraint 'PK__SETExact__3213E83F287051E9'. Cannot insert duplicate key in object 'dbo.SETExactAbortTest'. The duplicate key value is (1).
