rm(list = ls())
gc()
source("init.R")


# Parametros --------------------------------------------------------------

#Aqui se declaran como variables la rutas que se utilizaran para leer los archivos
#y otros parametros que sean importantes
files = c(train = "data_template/train.csv")
featuresFile = "data_template/features.tab"

# Features, update and get ------------------------------------------------

#aqui se actualizan las filas del Features para que correpondan con los nombres
# de las columnas de alguno de los set de datos, si no existe un "Features" crea uno
# lleno de 0's y NA's. Si ya existe uno, agrega la filas de las variables
# nuevas con 0's y NA's,  reordena las filas y elimina las filas de variables que no
# estan en el archivo leído para actualizar el Features
updateFeatures(dataset.file = files,
               features.file = featuresFile,
               ds.sep = ",",
               f.sep = "\t"
)

#En este punto creara una lista a partir del Features con la información necesaria para el resto del proceso
# por lo tanto el archivo features debe ser editado segun corresponda antes de seguir.
features = getFeatures(features.file = featuresFile, sep = "\t")

# Reading and splitting data ----------------------------------------------

# se juntan todos los datos en un unico dataframe que contiene todas las variables seleccionadas
# en features, y asigna NA's en las variables para los set de datos que carecían de ellas.
# Ademas se agrega una columna con el nombre del grupo al que pertenece cada registro
dataset = readDataset(files = files,
                      features.list = features,
                      sep = ",") 

#Se establencen los balanceos a comparar
responseRates=c(0.0195,0.0185,0.0175,0.0165)


# se balancean los grupos de entrenamiento segun alguna las tasas de respuesta
dataset_list =alply(responseRates,1, function(x){rebalance(dataset = dataset,
  subset = "train",
  responseRate = x,
  features = features)}
)

names(dataset_list)=responseRates# Esto es util para visualizacion

#se arman nuevos grupos a partir de cada dataset  
dataset_list = llply(dataset_list,
                     function(dataset) {
                       balancedSplitGroups(
                         dataset = dataset,
                         groups = "train",
                         splitter = c("train" = 0.8,
                                      "test" = 0.2)
                       )})

# Transforming data with features file ------------------------------------

dataset_list=llply(dataset_list,
                   function(dataset){
                     dataset = replaceNullFeatures(dataset = dataset)
                     dataset = forceClass(dataset = dataset)
                     dataset = limitFactors(dataset = dataset)
                     dataset = featuresScript(dataset = dataset)
                     # dummydataset = toDummyFeatures(dataset = dataset) #solo utilizar para modelos que lo requieran
                     return(dataset)
                   })



# Models calibraition and execution ---------------------------------------

#Se calibra un modelo para cada dataset

calibration = llply(dataset_list,
                    function(dataset) {
                      trainModel(
                        model = "rpart",
                        dataset = dataset,
                        subset = "train",
                        features = attr(dataset, "features"),
                        control = rpart.control(
                          minsplit = 10,
                          cp = 0.0001,
                          maxdepth = 9
                        )
                      )},.progress = "text")
                      
# se ejecuta el modelo para cada dataset 
score = alply(responseRates,
              1,
              function(x) {
                x = as.character(x)
                score = predictBDA(calibration = calibration[[x]],
                                   dataset = dataset_list[[x]],
                                   subset = "all")},.progress = "text")
names(score)=responseRates

# Comparing models ----------------------------------------------------------
train_scores=llply(score,function(x){x$train}) #se juntan los scores de entrenamiento de cada dataset en una lista

test_scores=llply(score,function(x){x$test}) #idem para los grupos de validacion



getAuc(train_scores)

getAuc(test_scores)

plota=rocPlot(test_scores,legendTitle = "balance",title = "Test Scores")
plotb=rocPlot(train_scores,legendTitle = "balance",title = "Training Scores")+ylim(0,1.25)

multiplot(plota,plotb)
# Saving the best model  ----------------------------------------------------------


# saveModel(calibration = ,
#           file="models/filename.RDS",
#           features = attr(calibration,"features"))




# Uploading Scores to analytics DB --------------------------------------------------------

# saveScore(score = , description= "Score for decision tree with x% balance")