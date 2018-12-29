import pandas as pd
import numpy as np
from os import listdir
from os.path import isfile, join,dirname
import os
import datetime

now = datetime.datetime.now()

# file directory
fileDir = dirname(os.path.realpath('__file__'))
# Creo el log de errores con la fecha actual
fileOutput = os.path.join(fileDir, 'output')
file = open(os.path.join(fileOutput, "logErrores.txt"),"a") 
file.write("*************************************************************************\n") 
file.write(str(now)) 
file.close()

# @ fn: drop_duplis
# @ argin tabla: Tabla de una hoja de excel (bebidas gasesoas,isotonicas, etc)
# @ brief: Esta funciòn se encarga de borrar las marcas duplicadas (marca == anunciante). En caso que existan marcas con precios diferentes, se uqeda con le menor
# @ return: Retorna la tabla sin marcas repetidas

def drop_duplis(tbl):
    
    aux = tbl.iloc[6:,0]
    
    if(aux[aux.duplicated()].empty == False):
        aux2 = tbl.iloc[6:,:]
        aux2.columns = ['a','b']
        aux2 = aux2.sort_values(by = ['a','b'],
                                ascending = True).drop_duplicates(subset = ["a"])
        aux2.columns = tbl.columns
        #print(aux[aux.duplicated()].unique(),tbl.iloc[2,1],tbl.iloc[3,0],tbl.iloc[0,1])
        
        return pd.concat([tbl.iloc[0:6,:],aux2])
    else:
        return tbl

# @ fn: get_tabla
# @ argin tabla: hoja de excel en forma de tabla
# @ argin excel: nombre del file que levantò
# @ argin sheet: nombre de la hoja que levantò
# @ brief: Esta funciòn se encarga de levantar todas las tablas (recuadros dentro de la tabla de Nielsen) y ponerlas en forma de lista
# @ return: retorna una lista de Dataframes que representan cada tabla de la Sheet de Nielsen

def get_tabla(tabla,excel_name,sheet,fileDir):
    
    col_names_index = [i for i,x in enumerate(tabla.columns) if (("Unnamed" not in x) & ("NABS" not in x) & ("Dummy" not in x)) ]
    col_names_index.pop(0)
    
    table_aux= pd.DataFrame(np.array(tabla.columns).reshape(1,tabla.shape[1]), columns = tabla.columns.values.tolist())
    tabla = pd.concat([table_aux,tabla])
    
    set_tablas = []
    # Recorro todas las columnas relevantes (que no tengan la palabra Unnamed,NABS o Dummy)
    # Busco el campo mes, el cual se repite siempre un numero par de veces. Caso contrario, hubo una inconsistencia
    for index_col in col_names_index:  
            
        aux = tabla.iloc[:,index_col]
        index_mes = np.where(aux == aux.iloc[2])[0]       
        
        if(len(index_mes) == 2):    
            pos_NotNa = np.where(~ tabla.iloc[:,index_col].isna())[0]
            set_tablas.append(tabla.iloc[index_mes[0] - 2: pos_NotNa[len(pos_NotNa)-1]+1,
                                       index_col-1:index_col+1])
        elif(len(index_mes) == 4):
             pos_NotNa = np.where(~ tabla.iloc[:,index_col].isna())[0]
             index2 = pos_NotNa[pos_NotNa < index_mes[2] - 2][-1]
             set_tablas.append(tabla.iloc[index_mes[0] - 2:index2+1,index_col-1:index_col+1])  # primer tabla de la columna
             set_tablas.append(    # segunda tabla de la columna    
                     tabla.iloc[index_mes[2] - 2: pos_NotNa[len(pos_NotNa)-1]+1,index_col-1:index_col+1])            
        else: # Si detecta un numero de tablas impar, no puede disernir y avisa!
            print("error en: ",excel_name,sheet,tabla.columns[index_col])
            
            fileOutput = os.path.join(fileDir, 'output/')
            file = open(os.path.join(fileOutput, "logErrores.txt"),"a") 
            file.write("\nError en: " + excel_name + sheet + tabla.columns[index_col] + "\n")
            file.close()
           
            return set_tablas # aborto!
           
    return set_tablas

