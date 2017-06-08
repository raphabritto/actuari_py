import pandas as pd

df_aval1 = pd.read_csv("input_csv/avaliacao.csv", sep=";", decimal=",", parse_dates=['DT_CALCULO', 'DT_REAJUSTE_BENEFICIO'])

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


df_prem_global1 = pd.read_csv("input_csv/premissa_global.csv", sep=";", decimal=",", parse_dates=['DT_ORIGEM_BNH', 'DT_LEI_9876_1999', 'DT_MEDIA_80_MAIORES_SALARIOS'])
print(df_prem_global1.dtypes)
print(df_prem_global1)

df_indice1 = pd.read_csv("input_csv/cotacao.csv", sep=";", decimal=",", parse_dates=['COTDATA'])
print(df_indice1.dtypes)
print(df_indice1.head(10))
print(df_indice1.tail(10))

df_indexador1 = pd.read_csv("input_csv/indexador_monetario.csv", sep=";", decimal=",")
print(df_indexador1.dtypes)
print(df_indexador1)

df_reaj_salarial1 = pd.read_csv("input_csv/reajuste_salarial.csv", sep=";", decimal=",")
print(df_reaj_salarial1.dtypes)
print(df_reaj_salarial1)

print("\n#########################################################################################\n")

df_aval2 = df_aval1.drop(['DS_PLANO_BENEFICIO', 'FL_CALCULAR_DEMONS_RESULTADO', 'FL_FLUXO_RECEITA_DESPESA_FOLHA', 'FL_MEMORIA_CALCULO', 'CD_COMPOSICAO_FAMILIAR'], axis=1)
#print(df_aval2.dtypes)
#print(df_aval2)

# renomear columas dataframe
nomes_colunas = {'ID_AVALIACAO': 'avaliacao', 'ID_CADASTRO': 'cadastro', 'IDPLANOPREV': 'plano_previdencia', 'ID_PLANO_BENEFICIO': 'plano_beneficio', 'DT_CALCULO': 'data_calculo', 'DT_REAJUSTE_BENEFICIO': 'data_reajuste_beneficio', 'VL_BENEFICIO_MINIMO': 'beneficio_minimo', 'PC_DESPESA_ADM_PARTICIPANTE': 'despesa_administrativa_partic', 'PC_DESPESA_ADM_PATROCINADORA': 'despesa_administrativa_patroc', 'PC_SAIDA_BPD': 'saida_bpd', 'PC_SAIDA_PORTABILIDADE': 'saida_portabilidade', 'PC_SAIDA_RESGATE': 'saida_resgate', 'VL_PECULIO_MINIMO_MORTE': 'peculio_minimo_morte', 'PC_PECULIO_MINIMO_MORTE': 'fator_peculio_morte_ativo', 'VL_PECULIO_MORTE_ASSISTIDO': 'fator_peculio_morte_assistido'}
df_aval2 = df_aval2.rename(columns = nomes_colunas)
print(df_aval2.dtypes)