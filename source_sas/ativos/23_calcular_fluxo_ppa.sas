*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

%macro obter_ativos_fluxo_ppa;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.ppa_ativos&a.);

		proc sql;
			create table determin.ppa_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					t1.PrbCasado,
					ppa.BenLiqCobPPA,
					ppa.BenTotCobPPA,
					max(0, (t7.lx / t8.lx)) format=12.8 as pjx,
					(case
						when ppa.AplicarPxsPPA = 0 then 1
						else max(0, (ajco.lxs / ajca.lxs))
					end) format=12.8 as pxs,
					max(0, ((t7.Nxcb / t7.Dxcb) - &Fb)) format=12.8 AS ajxcb,
					ajco.qx,
					t6.apxa format=10.6 as apx,
					txc.vl_taxa_juros as taxa_juros_cob,
					txd.vl_taxa_juros as taxa_juros_det
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
			inner join determin.deterministico_ativos&a. t4 on (t1.id_participante = t4.id_participante and t3.t = t4.tCobertura)
			inner join work.taxa_juros txc on (txc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join work.taxa_juros txd on (txd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join cobertur.ppa_ativos ppa on (t1.id_participante = ppa.id_participante and t3.t = ppa.t)
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t4.IddPartiDeter = t5.Idade and t5.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t6 on (t1.CdSexoPartic = t6.Sexo and t3.IddPartEvol = t6.Idade and t6.t = min(t3.t, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t7 on (t1.CdSexoConjug = t7.Sexo and t4.IddConjuDeter = t7.Idade and t7.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t8 on (t1.CdSexoConjug = t8.Sexo and t3.IddConjEvol = t8.Idade and t8.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajco on (t1.CdSexoPartic = ajco.Sexo and t3.IddPartEvol = ajco.Idade and ajco.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajca on (t1.CdSexoPartic = ajca.Sexo and t1.IddPartiCalc = ajca.Idade and ajca.t = 0)
			inner join tabuas.tabuas_servico_ajustada ajde on (t1.CdSexoPartic = ajde.Sexo and t4.IddPartiDeter = ajde.Idade and ajde.t = min(t4.tDeterministico, &maxTaxaJuros))
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_ppa;

%macro calcular_fluxo_ppa;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.ppa_deterministico_ativos);

		proc iml;
			load module= GetContribuicao;

			USE determin.ppa_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {pjx} into pjx;
				read all var {pxs} into pxs;
				read all var {qx} into qx;
				read all var {apx} into apxa;
				read all var {PrbCasado} into PrbCasado;
				read all var {BenLiqCobPPA} into BenLiqCobPpa;
				read all var {BenTotCobPPA} into BenTotCobPpa;
				read all var {ajxcb} into ajxcb;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;

				beneficio_ppa = J(qtsObs, 1, 0);
				contribuicao_ppa = J(qtsObs, 1, 0);
				despesa_ppa = J(qtsObs, 1, 0);
				despesa_bua_ppa = J(qtsObs, 1, 0);
				despesa_total_ppa = J(qtsObs, 1, 0);
				despesa_vp_ppa = J(qtsObs, 1, 0);
				pagamento_ppa = J(qtsObs, 1, 0);
				receita_total_ppa = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				t_vt = 0;

				DO a = 1 TO qtsObs;
					if (&CdPlanBen. = 1) then do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_ppa[a] = max(0, round(BenTotCobPpa[a] / &FtBenEnti., 0.01));
						end;
						else
							beneficio_ppa[a] = max(0, round(beneficio_ppa[a - 1] * (1 + &PrTxBenef.), 0.01));

						contribuicao_ppa[a] = max(0, round(GetContribuicao(beneficio_ppa[a]), 0.01));
						pagamento_ppa[a] = max(0, round((beneficio_ppa[a] - contribuicao_ppa[a]) * (1 - apxa[a]) * qx[a] * &NroBenAno. * PrbCasado[a], 0.01));
						despesa_total_ppa[a] = max(0, round(beneficio_ppa[a] * (1 - apxa[a]) * &NroBenAno. * pjx[a] * pxs[a] * qx[a] * PrbCasado[a], 0.01));
						receita_total_ppa[a] = max(0, round(contribuicao_ppa[a] * (1 - apxa[a]) * &NroBenAno. * pjx[a] * pxs[a] * qx[a] * PrbCasado[a], 0.01));
						despesa_ppa[a] = max(0, round(despesa_total_ppa[a] - receita_total_ppa[a], 0.01));
					end;
					else do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							pagamento_ppa[a] = max(0, round((BenLiqCobPpa[a] / &FtBenEnti.) * (1 - apxa[a]) * qx[a] * &NroBenAno. * PrbCasado[a], 0.01));
							despesa_bua_ppa[a] = max(0, round((BenTotCobPpa[a] * ajxcb[a] * &NroBenAno.) * qx[a] * (1 - apxa[a]) * PrbCasado[a] * &percentualSaqueBUA. * &percentualBUA., 0.01));
						end;
						else
							pagamento_ppa[a] = max(0, round(pagamento_ppa[a - 1] * (1 + &PrTxBenef.), 0.01));

						despesa_total_ppa[a] = max(0, round((pagamento_ppa[a] + despesa_bua_ppa[a]) * pjx[a] * pxs[a], 0.01));
						despesa_ppa[a] = despesa_total_ppa[a];
					end;

					v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
					vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** t_vt));

					if (tCobertura[a] = tDeterministico[a]) then
						despesa_vp_ppa[a] = max(0 , round(((pagamento_ppa[a] * pjx[a] * vt[a] * &FtBenEnti.) - (&Fb. * pagamento_ppa[a] * &FtBenEnti.) + despesa_bua_ppa[a]) * pxs[a] * v[a], 0.01));
					else
						despesa_vp_ppa[a] = max(0 , round(pagamento_ppa[a] * &FtBenEnti. * pjx[a] * vt[a] * pxs[a] * v[a], 0.01));

					t_vt = t_vt + 1;
				END;

				create work.ppa_deterministico_ativos var {id_participante tCobertura tDeterministico pagamento_ppa despesa_bua_ppa despesa_total_ppa receita_total_ppa despesa_ppa despesa_vp_ppa};
					append;
				close;
			end;
		quit;

		data determin.ppa_ativos&a.;
			merge determin.ppa_ativos&a. work.ppa_deterministico_ativos;
			by id_participante tCobertura tDeterministico;
			format pagamento_ppa COMMAX14.2 despesa_bua_ppa COMMAX14.2 despesa_ppa COMMAX14.2 despesa_vp_ppa COMMAX14.2 despesa_total_ppa COMMAX14.2 receita_total_ppa COMMAX14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.ppa_ativos);
	data determin.ppa_ativos;
		set determin.ppa_ativos1 - determin.ppa_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete ppa_ativos1 - ppa_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.ppa_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_ppa;


%_eg_conditional_dropds(determin.ppa_despesa_ativos);
proc summary data = determin.ppa_ativos;
 class tDeterministico;
 var despesa_ppa despesa_vp_ppa;
 output out=determin.ppa_despesa_ativos sum=;
run;

data determin.ppa_despesa_ativos;
	set determin.ppa_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.ppa_encargo_ativos);
proc summary data = determin.ppa_ativos;
 class id_participante;
 var despesa_vp_ppa;
 output out=determin.ppa_encargo_ativos sum=;
run;

data determin.ppa_encargo_ativos;
	set determin.ppa_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;


%_eg_conditional_dropds(work.despesa_ppa_alm, WORK.despesa_ppa_alm_sorted, determin.despesa_ppa_alm);
proc sql;
	create table work.despesa_ppa_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_ppa) format=commax18.2 as despesa_ppa
	from determin.ppa_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

PROC SORT
	DATA=WORK.despesa_ppa_alm(KEEP=despesa_ppa tDeterministico)
	OUT=WORK.despesa_ppa_alm_sorted;
	BY tDeterministico;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_ppa_alm_sorted
	OUT=determin.despesa_ppa_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_ppa;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_ppa_alm_sorted, work.despesa_ppa_alm);

%macro calcula_encargo_total_ppa_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%if (%sysfunc(exist(cobertur.ENCARGO_PPA_ALM))) %then %do;
			%_eg_conditional_dropds(work.ativos_ppa_bua cobertur.encargo_ppa_bua_alm)
			proc sql;
				create table work.ativos_ppa_bua as
				select d.tCobertura as t, sum(d.despesa_bua_ppa) format=commax14.2 as despesa_bua_ppa
				from determin.ppa_ativos d
				where d.tCobertura = d.tDeterministico
				group by d.tCobertura
				order by d.tCobertura;

				create table cobertur.encargo_ppa_bua_alm as
				select c.t, (c.encargo_ppa + d.despesa_bua_ppa) format=commax18.2 as encargo_ppa
				from cobertur.ENCARGO_PPA_ALM c
				inner join work.ativos_ppa_bua d on (c.t = d.t)
				order by c.t;
			run;
		%end;
	%end;
%mend;
%calcula_encargo_total_ppa_alm;

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			delete ppa_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