# @ fn: get_parcial_table
# @ argin tabla: Tabla de una hoja de excel (bebidas gasesoas,isotonicas, etc)
# @ brief: Parsea la tabla trasnformandola a Dataframe
# @ return: Dataframe parseado.

def get_parcial_table(tbl):
    
    categoria = tbl.iloc[0,1]
    total = tbl.iloc[3,1]
    tipo_venta = tbl.iloc[1,1]
    mes = tbl.iloc[2,1]
    pais =  tbl.iloc[3,0]
    
    marca_valor = tbl.iloc[6:,1].tolist()
    marca_name = tbl.iloc[6:,0].tolist()
    
    tbl_aux = []
    
    for i in range(len(marca_valor)):
        tbl_aux.append({"PAIS": pais,"MES":mes,"CATEGORIA":categoria,
                        "TIPO_VENTA":tipo_venta,"MARCA":marca_name[i],
                        "VALOR":marca_valor[i],"TOTAL":total})
    return tbl_aux

#################################################################################################
#___________________________________ Main ______________________________________________________
################################################################################################ 
    
# 1.________________________________ Levanto todas las tablas __________________________________

# Recorro todos los excels y sheets y extraigo todas las tablas existentes en cada sheet
    
tabla_master = []

#nombres_files = ["Reporte Flash Share SLBU - AGO 2017.xls","Reporte Flash Share SLBU - JUL 2017.xls",
#"Reporte Flash Share SLBU - Oct 2017.xls","Reporte Flash Share SLBU Abr 2017.xls",
#"Reporte Flash Share SLBU Category - Nov 2017.xls","Reporte Flash Share SLBU DIC 2016.xls",
#"Reporte Flash Share SLBU ENE 2017.xls", "Reporte Flash Share SLBU FEB 2016.xls",
#"Reporte Flash Share SLBU JUN 2017.xls","Reporte Flash Share SLBU MAR 2017.xls",
#"Reporte Flash Share SLBU Mayo 2017.xls"]

fileInput = os.path.join(fileDir, 'input/')

nombres_files = [f for f in listdir(fileInput)
                         if ((".xls" in f) & (f[0] != ".") & (f[0] != "~") )]

# cada entrada de la lista general contiene las tablas de una sheet
for files in nombres_files:
    xls = pd.ExcelFile(os.path.join(fileInput,files), on_demand = True)
    sheets = xls.sheet_names # extrae todos los nombres de las sheets de este excel
    sheets = [x for x in sheets  if (("WSP" in x) & ("WSP_TOC" not in x))]
    for sheet in sheets:
        tabla = pd.read_excel(os.path.join(fileInput,files),sheet_name = sheet)
        tabla_master.append(get_tabla(tabla,files,sheet,fileDir))

# 2.__________________________________________ Parseo __________________________________________ 

# Parseo todas las tablas moviendome en x,y para sacar pais,marcas,etc 
# El producto final es un Dataframe gigante
        
master_dataframe = []

i = 0
j = -1

for lTbl in tabla_master:
    j = j +1
    i = 0
    for tbl in lTbl:
        
        #print("i",i)
        i = i + 1
       # print ("j",j)
        if((j == 2) & (i == 1)):
            a = 1
        master_dataframe.append(get_parcial_table(tbl))  
        
csv_data = pd.DataFrame([item for sublist in master_dataframe for item in sublist])  

# 3.__________________________________________  Me creo un warning con la data que voy a dropear _______________
   
subdata = csv_data.loc[csv_data["MARCA"].isna()]

vect_na = np.array([str(type(x)) for x in subdata["VALOR"]])

if(vect_na.size > 0):  # Si no hay warnings que los saltee
    pos_vect_na = np.where(vect_na == str(float))[0]
    
    if (str(float) in vect_na):
        print("Warning. Borrando data con valores en:",
              subdata[['CATEGORIA', 'MES', 'PAIS', 'TIPO_VENTA',"VALOR"]].iloc[pos_vect_na])
    
    # Escribo el warining en un log
    
    fileOutput = os.path.join(fileDir, 'output/')
    file = open(os.path.join(fileOutput, "logErrores.txt"),"a")  
    file.write("\nWarnings: \n") 
    file.close()
    
    df = subdata[['CATEGORIA', 'MES', 'PAIS', 'TIPO_VENTA',"VALOR"]].iloc[pos_vect_na]
    df.to_csv(os.path.join(fileOutput, "logErrores.txt"), header=None, index=None, sep=' ', mode='a')

