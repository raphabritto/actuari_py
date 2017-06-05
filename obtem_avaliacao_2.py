
# coding: utf-8

import pyodbc as od
import pandas as pd

oraCon = od.connect("DSN=HOM;Uid=webplanus;Pwd=webplanus99")

oraQuery = "SELECT t1.ID_AVALIACAO, c1.ID_PLANO_BENEFICIO, t2.IDPLANOPREV, t1.ID_CADASTRO, t1.DT_CALCULO, t1.NR_IDADE_INI_CONT_INSS_MAS, t1.NR_IDADE_INI_CONT_INSS_FEM, t1.NR_IDADE_INI_APOS_MAS, t1.NR_IDADE_INI_APOS_FEM, t1.NR_TEMPO_CONT_INSS_MAS, t1.NR_TEMPO_CONT_INSS_FEM, t1.NR_MAIORIDADE_PLANO, t1.DT_REAJUSTE_BENEFICIO, t1.VL_BENEFICIO_MINIMO, t1.PC_DESPESA_ADM_PARTICIPANTE, t1.PC_DESPESA_ADM_PATROCINADORA, t1.PC_SAIDA_BPD, t1.PC_SAIDA_PORTABILIDADE, t1.PC_SAIDA_RESGATE, t1.VL_PECULIO_MINIMO_MORTE, t1.PC_PECULIO_MINIMO_MORTE, t1.VL_PECULIO_MORTE_ASSISTIDO, t1.NR_PAGTOS_BENEF_CONTRIB_ANO, t1.PC_FAIXA_01_CONTRIBUICAO, t1.PC_FAIXA_02_CONTRIBUICAO, t1.PC_FAIXA_03_CONTRIBUICAO, t1.PC_CONTRIBUICAO_PATROCINADORA, t1.PC_META_CUSTEIO_ADMIN, t1.PC_TAXA_ADMIN_BENEFICIO, t1.VL_INICIAL_LX, t1.PC_TAXA_REAL_CRESC_SALARIAL, t1.PC_TAXA_REAL_CRESC_BENEFICIO, t1.PC_COTA_FAMILIAR_PENSAO, t1.PC_PROB_PARTIC_CAS_APOS_MAS, t1.PC_PROB_PARTIC_CAS_APOS_FEM, t1.NR_DIFERENCIA_IDADE_CONJ_MAS, t1.NR_DIFERENCIA_IDADE_CONJ_FEM, t1.PC_FATOR_VLR_REAL_SALARIO, t1.PC_FATOR_VLR_REAL_BEN_FUNCEF, t1.PC_FATOR_VLR_REAL_BEN_INSS,                 t1.VL_TETO_INSS_CONTRIBUICAO,                 t1.VL_TETO_INSS_BENEFICIO,                 t1.VL_SALARIO_MINIMO,                 t1.PC_FATOR_REAJ_BENEF_LIQUIDO,                 t1.NR_MULT_SAL_PARTIC_BENEF_RISCO,                 t1.PC_OPCAO_BUA,                 t1.PC_SAQUE_BUA FROM TB_ATU_AVALIACAO t1, TB_ATU_CADASTRO c1, TB_ATU_PLANO_BENEFICIO t2 WHERE t1.ID_CADASTRO = c1.ID_CADASTRO AND c1.ID_PLANO_BENEFICIO = t2.ID_PLANO_BENEFICIO AND t1.ID_AVALIACAO = " + str(25445)

global df_aval = pd.read_sql(oraQuery, oraCon)

df_aval.dtypes

df_aval

