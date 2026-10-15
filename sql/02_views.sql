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
           c.ano,
           COUNT(*) AS casos,
           p.populacao,
           ROUND(COUNT(*) * 100000.0 / p.populacao, 1) AS incidencia_100mil
    FROM dengue.vw_casos c
    JOIN dengue.populacao p
      ON p.cod_municipio = c.cod_municipio
     AND p.ano = c.ano
    WHERE c.semana <= 36
    GROUP BY p.cod_municipio, p.municipio, c.ano, p.populacao
)
SELECT *,
       RANK() OVER (PARTITION BY ano ORDER BY incidencia_100mil DESC) AS posicao
FROM taxa;