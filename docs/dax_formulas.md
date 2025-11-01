D_Produtos =
ADDCOLUMNS(
    SUMMARIZE(
        Financials_origem,
        Financials_origem[ID_produto],
        Financials_origem[Produto]
    ),
    "Avg_Units", CALCULATE( AVERAGE(Financials_origem[Units Sold]) ),
    "Avg_SalesPrice", CALCULATE( AVERAGE(Financials_origem[Sales Price]) ),
    "Median_SalesPrice", CALCULATE( MEDIAN(Financials_origem[Sales Price]) ),
    "Max_SalesPrice", CALCULATE( MAX(Financials_origem[Sales Price]) ),
    "Min_SalesPrice", CALCULATE( MIN(Financials_origem[Sales Price]) )
) 


---

D_Produtos_Detalhes =
SUMMARIZE(
    Financials_origem,
    Financials_origem[ID_produto],
    Financials_origem[Discount Band],
    Financials_origem[Sales Price],
    Financials_origem[Units Sold],
    Financials_origem[Manufacturing Price]
) 


---

D_Descontos =
SUMMARIZE(
    Financials_origem,
    Financials_origem[ID_produto],
    Financials_origem[Discount],
    Financials_origem[Discount Band]
) 

---

D_Calendario =
ADDCOLUMNS(
    CALENDAR( MIN(Financials_origem[Date]), MAX(Financials_origem[Date]) ),
    "Year", YEAR([Date]),
    "MonthNumber", MONTH([Date]),
    "MonthName", FORMAT([Date], "MMMM"),
    "Quarter", "Q" & FORMAT([Date], "Q"),
    "YearMonth", FORMAT([Date], "YYYY-MM")
) 



---


F_Vendas =
SELECTCOLUMNS(
    Financials_origem,
    "SK_ID", Financials_origem[SK_ID],
    "ID_Produto", Financials_origem[ID_produto],
    "Produto", Financials_origem[Produto],
    "UnitsSold", Financials_origem[Units Sold],
    "SalesPrice", Financials_origem[Sales Price],
    "DiscountBand", Financials_origem[Discount Band],
    "Segment", Financials_origem[Segment],
    "Country", Financials_origem[Country],
    "Saler", Financials_origem[Saler],
    "Profit", Financials_origem[Profit],
    "Date", Financials_origem[Date]
) 



---

Total Sales = SUM(F_Vendas[SalesPrice] * F_Vendas[UnitsSold])
-- se SalesPrice já vier multiplicado por UnitsSold, adaptar para SUMX 


---

Total Units = SUM(F_Vendas[UnitsSold])


---

Average Sales Price = AVERAGE(F_Vendas[SalesPrice])


---


Median Sales Price = MEDIANX( VALUES(F_Vendas[SK_ID]), F_Vendas[SalesPrice] )
-- ou MEDIAN(F_Vendas[SalesPrice]) dependendo da granularidade 



---



Profit Margin % = DIVIDE( SUM(F_Vendas[Profit]), SUMX(F_Vendas, F_Vendas[SalesPrice] * F_Vendas[UnitsSold]) , 0 ) 


---

Product Index =
SWITCH(
    TRUE(),
    [Avg_SalesPrice] >= 1000, "Premium",
    [Avg_SalesPrice] >= 500, "High",
    [Avg_SalesPrice] >= 100, "Medium",
    "Low"
) 


---


Product Rank =
RANKX( ALL(D_Produtos), D_Produtos[Avg_SalesPrice], , DESC, DENSE ) 


---


Top N Sales = 
VAR N = SELECTEDVALUE(Parameters[TopN], 10)
RETURN
CALCULATE(
    [Total Sales],
    TOPN(N, VALUES(D_Produtos[ID_produto]), [Total Sales], DESC)
) 




---




