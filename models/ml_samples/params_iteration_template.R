# Setup -------------------------------------------------------------------
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

# dataset = rebalance(dataset = dataset,
#   subset = "train",
#   responseRate = 0.18
# )

dataset = splitGroups(
  dataset = dataset,
  groups = "train",
  splitter = c("train" = 0.8, "test" = 0.2)
)


# Transforming data with features file ------------------------------------

dataset = replaceNullFeatures(dataset = dataset)
dataset = forceClass(dataset = dataset)
dataset = limitFactors(dataset = dataset)
dataset = featuresScript(dataset = dataset)
#Version dummy del dataset para los metodos que lo necesitan
dummydataset = toDummyFeatures(dataset = dataset)


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

training_params=list(train_param_1=train_param_1,train_param_2=train_param_2)



# Models, calibraition and execution --------------------------------------

calibration = llply(training_params,
                    function(x) {#Aqui se deben definir los parametros fijos
                    x[["model"]]= "rpart"
                    x[["dataset"]] = dataset
                    x[["subset"]] = "train"
                    calibration=do.call(what = trainModel ,args = x)
                    return(calibration)},.progress = "text")



score = llply(calibration, function(x) {
  predictBDA(calibration = x,
             dataset = dataset,
             subset = "all")
},.progress = "text")

names(score)=names(training_params)


# Comparing models ----------------------------------------------------------
train_scores=llply(score,function(x){x$train}) #se juntan los scores de entrenamiento de cada dataset en una lista

test_scores=llply(score,function(x){x$test}) #idem para los grupos de validacion
  
  
getAuc(train_scores)

getAuc(test_scores)

plota=rocPlot(test_scores,legendTitle = "grupo de parametros",title = "Test Scores")
plotb=rocPlot(train_scores,legendTitle = "grupo de parametros",title = "Training Scores")+ylim(0,1.25)

multiplot(plota,plotb)
# Saving models  ----------------------------------------------------------


# saveModel(calibration = ,
#           file="models/filename.RDS",
#           )





# Uploading Scores to analytics DB --------------------------------------------------------

# saveScore(score = , description = "" )
