rm(list=ls())
gc()
# Rprof(tmp<-tempfile())
source("init.R")


# Parametros --------------------------------------------------------------

#Aqui se declaran como variables la rutas que se utilizaran para leer los archivos
#y otros parametros que sean importantes
model.path="models/modeloRfTemplate.RDS"
files=c(tabla1= "data_template/validation.csv")

# Reading and combining Data ----------------------------------------------


#se cargan los archivos
calibration=readRDS(model.path)
features=attr(calibration,"features")# o features=getFeatures(features.file)
dataset=readDataset(files = files, features.list = features, sep = ",")


#se arman nuevos grupos a partir de los grupos anteriores indicando el porcentaje que se va a cada grupo nuevo
# sin necesidad de tomar el 100% de los registros 

dataset=splitGroups(dataset=dataset,groups=c("tabla1"),splitter=c("execute_group"=1))


# Transforming data with features ------------------------------------

#se remplazan los nulos de las columnas con el valor que se indique en features para cada columna 
dataset=replaceNullFeatures(dataset)

#Se fuerzan las clases para las columnas segun features
dataset=forceClass(dataset)

#Para las variables que se forzaron a factores se conservan un limite de niveles
#establecido en features, se conservan solo aquellos niveles con los que se ha calibrado el modelo.
dataset=limitFactors(dataset)

#Aplica las operaciones declaradas en script para cada columna, si alguna operacion utiliza un valor 
# especifico, debe ser declarado con el mismo nombre antes de este paso.
# Lo que hace es aplicar transform(dataset,col="script") en cada variable que tenga un "script" 
dataset=featuresScript(dataset)


# Prediction --------------------------------------------------------------

score=predictBDA(calibration = calibration,
                 dataset = dataset,
                 subset="execute_group",
                 type="prob")



head(score)

# Uploading Scores to analytics DB --------------------------------------------------------

#saveScore(score = score, description = "data_prediction_template's example score" )



