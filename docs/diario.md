## 2026-10-07: exploração inicial
- O que fiz: li colunas e 6 campos dos dois arquivos do SINAN.
- O que descobri: 121 colunas iguais nos dois arquivos. DENGBR26 tem 465.323 linhas,
  todas de 2026. DENGBR25 tem 1.643.215, incluindo 2.282 notificadas em 29-31/12/2024,
  1.818 em 01-03/01/2026 (fronteira de semana epidemiológica) e 5.240 de 2026 a investigar.
  Residentes no ES: 34.075 (arquivo 2025) e 19.660 (arquivo 2026).
- Decisão e motivo: pendente (regra do "ano do caso").

## 2026-10-07: versionamento
- O que fiz: iniciei o Git (branch main) e conferi que data/ e _apoio/ ficam fora do repositório.
- O que descobri: a janela interativa roda de outra pasta, então caminhos relativos falharam.
- Decisão e motivo: o script localiza a raiz do projeto sozinho, para rodar em qualquer lugar.

## 2026-10-07: o que define o "ano" de cada arquivo
- O que fiz: cruzei NU_ANO, ano de DT_NOTIFIC, ano de SEM_NOT e ano de SEM_PRI nos dois arquivos.
- O que descobri: 100% das linhas de cada arquivo têm SEM_PRI do ano do arquivo
  (1.643.215 em 2025; 465.323 em 2026). O arquivo de 2025 inclui 2.282 notificadas em
  29-31/12/2024 e 7.058 notificadas em 2026, todas com sintomas no ano epidemiológico 2025.
- Decisão e motivo: ano do caso = ano do arquivo (ano epidemiológico do 1º sintoma);
  curva semanal por SEM_PRI. Assim os arquivos não se sobrepõem.

## 2026-10-07: simplificação do projeto
- O que fiz: reduzi o tratamento a um único script em pandas e achatei as pastas.
- O que descobri: CLASSI_FIN tem os códigos 0 e 8, que o dicionário do SINAN (revisão de 2015)
  não descreve; não há 5 (descartado) nem 13 (chikungunya) nos dados do ES. As semanas de
  1º sintoma vão de 202501 a 202553 em 2025 e de 202601 a 202638 em 2026.
- Decisão e motivo: Python só para ler, filtrar, ajustar e traduzir; a análise fica no SQL.
  A chave dos municípios é o código de 6 dígitos (texto) nas duas tabelas.

## 2026-10-07: tratamento concluído
- O que fiz: rodei o 01_tratamento.py, que gerou data/dengue_es.csv (casos do ES, 2025 e 2026) e data/populacao_es.csv (população do IBGE por município e ano).
- O que descobri: os 78 municípios dos casos existem todos na tabela de população, e o código de 6 dígitos (texto) funciona como chave entre as duas.
- Decisão e motivo: Python faz a preparação (ler, filtrar, tipos, tradução de códigos);
  as colunas novas e os indicadores serão feitos em SQL.

## 2026-10-07: banco de dados
- O que fiz: criei o banco dengue_es no PostgreSQL, com o schema dengue e as tabelas casos e populacao.
- O que descobri: a importação associa colunas por posição e o campo inteiro não aceita "34.0",
  então a ordem das colunas e o tipo da idade foram ajustados antes de exportar.
- Decisão e motivo: PostgreSQL em vez de SQLite porque o Power BI tem conector nativo.

## 2026-10-07: dados no PostgreSQL
- O que fiz: importei os CSVs para dengue.casos (53.735 linhas) e dengue.populacao;
  rodei a primeira consulta de incidência por 100 mil.
- O que descobri: alguns casos têm "0" em classificacao, criterio e evolucao, sem data de
  encerramento (provavelmente casos ainda em investigação, a confirmar). As maiores incidências
  são de municípios pequenos.
- Decisão e motivo: tratar o "0" no SQL com CASE WHEN; separar os anos nas consultas.

## 2026-10-08: o que significa o código "0"
- O que fiz: consultei as combinações de classificacao, criterio e evolucao com código 0.
- O que descobri: a combinação mais comum (5.198 casos) tem os três campos em 0 e 99% sem data
  de encerramento (casos abertos). Mas há pelo menos 1.245 casos já classificados como dengue e
  encerrados com evolução 0 (não preenchida).
- Decisão e motivo: tratar o 0 como "Não informado" (diferente de "Ignorado", código 9) numa view
  em SQL; a evolução em branco em casos encerrados entra na análise de qualidade dos dados.

## 2026-10-08: view e primeiras análises
- O que fiz: criei dengue.vw_casos (códigos 0 e nulo como "Não informado", faixa etária e
  situação aberto/encerrado) e consultas de curva semanal, ranking e gravidade.
- O que descobri: o código 8 aparece só em casos encerrados, provavelmente "Inconclusivo"
  (fonte secundária). 5.215 casos (cerca de 10%) estão sem classificação.
- Decisão e motivo: comparar 2025 e 2026 até a semana 38, o limite dos dados de 2026.