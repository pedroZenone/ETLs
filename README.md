# ETLs

Here are some ETLs that took me lot of time to develop. The main ones are:

- Nielsen parser: I think this parser will be the most difficult I'll do. Data came with a report format in excel and they didn’t want to give as in a structured way. The excels sheet were composed of squares with sales of a category listed by advertiser and above brand. The ETL loaded the data, parsed it understanding which row is brand or advertiser, and load it into a csv file. This step requires human revision, so when this finished one should run a SQL procedure in order to standardized with defined values.

- History integration: I had to integrate historical data of real sales, audited sales, investment, TRPs and qualitative metrics. All this source of information came from different places and in some cases a couple of years too.
