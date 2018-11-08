*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

%macro obter_ativos_fluxo_aiv;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.aiv_ativos&a.);

		proc sql;
			create table determin.aiv_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					aiv.BenLiqCobAIV,
					aiv.BenTotCobAIV,
					t1.PrbCasado,
					max(0, (t5.lxii / t6.lxii)) format=12.8 as pxii,
					(case
						when aiv.AplicarPxsAIV = 0 then 1
						else max(0, (t9.lxs / t10.lxs))
					end) format=12.8 as pxs,
					max(0, ((t5.Nxiicb / t5.Dxiicb) - &Fb.)) format=12.8 AS axiicb,
					t9.ix format=12.8,
					t6.apxa format=12.8 as apx,
					(case
						when t4.tCobertura = t4.tDeterministico
							then max(0, ((snc.Nxcb / snc.Dxcb) - &Fb.))
							else 0
					end) format=12.8 AS ajxcb,
					(case
						when t4.tCobertura = t4.tDeterministico
						then max(0, ((n1.njxx / d1.djxx) - &Fb.))
						else 0
					end) format=12.8 AS ajxx_i,
					(case
						when t4.tCobertura = t4.tDeterministico
						then max(0, (t6.Mxii / t6.'Dxii*'n))
						else 0
					end) format=12.8 as Axii,
					txc.vl_taxa_juros as taxa_juros_cob,
					txd.vl_taxa_juros as taxa_juros_det
			from partic.ativos t1
			inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
			inner join determin.deterministico_ativos&a. t4 on (t1.id_participante = t4.id_participante and t3.t = t4.tCobertura)
			inner join work.taxa_juros txc on (txc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join work.taxa_juros txd on (txd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join cobertur.aiv_ativos aiv on (t1.id_participante = aiv.id_participante and t3.t = aiv.t)
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t4.IddPartiDeter = t5.Idade and t5.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t6 on (t1.CdSexoPartic = t6.Sexo and t3.IddPartEvol = t6.Idade and t6.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada t9 on (t1.CdSexoPartic = t9.Sexo and t3.IddPartEvol = t9.Idade and t9.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada t10 on (t1.CdSexoPartic = t10.Sexo and t1.IddPartiCalc = t10.Idade and t10.t = 0)
			inner join TABUAS.TABUAS_SERVICO_NORMAL snc on (t1.CdSexoConjug = snc.Sexo and t3.IddConjEvol = snc.Idade and snc.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join TABUAS.TABUAS_PENSAO_NJXX n1 on (t1.CdSexoPartic = n1.sexo AND t3.IddPartEvol = n1.idade_x AND t3.IddConjEvol = n1.idade_j AND n1.tipo = 2 and n1.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join TABUAS.TABUAS_PENSAO_DJXX d1 on (t1.CdSexoPartic = d1.sexo AND t3.IddPartEvol = d1.idade_x AND t3.IddConjEvol = d1.idade_j AND d1.tipo = 2 and d1.t = min(t4.tCobertura, &maxTaxaJuros))
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_aiv;

%macro calcular_fluxo_aiv;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.aiv_deterministico_ativos);

		proc iml;
			load module= GetContribuicao;

			USE determin.aiv_ativos&a.;
				read all var {id_participante } into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {pxii} into pxii;
				read all var {pxs} into pxs;
				read all var {ix} into ix;
				read all var {apx} into apxa;
				read all var {BenLiqCobAIV} into BenLiqCobAIV;
				read all var {BenTotCobAIV} into BenTotCobAIV;
				read all var {axiicb} into axiicb;
				read all var {PrbCasado} into PrbCasado;
				read all var {ajxcb} into ajxcb;
				read all var {ajxx_i} into ajxx_i;
				read all var {Axii} into Axii;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				beneficio_aiv = J(qtsObs, 1, 0);
				contribuicao_aiv = J(qtsObs, 1, 0);
				despesa_total_aiv = J(qtsObs, 1, 0);
				despesa_aiv = J(qtsObs, 1, 0);
				despesa_bua_aiv = J(qtsObs, 1, 0);
				despesa_vp_aiv = J(qtsObs, 1, 0);
				receita_total_aiv = J(qtsObs, 1, 0);
				pagamento_aiv = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				t_vt = 0;

				DO a = 1 TO qtsObs;
					if (&CdPlanBen. = 1) then do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_aiv[a] = max(0, round(BenTotCobAIV[a] / &FtBenEnti., 0.01));
						end;
						else
							beneficio_aiv[a] = max(0, round(beneficio_aiv[a - 1] * (1 + &PrTxBenef.), 0.01));

						contribuicao_aiv[a] = max(0, round(GetContribuicao(beneficio_aiv[a]), 0.01));
						pagamento_aiv[a] = max(0, round((beneficio_aiv[a] - contribuicao_aiv[a]) * (1 - apxa[a]) * ix[a] * &NroBenAno., 0.01));
						despesa_total_aiv[a] = max(0, round(beneficio_aiv[a] * (1 - apxa[a]) * &NroBenAno. * pxii[a] * pxs[a] * ix[a], 0.01));
						receita_total_aiv[a] = max(0, round(contribuicao_aiv[a] * (1 - apxa[a]) * &NroBenAno. * pxii[a] * pxs[a] * ix[a], 0.01));
						despesa_aiv[a] = max(0, round(despesa_total_aiv[a] - receita_total_aiv[a], 0.01));
					end;
					else do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							pagamento_aiv[a] = max(0, round((BenLiqCobAIV[a] / &FtBenEnti.) * (1 - apxa[a]) * ix[a] * &NroBenAno., 0.01));
							despesa_bua_aiv[a] = max(0, round(((BenTotCobAIV[a] * (axiicb[a] + &CtFamPens. * PrbCasado[a] * (ajxcb[a] - ajxx_i[a])) * &NroBenAno.) + ((BenTotCobAIV[a] / &FtBenEnti.) * (axii[a] * &peculioMorteAssistido.))) * (1 - apxa[a]) * ix[a] * &percentualSaqueBUA. * &percentualBUA., 0.01));
						end;
						else
							pagamento_aiv[a] = max(0, round(pagamento_aiv[a - 1] * (1 + &PrTxBenef.), 0.01));

						despesa_total_aiv[a] = max(0, round((pagamento_aiv[a] + despesa_bua_aiv[a]) * pxii[a] * pxs[a], 0.01));
						despesa_aiv[a] = despesa_total_aiv[a];
					end;

					v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
					vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** t_vt));

					if (tCobertura[a] = tDeterministico[a]) then
						despesa_vp_aiv[a] = max(0, round(((pagamento_aiv[a] * pxii[a] * vt[a] * &FtBenEnti.) - (&Fb. * pagamento_aiv[a] * &FtBenEnti.) + despesa_bua_aiv[a]) * pxs[a] * v[a], 0.01));
					else
						despesa_vp_aiv[a] = max(0, round(pagamento_aiv[a] * pxii[a] * vt[a] * pxs[a] * v[a] * &FtBenEnti., 0.01));

					t_vt = t_vt + 1;
				END;

				create work.aiv_deterministico_ativos var {id_participante tCobertura tDeterministico pagamento_aiv despesa_bua_aiv despesa_total_aiv receita_total_aiv despesa_aiv despesa_vp_aiv} ;
					append;
				close;
			end;
		quit;

		data determin.aiv_ativos&a.;
			merge determin.aiv_ativos&a. work.aiv_deterministico_ativos;
				by id_participante tCobertura tDeterministico;
			format pagamento_aiv commax14.2 despesa_bua_aiv commax14.2 despesa_aiv commax14.2 despesa_vp_aiv commax14.2 despesa_total_aiv commax14.2 receita_total_aiv commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.aiv_ativos);
	data determin.aiv_ativos;
		set determin.aiv_ativos1 - determin.aiv_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete aiv_ativos1 - aiv_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.aiv_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_aiv;

%_eg_conditional_dropds(determin.aiv_despesa_ativos);
proc summary data = determin.aiv_ativos;
 class tDeterministico;
 var despesa_aiv despesa_vp_aiv;
 output out=determin.aiv_despesa_ativos sum=;
run;

data determin.aiv_despesa_ativos;
	set determin.aiv_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.aiv_encargo_ativos);
proc summary data = determin.aiv_ativos;
 class id_participante;
 var despesa_vp_aiv;
 output out=determin.aiv_encargo_ativos sum=;
run;

data determin.aiv_encargo_ativos;
	set determin.aiv_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;


%_eg_conditional_dropds(work.despesa_aiv_alm, WORK.despesa_aiv_alm_sorted, determin.despesa_aiv_alm);
proc sql;
	create table work.despesa_aiv_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_aiv) format=commax18.2 as despesa_aiv
	from determin.aiv_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

