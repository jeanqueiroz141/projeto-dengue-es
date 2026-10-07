# %%
import os
from pathlib import Path
import pandas as pd

# Sobe as pastas até achar o README.md (a raiz do projeto)
raiz = Path.cwd()
while not (raiz / "README.md").exists() and raiz != raiz.parent:
    raiz = raiz.parent
assert (raiz / "README.md").exists(), f"Não achei a raiz a partir de {Path.cwd()}"
os.chdir(raiz)
print("Raiz do projeto:", Path.cwd())

RAW = Path("data/raw/sinan")
ARQUIVOS = {2025: RAW / "DENGBR25.csv", 2026: RAW / "DENGBR26.csv"}

# %%
# 1) As colunas são iguais nos dois arquivos? (lê só o cabeçalho)
cols = {ano: pd.read_csv(p, encoding="latin1", sep=",", nrows=0).columns.tolist()
        for ano, p in ARQUIVOS.items()}
print(len(cols[2025]), len(cols[2026]))
print("Iguais:", cols[2025] == cols[2026])

# %%
# 2) Lê só 6 colunas, como texto (pode levar cerca de 1 minuto)
usar = ["DT_NOTIFIC", "SEM_NOT", "NU_ANO", "SG_UF_NOT", "SG_UF", "ID_MN_RESI",
        "SEM_PRI", "DT_SIN_PRI"]
dfs = {ano: pd.read_csv(p, encoding="latin1", sep=",", usecols=usar, dtype=str)
       for ano, p in ARQUIVOS.items()}
for ano, d in dfs.items():
    print(ano, len(d))

# %%
# 3) Ano do arquivo x ano da data de notificação x ano da semana epidemiológica
for ano, d in dfs.items():
    print(f"\nArquivo {ano}")
    print(pd.crosstab(d["NU_ANO"], d["DT_NOTIFIC"].str[:4]))
    print(pd.crosstab(d["NU_ANO"], d["SEM_NOT"].str[:4]))

# %%
# 4) Casos de residentes no ES (SG_UF = UF de residência; 32 = ES)
for ano, d in dfs.items():
    print(ano, "residentes ES:", (d["SG_UF"] == "32").sum(),
          "| notificados no ES:", (d["SG_UF_NOT"] == "32").sum())

# %%
# 5) O arquivo de cada ano reúne casos com 1º sintoma naquele ano?
for ano, d in dfs.items():
    print(f"\nArquivo {ano}: ano da semana do 1º sintoma (SEM_PRI)")
    print(d["SEM_PRI"].str[:4].value_counts(dropna=False).sort_index())