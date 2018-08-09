from datetime import datetime, date

class Participante(object):
    def __init__(self, nome, data_nascimento):
        # print('contruindo a classe participante')
        self.nome = nome
        self.data_nascimento = datetime.strptime(data_nascimento, '%d/%m/%Y').date()
        self.idade = self.calcularIdade(self.data_nascimento, date(2018, 1, 1))

    def calcularIdade(self, data_nascimento, data):
        return data.year - data_nascimento.year - ((data.month, data.day) < (data_nascimento.month, data_nascimento.day))



class Ativo(Participante):
    def __init__(self, nome, data_nascimento):
        super().__init__(nome, data_nascimento)
        # self.nome = nome


ativo = Ativo('fulando', '01/01/1990')
print(ativo.nome)
print(ativo.data_nascimento)
print(type(ativo.data_nascimento))
print(ativo.idade)
