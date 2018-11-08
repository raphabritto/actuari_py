*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Modificação para incorporar o saque de BUA: 30 de outubro de 2012                                             --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

*--- obtem os participantes, os valores do beneficio e os fatores utilizados no calculo ca cobertura PTC ---*;
%macro obter_ativos_fluxo_ptc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.ptc_ativos&a.);

		proc sql;
			create table determin.ptc_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					t1.PrbCasado,
					ptc.BenTotCobPTC,
					ptc.BenLiqCobPtc,
					max(0, (t5.lx / t6.lx)) format=12.8 as lx,
					max(0, (t7.lx / t8.lx)) format=12.8 as ljx,
					(case
						when (&CdPlanBen. = 4 | &CdPlanBen. = 5)
							then 1
							else max(0, (t9.lxs / t10.lxs))
					end) format=12.8 as pxs,
					(case
						when (t4.tCobertura = 0 or (&CdPlanBen. = 4 | &CdPlanBen. = 5))
							then t6.apxa
							else t6.apx
					end) format=12.8 as apx,
					txc.vl_taxa_juros as taxa_juros_cob,
					txd.vl_taxa_juros as taxa_juros_det
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
			inner join determin.deterministico_ativos&a. t4 on (t1.id_participante = t4.id_participante and t3.t = t4.tCobertura)
			inner join work.taxa_juros txc on (txc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join work.taxa_juros txd on (txd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join cobertur.ptc_ativos ptc on (t1.id_participante = ptc.id_participante and t3.t = ptc.t)
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t4.IddPartiDeter = t5.Idade and t5.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t6 on (t1.CdSexoPartic = t6.Sexo and t3.IddPartEvol = t6.Idade and t6.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t7 on (t1.CdSexoConjug = t7.Sexo and t4.IddConjuDeter = t7.Idade and t7.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t8 on (t1.CdSexoConjug = t8.Sexo and t3.IddConjEvol = t8.Idade and t8.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada t9 on (t1.CdSexoPartic = t9.Sexo and t3.IddPartEvol = t9.Idade and t9.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada t10 on (t1.CdSexoPartic = t10.Sexo and t1.IddPartiCalc = t10.Idade and t10.t = 0)
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_ptc;

%macro calcular_fluxo_ptc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.ptc_deterministico_ativos);

		proc iml;
			load module= GetContribuicao;

			USE determin.ptc_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {lx} into px;
				read all var {ljx} into pjx;
				read all var {pxs} into pxs;
				read all var {apx} into apx;
				read all var {PrbCasado} into PrbCasado;
				read all var {BenLiqCobPtc} into BenLiqCobPtc;
				read all var {BenTotCobPtc} into BenTotCobPtc;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				beneficio_ptc = J(qtsObs, 1, 0);
				contribuicao_ptc = J(qtsObs, 1, 0);
				despesa_ptc = J(qtsObs, 1, 0);
				despesa_total_ptc = J(qtsObs, 1, 0);
				despesa_vp_ptc = J(qtsObs, 1, 0);
				pagamento_ptc = J(qtsObs, 1, 0);
				receita_total_ptc = J(qtsObs, 1, 0);

				DO a = 1 TO qtsObs;
					if (&CdPlanBen. = 1) then do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_ptc[a] = max(0, round(BenTotCobPtc[a] / &FtBenEnti., 0.01));
						end;
						else
							beneficio_ptc[a] = max(0, round(beneficio_ptc[a - 1] * (1 + &PrTxBenef.), 0.01));

						contribuicao_ptc[a] = max(0, round(GetContribuicao(beneficio_ptc[a]), 0.01));
						pagamento_ptc[a] = max(0, round((beneficio_ptc[a] - contribuicao_ptc[a]) * apx[a] * &NroBenAno. * PrbCasado[a], 0.01));
						despesa_total_ptc[a] = max(0, round(beneficio_ptc[a] * apx[a] * &NroBenAno. * (pjx[a] - px[a] * pjx[a]) * pxs[a] * PrbCasado[a], 0.01));
						receita_total_ptc[a] = max(0, round(contribuicao_ptc[a] * apx[a] * &NroBenAno. * (pjx[a] - px[a] * pjx[a]) * pxs[a] * PrbCasado[a], 0.01));
						despesa_ptc[a] = max(0, round(despesa_total_ptc[a] - receita_total_ptc[a], 0.01));
					end;
					else do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							pagamento_ptc[a] = max(0, round((BenLiqCobPtc[a] / &FtBenEnti.) * apx[a] * &NroBenAno. * PrbCasado[a], 0.01));
						end;
						else
							pagamento_ptc[a] = max(0, round(pagamento_ptc[a - 1] * (1 + &PrTxBenef.), 0.01));

						despesa_total_ptc[a] = max(0, round(pagamento_ptc[a] * (pjx[a] - px[a] * pjx[a]) * pxs[a], 0.01));
						despesa_ptc[a] = despesa_total_ptc[a];
					end;

					v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
					vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** t_vt));

					despesa_vp_ptc[a] = max(0, round(pagamento_ptc[a] * (pjx[a] - px[a] * pjx[a]) * vt[a] * pxs[a] * v[a] * &FtBenEnti., 0.01));

					t_vt = t_vt + 1;
				END;

				create work.ptc_deterministico_ativos var {id_participante tCobertura tDeterministico pagamento_ptc despesa_total_ptc receita_total_ptc despesa_ptc despesa_vp_ptc};
					append;
				close;
			end;
		quit;

		data determin.ptc_ativos&a.;
			merge determin.ptc_ativos&a. work.ptc_deterministico_ativos;
				by id_participante tCobertura tDeterministico;
			format pagamento_ptc commax14.2 despesa_ptc commax14.2 despesa_vp_ptc commax14.2 despesa_total_ptc commax14.2 receita_total_ptc commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.ptc_ativos);
	data determin.ptc_ativos;
		set determin.ptc_ativos1 - determin.ptc_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete ptc_ativos1 - ptc_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.ptc_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_ptc;

%_eg_conditional_dropds(determin.ptc_despesa_ativos);
proc summary data = determin.ptc_ativos;
 class tDeterministico;
 var despesa_ptc despesa_vp_ptc;
 output out=determin.ptc_despesa_ativos sum=;
run;

data determin.ptc_despesa_ativos;
	set determin.ptc_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.ptc_encargo_ativos);
proc summary data = determin.ptc_ativos;
 class id_participante;
 var despesa_vp_ptc;
 output out=determin.ptc_encargo_ativos sum=;
run;

data determin.ptc_encargo_ativos;
	set determin.ptc_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(work.despesa_ptc_alm)
proc sql;
	create table work.despesa_ptc_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_ptc) format=commax18.2 as despesa_ptc
	from determin.ptc_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

%_eg_conditional_dropds(determin.despesa_ptc_alm, WORK.despesa_ptc_alm_sorted);
PROC SORT
	DATA=WORK.despesa_ptc_alm(KEEP=despesa_ptc tDeterministico)
	OUT=WORK.despesa_ptc_alm_sorted;
	BY tDeterministico;
RUN;
PROC TRANSPOSE DATA=WORK.despesa_ptc_alm_sorted
	OUT=determin.despesa_ptc_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_ptc;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_ptc_alm_sorted, work.despesa_ptc_alm);

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
		   delete ptc_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
