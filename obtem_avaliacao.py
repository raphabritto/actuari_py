import pandas as pd

df_aval1 = pd.read_csv("input_csv/avaliacao.csv", sep=";", decimal=",", parse_dates=['DT_CALCULO', 'DT_REAJUSTE_BENEFICIO'])
#print(df_aval1.dtypes)
#print(df_aval1)

df_taxa_juros1 = pd.read_csv("input_csv/taxa_juros.csv", sep=";", decimal=",")
#print(df_taxa_juros1.dtypes)
#print(df_taxa_juros1)

df_taxa_risco1 = pd.read_csv("input_csv/taxa_risco.csv", sep=";", decimal=",")
#print(df_taxa_risco1.dtypes)
#print(df_taxa_risco1)

df_prem_plano1 = pd.read_csv("input_csv/premissa_planos.csv", sep=";", decimal=",")
#print(df_prem_plano1.dtypes)
#print(df_prem_plano1)

df_prem_global1 = pd.read_csv("input_csv/premissa_global.csv", sep=";", decimal=",", parse_dates=['DT_ORIGEM_BNH', 'DT_LEI_9876_1999', 'DT_MEDIA_80_MAIORES_SALARIOS'])
#print(df_prem_global1.dtypes)
#print(df_prem_global1)

df_indice1 = pd.read_csv("input_csv/cotacao.csv", sep=";", decimal=",", parse_dates=['COTDATA'])
#print(df_indice1.dtypes)
#print(df_indice1.head(10))
#print(df_indice1.tail(10))

df_indexador1 = pd.read_csv("input_csv/indexador_monetario.csv", sep=";", decimal=",")
#print(df_indexador1.dtypes)
#print(df_indexador1)

df_reaj_salarial1 = pd.read_csv("input_csv/reajuste_salarial.csv", sep=";", decimal=",")
#print(df_reaj_salarial1.dtypes)
#print(df_reaj_salarial1)

print("\n#########################################################################################\n")

import tools

df_aval2 = df_aval1.drop(['DS_PLANO_BENEFICIO', 'FL_CALCULAR_DEMONS_RESULTADO', 'FL_FLUXO_RECEITA_DESPESA_FOLHA', 'FL_MEMORIA_CALCULO', 'CD_COMPOSICAO_FAMILIAR'], axis=1)
#print(df_aval2.dtypes)
#print(df_aval2)

# renomear columas dataframe
nomes_colunas = {'ID_AVALIACAO': 'avaliacao', 'ID_CADASTRO': 'cadastro', 'IDPLANOPREV': 'plano_previdencia', 'ID_PLANO_BENEFICIO': 'plano_beneficio', 'DT_CALCULO': 'data_calculo',
                 'DT_REAJUSTE_BENEFICIO': 'data_reajuste_beneficio', 'VL_BENEFICIO_MINIMO': 'beneficio_minimo', 'PC_DESPESA_ADM_PARTICIPANTE': 'despesa_administrativa_partic',
                 'PC_DESPESA_ADM_PATROCINADORA': 'despesa_administrativa_patroc', 'PC_SAIDA_BPD': 'saida_bpd', 'PC_SAIDA_PORTABILIDADE': 'saida_portabilidade', 'PC_SAIDA_RESGATE': 'saida_resgate',
                 'VL_PECULIO_MINIMO_MORTE': 'peculio_minimo_morte', 'PC_PECULIO_MINIMO_MORTE': 'fator_peculio_morte_ativo', 'VL_PECULIO_MORTE_ASSISTIDO': 'fator_peculio_morte_assistido',
                 'NR_PAGTOS_BENEF_CONTRIB_ANO': 'numero_pagamentos_ano', 'PC_FAIXA_01_CONTRIBUICAO': 'faixa_1_contribuicao', 'PC_FAIXA_02_CONTRIBUICAO': 'faixa_2_contribuicao',
                 'PC_FAIXA_03_CONTRIBUICAO': 'faixa_3_contribuicao', 'PC_META_CUSTEIO_ADMIN': 'taxa_carregamento_admin', 'PC_TAXA_ADMIN_BENEFICIO': 'taxa_admin_beneficio',
                 'PC_TAXA_REAL_CRESC_SALARIAL': 'taxa_cresc_salarial', 'PC_TAXA_REAL_CRESC_BENEFICIO': 'taxa_cresc_beneficio', 'PC_FATOR_VLR_REAL_SALARIO': 'fator_capacidade_salario',
                 'PC_FATOR_VLR_REAL_BEN_FUNCEF': 'fator_capacidade_funcef', 'PC_FATOR_VLR_REAL_BEN_INSS': 'fator_capacidade_inss', 'PC_FATOR_REAJ_BENEF_LIQUIDO': 'fator_capacidade_beneficio',
                 'PC_OPCAO_BUA': 'opcao_bua', 'PC_SAQUE_BUA': 'saque_bua'}
