private const int ThreadCount = 8;
private const int BatchSize = 10000;

private DateTime _postDate = DateTime.MinValue;
private int _threadId = 0;
private int _rowCount = 0;

public override void Input0_ProcessInputRow(Input0Buffer Row)
{
    // New PostDate
    if (Row.TransactionPostDate.Date != _postDate)
    {
        _postDate = Row.TransactionPostDate.Date;

        _threadId = (_threadId % ThreadCount) + 1;

        _rowCount = 0;
    }

    _rowCount++;

    Row.ThreadId = _threadId;
    Row.BatchNumber = ((_rowCount - 1) / BatchSize) + 1;
}
