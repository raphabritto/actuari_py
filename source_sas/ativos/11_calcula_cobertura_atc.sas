*-------------------------------------------------------------------------------------------------------------*;
*-- ATC - APOSENTADORIA POR TEMPO DE CONTRIBUIÇÃO					                                        --*;
*-------------------------------------------------------------------------------------------------------------*;

%_eg_conditional_dropds(cobertur.atc_ativos);
proc sql;
	create table cobertur.atc_ativos as
	select t1.id_participante,
			t3.t,
			t3.SalConPrjEvol,
			t3.SalProjeInssEvol,
			t3.VlSdoConPartEvol,
			t3.VlSdoConPatrEvol,
			t1.VlBenSaldado,
			t1.PeFatReduPbe,
			t1.PrbCasado,
			max(0, ((t7.Nxcb / t7.Dxcb) - &Fb)) format=12.8 AS axcb,
			max(0, ((t8.Nxcb / t8.Dxcb) - &Fb)) format=12.8 AS ajxcb,
			max(0, ((t9.njxx / t10.djxx) - &Fb)) format=12.8 AS ajxx,
			max(0, (t11.Dxs / t12.Dxs)) format=12.8 AS dy_dx,
			max(0, (t7.Mx / t7.'Dx*'n)) format=12.8 as Ax,
			(case
				when t3.t = 0
					then t7.apxa
					else t7.apx
			end) format=12.8 AS apx,
			t1.id_bloco
	from partic.ativos t1
	inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
	inner join TABUAS.TABUAS_SERVICO_NORMAL t7 on (t1.CdSexoPartic = t7.Sexo and t3.IddPartEvol = t7.Idade and t7.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_NORMAL t8 on (t1.CdSexoConjug = t8.Sexo and t3.IddConjEvol = t8.Idade and t8.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_PENSAO_NJXX t9 on (t1.CdSexoPartic = t9.sexo AND t3.IddPartEvol = t9.idade_x AND t3.IddConjEvol = t9.idade_j AND t9.tipo = 1 and t9.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_PENSAO_DJXX t10 on (t1.CdSexoPartic = t10.sexo AND t3.IddPartEvol = t10.idade_x AND t3.IddConjEvol = t10.idade_j AND t10.tipo = 1 and t10.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_AJUSTADA t11 on (t1.CdSexoPartic = t11.Sexo AND t3.IddPartEvol = t11.Idade and t11.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_AJUSTADA t12 on (t1.CdSexoPartic = t12.Sexo AND t1.IddPartiCalc = t12.Idade and t12.t = 0)
	order by t1.id_participante, t3.t;
quit;

%macro calcCoberturaAtc;
	%do a = 1 %to &numberOfBlocksAtivos;
		%_eg_conditional_dropds(work.atc_cobertura_ativos);

		PROC IML;
			load module= GetContribuicao;

			use cobertur.atc_ativos;
				read all var {id_participante t SalConPrjEvol SalProjeInssEvol VlSdoConPartEvol VlSdoConPatrEvol VlBenSaldado PeFatReduPbe PrbCasado axcb ajxcb ajxx dy_dx apx Ax} into ativos where (id_bloco = &a.);
			close;

			qtdObs = nrow(ativos);

			if (qtdObs > 0) then do;
				coberturaAtc = J(qtdObs, 5, 0);

				do a = 1 to qtdObs;
					BenTotCobAtc = 0;
				    contribuicaoAtc = 0;
				    BenLiqCobAtc = 0;
					FtRenVitAtc = 0;

					SalConPrj = ativos[a, 3];
					SalProjeInss = ativos[a, 4];
					VlSdoConPart = ativos[a, 5];
					VlSdoConPatr = ativos[a, 6];
					VlSdoConTot = VlSdoConPart + VlSdoConPatr;
					VlBenSaldado = ativos[a, 7];
					PeFatReduPbe = ativos[a, 8];
					PrbCasado = ativos[a, 9];
					axcb = ativos[a, 10];
					ajxcb = ativos[a, 11];
					ajxx = ativos[a, 12];
					dy_dx = ativos[a, 13];
					apx = ativos[a, 14];
					ax = ativos[a, 15];

					if (&CdPlanBen = 1) then do; *--- REG REPLAN NÃO SALDADO ---*;
						BenTotCobAtc = max(0, round(SalConPrj - SalProjeInss, &vRoundMoeda));

						if (PeFatReduPbe > 0) then BenTotCobAtc = max(0, round(BenTotCobAtc * PeFatReduPbe, &vRoundMoeda));

						FtRenVitAtc = max(0, round((axcb + &CtFamPens * PrbCasado * (ajxcb - ajxx)) * &NroBenAno * &FtBenEnti, 0.00000001));

						if (FtRenVitAtc > 0) then
							BenTotCobAtc = max(BenTotCobAtc, round((VlSdoConTot / FtRenVitAtc) * &FtBenEnti, &vRoundMoeda));

						*--- Calcula a contribuição utilizando benefício total cobertura ATC ---*;
						contribuicaoAtc = GetContribuicao(BenTotCobAtc/&FtBenEnti) * (1 - &TxaAdmBen);
					end;
					else if (&CdPlanBen = 2) then do; *--- REG REPLAN SALDADO ---*;
						BenTotCobAtc = max(0, VlBenSaldado * &FtBenLiquido * &FtBenEnti);
					end;
					else if (&CdPlanBen = 4 | &CdPlanBen = 5) then do; *--- REB e NOVO PLANO ---*;
						FtRenVitAtc = round((axcb + &CtFamPens * PrbCasado * (ajxcb - ajxx)) * &NroBenAno * &FtBenEnti + (ax * &peculioMorteAssistido), 0.00000001);

						if (FtRenVitAtc > 0) then do;
							BenTotCobAtc = max(0, round((VlSdoConTot / FtRenVitAtc) * &FtBenEnti, &vRoundMoeda));
						end;
					end;

					if (&CdPlanBen ^= 1 & &percentualSaqueBUA > 0) then
						BenLiqCobAtc = max(0, round((BenTotCobAtc - contribuicaoAtc) * (1 - &percentualBUA * &percentualSaqueBUA), 0.01));
					else
						BenLiqCobAtc = max(0, round(BenTotCobAtc - contribuicaoAtc, 0.01));

					coberturaAtc[a, 1] = ativos[a, 1];
					coberturaAtc[a, 2] = ativos[a, 2];
					coberturaAtc[a, 3] = BenTotCobAtc;
					coberturaAtc[a, 4] = contribuicaoAtc;
					coberturaAtc[a, 5] = BenLiqCobAtc;
				end;

				create work.atc_cobertura_ativos from coberturaAtc[colname={'id_participante' 't' 'BenTotCobATC' 'ConPrvCobATC' 'BenLiqCobATC'}];
					append from coberturaAtc;
				close;
			end;
		QUIT;

		data cobertur.atc_ativos;
			merge cobertur.atc_ativos work.atc_cobertura_ativos;
			by id_participante t;
			format BenTotCobATC commax14.2 ConPrvCobATC commax14.2 BenLiqCobATC commax14.2;
		run;
	%end;

	proc delete data = work.atc_cobertura_ativos (gennum=all);
	run;
%mend;
%calcCoberturaAtc;


%macro calcula_encargo_atc_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%_eg_conditional_dropds(work.encargo_atc_alm);
		proc sql;
			create table work.encargo_atc_alm as
			select c.id_participante,
				   c.t,
				   max(0, (c.BenLiqCobATC * c.axcb * c.apx * &NroBenAno.)) format=commax14.2 as encargo_atc
			from cobertur.atc_ativos c
			order by c.id_participante, c.t;
		run;

		%_eg_conditional_dropds(cobertur.encargo_atc_alm);
		proc sql;
			create table cobertur.encargo_atc_alm as
			select e.t,
				   max(0, sum(e.encargo_atc)) format=commax18.2 as encargo_atc
			from work.encargo_atc_alm e
			group by e.t
			order by e.t;
		run;

		proc delete data = work.encargo_atc_alm (gennum=all);
		run;
	%end;
%mend;
%calcula_encargo_atc_alm;
