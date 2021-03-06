*-------------------------------------------------------------------------------------------------------------*;
*-- PPA - Pensão por morte de ativo				                                     	          		 	--*;
*-------------------------------------------------------------------------------------------------------------*;

%_eg_conditional_dropds(cobertur.ppa_ativos);
proc sql;
	create table cobertur.ppa_ativos as
	select t1.id_participante,
			t3.t,
			t3.IddPartEvol,
			t1.IddIniApoInss,
			t1.VlBenefiInss,
			t3.SalConPrjEvol,
			t3.SalBenefInssEvol,
			t3.VlSdoConPartEvol,
			t3.VlSdoConPatrEvol,
			t1.VlBenSaldado,
			t1.PeFatReduPbe,
			t1.PrbCasado,
			t1.flg_manutencao_saldo,
			max(0, ((t8.Nxcb / t8.Dxcb) - &Fb)) format=12.8 AS ajxcb,
			max(0, (t11.Dxs / t12.Dxs)) format=12.8 AS dy_dx,
			t11.qx,
			t7.apxa as apx,
			t1.id_bloco
	from partic.ativos t1
	inner join cobertur.cobertura_ativos t3 on (t1.id_participante = t3.id_participante)
	inner join TABUAS.TABUAS_SERVICO_NORMAL t7 on (t1.CdSexoPartic = t7.Sexo and t3.IddPartEvol = t7.Idade and t7.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_NORMAL t8 on (t1.CdSexoConjug = t8.Sexo and t3.IddConjEvol = t8.Idade and t8.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_AJUSTADA t11 on (t1.CdSexoPartic = t11.Sexo AND t3.IddPartEvol = t11.Idade and t11.t = min(t3.t, &maxTaxaJuros))
	inner join TABUAS.TABUAS_SERVICO_AJUSTADA t12 on (t1.CdSexoPartic = t12.Sexo AND t1.IddPartiCalc = t12.Idade and t12.t = 0)
	inner join TABUAS.TABUAS_SERVICO_NORMAL t9 on (t1.CdSexoPartic = t9.Sexo and t9.Idade = (case when t1.CdSexoPartic = 1 then &idade_apx_fem else &idade_apx_mas end) and t9.t = 0)
	order by t1.id_participante, t3.t;
quit;

%macro calcCoberturaPpa;
	%do a = 1 %to &numberOfBlocksAtivos;
		%_eg_conditional_dropds(work.ppa_cobertura_ativos);

		PROC IML;
			LOAD MODULE= GetContribuicao;

			use cobertur.ppa_ativos;
				read all var {id_participante t SalConPrjEvol SalBenefInssEvol VlSdoConPartEvol VlSdoConPatrEvol VlBenSaldado PeFatReduPbe PrbCasado ajxcb dy_dx qx apx flg_manutencao_saldo} into ativos where (id_bloco = &a.);
			close;

			qtdObs = nrow(ativos);

			if (qtdObs > 0) then do;
				coberturaPpa = J(qtdObs, 6, 0);

				DO a = 1 TO qtdObs;
					t = ativos[a, 2];
					SalConPrj = ativos[a, 3];
					SalBenefInss = ativos[a, 4];
					VlSdoConPart = ativos[a, 5];
					VlSdoConPatr = ativos[a, 6];
					VlSdoConTot = VlSdoConPart + VlSdoConPatr;
					VlBenSaldado = ativos[a, 7];
					PeFatReduPbe = ativos[a, 8];
					PrbCasado = ativos[a, 9];
					ajxcb = ativos[a, 10];
					dy_dx = ativos[a, 11];
					qx = ativos[a, 12];
					apx = ativos[a, 13];
					flg_manutencao_saldo = ativos[a, 14];

					BenTotPpa = 0;
					ConPvdPpa = 0;
					BenLiqPpa = 0;
					FatRenVitPpa = 0;
					AplicarPxsPPA = 0;
					BenTotPxsPpa = 0;
					BenTotPpaRev = 0;

					if (&CdPlanBen = 1) then do;
						BenTotPxsPpa = max(0, round((SalConPrj * &CtFamPens) - SalBenefInss, 0.01));

						if (PeFatReduPbe > 0) then BenTotPxsPpa = round(BenTotPxsPpa * PeFatReduPbe, 0.01);

			    		FatRenVitPpa = max(0, round(ajxcb * &NroBenAno * &FtBenEnti * PrbCasado, 0.0000000001));

						if (FatRenVitPpa > 0) then
		               		BenTotPpaRev = max(0, round((VlSdoConTot / FatRenVitPpa) * &FtBenEnti, 0.01));

						if (BenTotPxsPpa > BenTotPpaRev) then do;
							BenTotPpa = BenTotPxsPpa;
							AplicarPxsPPA = 1;
						end;
						else
							BenTotPpa = BenTotPpaRev;

						*------ Contribuição e benefício líquido da cobertura PPA ------;
						ConPvdPpa = GetContribuicao(BenTotPpa / &FtBenEnti) * (1 - &TxaAdmBen);
					end;
					else if (&CdPlanBen = 2) then do;
						BenTotPpa = max(0, round(VlBenSaldado * &CtFamPens * &FtBenLiquido * &FtBenEnti, 0.01));
						AplicarPxsPPA = 1;
					end;
					else if (&CdPlanBen = 4 | &CdPlanBen = 5) then do;
						FtRenVitPpa = max(0, round(ajxcb * &NroBenAno * &FtBenEnti * PrbCasado, 0.0000000001));

						if (flg_manutencao_saldo = 0) then
							BenTotPxsPpa = max(0, max(round((SalConPrj * &CtFamPens) - SalBenefInss, 0.01), round(SalConPrj * &percentualSRB, 0.01)));

						if (&CdPlanBen = 5) then
							BenTotPxsPpa = max(0, round(BenTotPxsPpa - (VlBenSaldado * &FtBenLiquido * &CtFamPens), 0.01));

						if (FtRenVitPpa > 0) then
							BenTotPpaRev = max(0, round((VlSdoConTot / FtRenVitPpa) * &FtBenEnti, &vRoundMoeda));

						if (BenTotPxsPpa > BenTotPpaRev) then do;
							BenTotPpa = BenTotPxsPpa;
							AplicarPxsPPA = 1;
						end;
						else
							BenTotPpa = BenTotPpaRev;
					end;

					if (&CdPlanBen ^= 1 & &percentualSaqueBUA > 0) then
						BenLiqPpa = max(0, round((BenTotPpa - ConPvdPpa) * (1 - &percentualBUA * &percentualSaqueBUA), 0.01));
					else
						BenLiqPpa = max(0, round(BenTotPpa - ConPvdPpa, 0.01));

					coberturaPpa[a, 1] = ativos[a, 1];
					coberturaPpa[a, 2] = ativos[a, 2];
					coberturaPpa[a, 3] = BenTotPpa;
					coberturaPpa[a, 4] = ConPvdPpa;
					coberturaPpa[a, 5] = BenLiqPpa;
					coberturaPpa[a, 6] = AplicarPxsPPA;
				END;

				create work.ppa_cobertura_ativos from coberturaPpa[colname={'id_participante' 't' 'BenTotCobPPA' 'ConPvdCobPPA' 'BenLiqCobPPA' 'AplicarPxsPPA'}];
					append from coberturaPpa;
				close;
			end;
		QUIT;

		data cobertur.ppa_ativos;
			merge cobertur.ppa_ativos work.ppa_cobertura_ativos;
			by id_participante t;
			format BenTotCobPPA COMMAX14.2 ConPvdCobPPA COMMAX14.2 BenLiqCobPPA COMMAX14.2;
		run;
	%end;

	proc delete data = work.ppa_cobertura_ativos (gennum=all);
	run;
%mend;
%calcCoberturaPpa;

%macro calcula_encargo_ppa_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		%_eg_conditional_dropds(work.encargo_ppa_alm);
		proc sql;
			create table work.encargo_ppa_alm as
			select c.id_participante, c.t, max(0, (c.BenLiqCobPPA * (1 - c.apx) * c.qx * c.ajxcb * c.PrbCasado * &NroBenAno.)) format=commax14.2 as encargo_ppa
			from cobertur.ppa_ativos c
			order by c.id_participante, c.t;
		run;

		%_eg_conditional_dropds(cobertur.encargo_ppa_alm);
		proc sql;
			create table cobertur.encargo_ppa_alm as
			select e.t, max(0, sum(e.encargo_ppa)) format=commax18.2 as encargo_ppa
			from work.encargo_ppa_alm e
			group by e.t
			order by e.t;
		run;

		proc delete data = work.encargo_ppa_alm (gennum=all);
		run;
	%end;
%mend;
%calcula_encargo_ppa_alm;
