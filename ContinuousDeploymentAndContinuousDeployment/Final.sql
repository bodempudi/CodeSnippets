using System;
using System.Collections.Generic;
using Microsoft.SqlServer.Dts.Pipeline.Wrapper;
using Microsoft.SqlServer.Dts.Runtime.Wrapper;

[Microsoft.SqlServer.Dts.Pipeline.SSISScriptComponentEntryPointAttribute]
public class ScriptMain : UserComponent
{
    private int BatchSize = 0;
    private int MaximumNumberOfThreads = 0;

    private int _nextThreadId = 0;

    private Dictionary<DateTime, int> _postDateThreadMap;
    private Dictionary<DateTime, int> _postDateRowCount;


    public override void PreExecute()
    {
        base.PreExecute();

        BatchSize =
            Variables.BatchSize == 0
                ? 10000
                : Variables.BatchSize;

        MaximumNumberOfThreads =
            Variables.MaximumNumberOfThreads == 0
                ? 8
                : Variables.MaximumNumberOfThreads;

        _postDateThreadMap =
            new Dictionary<DateTime, int>();

        _postDateRowCount =
            new Dictionary<DateTime, int>();
    }


    public override void PostExecute()
    {
        base.PostExecute();
    }


    public override void Input0_ProcessInputRow(Input0Buffer Row)
    {
        DateTime postDate = Row.TransactionHubDate.Date;

        int threadId;

        // Assign ThreadID only once for each PostDate
        if (!_postDateThreadMap.TryGetValue(postDate, out threadId))
        {
            _nextThreadId =
                (_nextThreadId % MaximumNumberOfThreads) + 1;

            threadId = _nextThreadId;

            _postDateThreadMap.Add(postDate, threadId);

            _postDateRowCount.Add(postDate, 0);
        }

        // Maintain row count independently for each PostDate
        _postDateRowCount[postDate]++;

        Row.ThreadID = threadId;

        Row.BatchNumber =
            ((_postDateRowCount[postDate] - 1) / BatchSize) + 1;
    }
}
