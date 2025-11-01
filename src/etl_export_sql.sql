/**********************************************************************************************
* PROJETO: DASHBOARD E-COMMERCE — POWER BI + DAX
* ARQUIVO: /src/etl_export_sql.sql
* AUTOR: Sérgio Santos
* DATA: Novembro/2025
* DESCRIÇÃO:
*     Este script SQL realiza a simulação do processo ETL (Extract, Transform, Load)
*     para estruturar os dados de amostra "Financial Sample" em um modelo relacional
*     de Data Warehouse (Star Schema), pronto para integração com o Power BI.
*
* COMPATIBILIDADE:
*     PostgreSQL 14+ | SQL Server 2019+ | MySQL 8+ (pequenas adaptações de sintaxe)
**********************************************************************************************/


/**********************************************************************************************
* 1️⃣ ETAPA EXTRACT — Criação da tabela origem (Financial Sample)
**********************************************************************************************/

DROP TABLE IF EXISTS financials_origem;
CREATE TABLE financials_origem (
    sk_id SERIAL PRIMARY KEY,
    id_produto VARCHAR(50),
    produto VARCHAR(255),
    units_sold INT,
    sales_price DECIMAL(18,2),
    manufacturing_price DECIMAL(18,2),
    discount DECIMAL(10,4),
    discount_band VARCHAR(50),
    segment VARCHAR(100),
    country VARCHAR(100),
    saler VARCHAR(100),
    profit DECIMAL(18,2),
    dt_venda DATE
);

-- Exemplo de carga (substitua pelo caminho real do CSV)
-- PostgreSQL:
-- COPY financials_origem (id_produto, produto, units_sold, sales_price, manufacturing_price,
--                         discount, discount_band, segment, country, saler, profit, dt_venda)
-- FROM '/data/financial_sample.csv'
-- DELIMITER ',' CSV HEADER ENCODING 'UTF8';


/**********************************************************************************************
* 2️⃣ ETAPA TRANSFORM — Criação das tabelas dimensão e fato
**********************************************************************************************/

-- ============================================================================
-- DIMENSÃO PRODUTOS (D_PRODUTOS)
-- ============================================================================

DROP TABLE IF EXISTS d_produtos;
CREATE TABLE d_produtos AS
SELECT
    id_produto,
    produto,
    ROUND(AVG(units_sold)::numeric, 2) AS media_unidades,
    ROUND(AVG(sales_price)::numeric, 2) AS media_preco_venda,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_price) AS mediana_venda,
    MAX(sales_price) AS max_venda,
    MIN(sales_price) AS min_venda,
    COUNT(*) AS total_transacoes
FROM financials_origem
GROUP BY id_produto, produto
ORDER BY produto;


-- ============================================================================
-- DIMENSÃO PRODUTOS DETALHES (D_PRODUTOS_DETALHES)
-- ============================================================================

DROP TABLE IF EXISTS d_produtos_detalhes;
CREATE TABLE d_produtos_detalhes AS
SELECT DISTINCT
    id_produto,
    produto,
    discount_band,
    sales_price,
    units_sold,
    manufacturing_price
FROM financials_origem
ORDER BY id_produto;


-- ============================================================================
-- DIMENSÃO DESCONTOS (D_DESCONTOS)
-- ============================================================================

DROP TABLE IF EXISTS d_descontos;
CREATE TABLE d_descontos AS
SELECT
    discount_band,
    ROUND(AVG(discount)::numeric, 4) AS avg_discount,
    ROUND(MIN(discount)::numeric, 4) AS min_discount,
    ROUND(MAX(discount)::numeric, 4) AS max_discount,
    COUNT(DISTINCT id_produto) AS total_produtos
FROM financials_origem
GROUP BY discount_band
ORDER BY discount_band;


-- ============================================================================
-- DIMENSÃO DETALHES (VENDEDORES, SEGMENTO, PAÍS)
-- ============================================================================

DROP TABLE IF EXISTS d_detalhes;
CREATE TABLE d_detalhes AS
SELECT DISTINCT
    saler,
    segment,
    country
FROM financials_origem
ORDER BY country, saler;


-- ============================================================================
-- TABELA FATO VENDAS (F_VENDAS)
-- ============================================================================

