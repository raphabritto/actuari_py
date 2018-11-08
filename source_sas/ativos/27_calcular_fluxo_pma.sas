*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Versão: 22 de junho de 2012                                                                                   --*;
*-- Modificação para incorporar o saque de BUA: 30 de outubro de 2012                                             --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

/*%macro obter_ativos_fluxo_pma;*/
/*	%do a = 1 %to &numberOfBlocksAtivos.;*/
/*		%_eg_conditional_dropds(determin.pma_ativos&a.);*/

%_eg_conditional_dropds(WORK.pma_ativos);
		proc sql;
			create table WORK.pma_ativos as
			select t1.id_participante,
					t3.t as tCobertura,
/*					t4.tDeterministico,*/
					t3.SalConPrjEvol,
					t1.flg_manutencao_saldo,
					ajco.qx,
					t5.apxa format=10.8 as apx,
					max(0, (ajco.lxs / ajca.lxs)) format=10.8 as pxs,
					txc.vl_taxa_juros as taxa_juros_cob
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
/*			inner join determin.deterministico_ativos&a. t4 on (t4.id_participante = t3.id_participante and t3.t = t4.tCobertura)*/
			inner join work.taxa_juros txc on (txc.t = min(t3.t, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t3.IddPartEvol = t5.Idade and t5.t = min(t3.t, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajco on (t1.CdSexoPartic = ajco.Sexo and t3.IddPartEvol = ajco.Idade and ajco.t = min(t3.t, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajca on (t1.CdSexoPartic = ajca.Sexo and t1.IddPartiCalc = ajca.Idade and ajca.t = 0)
			order by t1.id_participante, t3.t;
		quit;
/*	%end;*/
/*%mend;*/
/*%obter_ativos_fluxo_pma;*/

%macro calcular_fluxo_pma;
/*	%do a = 1 %to &numberOfBlocksAtivos.;*/
		%_eg_conditional_dropds(work.pma_deterministico_ativos);

		proc iml;
			USE WORK.pma_ativos;
/*				read all var {id_participante tCobertura tDeterministico SalConPrjEvol apx qx flg_manutencao_saldo pxs taxa_juros_cob} into ativos;*/
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
/*				read all var {tDeterministico} into tDeterministico;*/
				read all var {SalConPrjEvol} into SalConPrjEvol;
				read all var {apx} into apx;
				read all var {qx} into qx;
				read all var {flg_manutencao_saldo} into flg_manutencao_saldo;
				read all var {pxs} into pxs;
				read all var {taxa_juros_cob} into taxa_juros_cob;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				beneficio_pma = J(qtsObs, 1, 0);
				despesa_pma = J(qtsObs, 1, 0);
				despesa_vp_pma = J(qtsObs, 1, 0);
				pagamento_pma = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);

				if (&CdPlanBen. ^= 1) then do;
					DO a = 1 TO qtsObs;
						if (flg_manutencao_saldo[a] = 0) then do;
							beneficio_pma[a] = max(0, max(&LimPecMin., round((SalConPrjEvol[a] / &FtBenEnti.) * &peculioMorteAtivo., 0.01)));
							pagamento_pma[a] = max(0, round(beneficio_pma[a] * qx[a] * (1 - apx[a]), 0.01));
							despesa_pma[a] = pagamento_pma[a];
							v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
							despesa_vp_pma[a] = max(0, round(pagamento_pma[a] * v[a] * pxs[a], 0.01));
						end;
					END;
				end;

				create work.pma_deterministico_ativos var {id_participante tCobertura beneficio_pma pagamento_pma despesa_pma despesa_vp_pma};
					append;
				close;
			end;
		quit;

		data determin.pma_ativos;
			merge WORK.pma_ativos work.pma_deterministico_ativos;
				by id_participante tCobertura;
			format beneficio_pma commax14.2 pagamento_pma commax14.2 despesa_pma commax14.2 despesa_vp_pma commax14.2;
		run;
/*	%end;*/

/*	%_eg_conditional_dropds(determin.pma_ativos);*/
/*	data determin.pma_ativos;*/
/*		set determin.pma_ativos1 - determin.pma_ativos&numberOfBlocksAtivos.;*/
/*	run;*/

/*	proc datasets nodetails library=determin;*/
/*	   delete pma_ativos1 - pma_ativos&numberOfBlocksAtivos.;*/
/*	run;*/

	proc delete data = work.pma_deterministico_ativos WORK.PMA_ATIVOS (gennum=all);
	run;
%mend;
%calcular_fluxo_pma;

%_eg_conditional_dropds(determin.pma_despesa_ativos);
proc summary data = determin.pma_ativos;
 class tCobertura;
 var despesa_pma despesa_vp_pma;
 format despesa_pma commax14.2 despesa_vp_pma commax14.2;
 output out=determin.pma_despesa_ativos sum=;
run;

data determin.pma_despesa_ativos;
	set determin.pma_despesa_ativos;
	if cmiss(tCobertura) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.pma_encargo_ativos);
proc summary data = determin.pma_ativos;
 class id_participante;
 var despesa_vp_pma;
 format despesa_vp_pma commax14.2;
 output out=determin.pma_encargo_ativos sum=;
run;

data determin.pma_encargo_ativos;
	set determin.pma_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(work.despesa_pma_alm, WORK.despesa_pma_alm_sorted, determin.despesa_pma_alm);
proc sql;
	create table work.despesa_pma_alm as
	select t1.tCobertura, sum(despesa_pma) format=commax18.2 as despesa_pma
	from determin.pma_ativos t1
	group by t1.tCobertura
	order by t1.tCobertura;
run;

PROC SORT
	DATA=WORK.despesa_pma_alm(KEEP=despesa_pma tCobertura)
	OUT=WORK.despesa_pma_alm_sorted;
	BY tCobertura;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_pma_alm_sorted
	OUT=determin.despesa_pma_alm(drop = Source rename= tCobertura = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tCobertura;
	VAR despesa_pma;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_pma_alm_sorted, work.despesa_pma_alm);

%macro calcular_encargo_pma_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%_eg_conditional_dropds(work.encargo_pma_alm);
		proc sql;
			create table work.encargo_pma_alm as
			select c.id_participante, c.t, max(0, ((c.SalConPrjEvol / &FtBenEnti.) * (1 - c.apx) * c.qx * &peculioMorteAssistido.)) format=commax14.2 as encargo_pma
			from cobertur.ppa_ativos c
			order by c.id_participante, c.t;
		run;

		%_eg_conditional_dropds(cobertur.encargo_pma_alm);
		proc sql;
			create table cobertur.encargo_pma_alm as
			select e.t, max(0, sum(e.encargo_pma)) format=commax18.2 as encargo_pma
			from work.encargo_pma_alm e
			group by e.t
			order by e.t;
		run;
	%end;
%mend;
%calcular_encargo_pma_alm;


/*%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			*delete pma_ativos1 - pma_ativos&numberOfBlocksAtivos;
			*delete pma_ativos;
			*delete pma_encargo_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;*/
