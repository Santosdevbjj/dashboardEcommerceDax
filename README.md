# 🛒 Dashboard de E-commerce — Star Schema + DAX + Power BI

<img width="1080" height="696" alt="Screenshot_20260311-222319" src="https://github.com/user-attachments/assets/0d6463eb-4cdd-469a-a1c5-568cd5d9aa6d" />



**Modelagem Dimensional e Análise com Power BI**

---

## 1. Problema de Negócio

Um arquivo CSV com dados transacionais de vendas responde uma pergunta por vez — e apenas para quem sabe escrever uma fórmula. Para qualquer outra área da empresa, esses dados são invisíveis.

O problema real de um e-commerce é mais específico: **como responder simultaneamente perguntas como "qual produto tem a maior margem de lucro?", "como crescemos em relação ao ano anterior?" e "quais segmentos geram mais desconto?" — de forma dinâmica, sem depender de um analista de plantão para cada consulta?**

A resposta exige sair do dado bruto e construir um modelo analítico. Não basta importar uma planilha no Power BI — é preciso modelar dimensões, criar uma tabela fato coerente, estabelecer uma tabela de calendário e escrever medidas DAX que respondam perguntas de negócio com precisão e performance.

Este projeto faz exatamente isso: transforma a base **Financial Sample** — uma planilha plana de transações comerciais — em um modelo dimensional completo capaz de alimentar um dashboard corporativo interativo.

---

## 2. Contexto

Este projeto foi desenvolvido como desafio de modelagem e análise de dados no **Bootcamp NTT DATA**, com foco em modelagem dimensional (Star Schema) e DAX aplicado a cenários reais de e-commerce.

A base **Financial Sample** simula as operações de vendas de uma empresa com múltiplos produtos, segmentos de clientes, países e canais de distribuição. Os dados incluem preço de venda, unidades vendidas, custo de manufatura, desconto por faixa e lucro por transação — todos armazenados de forma desnormalizada em uma única tabela plana.

O desafio técnico foi duplo: primeiro, **modelar esses dados em um esquema dimensional** (Star Schema) que separasse fatos de dimensões e viabilizasse análises cruzadas. Segundo, **escrever medidas DAX** que fossem além de somas simples — calculando margens, rankings dinâmicos, crescimento anual (YoY) e classificações inteligentes de produtos por faixa de preço.

O resultado é um dashboard de quatro páginas navegáveis, com KPIs interativos, filtros por dimensão e análises temporais por mês, trimestre e ano.

---

## 3. Premissas da Modelagem

Para a construção do modelo analítico, as seguintes premissas foram adotadas:

- **Fonte única e imutável:** a tabela `Financials_origem` é mantida como backup oculto no modelo. Todas as tabelas dimensão e fato são derivadas dela — nenhuma transformação altera a origem.
- **Star Schema como padrão arquitetural:** a tabela fato `F_Vendas` contém apenas métricas e chaves estrangeiras. Atributos descritivos pertencem exclusivamente às dimensões — eliminando ambiguidade e garantindo que os filtros se propaguem corretamente.
- **D_Calendario gerada via DAX:** a tabela de calendário é construída dinamicamente com `CALENDAR()` entre a menor e a maior data presente nos dados — garantindo que nenhuma data fique descoberta, independentemente do intervalo da base.
- **Medidas calculadas, não colunas:** KPIs como `Total Sales`, `Profit Margin %` e `YoY Growth %` são medidas DAX, não colunas calculadas. Isso garante que respondam corretamente ao contexto de filtro do relatório em tempo de execução.
- **`DIVIDE` em vez de divisão direta:** todas as divisões usam `DIVIDE(numerador, denominador, 0)` para evitar erros quando o denominador é zero — padrão de robustez para medidas financeiras.

---

## 4. Estratégia da Solução

A construção seguiu um pipeline estruturado em seis etapas:

