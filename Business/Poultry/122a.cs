public string Emit(
    IList<TSqlParserToken> tokens,
    LayoutPlan plan)
{
    if (tokens == null)
    {
        throw new ArgumentNullException("tokens");
    }

    if (plan == null)
    {
        throw new ArgumentNullException("plan");
    }

    Dictionary<int, LayoutInstruction> instructions =
        plan.Instructions
            .GroupBy(x => x.TokenIndex)
            .ToDictionary(
                x => x.Key,
                x => x.Last());

    StringBuilder output =
        new StringBuilder();

    for (int i = 0; i < tokens.Count; i++)
    {
        TSqlParserToken token =
            tokens[i];

        LayoutInstruction instruction;

        int previousMeaningful =
            FindPreviousNonWhitespaceToken(
                tokens,
                i - 1);

        bool followsDeveloperComment =
            previousMeaningful >= 0 &&
            IsCommentToken(
                tokens[previousMeaningful]);

        /*
         * A SQL token that follows a developer comment
         * on another physical line may still receive its
         * normal formatter layout instruction.
         *
         * Example:
         *
         * -- Customer lookup
         *     INNER JOIN ...
         *
         * A SQL token on the same physical line as the
         * comment remains protected.
         */
        bool hasNewLineAfterComment =
            followsDeveloperComment &&
            HasNewLineBetween(
                tokens,
                previousMeaningful + 1,
                i - 1);

        bool followsDeveloperCommentSameLine =
            followsDeveloperComment &&
            !hasNewLineAfterComment;

        if (instructions.TryGetValue(
                i,
                out instruction))
        {
            if (!IsCommentToken(token) &&
                !followsDeveloperCommentSameLine)
            {
                ApplyInstruction(
                    output,
                    instruction);
            }
        }

        if (token.TokenType ==
            TSqlTokenType.EndOfFile)
        {
            continue;
        }

        if (token.TokenType ==
            TSqlTokenType.WhiteSpace)
        {
            int previous =
                FindPreviousNonWhitespaceToken(
                    tokens,
                    i - 1);

            int next =
                FindNextNonWhitespaceToken(
                    tokens,
                    i + 1);

            TSqlParserToken previousToken =
                previous >= 0
                    ? tokens[previous]
                    : null;

            TSqlParserToken nextToken =
                next >= 0
                    ? tokens[next]
                    : null;

            /*
             * Developer-comment whitespace is source owned.
             *
             * Preserve the whitespace token exactly.
             */
            if (IsCommentToken(previousToken) ||
                IsCommentToken(nextToken))
            {
                output.Append(
                    token.Text);

                continue;
            }

            /*
             * If the upcoming SQL token has a layout
             * instruction, that instruction owns the
             * whitespace before the token.
             */
            if (next >= 0 &&
                instructions.ContainsKey(next))
            {
                continue;
            }

            /*
             * Existing source newline.
             */
            if (ContainsNewLine(
                    token.Text))
            {
                /*
                 * When the previous token already owns
                 * layout, normalize the gap according to
                 * SQL-token spacing rules.
                 */
                if (previous >= 0 &&
                    instructions.ContainsKey(
                        previous))
                {
                    if (ShouldInsertSpace(
                            previousToken,
                            nextToken))
                    {
                        RemoveTrailingWhitespace(
                            output);

                        if (output.Length > 0)
                        {
                            output.Append(' ');
                        }
                    }
                    else
                    {
                        RemoveTrailingWhitespace(
                            output);
                    }

                    continue;
                }

                /*
                 * Otherwise preserve the original newline.
                 */
                output.Append(
                    token.Text);

                continue;
            }

            if (previous < 0 ||
                next < 0)
            {
                continue;
            }

            /*
             * Normalize unnecessary horizontal whitespace
             * between SQL tokens that remain on the same
             * output line.
             */
            if (ShouldInsertSpace(
                    previousToken,
                    nextToken))
            {
                RemoveTrailingWhitespace(
                    output);

                if (output.Length > 0)
                {
                    output.Append(' ');
                }
            }
            else
            {
                RemoveTrailingWhitespace(
                    output);
            }

            continue;
        }

        output.Append(
            token.Text);
    }

    return output.ToString();
}
