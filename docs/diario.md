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