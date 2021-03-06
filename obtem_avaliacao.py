import pandas as pd
import tools
import itertools

df_aval1 = pd.read_csv("input_csv/avaliacao.csv", sep=";", decimal=",", parse_dates=['DT_CALCULO', 'DT_REAJUSTE_BENEFICIO'])

df_taxa_juros1 = pd.read_csv("input_csv/taxa_juros.csv", sep=";", decimal=",")

df_taxa_risco1 = pd.read_csv("input_csv/taxa_risco.csv", sep=";", decimal=",")

df_prem_plano1 = pd.read_csv("input_csv/premissa_planos.csv", sep=";", decimal=",")

df_prem_global1 = pd.read_csv("input_csv/premissa_global.csv", sep=";", decimal=",", parse_dates=['DT_ORIGEM_BNH', 'DT_LEI_9876_1999', 'DT_MEDIA_80_MAIORES_SALARIOS'])

df_indice1 = pd.read_csv("input_csv/cotacao.csv", sep=";", decimal=",", parse_dates=['COTDATA'])

df_indexador1 = pd.read_csv("input_csv/indexador_monetario.csv", sep=";", decimal=",")

df_reaj_salarial1 = pd.read_csv("input_csv/reajuste_salarial.csv", sep=";", decimal=",")

df_aval2 = df_aval1.drop(['DS_PLANO_BENEFICIO', 'FL_CALCULAR_DEMONS_RESULTADO', 'FL_FLUXO_RECEITA_DESPESA_FOLHA', 'FL_MEMORIA_CALCULO', 'CD_COMPOSICAO_FAMILIAR'], axis=1)

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
df_aval2['despesa_administrativa_partic'] = df_aval2.despesa_administrativa_partic.map(tools.convertToPercent)
df_aval2['despesa_administrativa_patroc'] = df_aval2.despesa_administrativa_patroc.map(tools.convertToPercent)
df_aval2['saida_bpd'] = df_aval2.saida_bpd.map(tools.convertToPercent)
df_aval2['saida_portabilidade'] = df_aval2.saida_portabilidade.map(tools.convertToPercent)
df_aval2['saida_resgate'] = df_aval2.saida_resgate.map(tools.convertToPercent)
df_aval2['faixa_1_contribuicao'] = df_aval2.faixa_1_contribuicao.map(tools.convertToPercent)
df_aval2['faixa_2_contribuicao'] = df_aval2.faixa_2_contribuicao.map(tools.convertToPercent)
df_aval2['faixa_3_contribuicao'] = df_aval2.faixa_3_contribuicao.map(tools.convertToPercent)
df_aval2['taxa_carregamento_admin'] = df_aval2.taxa_carregamento_admin.map(tools.convertToPercent)
df_aval2['taxa_admin_beneficio'] = df_aval2.taxa_admin_beneficio.map(tools.convertToPercent)
df_aval2['taxa_cresc_salarial'] = df_aval2.taxa_cresc_salarial.map(tools.convertToPercent)
df_aval2['taxa_cresc_beneficio'] = df_aval2.taxa_cresc_beneficio.map(tools.convertToPercent)
df_aval2['fator_capacidade_salario'] = df_aval2.fator_capacidade_salario.map(tools.convertToPercent)
df_aval2['fator_capacidade_funcef'] = df_aval2.fator_capacidade_funcef.map(tools.convertToPercent)
df_aval2['fator_capacidade_inss'] = df_aval2.fator_capacidade_inss.map(tools.convertToPercent)
df_aval2['fator_capacidade_beneficio'] = df_aval2.fator_capacidade_beneficio.map(tools.convertToIndice)
df_aval2['opcao_bua'] = df_aval2.opcao_bua.map(tools.convertToPercent)
df_aval2['saque_bua'] = df_aval2.saque_bua.map(tools.convertToPercent)


nomes_colunas = {'NR_TEMPO_TAXA_JUROS': 't', 'VL_TAXA_JUROS': 'taxa_juros'}
df_taxa_juros2 = df_taxa_juros1.rename(columns= nomes_colunas)
df_taxa_juros2['taxa_juros'] = df_taxa_juros2.taxa_juros.map(tools.convertToPercent)


nomes_colunas = {'NR_TEMPO_TAXA_RISCO': 't', 'ID_RESPONSABILIDADE': 'responsabilidade', 'VL_TAXA_RISCO': 'taxa_risco'}
df_taxa_risco2 = df_taxa_risco1.rename(columns= nomes_colunas)
df_taxa_risco2['taxa_risco'] = df_taxa_risco2.taxa_risco.map(tools.convertToPercent)


