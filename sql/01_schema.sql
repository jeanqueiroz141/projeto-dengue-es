CREATE SCHEMA IF NOT EXISTS dengue;

CREATE TABLE dengue.casos (
    data_notificacao  DATE,
    data_sintomas     DATE,
    data_encerramento DATE,
    uf_residencia     TEXT,
    cod_municipio     TEXT,
    sexo              TEXT,
    hospitalizado     TEXT,
    classificacao     TEXT,
    criterio          TEXT,
    evolucao          TEXT,
    ano               INTEGER,
    semana            INTEGER,
    idade_anos        INTEGER
);

CREATE TABLE dengue.populacao (
    cod_municipio TEXT,
    municipio     TEXT,
    ano           INTEGER,
    populacao     INTEGER,
    PRIMARY KEY (cod_municipio, ano)
);
