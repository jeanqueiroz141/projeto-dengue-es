# %%

import pandas as pd

# %%
# 1) LER os dois arquivos do SINAN, só com as colunas que vamos usar
colunas = ["DT_NOTIFIC", "DT_SIN_PRI", "SEM_PRI", "DT_ENCERRA", "SG_UF", "ID_MN_RESI",
           "CS_SEXO", "NU_IDADE_N", "HOSPITALIZ", "CLASSI_FIN", "CRITERIO", "EVOLUCAO"]

d25 = pd.read_csv("data/DENGBR25.csv", sep=",", encoding="latin1", usecols=colunas, dtype=str)
d26 = pd.read_csv("data/DENGBR26.csv", sep=",", encoding="latin1", usecols=colunas, dtype=str)

# %%
# 2) FILTRAR o ES (código 32), marcar o ano e JUNTAR os dois arquivos
d25 = d25[d25["SG_UF"] == "32"].copy()
d26 = d26[d26["SG_UF"] == "32"].copy()
d25["ano"] = 2025
d26["ano"] = 2026
dengue = pd.concat([d25, d26], ignore_index=True)
print(dengue.shape)   # esperado: (53735, 13)

# %%
# 3) AJUSTAR tipos: datas, semana epidemiológica e idade em anos
for col in ["DT_NOTIFIC", "DT_SIN_PRI", "DT_ENCERRA"]:
    dengue[col] = pd.to_datetime(dengue[col], format="%Y%m%d", errors="coerce")

dengue["semana"] = dengue["SEM_PRI"].str[4:].astype(int)      # 202538 -> 38

dengue["NU_IDADE_N"] = pd.to_numeric(dengue["NU_IDADE_N"], errors="coerce")
def idade_em_anos(codigo):
    if pd.isna(codigo):
        return None
    if codigo >= 4000:        # 4xxx = anos
        return codigo - 4000
    return 0                  # horas, dias ou meses = menos de 1 ano
dengue["idade_anos"] = dengue["NU_IDADE_N"].apply(idade_em_anos)

# %%
# 4) TRADUZIR os códigos (os que não estão no dicionário ficam como vieram)
dengue["CS_SEXO"] = dengue["CS_SEXO"].replace({"M": "Masculino", "F": "Feminino", "I": "Ignorado"})
dengue["HOSPITALIZ"] = dengue["HOSPITALIZ"].replace({"1": "Sim", "2": "Não", "9": "Ignorado"})
dengue["CLASSI_FIN"] = dengue["CLASSI_FIN"].replace({"10": "Dengue",
                                                     "11": "Dengue com sinais de alarme",
                                                     "12": "Dengue grave"})
dengue["CRITERIO"] = dengue["CRITERIO"].replace({"1": "Laboratório",
                                                 "2": "Clínico-epidemiológico",
                                                 "3": "Em investigação"})
dengue["EVOLUCAO"] = dengue["EVOLUCAO"].replace({"1": "Cura", "2": "Óbito pelo agravo",
                                                 "3": "Óbito por outras causas",
                                                 "4": "Óbito em investigação", "9": "Ignorado"})

# %%
# 5) RENOMEAR e tirar o que não precisa mais
dengue = dengue.rename(columns={"DT_NOTIFIC": "data_notificacao", "DT_SIN_PRI": "data_sintomas",
                                "DT_ENCERRA": "data_encerramento", "SG_UF": "uf_residencia",
                                "ID_MN_RESI": "cod_municipio", "CS_SEXO": "sexo",
                                "HOSPITALIZ": "hospitalizado", "CLASSI_FIN": "classificacao",
                                "CRITERIO": "criterio", "EVOLUCAO": "evolucao"})
dengue = dengue.drop(columns=["SEM_PRI", "NU_IDADE_N"])
dengue.head()

# %%
# 6) POPULAÇÃO do IBGE: a 2ª aba de cada arquivo tem os municípios
nomes = ["uf", "cod_uf", "cod_mun", "municipio", "populacao"]

def ler_pop(arquivo, ano):
    p = pd.read_excel(arquivo, sheet_name=1, header=None, skiprows=2,
                      usecols=[0, 1, 2, 3, 4], names=nomes,
                      dtype={"cod_uf": str, "cod_mun": str})
    p = p[p["cod_uf"] == "32"].copy()                          # só o ES
    p["cod_municipio"] = (p["cod_uf"] + p["cod_mun"]).str[:6]  # 2 + 5 dígitos -> 6 primeiros
    p["ano"] = ano
    return p[["cod_municipio", "municipio", "ano", "populacao"]]

populacao = pd.concat([ler_pop("data/POP2025_20260828.xls", 2025),
                       ler_pop("data/estimativa_dou_2026.xlsx", 2026)], ignore_index=True)
print(populacao.shape)

populacao["populacao"] = populacao["populacao"].astype(int)
# %%

populacao

# %%
# 7) CONFERIR se o código do município é o mesmo nas duas tabelas
casos = set(dengue["cod_municipio"].dropna())
pop = set(populacao["cod_municipio"])
print("Municípios nos casos:", len(casos), "| na população:", len(pop))
print("Códigos dos casos que não existem na população:", casos - pop)

# %%
# %%
# 8) EXPORTAR para o SQL
dengue["idade_anos"] = dengue["idade_anos"].astype("Int64")   # 34.0 -> 34
dengue = dengue[["data_notificacao", "data_sintomas", "data_encerramento", "uf_residencia",
                 "cod_municipio", "sexo", "hospitalizado", "classificacao", "criterio",
                 "evolucao", "ano", "semana", "idade_anos"]]   # mesma ordem da tabela no SQL
dengue.to_csv("data/dengue_es.csv", index=False)
populacao.to_csv("data/populacao_es.csv", index=False)

# %%

dengue