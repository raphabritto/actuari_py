
%macro loadAvaliacao;
	%if (%sysfunc(exist(work.avaliacao))) %then %do;
		DATA _NULL_;
			SET work.avaliacao;
			call symputx('isGravaMemoriaCalculo', FL_MEMORIA_CALCULO);
			call symputx('BenMinimo', VL_BENEFICIO_MINIMO);
/*			call symputx('CD_COMPOSICAO_FAMILIAR', CD_COMPOSICAO_FAMILIAR);*/
			call symputx('ID_AVALIACAO', ID_AVALIACAO);
			call symputx('ID_CADASTRO', ID_CADASTRO);
			call symputx('DtCalAval', DT_CALCULO);
			call symputx('DtReajBen', DT_REAJUSTE_BENEFICIO);
			call symputx('NR_DIFERENCIA_IDADE_CONJ_FEM', NR_DIFERENCIA_IDADE_CONJ_FEM);
			call symputx('NR_DIFERENCIA_IDADE_CONJ_MAS', NR_DIFERENCIA_IDADE_CONJ_MAS);
			call symputx('NR_IDADE_INI_CONT_INSS_MAS', NR_IDADE_INI_CONT_INSS_MAS);
			call symputx('NR_IDADE_INI_CONT_INSS_FEM', NR_IDADE_INI_CONT_INSS_FEM);
			call symputx('MaiorIdad', NR_MAIORIDADE_PLANO);
			call symputx('NR_TEMPO_CONT_INSS_MAS', NR_TEMPO_CONT_INSS_MAS);
			call symputx('NR_TEMPO_CONT_INSS_FEM', NR_TEMPO_CONT_INSS_FEM);
			call symputx('NR_IDADE_INI_APOS_MAS', NR_IDADE_INI_APOS_MAS);
			call symputx('NR_IDADE_INI_APOS_FEM', NR_IDADE_INI_APOS_FEM);
			call symputx('NroBenAno', NR_PAGTOS_BENEF_CONTRIB_ANO);
			call symputx('PC_DESPESA_ADM_PARTICIPANTE', PC_DESPESA_ADM_PARTICIPANTE);
			call symputx('PC_DESPESA_ADM_PATROCINADORA', PC_DESPESA_ADM_PATROCINADORA);
			call symputx('percentualSaidaBPD', PC_SAIDA_BPD);
			call symputx('percentualPortabilidade', PC_SAIDA_PORTABILIDADE);
			call symputx('percentualResgate', PC_SAIDA_RESGATE);
			call symputx('CtFamPens', PC_COTA_FAMILIAR_PENSAO);
			call symputx('Fxa01Cont', PC_FAIXA_01_CONTRIBUICAO);
			call symputx('Fxa02Cont', PC_FAIXA_02_CONTRIBUICAO);
			call symputx('Fxa03Cont', PC_FAIXA_03_CONTRIBUICAO);
			call symputx('FtBenLiquido', PC_FATOR_REAJ_BENEF_LIQUIDO);
			call symputx('FtBenEnti', PC_FATOR_VLR_REAL_BEN_FUNCEF);
			call symputx('FtBenInss', PC_FATOR_VLR_REAL_BEN_INSS);
			call symputx('FtSalPart', PC_FATOR_VLR_REAL_SALARIO);
			call symputx('PC_PROB_PARTIC_CAS_APOS_MAS', PC_PROB_PARTIC_CAS_APOS_MAS);
			call symputx('PC_PROB_PARTIC_CAS_APOS_FEM', PC_PROB_PARTIC_CAS_APOS_FEM);
			call symputx('TxaAdmBen', PC_TAXA_ADMIN_BENEFICIO);
			call symputx('PrTxBenef', PC_TAXA_REAL_CRESC_BENEFICIO);
			call symputx('PrSalPart', PC_TAXA_REAL_CRESC_SALARIAL);
/*			call symputx('PrTxJrAno', PC_TAXA_REAL_JUROS_ANUAL); -- campo retirado pra aplicacao da taxa de juros decrescente */
			call symputx('peculioMorteAtivo', PC_PECULIO_MORTE_ATIVO);
			call symputx('peculioMorteAssistido', PC_PECULIO_MORTE_ASSISTIDO);
			call symputx('LimPecMin', VL_PECULIO_MINIMO_MORTE);
			call symputx('VL_SALARIO_CAIXA', VL_SALARIO_CAIXA);
			call symputx('VL_TETO_INSS_CONTRIBUICAO', VL_TETO_INSS_CONTRIBUICAO);
			call symputx('TtInssBen', VL_TETO_INSS_BENEFICIO);
			call symputx('SalMinimo', VL_SALARIO_MINIMO);
			call symputx('VlrLxInicial', VL_INICIAL_LX);
			call symputx('TxCarregamentoAdm', PC_META_CUSTEIO_ADMIN);
