
%_eg_conditional_dropds(work.taxa_risco_ativos);
proc sql;
	create table work.taxa_risco_ativos as
	select t1.id_participante,
			agec.t,
			max(0, (t9.lxs / t10.lxs)) format=12.8 as pxs,
			max(0, ((noco.Nxiicb / noco.Dxiicb) - &Fb)) format=12.8 AS axiicb,
			max(0, ((((nojc.Nxcb / nojc.Dxcb) - &Fb) - ((n2.njxx / d2.djxx) - &Fb)) * t1.PrbCasado)) format=12.8 as amix,
			max(0, (noco.Mxii / noco.'Dxii*'n)) format=12.8 as Axii,
			max(0, ((nojc.Nxcb / nojc.Dxcb) - &Fb)) format=12.8 AS ajxcb,
			max(0, (noco.Mx / noco.'Dx*'n)) format=12.8 as Ax,
			t9.ix format=12.8 AS ix,
			t9.qx format=12.8 AS qx,
			noco.apxa format=12.8 AS apx
	from partic.ativos t1
	inner join cobertur.cobertura_ativos agec on (t1.id_participante = agec.id_participante)
	inner join tabuas.tabuas_servico_ajustada t9 on (t1.CdSexoPartic = t9.Sexo and agec.IddPartEvol = t9.Idade and t9.t = min(agec.t, &maxTaxaJuros))
	inner join tabuas.tabuas_servico_ajustada t10 on (t1.CdSexoPartic = t10.Sexo and t1.IddPartiCalc = t10.Idade and t10.t = 0)
	inner join TABUAS.tabuas_SERVICO_NORMAL noco on (t1.CdSexoPartic = noco.Sexo and agec.IddPartEvol = noco.Idade and noco.t = min(agec.t, &maxTaxaJuros))
	inner join TABUAS.tabuas_SERVICO_NORMAL nojc on (t1.CdSexoConjug = nojc.Sexo and agec.IddConjEvol = nojc.Idade and nojc.t = min(agec.t, &maxTaxaJuros))
	inner join TABUAS.tabuas_PENSAO_NJXX n2 on (t1.CdSexoPartic = n2.Sexo AND agec.IddPartEvol = n2.idade_x AND agec.IddConjEvol = n2.idade_j AND n2.Tipo = 2 and n2.t = min(agec.t, &maxTaxaJuros))
	inner join TABUAS.tabuas_PENSAO_DJXX d2 on (t1.CdSexoPartic = d2.Sexo AND agec.IddPartEvol = d2.idade_x AND agec.IddConjEvol = d2.idade_j AND d2.Tipo = 2 and d2.t = min(agec.t, &maxTaxaJuros))
	order by t1.id_participante, agec.t;
quit;

%_eg_conditional_dropds(work.taxa_risco_reserva_ativos);
proc sql;
	create table work.taxa_risco_reserva_ativos as
	select t1.id_participante,
			ben.t,
			(case
				when t1.flg_manutencao_saldo = 1 and &CdPlanBen <> 2
					then 0
					else max(0, ((ben.SalConPrjEvol / &FtSalPart) * fat.pxs * &NroBenAno * (1 - fat.apx)))
			end) format=commax14.2 as FolhaSalarial,
			max(0, ((ben.SalConPrjEvol / &FtSalPart) * fat.pxs * &NroBenAno * (1 - fat.apx) * 1 / ((1 + tx.vl_taxa_juros) ** ben.t))) format=commax14.2 as VPFolhaSalarial,
			(case
				when &CdPlanBen = 2
					then max(0, t1.VlBenSaldado * &FtBenLiquido * fat.pxs * &NroBenAno * (1 - fat.apx))
					else 0
			end) format=commax14.2 as FolhaBenSaldado,
			max(0, ben.VlSdoConPartEvol + ben.VlSdoConPatrEvol) format=commax14.2 as SaldoContaTotal,
			max(0, aiv.BenLiqCobAIV * fat.axiicb * &NroBenAno) format=commax14.2 as EncargoAIV,
			max(0, piv.BenLiqCobPIV * fat.amix * &NroBenAno) format=commax14.2 as EncargoPIV,
			max(0, pmi.beneficio_pmi * fat.Axii) format=commax14.2 as EncargoPMI,
			max(0, ppa.BenLiqCobPPA * fat.ajxcb * &NroBenAno * t1.PrbCasado) format=commax14.2 as EncargoPPA,
			max(0, pma.beneficio_pma) format=commax14.2 as EncargoPMA
	from partic.ativos t1
	inner join cobertur.cobertura_ativos ben on (t1.id_participante = ben.id_participante)
	inner join work.taxa_juros tx on (tx.t = min(ben.t, &maxTaxajuros))
	inner join cobertur.aiv_ativos aiv on (t1.id_participante = aiv.id_participante and ben.t = aiv.t)
	inner join cobertur.piv_ativos piv on (t1.id_participante = piv.id_participante and ben.t = piv.t)
	inner join determin.pmi_ativos pmi on (t1.id_participante = pmi.id_participante and ben.t = pmi.tCobertura and pmi.tCobertura = pmi.tDeterministico)
	inner join cobertur.ppa_ativos ppa on (t1.id_participante = ppa.id_participante and ben.t = ppa.t)
	inner join determin.pma_ativos pma on (t1.id_participante = pma.id_participante and ben.t = pma.tCobertura)
	inner join work.taxa_risco_ativos fat on (t1.id_participante = fat.id_participante and ben.t = fat.t)
	order by t1.id_participante, ben.t;
