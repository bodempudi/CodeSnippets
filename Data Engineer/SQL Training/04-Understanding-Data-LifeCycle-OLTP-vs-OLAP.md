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
      Basically surrogate key will not have any business meaning. It is just a primary key which will be used to uniqely indentify a record in a dimension table. We might get a Question that we load the data from OLTP or any other source systems. Such systems already have a primary key then why we need another primary key at data warehouse level. The reason for this is for any dimension member, values of the dimension member may change over a period of time. When a value is changed in source system we might have to load again into data warehouse with changed values. Source system primary key value will not change, when we load again the same primary key column into warehouse we will have duplicate value in the column and we will end up with an error saying duplicates in column. To avoid this we create our own primary key in data warehouse and when we load the changed values into data warehouse, new surrogate key value will be generated and new source values will be stored with new surrogate key value. This way we load the changed value and we maintain unique value to load the data at data warehouse side as well.

2. **Facts**
      Fact is some number in your business, it means SalesAmount, OrderQuantity, ProductCost etc. These are numbers measures your business. Basically a fact always provides answers to the questions. How many products sold? How much is the sales amount? How many orders ordered this year?
   
3. **Dimensions**
    Dimensions provide descriptive informaion to the facts. Without the dimension, fact does not have any meaning. Dimension provides answers to the following questions.
    which customer, which product, which date, which location, which country.

Lets take a simple analogy to understand the facts and dimensions in data warehousing.

Venkat went to Lulu Hyder Market, Salmiya on Feb 9th 2024 and he purchased gulf auqa water bottles 1 case at price 0.295 fills and he bought 2 Kg Italy apples at 1.250 fills respectively.

Here the measures(facts) are - 0.295, 1.250. when we take a look at these number we do not understand these values.
Here dimensions:
DimCustomer- Venkat
DimProduct- Gulf-Aqua, Italy Apple
DimDate- Feb 09 2024
DimLocation - LuLu Salmiya

Unless you add these dimensions to the facts, 0.295 and 1.250 does not have any meaning.

We will take a look at these implementations later.

  4. **Star Schema**
    Star Schema is a one of the dimensional modeling design technique. In this dimension modeling design technique each dimension directly connects to facts.
    Most of the data warehousing systems follows star schema based design to avoid more joins to read data from few places.
    
  5. **Snowflake Schema**
     Snowflake schema is another dimensional modeling design technique. In this dimensional modeling design technique few dimensions connects to facts through a referred dimension. This type of design is used only for POCs.
  6. **Slowly Changing Dimensions**
     Slowly changing dimensions are the dimenions which values will change over a period of time. When the value is changed we create a new record in dimension
     table and we tag old record with flag column or enddate column.

     Ex: If we take DimEmployee as example, once an employee changes his designatin over a period of time, we will have multiple entries in DimEmployee dimension with new suggogate key value.
     
  9. Early arriving Facts or Late Arriving Dimensions.
       Few facts values comes early to the system then we load the data into the  fact tables first and will populate referenced columns with -1 values. When we receive the data we wil update them with actual data.
  11. Staging Area - temparory/landing are in data warehousing systems.
  12. Lineage/Audit Columns - audit in dimensions or facts. using these value we delete data from dimensions or facts to reload the data.
  13. Control Table - contains information about ETL start date and ETL completion data and load status.

