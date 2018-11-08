*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

%macro obter_ativos_fluxo_piv;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.piv_ativos&a.);

		proc sql;
			create table determin.piv_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					t1.PrbCasado,
					piv.BenTotCobPIV,
					piv.BenLiqCobPIV,
					max(0, (t5.lxii / t6.lxii)) format=12.8 as pxii,
					max(0, (t7.lx / t8.lx)) format=12.8 as pjx,
					(case
						when piv.AplicarPxsPIV = 0
							then 1
							else max(0, (t9.lxs / t10.lxs))
						end) format=12.8 as pxs,
					t9.ix format=12.8,
					t6.apxa format=12.8 as apx,
					txc.vl_taxa_juros as taxa_juros_cob,
					txd.vl_taxa_juros as taxa_juros_det
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
			inner join determin.deterministico_ativos&a. t4 on (t1.id_participante = t4.id_participante and t3.t = t4.tCobertura)
			inner join work.taxa_juros txc on (txc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join work.taxa_juros txd on (txd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join cobertur.piv_ativos piv on (t1.id_participante = piv.id_participante and t3.t = piv.t)
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
%obter_ativos_fluxo_piv;

%macro calcular_fluxo_piv;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.piv_deterministico_ativos);

		proc iml;
			load module= GetContribuicao;

			USE determin.piv_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {BenTotCobPIV} into BenTotCobPiv;
				read all var {BenLiqCobPIV} into BenLiqCobPiv;
				read all var {PrbCasado} into PrbCasado;
				read all var {pxii} into pxii;
				read all var {pjx} into pjx;
				read all var {pxs} into pxs;
				read all var {ix} into ix;
				read all var {apx} into apxa;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				beneficio_piv = J(qtsObs, 1, 0);
				contribuicao_piv = J(qtsObs, 1, 0);
				despesa_piv = J(qtsObs, 1, 0);
				despesa_total_piv = J(qtsObs, 1, 0);
				despesa_vp_piv = J(qtsObs, 1, 0);
				pagamento_piv = J(qtsObs, 1, 0);
				receita_total_piv = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);

				DO a = 1 TO qtsObs;
					if (&CdPlanBen. = 1) then do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_piv[a] = max(0, round(BenTotCobPiv[a] / &FtBenEnti., 0.01));
						end;
						else
							beneficio_piv[a] = max(0, round(beneficio_piv[a - 1] * (1 + &PrTxBenef.), 0.01));

						contribuicao_piv[a] = max(0, round(GetContribuicao(beneficio_piv[a]), 0.01));
						pagamento_piv[a] = max(0, round((beneficio_piv[a] - contribuicao_piv[a]) * (1 - apxa[a]) * ix[a] * &NroBenAno. * PrbCasado[a], 0.01));
						despesa_total_piv[a] = max(0, round(beneficio_piv[a] * (1 - apxa[a]) * &NroBenAno. * (pjx[a] - pxii[a] * pjx[a]) * pxs[a] * ix[a] * PrbCasado[a], 0.01));
						receita_total_piv[a] = max(0, round(contribuicao_piv[a] * (1 - apxa[a]) * &NroBenAno. * (pjx[a] - pxii[a] * pjx[a]) * pxs[a] * ix[a] * PrbCasado[a], 0.01));
						despesa_piv[a] = max(0, round(despesa_total_piv[a] - receita_total_piv[a], 0.01));
					end;
					else do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							pagamento_piv[a] = max(0, round((BenLiqCobPiv[a] / &FtBenEnti.) * (1 - apxa[a]) * ix[a] * &NroBenAno. * PrbCasado[a], 0.01));
						end;
						else
							pagamento_piv[a] = max(0, round(pagamento_piv[a - 1] * (1 + &PrTxBenef.), 0.01));

						despesa_total_piv[a] = max(0, round(pagamento_piv[a] * (pjx[a] - pxii[a] * pjx[a]) * pxs[a], 0.01));
						despesa_piv[a] = despesa_total_piv[a];
					end;

					v[a] = 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]);
					vt[a] = 1 / ((1 + taxa_juros_det[a]) ** t_vt);

					despesa_vp_piv[a] = max(0, round(pagamento_piv[a] * &FtBenEnti. * (pjx[a] - pxii[a] * pjx[a]) * vt[a] * pxs[a] * v[a], 0.01));

					t_vt = t_vt + 1;
				END;

				create work.piv_deterministico_ativos var {id_participante tCobertura tDeterministico pagamento_piv despesa_total_piv receita_total_piv despesa_piv despesa_vp_piv};
					append;
				close;
			end;
		quit;

		data determin.piv_ativos&a.;
			merge determin.piv_ativos&a. work.piv_deterministico_ativos;
			by id_participante tCobertura tDeterministico;
			format pagamento_piv commax14.2 despesa_piv commax14.2 despesa_vp_piv commax14.2 despesa_total_piv commax14.2 receita_total_piv commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.piv_ativos);
	data determin.piv_ativos;
		set determin.piv_ativos1 - determin.piv_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete piv_ativos1 - piv_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.piv_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_piv;

%_eg_conditional_dropds(determin.piv_despesa_ativos);
proc summary data = determin.piv_ativos;
 class tDeterministico;
 var despesa_piv despesa_vp_piv;
 output out=determin.piv_despesa_ativos sum=;
run;

data determin.piv_despesa_ativos;
	set determin.piv_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.piv_encargo_ativos);
proc summary data = determin.piv_ativos;
 class id_participante;
 var despesa_vp_piv;
 output out=determin.piv_encargo_ativos sum=;
run;

data determin.piv_encargo_ativos;
	set determin.piv_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;


%_eg_conditional_dropds(work.despesa_piv_alm, WORK.despesa_piv_alm_sorted, determin.despesa_piv_alm);
proc sql;
	create table work.despesa_piv_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_piv) format=commax18.2 as despesa_piv
	from determin.piv_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

PROC SORT
	DATA=WORK.despesa_piv_alm(KEEP=despesa_piv tDeterministico)
	OUT=WORK.despesa_piv_alm_sorted;
	BY tDeterministico;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_piv_alm_sorted
	OUT=determin.despesa_piv_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_piv;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_piv_alm_sorted, work.despesa_piv_alm);


%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			delete piv_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
