
%_eg_conditional_dropds(WORK.PARTICIPANTE);
PROC SQL;
   	CREATE TABLE WORK.PARTICIPANTE AS
   	SELECT t1.ID_PARTICIPANTE,
          t1.ID_CADASTRO AS CdSitCadPart,
          t1.NR_MATRICULA AS NuMatrPartic,
          (DATEPART(t1.DT_NASCIMENTO)) FORMAT=DDMMYY10. AS DtNascPartic,
	      t1.ID_SEXO AS CdSexoPartic,
          t1.ID_PATROCINADORA AS CdPatrocPlan,
          t1.ID_SITUACAO_PATROCINADORA,
	  	t1.ID_ESTADO_CIVIL AS CdEstCivPart,
            (DATEPART(t1.DT_OPCAO_BPD)) FORMAT=DDMMYY10. AS DT_OPCAO_BPD,
            (DATEPART(t1.DT_ADMISSAO)) FORMAT=DDMMYY10. AS DtAdmPatroci,
            (DATEPART(t1.DT_ASSOCIACAO_FUNDACAO)) FORMAT=DDMMYY10. AS DtAssEntPrev,
          (t1.PC_BENEFICIO_ESPECIAL / 100) AS PeFatReduPbe,
          t1.ID_ENTIDADE_ORIGEM AS CdParEntPrev,
		  t1.FL_DEFICIENTE,
          t1.NR_MATRICULA_TITULAR AS NuMatrOrigem,
		  (CASE
		  	WHEN t1.NR_MATRICULA_TITULAR IS NULL THEN 0
			ELSE 1
		   END) AS FlgPensionista,
			t1.fl_migrado
  FROM sgca.TB_ATU_PARTICIPANTE t1
  WHERE t1.ID_CADASTRO = &id_cadastro.
  ORDER BY t1.ID_PARTICIPANTE;
RUN;

*--- plano beneficio ---*;
%_eg_conditional_dropds(WORK.PLANO_BENEFICIO);
PROC SQL;
	CREATE TABLE WORK.PLANO_BENEFICIO AS
	SELECT  distinct(t1.ID_PARTICIPANTE),
			t1.ID_PLANO,
			(DATEPART(t1.DT_ADESAO)) FORMAT=DDMMYY10. AS DtAdesaoPlan,
			t1.VL_SALDO_CONTA_PARTICIPANTE FORMAT=COMMAX14.2 AS VlSdoConPart,
			t1.VL_SALDO_CONTA_PATROCINADORA FORMAT=COMMAX14.2 AS VlSdoConPatr,
			t1.VL_RESERVA_BPD FORMAT=COMMAX14.2,
			t1.VL_SALDO_PORTADO FORMAT=COMMAX14.2,
			t1.VL_BENEFICIO_SALDADO FORMAT=COMMAX14.2 AS VlBenSaldado,
			t1.VL_SALARIO_PARTICIPACAO FORMAT=COMMAX14.2 AS VlSalEntPrev,
			t1.ID_SITUACAO_FUNDACAO,
			(t1.PC_CONTRIBUICAO_PARTICIPANTE / 100) FORMAT=.5 AS PeContrParti,
			(t1.PC_CONTRIBUICAO_PATROCINADORA / 100) FORMAT=.5 AS PeContrPatro
		FROM sgca.TB_ATU_PARTIC_PLANO t1
		INNER JOIN WORK.PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE)
	WHERE t1.ID_PLANO = &IDPLANOPREV
		ORDER BY t1.ID_PARTICIPANTE;
RUN;

*--- beneficio inss ----*;
%_eg_conditional_dropds(WORK.BENEFICIO_INSS);
PROC SQL;
   CREATE TABLE WORK.BENEFICIO_INSS AS
   SELECT distinct(t1.ID_PARTICIPANTE),
          (DATEPART(t1.DT_INICIO_BENEFICIO)) FORMAT=DDMMYY10. AS DtIniBenInss,
		  t1.VL_VALOR FORMAT=COMMAX14.2 AS VlBenefiInss
      FROM sgca.TB_ATU_PARTIC_BEN_RGPS t1
      INNER JOIN WORK.PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE)
      ORDER BY t1.ID_PARTICIPANTE;
RUN;

