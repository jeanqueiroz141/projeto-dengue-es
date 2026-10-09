-- Incidência por 100 mil: 10 maiores

SELECT
	p.municipio,
	c.ano,
	count(*) as casos,
	p.populacao,
	round(count(*) * 100000.0 / p.populacao, 1)  as incidencia_100mil
FROM dengue.casos as c
LEFT JOIN dengue.populacao as p
ON p.cod_municipio = c.cod_municipio
AND p.ano = c.ano
GROUP BY p.municipio, c.ano, p.populacao
ORDER BY incidencia_100mil desc;


SELECT semana,
       SUM(CASE WHEN ano = 2025 THEN 1 ELSE 0 END) AS casos_2025,
       SUM(CASE WHEN ano = 2026 THEN 1 ELSE 0 END) AS casos_2026
FROM dengue.vw_casos
WHERE semana <= 38
GROUP BY semana
ORDER BY semana;


WITH taxa AS (
    SELECT p.municipio, c.ano, COUNT(*) AS casos, p.populacao,
           ROUND(COUNT(*) * 100000.0 / p.populacao, 1) AS incidencia_100mil
    FROM dengue.vw_casos c
    JOIN dengue.populacao p ON p.cod_municipio = c.cod_municipio AND p.ano = c.ano
    WHERE c.semana <= 38
    GROUP BY p.municipio, c.ano, p.populacao
),
ranking AS (
    SELECT *, RANK() OVER (PARTITION BY ano ORDER BY incidencia_100mil DESC) AS posicao
    FROM taxa
)
SELECT * FROM ranking WHERE posicao <= 10 ORDER BY ano, posicao;