PROC SORT
	DATA=WORK.despesa_aiv_alm(KEEP=despesa_aiv tDeterministico)
	OUT=WORK.despesa_aiv_alm_sorted;
	BY tDeterministico;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_aiv_alm_sorted
	OUT=determin.despesa_aiv_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_aiv;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_aiv_alm_sorted, work.despesa_aiv_alm);

%macro calcula_encargo_total_aiv_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%if (%sysfunc(exist(cobertur.ENCARGO_AIV_ALM))) %then %do;
			%_eg_conditional_dropds(work.ativos_aiv_bua cobertur.encargo_aiv_bua_alm)
			proc sql;
				create table work.ativos_aiv_bua as
				select d.tCobertura as t, sum(d.despesa_bua_aiv) format=commax14.2 as despesa_bua_aiv
				from determin.aiv_ativos d
				where d.tCobertura = d.tDeterministico
				group by d.tCobertura
				order by d.tCobertura;

				create table cobertur.ENCARGO_AIV_BUA_ALM as
				select c.t, (c.encargo_aiv + d.despesa_bua_aiv) format=commax18.2 as encargo_aiv
				from cobertur.ENCARGO_AIV_ALM c
				inner join work.ativos_aiv_bua d on (c.t = d.t)
				order by c.t;
			run;
		%end;
	%end;
%mend;
%calcula_encargo_total_aiv_alm;

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			delete aiv_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
