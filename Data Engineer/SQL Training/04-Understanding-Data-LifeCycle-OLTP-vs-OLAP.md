In any organization data gets generated at various levels. In this section we will take a look at different data engineering terminologies and understand the same.

## Online Transaction Processing System (OLTP).
  **Online transaction processing system** usually referred to as **OLTP** is a data storage system, it stores the data that has generated based on user interaction with the applications. 
  
  For instance, 
    in banking systems, 
      1. bank employee sitting in the branch will deposit or withdraw money behalf of the customer of the bank. 
      2. We do withdraw our money using ATM centers.
      
These type of day to day transactions get stored in storage systems such as OLTP storage systems. If we take a look at the vollume of the transaction is very less. Only particular user related
transactions will get stored in database and here we deal with very recent data of the user. Here read and write(Insert, Update and delete) are most common operations in OLTP at the same time, we read or write the data of a specific user.
Since the user waits for the reply from interactive applications, the data storage should happen very quickly. In order to achieve this, we should have normalized database design so that our data is going to inserted or updated only at few places so that the operation is going to be completed quickly and user get updated quickly.
  
When we have normalized database design we might end with more number joins in query. But it is okay in OLTP systems since we deal with less vollumn of data. Here users of the applications usually generates the data.

The prime focus of the OLTP is data entry not reporting.

## Online Analytical Processing System (OLAP)
 **Online Analytical Processing System** usually referred to as **OLAP** is also a data storage system. It contains the data which was generated over the years. Data in OLAP is historical data in the business.
 Reading is the only or main operation in OLAP systems and we read lot of data for reporting purpose. When we read lot data, to read lot of data quickly, we should have less joins. So denormaized database design
 is used incase of OLAP system. Users of the OLAP system is business people in the organization like Product Owners, Executive leadership people, top management people, operatins people. The data in OLAP systems is being stored with the help of ETL tools such as SSIS from Microsoft.

 Both OLTP and OLAP systems can be stored in SQL Server. Only the database design different from one to another. In case of OLTP systems more joins where as in case OLAP systems less joins. The usage of each system is different, in order to achive the proper performance design is also going to different.

 OLAP systems referred to as Data warehouses or EDW.

 Data warehouse is contains entire organization data, but some times we may store one specific subject or business case(Retail sales or online sales) data, this spefic business data storage system is called Datamart. When combine all the datamarts it will become data warehouse.

 There few theorietical topics to concepts should aware of data warehousing.

 They are
  1 Surrogate Key
  2 Facts
  3 Dimensions
  4 Star Schema
  5 Snowflake Schema
