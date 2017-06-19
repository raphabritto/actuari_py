from datetime import date, datetime
import pandas as pd
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

from dateutil import parser

def calculateAge(data_nascimento, data_calculo):
    # dias_ano = 365.25
    idade = 0

    try:
        if not isnull(data_nascimento):
            # data_calculo = date.strftime(data_calculo[0], '%Y-%m-%d')
                # datetime(data_calculo.values, '%Y-%m-%d')
                # datetime.strftime(parser.parse(data_calculo), '%Y-%m-%d')
            idade = int(data_calculo.year - data_nascimento.year - ((data_calculo.month, data_calculo.day) < (data_nascimento.month, data_nascimento.day)))
    except AttributeError as e:
        idade = -1

    return idade


def changeNullToZero(value):
    if isnull(value):
        return 0
    else:
        return value