/*			call symputx('FlCalculaFluxo', FL_FLUXO_RECEITA_DESPESA_FOLHA);*/
			call symputx('CdPlanBen', ID_PLANO_BENEFICIO);
			call symputx('IDPLANOPREV', ID_PLANO);
			call symputx('percentualBUA', PC_OPCAO_BUA);
			call symputx('percentualSaqueBUA', PC_SAQUE_BUA);
			call symputx('percentualSRB', NR_MULT_SAL_PARTIC_BENEF_RISCO);
		RUN;

		%_eg_conditional_dropds(work.parametro);
		PROC SQL;
		   CREATE TABLE work.PARAMETRO AS
		   SELECT (DATEPART(t1.DT_ORIGEM_BNH)) FORMAT=DDMMYY10. AS DT_ORIGEM_BNH,
				  (DATEPART(t1.DT_INICIO_LEI_9876_1999)) FORMAT=DDMMYY10. AS DT_INICIO_LEI_9876_1999,
				  (DATEPART(t1.DT_INICIO_MEDIA_80PC_MAIORES_S)) FORMAT=DDMMYY10. AS DT_INICIO_MEDIA_80PC_MAIORES_S
		      FROM sgca.TB_ATU_PARAMETRIZACAO t1
		      WHERE t1.DT_VIGENCIA_FIM IS MISSING
		      ORDER BY t1.ID_PARAMETRIZACAO DESC;
		RUN;

		DATA _NULL_;
			SET work.PARAMETRO;
			call symput('DtOrigBnh', DT_ORIGEM_BNH);
			call symput('DtLei9876', DT_INICIO_LEI_9876_1999);
			call symput('DatMedSal', DT_INICIO_MEDIA_80PC_MAIORES_S);
		RUN;

		%_eg_conditional_dropds(work.reajuste_salarial);
		PROC SQL;
		   CREATE TABLE work.REAJUSTE_SALARIAL AS
		   SELECT t1.ID_TIPO_REAJUSTE,
		          t1.ID_PATROCINADORA,
		          ((t1.PC_REAJUSTE / 100) + 1) AS PC_REAJUSTE,
				  t2.DS_TIPO_REAJUSTE
		      FROM sgca.TB_ATU_REAJUSTE_SALARIAL t1
			  JOIN sgca.TB_ATU_TIPO_REAJUSTE t2 ON (t1.ID_TIPO_REAJUSTE = t2.ID_TIPO_REAJUSTE)
		      WHERE t1.ID_AVALIACAO = &id_avaliacao
			  ORDER BY t1.ID_REAJUSTE_SALARIAL;
		RUN;

		%_eg_conditional_dropds(work.INDEXADOR_MONETARIO);
		PROC SQL;
		   CREATE TABLE work.INDEXADOR_MONETARIO AS
		   SELECT t1.ID_REFERENCIA_INDEXADOR,
		          t1.PC_REAJUSTE,
				  t2.DS_REFERENCIA_INDEXADOR
		      FROM sgca.TB_ATU_INDEXADOR_MONETARIO t1
			  JOIN sgca.TB_ATU_REFERENCIA_INDEXADOR t2 ON (t1.ID_REFERENCIA_INDEXADOR = t2.ID_REFERENCIA_INDEXADOR)
			  WHERE t1.ID_AVALIACAO = &id_avaliacao
		      ORDER BY t1.ID_REFERENCIA_INDEXADOR;
		RUN;

		%_eg_conditional_dropds(work.COTACAO);
		PROC SQL;
		   CREATE TABLE work.COTACAO AS
		   SELECT t1.IDCOTACAOMOEDA,
		          t1.MOECODIGO,
				  (DATEPART(t1.COTDATA)) FORMAT=DDMMYY10. AS COTDATA,
		            ((t1.COTVALOR / 100) + 1) AS COTVALOR
		      FROM sgca.tb_atu_cotacao_moeda t1
		      WHERE t1.MOECODIGO = 7
		      ORDER BY t1.COTDATA;
		RUN;

		%_eg_conditional_dropds(work.taxa_juros);
		proc sql;
			create table work.taxa_juros as
			select t1.nr_tempo_taxa_juros as t,
				   (t1.vl_taxa_juros / 100) as vl_taxa_juros
			from sgca.tb_atu_taxa_juros t1
			where t1.id_avaliacao = &id_avaliacao
			order by t1.nr_tempo_taxa_juros;
		run;

		PROC SQL NOPRINT;
			SELECT COUNT (*) INTO: numberOfTaxaJuros
			FROM work.taxa_juros;

			SELECT max(t) into: maxTaxaJuros
			FROM work.taxa_juros;
		RUN;

		%_eg_conditional_dropds(work.taxa_risco);
		proc sql;
			create table work.taxa_risco as
			select t1.nr_tempo_taxa_risco as t,
				   t1.id_responsabilidade,
				   (t1.vl_taxa_risco / 100) as vl_taxa_risco
			from sgca.tb_atu_taxa_risco t1
			where t1.id_avaliacao = &id_avaliacao
			order by t1.id_responsabilidade, t1.nr_tempo_taxa_risco;
		quit;

		PROC SQL NOPRINT;
			/*SELECT COUNT (*) INTO: numberOfTaxaRiscoPartic
			FROM work.taxa_risco t1
			WHERE t1.id_responsabilidade = 1;

			SELECT COUNT (*) INTO: numberOfTaxaRiscoPatroc
			FROM work.taxa_risco t1
			WHERE t1.id_responsabilidade = 2;*/

			SELECT max(t) INTO: maxTaxaRiscoPartic
			FROM work.taxa_risco t1
			WHERE t1.id_responsabilidade = 1;

			SELECT max(t) INTO: maxTaxaRiscoPatroc
			FROM work.taxa_risco t1
			WHERE t1.id_responsabilidade = 2;
		RUN;
	%end;
