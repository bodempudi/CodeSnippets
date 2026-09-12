SELECT
    T.TransactionId,
    T.CustomerId,
    C.CustomerName,
    A.AccountNumber,
    B.BranchName
FROM dbo.Transactions AS T
INNER JOIN dbo.Customers AS C
    ON T.CustomerId = C.CustomerId
LEFT JOIN dbo.Accounts AS A
    ON T.AccountId = A.AccountId
    AND A.IsActive = 1
INNER JOIN dbo.Branches AS B
    ON A.BranchId = B.BranchId
    AND B.IsActive = 1
WHERE T.TransactionDate >= '2026-01-01'
    AND T.TransactionStatus = 'A';
