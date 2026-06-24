-- ============================================
-- PROJETO: Análise Financeira Banco do Brasil (2016-2025)
-- ARQUIVO: 02_margem_financeira.sql
-- OBJETIVO: Calcular a Margem Financeira anual do BB
-- ============================================
--
-- CONCEITO:
-- Margem Financeira = Resultado Bruto de Intermediação Financeira
--                     / Receitas de Intermediação Financeira * 100
--
-- É o equivalente à "margem bruta" para bancos:
-- mede quanto sobra da atividade-fim (captar e emprestar)
-- ANTES de despesas operacionais, pessoal e impostos.
--
-- ATENÇÃO: a CVM usou nomes diferentes ao longo dos anos:
--   "Receitas da Intermediação" (2016-2019)
--   "Receitas de Intermediação" (2020-2025)
-- O mesmo ocorre com Resultado Bruto (com/sem preposição "de").
-- Solução: OR para cobrir todas as variações.
-- ============================================


-- ============================================
-- EXPLORAÇÃO: nomes de conta para Intermediação Financeira
-- ============================================
SELECT DISTINCT ds_conta
FROM dre
WHERE ds_conta LIKE '%Intermediação%';


-- ============================================
-- MARGEM FINANCEIRA POR ANO (2016-2025)
-- ============================================
-- Técnica usada: SUM(CASE WHEN ...) para "pivotar" duas contas
-- diferentes (Receita e Resultado Bruto) em colunas separadas,
-- sem precisar de JOIN (ambas estão na mesma tabela dre).
--
-- CTE (Common Table Expression) usada para calcular Receita e
-- Resultado Bruto primeiro, e depois dividir um pelo outro sem
-- repetir os CASE WHEN duas vezes no mesmo SELECT.
--
-- Insight observado:
--   2020: margem salta para 56% — Selic na mínima histórica (2%)
--   reduziu despesas de captação mais que as receitas, inflando
--   a margem bruta. Mas o ROE caiu (10,4%) no mesmo ano, pois
--   provisões para perdas (pandemia) consumiram o resultado final.
--   Isso prova que margem financeira isolada pode enganar.
WITH receitas_resultado AS (
  SELECT
    dt_refer,
    SUM(CASE WHEN ds_conta = 'Receitas de Intermediação Financeira' OR ds_conta = 'Receitas da Intermediação Financeira' THEN vl_conta ELSE 0 END) AS receita_financeira,
    SUM(CASE WHEN ds_conta = 'Resultado Bruto Intermediação Financeira' OR ds_conta = 'Resultado Bruto de Intermediação Financeira' THEN vl_conta ELSE 0 END) AS resultado_bruto
  FROM dre
  WHERE ordem_exerc = 'ÚLTIMO'
  GROUP BY dt_refer
)
SELECT
  dt_refer,
  receita_financeira,
  resultado_bruto,
  ROUND((resultado_bruto / receita_financeira) * 100, 2) AS margem_financeira
FROM receitas_resultado
ORDER BY dt_refer;
