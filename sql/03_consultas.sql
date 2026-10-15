-- ver o municipio que nao repetiu
SELECT
    p.municipio,
    p.ano
FROM dengue.populacao AS p
LEFT JOIN dengue.casos AS c
    ON c.cod_municipio = p.cod_municipio
   	AND c.ano = p.ano
WHERE c.cod_municipio IS NULL;

-----------

SELECT 
	semana,
    SUM(CASE WHEN ano = 2025 THEN 1 ELSE 0 END) AS casos_2025,
    SUM(CASE WHEN ano = 2026 THEN 1 ELSE 0 END) AS casos_2026
FROM dengue.vw_casos
WHERE semana <= 38
GROUP BY semana
ORDER BY semana;

-------------

SELECT faixa_etaria,
       COUNT(*) AS casos,
       ROUND(100.0 * SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_hospitalizado,
       ROUND(100.0 * SUM(CASE WHEN classificacao IN ('Dengue com sinais de alarme', 'Dengue grave')
                              THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_alarme_ou_grave
FROM dengue.vw_casos
GROUP BY faixa_etaria
ORDER BY pct_hospitalizado DESC;

------------

SELECT 
	ano,
	COUNT(*) AS casos,
	SUM(CASE WHEN data_encerramento IS NULL THEN 1 ELSE 0 END) AS abertos,
	ROUND(100.0 * SUM(CASE WHEN data_encerramento IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_abertos
FROM dengue.vw_casos
GROUP BY ano;

------------

-- Concentração de casos por município (volume)
WITH por_municipio AS (
    SELECT 
		p.municipio,
		c.ano,
		COUNT(*) AS casos
    FROM dengue.vw_casos as c
    JOIN dengue.populacao as p 
	ON p.cod_municipio = c.cod_municipio
	AND p.ano = c.ano
    WHERE c.semana <= 38
    GROUP BY p.municipio, c.ano
)
SELECT
	ano,
	municipio,
	casos,
    ROUND(100.0 * casos / SUM(casos) OVER (PARTITION BY ano), 1) AS pct_do_total,
    ROUND(100.0 * SUM(casos) OVER (PARTITION BY ano ORDER BY casos DESC)
		/ SUM(casos) OVER (PARTITION BY ano), 1) AS pct_acumulado
FROM por_municipio
ORDER BY ano, casos DESC;

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

--------------

-- Top 10 de incidência por ano (SE 1 a 36)
SELECT *
FROM dengue.vw_incidencia_municipio
WHERE posicao <= 10
ORDER BY ano, posicao;


-- Repete? Correlação entre as posições de 2025 e de 2026
SELECT ROUND(CORR(a.posicao, b.posicao)::numeric, 2) AS correlacao_posicoes,
       COUNT(*) AS municipios
FROM dengue.vw_incidencia_municipio a
JOIN dengue.vw_incidencia_municipio b 
ON b.cod_municipio = a.cod_municipio
WHERE a.ano = 2025 AND b.ano = 2026;

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

-- Piorou? Variação da incidência de 2025 para 2026 (municípios com pelo menos 30 casos nos dois anos)
SELECT a.municipio,
       a.casos AS casos_2025, b.casos AS casos_2026,
       a.incidencia_100mil AS incidencia_2025, b.incidencia_100mil AS incidencia_2026,
       ROUND(b.incidencia_100mil - a.incidencia_100mil, 1) AS diferenca
FROM dengue.vw_incidencia_municipio a
JOIN dengue.vw_incidencia_municipio b ON b.cod_municipio = a.cod_municipio
WHERE a.ano = 2025 AND b.ano = 2026
  AND a.casos >= 30 AND b.casos >= 30
ORDER BY diferenca DESC;