*--- beneficio funcef ---;
%_eg_conditional_dropds(work.beneficio_funcef_all);
PROC SQL;
   CREATE TABLE work.beneficio_funcef_all AS
   SELECT t1.ID_PARTICIPANTE,
		  t1.VL_VALOR format=commax14.2,
          (DATEPART(t1.DT_INICIO_BENEFICIO)) FORMAT=DDMMYY10. AS DT_INICIO_BENEFICIO,
		  B.ID_TIPO_BENEFICIO,
		  tb.NM_TIPO_BENEFICIO,
		  o.nm_origem_beneficio
      FROM sgca.TB_ATU_PARTIC_BEN_FUNCEF t1
      INNER JOIN WORK.PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE)
	  INNER JOIN sgca.TB_ATU_BENEFICIO B ON (t1.ID_BENEFICIO = B.ID_BENEFICIO)
	  LEFT JOIN sgca.tb_atu_origem_beneficio o on (t1.id_origem_beneficio = o.id_origem_beneficio)
	  INNER JOIN sgca.tb_atu_tipo_beneficio tb on (b.ID_TIPO_BENEFICIO = tb.ID_TIPO_BENEFICIO)
	 WHERE t1.ID_PLANO = &IDPLANOPREV.
	 AND B.ID_ENTIDADE = 1
      ORDER BY t1.ID_PARTICIPANTE;
RUN;

%_eg_conditional_dropds(work.tipo_beneficio_dib_funcef);
PROC SQL;
   CREATE TABLE work.tipo_beneficio_dib_funcef AS
	SELECT distinct(t1.ID_PARTICIPANTE),
		   t1.ID_TIPO_BENEFICIO as CdTipoBenefi,
		   t1.DT_INICIO_BENEFICIO as DtIniBenPrev,
		   t1.NM_TIPO_BENEFICIO,
		   t1.nm_origem_beneficio
	FROM work.beneficio_funcef_all t1
	WHERE t1.ID_TIPO_BENEFICIO <> 0
	ORDER BY t1.ID_PARTICIPANTE;
RUN;

%_eg_conditional_dropds(work.BENEFICIO_FUNCEF);
PROC SQL;
	CREATE TABLE work.BENEFICIO_FUNCEF AS
    SELECT t1.ID_PARTICIPANTE,
			SUM(t1.VL_VALOR) format=commax14.2 AS VlBenefiPrev
	FROM work.beneficio_funcef_all t1
   GROUP BY t1.ID_PARTICIPANTE
   ORDER BY t1.ID_PARTICIPANTE;
RUN;

%_eg_conditional_dropds(partic.beneficio_funcef);
data partic.beneficio_funcef;
	merge work.beneficio_funcef work.tipo_beneficio_dib_funcef;
	by id_participante;
run;

proc delete data = work.tipo_beneficio_dib_funcef work.beneficio_funcef_all;


*--- rubrica judicial ----*;
%_eg_conditional_dropds(WORK.RUBRICA_JUDICIAL);
PROC SQL noprint;
	CREATE TABLE work.RUBRICA_JUDICIAL AS
	SELECT t1.ID_PARTICIPANTE,
           (DATEPART(t1.DT_INICIO_BENEFICIO)) FORMAT=DDMMYY10. AS DtIniRubJud,
		   t1.VL_VALOR FORMAT=COMMAX14.2 AS VlBenefiRubJud
     FROM sgca.TB_ATU_PARTIC_RUB_JUDICIAL t1
/*    INNER JOIN WORK.PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE)*/
	INNER JOIN WORK.PLANO_BENEFICIO t3 ON (t1.ID_PARTICIPANTE = t3.ID_PARTICIPANTE AND t1.ID_PLANO = t3.ID_PLANO)
    ORDER BY t1.ID_PARTICIPANTE;

	SELECT COUNT (*) INTO: numberOfRubricas
  	FROM work.RUBRICA_JUDICIAL;
RUN;

%macro updateRubrica;
	%if (&numberOfRubricas > 0) %then %do;
		proc sql;
			update work.beneficio_funcef b1
			set DtIniBenPrev = (select DtIniRubJud from work.rubrica_judicial r1 where b1.id_participante = r1.id_participante),
				VlBenefiPrev = (select VlBenefiRubJud from work.rubrica_judicial r1 where b1.id_participante = r1.id_participante);
		run;
	%end;
%mend;
%updateRubrica;


*--- dependente ---*;
%_eg_conditional_dropds(WORK.DEPENDENTE);
PROC SQL;
   CREATE TABLE WORK.DEPENDENTE AS
   SELECT t1.ID_PARTICIPANTE,
            (CASE
               WHEN tp.CD_TIPO_DEPENDENTE = 'COM' THEN 1
			   WHEN tp.CD_TIPO_DEPENDENTE = 'EXC' THEN 1
               WHEN tp.CD_TIPO_DEPENDENTE = 'FIL' THEN 2
			   WHEN tp.CD_TIPO_DEPENDENTE = 'ENT' THEN 2
               ELSE 3
            END) AS CD_GRAU_DEPENDENCIA,
            (DATEPART(t1.DT_NASCIMENTO)) FORMAT=DDMMYY10. AS DT_NASCIMENTO,
            t1.ID_SEXO,
            t1.FL_INVALIDO
      FROM sgca.TB_ATU_PARTIC_DEPENDENTE t1
	  INNER JOIN WORK.PARTICIPANTE t2 ON (t1.ID_PARTICIPANTE = t2.ID_PARTICIPANTE)
	  INNER JOIN sgca.TB_ATU_TIPO_DEPENDENTE tp ON (T1.ID_TIPO_DEPENDENTE = tp.ID_TIPO_DEPENDENTE)
      ORDER BY t1.ID_PARTICIPANTE;
