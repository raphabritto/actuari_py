
# coding: utf-8

# In[2]:

import pandas as pd


# In[3]:

#df_aval = pd.read_csv('avaliacao.csv', ';', names = ['avaliacao', 'cadastro', 'plano_previdencia'])


# In[4]:

#df_aval = pd.read_table('avaliacao.csv', ';', names = ['avaliacao'])


# In[21]:

df_aval = pd.read_csv('avaliacao.csv', ';', decimal=',')


# In[22]:

del df_aval['DS_PLANO_BENEFICIO']


# In[23]:

nomes_colunas = {'ID_AVALIACAO': 'avaliacao', 'ID_CADASTRO': 'cadastro', 'IDPLANOPREV': 'plano_previdencia', 'ID_PLANO_BENEFICIO': 'plano_beneficio', 'DT_CALCULO': 'data_calculo'}


# In[24]:

df_aval = df_aval.rename(columns = nomes_colunas)


# In[32]:

df_aval


# In[26]:

df_aval.dtypes


# In[11]:

df_aval.isnull().values.any()


# In[12]:

def calculatePercent(x):
    if isinstance(x, str):
        if (x.count(',') == 1):
            x = x.replace(',', '.')
            x.astype(float)
    x /= 100
    return(x)


# In[27]:

df_aval['PC_FATOR_VLR_REAL_SALARIO'] = [calculatePercent(x) for x in df_aval['PC_FATOR_VLR_REAL_SALARIO']]


# In[28]:

df_aval['PC_FATOR_VLR_REAL_BEN_FUNCEF'] = [calculatePercent(x) for x in df_aval['PC_FATOR_VLR_REAL_BEN_FUNCEF']]


# In[29]:

df_aval['PC_FATOR_VLR_REAL_BEN_INSS'] = [calculatePercent(x) for x in df_aval['PC_FATOR_VLR_REAL_BEN_INSS']]


# In[30]:

df_aval['PC_OPCAO_BUA'] = [calculatePercent(x) for x in df_aval['PC_OPCAO_BUA']]


# In[18]:

#df_aval['avaliacao'].astype(int);


# In[31]:

df_aval['FL_MEMORIA_CALCULO'].astype(bool)


# In[ ]:

#df_aval = pd.read_csv('avaliacao.csv', ';', names = ['id_avaliacao', 'id_cadastro', 'id_plano_previdencia', 'id_plano_beneficio', 'plano', 'data_calculo', 'calcular_demonstrativo'])


# In[ ]:

#df_aval = pd.read_table('avaliacao.csv', ';', names = ['id_avaliacao', 'id_cadastro', 'id_plano_previdencia', 'id_plano_beneficio', 'plano', 'data_calculo', 'calcular_demonstrativo'])


# In[ ]:

#type(df_aval)


# In[ ]:

#df_aval.describe()


# In[ ]:

#df_aval.index


# In[ ]:

#df_aval.columns


# In[ ]:

#df_aval.values


# In[ ]:



