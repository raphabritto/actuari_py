
%macro obter_ativos_fluxo_pmi;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.pmi_ativos&a.);

		proc sql;
			create table determin.pmi_ativos&a. as
			select t1.id_participante,
					t4.tCobertura,
					t4.tDeterministico,
					aiv.BenLiqCobAIV,
					t1.flg_manutencao_saldo,
					t3.IddPartEvol,
					t1.IddIniApoInss,
					t5.dxii,
					ajco.ix,
					t6.apxa format=12.8 as apx,
					t6.lxii,
					(case
						when (aiv.AplicarPxsAIV = 0)
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
			inner join cobertur.aiv_ativos aiv on (t1.id_participante = aiv.id_participante and t3.t = aiv.t)
			inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t4.IddPartiDeter = t5.Idade and t5.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_normal t6 on (t1.CdSexoPartic = t6.Sexo and t3.IddPartEvol = t6.Idade and t6.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajcd on (t1.CdSexoPartic = ajcd.Sexo and t4.IddPartiDeter = ajcd.Idade and ajcd.t = min(t4.tDeterministico, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajco on (t1.CdSexoPartic = ajco.Sexo and t3.IddPartEvol = ajco.Idade and ajco.t = min(t4.tCobertura, &maxTaxaJuros))
			inner join tabuas.tabuas_servico_ajustada ajca on (t1.CdSexoPartic = ajca.Sexo and t1.IddPartiCalc = ajca.Idade and ajca.t = 0)
			order by t1.id_participante, t3.t, t4.tDeterministico;
		quit;
	%end;
%mend;
%obter_ativos_fluxo_pmi;

%macro calcular_fluxo_pmi;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.ativos_resultado_pmi);

		proc iml;
			USE determin.pmi_ativos&a.;
				read all var {id_participante} into id_participante;
				read all var {tCobertura} into tCobertura;
				read all var {tDeterministico} into tDeterministico;
				read all var {BenLiqCobAIV} into BenLiqCobAiv;
				read all var {dxii} into dxii;
				read all var {ix} into ix;
				read all var {apx} into apx;
				read all var {flg_manutencao_saldo} into flg_manutencao_saldo;
				read all var {IddPartEvol} into IddPartEvol;
				read all var {IddIniApoInss} into IddIniApoInss;
				read all var {lxii} into lxii;
				read all var {pxs} into pxs;
				read all var {taxa_juros_cob} into taxa_juros_cob;
				read all var {taxa_juros_det} into taxa_juros_det;
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				beneficio_pmi = J(qtsObs, 1, 0);
				despesa_pmi = J(qtsObs, 1, 0);
				despesa_vp_pmi = J(qtsObs, 1, 0);
				pagamento_pmi = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);
				vt = J(qtsObs, 1, 0);
				vt_dxii = J(qtsObs, 1, 0);

				if (&CdPlanBen. ^= 1) then do;
					DO a = 1 TO qtsObs;
						if (tCobertura[a] = tDeterministico[a]) then do;
							t_vt = 0;
							beneficio_pmi[a] = max(0, round((BenLiqCobAiv[a] / &FtBenEnti.) * &peculioMorteAssistido., 0.01));

							if (flg_manutencao_saldo[a] = 0 & beneficio_pmi[a] > 0) then
								beneficio_pmi[a] = max(beneficio_pmi[a], &LimPecMin.);

/*							pagamento_pmi[a] = max(0, round(beneficio_pmi[a] * ix[a] * (1 - apx[a]), 0.01));*/
						end;
						else
							beneficio_pmi[a] = beneficio_pmi[a - 1];

						pagamento_pmi[a] = max(0, round(beneficio_pmi[a] * ix[a] * (1 - apx[a]), 0.01));

						vt[a] = max(0, 1 / ((1 + taxa_juros_det[a]) ** (t_vt + 1)));
						vt_dxii[a] = max(0, vt[a] * dxii[a]);

						if (lxii[a] > 0) then
							despesa_pmi[a] = max(0, round(pagamento_pmi[a] * vt_dxii[a] / lxii[a], 0.01));

						v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));
						despesa_vp_pmi[a] = max(0, round(despesa_pmi[a] * pxs[a] * v[a], 0.01));

						t_vt = t_vt + 1;
					END;
				end;

				create work.ativos_resultado_pmi var {id_participante tCobertura tDeterministico beneficio_pmi pagamento_pmi despesa_pmi despesa_vp_pmi};
					append;
				close;
			end;
		quit;

		data determin.pmi_ativos&a.;
			merge determin.pmi_ativos&a. work.ativos_resultado_pmi;
				by id_participante tCobertura tDeterministico;
			format beneficio_pmi commax14.2 pagamento_pmi commax14.2 despesa_pmi commax14.2 despesa_vp_pmi commax14.2;
		run;
	%end;

	%_eg_conditional_dropds(determin.pmi_ativos);
	data determin.pmi_ativos;
		set determin.pmi_ativos1 - determin.pmi_ativos&numberOfBlocksAtivos.;
	run;

	proc delete data = work.ativos_resultado_pmi (gennum=all);
	run;

	proc datasets nodetails library=determin;
	   delete pmi_ativos1 - pmi_ativos&numberOfBlocksAtivos.;
	run;
