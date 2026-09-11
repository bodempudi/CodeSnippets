public int FindPreviousNonWhitespaceToken(
    int startIndex)
{
    if (startIndex >= _tokens.Count)
    {
        startIndex = _tokens.Count - 1;
    }

    for (int i = startIndex;
         i >= 0;
         i--)
    {
        if (_tokens[i].TokenType !=
            TSqlTokenType.WhiteSpace)
        {
            return i;
        }
    }

    return -1;
}