csv_data = csv_data.loc[~csv_data["MARCA"].isna()]

# 4.__________________________________________  normalizacion __________________________________________ 

# @ fn: normalizacion
# @ argin tabla: Tabla de una hoja de excel (bebidas gasesoas,isotonicas, etc)
# @ argin colname_normalizado: Nombre de la columna en el file que contiene la palabra con la que se va a reemplazar
# @ argin colname_normalizador: Nombre de la columna en el file que contiene la palabra a reemplazar
# @ argin sheetName: nombre de la hoja donde esta la tabla de normalizacion
# @ argin FileNormalizador: nombre del file donde estan las tablas normalizadoras
# @ brief: Normaliza los campos de Tabla especificados en el archivo FileNormalizador
# @ return: Dataframe con campos normalizado

debug = csv_data
def normalizacion(tabla,colname_normalizado,colname_normalizador,sheetName,FileNormalizador,col_replace):
    
    tabla_normalizadora = pd.read_excel(FileNormalizador,sheet_name = sheetName)
    ventas = tabla_normalizadora[colname_normalizado].unique()

    for venta in ventas:
        desnorm = tabla_normalizadora.loc[tabla_normalizadora[colname_normalizado] == venta]
        [tabla[col_replace].replace(x,venta,inplace = True) for x in desnorm[colname_normalizador]]

def func_split_month(x):
    x.ANO = x.MES.split[1]
    x.MES = x.MES.split[0]
    return x
        
normalizacion(csv_data,"Tipo_Venta_Normalizado","Tipo_Venta","Venta","NormalizadorPais_Python.xlsx","TIPO_VENTA")
normalizacion(csv_data,"Pais_normalizado","Pais","Pais","NormalizadorPais_Python.xlsx","PAIS")

csv_data["ANO"] = csv_data["MES"] # Agrego el campo año para cargar el año normalizado 
csv_data["ANO"] = csv_data["MES"].apply(lambda x: x.split()[1])
csv_data["MES"] = csv_data["MES"].apply(lambda x: x.split()[0])

# Paso a numeric. OJO: si falla aca ver donde convierto mal el año!!

normalizacion(csv_data,"Mes_Normalizado_Numerico","Mes","Mes","NormalizadorPais_Python.xlsx","MES")

csv_data["ANO"] = pd.to_numeric(csv_data["ANO"], errors='coerce')
csv_data["MES"] = pd.to_numeric(csv_data["MES"], errors='coerce')

# Como necesito 2 csv: uno con los valores totales y otro con los porcentajes de cada marca.
# csv_tabla_total representa la tabla de totales. Hago un drop duplicates porque parto de una
# tabla generica donde el campo total se replica la misma cantidad de veces que marcas haya en la tabla
csv_tabla_total = csv_data.drop_duplicates(subset = ["TOTAL","CATEGORIA","MES","PAIS","ANO"])
csv_tabla_total = csv_tabla_total.drop(["VALOR"],axis = 1)

csv_data = csv_data.drop(["TOTAL"],axis = 1)  # dropeo la cloumna que esta de mas

# 5.__________________________________________ Melt __________________________________________ 

# sorteo para que me quede una linea valor peso y la de abajo valor unit
csv_data = csv_data.sort_values(by = ["CATEGORIA","MARCA","MES","PAIS","ANO"])
csv_tabla_total = csv_tabla_total.sort_values(by = ["CATEGORIA","MARCA","MES","PAIS","ANO"])
csv_tabla_total = csv_tabla_total.drop(["MARCA"],axis = 1) # no tiene sentido marca en este dataframe, son solo totales

# como estan ordenados, extraigo ventas y volumn y despes los joineo.
# Hago lo mismo para csv_data y csv_tabla_total
tabla1 = csv_data[csv_data["TIPO_VENTA"] == "ventas unit cases ('000)"]
tabla1 = tabla1.drop(["TIPO_VENTA"],axis = 1)
tabla11 = csv_tabla_total[csv_tabla_total["TIPO_VENTA"] == "ventas unit cases ('000)"]
tabla11 = tabla11.drop(["TIPO_VENTA"],axis = 1)

