
proc sql;
	create table work.idade_cobertura_bloco as
	select t2.id_participante,
		   t2.t,
		   t1.IddPartiCalc,
		   t1.IddConjuCalc,
/*		   t2.IddPartEvol,*/
/*		   t2.IddConjEvol,*/
		   t1.id_bloco
	from partic.ativos t1
	inner join cobertur.cobertura_ativos t2 on (t1.id_participante = t2.id_participante)
	order by t1.id_participante, t2.t;
quit;

/*data _null_;*/
/*	do a = 1 to &numberOfBlocksAtivos.;*/
		%_eg_conditional_dropds(work.idade_deterministico_ativos);
		data work.idade_deterministico_ativos;
			set work.idade_cobertura_bloco;

			retain id_participante t tDeterministico IddPartiDeter IddConjuDeter id_bloco;

			do tDeterministico = t to &MaxAgeDeterministicoAtivos. - min(IddPartiCalc, IddConjuCalc);
				IddPartiDeter = min(IddPartiCalc + tDeterministico, &MaxAgeDeterministicoAtivos.);
				IddConjuDeter = min(IddConjuCalc + tDeterministico, &MaxAgeDeterministicoAtivos.);
				output;
			end;

			rename t = tCobertura;
			keep id_participante t tDeterministico IddPartiDeter IddConjuDeter id_bloco;
		run;
/*	end;*/
/*run;*/

%macro evolucaoDeterministicoAtivos;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(determin.deterministico_ativos&a.);
		data determin.deterministico_ativos&a.;
			set work.idade_deterministico_ativos(where=(id_bloco = &a.));

/*			if tCobertura = tDeterministico and IddPartiDeter = IddConjuDeter then delete;*/
		run;
	%end;
%mend;
%evolucaoDeterministicoAtivos;

/*
%macro evolucaoDeterministicoAtivos;
	%do a = 1 %to &numberOfBlocksAtivos.;
		%_eg_conditional_dropds(work.idade_deterministico_ativos);

		PROC IML;
			USE work.idade_cobertura_bloco;
				read all var {id_participante} into id_participante_cobert where (id_bloco = &a.);
				read all var {t} into t_cobert where (id_bloco = &a.);
				read all var {IddPartEvol} into IddPartEvol_cobert where (id_bloco = &a.);
				read all var {IddConjEvol} into IddConjEvol_cobert where (id_bloco = &a.);
			CLOSE;

			qtsObs = nrow(id_participante_cobert);

			if (qtsObs > 0) then do;
				qtdEvol = 0;
				b = 1;

				DO a = 1 TO qtsObs;
					idade = min(IddPartEvol_cobert[a], IddConjEvol_cobert[a]);
					qtdEvol = qtdEvol + ((&MaxAgeDeterministicoAtivos. - idade) + 1);
				END;

				id_participante = J(qtdEvol, 1, 0);
				tCobertura = J(qtdEvol, 1, 0);
				tDeterministico = J(qtdEvol, 1, 0);
				IddPartiDeter = J(qtdEvol, 1, 0);
				IddConjuDeter = J(qtdEvol, 1, 0);

				DO a = 1 TO qtsObs;
					idade = min(IddPartEvol_cobert[a], IddConjEvol_cobert[a]);

					DO t = t_cobert[a] to &MaxAgeDeterministicoAtivos. - idade;
						id_participante[b] = id_participante_cobert[a];
						tCobertura[b] = t_cobert[a];
						tDeterministico[b] = t;

						*------ Idade do participante na evolucao ------*;
						IddPartiDeter[b] = min(IddPartEvol_cobert[a] + t, &MaxAgeDeterministicoAtivos.);

						*------ Idade do conjuce na evolucao ------*;
						IddConjuDeter[b] = min(IddConjEvol_cobert[a] + t, &MaxAgeDeterministicoAtivos.);

						b = b + 1;
					END;
				END;

				create work.idade_deterministico_ativos var {id_participante tCobertura tDeterministico IddPartiDeter IddConjuDeter};
					append;
				close;
			end;
		QUIT;

		%_eg_conditional_dropds(determin.deterministico_ativos&a.);
		data determin.deterministico_ativos&a.;
			set work.idade_deterministico_ativos;
		run;
	%end;

	proc delete data = work.idade_deterministico_ativos;
%mend;
%evolucaoDeterministicoAtivos;*/
