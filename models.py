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
        self.dataMorte = data_morte
        self.invalido = invalido
        self.idade = self.calcularIdade(self.dataNascimento, date(2018, 1, 1))

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
            if all([value is not None, len(value) == 10]):
                self._dataNascimento = datetime.strptime(value, '%d/%m/%Y').date()
            else:
                self._dataNascimento = None
        except ValueError:
            print('Erro formato data nascimento.')
        except:
            print("Erro inesperado na data nascimento.")

    @property
    def invalido(self):
        return self._invalido

    @invalido.setter
    def invalido(self, value):
        if (value in (0,1)):
            self._invalido = bool(value)
        else:
            self._invalido = False

    @property
    def dataMorte(self):
        return self._dataMorte

    @dataMorte.setter
    def dataMorte(self, value):
        try:
            if all([value is not None, len(value) == 10]):
                self._dataMorte = datetime.strptime(value, '%d/%m/%Y').date()
        except ValueError:
            print('Erro formato data morte.')
        except:
            print("Erro inesperado na data morte.")

    def calcularIdade(self, data_nascimento, data):
        try:
            return data.year - data_nascimento.year - ((data.month, data.day) < (data_nascimento.month, data_nascimento.day))
        except:
            print("Erro calculo idade.")

    def __str__(self):
        return self.nome


class Participante(Pessoa):
    def __init__(self, id, nome, sexo, data_nascimento, data_morte, invalido):
        super().__init__(id, nome, sexo, data_nascimento, data_morte, invalido)
        self.estadoCivil = 0
        self.patrocinadora = None
        self.migrado = False
        self.plano = None
        self.situacaoPlano = None
        self.situacaoFundacao = None
        # self.conjuge = self.addConjuge(self.sexo, self.dataNascimento)
        self.sexoConjuge = 1
        self.idadeConjuge = 21

    # @property
    # def conjuge(self):
    #     return self._conjuge
    #
    # @conjuge.setter
    # def conjuge(self, value):
    #     self._conjuge = Pessoa(None, None, value[0], None, None, False)
    #
    # def addConjuge(self, sexo, data_nascimento):
    #     sexo = 1 if sexo == 2 else 2
    #
    #     self.conjuge = (sexo, data_nascimento)


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



