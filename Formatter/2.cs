using System.Text;
using SqlFormatter.Core.Configuration;

namespace SqlFormatter.Core.Writing
{
	public sealed class SqlFormatWriter
	{
		private readonly StringBuilder _sb = new StringBuilder();
		private readonly SqlFormattingOptions _options;

		public SqlFormatWriter(SqlFormattingOptions options)
		{
			_options = options;
		}

		public void WriteLine(int indent, string text)
		{
			for (int i = 0; i < indent; i++)
				_sb.Append(_options.IndentToken);

			_sb.AppendLine(text);
		}

		public void WriteBlankLine()
		{
			_sb.AppendLine();
		}

		public override string ToString()
		{
			return _sb.ToString().TrimEnd();
		}
	}
}
