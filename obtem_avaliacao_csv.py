


import random

qtd_try = 0

apostas = []

for i in range(10):
    facil = random.sample(range(1, 26), 15)
    facil.sort()
    qtd_match = set(a).intersection(set(b))
    apostas.append(facil)


apostas


# In[88]:

apostas[0]


# In[80]:

a = list(range(1,6))


# In[81]:

a


# In[82]:

b = list(range(1,13, 2))


# In[83]:

b


# In[86]:

c = set(a) & set(b)


# In[87]:

c


# In[85]:

set(a).intersection(set(b))


# In[65]:

facil = random.sample(range(1, 26), 15)


# In[ ]:




# In[ ]:




# In[66]:

type(facil)


# In[67]:

facil


# In[68]:

facil.sort()


# In[69]:

print(facil)

