# noinspection PyPep8Naming

from datetime import datetime, date

# class Sexo(object):
#     def __init__(self):
#         self.id = None
#         self.sexo = None


class Pessoa(object):
    def __init__(self, id, nome, sexo, data_nascimento, data_morte, invalido = False):
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
        if value in [1,2]:
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
        if value in (0, 1, False, True):
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
            print('Erro no valor da data morte.')
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
    def __init__(self, id, matricula, nome, sexo, data_nascimento, data_morte, invalido):
        super().__init__(id, nome, sexo, data_nascimento, data_morte, invalido)
        self.estadoCivil = 0
        self.matricula = matricula
        self.migrado = False
        self.plano = None
        self.patrocinadora = None
        self.situacaoPlano = None
        self.situacaoFundacao = None
        # self.conjuge = self.addConjuge(self.sexo, self.dataNascimento)
        self.sexoConjuge = 1
        self.idadeConjuge = 21

    @property
    def matricula(self):
        return self._matricula

    @matricula.setter
    def matricula(self, value):
        try:
            self._matricula = value
        except:
            print("Erro matricula.")

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
    def __init__(self, id, matricula, nome, sexo, data_nascimento, data_admissao, data_associacao, data_morte, pbe = 0.00, invalido = False):
        super().__init__(id, matricula, nome, sexo, data_nascimento, data_morte, invalido)
        # self.dataAdmissao = None
        # self.dataAssociacao = None
        self.beneficioSaldado = 0
        self.dataAdmissao = data_admissao
        self.dataAssociacao = data_associacao
        self.dataInicioContribuicaoINSS = None
        self.idadeAposentadoriaFundacao = 0
        self.idadeAposentadoriaINSS = 0
        self.idadeAdmissao = 0
        self.idadeAssociacao = 0
        self.percentualBeneficioEspecial = pbe
        self.percentualContribuicaoParticipante = 0
        self.percentualContribuicaoPatrocinadora = 0
        self.saldoContaParticipante = 0
        self.saldoContaPatrocinadora = 0
        self.tempoServicoAnos = 0
        self.tempoServicoMeses = 0
        self.tempoServicoDias = 0

    @property
    def dataAdmissao(self):
        return self._dataAdmissao

    @dataAdmissao.setter
    def dataAdmissao(self, value):
        try:
            if all([value is not None, len(value) == 10]):
                self._dataAdmissao = datetime.strptime(value, '%d/%m/%Y').date()
            else:
                self._dataAdmissao = None
        except:
            print("Erro data admissão.")

    @property
    def dataAssociacao(self):
        return self._dataAssociacao

    @dataAssociacao.setter
    def dataAssociacao(self, value):
        try:
            if all([value is not None, len(value) == 10]):
                self._dataAssociacao = datetime.strptime(value, '%d/%m/%Y').date()
            else:
                self._dataAssociacao = None
        except:
            print("Erro data associação.")

    @property
    def percentualBeneficioEspecial(self):
        return self._percentualBeneficioEspecial

    @percentualBeneficioEspecial.setter
    def percentualBeneficioEspecial(self, value):
        if isinstance(value, str):
            self._percentualBeneficioEspecial = float(value.replace(',', '.'))
        elif isinstance(value, int):
            self._percentualBeneficioEspecial = float(value)
        elif isinstance(value, float):
            self._percentualBeneficioEspecial = value
        else:
            self._percentualBeneficioEspecial = 0.00


class Assistido(Participante):
    def __init__(self, matricula_titular):
        pass
        self.dependente = None
        self.matriculaTitular = matricula_titular

    @property
    def matriculaTitular(self):
        return self._matriculaTitular

    @matriculaTitular.setter
    def matriculaTitular(self, value):
        try:
            self._matriculaTitular = value
        except:
            print("Erro matricula titular.")


class Avaliacao(object):

    def __init__(self, id, data_calculo, maioridade, cota_familiar):
        self.id = id
        self.dataCalculo = data_calculo
        self.maioridade = maioridade
        self.cotaFamiliar = cota_familiar
        self.despesaAdministrativaParticipante = None
        self.despesaAdministrativaPatrocinadora = None
        self.faixaContribuicao1 = None
        self.faixaContribuicao2 = None
        self.faixaContribuicao3 = None
        self.reajusteSalario = None
        self.reajusteBeneficioFundacao = None
        self.reajusteBeneficioINSS = None
        self.metaCusteio = None
        self.metaCusteioAdministrativo = None
        self.opcaoBUA = None
        self.saqueBUA = None
        self.peculioMorteAtivo = None
        self.peculioMorteAssistido = None
        self.saidaBPD = None
        self.saidaPortabilidade = None
        self.saidaResgate = None
        self.taxaAdministracaoBeneficio = None
        self.taxaCrescimentoBeneficio = None
        self.taxaCrescimentoSalarial = None
        self.beneficioMinimo = None # piso beneficio, menor valor para beneficio
        self.lx = None
        self.peculioMinimoMorte = None # piso peculio morte, menor valor para peculio por morte
        self.salarioCaixa = None # teto salario caixa
        self.salarioMinimo = None
        self.tetoBeneficioINSS = None
        self.tetoContribuicaoINSS = None
        self.planoBeneficio = None # id plano beneficio


    @property
    def dataCalculo(self):
        return self._dataCalculo

    @dataCalculo.setter
    def dataCalculo(self, value):
        try:
            if all([value is not None, len(value) == 10]):
                self._dataCalculo = datetime.strptime(value, '%d/%m/%Y').date()
            else:
                self._dataCalculo = None
        except:
            print("Erro data calculo avaliacao.")
