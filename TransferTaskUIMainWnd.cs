 
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Windows.Forms;
using System.Xml;
using Microsoft.DataTransformationServices.Controls;
using Microsoft.SqlServer.Dts.Runtime;

namespace Microsoft.SqlServer.Dts.Tasks.TransferTasks;

internal class TransferTaskUIMainWnd : DTSBaseTaskUI
{
    private IDTSComponentPersist taskPersist;

    private XmlElement backupXml;

    public TransferTaskUIMainWnd(string title, Icon icon, string description, TaskHost taskHost, object connections)
        : base(title, icon, description, (object)taskHost, connections)
    {
        ref IDTSComponentPersist reference = ref taskPersist;
        object innerObject = taskHost.InnerObject;
        reference = (IDTSComponentPersist)((innerObject is IDTSComponentPersist) ? innerObject : null);
        BackupTask();
    }

    public void AddViews(List<KeyValuePair<string, IDTSTaskUIView>> views)
    {
        foreach (KeyValuePair<string, IDTSTaskUIView> view in views)
        {
            ((DTSBaseTaskUI)this).DTSTaskUIHost.AddView(view.Key, view.Value, (TreeNode)null);
        }
    }

    protected override void OnClosing(CancelEventArgs e)
    {
        //IL_0001: Unknown result type (might be due to invalid IL or missing references)
        //IL_0007: Invalid comparison between Unknown and I4
        if ((int)((Form)this).DialogResult != 1)
        {
            RestoreTask();
        }
    }

    protected override void OnCancel(object sender, EventArgs e)
    {
        ((Form)this).Close();
    }

    private void BackupTask()
    {
        if (taskPersist != null)
        {
            XmlDocument xmlDocument = new XmlDocument();
            taskPersist.SaveToXML(xmlDocument, (IDTSInfoEvents)null);
            backupXml = xmlDocument.DocumentElement;
        }
    }

    private void RestoreTask()
    {
        if (taskPersist != null)
        {
            taskPersist.LoadFromXML(backupXml, (IDTSInfoEvents)null);
        }
    }
}
