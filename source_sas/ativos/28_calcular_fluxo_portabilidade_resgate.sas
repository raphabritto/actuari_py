*-- CÁLCULO DO FLUXO ATUARIAL DAS RECEITAS E DESPESAS DO PLANO DE BENEFÍCIOS - PARTICIPANTES E ASSISTIDOS         --*;
*-- Versão: 22 de junho de 2012                                                                                   --*;
*-- Modificação para incorporar o saque de BUA: 30 de outubro de 2012                                             --*;
*-- Para o cálculo de BUA, ele é feito com base no saldo de conta, para o caso dos planos CD e CV. Para os        --*;
*-- planos BD, o cálculo de BUA é feito apenas quando o método de financiamento é do tipo BSD.                    --*;

%_eg_conditional_dropds(determin.rotatividade_ativos);
proc sql;
	create table determin.rotatividade_ativos as
	select t1.id_participante,
			ben.t,
			ben.SalConPrjEvol,
			ben.ConParSdoEvol,
			ben.ConPatSdoEvol,
			ben.VlSdoConPartEvol,
			ben.VlSdoConPatrEvol,
			floor(t1.TmpPlanoPrev + ben.t) as TmpPlanoPrev,
			ajco.'wx'n as wx,
			noco.apxa format=12.8 as apx,
			txc.vl_taxa_juros as taxa_juros_cob
	from partic.ativos t1
	inner join cobertur.cobertura_ativos ben on (t1.id_participante = ben.id_participante)
	inner join work.taxa_juros txc on (txc.t = min(ben.t, &maxTaxaJuros))
	inner join tabuas.tabuas_servico_normal noco on (t1.CdSexoPartic = noco.Sexo and ben.IddPartEvol = noco.Idade and noco.t = min(ben.t, &maxTaxaJuros))
	inner join tabuas.tabuas_servico_ajustada ajco on (t1.CdSexoPartic = ajco.Sexo and ben.IddPartEvol = ajco.Idade and ajco.t = min(ben.t, &maxTaxaJuros))
	order by t1.id_participante, ben.t;
quit;

%_eg_conditional_dropds(work.rotatividade_determin_ativos);
proc iml;
	USE determin.rotatividade_ativos;
/*		read all var {id_participante t SalConPrjEvol ConParSdoEvol ConPatSdoEvol VlSdoConPartEvol VlSdoConPatrEvol TmpPlanoPrev wx apx taxa_juros_cob} into ativos;*/
		read all var {id_participante} into id_participante;
		read all var {t} into t;
		read all var {SalConPrjEvol} into SalConPrjEvol;
		read all var {ConParSdoEvol} into ConParSdoEvol;
		read all var {ConPatSdoEvol} into ConPatSdoEvol;
		read all var {VlSdoConPartEvol} into VlSdoConPartEvol;
		read all var {VlSdoConPatrEvol} into VlSdoConPatrEvol;
		read all var {TmpPlanoPrev} into TmpPlanoPrev;
		read all var {wx} into wx;
		read all var {apx} into apx;
		read all var {taxa_juros_cob} into taxa_juros_cob;
	CLOSE;

	qtsObs = nrow(id_participante);

	if (qtsObs > 0) then do;
