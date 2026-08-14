using ScriptFormatter.Core.Errors;
using ScriptFormatter.Core.Formatting.Custom;
using ScriptFormatter.Core.Review.Models;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace VenkatSQLFormatter
{
    public sealed class SqlErrorPanel : Form
    {
        private readonly Label _titleLabel;

        private readonly ListView _list;

        private readonly ContextMenuStrip _contextMenu;

        private readonly List<SqlErrorInfo> _errors;

        public event Action<int, int> ErrorDoubleClicked;

        public SqlErrorPanel()
        {
            Text =
                "SQL Results";

            _errors =
                new List<SqlErrorInfo>();

            //
            // Dynamic title
            //
            _titleLabel =
                new Label();

            _titleLabel.Dock =
                DockStyle.Top;

            _titleLabel.Height =
                28;

            _titleLabel.Text =
                "SQL Results";

            _titleLabel.TextAlign =
                ContentAlignment.MiddleLeft;

            _titleLabel.Padding =
                new Padding(
                    6,
                    0,
                    0,
                    0);

            _titleLabel.Font =
                new Font(
                    "Segoe UI",
                    9F,
                    FontStyle.Bold);

            //
            // Results ListView
            //
            _list =
                new ListView();

            _list.Dock =
                DockStyle.Fill;

            _list.View =
                View.Details;

            _list.FullRowSelect =
                true;

            _list.GridLines =
                true;

            _list.HideSelection =
                false;

            _list.MultiSelect =
                false;

            _list.Font =
                new Font(
                    "Segoe UI",
                    9F);

            _list.BorderStyle =
                BorderStyle.None;

            _list.HeaderStyle =
                ColumnHeaderStyle.Nonclickable;

            _list.OwnerDraw =
                true;

            _list.DrawColumnHeader +=
                DrawColumnHeader;

            _list.DrawItem +=
                DrawItem;

            _list.DrawSubItem +=
                DrawSubItem;

            //
            // Common columns
            //
            _list.Columns.Add(
                "Source",
                100);

            _list.Columns.Add(
                "Severity",
                120);

            _list.Columns.Add(
                "Line",
                50);

            _list.Columns.Add(
                "Column",
                80);

            _list.Columns.Add(
                "Message",
                900);

            //
            // List events
            //
            _list.DoubleClick +=
                OnDoubleClick;

            _list.Resize +=
                OnResize;

            _list.MouseDown +=
                OnListMouseDown;

            //
            // Right-click context menu
            //
            _contextMenu =
                new ContextMenuStrip();

            ToolStripMenuItem copyMessageItem =
                new ToolStripMenuItem(
                    "Copy Message");

            copyMessageItem.Click +=
                CopyMessage;

            _contextMenu.Items.Add(
                copyMessageItem);

            _list.ContextMenuStrip =
                _contextMenu;

            //
            // Add Fill control first,
            // then Top control.
            //
            Controls.Add(
                _list);

            Controls.Add(
                _titleLabel);
        }

        protected override bool ProcessCmdKey(
            ref Message msg,
            Keys keyData)
        {
            if (keyData ==
                (Keys.Control | Keys.C))
            {
                if (_list.SelectedItems.Count > 0)
                {
                    CopySelectedMessage();

                    return true;
                }
            }

            return base.ProcessCmdKey(
                ref msg,
                keyData);
        }

        private void OnListMouseDown(
            object sender,
            MouseEventArgs e)
        {
            if (e.Button !=
                MouseButtons.Right)
            {
                return;
            }

            ListViewItem item =
                _list.GetItemAt(
                    e.X,
                    e.Y);

            if (item == null)
            {
                return;
            }

            item.Selected =
                true;

            item.Focused =
                true;

            _list.Focus();
        }

        private void CopyMessage(
            object sender,
            EventArgs e)
        {
            CopySelectedMessage();
        }

        private void CopySelectedMessage()
        {
            if (_list.SelectedItems.Count == 0)
            {
                return;
            }

            ListViewItem item =
                _list.SelectedItems[0];

            if (item.SubItems.Count < 5)
            {
                return;
            }

            string message =
                item.SubItems[4].Text;

            if (string.IsNullOrWhiteSpace(
                    message))
            {
                return;
            }

            Clipboard.SetText(
                message);
        }

        public void SetTitle(
            string title)
        {
            _titleLabel.Text =
                string.IsNullOrWhiteSpace(title)
                    ? "SQL Results"
                    : title;
        }

        public void ShowResults(
            IList<SqlResultInfo> results)
        {
            _list.BeginUpdate();

            try
            {
                _list.Items.Clear();

                if (results == null)
                {
                    ResizeLastColumn();

                    return;
                }

                foreach (
                    SqlResultInfo result
                    in results)
                {
                    ListViewItem item =
                        new ListViewItem(
                            result.Source ??
                            string.Empty);

                    item.SubItems.Add(
                        result.Severity ??
                        string.Empty);

                    item.SubItems.Add(
                        result.Line > 0
                            ? result.Line.ToString()
                            : "-");

                    item.SubItems.Add(
                        result.Column > 0
                            ? result.Column.ToString()
                            : "-");

                    item.SubItems.Add(
                        result.Message ??
                        string.Empty);

                    item.Tag =
                        result;

                    _list.Items.Add(
                        item);
                }

                ResizeLastColumn();
            }
            finally
            {
                _list.EndUpdate();
            }
        }

        public void ShowErrors(
            IList<SqlErrorInfo> errors)
        {
            _list.BeginUpdate();

            try
            {
                _list.Items.Clear();

                _errors.Clear();

                if (errors == null ||
                    errors.Count == 0)
                {
                    ListViewItem item =
                        new ListViewItem(
                            "Parser");

                    item.SubItems.Add(
                        "Info");

                    item.SubItems.Add(
                        "-");

                    item.SubItems.Add(
                        "-");

                    item.SubItems.Add(
                        "No SQL parse errors.");

                    _list.Items.Add(
                        item);

                    ResizeLastColumn();

                    return;
                }

                foreach (
                    SqlErrorInfo err
                    in errors)
                {
                    _errors.Add(
                        err);

                    ListViewItem item =
                        new ListViewItem(
                            string.IsNullOrWhiteSpace(
                                err.Source)
                                ? "Parser"
                                : err.Source);

                    item.SubItems.Add(
                        "Error");

                    item.SubItems.Add(
                        err.Line.ToString());

                    item.SubItems.Add(
                        err.Column.ToString());

                    item.SubItems.Add(
                        err.Message ??
                        string.Empty);

                    item.Tag =
                        err;

                    _list.Items.Add(
                        item);
                }

                ResizeLastColumn();
            }
            finally
            {
                _list.EndUpdate();
            }
        }

        public void ShowFormatterMessages(
            IReadOnlyList<FormatterMessage> messages)
        {
            _list.BeginUpdate();

            try
            {
                _list.Items.Clear();

                _errors.Clear();

                if (messages == null ||
                    messages.Count == 0)
                {
                    ListViewItem item =
                        new ListViewItem(
                            "Formatter");

                    item.SubItems.Add(
                        "Info");

                    item.SubItems.Add(
                        "-");

                    item.SubItems.Add(
                        "-");

                    item.SubItems.Add(
                        "Formatting completed successfully.");

                    _list.Items.Add(
                        item);

                    ResizeLastColumn();

                    return;
                }

                foreach (
                    FormatterMessage message
                    in messages)
                {
                    ListViewItem item =
                        new ListViewItem(
                            "Formatter");

                    item.SubItems.Add(
                        message.Type.ToString());

                    item.SubItems.Add(
                        message.Line.HasValue
                            ? message.Line.Value.ToString()
                            : "-");

                    item.SubItems.Add(
                        message.Column.HasValue
                            ? message.Column.Value.ToString()
                            : "-");

                    item.SubItems.Add(
                        message.Message ??
                        string.Empty);

                    item.Tag =
                        message;

                    _list.Items.Add(
                        item);
                }

                ResizeLastColumn();
            }
            finally
            {
                _list.EndUpdate();
            }
        }

        private void DrawColumnHeader(
            object sender,
            DrawListViewColumnHeaderEventArgs e)
        {
            using (
                SolidBrush backBrush =
                    new SolidBrush(
                        Color.FromArgb(
                            245,
                            245,
                            245)))
            {
                e.Graphics.FillRectangle(
                    backBrush,
                    e.Bounds);
            }

            using (
                Pen borderPen =
                    new Pen(
                        Color.FromArgb(
                            220,
                            220,
                            220)))
            {
                e.Graphics.DrawRectangle(
                    borderPen,
                    e.Bounds);
            }

            TextRenderer.DrawText(
                e.Graphics,
                e.Header.Text,
                new Font(
                    "Segoe UI",
                    9F,
                    FontStyle.Bold),
                e.Bounds,
                Color.Black,
                TextFormatFlags.Left |
                TextFormatFlags.VerticalCenter);
        }

        private void DrawSubItem(
            object sender,
            DrawListViewSubItemEventArgs e)
        {
            e.DrawDefault =
                true;
        }

        private void DrawItem(
            object sender,
            DrawListViewItemEventArgs e)
        {
            e.DrawDefault =
                true;
        }

        private void OnDoubleClick(
            object sender,
            EventArgs e)
        {
            if (_list.SelectedItems.Count == 0)
            {
                return;
            }

            object tag =
                _list.SelectedItems[0].Tag;

            //
            // Common review/result model
            //
            SqlResultInfo result =
                tag as SqlResultInfo;

            if (result != null)
            {
                if (result.Line > 0)
                {
                    ErrorDoubleClicked?.Invoke(
                        result.Line,
                        result.Column > 0
                            ? result.Column
                            : 1);
                }

                return;
            }

            //
            // Formatter result
            //
            FormatterMessage message =
                tag as FormatterMessage;

            if (message != null)
            {
                if (message.Line.HasValue)
                {
                    ErrorDoubleClicked?.Invoke(
                        message.Line.Value,
                        message.Column ?? 1);
                }

                return;
            }

            //
            // Parser / validator result
            //
            SqlErrorInfo err =
                tag as SqlErrorInfo;

            if (err != null)
            {
                ErrorDoubleClicked?.Invoke(
                    err.Line,
                    err.Column);
            }
        }

        private void OnResize(
            object sender,
            EventArgs e)
        {
            ResizeLastColumn();
        }

        private void ResizeLastColumn()
        {
            if (_list.Columns.Count < 5)
            {
                return;
            }

            int usedWidth =
                _list.Columns[0].Width +
                _list.Columns[1].Width +
                _list.Columns[2].Width +
                _list.Columns[3].Width +
                25;

            int width =
                _list.ClientSize.Width -
                usedWidth;

            if (width < 300)
            {
                width =
                    300;
            }

            _list.Columns[4].Width =
                width;
        }

        protected override void OnShown(
            EventArgs e)
        {
            base.OnShown(
                e);

            ActiveControl =
                null;
        }

        protected override void OnFormClosing(
            FormClosingEventArgs e)
        {
            e.Cancel =
                true;

            Hide();
        }
    }
}
