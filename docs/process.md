# /docs/process.md

# Processo de Construção do Projeto — Power Query (M) + DAX
Este documento descreve passo a passo todo o processo de ingestão, limpeza, modelagem e preparação dos dados no Power BI usando **Power Query (M)**, até a criação das tabelas dimensão e fato (star schema). Inclui os códigos M (quando aplicável) e instruções para criar a `D_Calendario` em **DAX** (conforme requisitado).

---

## Visão Geral das Tabelas Finais
- `Financials_origem` (consulta de backup; ocultar no modelo)
- `F_Vendas` (tabela fato — granularidade de transação)
- `D_Produtos` (dimensão agregada por produto)
- `D_Produtos_Detalhes` (dimensão de detalhes do produto)
- `D_Descontos` (dimensão de faixas de desconto)
- `D_Detalhes` (dimensão para campos restantes / vendedores / segmentos)
- `D_Calendario` (criada por **DAX** com `CALENDAR()`)

---

## Regras e pressupostos utilizados
1. Colunas esperadas na `Financial Sample` (nomes padronizados usados neste documento):
   - `SK_ID` (identificador da linha/transação)
   - `ID_produto` (identificador do produto)
   - `Produto` (nome do produto)
   - `Units Sold` (unidades vendidas)
   - `Sales Price` (preço de venda unitário)
   - `Manufacturing Price` (preço de fabricação / custo unitário)
   - `Discount` (valor do desconto, ex: 0.05 para 5% ou 5 dependendo do formato)
   - `Discount Band` (faixa textual do desconto)
   - `Segment` (segmento do cliente)
   - `Country` (país)
   - `Saler` (vendedor / sales rep)
   - `Profit` (lucro da transação)
   - `Date` (data da transação)
2. Onde necessário, normalizamos nomes para **sem espaços** ou com underscores para facilitar DAX (ex.: `Units_Sold`, `Sales_Price`), mas no processo abaixo mantenho os nomes originais entre colchetes e ofereço alternativa de renomeação.
3. Medidas e colunas calculadas mais complexas são feitas em **DAX** (ex.: `D_Calendario` via `CALENDAR`, índices por agregação e `RANKX`) — as tabelas dimensionais podem ser preparadas tanto no Power Query quanto em DAX; aqui privilegiamos Power Query para transformar/limpar e DAX para cálculos relacionados ao modelo.

---

## 1) Importar a fonte e criar o backup `Financials_origem`

### GUI (Power Query)
1. Em *Home > Get Data > Text/CSV*, selecione `financial_sample.csv`.
2. Carregue para o *Power Query Editor* e renomeie a consulta para `Financials_origem`.
3. Verifique tipos automáticos; corrigir manualmente os tipos conforme abaixo.
4. Ao terminar, marque a query para **Load to Model** (carregar) e **oculte** a tabela no modelo (Model view → clicar com o direito → Hide).

### M (exemplo automático gerado pela importação)
```m
let
    Source = Csv.Document(File.Contents("C:\path\data\financial_sample.csv"),[Delimiter=",", Columns=20, Encoding=1252, QuoteStyle=QuoteStyle.Csv]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    ChangedTypes = Table.TransformColumnTypes(PromoteHeaders,{
        {"SK_ID", Int64.Type},
        {"ID_produto", type text},
        {"Produto", type text},
        {"Units Sold", Int64.Type},
        {"Sales Price", type number},
        {"Manufacturing Price", type number},
        {"Discount", type number},
        {"Discount Band", type text},
        {"Segment", type text},
        {"Country", type text},
        {"Saler", type text},
        {"Profit", type number},
        {"Date", type date}
    })
in
    ChangedTypes

---
```

**Observação:** ajuste o caminho do arquivo conforme seu ambiente. Se o CSV estiver em UTF-8, ajuste Encoding=65001.




---

2) Limpeza geral e padronização (aplicar em Financials_origem)

Objetivos desta etapa

Remover colunas irrelevantes.

Corrigir e padronizar tipos.

Tratar valores nulos/zerados/outliers.

Normalizar nomes de colunas (opcional: criar versão sem espaços).


Passos (GUI)

1. Remover colunas que não serão usadas no modelo (ex.: Notes, RowChecksum etc) — Home > Remove Columns.


2. Alterar tipos de colunas: Date → Date, Units Sold → Whole Number, Sales Price/Manufacturing Price/Profit → Decimal Number.


3. Tratar nulos:

Substituir valores nulos em Units Sold por 0 ou remover linhas onde Sales Price é nulo.

Substituir Discount nulo por 0.



4. Filtrar linhas inválidas:

