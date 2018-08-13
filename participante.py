from datetime import datetime, date

class Pessoa(object):
    def __init__(self, nome, data_nascimento, invalido):
        self.nome = nome
        self.dataNascimento = datetime.strptime(data_nascimento, '%d/%m/%Y').date()
        self.idade = self.calcularIdade(self.dataNascimento, date(2018, 1, 1))
        self.invalido = bool(invalido)
        self.dataMorte = None

    def calcularIdade(self, data_nascimento, data):
        return data.year - data_nascimento.year - ((data.month, data.day) < (data_nascimento.month, data_nascimento.day))


class Participante(Pessoa):
    def __init__(self, nome, data_nascimento, invalido):
        super().__init__(nome, data_nascimento, invalido)
        self.estadoCivil = 0
        self.conjuge = None
        self.patrocinadora = None


class Ativo(Participante):
    def __init__(self, nome, data_nascimento, invalido):
        super().__init__(nome, data_nascimento, invalido)
        self.dataAdmissao = None
        self.dataAssociacao = None
        self.percentualBeneficioEspecial = None


class Assistido(Participante):
    def __init__(self, arg):
        pass
        self.dependente = None


ativo = Ativo('fulando', '01/01/1990', 0)
print(ativo.nome)
print(ativo.dataNascimento)
print(type(ativo.dataNascimento))
print(ativo.idade)
print(ativo.invalido)