quit;

%_eg_conditional_dropds(work.ativos_encargo_risco);
proc sql;
	create table work.ativos_encargo_risco as
	select res.id_participante,
			res.t,
			max(0, ((res.EncargoAIV + res.EncargoPIV + EncargoPMI) - res.SaldoContaTotal) * fat.ix * (1 - fat.apx)) format=commax14.2 as CustoNormalInvalidez,
			max(0, (max(0, res.EncargoPPA - res.SaldoContaTotal) + res.EncargoPMA) * fat.qx * (1 - fat.apx)) format=commax14.2 as CustoNormalMorte
	from work.taxa_risco_reserva_ativos res
	inner join work.taxa_risco_ativos fat on (res.id_participante = fat.id_participante and res.t = fat.t)
	order by res.id_participante, res.t;
quit;

%_eg_conditional_dropds(risco.folha_salarial_ativos);
data risco.folha_salarial_ativos;
	merge work.taxa_risco_ativos work.taxa_risco_reserva_ativos work.ativos_encargo_risco;
	by id_participante t;
run;

proc datasets nodetails library=risco;
   delete taxa_risco_ativos;
   delete taxa_risco_reserva_ativos;
   delete ativos_encargo_risco;
run;

%_eg_conditional_dropds(risco.taxa_risco_ativos);
proc sql;
	create table risco.taxa_risco_ativos as
	select enc.t,
			max(0, sum(enc.FolhaSalarial)) format=commax18.2 as FolhaSalarial,
			max(0, sum(enc.VPFolhaSalarial)) format=commax18.2 as VPFolhaSalarial,
			max(0, sum(enc.SaldoContaTotal)) format=commax18.2 as SaldoContaTotal,
			max(0, sum(enc.FolhaBenSaldado)) format=commax18.2 as FolhaBenSaldado,
			max(0, sum(enc.EncargoAIV)) format=commax18.2 as EncargoAIV,
			max(0, sum(enc.EncargoPIV)) format=commax18.2 as EncargoPIV,
			max(0, sum(enc.EncargoPMI)) format=commax18.2 as EncargoPMI,
			max(0, sum(enc.EncargoPPA)) format=commax18.2 as EncargoPPA,
			max(0, sum(enc.EncargoPMA)) format=commax18.2 as EncargoPMA,
			max(0, sum(enc.CustoNormalInvalidez)) format=commax18.2 as CustoNormalInvalidez,
			max(0, sum(enc.CustoNormalMorte)) format=commax18.2 as CustoNormalMorte,
		   max(0, (sum(enc.CustoNormalInvalidez + enc.CustoNormalMorte) / sum(enc.FolhaSalarial))) format=10.6 as TaxaRisco
	from risco.folha_salarial_ativos enc
	group by enc.t
	order by enc.t;
quit;


%macro calcula_despesa_total_alm;
	%if (&CdPlanBen. = 4 | &CdPlanBen. = 5) %then %do;
		proc iml;
			use determin.despesa_atc_alm;
				read all var _all_ into despesa_atc;
			close;

			use determin.despesa_ptc_alm;
				read all var _all_ into despesa_ptc;
			close;

			use determin.despesa_aiv_alm;
				read all var _all_ into despesa_aiv;
			close;

			use determin.despesa_piv_alm;
				read all var _all_ into despesa_piv;
			close;

			use determin.despesa_ppa_alm;
				read all var _all_ into despesa_ppa;
			close;

			use determin.despesa_pmc_alm;
				read all var _all_ into despesa_pmc;
			close;

			use determin.despesa_pmi_alm;
				read all var _all_ into despesa_pmi;
			close;

			use determin.despesa_pma_alm;
				read all var _all_ into despesa_pma;
			close;

			despesa_total = despesa_atc + despesa_ptc + despesa_aiv + despesa_piv + despesa_ppa + despesa_pmc + despesa_pmi + despesa_pma;

			create work.despesa_total_alm from despesa_total;
				append from despesa_total;
			close;

			/*   calculo encargo alm    */

			use cobertur.encargo_atc_bua_alm;
				read all var _all_ into encargo_atc;
			close;

			use cobertur.encargo_ptc_alm;
				read all var _all_ into encargo_ptc;
			close;

			use cobertur.encargo_aiv_bua_alm;
				read all var _all_ into encargo_aiv;
			close;

			use cobertur.encargo_piv_alm;
				read all var _all_ into encargo_piv;
			close;

			use cobertur.encargo_ppa_bua_alm;
				read all var _all_ into encargo_ppa;
			close;

			use cobertur.encargo_pmc_alm;
				read all var _all_ into encargo_pmc;
			close;

			use cobertur.encargo_pmi_alm;
				read all var _all_ into encargo_pmi;
			close;

			use cobertur.encargo_pma_alm;
				read all var _all_ into encargo_pma;
			close;

			encargo_total = encargo_atc + encargo_ptc + encargo_aiv + encargo_piv + encargo_ppa + encargo_pmc + encargo_pmi + encargo_pma;

			create work.encargo_total_alm from encargo_total;
				append from encargo_total;
			close;
		quit;

		data sisatu.despesa_total_alm;
			set work.despesa_total_alm;
			col1 = _n_ - 1;
			format col2 - col80 commax18.2;
			rename col1 = t;
		run;

		data sisatu.encargo_total_alm;
			set work.encargo_total_alm;
			col1 = _n_ - 1;
			format col2 commax18.2;
			rename col1 = t col2 = EncargoTotal;
		run;
	%end;
%mend;
%calcula_despesa_total_alm;
