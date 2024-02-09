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

There is book called, Data warehousing toolkit 2nd Edition Ralf Kimbal, just read first 25 pages, that is more than enough.
When any ETL developer started working on data warehousing projects, he should first understand the business or domain.

In any ETL systems, First we connect to source systems(OLTP systems or Operational Source System). Each company follows different models to allow subsequest systems to connect and read the data for further ETL purposes. Most of the companies won't allow connecting to production systems directly, this will lead to performance issues. Rather allowing connecting to production systems directly, they create a replicated database server and they allow connecting to replicated server data for ETL puposes. We bring the data from source systems(Operational Source System) to staging(Landing) area. Stage layer always follow truncate and load model. Once we have the data in stage layer, it very flexible to apply the required transformations to the data into data warehouse.

There are few theorietical topics that every ETL developer should be aware of data warehousing.

They are
  1. **Surrogate Key** 
      Basically surrogate key will not have a business meaning. It is just a primary key which will be used to uniqely indentify a record in a table. We might get a Question that we load the data from OLTP or any other systems. Such systems already have a primary key, why we need another primary key at data warehouse
 level. The reason for this is for any dimension member, values of that dimension member may change over a period of time. When a value is changed in source system we might have to load again into data warehouse with changed values. Source system primary key value will not change, when we load again the same primary key column into ware house we will have duplicate value in the column and we will end up with an error saying duplicates in column. To avoid this we create our own primary key in data warehouse and when we load the changed values into data warehouse, new surrogate key value will be generated and new source values will be stored with new surrogate key value. This way we load the changed value and we maintain unique value to load the data at data warehouse side as well.

2. **Dimensions**
      
  4. Facts
  5. Dimensions
  6. Star Schema
  7. Snowflake Schema
  8. Early arriving Facts or Late Arriving Dimensions.
  9. Staging Area
  10. Lineage/Audit Columns
  11. Control Table
  12. Slowly Changing Dimensions

All ETL systems follow more or less same design patterns. For easy trouble sho