%mend;
%calcular_fluxo_pmi;

/*proc datasets nodetails library=determin;*/
/*   delete pmi_ativos1 - pmi_ativos&numberOfBlocksAtivos;*/
/*run;*/

%_eg_conditional_dropds(determin.pmi_despesa_ativos);
proc summary data = determin.pmi_ativos;
 class tDeterministico;
 var despesa_pmi despesa_vp_pmi;
 output out=determin.pmi_despesa_ativos sum=;
run;

data determin.pmi_despesa_ativos;
	set determin.pmi_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;

%_eg_conditional_dropds(determin.pmi_encargo_ativos);
proc summary data = determin.pmi_ativos;
 class id_participante;
 var despesa_vp_pmi;
 output out=determin.pmi_encargo_ativos sum=;
run;

data determin.pmi_encargo_ativos;
	set determin.pmi_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;


%_eg_conditional_dropds(work.despesa_pmi_alm, WORK.despesa_pmi_alm_sorted, determin.despesa_pmi_alm);
proc sql;
	create table work.despesa_pmi_alm as
	select t1.tCobertura, t1.tDeterministico, sum(despesa_pmi) format=commax18.2 as despesa_pmi
	from determin.pmi_ativos t1
	group by t1.tDeterministico, t1.tCobertura
	order by t1.tCobertura, t1.tDeterministico;
run;

PROC SORT
	DATA=WORK.despesa_pmi_alm(KEEP=despesa_pmi tDeterministico)
	OUT=WORK.despesa_pmi_alm_sorted;
	BY tDeterministico;
RUN;

PROC TRANSPOSE DATA=WORK.despesa_pmi_alm_sorted
	OUT=determin.despesa_pmi_alm(drop = Source rename= tDeterministico = t)
	PREFIX=Column
	NAME=Source
	LABEL=Label;
	BY tDeterministico;
	VAR despesa_pmi;
RUN; QUIT;
%_eg_conditional_dropds(WORK.despesa_pmi_alm_sorted, work.despesa_pmi_alm);


%macro calcula_encargo_pmi_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%_eg_conditional_dropds(work.encargo_pmi_alm);
		proc sql;
			create table work.encargo_pmi_alm as
			select c.id_participante,
				   c.t,
				   max(0, ((c.BenLiqCobAIV / &FtBenEnti.) * (1 - c.apx) * c.ix * c.axii * &peculioMorteAssistido.)) format=commax14.2 as encargo_pmi
			from cobertur.aiv_ativos c
			order by c.id_participante, c.t;
		run;

		%_eg_conditional_dropds(cobertur.encargo_pmi_alm);
		proc sql;
			create table cobertur.encargo_pmi_alm as
			select e.t,
				   max(0, sum(e.encargo_pmi)) format=commax18.2 as encargo_pmi
			from work.encargo_pmi_alm e
			group by e.t
			order by e.t;
		run;
	%end;
%mend;
%calcula_encargo_pmi_alm;

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			delete pmi_ativos1 - pmi_ativos&numberOfBlocksAtivos.;
			*delete pmi_ativos;
			*delete pmi_encargo_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
