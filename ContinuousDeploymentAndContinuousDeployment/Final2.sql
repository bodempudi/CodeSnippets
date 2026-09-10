private Dictionary<DateTime, int> _postDateRowCount;

public override void PreExecute()
{
    base.PreExecute();

    BatchSize = Variables.BatchSize == 0
        ? 10000
        : Variables.BatchSize;

    MaximumNumberOfThreads = Variables.MaximumNumberOfThreads == 0
        ? 8
        : Variables.MaximumNumberOfThreads;

    _postDateRowCount = new Dictionary<DateTime, int>();
}

public override void Input0_ProcessInputRow(Input0Buffer Row)
{
    DateTime postDate = Row.TransactionHubDate.Date;

    // ThreadID directly from PostDate
    int dayNumber = (postDate - new DateTime(2000, 1, 1)).Days;

    Row.ThreadID =
        (dayNumber % MaximumNumberOfThreads) + 1;

    // Row count for this PostDate
    if (!_postDateRowCount.ContainsKey(postDate))
        _postDateRowCount[postDate] = 0;

    _postDateRowCount[postDate]++;

    // BatchNumber for this PostDate
    Row.BatchNumber =
        ((_postDateRowCount[postDate] - 1) / BatchSize) + 1;
}