Remover linhas onde Units Sold <= 0 ou Sales Price <= 0 (a menos que queira manter devoluções — documente).



5. Remover duplicatas por SK_ID se existirem: Home > Remove Rows > Remove Duplicates.


6. (Opcional) Criar coluna SalesAmount = [Units Sold] * [Sales Price] no Power Query para inspeção (no modelo pode preferir medida DAX).



M-code (aplicar como etapa abaixo em Financials_origem)

let
    Fonte = Csv.Document(File.Contents("C:\path\data\financial_sample.csv"),[Delimiter=",", Columns=20, Encoding=1252, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Fonte, [PromoteAllScalars=true]),
    Types = Table.TransformColumnTypes(Promoted,{
        {"SK_ID", Int64.Type},
        {"ID_produto", type text},
        {"Produto", type text},
        {"Units Sold", Int64.Type},
        {"Sales Price", type number},
        {"Manufacturing Price", type number},
        {"Discount", type number},
        {"Discount Band", type text},
        {"Segment", type text},
        {"Country", type text},
        {"Saler", type text},
        {"Profit", type number},
        {"Date", type date}
    }),
    // Substituir nulos
    ReplaceNulls = Table.ReplaceValue(Types, null, 0, Replacer.ReplaceValue, {"Units Sold", "Discount"}),
    // Remover linhas inválidas
    FilterRows = Table.SelectRows(ReplaceNulls, each ([Units Sold] > 0 and [Sales Price] <> null and [Sales Price] > 0)),
    // Remover duplicados por SK_ID
    RemoveDup = Table.Distinct(FilterRows, {"SK_ID"}),
    // Criar coluna SalesAmount (opcional, para validação)
    AddSalesAmount = Table.AddColumn(RemoveDup, "SalesAmount", each [Units Sold] * [Sales Price], type number),
    // Trim e limpeza em colunas textuais
    Trimmed = Table.TransformColumns(AddSalesAmount, {{"Produto", Text.Trim, type text}, {"Discount Band", Text.Trim, type text}, {"Segment", Text.Trim, type text}, {"Country", Text.Trim, type text}, {"Saler", Text.Trim, type text}})
in
    Trimmed


---

3) Criando F_Vendas (tabela fato) no Power Query

Objetivo

Criar uma tabela fato com apenas as colunas necessárias na granularidade de transação (uma linha = uma venda).

Passos (GUI)

1. Duplique a consulta Financials_origem → renomeie para F_Vendas.


2. Remova colunas que não fazem parte do fato (ex.: colunas de descrição longa, comentários).


3. Reordenar colunas (opcional): SK_ID, ID_produto, Produto, Date, Units Sold, Sales Price, SalesAmount, Discount, Discount Band, Segment, Country, Saler, Profit, Manufacturing Price.


4. Alterar nomes para versão amigável (ex.: Units_Sold, Sales_Price) — isso facilita DAX.



M-code para F_Vendas

let
    Fonte = Financials_origem, // referência à query já limpa
    SelectCols = Table.SelectColumns(Fonte, {
        "SK_ID","ID_produto","Produto","Date","Units Sold","Sales Price",
        "Manufacturing Price","Discount","Discount Band","Segment","Country","Saler","Profit","SalesAmount"
    }),
    Renamed = Table.RenameColumns(SelectCols,{
        {"Units Sold","Units_Sold"},
        {"Sales Price","Sales_Price"},
        {"Manufacturing Price","Manufacturing_Price"},
        {"Discount Band","Discount_Band"}
    }),
    ChangedTypes = Table.TransformColumnTypes(Renamed,{
        {"SK_ID", Int64.Type},
        {"ID_produto", type text},
        {"Produto", type text},
        {"Date", type date},
        {"Units_Sold", Int64.Type},
        {"Sales_Price", type number},
        {"Manufacturing_Price", type number},
        {"Discount", type number},
        {"Discount_Band", type text},
        {"Segment", type text},
        {"Country", type text},
        {"Saler", type text},
        {"Profit", type number},
        {"SalesAmount", type number}
    })
in
    ChangedTypes

> Observação: se preferir não materializar a coluna SalesAmount no Power Query, remova-a e calcule em DAX via SUMX.




---

4) Criando D_Produtos (dimensão agregada por produto)

Objetivo

Gerar uma dimensão por produto com métricas agregadas (média de unidades, média de preço, mediana, min, max).

Por que no Power Query?

Facilita verificação e qualidade dos dados antes do modelo.

Evita cálculos repetidos no runtime quando a cardinalidade de produto for limitada e estática.


Passos (GUI)

1. Criar nova consulta referenciando Financials_origem → Reference → renomear para D_Produtos.


