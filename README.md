# Dengue no Espírito Santo: onde agir primeiro

## Objetivo
Diagnosticar como a dengue se distribuiu no Espírito Santo em 2025 e 2026 (quando, onde e em quem), separando os municípios com mais casos (volume) daqueles em que o risco por habitante é maior, para apoiar a priorização de ações de prevenção e de resposta.

## Perguntas de negócio
1. **Quando?** Como a curva semanal de 2026 se compara à de 2025?
2. **Onde?** Quais municípios concentram os casos (volume) e quais têm maior risco por habitante (incidência por 100 mil)?
3. **Repete?** Os municípios de maior risco são os mesmos nos dois anos?
4. **Quem?** Quais faixas etárias têm mais hospitalização e mais casos com sinais de alarme ou graves?
5. **Piorou?** Em quais municípios a incidência aumentou de 2025 para 2026, nas mesmas semanas?
6. **Confiável?** Qual a qualidade dos dados (casos sem classificação, abertos, tempo até o encerramento)?
7. **Onde agir?** Como classificar os municípios por volume e risco para orientar a priorização?

## Fontes de dados
| Fonte | Arquivo | Data do download | Link |
|---|---|---|---|
| Datasus dengue | DENGBR25.csv, DENGBR26.csv | (06/10/2026) | (https://datasus.saude.gov.br/transferencia-de-arquivos/) |
| IBGE, estimativa 2025 | POP2025_20260828.xls | (06/10/2026) | https://www.ibge.gov.br/estatisticas/sociais/populacao/9103-estimativas-de-populacao.html |
| IBGE, estimativa 2026 | estimativa_dou_2026.xlsx | (06/10/2026) | mesma página |

## Estrutura
- data/: arquivos originais do SINAN e do IBGE e CSVs tratados (não versionados)
- 01_tratamento.py: leitura, filtro do ES e limpeza com pandas
- sql/: criação das tabelas e consultas de análise (PostgreSQL)
- docs/diario.md: diário do projeto

## Decisões sobre os dados
- **Ano do caso = ano do arquivo do SINAN.** Os arquivos são organizados pelo ano
  epidemiológico dos primeiros sintomas (SEM_PRI): 100% das linhas de DENGBR25 têm
  SEM_PRI de 2025 e 100% das de DENGBR26 têm de 2026, então os arquivos não se sobrepõem.
  O arquivo de 2025 inclui notificações de 29-31/12/2024 e de 2026.
- **Local:** casos por município de **residência** (SG_UF = 32), pois a população do IBGE
  é de residentes.

## Modelo de dados (PostgreSQL, schema `dengue`)
| Objeto | Tipo | Chave / regra |
|---|---|---|
| `dengue.casos` | tabela | Uma linha por notificação (ES, 2025-2026). Sem chave única: o recorte dos microdados públicos não traz identificador do caso. |
| `dengue.populacao` | tabela | **Chave primária composta (cod_municipio, ano)**: uma só linha por município e ano. Impede duplicidade e evita que o JOIN multiplique casos. |
| `dengue.vw_casos` | view | Camada de análise: trata os códigos 0, 8 e nulo e cria faixa etária e situação do caso. |

Relação: `casos (cod_municipio, ano)` com `populacao (cod_municipio, ano)`, usando o código de 6 dígitos do município (texto).

## Onde cada tratamento acontece
- **Python (pandas):** leitura, filtro do ES, tipos (datas, idade) e tradução dos códigos definidos no dicionário do SINAN.
- **SQL (view):** interpretações que dependem da análise (códigos 0 e 8) e colunas derivadas. Os dados originais ficam intactos em `dengue.casos`.