oraQuery = "SELECT t1.CD_TIPO_REAJUSTE_SALARIAL, t1.ID_PATROCINADORA, t1.PC_REAJUSTE, t2.DS_TIPO_REAJUSTE_SALARIAL               FROM TB_ATU_AVAL_PLANO_REAJ_SAL t1               JOIN TB_ATU_TIPO_REAJUSTE_SALARIAL t2 ON (t1.CD_TIPO_REAJUSTE_SALARIAL = t2.CD_TIPO_REAJUSTE_SALARIAL)              WHERE t1.ID_AVALIACAO = " + str(int(df_aval['ID_AVALIACAO'])) + " ORDER BY t1.ID_AVAL_PLANO_REAJ_SAL"

df_reaj_sal = pd.read_sql(oraQuery, oraCon)

df_reaj_sal.dtypes

df_reaj_sal

oraQuery = "SELECT t1.ID_REFERENCIA_IDX_MON, t1.PC_REAJUSTE, t2.DS_REFERENCIA_IDX_MON               FROM TB_ATU_AVAL_PLANO_IDX_MON t1               JOIN tb_atu_referencia_idx_mon t2 ON (t1.ID_REFERENCIA_IDX_MON = t2.ID_REFERENCIA_IDX_MON)              WHERE t1.ID_AVALIACAO = " + str(int(df_aval['ID_AVALIACAO'])) + " ORDER BY t1.ID_REFERENCIA_IDX_MON"

df_ind_monet = pd.read_sql(oraQuery, oraCon)

df_ind_monet.dtypes

df_ind_monet

oraQuery = "select t1.nr_tempo_taxa_juros, t1.vl_taxa_juros               from tb_atu_avaliacao_taxa_juros t1              where t1.id_avaliacao = " + str(int(df_aval['ID_AVALIACAO'])) + " order by t1.nr_tempo_taxa_juros"

df_juros = pd.read_sql(oraQuery, oraCon)

df_juros.dtypes

df_juros

oraQuery = "select t1.nr_tempo_taxa_risco, t1.id_responsabilidade, t1.vl_taxa_risco               from tb_atu_avaliacao_taxa_risco t1              where t1.id_avaliacao = " + str(int(df_aval['ID_AVALIACAO'])) + " order by t1.id_responsabilidade, t1.nr_tempo_taxa_risco"

df_risco = pd.read_sql(oraQuery, oraCon)

df_risco.dtypes

df_risco

oraQuery = "SELECT t1.DT_ORIGEM_BNH, t1.DT_INICIO_LEI_9876_1999, t1.DT_INICIO_MEDIA_80PC_MAIORES_S               FROM TB_ATU_PARAMETRIZACAO t1              WHERE t1.DT_VIGENCIA_FIM IS NULL              ORDER BY t1.ID_PARAMETRIZACAO DESC"

df_param = pd.read_sql(oraQuery, oraCon)

df_param.dtypes

df_param

oraQuery = "SELECT t1.COTDATA, t1.COTVALOR               FROM COTACAOMOEDA t1              WHERE t1.MOECODIGO = 7              ORDER BY t1.COTDATA"

df_cotacao = pd.read_sql(oraQuery, oraCon)

df_cotacao.dtypes

df_cotacao.head(8)

oraQuery = "SELECT t1.ID_PARTICIPANTE,                    t1.id_cadastro,                    t1.NR_MATRICULA,                    t1.DT_NASCIMENTO,                    t1.IR_SEXO,                    t1.ID_PATROCINADORA,                    t1.CD_SITUACAO_PATROC,                    t1.CD_ESTADO_CIVIL,                    t2.DS_ESTADO_CIVIL,                    t1.DT_OPCAO_BPD,                    t1.DT_ADMISSAO,                    t1.DT_ASSOCIACAO_FUNDACAO,                    t1.PC_BENEFICIO_ESPECIAL,                    t1.FL_DEFICIENTE,                    t1.NR_MATRICULA_TITULAR,                    t1.fl_migrado               FROM TB_ATU_PARTICIPANTE t1              INNER JOIN TB_ATU_ESTADO_CIVIL t2 on (t1.CD_ESTADO_CIVIL = t2.CD_ESTADO_CIVIL)              WHERE t1.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + " ORDER BY t1.ID_PARTICIPANTE"