# rename
tabla1.columns = ['CATEGORIA', 'MARCA', 'MES', 'PAIS', "ventas unit cases ('000)", 'ANO']
tabla11.columns = ['CATEGORIA', 'MES', 'PAIS', "ventas unit cases ('000)", 'ANO']

tabla2 = csv_data[csv_data["TIPO_VENTA"] == "ventas en valores pesos ('000)"]
tabla2 = tabla2.drop(["TIPO_VENTA"],axis = 1)
tabla22 = csv_tabla_total[csv_tabla_total["TIPO_VENTA"] == "ventas en valores pesos ('000)"]
tabla22 = tabla22.drop(["TIPO_VENTA"],axis = 1)

tabla2.columns = ['CATEGORIA', 'MARCA', 'MES', 'PAIS', "ventas en valores pesos ('000)", 'ANO']
tabla22.columns = ['CATEGORIA', 'MES', 'PAIS', "ventas en valores pesos ('000)", 'ANO']

# join
result = pd.merge(tabla1, tabla2, how = "outer", on=["CATEGORIA","MARCA","MES","PAIS","ANO"])
result_Total = pd.merge(tabla11, tabla22, how = "outer", on=["CATEGORIA","MES","PAIS","ANO"])

# 6.__________________________________________ Saco los Nans __________________________________________

#debido a que hubo una franja en blanco o algo atipico en la tabla
result["ventas en valores pesos ('000)"] = pd.to_numeric(result["ventas en valores pesos ('000)"],errors='coerce')   
result["ventas unit cases ('000)"] = pd.to_numeric(result["ventas unit cases ('000)"] ,errors='coerce')   
result = result.dropna()

result_Total.columns = ['CATEGORIA',	'MES',	'PAIS'	,'VENTAS_UNIT',	'ANO',	'VENTAS_PESOS']
# output 
#result.to_excel(os.path.join( fileOutput, "output_SalesKo.xls"),index= False)
result_Total.to_excel(os.path.join(fileOutput, "output_SalesKoTotal.xls"),index = False)

# 7._________________________________ Detecto Anunciantes y Anunciantes qu deben pasar a ser marca__________________________________________

data = result

# Dropeo las marcas que son tipo anunciantes (engloban a algunas marcas)
data = data.loc[data["MARCA"] != "CCTM"]
data = data.loc[data["MARCA"] != "CEPITA"]
data = data.loc[data["MARCA"] != "WATTS TM"]
data = data.loc[data["MARCA"] != "ANDINA TM"]

data["ind"] = data.index.values # le pongo un indice para traquear errores

# Levanto las tablas - Esto va a ser desde SQL
tabla_aunciantes = pd.read_csv("tabla_aunciantes2.csv",sep = ";")
tabla_marcas = pd.read_csv("tabla_marcas2.csv",sep = ";")

# Detecto Marcas/anunciantes no cargados en las tablas!
data_marcas_non = pd.merge(data,tabla_marcas,how = "left", on=["CATEGORIA","MARCA","PAIS"])
data_marcas_non["ANUNCIANTE NIELSEN"] = data_marcas_non["ANUNCIANTE NIELSEN"].astype(str)
data_marcas_non = data_marcas_non.loc[data_marcas_non["ANUNCIANTE NIELSEN"] == "nan"]
data_marcas_non = data_marcas_non.drop(["ANUNCIANTE NIELSEN"],axis = 1)
data_marcas_non = pd.merge(data_marcas_non,tabla_aunciantes,how = "left", 
                           left_on=["CATEGORIA","MARCA","PAIS"],right_on = ["CATEGORIA","ANUNCIANTE NIELSEN","PAIS"])
data_marcas_non["ANUNCIANTE NIELSEN"] = data_marcas_non["ANUNCIANTE NIELSEN"].astype(str)
data_marcas_non = data_marcas_non.loc[data_marcas_non["ANUNCIANTE NIELSEN"] == "nan"]

