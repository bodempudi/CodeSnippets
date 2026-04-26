namespace SqlFormatter.Core.Configuration
{
	public sealed class SqlFormattingOptions
	{
		public bool UppercaseKeywords { get; set; } = true;
		public bool CommaFirst { get; set; } = true;
		public bool BreakBeforeBooleanOperator { get; set; } = true;
		public string IndentToken { get; set; } = "\t";
	}
}