2. Selecionar colunas ID_produto, Produto, Units Sold, Sales Price.


3. Agrupar por ID_produto e Produto:

Operação: All Rows (ou usar agregações diretamente: Média de Units, Média Sales Price, Máx, Mín).



4. Se usou All Rows, adicionar colunas com fórmulas usando Table.TransformColumns e List.Median.



M-code (opção com operações explícitas)

let
    Fonte = Financials_origem,
    SelectCols = Table.SelectColumns(Fonte, {"ID_produto","Produto","Units Sold","Sales Price"}),
    // Agrupar e calcular média/min/max
    Grouped = Table.Group(SelectCols, {"ID_produto","Produto"}, {
        {"Avg_Units", each List.Average([Units Sold]), type nullable number},
        {"Avg_SalesPrice", each List.Average([Sales Price]), type nullable number},
        {"Median_SalesPrice", each List.Median([Sales Price]), type nullable number},
        {"Max_SalesPrice", each List.Max([Sales Price]), type nullable number},
        {"Min_SalesPrice", each List.Min([Sales Price]), type nullable number},
        {"CountTransactions", each List.Count([Sales Price]), Int64.Type}
    }),
    // Opcional: renomear colunas para padronização
    Renamed = Table.RenameColumns(Grouped,{
        {"ID_produto","ID_Produto"},
        {"Produto","Produto"}
    })
in
    Renamed

> Nota: List.Median está disponível nas versões mais recentes do Power Query; se faltar, use uma função customizada para mediana (ex.: ordenar a lista e tirar o valor do meio).




---

5) Criando D_Produtos_Detalhes (dimensão de granularidade produto + faixa de desconto)

Objetivo

Manter uma visão detalhada por combinação de ID_produto × Discount_Band com preços e unidades típicas.

Passos (GUI)

1. Da Financials_origem → Reference → renomear D_Produtos_Detalhes.


2. Selecionar colunas: ID_produto, Produto, Discount Band, Sales Price, Units Sold, Manufacturing Price.


3. Remover duplicatas (se desejar uma linha por combinação distinta).



M-code

let
    Fonte = Financials_origem,
    SelectCols = Table.SelectColumns(Fonte, {"ID_produto","Produto","Discount Band","Sales Price","Units Sold","Manufacturing Price"}),
    Renamed = Table.RenameColumns(SelectCols, {{"Discount Band","Discount_Band"},{"Manufacturing Price","Manufacturing_Price"},{"Units Sold","Units_Sold"}}),
    RemovedDuplicates = Table.Distinct(Renamed)
in
    RemovedDuplicates


---

6) Criando D_Descontos (faixas de desconto)

Objetivo

Tabela simples com as faixas (Discount_Band) e valores médios de desconto.

Passos (GUI)

1. Reference → D_Descontos.


2. Selecionar Discount Band, Discount, ID_produto.


3. Agrupar por Discount Band para obter métricas por faixa.



M-code

let
    Fonte = Financials_origem,
    SelectCols = Table.SelectColumns(Fonte, {"ID_produto","Discount","Discount Band"}),
    Renamed = Table.RenameColumns(SelectCols, {{"Discount Band","Discount_Band"}}),
    Grouped = Table.Group(Renamed, {"Discount_Band"}, {
        {"Avg_Discount", each List.Average([Discount]), type nullable number},
        {"Min_Discount", each List.Min([Discount]), type nullable number},
        {"Max_Discount", each List.Max([Discount]), type nullable number},
        {"CountProducts", each List.Count([ID_produto]), Int64.Type}
    })
in
    Grouped


---

7) Criando D_Detalhes (vendedores, segmentos, países)

Objetivo

Centralizar dados que descrevem vendedores, segmento e geografia.

Passos (GUI)

1. Reference → D_Detalhes.


2. Selecionar: Saler, Segment, Country.


3. Remover duplicatas.



M-code

let
    Fonte = Financials_origem,
    SelectCols = Table.SelectColumns(Fonte, {"Saler","Segment","Country"}),
    RemovedDup = Table.Distinct(SelectCols),
    Renamed = Table.TransformColumnTypes(RemovedDup, {{"Saler", type text}, {"Segment", type text}, {"Country", type text}})
in
    Renamed


---

8) Reorganizar e otimizar colunas e tipos (boas práticas)

Em todas as tabelas, verifique tipos numéricos como Decimal Number e inteiros como Whole Number.

Crie chaves únicas quando necessário (ex.: D_Produtos pode ter ID_Produto como chave).

Remova colunas que não são usadas nos relatórios para reduzir o tamanho do modelo.

Marque tabelas de apoio (ex.: Financials_origem) como ocultas no modelo.



---