fileOutput = os.path.join(fileDir, 'output')
data_marcas_non.to_excel(os.path.join(fileOutput, "Marcas Desconocidas " + str(now.day) + 
                                      str(now.month) + str(now.year) +  ".xls"))  

# Cruzo las marcas que tengo guardadas con la bajada de Nielsen. Mismo para anunciantes
data_marcas = pd.merge(data,tabla_marcas,how = "inner", on=["CATEGORIA","MARCA","PAIS"])
data_anunciante = pd.merge(data,tabla_aunciantes,how = "inner", left_on=["CATEGORIA","MARCA","PAIS"],
                           right_on = ["CATEGORIA","ANUNCIANTE NIELSEN","PAIS"])

## Me fijo cuantos anunciantes repetidos encuentro y discrimino entre "anunciante anunciante" y "anunciante marca"
op = data_anunciante.groupby(["CATEGORIA","MES","PAIS","MARCA","ANO"]).count()
op = op[op.ind > 1]
op["aux"] = op.index.values

aux = []
aux2 = []

ind_max = data.ind.max()
for index,x in op.iterrows():
    
    ind_max = ind_max + 1
    cate = index[0]; mes = int(index[1]); pais = index[2];marca = index[3];ano = int(index[4])
    data_iter = data_anunciante.loc[(data_anunciante.CATEGORIA == cate) & 
                        (data_anunciante.MES == mes) &
                        (data_anunciante.PAIS == pais) & 
                        (data_anunciante.MARCA == marca) &
                        (data_anunciante.ANO == ano)]
    
    # los minimos son los anunciantes que pasan a ser marca
    aux.append({'CATEGORIA': cate, 'MARCA': "VARIOS_" + marca , 'MES': mes
                ,'PAIS': pais,  "ventas unit cases ('000)": data_iter["ventas unit cases ('000)"].min(),
                'ANO': ano,"ventas en valores pesos ('000)":  data_iter["ventas en valores pesos ('000)"].min(),
                'ind' : ind_max,"ANUNCIANTE NIELSEN": marca })
    
    # Los anunciantes son los maximos
    aux2.append({'CATEGORIA': cate, 'MARCA': marca , 'MES': mes
                ,'PAIS': pais,  "ventas unit cases ('000)": data_iter["ventas unit cases ('000)"].max(),
                'ANO': ano,"ventas en valores pesos ('000)":  data_iter["ventas en valores pesos ('000)"].max(),
                'ind' : ind_max,"ANUNCIANTE NIELSEN": marca })   
    
    # dropeo las filas donde hay duplicados de anunciante!
    data_anunciante = data_anunciante.loc[~((data_anunciante.CATEGORIA == cate) & 
                        (data_anunciante.MES == mes) &
                        (data_anunciante.PAIS == pais) & 
                        (data_anunciante.MARCA == marca) &
                        (data_anunciante.ANO == ano))]
    
marcas_add = pd.DataFrame(aux)
new_anunciantes = pd.DataFrame(aux2)

if(marcas_add.shape[0] != 0): # en caso de que no haya casos de repetidos salteo la parte de carga de anunciante-marca
    marcas_add = marcas_add[data_marcas.columns]
    data_anunciante = data_anunciante[new_anunciantes.columns]
    
    # le agrego los anunciantes nuevamnete y los nuevos anunciantes-marca a la tabla de marcas
    data_anunciante = data_anunciante.append(new_anunciantes)
    data_marcas = data_marcas.append(marcas_add)

######

tabla_excepciones = pd.read_excel("tabla_excepciones.xlsx")

# el tema de las marcas es que si tienen 2 anunciantes no podes discriminar e identificar marcas. Para eso lo que haces es volver a joinearla con los anunciantes existentes
data_anunciante_aux = data_anunciante[["CATEGORIA","ANUNCIANTE NIELSEN","PAIS","MES","ANO"]]
data_marcas2 = pd.merge(data_marcas,data_anunciante_aux,how = "inner", left_on=["CATEGORIA","ANUNCIANTE NIELSEN","PAIS","MES","ANO"],
                           right_on = ["CATEGORIA","ANUNCIANTE NIELSEN","PAIS","MES","ANO"])

