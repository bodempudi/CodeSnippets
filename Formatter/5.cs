using SqlFormatter.Core.Configuration;
using SqlFormatter.Core.Services;
using SqlFormatter.Core.Writing;

namespace SqlFormatter.Core
{
	public sealed class SqlFormatterContext
	{
		public SqlFormattingOptions Options { get; }
		public SqlFormatWriter Writer { get; }
		public SqlKeywordService Keywords { get; }
		public SqlGenerationService Generator { get; }

		public SqlFormatterContext(SqlFormattingOptions options)
		{
			Options = options;
			Writer = new SqlFormatWriter(options);
			Keywords = new SqlKeywordService(options);
			Generator = new SqlGenerationService();
		}
	}
}
