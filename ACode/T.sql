SELECT
    CONVERT
    (
        VARCHAR(10),
        CASE
            WHEN @A > 0 AND @B > 0 THEN 'SUCCESS'
            WHEN @A = 0 OR @B = 0 THEN 'FAILED'
            ELSE 'OTHER'
        END
    );
