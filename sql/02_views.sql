-- criando uma view com regra de faixas de idades.

CREATE OR REPLACE VIEW dengue.vw_casos AS
SELECT
    data_notificacao, data_sintomas, data_encerramento,
    cod_municipio, sexo, hospitalizado, ano, semana, idade_anos,
    classificacao, criterio, evolucao,
    CASE WHEN idade_anos IS NULL THEN 'Não informada'
         WHEN idade_anos < 5     THEN '0 a 4'
         WHEN idade_anos < 15    THEN '5 a 14'
         WHEN idade_anos < 60    THEN '15 a 59'
         ELSE '60 ou mais' END AS faixa_etaria,
    CASE WHEN data_encerramento IS NULL THEN 'Aberto' ELSE 'Encerrado' END AS situacao
FROM dengue.casos;


-- Incidência por 100 mil rankeada

CREATE OR REPLACE VIEW dengue.vw_incidencia_municipio AS
WITH taxa AS (
    SELECT p.cod_municipio,
           p.municipio,
           p.ano,
           COUNT(c.cod_municipio) AS casos,
           p.populacao,
           ROUND(COUNT(c.cod_municipio) * 100000.0 / p.populacao, 1) AS incidencia_100mil
    FROM dengue.populacao p
    LEFT JOIN dengue.vw_casos c
      ON c.cod_municipio = p.cod_municipio
     AND c.ano = p.ano
     AND c.semana <= 36
    GROUP BY p.cod_municipio, p.municipio, p.ano, p.populacao
)
SELECT *,
       RANK() OVER (PARTITION BY ano ORDER BY incidencia_100mil DESC) AS posicao
FROM taxa;

------------

CREATE OR REPLACE VIEW dengue.vw_matriz_prioridade AS
WITH es AS (
    SELECT ano,
           SUM(casos) AS casos_es,
           ROUND(SUM(casos) * 100000.0 / SUM(populacao), 1) AS incidencia_es
    FROM dengue.vw_incidencia_municipio
    GROUP BY ano
),
base AS (
    SELECT m.cod_municipio, m.municipio, m.casos, m.populacao,
           m.incidencia_100mil,
           ROUND(100.0 * m.casos / e.casos_es, 1) AS pct_casos_es,
           e.incidencia_es,
           a.incidencia_100mil AS incidencia_2025
    FROM dengue.vw_incidencia_municipio m
    JOIN es e ON e.ano = m.ano
    JOIN dengue.vw_incidencia_municipio a
      ON a.cod_municipio = m.cod_municipio AND a.ano = 2025
    WHERE m.ano = 2026
)
SELECT *,
       CASE WHEN casos < 30 THEN 'Poucos casos (não classificado)'
            WHEN pct_casos_es >= 2 AND incidencia_100mil > incidencia_es THEN 'Alto volume e risco acima do ES'
            WHEN pct_casos_es >= 2 THEN 'Alto volume, risco na média ou abaixo'
            WHEN incidencia_100mil > incidencia_es THEN 'Baixo volume e risco acima do ES'
            ELSE 'Baixo volume, risco na média ou abaixo' END AS quadrante,
       CASE WHEN incidencia_100mil > incidencia_2025 THEN 'Subiu' ELSE 'Não subiu' END AS tendencia
FROM base;