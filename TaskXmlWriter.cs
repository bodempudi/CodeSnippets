
using System;
using System.Globalization;
using System.Xml;

namespace Microsoft.SqlServer.IntegrationServices.TasksCommon;

internal class TaskXmlWriter
{
    private readonly XmlDocument m_xmlDocument;

    private readonly XmlElement m_rootElement;

    public XmlDocument Document => m_xmlDocument;

    public XmlElement RootElement => m_rootElement;

    public TaskXmlWriter(XmlDocument xmlDocument, string rootName)
        : this(xmlDocument, null, rootName, null)
    {
    }

    public TaskXmlWriter(XmlDocument xmlDocument, string rootPrefix, string rootName, string rootNamespace)
    {
        m_xmlDocument = xmlDocument;
        m_rootElement = xmlDocument.CreateElement(rootPrefix, rootName, rootNamespace);
    }

    public void AddAttributeForNullOrEmptyString(string attributeName, string currentValue)
    {
        AddAttributeForNullOrEmptyString(null, attributeName, null, currentValue);
    }

    public void AddAttributeForNullOrEmptyString(string attributePrefix, string attributeName, string attributeNamespace, string currentValue)
    {
        if (!string.IsNullOrEmpty(currentValue))
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = currentValue;
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttribute(string attributeName, string defaultValue, string currentValue)
    {
        AddAttribute(null, attributeName, null, defaultValue, currentValue);
    }

    public void AddAttribute(string attributePrefix, string attributeName, string attributeNamespace, string defaultValue, string currentValue)
    {
        if (string.Compare(defaultValue, currentValue, StringComparison.Ordinal) != 0)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = currentValue;
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttribute(string attributeName, long defaultValue, long currentValue)
    {
        AddAttribute(null, attributeName, null, defaultValue, currentValue);
    }

    public void AddAttribute(string attributePrefix, string attributeName, string attributeNamespace, long defaultValue, long currentValue)
    {
        if (defaultValue != currentValue)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = currentValue.ToString(CultureInfo.InvariantCulture);
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttribute(string attributeName, int defaultValue, int currentValue)
    {
        AddAttribute(null, attributeName, null, defaultValue, currentValue);
    }

    public void AddAttribute(string attributePrefix, string attributeName, string attributeNamespace, int defaultValue, int currentValue)
    {
        if (defaultValue != currentValue)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = currentValue.ToString(CultureInfo.InvariantCulture);
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttribute(string attributeName, bool defaultValue, bool currentValue)
    {
        AddAttribute(null, attributeName, null, defaultValue, currentValue);
    }

    public void AddAttribute(string attributePrefix, string attributeName, string attributeNamespace, bool defaultValue, bool currentValue)
    {
        if (defaultValue != currentValue)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = currentValue.ToString(CultureInfo.InvariantCulture);
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttributeForEnum(string attributeName, Type enumType, long defaultValue, long currentValue)
    {
        AddAttributeForEnum(null, attributeName, null, enumType, defaultValue, currentValue);
    }

    public void AddAttributeForEnum(string attributePrefix, string attributeName, string attributeNamespace, Type enumType, long defaultValue, long currentValue)
    {
        if (defaultValue != currentValue)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = Enum.Format(enumType, currentValue, "f");
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddAttributeForEnum(string attributeName, Type enumType, int defaultValue, int currentValue)
    {
        AddAttributeForEnum(null, attributeName, null, enumType, defaultValue, currentValue);
    }

    public void AddAttributeForEnum(string attributePrefix, string attributeName, string attributeNamespace, Type enumType, int defaultValue, int currentValue)
    {
        if (defaultValue != currentValue)
        {
            XmlAttribute xmlAttribute = m_xmlDocument.CreateAttribute(attributePrefix, attributeName, attributeNamespace);
            xmlAttribute.Value = Enum.Format(enumType, currentValue, "f");
            m_rootElement.Attributes.Append(xmlAttribute);
        }
    }

    public void AddCDataNode(string cdataNodeName, string cdataValue)
    {
        XmlNode xmlNode = m_xmlDocument.CreateElement(cdataNodeName);
        m_rootElement.AppendChild(xmlNode);
        XmlCDataSection newChild = m_xmlDocument.CreateCDataSection(cdataValue);
        xmlNode.AppendChild(newChild);
    }

    public void SaveChangesToXmlDocument()
    {
        if ((m_rootElement.Attributes != null && m_rootElement.Attributes.Count > 0) || (m_rootElement.ChildNodes != null && m_rootElement.ChildNodes.Count > 0))
        {
            SaveToXmlDocument();
        }
    }

    public void SaveToXmlDocument()
    {
        if (m_rootElement.ParentNode == null)
        {
            m_xmlDocument.AppendChild(m_rootElement);
        }
    }
}
