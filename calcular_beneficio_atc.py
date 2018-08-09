
import pandas as pd

CtFamPens = 0.8
NroBenAno = 13
FtBenEnti = 0.98
FtBenLiquido = 1
peculioMorteAssistido = 11.62
perct_saque_bua = 0
perct_opcao_bua = 0
CdPlanBen = 5
teto_contribuicao_inss = 5481.59
faixa_1 = 0.0
faixa_2 = 0.0
faixa_3 = 0.0

class AposentadoriaTempoContribuicao(object):
    def __init__(self):

    def calcularBeneficioTotal(self):


def calcularBeneficioTotalATC(row):
    benef_total_atc = 0

    if CdPlanBen == 1:
        benef_total_atc = max(0, row['SalConPrjEvol'] - row['SalProjeInssEvol'])

        if row['PeFatReduPbe'] > 0:
            benef_total_atc = max(0, benef_total_atc * row['PeFatReduPbe'])

        FtRenVitAtc = max(0, (row['axcb'] + CtFamPens * row['PrbCasado'] * (row['ajxcb'] - row['ajxx'])) * NroBenAno * FtBenEnti)

        if FtRenVitAtc > 0:
            benef_total_atc = max(benef_total_atc, ((row['VlSdoConPartEvol'] + row['VlSdoConPatrEvol']) / FtRenVitAtc) * FtBenEnti)
    elif CdPlanBen == 2:
        benef_total_atc = max(0, row['VlBenSaldado'] * FtBenLiquido * FtBenEnti)
    elif CdPlanBen == 4 or CdPlanBen == 5:
        FtRenVitAtc = max(0, (row['axcb'] + CtFamPens * row['PrbCasado'] * (row['ajxcb'] - row['ajxx'])) * NroBenAno * FtBenEnti + (row['Ax'] * peculioMorteAssistido))

        if FtRenVitAtc > 0:
            benef_total_atc = max(0, ((row['VlSdoConPartEvol'] + row['VlSdoConPatrEvol']) / FtRenVitAtc) * FtBenEnti)

    return round(benef_total_atc, 2)


def calcular_contribuicao(beneficio, teto_contribuicao_inss, faixa_1, faixa_2, faixa_3):
    contribuicao = 0

    if CdPlanBen == 1:
        contr1, contr2, contr3 = 0

        contr1 = min(beneficio, teto_contribuicao_inss / 2) * faixa_1

        if (beneficio > (teto_contribuicao_inss / 2)):
            contr2 = (min(beneficio, teto_contribuicao_inss) - (teto_contribuicao_inss / 2)) * faixa_2

        if (beneficio > teto_contribuicao_inss):
            contr3 = (beneficio - teto_contribuicao_inss) * faixa_3

        contribuicao = contr1 + contr2 + contr3

    return round(contribuicao, 2)


def calcular_beneficio_liquido_atc(beneficio_total, contribuicao, perct_opcao_bua, perct_saque_bua):
    benef_liquido_atc = max(0, (beneficio_total - contribuicao) * (1 - perct_opcao_bua * perct_saque_bua))
    return round(benef_liquido_atc, 2)


ativo = pd.read_csv("input_csv/30318/atc_ativos.csv", sep=",", decimal=".").drop(['id_bloco'], axis=1)

ativo['SalConPrjEvol'] = [float(x.replace(".","").replace(",", ".")) for x in ativo['SalConPrjEvol']]

ativo['SalProjeInssEvol'] = [float(x.replace(".","").replace(",", ".")) for x in ativo['SalProjeInssEvol']]

ativo['VlSdoConPartEvol'] = [float(x.replace(".","").replace(",", ".")) for x in ativo['VlSdoConPartEvol']]

ativo['VlSdoConPatrEvol'] = [float(x.replace(".","").replace(",", ".")) for x in ativo['VlSdoConPatrEvol']]

ativo['VlBenSaldado'] = [float(x.replace(".","").replace(",", ".")) for x in ativo['VlBenSaldado']]

ativo.dtypes

ativo.describe()

ativo.head()

ativo['beneficio_total_atc'] = ativo.apply(calcular_beneficio_total_atc, axis = 1)

ativo['contribuicao_beneficio_atc'] = [calcular_contribuicao(value, teto_contribuicao_inss, faixa_1, faixa_2, faixa_3) for value in ativo['beneficio_total_atc']]

ativo['beneficio_liquido_atc'] = [calcular_beneficio_liquido_atc(b, c, perct_opcao_bua, perct_saque_bua) for b, c in zip(ativo['beneficio_total_atc'], ativo['contribuicao_beneficio_atc'])]

ativo[['ID_PARTICIPANTE', 't', 'beneficio_total_atc', 'contribuicao_beneficio_atc', 'beneficio_liquido_atc']]
