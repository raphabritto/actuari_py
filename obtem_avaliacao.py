import pandas as pd

df_aval1 = pd.read_csv("input_csv/avaliacao.csv", sep=";", decimal=",")

print(df_aval1.dtypes)
print(df_aval1)

df_taxa_juros1 = pd.read_csv("input_csv/taxa_juros.csv", sep=";", decimal=",")
print(df_taxa_juros1.dtypes)
print(df_taxa_juros1)

df_taxa_risco1 = pd.read_csv("input_csv/taxa_risco.csv", sep=";", decimal=",")
print(df_taxa_risco1.dtypes)
print(df_taxa_risco1)

df_prem_plano1 = pd.read_csv("input_csv/premissa_planos.csv", sep=";", decimal=",")
print(df_prem_plano1.dtypes)
print(df_prem_plano1)


df_prem_global1 = pd.read_csv("input_csv/premissa_global.csv", sep=";", decimal=",")
print(df_prem_global1.dtypes)
print(df_prem_global1)

df_indice1 = pd.read_csv("input_csv/cotacao.csv", sep=";", decimal=",")
print(df_indice1.dtypes)
print(df_indice1.head(10))
print(df_indice1.tail(10))

df_indexador1 = pd.read_csv("input_csv/indexador_monetario.csv", sep=";", decimal=",")
print(df_indexador1.dtypes)
print(df_indexador1)

df_reaj_salarial1 = pd.read_csv("input_csv/reajuste_salarial.csv", sep=";", decimal=",")
print(df_reaj_salarial1.dtypes)
print(df_reaj_salarial1)
