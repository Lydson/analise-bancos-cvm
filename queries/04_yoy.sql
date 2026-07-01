-- ============================================
-- PROJETO: Análise Financeira Banco do Brasil (2016-2025)
-- ARQUIVO: 04_yoy.sql
-- OBJETIVO: Calcular variação Year over Year (YoY) do
--           Lucro Líquido e da Receita de Intermediação
-- ============================================
--
-- CONCEITO:
-- YoY (Year over Year) mede a variação percentual de um indicador
-- em relação ao mesmo período do ano anterior.
-- Fórmula: (valor_atual - valor_anterior) / valor_anterior * 100
--
-- CONCEITO SQL NOVO: Window Functions com LAG()
-- LAG() é uma window function — diferente de SUM() e COUNT(),
-- ela NÃO colapsa linhas. Mantém todas as linhas da tabela e
-- adiciona uma coluna nova "olhando para a linha anterior".
--
-- Sintaxe:
--   LAG(coluna, offset) OVER (ORDER BY outra_coluna)
--   - coluna:  qual valor pegar da linha anterior
--   - offset:  quantas linhas para trás (1 = linha anterior)
--   - OVER():  define a "janela" — como ordenar as linhas
--
-- ATENÇÃO: o primeiro ano (2016) retorna NULL para LAG()
-- porque não existe linha anterior — comportamento esperado.
-- ============================================


-- ============================================
-- YoY DO LUCRO LÍQUIDO (2016-2025)
-- ============================================
-- Contas usadas: dois nomes diferentes ao longo dos anos
-- (mudança de nomenclatura da CVM em 2020 — padrão já visto
-- no ROE e na Margem Financeira).
--
-- Resultados relevantes:
--   2020: -29,62% — pandemia, provisões para crédito explodiram
--   2021: +48,37% e 2022: +51,34% — recuperação forte,
--         dois anos consecutivos de crescimento acima de 40%
--   2024: -12,04% e 2025: -42,47% — crise da carteira agro.
--   O -42,47% em 2025 bate com o ROE caindo para 8,67% no mesmo ano.
WITH lucro_anual AS (
  SELECT
    dt_refer,
    vl_conta
  FROM dre
  WHERE
    (ds_conta = 'Lucro/Prejuízo Consolidado do Período'
    OR ds_conta = 'Lucro ou Prejuízo Líquido Consolidado do Período')
    AND ordem_exerc = 'ÚLTIMO'
)
SELECT
  dt_refer,
  vl_conta AS lucro_liquido,
  LAG(vl_conta, 1) OVER (ORDER BY dt_refer) AS lucro_ano_anterior,
  ROUND(
    (vl_conta - LAG(vl_conta, 1) OVER (ORDER BY dt_refer))
    / LAG(vl_conta, 1) OVER (ORDER BY dt_refer) * 100
  , 2) AS variacao_yoy
FROM lucro_anual
ORDER BY dt_refer;


-- ============================================
-- YoY DA RECEITA DE INTERMEDIAÇÃO (2016-2025)
-- ============================================
-- Receita de juros é o principal motor de crescimento de um banco.
-- Acompanhar seu YoY junto com o YoY do lucro revela se o
-- crescimento de receita se converte (ou não) em lucro.
--
-- Resultados relevantes:
--   2016-2020: receita caindo — Selic caiu de 14,25% para 2%
--              (mínima histórica). Banco recebe menos juros
--              quando a taxa básica cai.
--   2022: +87,82% — Selic subiu de 2% para 13,75% em um ano,
--         quase dobrando a receita de juros do BB.
--   2025: +16,80% — receita crescendo com Selic alta, mas lucro
--         caiu 42% no mesmo ano por provisões do agro.
WITH receita_anual AS (
  SELECT
    dt_refer,
    vl_conta
  FROM dre
  WHERE
    (ds_conta = 'Receitas de Intermediação Financeira'
    OR ds_conta = 'Receitas da Intermediação Financeira')
    AND ordem_exerc = 'ÚLTIMO'
)
SELECT
  dt_refer,
  vl_conta AS receita_intermediacao,
  LAG(vl_conta, 1) OVER (ORDER BY dt_refer) AS receita_ano_anterior,
  ROUND(
    (vl_conta - LAG(vl_conta, 1) OVER (ORDER BY dt_refer))
    / LAG(vl_conta, 1) OVER (ORDER BY dt_refer) * 100
  , 2) AS variacao_yoy
FROM receita_anual
ORDER BY dt_refer;


-- ============================================
-- YoY CONSOLIDADO: LUCRO E RECEITA (2016-2025)
-- ============================================
-- Combina as duas CTEs acima com JOIN por dt_refer,
-- mostrando YoY de lucro e receita lado a lado.
--
-- TÉCNICA: duas CTEs encadeadas no mesmo WITH, separadas por vírgula.
-- JOIN entre CTEs usa prefixo (tabela.coluna) para evitar ambiguidade
-- quando duas CTEs têm colunas com o mesmo nome (dt_refer, vl_conta).
-- O prefixo no OVER (ORDER BY tabela.coluna) também é necessário
-- pelo mesmo motivo — sem ele, PostgreSQL retorna erro de ambiguidade.
--
-- INSIGHT PRINCIPAL:
-- Em 2024-2025, receita cresceu (+3% e +17%) mas lucro despencou
-- (-12% e -42%). Isso é a crise do agro em números: a Selic alta
-- trouxe mais receita, mas a inadimplência rural gerou provisões
-- que consumiram todo o crescimento. Crescimento de receita não
-- garante crescimento de lucro quando a inadimplência explode.
WITH lucro_anual AS (
  SELECT
    dt_refer,
    vl_conta
  FROM dre
  WHERE
    (ds_conta = 'Lucro/Prejuízo Consolidado do Período'
    OR ds_conta = 'Lucro ou Prejuízo Líquido Consolidado do Período')
    AND ordem_exerc = 'ÚLTIMO'
),
receita_anual AS (
  SELECT
    dt_refer,
    vl_conta
  FROM dre
  WHERE
    (ds_conta = 'Receitas de Intermediação Financeira'
    OR ds_conta = 'Receitas da Intermediação Financeira')
    AND ordem_exerc = 'ÚLTIMO'
)
SELECT
  receita_anual.dt_refer,
  ROUND(
    (lucro_anual.vl_conta - LAG(lucro_anual.vl_conta, 1) OVER (ORDER BY lucro_anual.dt_refer))
    / LAG(lucro_anual.vl_conta, 1) OVER (ORDER BY lucro_anual.dt_refer) * 100
  , 2) AS yoy_lucro,
  ROUND(
    (receita_anual.vl_conta - LAG(receita_anual.vl_conta, 1) OVER (ORDER BY receita_anual.dt_refer))
    / LAG(receita_anual.vl_conta, 1) OVER (ORDER BY receita_anual.dt_refer) * 100
  , 2) AS yoy_receita
FROM lucro_anual
JOIN receita_anual ON lucro_anual.dt_refer = receita_anual.dt_refer;
