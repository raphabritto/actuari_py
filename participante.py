
class Participante(object):
    def __init__(self):
        print('contruindo a classe participante')

class Ativo(Participante):
    def __init__(self):
        super().__init__()


ativo = Ativo()
