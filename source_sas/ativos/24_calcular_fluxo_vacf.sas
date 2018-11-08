
%_eg_conditional_dropds(determin.vacf_ativos);
proc sql;
	create table determin.vacf_ativos as
	select t1.id_participante,
			t3.t as tCobertura,
			t3.ConParSdoEvol,
			t3.ConPatSdoEvol,
			t3.SalConPrjEvol,
			max(0, (t10.lxs / t12.lxs)) format=12.8 as pxs,
			max(0, (t10.dxs / t12.dxs)) format=12.8 as dxs,
			t5.apxa format=12.8 as apx,
			t1.id_bloco,
			txc.vl_taxa_juros as taxa_juros_cob,
			(case
				when txrp1.vl_taxa_risco is null
					then 0
					else txrp1.vl_taxa_risco
			end) format=10.6 as vl_taxa_risco_partic,
			(case
				when txrp2.vl_taxa_risco is null
					then 0
					else txrp2.vl_taxa_risco
			end) format=10.6 as vl_taxa_risco_patroc
	from partic.ativos t1
	inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
	inner join work.taxa_juros txc on (txc.t = min(t3.t, &maxTaxaJuros))
	left join work.taxa_risco txrp1 on (txrp1.t = min(t3.t, &maxTaxaRiscoPartic) and txrp1.id_responsabilidade = 1)
	left join work.taxa_risco txrp2 on (txrp2.t = min(t3.t, &maxTaxaRiscoPatroc) and txrp2.id_responsabilidade = 2)
	inner join tabuas.tabuas_servico_normal t5 on (t1.CdSexoPartic = t5.Sexo and t3.IddPartEvol = t5.Idade and t5.t = min(t3.t, &maxTaxaJuros))
	inner join tabuas.tabuas_servico_ajustada t10 on (t1.CdSexoPartic = t10.Sexo and t3.IddPartEvol = t10.Idade and t10.t = min(t3.t, &maxTaxaJuros))
	inner join tabuas.tabuas_servico_ajustada t12 on (t1.CdSexoPartic = t12.Sexo and t1.IddPartiCalc = t12.Idade and t12.t = 0)
	order by t1.id_participante, t3.t;
quit;

