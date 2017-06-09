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
    elif isinstance(x, int):
        if x == 1:
            return True
        else:
            return False
