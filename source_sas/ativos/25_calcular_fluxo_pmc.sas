*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Versão: 22 de junho de 2012                                                                                   --*;
*-- Modificação para incorporar o saque de BUA: 30 de outubro de 2012                                             --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

%macro obter_ativos_fluxo_pmc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.pmc_ativos&a.);

		proc sql;
			create table determin.pmc_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					atc.BenLiqCobATC,
					t1.flg_manutencao_saldo,
					t5.dx,
/*					ALTERADO NO DIA 04/01/2018 */
/*					(case */
/*						when (t4.tDeterministico = 0 or (&CdPlanBen. = 4 | &CdPlanBen. = 5))*/
/*							then t5.apxa*/
/*							else t5.apx*/
/*					end) format=12.8 as apx,*/
					(case
						when (t4.tCobertura = 0 or (&CdPlanBen. = 4 | &CdPlanBen. = 5))
							then t6.apxa
							else t6.apx
					end) format=12.8 as apx,
					t6.lx format=commax14.2 as lx,
					(case
						when (&CdPlanBen. = 4 | &CdPlanBen. = 5)
							then 1
							else max(0, (ajco.lxs / ajca.lxs))
					end) format=12.8 as pxs,
					txc.vl_taxa_juros as taxa_juros_cob,
					txd.vl_taxa_juros as taxa_juros_det
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
			inner join determin.deterministico_ativos&a. t4 on (t1.id_participante = t4.id_participante and t3.t = t4.tCobertura)
			inner join work.taxa_juros txc on (txc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join work.taxa_juros txd on (txd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join cobertur.atc_ativos atc on (t1.id_participante = atc.id_participante and t3.t = atc.t)
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t4.IddPartiDeter = t5.Idade and t5.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t6 on (t1.CdSexoPartic = t6.Sexo and t3.IddPartEvol = t6.Idade and t6.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajco on (t1.CdSexoPartic = ajco.Sexo and t3.IddPartEvol = ajco.Idade and ajco.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajca on (t1.CdSexoPartic = ajca.Sexo and t1.IddPartiCalc = ajca.Idade and ajca.t = 0)
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_pmc;

%macro calcular_fluxo_pmc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.pmc_deterministico_ativos);

		proc iml;
			USE determin.pmc_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {BenLiqCobATC} into BenLiqCobATC;
				read all var {dx} into dx;
				read all var {lx} into lx;
				read all var {apx} into apx;
				read all var {flg_manutencao_saldo} into flg_manutencao_saldo;
				read all var {pxs} into pxs;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				vt_dx = J(qtsObs, 1, 0);
				despesa_pmc = J(qtsObs, 1, 0);
				despesa_vp_pmc = J(qtsObs, 1, 0);
				beneficio_pmc = J(qtsObs, 1, 0);
				pagamento_pmc = J(qtsObs, 1, 0);

				if (&CdPlanBen. ^= 1) then do;
					DO a = 1 TO qtsObs;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_pmc[a] = max(0, round((BenLiqCobAtc[a] / &FtBenEnti.) * &peculioMorteAssistido., 0.01));

							if (flg_manutencao_saldo[a] = 0 & beneficio_pmc[a] > 0) then
								beneficio_pmc[a] = max(beneficio_pmc[a], &LimPecMin.);
						end;
						else
							beneficio_pmc[a] = beneficio_pmc[a - 1];

						pagamento_pmc[a] = max(0, round(beneficio_pmc[a] * apx[a], 0.01));

						vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** (t_vt + 1)));
						vt_dx[a] = max(0, vt[a] * dx[a]);
						v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));

						if (lx[a] > 0) then
							despesa_pmc[a] = max(0, round(pagamento_pmc[a] * vt_dx[a] / lx[a], 0.01));

						despesa_vp_pmc[a] = max(0, round(despesa_pmc[a] * pxs[a] * v[a], 0.01));

						t_vt = t_vt + 1;
					END;
				end;

				create work.pmc_deterministico_ativos var {id_participante tCobertura tDeterministico beneficio_pmc pagamento_pmc despesa_pmc despesa_vp_pmc};
					append;
				close;
			end;
		quit;

		data determin.pmc_ativos&a.;
			merge determin.pmc_ativos&a. work.pmc_deterministico_ativos;
			by id_participante tCobertura tDeterministico;
			format beneficio_pmc commax14.2 pagamento_pmc commax14.2 despesa_pmc commax14.2 despesa_vp_pmc commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.pmc_ativos);
	data determin.pmc_ativos;
		set determin.pmc_ativos1 - determin.pmc_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete pmc_ativos1 - pmc_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.pmc_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_pmc;

%_eg_conditional_dropds(determin.pmc_despesa_ativos);
proc summary data = determin.pmc_ativos;
 class tDeterministico;
 var despesa_pmc despesa_vp_pmc;
 output out=determin.pmc_despesa_ativos sum=;
run;

data determin.pmc_despesa_ativos;
	set determin.pmc_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.pmc_encargo_ativos);
proc summary data = determin.pmc_ativos;
 class id_participante;
 var despesa_vp_pmc;
 output out=determin.pmc_encargo_ativos sum=;
run;

data determin.pmc_encargo_ativos;
	set determin.pmc_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;


%_eg_conditional_dropds(work.despesa_pmc_alm, WORK.despesa_pmc_alm_sorted, determin.despesa_pmc_alm);
proc sql;
	create table work.despesa_pmc_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_pmc) format=commax18.2 as despesa_pmc
	from determin.pmc_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

PROC SORT
	DATA=WORK.despesa_pmc_alm(KEEP=despesa_pmc tDeterministico)
	OUT=WORK.despesa_pmc_alm_sorted;
	BY tDeterministico;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_pmc_alm_sorted
	OUT=determin.despesa_pmc_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_pmc;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_pmc_alm_sorted, work.despesa_pmc_alm);

%macro calcula_encargo_pmc_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%_eg_conditional_dropds(work.encargo_pmc_alm);
		proc sql;
			create table work.encargo_pmc_alm as
			select c.id_participante,
				   c.t,
				   max(0, ((c.BenLiqCobATC / &FtBenEnti.) * c.apx * c.ax * &peculioMorteAssistido.)) format=commax14.2 as encargo_pmc
			from cobertur.atc_ativos c
			order by c.id_participante, c.t;
		run;

		%_eg_conditional_dropds(cobertur.encargo_pmc_alm);
		proc sql;
			create table cobertur.encargo_pmc_alm as
			select e.t,
				   max(0, sum(e.encargo_pmc)) format=commax18.2 as encargo_pmc
			from work.encargo_pmc_alm e
			group by e.t
			order by e.t;
		run;
	%end;
%mend;
%calcula_encargo_pmc_alm;

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			*delete pmc_ativos1 - pmc_ativos&numberOfBlocksAtivos;
			delete pmc_ativos;
			*delete pmc_encargo_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
