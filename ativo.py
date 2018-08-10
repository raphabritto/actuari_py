from participante import Participante

class Ativo(Participante):
    def __init__(self, nome, data_nascimento):
        super().__init__(nome, data_nascimento)
        # self.nome = nome


ativo = Ativo('fulando', '01/01/1990')
print(ativo.nome)
print(ativo.data_nascimento)
print(type(ativo.data_nascimento))
print(ativo.idade)
