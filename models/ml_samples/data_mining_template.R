rm(list = ls())
gc()
source("init.R")


# Parameters --------------------------------------------------------------

# Aqui se declaran como variables la rutas que se utilizaran para leer los archivos
# y otros parametros que sean importantes
files = c(train  = "files/datasets/input/data_template/train.csv",
          validation = "files/datasets/input/data_template/validation.csv")
featuresFile = "files/datasets/input/data_template/features.tab"

# Features, update and get ------------------------------------------------

# Aqui se actualizan las filas del Features para que correpondan con los nombres
# de las columnas de alguno de los set de datos, si no existe un "Features" crea uno
# lleno de 0's y NA's. Si ya existe uno, agrega la filas de las variables
# nuevas con 0's y NA's,  reordena las filas y elimina las filas de variables que no
# estan en el archivo leído para actualizar el Features
# updateFeatures(dataset.file = files,
#   features.file = featuresFile,
#   ds.sep = ";",
#   f.sep = "\t"
# )

#En este punto creara una lista a partir del Features con la información necesaria para el resto del proceso
# por lo tanto el archivo features debe ser editado segun corresponda antes de seguir.
features = ml.readFeatures(features.file = featuresFile, sep = "\t")

# Reading and splitting data ----------------------------------------------

# se juntan todos los datos en un unico dataframe que contiene todas las variables seleccionadas
# en features, y asigna NA's en las variables para los set de datos que carecían de ellas.
# Ademas se agrega una columna con el nombre del grupo al que pertenece cada registro
dataset = ml.readDataset(files = files,
                         features.list = features,
                         sep = ";")

#se balancea el grupo  de entrenamiento segun alguna tasa de respuesta
# dataset = rebalance(dataset = dataset,
#   subset = "train",
#   responseRate = 0.019,
#   features = attr(dataset,"features")
# )

#se arman nuevos grupos a partir de los grupos anteriores indicando el porcentaje que se va a cada grupo nuevo
# sin necesidad de tomar el 100% de los registros
# y se mantenienen las tasas de respuesta de cada uno.
dataset = ml.splitDataset(
  dataset = dataset,
  groups = "train",
  splitter = c("train" = 0.7, "test" = 0.3)
)

# set new responce rate on train group
dataset = ml.setResponseRate(dataset, rate = 0.1, "train")

# Transforming data with features file ------------------------------------

#se remplazan los nulos de las columnas con el valor que se indique en features para cada columna
dataset = ml.transformFeaturesReplaceNull(dataset = dataset, features = attr(dataset, "features"))

#Se fuerzan las clases para las columnas segun features
dataset = ml.transformFeaturesClass(dataset = dataset, features = attr(dataset, "features"))

#Para las variables que se forzaron a factores se conservan un limite de niveles
#establecido en features, tomando los mas frecuentes. El resto se agrupa como un nivel mas llamado "otros".
dataset = ml.transformFeaturesLimitFactors(dataset = dataset, features = attr(dataset, "features"))

#Aplica las operaciones declaradas en script para cada columna, si alguna operacion utiliza un valor
# especifico, debe ser declarado con el mismo nombre antes de este paso.
# Lo que hace es aplicar transform(dataset,col="script") en cada variable que tenga un "script"
dataset = ml.transformFeaturesScripts(dataset = dataset, features = attr(dataset, "features"))

#Version dummy del dataset para los metodos que lo necesitan

dummydataset = ml.transformFeaturesDummy(dataset = dataset, features = attr(dataset, "features"))

# Model Calibration and Reports -------------------------------------------

templates.path = paste0(project.src.path, "reports/reports_templates/")
performanceReportTemplate.path = paste0(templates.path, "performanceReport_template.Rmd")
report.dir = paste0(project.files.path, "modeling_output/reports/")

calibration_tree = ml.trainModel(
  model = "rpart",
  dataset = dataset,
  subset = "train",
  features = attr(dataset, "features"),
  control = rpart.control(
    minsplit = 10,
    cp = 0.0001,
    maxdepth = 5
  )
)
ml.makeModelReport(
  calibration = calibration_tree,
  model.name = "model_nuevo_rpart",
  templates.path = templates.path,
  report.dir = report.dir,
  sep.dec = ","
)# Se genera un reporte que se almacena en la carpeta reports

calibration_rf = ml.trainModel(
  model = "randomForest",
  dataset = dataset,
  subset = "train",
  features = attr(dataset, "features"),
  ntree = 50
)
ml.makeModelReport(
  calibration = calibration_rf,
  model.name = "model_nuevo_rf",
  templates.path = templates.path,
  report.dir = report.dir,
  sep.dec = ","
)

