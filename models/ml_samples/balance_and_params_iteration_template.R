rm(list = ls())
gc()
source("init.R")
# Parametros --------------------------------------------------------------

files = c(train = "data_template/train.csv")
featuresFile = "data_template/features.tab"

# Features, update and get ------------------------------------------------

updateFeatures(dataset.file = files,
               features.file = featuresFile,
               ds.sep = ",",
               f.sep = "\t"
)

features = getFeatures(features.file = featuresFile, sep = "\t")

# Reading and splitting data ----------------------------------------------

dataset = readDataset(files = files,
                      features.list = features,
                      sep = ",") 

#Se establencen los balanceos a comparar
responseRates=c(0.0195,0.0185,0.0175,0.0165)

# se balancean los grupos de entrenamiento segun alguna las tasas de respuesta
dataset_list = alply(responseRates,
                     1,
                     function(x) {
                       rebalance(
                         dataset = dataset,
                         subset = "train",
                         responseRate = x,
                         features = features
                       )
                     })

names(dataset_list)=responseRates# Esto es util para visualizacion

#se arman nuevos grupos a partir de cada dataset  
dataset_list = llply(dataset_list,
                     function(dataset) {
                       balancedSplitGroups(#usar splitGroups
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

# Parameters to iterate ----------------------------------------------------

train_param_1 = list(control = rpart.control(
  minsplit = 10,
  cp = 0.0001,
  maxdepth = 9
))

train_param_2 = list(control = rpart.control(
  minsplit = 5,
  cp = 0.001,
  maxdepth = 12
))

training_params=list(grupo1=train_param_1,grupo2=train_param_2)

# Models calibraition and execution ---------------------------------------

#Se calibra un modelo para cada dataset

calibration = llply(dataset_list,
                    function(dataset) {
                      llply(training_params,
                            function(x) {
                              #Aqui se deben definir los parametros fijos
                              x[["model"]] = "rpart"
                              x[["dataset"]] = dataset
                              x[["subset"]] = "train"
                              calibration = do.call(what = trainModel , args = x)
                              return(calibration)
                            })
                    },.progress = "text")

# se ejecuta el modelo para cada dataset 
score = alply(responseRates,
              1,
              function(x) {
                x = as.character(x)
                score = llply(calibration[[x]], function(y) {
                  predictBDA(calibration = y,
                             dataset = dataset_list[[x]],
                             subset = "all")
                })
              },.progress = "text")

names(score)=responseRates

# Comparing models and display----------------------------------------------------------
train_scores=llply(score,function(y){llply(y,function(x){x$train})}) #se juntan los scores de entrenamiento de cada dataset en una lista

test_scores=llply(score,function(y){llply(y,function(x){x$test})}) #idem para los grupos de validacion


#Ver AUC
llply(train_scores,getAuc)

llply(test_scores,getAuc)

#Graficos
plot = llply(test_scores,
              function(x)
                rocPlot(
                  x,
                  legendTitle = "Parametros")
                )

#Poner titulo a los graficos segun el balanceo que corresponde
plot = alply(responseRates,
             1,
             function(x) {
               y = plot[[x]]
               y=y+labs(title = paste("Roc para balanceo",x))})



#graficar
multiplot(plotlist = plot,cols = 2)

# Saving the best model  ----------------------------------------------------------


# saveModel(calibration = ,
#           file="models/filename.RDS",
#           features = attr(calibration,"features"))




# Uploading Scores to analytics DB --------------------------------------------------------

# saveScore(score = , description= "Score for decision tree with x% balance")