nomes_colunas = {'ID_PLANO_BENEFICIO': 'plano_beneficio', 'IDADE_INICIO_CONTRIB_INSS_MAS': 'idade_inicio_contrib_inss_mas', 'IDADE_INICIO_CONTRIB_INSS_FEM': 'idade_inicio_contrib_inss_fem',
                 'IDADE_APOSENT_FUNDACAO_MAS': 'idade_aposent_fundacao_mas', 'IDADE_APOSENT_FUNDACAO_FEM': 'idade_aposent_fundacao_fem', 'TEMPO_CONTRIB_INSS_MAS': 'tempo_contrib_inss_mas',
                 'TEMPO_CONTRIB_INSS_FEM': 'tempo_contrib_inss_fem', 'MAIORIDADE_PLANO': 'maioridade_plano', 'PERCENTUAL_SRB': 'percentual_srb', 'TEMPO_CARENCIA_APOSENTADORIA': 'carencia_aposentadoria'}
df_prem_plano2 = df_prem_plano1.rename(columns= nomes_colunas).drop(['ID_PREMISSA_PLANO'], axis=1)[df_prem_plano1.ID_PLANO_BENEFICIO == int(df_aval2.plano_beneficio)]
df_prem_plano2['percentual_srb'] = df_prem_plano2.percentual_srb.map(tools.convertToPercent)


nomes_colunas = {'DT_ORIGEM_BNH': 'data_bnh', 'DT_LEI_9876_1999': 'data_lei_9876', 'DT_MEDIA_80_MAIORES_SALARIOS': 'data_media_maiores_salarios', 'TETO_CONTRIBUICAO_INSS': 'teto_contribuicao_inss',
                 'TETO_BENEFICIO_INSS': 'teto_beneficio_inss', 'SALARIO_MINIMO': 'salario_minimo', 'COTA_FAMILIAR_PENSAO': 'cota_pensao_familiar',
                 'PROB_APOSENTADO_CASADO_MAS': 'prob_aposentado_casado_mas', 'PROB_APOSENTADO_CASADO_FEM': 'prob_aposentado_casado_fem', 'DIF_IDADE_CONJUGE_MAS': 'dif_idade_conjuge_mas',
                 'DIF_IDADE_CONJUGE_FEM': 'dif_idade_conjuge_fem', 'LX_INICIAL': 'lx_inicial'}
df_prem_global2 = df_prem_global1.rename(columns= nomes_colunas).drop(['ID_PREMISSA_GLOBAL'], axis=1)
df_prem_global2.cota_pensao_familiar = df_prem_global2.cota_pensao_familiar.map(tools.convertToPercent)
df_prem_global2.prob_aposentado_casado_mas = df_prem_global2.prob_aposentado_casado_mas.map(tools.convertToPercent)
df_prem_global2.prob_aposentado_casado_fem = df_prem_global2.prob_aposentado_casado_fem.map(tools.convertToPercent)
df_prem_global2['avaliacao'] = df_aval2.avaliacao


nomes_colunas = {'COTDATA': 'data_indice', 'COTVALOR': 'indice'}
df_indice2 = df_indice1.rename(columns= nomes_colunas)
df_indice2.indice = df_indice2.indice.map(tools.convertToIndice)


nomes_colunas = {'ID_REFERENCIA_IDX_MON': 'id_indexador', 'PC_REAJUSTE': 'pc_indexador'}
df_indexador2 = df_indexador1.rename(columns=nomes_colunas).drop(['DS_REFERENCIA_IDX_MON'], axis=1)


nomes_colunas = {'CD_TIPO_REAJUSTE_SALARIAL': 'id_reajuste', 'ID_PATROCINADORA': 'patrocinadora', 'PC_REAJUSTE': 'pc_reajuste'}
df_reaj_salarial2 = df_reaj_salarial1.rename(columns= nomes_colunas).drop(['DS_TIPO_REAJUSTE_SALARIAL'], axis= 1)
df_reaj_salarial2.pc_reajuste = df_reaj_salarial2.pc_reajuste.map(tools.convertToPercent)


df_avaliacao = pd.merge(df_aval2, df_prem_plano2, how='inner', on='plano_beneficio')
df_avaliacao = pd.merge(df_avaliacao, df_prem_global2, how='inner', on='avaliacao')

# participantes
nomes_colunas = {'ID_PARTICIPANTE': 'id_participante', 'NR_MATRICULA': 'matricula', 'DT_NASCIMENTO': 'data_nascimento_partic', 'IR_SEXO': 'sexo_partic', 'ID_PATROCINADORA': 'patrocinadora',
                 'CD_ESTADO_CIVIL': 'estado_civil', 'DT_ADMISSAO': 'data_admissao', 'DT_ASSOCIACAO_FUNDACAO': 'data_associacao', 'PC_BENEFICIO_ESPECIAL': 'pbe', 'FL_DEFICIENTE': 'deficiente',
                 'NR_MATRICULA_TITULAR': 'matricula_titular', 'FL_MIGRADO': 'migrado'}