calibration_h2o.rf = ml.trainModel(
  model = "h2o.randomForest",
  dataset = dataset,
  subset = "train",
  features = attr(dataset, "features"),
  ntree = 50
)
ml.makeModelReport(
  calibration = calibration_h2o.rf,
  model.name = "model_nuevo_h2o",
  templates.path = templates.path,
  report.dir = report.dir,
  sep.dec = ","
)

calibration_lasso = ml.trainModel(
  model = "cv.glmnet",
  dataset = dummydataset,
  subset = "train",
  family = "binomial",
  nfolds = 3,
  alpha = 1,
  type.measure = "mse",
  parallel = F
)
ml.makeModelReport(
  calibration = calibration_lasso,
  model.name = "model_lasso",
  templates.path = templates.path,
  report.dir = report.dir,
  sep.dec = ","
)

calibration_logistic = ml.trainModel(
  model = "glm" ,
  dataset = dummydataset,
  subset = "train",
  family = binomial(link = 'logit')
)

ml.makeModelReport(
  calibration = calibration_logistic,
  model.name = "model_logit",
  templates.path = templates.path,
  report.dir = report.dir,
  sep.dec = ","
)

# Scoring -----------------------------------------------------------------


score_tree = ml.predict(calibration = calibration_tree,
                        dataset = dataset)
# ml.makeModelPerformanceReport(scores =  score_tree,id_execution = c(1,2,3),quantileCuts = c(10))
ml.makeModelPerformanceReport(
  scores = score_tree,
  model.name = "modelo_rpart",
  template.path = performanceReportTemplate.path,
  report.dir = report.dir
)

score_rf = ml.predict(calibration = calibration_rf,
                      dataset = dataset,
                      type = "prob")
ml.makeModelPerformanceReport(
  scores = score_rf,
  model.name = "modelo_rf",
  template.path = performanceReportTemplate.path,
  report.dir = report.dir
)

# ml.makeModelPerformanceReport(scores =  score_rf,id_execution = c(1,2,3),quantileCuts = c(10))

# score_lasso = ml.predict(
#   calibration = calibration_lasso,
#   dataset = dummydataset,
#   type = "response",
#   s = "lambda.min"
# )

# ml.makeModelPerformanceReport(
#   scores = score_lasso,
#   model.name = "modelo_lasso",
#   template.path = performanceReportTemplate.path,
#   report.dir = report.dir
# ) # Con problemas, quizas por la cantidad de registros. Cambiarlo al de h2o

score_logistic = ml.predict(calibration = calibration_logistic,
                            dataset = dummydataset,
                            type = "response")

ml.makeModelPerformanceReport(
  scores = score_logistic,
  model.name = "modelo_logit",
  template.path = performanceReportTemplate.path,
  report.dir = report.dir
)

# Comparing models ----------------------------------------------------------
train_scores = list(dec_tree = score_tree$train,
                    random_forest = score_rf$train)
# logistic = score_logistic$train,
# lasso = score_lasso$train


test_scores = list(dec_tree = score_tree$test,
                   random_forest = score_rf$test)
# logistic = score_logistic$test,
# lasso = score_lasso$test

ml.getAUC(train_scores)

ml.getAUC(test_scores)

plota = ml.plotROC(score = test_scores,
                   legendTitle = "Model",
                   title = "Test Scores") +
  ylim(0, 1.25)
plotb = ml.plotROC(score = train_scores,
                   legendTitle = "Model",
                   title = "Training Scores") +
  ylim(0, 1.25)
plotc = ml.plotLift(
  score = test_scores,
  legendTitle = "Model",
  title = "Cumulative Lift",
  quantileCuts = c(5, 20)
) + xlim(0, 25) + ylim(0.8, 6)

multiplot(plota, plotb, plotc, layout = rbind(1:2, c(3, 3)))
# Saving models  ----------------------------------------------------------

models.path = paste0(project.files.path, "modeling_output/model_fit/")

ml.saveModel(
  calibration = calibration_rf,
  file = paste0(models.path, "modeloRfTemplate.RDS"),
  features = attr(calibration_rf, "features")
)


ml.saveModel(
  calibration = calibration_tree,
  file = paste0(models.path, "modeloTreeTemplate.RDS"),
  features = attr(calibration_tree, "features")
)

# ml.saveModel(calibration = calibration_lasso,
#           file = "models/modeloLassoTemplate.RDS",
#           features = attr(calibration_lasso,"features"))
#
# ml.saveModel(calibration = calibration_logistic,
#           file = "models/modeloLogisticTemplate.RDS",
#           features = attr(calibration_logistic,"features"))


# Uploading Scores to analytics DB --------------------------------------------------------

#TODO

# ml.saveScore(score = score_rf, description = "Template's example score for random forest" )
#
# ml.saveScore(score = score_tree, description= "Template's example score for decision tree")

# ml.saveScore(score = score_lasso, description= "Template's example score for lasso")
#
# ml.saveScore(score = score_logistic, description= "Template's example score for Logistic")