**Etapa 1 — Importação e proteção da origem**
O arquivo `financial_sample.csv` foi importado no Power BI e renomeado para `Financials_origem`. A consulta foi ocultada no modelo para que nunca seja usada diretamente em visuais — apenas como fonte das demais tabelas. Esse padrão garante rastreabilidade: qualquer alteração futura na origem pode ser inspecionada sem risco de corromper o modelo.

**Etapa 2 — Limpeza e transformação no Power Query**
Padronização de tipos de dados (decimal para preços e lucro, date para datas), normalização dos nomes de colunas e remoção de registros inconsistentes. Criação de `ID_produto` como chave de relacionamento entre as tabelas.

**Etapa 3 — Modelagem dimensional (DAX)**
Construção das cinco tabelas do modelo via DAX:
- `D_Produtos` com `SUMMARIZE + ADDCOLUMNS` — estatísticas agregadas por produto (média, mediana, máximo e mínimo de preço de venda)
- `D_Produtos_Detalhes` com `SUMMARIZE` — atributos individuais de preço, unidades e custo de manufatura
- `D_Descontos` com `SUMMARIZE` — faixas e valores de desconto por produto
- `D_Calendario` com `ADDCOLUMNS(CALENDAR(...))` — dimensão temporal com ano, mês, trimestre, semana e número do mês para ordenação
- `F_Vendas` com `SELECTCOLUMNS` — tabela fato limpa com apenas as colunas necessárias para análise

**Etapa 4 — Relacionamentos e cardinalidades**
Relacionamentos definidos entre `F_Vendas` e cada dimensão, com verificação de cardinalidade (1:N) e direção de filtro (dimensão → fato). A `D_Calendario` foi marcada como tabela de datas para habilitar funções de inteligência de tempo no DAX.

**Etapa 5 — Medidas DAX**
Onze medidas implementadas cobrindo vendas, lucro, margem, mediana, ranking, crescimento anual e análise de desconto. As medidas mais sofisticadas usam os padrões `VAR/RETURN` para legibilidade e `TOPN + SELECTEDVALUE` para análises dinâmicas de Top N produtos.

**Etapa 6 — Design do Dashboard**
Quatro páginas navegáveis construídas com os dados do modelo: Visão Geral com KPIs principais, Análise de Produtos com ranking e classificação, Tendência Temporal com crescimento mês a mês e ano a ano, e Tabela de Detalhes com filtros interativos por país, segmento e faixa de desconto.

---

## 5. Decisões Técnicas

**Por que Star Schema e não uma tabela plana?**
Uma tabela plana — como o CSV original — funciona para análises simples, mas quebra quando as perguntas se tornam cruzadas. "Qual a margem por produto em cada país, filtrando apenas clientes Premium?" exige que filtros se propaguem corretamente entre entidades distintas. O Star Schema foi a única estrutura que viabilizou isso sem criar medidas com lógica condicional complexa para compensar um modelo ruim.

**Por que `ADDCOLUMNS + SUMMARIZE` para `D_Produtos` em vez de Power Query?**
O Power Query resolve bem transformações de linha, mas agregar estatísticas por grupo (média, mediana, máximo por produto) é muito mais natural e eficiente em DAX — que opera diretamente sobre o modelo relacional já carregado. Além disso, manter a lógica de agregação em DAX permite que a dimensão responda a alterações no modelo sem refazer o ETL.

**Por que `MEDIANX` em vez de `MEDIAN`?**
`MEDIAN` opera sobre uma coluna inteira. `MEDIANX` itera linha a linha sobre um contexto específico — neste caso, sobre os valores únicos de `SK_ID` — garantindo que a mediana seja calculada corretamente quando há filtros ativos no relatório, evitando o erro clássico de mediana ignorar o contexto de linha.

**Por que `RANKX(ALL(...), ..., , DESC, DENSE)`?**
O argumento `ALL(D_Produtos)` remove qualquer filtro ativo na dimensão de produtos antes de calcular o ranking — garantindo que o produto sempre seja ranqueado em relação a todos os outros, independentemente dos filtros do relatório. `DENSE` elimina lacunas na sequência quando produtos empatam.