9) Criar D_Calendario — EM DAX (requisito do desafio)

A criação da D_Calendario foi solicitada em DAX com CALENDAR() (não em Power Query). Exemplo de tabela calculada DAX:

D_Calendario =
ADDCOLUMNS(
    CALENDAR( MIN(F_Vendas[Date]), MAX(F_Vendas[Date]) ),
    "DateKey", FORMAT([Date],"YYYYMMDD"),
    "Year", YEAR([Date]),
    "MonthNumber", MONTH([Date]),
    "MonthName", FORMAT([Date],"MMMM"),
    "Quarter", "Q" & FORMAT([Date],"Q"),
    "YearMonth", FORMAT([Date],"YYYY-MM"),
    "Day", DAY([Date]),
    "WeekOfYear", WEEKNUM([Date])
)

Boas práticas para o calendário

Defina DateKey (inteiro YYYYMMDD) para relacionamentos rápidos.

Adicione colunas fiscais se necessário (FiscalYear, FiscalMonth).

Marque D_Calendario[Date] como Date no modelo e defina como tabela de datas padrão (se aplicável).



---

10) Relacionamentos e Modelagem

1. Vá para a Model view.


2. Crie relacionamentos (1 → N):

D_Produtos[ID_Produto] (1) → F_Vendas[ID_Produto] (N)

D_Calendario[Date] (1) → F_Vendas[Date] (N)

D_Descontos[Discount_Band] (1) → F_Vendas[Discount_Band] (N) (se chave consistente)

D_Detalhes[Saler] (1) → F_Vendas[Saler] (N) (ou use surrogate key se necessário)



3. Verifique direção do filtro (por padrão, de dimensão para fato).


4. Ajuste cardinalidades se alguma dimensão tiver duplicidade inesperada.




---

11) Medidas e colunas calculadas (sugestão para implementar em DAX)

Alguns exemplos que mencionamos no /docs/dax_formulas.md (recomendo criar em DAX dentro do Power BI):

Total Sales = SUMX(F_Vendas, F_Vendas[Sales_Price] * F_Vendas[Units_Sold])

Total Units = SUM(F_Vendas[Units_Sold])

Median Sales Price = MEDIANX(VALUES(F_Vendas[SK_ID]), F_Vendas[Sales_Price])

Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)



---

12) Validação e QA (Quality Assurance)

Compare SUM(SalesAmount) da F_Vendas com agregações da Financials_origem.

Verifique contagem de linhas por produto: COUNTROWS na D_Produtos vs. GROUP BY no Financials_origem.

Inspecione valores extremos (preços > 99 percentil).

Teste slicers/filtros no relatório para garantir performance.



---

13) Exportar artefatos para o repositório

Salve o arquivo .pbix em /powerbi/dashboardEcommerce.pbix.

No Power BI Desktop: Model view > View > Diagram View → exporte como imagem → salvar em /docs/ER_diagram.png.

Exporte screenshots das páginas do dashboard para /images/.

Exporte passos do Power Query (Advanced Editor) para /src/powerquery_steps.txt (copie o M gerado).



---

14) Observações finais / recomendações avançadas

Se o arquivo .pbix ficar grande (>50MB), use Git LFS para versionar ou publique o .pbix nas Releases do GitHub.

Prefira medidas DAX para cálculos dinâmicos que dependem de contexto de filtro; prefira Power Query para limpeza/transformações que não mudam com filtro.

Documente cada transformação no /docs/process.md (este arquivo) e inclua comentários nas etapas M (via // comentário) para facilitar revisão por avaliadores.

Registre os requisitos de hardware e software no /docs/requirements.md.



---

Anexos: Função auxiliar de mediana (se List.Median não estiver disponível)

Caso sua versão do Power Query não ofereça List.Median, adicione uma função personalizada fnMedian:

(fnMedian) =>
let
    list = _,
    sorted = List.Sort(list),
    count = List.Count(sorted),
    median =
        if count = 0 then null
        else if Number.Mod(count, 2) = 1
            then List.Skip(sorted, Number.IntegerDivide(count,2)){0}
            else
                let
                    idx = Number.IntegerDivide(count,2),
                    a = List.Skip(sorted, idx-1){0},
                    b = List.Skip(sorted, idx){0}
                in
                    (a + b) / 2
in
    median

Uso (exemplo dentro de Table.Group):

{"Median_SalesPrice", each fnMedian([Sales Price]), type nullable number}


---

**Histórico e autoria**

Documento gerado por: Sérgio Santos

Data: 2025

Objetivo: documentação técnica completa para entrega do desafio "Modelando um Dashboard de E-commerce com Power BI Utilizando Fórmulas DAX".



---




