*-- CÁLCULO DETERMINISTICO DO BENEFÍCIO DE APOSENTADORIA POR TEMPO DE CONTRIBUIÇÃO (ATC) DOS PARTICIPANTES ATIVOS --*;

options noquotelenmax;

%macro obter_ativos_fluxo_atc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.atc_ativos&a.);

		proc sql;
			create table work.atc_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					atc.BenLiqCobAtc,
					atc.BenTotCobAtc,
					t1.PrbCasado,
					(case
						when t4.tCobertura = t4.tDeterministico
							then t3.VlSdoConPartEvol
							else 0
					end) format=commax14.2 as VlSdoConPartEvol,
					(case
						when t4.tCobertura = t4.tDeterministico
							then t3.VlSdoConPatrEvol
							else 0
					end) format=commax14.2 as VlSdoConPatrEvol,
					max(0, (t5.lx / t6.lx)) format=12.8 as px,
					(case
						when (&CdPlanBen. = 4 | &CdPlanBen. = 5)
							then 1
							else max(0, (t9.lxs / t10.lxs))
					end) format=12.8 as pxs,
					max(0, ((t5.Nxcb / t5.Dxcb) - &Fb)) format=12.8 AS axcb,
					(case
						when (t4.tCobertura = 0 or (&CdPlanBen. = 4 | &CdPlanBen. = 5))
							then t6.apxa
							else t6.apx
					end) format=12.8 as apx,
					(case
						when t4.tCobertura = t4.tDeterministico
							then max(0, ((snc.Nxcb / snc.Dxcb) - &Fb))
							else 0
					end) format=12.8 AS ajxcb,
					(case
						when t4.tCobertura = t4.tDeterministico
							then max(0, ((n1.njxx / d1.djxx) - &Fb))
							else 0
					end) format=12.8 AS ajxx,
					(case
						when t4.tCobertura = t4.tDeterministico
							then max(0, (t6.Mx / t6.'Dx*'n))
							else 0
					end) format=12.8 as Ax,
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
			inner join tabuas.tabuas_servico_ajustada t9 on (t1.CdSexoPartic = t9.Sexo and t3.IddPartEvol = t9.Idade and t9.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada t10 on (t1.CdSexoPartic = t10.Sexo and t1.IddPartiCalc = t10.Idade and t10.t = 0)
			inner join TABUAS.TABUAS_SERVICO_NORMAL snc on (t1.CdSexoConjug = snc.Sexo and t4.IddConjuDeter = snc.Idade and snc.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join TABUAS.TABUAS_PENSAO_NJXX n1 on (t1.CdSexoPartic = n1.sexo AND t3.IddPartEvol = n1.idade_x AND t3.IddConjEvol = n1.idade_j AND n1.tipo = 1 and n1.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join TABUAS.TABUAS_PENSAO_DJXX d1 on (t1.CdSexoPartic = d1.sexo AND t3.IddPartEvol = d1.idade_x AND t3.IddConjEvol = d1.idade_j AND d1.tipo = 1 and d1.t = min(t4.tCobertura, &maxTaxaJuros))
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_atc;

%macro calcular_fluxo_atc;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.atc_deterministico_ativos);

		proc iml;
			load module= GetContribuicao;

			USE work.atc_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {BenLiqCobAtc} into BenLiqCobAtc;
				read all var {BenTotCobAtc} into BenTotCobAtc;
				read all var {VlSdoConPartEvol} into VlSdoConPartEvol;
				read all var {VlSdoConPatrEvol} into VlSdoConPatrEvol;
				read all var {PrbCasado} into PrbCasado;
				read all var {axcb} into axcb;
				read all var {px} into px;
				read all var {pxs} into pxs;
				read all var {apx} into apx;
				read all var {ajxcb} into ajxcb;
				read all var {ajxx} into ajxx;
				read all var {Ax} into ax;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				pagamento_atc = J(qtsObs, 1, 0);
				beneficio_atc = J(qtsObs, 1, 0);
				contribuicao_atc = J(qtsObs, 1, 0);
				despesa_total_atc = J(qtsObs, 1, 0);
				despesa_atc = J(qtsObs, 1, 0);
				despesa_bua_atc = J(qtsObs, 1, 0);
				despesa_vp_atc = J(qtsObs, 1, 0);
				receita_total_atc = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				t_vt = 0;

				DO a = 1 TO qtsObs;
					if (&CdPlanBen. = 1) then do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_atc[a] = max(0, round(BenTotCobAtc[a] / &FtBenEnti., 0.01));
						end;
						else
							beneficio_atc[a] = max(0, round(beneficio_atc[a - 1] * (1 + &PrTxBenef.), 0.01));

						contribuicao_atc[a] = max(0, round(GetContribuicao(beneficio_atc[a]), 0.01));
						pagamento_atc[a] = max(0, round((beneficio_atc[a] - contribuicao_atc[a]) * apx[a] * &NroBenAno., 0.01));
						despesa_total_atc[a] = max(0, round(beneficio_atc[a] * apx[a] * &NroBenAno. * px[a] * pxs[a], 0.01));
						receita_total_atc[a] = max(0, round(contribuicao_atc[a] * apx[a] * &NroBenAno. * px[a] * pxs[a], 0.01));
						despesa_atc[a] = max(0, round(despesa_total_atc[a] - receita_total_atc[a], 0.01));
					end;
					else do;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							pagamento_atc[a] = max(0, round((BenLiqCobAtc[a] / &FtBenEnti.) * apx[a] * &NroBenAno., 0.01));

							if (&CdPlanBen. = 2) then
								despesa_bua_atc[a] = max(0, round(((BenTotCobAtc[a] * (axcb[a] + &CtFamPens. * PrbCasado[a] * (ajxcb[a] - ajxx[a])) * &NroBenAno.) + ((BenTotCobAtc[a] / &FtBenEnti.) * (ax[a] * &peculioMorteAssistido.))) * apx[a] * &percentualSaqueBUA. * &percentualBUA., 0.01));
							else
								despesa_bua_atc[a] = max(0, round((VlSdoConPartEvol[a] + VlSdoConPatrEvol[a]) * apx[a] * &percentualSaqueBUA. * &percentualBUA., 0.01));
						end;
						else
							pagamento_atc[a] = max(0, round(pagamento_atc[a - 1] * (1 + &PrTxBenef.), 0.01));

						despesa_total_atc[a] = max(0, round((pagamento_atc[a] + despesa_bua_atc[a]) * px[a] * pxs[a], 0.01));
						despesa_atc[a] = despesa_total_atc[a];
					end;

					v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
					vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** t_vt));

					if (tCobertura[a] = tDeterministico[a]) then
						despesa_vp_atc[a] = max(0, round(((pagamento_atc[a] * px[a] * vt[a] * &FtBenEnti.) - (&Fb. * pagamento_atc[a] * &FtBenEnti.)) * pxs[a] * v[a] + despesa_bua_atc[a] * v[a] * pxs[a], 0.01));
					else
						despesa_vp_atc[a] = max(0, round(pagamento_atc[a] * px[a] * vt[a] * pxs[a] * v[a] * &FtBenEnti., 0.01));

					t_vt = t_vt + 1;
				END;

				create work.atc_deterministico_ativos var {id_participante tCobertura tDeterministico pagamento_atc despesa_bua_atc despesa_total_atc receita_total_atc despesa_atc despesa_vp_atc};
					append;
				close;
			end;
		quit;

		data work.atc_ativos&a.;
			merge work.atc_ativos&a. work.atc_deterministico_ativos;
				by id_participante tCobertura tDeterministico;
			format pagamento_atc commax14.2 despesa_bua_atc commax14.2 despesa_atc commax14.2 despesa_vp_atc commax14.2 despesa_total_atc commax14.2 receita_total_atc commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.atc_ativos);
	data determin.atc_ativos;
		set work.atc_ativos1 - work.atc_ativos&numberOfBlocksAtivos.;
	run;

	proc datasets nodetails library=determin;
	   delete atc_ativos1 - atc_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.atc_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_atc;