DROP TABLE IF EXISTS f_vendas;
CREATE TABLE f_vendas AS
SELECT
    fo.sk_id AS sk_id,
    fo.id_produto,
    fo.produto,
    fo.dt_venda AS data_venda,
    fo.units_sold AS unidades_vendidas,
    fo.sales_price AS preco_unitario,
    (fo.units_sold * fo.sales_price) AS total_venda,
    fo.discount AS percentual_desconto,
    fo.discount_band AS faixa_desconto,
    fo.segment AS segmento,
    fo.country AS pais,
    fo.saler AS vendedor,
    fo.profit AS lucro,
    fo.manufacturing_price AS custo_fabricacao
FROM financials_origem fo
WHERE fo.units_sold > 0 AND fo.sales_price > 0
ORDER BY fo.dt_venda;


-- ============================================================================
-- DIMENSÃO CALENDÁRIO (D_CALENDARIO)
-- ============================================================================

DROP TABLE IF EXISTS d_calendario;
CREATE TABLE d_calendario AS
WITH limites AS (
    SELECT MIN(dt_venda) AS data_inicial, MAX(dt_venda) AS data_final FROM financials_origem
),
datas AS (
    SELECT generate_series(
        (SELECT data_inicial FROM limites),
        (SELECT data_final FROM limites),
        interval '1 day'
    )::date AS data
)
SELECT
    data,
    EXTRACT(YEAR FROM data)::int AS ano,
    EXTRACT(MONTH FROM data)::int AS mes_num,
    TO_CHAR(data, 'TMMonth') AS mes_nome,
    EXTRACT(DAY FROM data)::int AS dia,
    EXTRACT(QUARTER FROM data)::int AS trimestre,
    TO_CHAR(data, 'YYYY-MM') AS ano_mes,
    EXTRACT(WEEK FROM data)::int AS semana_ano,
    TO_CHAR(data, 'YYYYMMDD')::int AS chave_data
FROM datas
ORDER BY data;


-- ============================================================================
-- CRIAÇÃO DE CHAVES PRIMÁRIAS E RELACIONAMENTOS (opcional, se desejado)
-- ============================================================================

ALTER TABLE d_produtos ADD CONSTRAINT pk_d_produtos PRIMARY KEY (id_produto);
ALTER TABLE d_descontos ADD CONSTRAINT pk_d_descontos PRIMARY KEY (discount_band);
ALTER TABLE d_detalhes ADD CONSTRAINT pk_d_detalhes PRIMARY KEY (saler, country);
ALTER TABLE d_calendario ADD CONSTRAINT pk_d_calendario PRIMARY KEY (chave_data);

-- Exemplo de foreign keys (desativar se preferir performance em DW):
-- ALTER TABLE f_vendas
--   ADD CONSTRAINT fk_produto FOREIGN KEY (id_produto) REFERENCES d_produtos(id_produto),
--   ADD CONSTRAINT fk_calendario FOREIGN KEY (data_venda) REFERENCES d_calendario(data);


-- ============================================================================
-- 3️⃣ ETAPA LOAD — Exportação dos dados tratados (para Power BI)
-- ============================================================================

-- PostgreSQL: Exportar tabelas tratadas para CSV (ajuste caminho conforme seu ambiente)

-- \COPY f_vendas TO '/data/export/f_vendas.csv' CSV HEADER ENCODING 'UTF8';
-- \COPY d_produtos TO '/data/export/d_produtos.csv' CSV HEADER ENCODING 'UTF8';
-- \COPY d_produtos_detalhes TO '/data/export/d_produtos_detalhes.csv' CSV HEADER ENCODING 'UTF8';
-- \COPY d_descontos TO '/data/export/d_descontos.csv' CSV HEADER ENCODING 'UTF8';
-- \COPY d_detalhes TO '/data/export/d_detalhes.csv' CSV HEADER ENCODING 'UTF8';
-- \COPY d_calendario TO '/data/export/d_calendario.csv' CSV HEADER ENCODING 'UTF8';

-- Após essa exportação, os arquivos .CSV podem ser utilizados no Power BI Desktop.


/**********************************************************************************************
* 🔧 Observações Finais:
* - Este script pode ser adaptado para PostgreSQL, SQL Server ou MySQL.
* - Todas as tabelas seguem convenções do modelo em estrela (Star Schema).
* - No Power BI, o relacionamento deve ser criado entre:
*       f_vendas.id_produto → d_produtos.id_produto
*       f_vendas.faixa_desconto → d_descontos.discount_band
*       f_vendas.vendedor → d_detalhes.saler
*       f_vendas.data_venda → d_calendario.data
*
* - As métricas e medidas adicionais (lucro, margem, ranking, índice de produto)
*   devem ser criadas em DAX dentro do Power BI.
**********************************************************************************************/
