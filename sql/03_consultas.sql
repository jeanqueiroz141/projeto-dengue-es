----------------------------------------------
-- PARTE 1: CONFERÊNCIAS E QUALIDADE DOS DADOS
----------------------------------------------

-- ver o municipio que nao repetiu

SELECT
    p.municipio,
    p.ano
FROM dengue.populacao AS p
LEFT JOIN dengue.casos AS c
    ON c.cod_municipio = p.cod_municipio
   	AND c.ano = p.ano
WHERE c.cod_municipio IS NULL;

-- Período coberto por cada ano
SELECT ano,
	   MIN(semana) as primeira_semana,
	   MAX(semana) as ultima_semana,
       MIN(data_sintomas)    AS primeiro_sintoma,
       MAX(data_sintomas)    AS ultimo_sintoma,
       MIN(data_notificacao) AS primeira_notificacao,
       MAX(data_notificacao) AS ultima_notificacao
FROM dengue.casos
GROUP BY ano
ORDER BY ano;

-- Top 10 de incidência por ano (SE 1 a 36)
SELECT *
FROM dengue.vw_incidencia_municipio
WHERE posicao <= 10
ORDER BY ano, posicao;

-- Quais municípios estão no top 10 dos dois anos?
SELECT 
	a.municipio,
	a.posicao AS posicao_2025, 
	b.posicao AS posicao_2026
FROM dengue.vw_incidencia_municipio a
JOIN dengue.vw_incidencia_municipio b 
ON b.cod_municipio = a.cod_municipio
WHERE a.ano = 2025 AND b.ano = 2026
AND a.posicao <= 10 AND b.posicao <= 10
ORDER BY a.posicao;

-- Quantidade de municipios por ano

SELECT 
	ano, 
	COUNT(DISTINCT cod_municipio) AS municipios
FROM dengue.casos
GROUP BY ano;

-- Casos abertos há mais de 60 dias (prazo de encerramento)
SELECT 
	SUM(CASE WHEN situacao = 'Aberto' 
		AND data_notificacao < DATE '2026-09-27' - 60 
		AND ano = 2026
		THEN 1 ELSE 0 END) AS casos_abertos_2026,
	SUM(CASE WHEN situacao = 'Aberto' 
		AND data_notificacao < DATE '2025-09-27' - 60 
		AND ano = 2025 
		THEN 1 ELSE 0 END) AS casos_abertos_2025
FROM dengue.vw_casos

-----------------------------------------------
-- PARTE 2: RESPONDENDO ÀS PERGUNTAS DO PROJETO
-----------------------------------------------

-- Quantos casos por semana?

SELECT 
	semana,
    SUM(CASE WHEN ano = 2025 THEN 1 ELSE 0 END) AS casos_2025,
    SUM(CASE WHEN ano = 2026 THEN 1 ELSE 0 END) AS casos_2026
FROM dengue.vw_casos
WHERE semana <= 36
GROUP BY semana
ORDER BY semana;

-- Gravidade por faixa etária (todos os casos)
SELECT faixa_etaria,
       COUNT(*) AS casos,
       SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END) AS hospitalizados,
       ROUND(100.0 * SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_hospitalizado,
       ROUND(100.0 * SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END)
             / SUM(SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END)) OVER (), 1) AS pct_das_internacoes,
       ROUND(100.0 * SUM(CASE WHEN classificacao IN ('Dengue com sinais de alarme', 'Dengue grave')
                              THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_alarme_ou_grave
FROM dengue.vw_casos
GROUP BY faixa_etaria
ORDER BY pct_hospitalizado DESC;
-- Concentração de casos por município (volume)

SELECT 	ano, municipio, casos,
		ROUND(100.0 * casos / SUM(casos) OVER (PARTITION BY ano), 1) AS pct_do_total,
		ROUND(100.0 * SUM(casos) OVER (PARTITION BY ano ORDER BY ano, casos DESC)
			/ SUM(casos) OVER (PARTITION BY ano), 1) AS pct_acumulado
FROM dengue.vw_incidencia_municipio
GROUP BY ano, municipio, casos
-- ORDER BY SUM(casos) OVER (PARTITION BY municipio) DESC, municipio, ano;
ORDER BY ano, casos desc;

-- Quantos municípios em cada quadrante
SELECT quadrante, COUNT(*) AS municipios, SUM(casos) AS casos
FROM dengue.vw_matriz_prioridade
GROUP BY quadrante
ORDER BY municipios DESC;


-- Piorou? Variação da incidência de 2025 para 2026 (municípios com pelo menos 30 casos nos dois anos)

SELECT 
	a.municipio, a.casos AS casos_2025, 
	b.casos AS casos_2026, a.incidencia_100mil AS incidencia_2025, 
	b.incidencia_100mil AS incidencia_2026,
	ROUND(b.incidencia_100mil - a.incidencia_100mil, 1) AS diferenca
FROM dengue.vw_incidencia_municipio AS a
JOIN dengue.vw_incidencia_municipio AS b
	ON b.cod_municipio = a.cod_municipio
	AND b.ano = 2026
WHERE a.ano = 2025
  AND a.casos >= 30 AND b.casos >= 30
ORDER BY diferenca DESC
LIMIT 10;


-- Casos sem classificação final por ano (SE 1 a 36)
SELECT ano,
       COUNT(*) AS notificados,
       SUM(CASE WHEN classificacao IN ('Dengue', 'Dengue com sinais de alarme', 'Dengue grave') THEN 1 ELSE 0 END) AS classificados,
       ROUND(100.0 * (COUNT(*) - SUM(CASE WHEN classificacao IN ('Dengue', 'Dengue com sinais de alarme', 'Dengue grave') THEN 1 ELSE 0 END)) / COUNT(*), 1) AS pct_sem_classificacao
FROM dengue.vw_casos
WHERE semana <= 36
GROUP BY ano
ORDER BY ano;


-- Grande Vitória e interior (SE 1 a 36)
SELECT ano,
       CASE WHEN municipio IN ('Vitória', 'Vila Velha', 'Serra', 'Cariacica', 'Viana', 'Guarapari', 'Fundão')
            THEN 'Grande Vitória' ELSE 'Interior' END AS regiao,
       SUM(casos) AS casos,
       ROUND(100.0 * SUM(casos) / SUM(SUM(casos)) OVER (PARTITION BY ano), 1) AS pct_dos_casos,
       ROUND(SUM(casos) * 100000.0 / SUM(populacao), 1) AS incidencia_100mil
FROM dengue.vw_incidencia_municipio
GROUP BY ano, regiao
ORDER BY regiao, ano;
	
-- Lista de prioridade: alto volume e risco acima do ES
SELECT municipio, casos, pct_casos_es,
       incidencia_mun_2025, incidencia_mun_2026, tendencia
FROM dengue.vw_matriz_prioridade
WHERE quadrante = 'Alto volume e risco acima do ES'
ORDER BY casos DESC;

SELECT quadrante,
		count(*)
from dengue.vw_matriz_prioridade
group by quadrante