df_aval2 = df_aval2.rename(columns = nomes_colunas)
#print(df_aval2.dtypes)

df_aval2['despesa_administrativa_partic'] = df_aval2.despesa_administrativa_partic.map(tools.calcPercent)
df_aval2['despesa_administrativa_patroc'] = df_aval2.despesa_administrativa_patroc.map(tools.calcPercent)
df_aval2['saida_bpd'] = df_aval2.saida_bpd.map(tools.calcPercent)
df_aval2['saida_portabilidade'] = df_aval2.saida_portabilidade.map(tools.calcPercent)
df_aval2['saida_resgate'] = df_aval2.saida_resgate.map(tools.calcPercent)
df_aval2['faixa_1_contribuicao'] = df_aval2.faixa_1_contribuicao.map(tools.calcPercent)
df_aval2['faixa_2_contribuicao'] = df_aval2.faixa_2_contribuicao.map(tools.calcPercent)
df_aval2['faixa_3_contribuicao'] = df_aval2.faixa_3_contribuicao.map(tools.calcPercent)

df_aval2['taxa_carregamento_admin'] = df_aval2.taxa_carregamento_admin.map(tools.calcPercent)
df_aval2['taxa_admin_beneficio'] = df_aval2.taxa_admin_beneficio.map(tools.calcPercent)
df_aval2['taxa_cresc_salarial'] = df_aval2.taxa_cresc_salarial.map(tools.calcPercent)
df_aval2['taxa_cresc_beneficio'] = df_aval2.taxa_cresc_beneficio.map(tools.calcPercent)
df_aval2['fator_capacidade_salario'] = df_aval2.fator_capacidade_salario.map(tools.calcPercent)
df_aval2['fator_capacidade_funcef'] = df_aval2.fator_capacidade_funcef.map(tools.calcPercent)
df_aval2['fator_capacidade_inss'] = df_aval2.fator_capacidade_inss.map(tools.calcPercent)
df_aval2['fator_capacidade_beneficio'] = df_aval2.fator_capacidade_beneficio.map(tools.calcIndice)
df_aval2['opcao_bua'] = df_aval2.opcao_bua.map(tools.calcPercent)
df_aval2['saque_bua'] = df_aval2.saque_bua.map(tools.calcPercent)

#print(df_aval2)

nomes_colunas = {'NR_TEMPO_TAXA_JUROS': 't', 'VL_TAXA_JUROS': 'taxa_juros'}

df_taxa_juros2 = df_taxa_juros1.rename(columns= nomes_colunas)
df_taxa_juros2['taxa_juros'] = df_taxa_juros2.taxa_juros.map(tools.calcPercent)

#print(df_taxa_juros2)

nomes_colunas = {'NR_TEMPO_TAXA_RISCO': 't', 'ID_RESPONSABILIDADE': 'responsabilidade', 'VL_TAXA_RISCO': 'taxa_risco'}

df_taxa_risco2 = df_taxa_risco1.rename(columns= nomes_colunas)
df_taxa_risco2['taxa_risco'] = df_taxa_risco2.taxa_risco.map(tools.calcPercent)

#print(df_taxa_risco2)


nomes_colunas = {'ID_PLANO_BENEFICIO': 'plano_beneficio', 'IDADE_INICIO_CONTRIB_INSS_MAS': 'idade_inicio_contrib_inss_mas', 'IDADE_INICIO_CONTRIB_INSS_FEM': 'idade_inicio_contrib_inss_fem',
                 'IDADE_APOSENT_FUNDACAO_MAS': 'idade_aposent_fundacao_mas', 'IDADE_APOSENT_FUNDACAO_FEM': 'idade_aposent_fundacao_fem', 'TEMPO_CONTRIB_INSS_MAS': 'tempo_contrib_inss_mas',
                 'TEMPO_CONTRIB_INSS_FEM': 'tempo_contrib_inss_fem', 'MAIORIDADE_PLANO': 'maioridade_plano', 'PERCENTUAL_SRB': 'percentual_srb', 'TEMPO_CARENCIA_APOSENTADORIA': 'carencia_aposentadoria'}
df_prem_plano2 = df_prem_plano1.rename(columns= nomes_colunas).drop(['ID_PREMISSA_PLANO'], axis=1)[df_prem_plano1.ID_PLANO_BENEFICIO == int(df_aval2.plano_beneficio)]

df_prem_plano2['percentual_srb'] = df_prem_plano2.percentual_srb.map(tools.calcPercent)
#print(df_prem_plano2)

