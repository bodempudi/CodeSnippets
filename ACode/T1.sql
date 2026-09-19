-- 1. ISNULL in SET
SET @Result = ISNULL(@Value, 0)

-- 2. ISNULL in SELECT
SELECT @Result = ISNULL(@Value, 0)

-- 3. COALESCE
SELECT COALESCE(@A, @B, 0)

-- 4. CAST ordinary expression
SELECT CAST(@A AS VARCHAR(10))

-- 5. CONVERT ordinary expression
SELECT CONVERT(VARCHAR(10), @A)

-- 6. SUM ordinary expression
SELECT SUM(Amount)

-- 7. Function containing CASE
SELECT SUM(CASE WHEN @A > 0 THEN Amount ELSE 0 END)

-- 8. ISNULL containing CASE
SELECT ISNULL(CASE WHEN @A > 0 THEN @B ELSE 0 END, 0)