df_partic = pd.read_sql(oraQuery, oraCon)

df_partic.dtypes

df_partic.head(8)

oraQuery = "SELECT  t1.ID_PARTICIPANTE,                     t1.DT_ADESAO,                     t1.VL_SLD_SUBCONTA_PARTICIPANTE,                     t1.VL_SLD_SUBCONTA_PATROCINADORA,                     t1.VL_RESERVA_BPD,                     t1.VL_SALDO_PORTADO,                     t1.VL_BEN_SALDADO_INICIAL,                     t1.VL_SALARIO_PARTICIPACAO,                     t1.CD_SITUACAO_FUNDACAO,                     t1.PC_CONTRIBUICAO_PARTICIPANTE,                     t1.PC_CONTRIBUICAO_PATROCINADORA                FROM TB_ATU_PARTIC_PLANO t1               INNER JOIN TB_ATU_PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE AND t2.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + ")               WHERE t1.IDPLANOPREV = " + str(int(df_aval['IDPLANOPREV'])) + " ORDER BY t1.ID_PARTICIPANTE"

df_plano = pd.read_sql(oraQuery, oraCon)

df_plano.dtypes

df_plano.head(8)

oraQuery = "SELECT t1.ID_PARTICIPANTE, t1.DT_INICIO_BENEFICIO, t1.VL_VALOR               FROM TB_ATU_PARTIC_BEN_RGPS t1              INNER JOIN TB_ATU_PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE AND t2.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + ")             ORDER BY t1.ID_PARTICIPANTE"

df_ben_inss = pd.read_sql(oraQuery, oraCon)

df_ben_inss.dtypes

df_ben_inss.head(8)

oraQuery = "SELECT t1.ID_PARTICIPANTE, t1.IDBENEFICIO, b1.nome, t1.VL_VALOR, t1.DT_INICIO_BENEFICIO               FROM TB_ATU_PARTIC_BEN_FUNCEF t1              INNER JOIN TB_ATU_PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE AND t2.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + ")             inner join beneficio b1 on (t1.idbeneficio = b1.idbeneficio)              WHERE t1.IDPLANOPREV = " + str(int(df_aval['IDPLANOPREV'])) + " ORDER BY t1.ID_PARTICIPANTE"

df_ben_func = pd.read_sql(oraQuery, oraCon)

df_ben_func.dtypes

df_ben_func.head(8)

oraQuery = "SELECT t1.ID_PARTICIPANTE, t1.DT_INICIO_BENEFICIO, t1.VL_VALOR               FROM TB_ATU_PARTIC_RUB_JUDICIAL t1              INNER JOIN TB_ATU_PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE AND t2.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + ")              INNER JOIN TB_ATU_PARTIC_PLANO t3 ON (t1.ID_PARTICIPANTE = t3.ID_PARTICIPANTE AND t1.IDPLANOPREV = t3.IDPLANOPREV)              ORDER BY t1.ID_PARTICIPANTE"

df_rubr = pd.read_sql(oraQuery, oraCon)

df_rubr.dtypes

df_rubr.head(8)

oraQuery = "SELECT t1.ID_PARTICIPANTE,                    t1.CD_GRAU_DEPENDENCIA,                    t1.DT_NASCIMENTO,                    t1.IR_SEXO,                    t1.FL_INVALIDO,                    t1.FL_DESIGNADO_RESGATE,                    t1.FL_DEPENDENTE_LEGAL               FROM TB_ATU_PARTIC_DEPENDENTE t1              INNER JOIN TB_ATU_PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE AND t2.ID_CADASTRO = " + str(int(df_aval['ID_CADASTRO'])) + ")             ORDER BY t1.ID_PARTICIPANTE"

df_depen = pd.read_sql(oraQuery, oraCon)

df_depen.dtypes

df_depen.head(8)

oraCon.close()