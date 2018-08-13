import pandas as pd
import numpy as np
from datetime import date, datetime
from pandas import isnull

def convertToPercent(x):
    return (x / 100)

def convertToIndice(x):
    return ((x / 100) + 1)

def convertToBoolean(x):
    if isinstance(x, str):
        if x == 'S':
            return True
        else:
            return False
    elif isinstance(x, (int, float)):
        if x == 1:
            return True
        else:
            return False

# tipos de beneficios
aposent_normal = [149, 156, 492, 495, 503, 513, 514, 480, 479, 487, 517, 319, 252, 320, 318, 152]
aposent_especial = [154, 505]
aposent_invalidez = [159, 504, 521, 481, 251, 327, 160, 328, 161, 329]
pensao = [164, 338, 496, 497, 522, 488, 482, 325, 278, 324, 165, 326, 171]

def convertToTipoBeneficio(x):
    tipo = 0
    if x in aposent_normal:
        tipo = 1
    elif x in aposent_especial:
        tipo = 2
    elif x in aposent_invalidez:
        tipo = 3
    elif x in pensao:
        tipo = 4

    return int(tipo)


def calculateAge(data_nascimento, data_calculo):
    idade = 0

    try:
        if pd.notnull(data_nascimento) and pd.notnull(data_calculo):
            idade = int(data_calculo.year - data_nascimento.year - ((data_calculo.month, data_calculo.day) < (data_nascimento.month, data_nascimento.day)))
    except AttributeError as e:
        idade = -1

    return int(idade)

def calculateAgeDif(sexoPartic, idadePartic, difIdade):
    idadeCalculada = 0

    if sexoPartic == 'M':
        difIdade *= -1

    idadeCalculada = idadePartic + (difIdade)

    return idadeCalculada


def changeSexoDependenteNull(sexoPartic, sexoDepend):
    if isnull(sexoDepend):
        if sexoPartic == 'F':
            sexoDepend = 'M'
        else:
            sexoDepend = 'F'

    return sexoDepend


def changeNullToZero(value):
    if isnull(value):
        return 0
    else:
        return value


def getTipoAssistido(matriculaTitular):
    tipo = 0

    if isnull(matriculaTitular):
        # aposentado
        tipo = 1
    else:
        # pensionista
        tipo = 2

    return tipo


import csv
from models import Ativo

def getAtivoAll():
    file_name = 'data/participantes_cadastro_27597.csv'
    ativos = []

    with open(file_name, 'r') as csv_file:
        reader = csv.reader(csv_file, delimiter=';')
        next(reader)

        for row in reader:
            ativo = Ativo(row[0], row[7], row[2], row[9], row[15], row[14])
            ativos.append(ativo)

    return ativos


ativos = getAtivoAll()

for ativo in ativos[:10]:
    print(ativo, ativo.dataNascimento, ativo.idade)