**Por que `VAR/RETURN` no `YoY Growth %`?**
O padrão `VAR/RETURN` não é apenas estético — ele armazena o resultado intermediário de `[Total Sales]` e `DATEADD(...)` em variáveis, evitando que o motor DAX avalie a mesma expressão duas vezes. Em modelos com alto volume de dados, isso tem impacto direto na performance de renderização do relatório.

**O que eu faria diferente hoje?**
Publicaria o modelo no **Power BI Service** com atualização incremental configurada e criaria um **parâmetro de What-If** para simular cenários de margem — por exemplo, "o que acontece com o lucro total se reduzirmos o desconto médio em 5%?". Também implementaria **RLS (Row-Level Security)** para controlar o acesso por país ou segmento de cliente.

---

## 6. Insights do Desenvolvimento

Durante a construção do projeto, ficou evidente que:

- **O modelo é mais importante que o visual.** Um dashboard bonito sobre um modelo ruim produz respostas erradas de forma elegante. A decisão de construir o Star Schema antes de criar qualquer visual foi o que garantiu que todas as métricas respondessem corretamente aos filtros — incluindo os cruzamentos mais complexos entre produto, país e período.
- **`D_Calendario` é indispensável para inteligência de tempo.** Sem uma tabela de datas marcada como tal, funções como `DATEADD` e `SAMEPERIODLASTYEAR` não funcionam. O `YoY Growth %` só foi possível porque a `D_Calendario` foi criada e configurada corretamente — não apenas importada.
- **`SWITCH(TRUE(), ...)` é o padrão correto para classificações condicionais.** O `Product Index` classifica produtos em Low, Medium, High e Premium com base no preço médio. Usar `IF` aninhados produziria o mesmo resultado, mas com legibilidade zero. `SWITCH(TRUE(), ...)` torna a intenção explícita e o código auditável.
- **Backup de origem é uma prática de governança, não de paranoia.** Manter `Financials_origem` oculta no modelo permite rastrear a origem de qualquer valor em qualquer tabela derivada. Em projetos reais com múltiplas fontes e atualizações frequentes, essa prática evita horas de diagnóstico quando um número "muda sozinho".

---

## 7. Resultados

Com o modelo completo implementado, o projeto entrega:

- ✅ Star Schema com 4 dimensões + 1 tabela fato totalmente relacionadas e auditáveis
- ✅ 11 medidas DAX cobrindo vendas, lucro, margem, mediana, ranking, Top N dinâmico e crescimento anual (YoY)
- ✅ Dashboard de 4 páginas interativas com KPIs, rankings, tendências temporais e tabela de detalhes com filtros cruzados
- ✅ Classificação dinâmica de produtos por faixa de preço (`Product Index`) e ranking por receita (`Product Rank`)
- ✅ Análise de crescimento anual de vendas (YoY) habilitada pela `D_Calendario` com inteligência de tempo

---

## 8. Próximos Passos

- [ ] Publicar no **Power BI Service** com atualização agendada e compartilhamento via link
- [ ] Implementar **parâmetro What-If** para simulação de cenários de desconto e margem
- [ ] Adicionar **RLS (Row-Level Security)** para controle de acesso por país ou segmento
- [ ] Criar página de **Análise de Cohort** — comportamento de recompra por segmento ao longo do tempo
- [ ] Conectar a uma fonte de dados dinâmica (Azure SQL ou SharePoint) para substituir o CSV estático

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Finalidade |
|---|---|
| Power BI Desktop | Modelagem dimensional, DAX e design do dashboard |
| Power Query (M) | ETL — limpeza, tipagem e transformação dos dados |
| DAX | Tabelas calculadas, colunas e medidas dinâmicas |
| Git + GitHub | Versionamento e documentação do projeto |

---

## 🧮 Modelo Dimensional — Star Schema

```
                    D_Calendario
                        │
          D_Descontos ──┤
                        │
D_Produtos_Detalhes ────┼──── F_Vendas (tabela fato)
                        │
              D_Produtos─┘
```

