private const int ThreadCount = 8;
private const int BatchSize = 10000;

private int _nextThreadId = 0;

private Dictionary<DateTime, int> _postDateThread
    = new Dictionary<DateTime, int>();

private Dictionary<DateTime, long> _postDateRowCount
    = new Dictionary<DateTime, long>();

public override void Input0_ProcessInputRow(Input0Buffer Row)
{
    DateTime postDate = Row.TransactionHubDate.Date;

    if (!_postDateThread.ContainsKey(postDate))
    {
        _nextThreadId = (_nextThreadId % ThreadCount) + 1;

        _postDateThread.Add(postDate, _nextThreadId);
        _postDateRowCount.Add(postDate, 0);
    }

    _postDateRowCount[postDate]++;

    Row.ThreadID = _postDateThread[postDate];

    Row.BatchNumber =
        (int)((_postDateRowCount[postDate] - 1) / BatchSize) + 1;
}
