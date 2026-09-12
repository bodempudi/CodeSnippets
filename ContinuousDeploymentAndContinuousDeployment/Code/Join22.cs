SELECT
    T.TransactionId,
    T.CustomerId,
    C.CustomerName,
    A.TotalAmount
FROM dbo.Transactions AS T
INNER JOIN dbo.Customers AS C
    ON T.CustomerId = C.CustomerId
    AND (
        C.IsActive = 1
        OR C.CustomerType = 'VIP'
    )
LEFT JOIN
(
    SELECT
        TransactionId,
        SUM(Amount) AS TotalAmount
    FROM dbo.TransactionDetails
    GROUP BY TransactionId
) AS A
    ON T.TransactionId = A.TransactionId
WHERE T.TransactionStatus = 'A';
