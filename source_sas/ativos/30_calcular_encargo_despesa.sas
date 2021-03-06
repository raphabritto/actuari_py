
%_eg_conditional_dropds(SISATU.ENCARGOS_ATIVOS);
PROC SQL;
	CREATE TABLE SISATU.ENCARGOS_ATIVOS AS
	SELECT t2.id_participante,
	      t2.NuMatrPartic,
	      atc.Despesa_Vp_ATC as EncargoATC,
	      ptc.Despesa_Vp_PTC as EncargoTotPtc,
	      pmc.Despesa_Vp_PMC as EncargoTotPmc,
	      aiv.Despesa_Vp_AIV as EncargoTotAiv,
	      piv.Despesa_Vp_PIV as EncargoTotPiv,
	      pmi.Despesa_Vp_PMI as EncargoTotPmi,
	      ppa.Despesa_Vp_PPA as EncargoTotPpa,
	      pma.Despesa_Vp_PMA as EncargoTotPma,
	        (atc.Despesa_Vp_Atc + ptc.Despesa_Vp_Ptc + pmc.Despesa_Vp_Pmc + aiv.Despesa_Vp_Aiv + piv.Despesa_Vp_Piv +
	        pmi.Despesa_Vp_Pmi + ppa.Despesa_Vp_Ppa + pma.Despesa_Vp_Pma) FORMAT=COMMAX14.2 AS EncargoTotal,
	        axfa.CusNorCobAXFA,
	        axfi.CusNorCobAXFI,
	        vacf.vacf_prog_partic,
	        vacf.vacf_risco_partic,
	        vacf.vacf_prog_patroc,
	        vacf.vacf_risco_patroc,
			rot.despesa_resgate_vp,
			rot.despesa_portabilidade_vp
	from partic.ATIVOS t2
	INNER JOIN determin.atc_encargo_ativos atc ON (t2.ID_PARTICIPANTE = atc.id_participante)
	LEFT JOIN DETERMIN.ptc_encargo_ativos ptc ON (t2.ID_PARTICIPANTE = ptc.id_participante)
	INNER JOIN DETERMIN.pmc_encargo_ativos pmc ON (t2.ID_PARTICIPANTE = pmc.id_participante)
	LEFT JOIN DETERMIN.aiv_encargo_ativos aiv ON (t2.ID_PARTICIPANTE = aiv.id_participante)
	LEFT JOIN DETERMIN.piv_encargo_ativos piv ON (t2.ID_PARTICIPANTE = piv.id_participante)
	INNER JOIN DETERMIN.pma_encargo_ativos pma ON (t2.ID_PARTICIPANTE = pma.id_participante)
	LEFT JOIN DETERMIN.pmi_encargo_ativos pmi ON (t2.ID_PARTICIPANTE = pmi.id_participante)
	LEFT JOIN DETERMIN.ppa_encargo_ativos ppa ON (t2.ID_PARTICIPANTE = ppa.id_participante)
	INNER JOIN cobertur.axfa_produto_ativos axfa ON (t2.ID_PARTICIPANTE = axfa.id_participante)
	LEFT JOIN cobertur.axfi_produto_ativos axfi ON (t2.ID_PARTICIPANTE = axfi.id_participante)
	INNER JOIN determin.vacf_encargo_ativos vacf ON (t2.ID_PARTICIPANTE = vacf.id_participante)
	inner join determin.rotatividade_encargo_ativos rot on (t2.ID_PARTICIPANTE = rot.id_participante)
	order by t2.id_participante;
QUIT;

%_eg_conditional_dropds(work.quantidade_ativos_parcial);
proc sql;
    create table work.quantidade_ativos_parcial as
    select a1.id_participante,
            i1.t,
            (case
                   when (i1.t = 0 and no.apxa = 1) then 1
                   else (max(0, (aje.lxs / aj.lxs) * (1 - no.apxa)))
              end) format=.10 as QtdeParticipantes,
              (case
                   when (i1.t = 0 and no.apxa = 1) then 0
                    else (max(0, (aje.lxs / aj.lxs) * no.apxa))
              end) format=.10 as QtdeElegiveis
    from partic.ativos a1
    inner join cobertur.cobertura_ativos i1 on (a1.id_participante = i1.id_participante)
    inner join tabuas.tabuas_servico_normal no on (a1.CdSexoPartic = no.Sexo and i1.IddPartEvol = no.Idade and no.t = min(i1.t, &maxTaxaJuros))
    inner join tabuas.tabuas_servico_ajustada aj on (a1.CdSexoPartic = aj.Sexo and a1.IddPartiCalc = aj.Idade and aj.t = 0)
    inner join tabuas.tabuas_servico_ajustada aje on (a1.CdSexoPartic = aje.Sexo and i1.IddPartEvol = aje.Idade and aje.t = min(i1.t, &maxTaxaJuros))
    order by i1.id_participante, i1.t;