| Tipo | Tabela | Descrição |
|---|---|---|
| Backup | `Financials_origem` | Tabela original, mantida oculta — fonte de todas as demais |
| Dimensão | `D_Produtos` | Estatísticas agregadas por produto (média, mediana, máx, mín) |
| Dimensão | `D_Produtos_Detalhes` | Atributos individuais: preço, unidades, custo de manufatura |
| Dimensão | `D_Descontos` | Faixas e valores de desconto por produto |
| Dimensão | `D_Calendario` | Gerada via `ADDCOLUMNS(CALENDAR(...))` com ano, mês, trimestre e semana |
| Fato | `F_Vendas` | Transações consolidadas: vendas, lucro, unidades, segmento e país |

---

## 🧠 Medidas DAX Implementadas

```dax
-- Total de vendas (SUMX para contexto de linha correto)
Total Sales = SUMX(F_Vendas, F_Vendas[SalesPrice] * F_Vendas[UnitsSold])

-- Margem de lucro com proteção contra divisão por zero
Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)

-- Crescimento anual com padrão VAR/RETURN
YoY Growth % =
VAR CurrYear = [Total Sales]
VAR PrevYear = CALCULATE([Total Sales], DATEADD(D_Calendario[Date], -1, YEAR))
RETURN DIVIDE(CurrYear - PrevYear, PrevYear, 0)

-- Classificação dinâmica por faixa de preço
Product Index =
SWITCH(
    TRUE(),
    [Average Sales Price] >= 1000, "Premium",
    [Average Sales Price] >= 500,  "High",
    [Average Sales Price] >= 100,  "Medium",
    "Low"
)

-- Ranking por receita média, removendo filtros do contexto
Product Rank = RANKX(ALL(D_Produtos), [Average Sales Price], , DESC, DENSE)

-- Top N dinâmico via parâmetro selecionável
Top N Sales =
VAR N = SELECTEDVALUE(Parameters[TopN], 10)
RETURN CALCULATE([Total Sales], TOPN(N, VALUES(D_Produtos[ID_Produto]), [Total Sales], DESC))
```

> Todas as fórmulas completas e comentadas estão em [`/docs/dax_formulas.md`](docs/dax_formulas.md)

---

## 📂 Estrutura do Repositório

```
dashboardEcommerceDax/
├── data/
│   └── financial_sample.csv              # Base de dados original (Financial Sample)
├── powerbi/
│   └── dashboardEcommerce.pbix           # Arquivo Power BI com modelo, DAX e relatórios
├── docs/
│   ├── ER_diagram.png                    # Diagrama do Star Schema
│   ├── dax_formulas.md                   # Todas as fórmulas DAX documentadas e comentadas
│   ├── process.md                        # Descrição do processo de modelagem e ETL
│   └── requirements.md                   # Requisitos de hardware e software
├── images/
│   ├── overview_kpis.png                 # Página 1 — Visão Geral (KPIs)
│   └── product_analysis.png              # Página 2 — Análise de Produtos
└── src/
    ├── etl_export_sql.sql                # Script SQL auxiliar de extração (opcional)
    └── powerquery_steps.txt              # Passos M exportados do Power Query
```

---

## ▶️ Como Abrir o Projeto

**Pré-requisitos:** Power BI Desktop 2023 ou superior, Windows 10/11

1. Clone o repositório:
```bash
git clone https://github.com/Santosdevbjj/dashboardEcommerceDax.git
```
2. Abra o arquivo `powerbi/dashboardEcommerce.pbix` no Power BI Desktop
3. Se necessário, atualize o caminho da fonte de dados apontando para `data/financial_sample.csv`
4. Clique em **Atualizar** para recarregar os dados e renderizar o dashboard

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License** — consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## Autor

**Sergio Santos**

[![Portfólio](https://img.shields.io/badge/Portfólio-Sérgio_Santos-111827?style=for-the-badge&logo=githubpages&logoColor=00eaff)](https://portfoliosantossergio.vercel.app)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Sérgio_Santos-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/santossergioluiz)
