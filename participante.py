from datetime import datetime, date

class Participante(object):
    def __init__(self, id, nome, sexo, data_nascimento):
        # print('contruindo a classe participante')
        self.nome = nome
        self.data_nascimento = datetime.strptime(data_nascimento, '%d/%m/%Y').date()
        self.idade = self.calcularIdade(self.data_nascimento, date(2018, 1, 1))

    def calcularIdade(self, data_nascimento, data):
        return data.year - data_nascimento.year - ((data.month, data.day) < (data_nascimento.month, data_nascimento.day))