quit;

 %_eg_conditional_dropds(work.quantidade_ativos);
 proc sql;
      create table work.quantidade_ativos as
      select qtd.t, sum(qtd.QtdeParticipantes) as QtdeParticipantes, sum(qtd.QtdeElegiveis) as QtdeElegiveis
      from work.quantidade_ativos_parcial qtd
      group by qtd.t
      order by qtd.t;

      drop table work.quantidade_ativos_parcial;
 quit;

%_eg_conditional_dropds(work.despesa_saldo_conta_ativos);
 proc sql;
      create table work.despesa_saldo_conta_ativos as
      select t1.t,
			 max(0, sum(t1.VlSdoConPartEvol)) format=commax18.2 as VlSdoConPart,
			 max(0, sum(t1.VlSdoConPatrEvol)) format=commax18.2 as VlSdoConPatr
      from cobertur.cobertura_ativos t1
      group by t1.t
      order by t1.t;
 quit;

%_eg_conditional_dropds(sisatu.DESPESAS_ATIVOS);
proc sql;
     create table sisatu.DESPESAS_ATIVOS as
     select qtat.t,
            qtat.QtdeParticipantes,
            qtat.QtdeElegiveis,
            atc.Despesa_ATC,
            ptc.Despesa_PTC,
            pmc.Despesa_PMC,
            aiv.Despesa_AIV,
            piv.Despesa_PIV,
            pmi.Despesa_PMI,
            ppa.Despesa_PPA,
            pma.Despesa_PMA,
            res.despesa_resgate,
            res.despesa_portabilidade,
            vacf.receita_prog_partic,
			vacf.receita_risco_partic,
			vacf.receita_prog_patroc,
			vacf.receita_risco_patroc,
			sdc.VlSdoConPart,
			sdc.VlSdoConPatr,
            atc.Despesa_Vp_ATC,
            ptc.Despesa_Vp_PTC,
            pmc.Despesa_Vp_PMC,
            aiv.Despesa_Vp_AIV,
            piv.Despesa_Vp_PIV,
            pmi.Despesa_Vp_PMI,
            ppa.Despesa_Vp_PPA,
            pma.Despesa_Vp_PMA,
			res.despesa_resgate_vp,
			res.despesa_portabilidade_vp,
            vacf.vacf_prog_partic,
            vacf.vacf_risco_partic,
            vacf.vacf_prog_patroc,
            vacf.vacf_risco_patroc
     from work.quantidade_ativos qtat
     inner join determin.atc_despesa_ativos atc on (qtat.t = atc.tDeterministico)
     inner join determin.ptc_despesa_ativos ptc on (qtat.t = ptc.tDeterministico)
     inner join determin.pmc_despesa_ativos pmc on (qtat.t = pmc.tDeterministico)
     inner join determin.aiv_despesa_ativos aiv on (qtat.t = aiv.tDeterministico)
     inner join determin.piv_despesa_ativos piv on (qtat.t = piv.tDeterministico)
     inner join determin.pmi_despesa_ativos pmi on (qtat.t = pmi.tDeterministico)
     inner join determin.ppa_despesa_ativos ppa on (qtat.t = ppa.tDeterministico)
     inner join determin.pma_despesa_ativos pma on (qtat.t = pma.tCobertura)
     inner join determin.rotatividade_despesa_ativos res on (qtat.t = res.t)
     inner join determin.VACF_RECEITA_ATIVOS vacf on (qtat.t = vacf.tCobertura)
	 inner join work.despesa_saldo_conta_ativos sdc on (qtat.t = sdc.t)
     order by qtat.t;
quit;

proc delete data = work.quantidade_ativos work.despesa_saldo_conta_ativos;

proc sql;
     create table sisatu.demonstracao_atuarial_ativo as
     select count(t1.id_participante) as QuantParticipantes,
             round((sum(t1.TmpPlanoPrev) / count(t1.id_participante))) * 12 as TempoMedioContribuicao,
             round((sum(t1.TmpPlanoRest) / count(t1.id_participante)) * 12) as TempoMedioFaltanteAposent,
             sum(t1.VlSalEntPrev) format=commax14.2 as SalarioParticipacao
     from partic.ativos t1;
quit;