# Levanto una tabla de excepciones con las marcas que para un cierto tiempo tuvieron un anunciante y despues cambiaron a otro que siempre esta en el excel de Nielsen. Ej: anunciante KO y Unilever (ADES)
def foo(x):

    aux = tabla_excepciones.loc[(tabla_excepciones.MARCA == x.MARCA) & (tabla_excepciones.CATEGORIA == x.CATEGORIA) & (tabla_excepciones.PAIS == x.PAIS)]
        
    if((x.MES >= aux.MES.values) & (x.ANO >= aux.ANO.values)):
        x["ANUNCIANTE NIELSEN"] = aux["ANUNCIANTE NIELSEN"].values[0]  
    else:
        x["ANUNCIANTE NIELSEN"] = aux["ANUNCIANTE NIELSEN MENORES"].values[0]
        
    return x
        
for x in tabla_excepciones.MARCA.unique():
    data_marcas2.loc[data_marcas2.MARCA == x] = data_marcas2.loc[data_marcas2.MARCA == x].apply(foo,axis = 1 )
 
ind_dupli = data_marcas2[data_marcas2.ind.duplicated()].ind
data_marcas2 = data_marcas2.drop_duplicates(subset = ["ind"])  # dropeo por indice
    
data_marcas = data_marcas2
data_anunciante.ind = data_anunciante.index.values

# Le hago un left join para traerme los anunciantes que aparecen en la tabla Nielsen pero que no hay ninguna marca que tenga ese anunciante, entonces ese anunciante debe ser una marca tipo varios
data_anunciantesMarca = pd.merge(data_anunciante,data_marcas,how = "left", 
                                 left_on=["CATEGORIA","ANUNCIANTE NIELSEN","PAIS","MES","ANO"],
                                 right_on = ["CATEGORIA","ANUNCIANTE NIELSEN","PAIS","MES","ANO"])

data_anunciantesMarca.MARCA_y = data_anunciantesMarca.MARCA_y.astype(str)
data_anunciantesMarca = data_anunciantesMarca.loc[data_anunciantesMarca.MARCA_y == "nan"]
data_anunciantesMarca = data_anunciantesMarca [['CATEGORIA', 'MARCA_x', 'MES', 'PAIS', "ventas unit cases ('000)_x",
       'ANO', "ventas en valores pesos ('000)_x", 'ANUNCIANTE NIELSEN' ]]
       
data_anunciantesMarca.columns = ['CATEGORIA', 'MARCA', 'MES', 'PAIS', "VENTAS_UNIT", 'ANO',
       "VENTAS_PESOS", 'ANUNCIANTE NIELSEN']

# Le agrego un varios a los anunciantes que ahora van a ser marcas

data_anunciantesMarca.MARCA = data_anunciantesMarca.MARCA.apply(lambda x: "VARIOS_" + x)

data_marcas.drop(["ind"],axis = 1,inplace = True)
data_marcas.columns = ['CATEGORIA', 'MARCA', 'MES', 'PAIS', "VENTAS_UNIT", 'ANO',
       "VENTAS_PESOS", 'ANUNCIANTE NIELSEN']

data_final = data_marcas.append(data_anunciantesMarca,ignore_index = True)

# Sumo por cada tabla de Nielsen tods los parciales de las marcas, Deberían sumar 100%
resu = data_final.groupby(['CATEGORIA', 'MES', 'PAIS','ANO'])["VENTAS_PESOS"].sum()
resu = resu.reset_index()

fileOutput = os.path.join(fileDir, 'output')
data_final.to_excel(os.path.join(fileOutput, "OutputSaleKO " + str(now.day) + 
                                      str(now.month) + str(now.year) +  ".xls"),index = False) 

fileOutput = os.path.join(fileDir, 'output')
resu.to_excel(os.path.join(fileOutput, "SumaCategorias " + str(now.day) + 
                                      str(now.month) + str(now.year) +  ".xls"),index = True)    

#resu_final = pd.DataFrame({'indice':resu.index.values.tolist(),'sumatoria':resu.values.tolist()})
#resu_final.to_excel(os.path.join(fileOutput, "SumaCategorias " + str(now.day) + 
#                                      str(now.month) + str(now.year) +  ".xls"),index = True)    