%mend;
%loadAvaliacao;

%macro mountLibrary;
	%if (&id_avaliacao > 0) %then %do;
		libname SISATU "&root_dir.\Avaliacoes\&id_avaliacao.\";
		libname TABUAS "&root_dir.\Avaliacoes\&id_avaliacao.\Tabuas\";
		libname COBERTUR "&root_dir.\Avaliacoes\&id_avaliacao.\Cobertura\";
		libname DETERMIN "&root_dir.\Avaliacoes\&id_avaliacao.\Deterministico\";
		libname PARTIC "&root_dir.\Avaliacoes\&id_avaliacao.\Participantes\";
		libname RISCO "&root_dir.\Avaliacoes\&id_avaliacao.\Risco\";
		libname TEMP "&root_dir.\Avaliacoes\&id_avaliacao.\Temp\";
		run;
	%end;
%mend;
%mountLibrary;


%put &isGravaMemoriaCalculo;
%put &BenMinimo;
%put &ID_AVALIACAO;
%put &ID_CADASTRO;
%put &DtCalAval;
%put &DtReajBen;
%put &NR_DIFERENCIA_IDADE_CONJ_FEM;
%put &NR_DIFERENCIA_IDADE_CONJ_MAS;
%put &NR_IDADE_INI_CONT_INSS_MAS;
%put &NR_IDADE_INI_CONT_INSS_FEM;
%put &MaiorIdad;
%put &NR_TEMPO_CONT_INSS_MAS;
%put &NR_TEMPO_CONT_INSS_FEM;
%put &NR_IDADE_INI_APOS_MAS;
%put &NR_IDADE_INI_APOS_FEM;
%put &NroBenAno;
%put &PC_DESPESA_ADM_PARTICIPANTE;
%put &PC_DESPESA_ADM_PATROCINADORA;
%put &percentualSaidaBPD;
%put &percentualPortabilidade;
%put &percentualResgate;
%put &CtFamPens;
%put &Fxa01Cont;
%put &Fxa02Cont;
%put &Fxa03Cont;
%put &FtBenLiquido;
%put &FtBenEnti;
%put &FtBenInss;
%put &FtSalPart;
%put &PC_PROB_PARTIC_CAS_APOS_MAS;
%put &PC_PROB_PARTIC_CAS_APOS_FEM;
%put &TxaAdmBen;
%put &PrTxBenef;
%put &PrSalPart;
%put &peculioMorteAtivo;
%put &peculioMorteAssistido;
%put &LimPecMin;
%put &VL_SALARIO_CAIXA;
%put &VL_TETO_INSS_CONTRIBUICAO;
%put &TtInssBen;
%put &SalMinimo;
%put &VlrLxInicial;
%put &TxCarregamentoAdm;
/*%put &FlCalculaFluxo;*/
%put &CdPlanBen;
%put &IDPLANOPREV;
%put &percentualBUA;
%put &percentualSaqueBUA;
%put &percentualSRB;
%put &numberOfTaxaJuros;
%put &maxTaxaJuros;
%put &maxTaxaRiscoPartic;
%put &maxTaxaRiscoPatroc;
