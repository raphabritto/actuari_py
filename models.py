# noinspection PyPep8Naming

from datetime import datetime, date

# class Sexo(object):
#     def __init__(self):
#         self.id = None
#         self.sexo = None


class Pessoa(object):
    def __init__(self, id, nome, sexo, data_nascimento, data_morte, invalido):
        self.id = id
        self.nome = nome
        self.sexo = sexo
        self.dataNascimento = data_nascimento
        self.idade = self.calcularIdade(self.dataNascimento, date(2018, 1, 1))
        self.invalido = bool(invalido)
        self.dataMorte = data_morte

    @property
    def sexo(self):
        return self._sexo

    @sexo.setter
    def sexo(self, value):
        if (value in [1,2]):
            self._sexo = value
        else:
            self._sexo = None

    @property
    def dataNascimento(self):
        return self._dataNascimento

    @dataNascimento.setter
    def dataNascimento(self, value):
        try:
            self._dataNascimento = datetime.strptime(value, '%d/%m/%Y').date()
        except ValueError:
            print('Erro formato da data')
        except:
            print("Erro inesperado.")

    def __str__(self):
        return self.nome

    def calcularIdade(self, data_nascimento, data):
        try:
            return data.year - data_nascimento.year - ((data.month, data.day) < (data_nascimento.month, data_nascimento.day))
        except:
            print("Erro calculo idade")
        # return 0


class Participante(Pessoa):
    def __init__(self, id, nome, sexo, data_nascimento, data_morte, invalido):
        super().__init__(id, nome, sexo, data_nascimento, data_morte, invalido)
        self.estadoCivil = 0
        self.conjuge = None
        self.patrocinadora = None
        self.migrado = False
        self.plano = None
        self.situacaoPlano = None
        self.situacaoFundacao = None


class Ativo(Participante):
    def __init__(self, id, nome, sexo, data_nascimento, data_morte, invalido):
        super().__init__(id, nome, sexo, data_nascimento, data_morte, invalido)
        self.dataAdmissao = None
        self.dataAssociacao = None
        self.percentualBeneficioEspecial = 0
        self.tempoServicoAnos = 0
        self.tempoServicoMeses = 0
        self.tempoServicoDias = 0


class Assistido(Participante):
    def __init__(self, arg):
        pass
        self.dependente = None


# ativo = Ativo('fulano', 2, '01/01/1990', None , 0)
# print(ativo.nome)
# print(ativo.dataNascimento)
# print(type(ativo.dataNascimento))
# print(ativo.idade)
# print(ativo.invalido)
# print(ativo.sexo)