df_partic1 = pd.read_csv("input_csv/participante.csv", sep=";", decimal=",", encoding="latin1", parse_dates=['DT_NASCIMENTO', 'DT_OPCAO_BPD', 'DT_ADMISSAO', 'DT_ASSOCIACAO_FUNDACAO'], dtype= {'NR_MATRICULA': str, 'matricula_titular': str}, low_memory = False).rename(columns= nomes_colunas).drop(['CD_SITUACAO_PATROC', 'DS_ESTADO_CIVIL', 'DT_OPCAO_BPD'], axis= 1)
#df_partic2 = df_partic1.rename(columns= nomes_colunas).drop(['CD_SITUACAO_PATROC', 'DS_ESTADO_CIVIL', 'DT_OPCAO_BPD'], axis= 1)
df_partic1.deficiente = df_partic1.deficiente.map(tools.convertToBoolean)
df_partic1.migrado = df_partic1.migrado.map(tools.convertToBoolean)
df_partic1.pbe = df_partic1.pbe.map(tools.convertToPercent)


nomes_colunas = {'ID_PARTICIPANTE': 'id_participante', 'DT_ADESAO': 'data_adesao', 'VL_SLD_SUBCONTA_PARTICIPANTE': 'saldo_conta_partic', 'VL_SLD_SUBCONTA_PATROCINADORA': 'saldo_conta_patroc',
                 'VL_RESERVA_BPD': 'reserva_bpd', 'VL_SALDO_PORTADO': 'saldo_portado', 'VL_BEN_SALDADO_INICIAL': 'beneficio_saldado', 'VL_SALARIO_PARTICIPACAO': 'salario_participacao',
                 'PC_CONTRIBUICAO_PARTICIPANTE': 'contribuicao_partic', 'PC_CONTRIBUICAO_PATROCINADORA': 'contribuicao_patroc'}
df_plano1 = pd.read_csv("input_csv/plano_beneficio.csv", sep=";", decimal=",", parse_dates=['DT_ADESAO']).rename(columns= nomes_colunas)
df_plano1.contribuicao_partic = df_plano1.contribuicao_partic.map(tools.convertToPercent)
df_plano1.contribuicao_patroc = df_plano1.contribuicao_patroc.map(tools.convertToPercent)


df_benef_inss1 = pd.read_csv("input_csv/beneficio_inss.csv", sep=";", decimal=",", parse_dates=['DT_INICIO_BENEFICIO'])
nomes_colunas = {'ID_PARTICIPANTE': 'id_participante', 'DT_INICIO_BENEFICIO': 'dib_inss', 'VL_VALOR': 'valor_beneficio_inss'}
df_benef_inss2 = df_benef_inss1.rename(columns= nomes_colunas)


nomes_colunas = {'ID_PARTICIPANTE': 'id_participante', 'IDBENEFICIO': 'beneficio', 'VL_VALOR': 'valor_beneficio_funcef', 'DT_INICIO_BENEFICIO': 'dib_funcef'}
df_benef_func1 = pd.read_csv("input_csv/beneficio_funcef.csv", sep=";", decimal=",", encoding="latin1", parse_dates=['DT_INICIO_BENEFICIO']).rename(columns= nomes_colunas).drop(['NOME'], axis= 1)
df_benef_func1['tipo_beneficio'] = df_benef_func1.beneficio.map(tools.convertToTipoBeneficio)
df_benef_func2 = df_benef_func1[df_benef_func1.tipo_beneficio != 0].drop(['beneficio'], axis = 1)


nomes_colunas = {'ID_PARTICIPANTE': 'id_participante', 'CD_GRAU_DEPENDENCIA': 'parentesco', 'DT_NASCIMENTO': 'data_nascimento', 'IR_SEXO': 'sexo', 'FL_INVALIDO': 'invalido'}
df_depend1 = pd.read_csv("input_csv/dependente.csv", sep=";", decimal=",", encoding="latin1", parse_dates=['DT_NASCIMENTO']).rename(columns= nomes_colunas).drop(['FL_DESIGNADO_RESGATE', 'FL_DEPENDENTE_LEGAL'], axis=1)
df_depend1.invalido = df_depend1.invalido.map(tools.convertToBoolean)


df_depend_valido = df_depend1[(df_depend1.parentesco == 'COM') & (df_depend1.invalido == False)].rename(columns = {'sexo': 'sexo_valido'}).drop(['parentesco', 'invalido'], axis = 1)
df_depend_valido['idade_valido'] = list(map(tools.calculateAge, df_depend_valido.data_nascimento, itertools.repeat(df_avaliacao.data_calculo, len(df_depend_valido))))
print(df_depend_valido.head(10))

df_depend_invalido = df_depend1[df_depend1.invalido == True].rename(columns = {'sexo': 'sexo_invalido'}).drop(['parentesco', 'invalido'], axis = 1)
#print(df_depend_invalido)

df_depend_temporario = df_depend1[(df_depend1.parentesco == 'FIL') & (df_depend1.invalido == False)].rename(columns = {'sexo': 'sexo_temporario'}).drop(['parentesco', 'invalido'], axis = 1)
#print(df_depend_temporario)