/*		lstResgatePortabilidade = J(qtsObs, 6, 0);*/
		resgate = J(qtsObs, 1, 0);
		portabilidade = J(qtsObs, 1, 0);
		despesa_resgate = J(qtsObs, 1, 0);
		despesa_portabilidade = J(qtsObs, 1, 0);
		despesa_resgate_vp = J(qtsObs, 1, 0);
		despesa_portabilidade_vp = J(qtsObs, 1, 0);
		v = J(qtsObs, 1, 0);

		DO a = 1 TO qtsObs;
			if (&CdPlanBen. = 4 | &CdPlanBen. = 5) then do;
				*** regra calculo resgate - regra separada pois as premissas de tempo de participacao no plano podem variar da portabilidade ***;
				if (&CdPlanBen. = 4) then do;
					if (TmpPlanoPrev[a] < 11) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01)); * --- Mariana alterou aqui 0.05 --- *;
					end;
					else if (TmpPlanoPrev[a] >= 11 & TmpPlanoPrev[a] < 16) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01)); * --- Mariana alterou aqui 0.1 --- *;
					end;
					else if (TmpPlanoPrev[a] >= 16 & TmpPlanoPrev[a] < 21) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01)); * --- Mariana alterou aqui 0.15 --- *;
					end;
					else if (TmpPlanoPrev[a] >= 21) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01)); * --- Mariana alterou aqui 0.2 --- *;
					end;
				end;
				else if (&CdPlanBen. = 5) then do;
					if (TmpPlanoPrev[a] <= 10) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 10 & TmpPlanoPrev[a] <= 15) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 15 & TmpPlanoPrev[a] <= 20) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 20) then do;
						resgate[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
				end;

				if (TmpPlanoPrev[a] < 3) then
					despesa_resgate[a] = max(0, round((VlSdoConPartEvol[a] + resgate[a]) * wx[a] * (1 - apx[a]), 0.01));
				else
					despesa_resgate[a] = max(0, round((VlSdoConPartEvol[a] + resgate[a]) * wx[a] * &percentualResgate. * (1 - apx[a]), 0.01));

				*** regra calculo portabilidade - regra separada pois as premissas de tempo de participacao no plano podem variar do resgate ***;
				if (&CdPlanBen. = 4) then do;
					if (TmpPlanoPrev[a] <= 10) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 10 & TmpPlanoPrev[a] <= 15) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 15 & TmpPlanoPrev[a] <= 20) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 20) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
				end;
				else if (&CdPlanBen. = 5) then do;
					if (TmpPlanoPrev[a] <= 10) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 10 & TmpPlanoPrev[a] <= 15) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 15 & TmpPlanoPrev[a] <= 20) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
					else if (TmpPlanoPrev[a] > 20) then do;
						portabilidade[a] = max(0, round(VlSdoConPatrEvol[a] * 1, 0.01));
					end;
				end;

				if (TmpPlanoPrev[a] < 3) then
					despesa_portabilidade[a] = 0;
				else
					despesa_portabilidade[a] = max(0, round((VlSdoConPartEvol[a] + portabilidade[a]) * wx[a] * &percentualPortabilidade. * (1 - apx[a]), 0.01));

				v[a] = max(0, 1 / ((1 + taxa_juros_cob[a]) ** t[a]));

				despesa_resgate_vp[a] = max(0, round(despesa_resgate[a] * v[a], 0.01));
				despesa_portabilidade_vp[a] = max(0, round(despesa_portabilidade[a] * v[a], 0.01));
			end;
		END;

/*		create work.rotatividade_determin_ativos from lstResgatePortabilidade[colname={'id_participante' 't' 'DespesaResgate' 'DespesaPortabilidade' 'DespesaResgateVP' 'DespesaPortabilidadeVP'}];*/
/*			append from lstResgatePortabilidade;*/
		create work.rotatividade_determin_ativos var {id_participante t despesa_resgate despesa_portabilidade despesa_resgate_vp despesa_portabilidade_vp};
			append;
		close;
	end;
quit;

data determin.rotatividade_ativos;
	merge determin.rotatividade_ativos work.rotatividade_determin_ativos;
		by id_participante t;
	format despesa_resgate commax14.2 despesa_portabilidade commax14.2 despesa_resgate_vp commax14.2 despesa_portabilidade_vp commax14.2;
run;

proc delete data = work.rotatividade_determin_ativos;

/*%_eg_conditional_dropds(determin.rotatividade_ativos);
data determin.rotatividade_ativos;
	set determin.rotatividade_ativos1 - determin.rotatividade_ativos&numberOfBlocksAtivos;
run;*/

/*proc datasets nodetails library=determin;
   delete rotatividade_ativos1 - rotatividade_ativos&numberOfBlocksAtivos;
run;*/

%_eg_conditional_dropds(determin.rotatividade_despesa_ativos);
proc summary data = determin.rotatividade_ativos;
	class t;
	var despesa_resgate despesa_portabilidade despesa_resgate_vp despesa_portabilidade_vp;
	output out=determin.rotatividade_despesa_ativos sum=;
run;

%_eg_conditional_dropds(determin.rotatividade_encargo_ativos);
proc summary data = determin.rotatividade_ativos;
	class id_participante;
	var despesa_resgate_vp despesa_portabilidade_vp;
	output out=determin.rotatividade_encargo_ativos sum=;
run;

/*data determin.rotatividade_despesa_ativos;
	set determin.rotatividade_despesa_ativos;
	if cmiss(tDeterministico) then delete;
	drop _TYPE_ _FREQ_;
run;*/

%macro gravaMemoriaCalculo;
	%if (&isGravaMemoriaCalculo = 0) %then %do;
		proc datasets nodetails library=determin;
			delete rotatividade_ativos;
		run;
	%end;
%mend;
%gravaMemoriaCalculo;
