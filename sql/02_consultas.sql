SELECT classificacao, criterio, evolucao,
       COUNT(*) AS casos,
       SUM(CASE WHEN data_encerramento IS NULL THEN 1 ELSE 0 END) AS sem_encerramento
FROM dengue.casos
WHERE classificacao = '0' OR criterio = '0' OR evolucao = '0'
GROUP BY classificacao, criterio, evolucao
ORDER BY casos DESC;