from datetime import date
# import pandas as pd
from pandas import isnull, NaT

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

def calculateAge(born, today):
    try:
        # if isinstance(born, date):
        if not born.isnull():
            if isinstance(born, date):
                born = date.strftime()
                return int(today.year - born.year - ((today.month, today.day) < (born.month, born.day)))
            else:
                return -1
        else:
            return 0
    except AttributeError as e:
        # print('Erro: ', e)
        return -2

def changeNullToZero(value):
    if isnull(value):
        return 0
    else:
        return value