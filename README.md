## Modelando um Dashboard de E-commerce com Power BI Utilizando Fórmulas DAX.


<img width="1080" height="713" alt="Screenshot_20251101-191239" src="https://github.com/user-attachments/assets/a0a6d027-6a8e-4bab-a082-68f71954d516" />


---

# 🛒 Dashboard de E-commerce — Power BI + DAX + Star Schema

**Tecnologias:** Power BI Desktop • Power Query (M) • DAX • GitHub  

---

## 📘 Descrição do Projeto

Este projeto foi desenvolvido como desafio de modelagem e análise de dados no Power BI, aplicando conceitos de **modelagem dimensional (Star Schema)** e **fórmulas DAX avançadas** para criação de medidas, colunas calculadas e tabelas derivadas.

A base de dados utilizada foi a amostra **Financial Sample**, com o objetivo de criar **tabelas dimensão e fato** para um cenário simulado de **E-commerce**, possibilitando análises dinâmicas de vendas, produtos, lucros e descontos.

O projeto está totalmente documentado e preparado para ser exibido no GitHub como portfólio técnico profissional.

---

## 🧱 Estrutura do Repositório

```bash
/dashboardEcommerceDax/
├── README.md                              # Documentação principal (este arquivo)
├── /data/
│   └── financial_sample.csv               # Base de dados original (Financial Sample)
├── /powerbi/
│   └── dashboardEcommerce.pbix            # Arquivo Power BI com modelo, DAX e relatórios
├── /docs/
│   ├── ER_diagram.png                     # Diagrama do modelo em estrela
│   ├── dax_formulas.md                    # Fórmulas DAX utilizadas no projeto
│   ├── process.md                         # Descrição do processo de modelagem e transformação
│   └── requirements.md                    # Requisitos de hardware e software
├── /images/
│   ├── overview_kpis.png                  # Página principal do dashboard
│   └── product_analysis.png               # Página de análise de produtos
└── /src/
    ├── etl_export_sql.sql                 # (Opcional) Script SQL auxiliar de extração
    └── powerquery_steps.txt               # Passos M exportados do Power Query.


```
---

---

🎯 Objetivo Técnico

Modelar o conjunto de dados Financial Sample para obter um modelo de dados analítico otimizado, criando tabelas dimensão e fato e aplicando medidas DAX para calcular métricas como:

Total de Vendas

Quantidade de Unidades Vendidas

Margem de Lucro (%)

Preço Médio e Mediano

Índice de Produto

Rankings de Produtos

---


🧮 **Estrutura do Modelo de Dados**

O modelo segue o padrão Star Schema (Esquema em Estrela):

<img width="988" height="736" alt="Screenshot_20251101-185807" src="https://github.com/user-attachments/assets/7c76415f-1a77-4ca6-a50a-24fe56df6d2f" />

---

Tabelas criadas:

Tipo	Nome da Tabela	Descrição

Backup	Financials_origem	Tabela original, mantida oculta no modelo
Dimensão	D_Produtos	Dados agregados por produto
Dimensão	D_Produtos_Detalhes	Detalhes individuais (preço, unidades, manufatura)
Dimensão	D_Descontos	Descontos e faixas
Dimensão	D_Calendario	Gerada via DAX com CALENDAR()
Fato	F_Vendas	Fato consolidado de vendas e lucros



---

⚙️ Etapas de Construção

1. Importação e backup da base

Importar financial_sample.csv

Renomear consulta para Financials_origem e ocultar no modelo.



2. Limpeza e transformação (Power Query)

Padronizar tipos de dados.

Remover nulos e valores inconsistentes.

Normalizar nomes de colunas.



3. Criação das tabelas dimensão e fato (DAX / Power Query)

Usar SUMMARIZE e ADDCOLUMNS para construir tabelas agregadas.

Criar D_Calendario com CALENDAR() entre o menor e o maior valor de data.



4. Modelagem relacional

Relacionar F_Vendas às dimensões.

Verificar cardinalidades e direções de filtro.



5. Criação das medidas DAX

Implementar cálculos de vendas, lucro e margem.

Criar índices e classificações com SWITCH, RANKX, IF.



6. Design do Dashboard

Página 1: Visão Geral (KPIs)

Página 2: Análise de Produtos

Página 3: Tendência Temporal (Gráficos por Mês/Ano)

Página 4: Tabela de Detalhes (Filtros Interativos)





---

🧠 Principais Fórmulas DAX Utilizadas

Consulte o arquivo completo: /docs/dax_formulas.md

Exemplo de medida:

Total Sales = 
SUMX(F_Vendas, F_Vendas[SalesPrice] * F_Vendas[UnitsSold])

Exemplo de tabela calculada:

D_Calendario =
ADDCOLUMNS(
    CALENDAR(MIN(F_Vendas[Date]), MAX(F_Vendas[Date])),
    "Ano", YEAR([Date]),
    "Mês", FORMAT([Date], "MMMM"),
    "Trimestre", "T" & FORMAT([Date], "Q")
)


---

🧰 Tecnologias e Ferramentas

Tecnologia	Uso

Power BI Desktop	Modelagem de dados e criação de relatórios
Power Query (M)	ETL — limpeza e transformação de dados
DAX	Cálculos e medidas dinâmicas
Git / GitHub	Versionamento e documentação do projeto



---

💻 Requisitos de Sistema

Software:

Power BI Desktop (versão 2023 ou superior)

Windows 10/11

Git (para versionamento)