%_eg_conditional_dropds(determin.atc_despesa_ativos);
proc summary data = determin.atc_ativos;
 class tDeterministico;
 var despesa_atc despesa_vp_atc;
 output out=determin.atc_despesa_ativos sum=;
run;

data determin.atc_despesa_ativos;
	set determin.atc_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.atc_encargo_ativos);
proc summary data = determin.atc_ativos;
 class id_participante;
 var despesa_vp_atc;
 output out=determin.atc_encargo_ativos sum=;
run;

data determin.atc_encargo_ativos;
	set determin.atc_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(work.despesa_atc_alm)
proc sql;
	create table work.despesa_atc_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_atc) format=commax18.2 as despesa_atc
	from determin.atc_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

%_eg_conditional_dropds(determin.despesa_atc_alm, WORK.despesa_atc_alm_sorted);
PROC SORT
	DATA=WORK.despesa_atc_alm(KEEP=despesa_atc tDeterministico)
	OUT=WORK.despesa_atc_alm_sorted;
	BY tDeterministico;
RUN;
PROC TRANSPOSE DATA=WORK.despesa_atc_alm_sorted
	OUT=determin.despesa_atc_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_atc;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_atc_alm_sorted, work.despesa_atc_alm);

%macro calcular_encargo_atc_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%if (%sysfunc(exist(cobertur.encargo_atc_alm))) %then %do;
			%_eg_conditional_dropds(work.ativos_atc_bua cobertur.encargo_atc_bua_alm)
			proc sql;
				create table work.ativos_atc_bua as
				select d.tCobertura as t, sum(d.despesa_bua_atc) format=commax14.2 as despesa_bua_atc
				from determin.atc_ativos d
				where d.tCobertura = d.tDeterministico
				group by d.tCobertura
				order by d.tCobertura;

				create table cobertur.encargo_atc_bua_alm as
				select c.t, (c.encargo_atc + d.despesa_bua_atc) format=commax18.2 as encargo_atc
				from cobertur.encargo_atc_alm c
				inner join work.ativos_atc_bua d on (c.t = d.t)
				order by c.t;
			run;
		%end;
	%end;
%mend;
%calcular_encargo_atc_alm;

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo. = 0) %then %do;
		proc delete data = determin.atc_ativos (gennum=all);
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
