-- Incidência por 100 mil: 10 maiores

SELECT
	p.municipio,
	c.ano,
	count(*) as casos,
	p.populacao,
	round(count(*) * 100000.0 / p.populacao, 1)  as incidencia_100mil
FROM dengue.casos as c
JOIN dengue.populacao as p
ON p.cod_municipio = c.cod_municipio
AND p.ano = c.ano
GROUP BY p.municipio, c.ano, p.populacao
ORDER BY incidencia_100mil desc;

-----------

SELECT 
	semana,
    SUM(CASE WHEN ano = 2025 THEN 1 ELSE 0 END) AS casos_2025,
    SUM(CASE WHEN ano = 2026 THEN 1 ELSE 0 END) AS casos_2026
FROM dengue.vw_casos
WHERE semana <= 38
GROUP BY semana
ORDER BY semana;

--------------

WITH taxa AS (
    SELECT 
		p.municipio, 
		c.ano, 
		COUNT(*) AS casos, 
		p.populacao,
        ROUND(COUNT(*) * 100000.0 / p.populacao, 1) AS incidencia_100mil
    FROM dengue.vw_casos c
    JOIN dengue.populacao p
	ON p.cod_municipio = c.cod_municipio
	AND p.ano = c.ano
    WHERE c.semana <= 38
    GROUP BY p.municipio, c.ano, p.populacao
),
ranking AS (
    SELECT
		*,
 		RANK() OVER (PARTITION BY ano ORDER BY incidencia_100mil DESC) AS posicao
    	FROM taxa
)


SELECT * 
FROM ranking 
WHERE posicao <= 10 
ORDER BY ano, posicao;

-------------

SELECT faixa_etaria,
       COUNT(*) AS casos,
       ROUND(100.0 * SUM(CASE WHEN hospitalizado = 'Sim' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_hospitalizado,
       ROUND(100.0 * SUM(CASE WHEN classificacao IN ('Dengue com sinais de alarme', 'Dengue grave')
                              THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_alarme_ou_grave
FROM dengue.vw_casos
GROUP BY faixa_etaria
ORDER BY pct_hospitalizado DESC;

--------

SELECT
	p.municipio,
	p.ano
FROM dengue.populacao p
LEFT JOIN dengue.casos c 
ON c.cod_municipio = p.cod_municipio
AND c.ano = p.ano
WHERE c.cod_municipio IS NULL;

------------

SELECT 
	ano,
	COUNT(*) AS casos,
	SUM(CASE WHEN data_encerramento IS NULL THEN 1 ELSE 0 END) AS abertos,
	ROUND(100.0 * SUM(CASE WHEN data_encerramento IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_abertos,
	ROUND(AVG(data_encerramento - data_notificacao), 1) AS media_dias_ate_encerrar
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