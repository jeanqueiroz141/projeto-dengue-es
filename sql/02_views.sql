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

SELECT * FROM dengue.vw_casos LIMIT 10;