%macro calcular_fluxo_vacf;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.vacf_deterministico_ativos);

		proc iml;
			USE determin.vacf_ativos;
				read all var {id_participante} into id_participante where(id_bloco = &a.);
				read all var {tCobertura} into tCobertura where(id_bloco = &a.);
				read all var {pxs} into pxs where(id_bloco = &a.);
				read all var {apx} into apx where(id_bloco = &a.);
				read all var {dxs} into dxs where(id_bloco = &a.);
				read all var {SalConPrjEvol} into SalConPrjEvol where(id_bloco = &a.);
				read all var {ConParSdoEvol} into ConParSdoEvol where(id_bloco = &a.);
				read all var {ConPatSdoEvol} into ConPatSdoEvol where(id_bloco = &a.);
				read all var {taxa_juros_cob} into taxa_juros_cob where(id_bloco = &a.);
				read all var {vl_taxa_risco_partic} into taxa_risco_partic where(id_bloco = &a.);
				read all var {vl_taxa_risco_patroc} into taxa_risco_patroc where(id_bloco = &a.);
			CLOSE;

			qtsObs = nrow(id_participante);

			if (qtsObs > 0) then do;
				receita_prog_partic = J(qtsObs, 1, 0);
				receita_risco_partic = J(qtsObs, 1, 0);
				receita_prog_patroc = J(qtsObs, 1, 0);
				receita_risco_patroc = J(qtsObs, 1, 0);
				vacf_prog_partic = J(qtsObs, 1, 0);
				vacf_risco_partic = J(qtsObs, 1, 0);
				vacf_prog_patroc = J(qtsObs, 1, 0);
				vacf_risco_patroc = J(qtsObs, 1, 0);
				v = J(qtsObs, 1, 0);

				DO a = 1 TO qtsObs;
					v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** tCobertura[a]));

					if (&CdPlanBen. = 1) then do;
						receita_prog_partic[a] = max(0, round(ConParSdoEvol[a] * (1 - &TxCarregamentoAdm.), 0.01));
						vacf_prog_partic[a] = max(0, round(receita_prog_partic[a] * v[a] * &FtSalPart., 0.01));
						receita_prog_patroc[a] = receita_prog_partic[a];
						vacf_prog_patroc[a] = vacf_prog_partic[a];
					end;
					else if (&CdPlanBen. = 4 | &CdPlanBen. = 5) then do;
						receita_prog_partic[a] = max(0, ConParSdoEvol[a]);

						if (&CdPlanBen. = 4) then do;
							/*if (ConParSdoEvol > 0) then*/
							receita_risco_partic[a] = max(0, round((SalConPrjEvol[a] / &FtSalPart.) * taxa_risco_partic[a] * &NroBenAno. * (1 - apx[a]) * pxs[a], 0.01));
						end;

						vacf_prog_partic[a] = max(0, round(receita_prog_partic[a] * v[a], 0.01)); *---- Mari tirou a multiplicação pelo * &FtSalPart ----*;
						vacf_risco_partic[a] = max(0, round(receita_risco_partic[a] * v[a], 0.01)); *---- Mari tirou a multiplicação pelo * &FtSalPart ----*;

						receita_prog_patroc[a] = ConPatSdoEvol[a];

						/*if (ConPatSdoEvol > 0) then*/
						receita_risco_patroc[a] = max(0, round((SalConPrjEvol[a] / &FtSalPart.) * taxa_risco_patroc[a] * &NroBenAno. * (1 - apx[a]) * pxs[a], 0.01));

						vacf_prog_patroc[a] = max(0, round(receita_prog_patroc[a] * v[a], 0.01)); *---- Mari tirou a multiplicação pelo * &FtSalPart ----*;
						vacf_risco_patroc[a] = max(0, round(receita_risco_patroc[a] * v[a], 0.01)); *---- Mari tirou a multiplicação pelo * &FtSalPart ----*;
					end;
				END;

				create work.vacf_deterministico_ativos var {id_participante tCobertura receita_prog_partic receita_risco_partic receita_prog_patroc receita_risco_patroc vacf_prog_partic vacf_prog_patroc vacf_risco_partic vacf_risco_patroc};
					append;
				close;
			end;
		quit;

		data determin.vacf_ativos;
			merge determin.vacf_ativos work.vacf_deterministico_ativos;
			by id_participante tCobertura;
			format receita_prog_partic commax14.2 receita_risco_partic commax14.2 receita_prog_patroc commax14.2 receita_risco_patroc commax14.2 vacf_prog_partic commax14.2 vacf_risco_partic commax14.2 vacf_prog_patroc commax14.2 vacf_risco_patroc commax14.2;
		run;
	%end;

	proc delete data = work.vacf_deterministico_ativos (gennum=all);
	run;
%mend;
%calcular_fluxo_vacf;


/*%_eg_conditional_dropds(determin.vacf_ativos);*/
/*data determin.vacf_ativos;*/
/*	set determin.vacf_ativos1 - determin.vacf_ativos&numberOfBlocksAtivos;*/
/*run;*/

/*proc datasets nodetails library=determin;*/
/*   delete vacf_ativos1 - vacf_ativos&numberOfBlocksAtivos;*/
/*run;*/

%_eg_conditional_dropds(determin.vacf_receita_ativos);
proc summary data = determin.vacf_ativos;
 class tCobertura;
 var vacf_prog_partic vacf_risco_partic vacf_prog_patroc vacf_risco_patroc
	 receita_prog_partic receita_risco_partic receita_prog_patroc receita_risco_patroc;
 output out=determin.vacf_receita_ativos sum=;
run;

/*data determin.vacf_despesa_ativos;
	set determin.vacf_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;*/

/*%_eg_conditional_dropds(determin.receita_ativos);
proc summary data = determin.vacf_ativos;
 class tCobertura;
 var receita_prog_partic receita_risco_partic receita_prog_patroc receita_risco_patroc;
 output out=determin.receita_ativos sum=;
run;*/

%_eg_conditional_dropds(determin.vacf_encargo_ativos);
proc summary data = determin.vacf_ativos;
 class id_participante;
 var vacf_prog_partic vacf_risco_partic vacf_prog_patroc vacf_risco_patroc;
 output out=determin.vacf_encargo_ativos sum=;
run;

data determin.vacf_encargo_ativos;
	set determin.vacf_encargo_ativos;
	if cmiss(id_participante) then delete;
	drop _TYPE_ _FREQ_;
run;

/*data ativos.ativos;*/
/*	merge ativos.ativos determin.vacf_encargo_ativos;*/
/*	by id_participante;*/
/*run;*/

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
		   *delete vacf_ativos1 - vacf_ativos&numberOfBlocksAtivos;
		   delete vacf_ativos;
		   *delete vacf_encargo_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