Hardware recomendado:

CPU: Intel i5 ou superior

RAM: 8 GB (mínimo) / 16 GB (ideal)

Armazenamento: 10 GB livres



---

📊 Resultados Esperados

Modelo relacional limpo, otimizado e documentado.

Dashboard interativo com filtros, KPIs e análises visuais.

Utilização de funções DAX como CALCULATE, SUMMARIZE, ADDCOLUMNS, MEDIANX, RANKX e SWITCH.

README estruturado para atrair recrutadores e avaliadores técnicos.



---

✍️ Autor

Sérgio Santos
Analista de Sistemas e Desenvolvedor Power BI
📧 LinkedIn • 💻 GitHub: Santosdevbjj


---

---

## 📘 **(2) `/docs/dax_formulas.md` — todas as fórmulas DAX completas e comentadas**

> Caminho no GitHub:  
> `/docs/dax_formulas.md`

---

```markdown
# 📘 DAX Formulas — Dashboard E-commerce (Power BI)

Este arquivo documenta todas as **tabelas calculadas**, **colunas** e **medidas DAX** utilizadas no projeto **Dashboard E-commerce com Power BI**.

---
```

## 🧱 Tabelas Calculadas

### 1️⃣ D_Produtos
Resumo e estatísticas por produto.

```dax
D_Produtos =
ADDCOLUMNS(
    SUMMARIZE(
        Financials_origem,
        Financials_origem[ID_produto],
        Financials_origem[Produto]
    ),
    "Média Unidades", CALCULATE(AVERAGE(Financials_origem[Units Sold])),
    "Média Vendas", CALCULATE(AVERAGE(Financials_origem[Sales Price])),
    "Mediana Vendas", CALCULATE(MEDIAN(Financials_origem[Sales Price])),
    "Máximo Venda", CALCULATE(MAX(Financials_origem[Sales Price])),
    "Mínimo Venda", CALCULATE(MIN(Financials_origem[Sales Price]))
)


---
```

2️⃣ **D_Produtos_Detalhes**

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

3️⃣ **D_Descontos**

D_Descontos =
SUMMARIZE(
    Financials_origem,
    Financials_origem[ID_produto],
    Financials_origem[Discount],
    Financials_origem[Discount Band]
)


---

4️⃣ **D_Calendario**

D_Calendario =
ADDCOLUMNS(
    CALENDAR(MIN(Financials_origem[Date]), MAX(Financials_origem[Date])),
    "Ano", YEAR([Date]),
    "Mês", FORMAT([Date], "MMMM"),
    "Trimestre", "T" & FORMAT([Date], "Q"),
    "Ano-Mês", FORMAT([Date], "YYYY-MM"),
    "Dia", DAY([Date]),
    "MêsNum", MONTH([Date]),
    "SemanaAno", WEEKNUM([Date])
)


---

5️⃣ **F_Vendas**

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

📊 **Medidas DAX**

Total Sales

Total Sales = 
SUMX(F_Vendas, F_Vendas[SalesPrice] * F_Vendas[UnitsSold])


---

**Total Units Sold**

Total Units Sold =
SUM(F_Vendas[UnitsSold])


---

**Average Sales Price**

Average Sales Price =
AVERAGE(F_Vendas[SalesPrice])


---

**Median Sales Price**

Median Sales Price =
MEDIANX(VALUES(F_Vendas[SK_ID]), F_Vendas[SalesPrice])


---

**Total Profit**

Total Profit = SUM(F_Vendas[Profit])


---

**Profit Margin %**

Profit Margin % =
DIVIDE([Total Profit], [Total Sales], 0)


---

**Product Index (classificação de preço)**

Product Index =
SWITCH(
    TRUE(),
    [Average Sales Price] >= 1000, "Premium",
    [Average Sales Price] >= 500, "High",
    [Average Sales Price] >= 100, "Medium",
    "Low"
)


---

**Product Rank (ranking por valor médio)**

Product Rank =
RANKX(ALL(D_Produtos), [Average Sales Price], , DESC, DENSE)


---

**Top N Products (dinâmico)**

Top N Sales =
VAR N = SELECTEDVALUE(Parameters[TopN], 10)
RETURN
CALCULATE(
    [Total Sales],
    TOPN(N, VALUES(D_Produtos[ID_Produto]), [Total Sales], DESC)
)


---

**YoY Growth (Crescimento Anual de Vendas)**

YoY Growth % =
VAR CurrYear = [Total Sales]
VAR PrevYear = CALCULATE([Total Sales], DATEADD(D_Calendario[Date], -1, YEAR))
RETURN DIVIDE(CurrYear - PrevYear, PrevYear, 0)


---

**Average Discount %**

Average Discount % =
AVERAGE(F_Vendas[Discount])


---

**Sales per Country**

Sales per Country =
SUMMARIZE(
    F_Vendas,
    F_Vendas[Country],
    "TotalSales", [Total Sales],
    "Profit", [Total Profit]
)


---

📈 **DAX Tips**

**Use CALCULATE** para alterar o contexto de filtro.

**SUMMARIZE** cria contextos de agrupamento.

**ADDCOLUMNS** adiciona métricas a um contexto existente.

**DIVIDE** evita erros de divisão por zero.

**SWITCH e RANKX** permitem criar classificações inteligentes.



---

📘 **Autor:** Sérgio Santos
💡 Projeto: Dashboard de E-commerce — Modelagem DAX com Power BI
📅 Ano: 2025

---









