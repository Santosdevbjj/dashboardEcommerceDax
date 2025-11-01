# /docs/requirements.md

# 💻 Requisitos Técnicos — Projeto Dashboard E-commerce Power BI + DAX


---

## 🧠 Objetivo deste Documento

Este documento lista os **requisitos técnicos mínimos e recomendados** para abrir, editar e executar corretamente o projeto **Dashboard E-commerce — Modelagem com Power BI e DAX**, garantindo compatibilidade total com as bibliotecas e recursos utilizados (Power Query, DAX, CALENDAR, etc).

---

## 🧰 Software Necessário

| Software / Ferramenta | Descrição | Versão Recomendada |
|------------------------|-----------|--------------------|
| **Power BI Desktop** | Ferramenta principal para modelagem, transformação e visualização de dados. | **Versão: Outubro/2024 (2.136.1234.0)** ou superior |
| **Microsoft Excel** *(opcional)* | Usado para validação cruzada e exportação de dados. | 2019 / Microsoft 365 |
| **Git** | Controle de versão e integração com o repositório GitHub. | 2.40 ou superior |
| **Git LFS** *(opcional)* | Necessário apenas se o arquivo `.pbix` ultrapassar 50 MB. | Última versão |
| **Navegador Web (Edge / Chrome)** | Para acesso ao Power BI Service ou GitHub Pages. | Atualizado |
| **Editor de texto (VS Code / Notepad++)** | Para edição dos arquivos `.md` e `.txt` do projeto. | Qualquer versão recente |

---

## 🧱 Requisitos de Hardware

| Componente | Mínimo | Recomendado |
|-------------|---------|-------------|
| **Processador (CPU)** | Dual-Core 2.0 GHz | Quad-Core i5 / Ryzen 5 ou superior |
| **Memória RAM** | 8 GB | 16 GB (ideal para modelos grandes e uso intensivo de DAX) |
| **Armazenamento** | 10 GB livres | SSD com 50 GB livres |
| **GPU (opcional)** | Integrada | Dedicada (para visualizações complexas) |
| **Resolução de Tela** | 1366×768 | Full HD (1920×1080) ou superior |
| **Sistema Operacional** | Windows 10 (x64) | Windows 11 (x64, build 22H2 ou superior) |

---

## 🌐 Conectividade e Configuração

- **Conexão com Internet:**  
  Necessária para atualizações do Power BI, GitHub, downloads e pacotes de idioma.

- **Idioma do Power BI:**  
  Português (Brasil) ou Inglês (compatível com fórmulas DAX em inglês).

- **Regional Settings:**  
  Recomendado: `pt-BR` (Data no formato DD/MM/AAAA e separador decimal “,”).

- **Permissões:**  
  O usuário deve ter permissão de leitura/gravação na pasta de trabalho (onde o `.pbix` está salvo).

---

## 📊 Versões e Dependências DAX / Power Query

O projeto utiliza funções compatíveis com as versões atuais do Power BI Desktop (2023+), incluindo:

### 🔹 Funções DAX utilizadas:
- `CALENDAR()`
- `ADDCOLUMNS()`
- `SUMMARIZE()`
- `CALCULATE()`
- `MEDIANX()`
- `RANKX()`
- `DIVIDE()`
- `SWITCH()`
- `VALUES()`
- `SELECTCOLUMNS()`

> ⚠️ **Observação:** As funções acima requerem versão mínima **Power BI Desktop ≥ Maio/2022**.  
> Recomenda-se usar a **versão Outubro/2024 ou mais recente**, pois inclui melhorias de performance no Power Query e DAX Engine (VertiPaq v3).

### 🔹 Funções Power Query (M) utilizadas:
- `Table.Group`
- `List.Average`, `List.Median`, `List.Max`, `List.Min`
- `Table.SelectRows`, `Table.Distinct`
- `Table.AddColumn`
- `Table.TransformColumnTypes`
- `Table.ReplaceValue`
- `Csv.Document`
- `Text.Trim`

> Se estiver usando Power BI em versões antigas, substitua `List.Median` por uma função personalizada (ver `/docs/process.md`, seção "Função auxiliar de mediana").

---

## ⚙️ Configuração do Projeto no Power BI

### 1. **Estrutura de Arquivos**
Certifique-se de manter os diretórios no mesmo formato do repositório: 



/data/financial_sample.csv /powerbi/dashboardEcommerce.pbix /docs/*.md /src/powerquery_steps.txt /images/

---


### 2. **Localização dos Dados**
- Atualize o caminho do arquivo `financial_sample.csv` no Power Query caso o projeto seja movido de pasta.
- Utilize `File.Contents()` com caminho relativo se quiser portabilidade total (Power BI > Transformar Dados > Gerenciar Fonte de Dados).

### 3. **Regionalização**
- Se a base estiver em formato americano (datas no formato `MM/DD/YYYY`), ajuste no Power Query:
  ```m
  Table.TransformColumnTypes(#"Previous Step", {{"Date", type date}}, "en-US")


  ---


**Para formato brasileiro:**

Table.TransformColumnTypes(#"Previous Step", {{"Date", type date}}, "pt-BR")



---

🧩 **Compatibilidade e Performance**

Recurso	Impacto	Recomendação

Star Schema	Alta performance	Sempre preferir modelo em estrela
Tabelas Agregadas (D_Produtos)	Reduz volume da Fato	Ideal para relatórios com filtros
Medidas DAX com CALCULATE e SUMX	Custo médio	Avaliar dependência de filtros complexos
DAX com RANKX e SWITCH	Pode exigir mais CPU	Evite em relatórios com milhares de linhas


> 🔧 Dica: mantenha o tamanho da tabela fato (F_Vendas) abaixo de 1 milhão de linhas para garantir fluidez no Power BI Desktop.




---

🔐 **Segurança e Boas Práticas**

Utilize backup da tabela original (Financials_origem) oculta no modelo.

Evite deixar colunas sensíveis expostas em tabelas fato.

Use nomes consistentes (ex.: ID_Produto, Sales_Price, Units_Sold) para facilitar manutenção.

Configure o auto recovery do Power BI (File → Options → Auto Recovery → 5 min).



---

🧾 **Verificação Final (Checklist)**

Item	Status

✅ Power BI Desktop atualizado (Outubro/2024 ou superior)	☐
✅ Base financial_sample.csv conectada corretamente	☐
✅ Todas as queries criadas no Power Query Editor	☐
✅ Tabela D_Calendario criada em DAX com CALENDAR()	☐
✅ Relacionamentos verificados (1:N)	☐
✅ F_Vendas validada (sem nulos ou duplicados)	☐
✅ Dashboard salvo em /powerbi/dashboardEcommerce.pbix	☐
✅ README.md completo no repositório	☐
✅ Documentação /docs e /src revisadas	☐





---

🧾 **Referências Técnicas**

Microsoft Docs – Funções DAX

Microsoft Docs – Power Query M Reference

Power BI Blog – Versões e Atualizações Recentes



---

✍️ **Autor**

Sérgio Santos
📅 Atualizado em: Novembro/2025


---

**Resumo Final:**

> Este documento define o ambiente ideal para abrir, rodar e avaliar o projeto Dashboard E-commerce Power BI, garantindo compatibilidade total com os recursos de transformação de dados (Power Query), modelagem em estrela (Star Schema) e fórmulas DAX aplicadas para criação de medidas e KPIs.





  