RUN;

%_eg_conditional_dropds(WORK.CONJUGE);
PROC SQL;
	CREATE TABLE WORK.CONJUGE AS
	SELECT distinct(t1.ID_PARTICIPANTE),
			t1.ID_SEXO AS CdSexoConjug,
			t1.DT_NASCIMENTO AS DtNascConjug
	FROM WORK.DEPENDENTE t1
	WHERE t1.CD_GRAU_DEPENDENCIA = 1
	ORDER BY t1.ID_PARTICIPANTE;
RUN;

%_eg_conditional_dropds(WORK.FILHO_JOVEM);
PROC SQL;
	CREATE TABLE WORK.FILHO_JOVEM AS
	SELECT DISTINCT(t1.ID_PARTICIPANTE) AS ID_PARTICIPANTE,
			t1.ID_SEXO AS CdSexoFilJov,
			t1.DT_NASCIMENTO AS DtNascFilJov
	FROM WORK.DEPENDENTE t1
	WHERE t1.CD_GRAU_DEPENDENCIA = 2
	AND t1.FL_INVALIDO = 0
	ORDER BY t1.ID_PARTICIPANTE, t1.DT_NASCIMENTO;
RUN;

%_eg_conditional_dropds(WORK.FILHO_INVALIDO);
PROC SQL;
	CREATE TABLE WORK.FILHO_INVALIDO AS
	SELECT DISTINCT(t1.ID_PARTICIPANTE) AS ID_PARTICIPANTE,
			t1.ID_SEXO as CdSexoFilInv,
			t1.DT_NASCIMENTO AS DtNascFilInv
	FROM WORK.DEPENDENTE t1
	WHERE t1.CD_GRAU_DEPENDENCIA = 2
	AND t1.FL_INVALIDO = 1
	ORDER BY t1.ID_PARTICIPANTE, t1.DT_NASCIMENTO;
RUN;

PROC DELETE DATA = WORK.DEPENDENTE;

data work.participante;
	MERGE WORK.PARTICIPANTE WORK.PLANO_BENEFICIO WORK.BENEFICIO_INSS PARTIC.BENEFICIO_FUNCEF WORK.CONJUGE WORK.FILHO_JOVEM WORK.FILHO_INVALIDO;
	BY ID_PARTICIPANTE;

	if (VlBenefiInss = .) then
		VlBenefiInss = 0;

	if (VlBenefiPrev = .) then
		VlBenefiPrev = 0;

	if (ID_SITUACAO_FUNDACAO in (58, 63, 121)) then
		CdAutoPatroc = 1;
	else CdAutoPatroc = 0;

	/*if (CD_SITUACAO_FUNDACAO not in (1, 2, 3, 26, 33, 41, 77, 93, 112, 116) & CdTipoBenefi = .) then
			flg_manutencao_saldo = 1;
	else flg_manutencao_saldo = 0;*/

	if (ID_SITUACAO_FUNDACAO not in (1, 2, 3, 4, 11, 12, 15, 26, 33, 36, 37, 38, 39, 41, 65, 77, 83, 89, 93, 112, 116) & CdTipoBenefi = .) then
			flg_manutencao_saldo = 1;
	else flg_manutencao_saldo = 0;;
run;


*--- separa participante grupo ativo e assistido ---*;
%_eg_conditional_dropds(work.ATIVOS);
PROC SQL;
	CREATE TABLE work.ATIVOS AS
	SELECT p1.*
	FROM WORK.PARTICIPANTE p1
	WHERE CdTipoBenefi IS NULL
	AND DtIniBenPrev IS NULL
	ORDER BY p1.ID_PARTICIPANTE;
RUN;

PROC SQL NOPRINT;
	SELECT COUNT (*) INTO: numberOfAtivos
	FROM work.ATIVOS;
RUN;

%_eg_conditional_dropds(work.ASSISTIDOS);
PROC SQL;
	CREATE TABLE work.ASSISTIDOS AS
   	SELECT *
  	FROM WORK.PARTICIPANTE t1
	WHERE CdTipoBenefi IS NOT NULL
	AND DtIniBenPrev IS NOT NULL
	ORDER BY t1.ID_PARTICIPANTE;
RUN;

PROC SQL NOPRINT;
	SELECT COUNT (*) INTO: numberOfAssistidos
	FROM work.ASSISTIDOS;
RUN;

*PROC DELETE DATA = WORK.PLANO_BENEFICIO WORK.BENEFICIO_INSS WORK.BENEFICIO_FUNCEF WORK.RUBRICA_JUDICIAL WORK.CONJUGE WORK.FILHO_JOVEM WORK.FILHO_INVALIDO WORK.PARTICIPANTE;
