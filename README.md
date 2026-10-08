# Dengue no Espírito Santo: onde agir primeiro

## Objetivo
Identificar em quais municípios do ES e para quais grupos priorizar ações
contra a dengue, a partir de notificações do SINAN (2025 e 2026) e população do IBGE.

## Fontes de dados
| Fonte | Arquivo | Data do download | Link |
|---|---|---|---|
| SINAN dengue | DENGBR25.csv, DENGBR26.csv | (preencha) | (cole a URL que você usou) |
| IBGE, estimativa 2025 | POP2025_20260828.xls | (preencha) | https://www.ibge.gov.br/estatisticas/sociais/populacao/9103-estimativas-de-populacao.html |
| IBGE, estimativa 2026 | estimativa_dou_2026.xlsx | (preencha) | mesma página |

## Estrutura
- data/: arquivos originais do SINAN e do IBGE e CSVs tratados (não versionados)
- 01_tratamento.py: leitura, filtro do ES e limpeza com pandas
- sql/: consultas de análise
- docs/diario.md: diário do projeto

## Decisões sobre os dados
- **Ano do caso = ano do arquivo do SINAN.** Os arquivos são organizados pelo ano
  epidemiológico dos primeiros sintomas (SEM_PRI): 100% das linhas de DENGBR25 têm
  SEM_PRI de 2025 e 100% das de DENGBR26 têm de 2026, então os arquivos não se sobrepõem.
  O arquivo de 2025 inclui notificações de 29-31/12/2024 e de 2026.
- **Local:** casos por município de **residência** (SG_UF = 32), pois a população do IBGE
  é de residentes.

sql/: criação das tabelas e consultas de análise (PostgreSQL)