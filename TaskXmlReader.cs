
using System;
using System.Globalization;
using System.Xml;

namespace Microsoft.SqlServer.IntegrationServices.TasksCommon;

internal class TaskXmlReader
{
    private readonly XmlElement m_element;

    public TaskXmlReader(XmlElement xmlElement)
    {
        m_element = xmlElement;
    }

    public bool TryGetAttributeValue(string attributeName, out string value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue(string attributeName, string attributeNamespace, out string value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = Convert.ToString(attributeValue, CultureInfo.InvariantCulture);
            return true;
        }

        value = null;
        return false;
    }

    public bool TryGetAttributeValue(string attributeName, out long value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue(string attributeName, string attributeNamespace, out long value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = Convert.ToInt64(attributeValue, CultureInfo.InvariantCulture);
            return true;
        }

        value = 0L;
        return false;
    }

    public bool TryGetAttributeValue(string attributeName, out int value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue(string attributeName, string attributeNamespace, out int value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = Convert.ToInt32(attributeValue, CultureInfo.InvariantCulture);
            return true;
        }

        value = 0;
        return false;
    }

    public bool TryGetAttributeValue(string attributeName, out bool value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue(string attributeName, string attributeNamespace, out bool value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = Convert.ToBoolean(attributeValue, CultureInfo.InvariantCulture);
            return true;
        }

        value = false;
        return false;
    }

    public bool TryGetAttributeValue(string attributeName, out uint value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue(string attributeName, string attributeNamespace, out uint value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = Convert.ToUInt32(attributeValue, CultureInfo.InvariantCulture);
            return true;
        }

        value = 0u;
        return false;
    }

    public bool TryGetAttributeValue<T>(string attributeName, out T value)
    {
        return TryGetAttributeValue(attributeName, (string)null, out value);
    }

    public bool TryGetAttributeValue<T>(string attributeName, string attributeNamespace, out T value)
    {
        string attributeValue = GetAttributeValue(attributeName, attributeNamespace);
        if (attributeValue != null)
        {
            value = (T)Enum.Parse(typeof(T), attributeValue, ignoreCase: true);
            return true;
        }

        value = default(T);
        return false;
    }

    private string GetAttributeValue(string attributeName, string attributeNamespace)
    {
        return ((attributeNamespace != null) ? m_element.Attributes.GetNamedItem(attributeName, attributeNamespace) : m_element.Attributes.GetNamedItem(attributeName))?.Value;
    }

    public bool TryGetCDataNode(string cdataNodeName, out string cdataValue)
    {
        XmlNodeList elementsByTagName = m_element.GetElementsByTagName(cdataNodeName);
        if (elementsByTagName != null && elementsByTagName.Count > 0)
        {
            foreach (XmlNode childNode in elementsByTagName[0].ChildNodes)
            {
                if (childNode.NodeType == XmlNodeType.CDATA)
                {
                    cdataValue = childNode.Value;
                    return true;
                }
            }
        }

        cdataValue = null;
        return false;
    }
}
