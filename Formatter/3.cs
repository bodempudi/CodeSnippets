using SqlFormatter.Core.Configuration;

namespace SqlFormatter.Core.Services
{
	public sealed class SqlKeywordService
	{
		private readonly SqlFormattingOptions _options;

		public SqlKeywordService(SqlFormattingOptions options)
		{
			_options = options;
		}

		public string Kw(string text)
		{
			return _options.UppercaseKeywords
				? text.ToUpperInvariant()
				: text.ToLowerInvariant();
		}
	}
}
