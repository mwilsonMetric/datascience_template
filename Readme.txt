En este documento se describen las mejores practicas de programación que hemos acordado como equipo, las cuales se dividen en 2 partes:
1) Iniciar un proyecto
2) Estructura de proyecto.
3) Estilo de codigo.

Iniciar un proyecto
===================

Para usar Jupyter
-----------------
Al clonar un proyecto con "git clone", luego debe ejecutar desde la carpeta del repositorio "nbstripout --install", si no está instalado, 
instalelo con 
    Lab: yay -Sy python-nbstripout
    PC Windows: pip install nbstripout

En jupyter el woking directory siempre es la carpeta del notebook, no la del proyecto, para corregir ello, en la carpeta Template hay un ejemplo de codigo que retrocederá hasta encontrar la carpeta ".git" o "files" que está en la raiz del proyecto.
Todo lo que debe hacer esponer y ejecutar ese codigo al principio de cualqueir codigo python usado en JupyterLab.

El codigo es el Siguiente:

    import os
    while not any([x in  [".git","files"] for x in os.listdir()]):
        os.chdir("..")
    print("Working Directory: " + os.getcwd())

    import sys
    if not os.getcwd() in sys.path:
        sys.path.append(os.getcwd())

Estructura de proyecto
======================

Básicamente el proyecto se divide en 2 grande mundos, lo que está dentro de la carpeta "files" y lo que no está.
Por que esa divición, muy simple, lo que está fuera de files, es codigo versionable que se respalda en GIT, mientras que los archivos no versionables van a la carpeta files que se respalda en Amazon S3.

Cada compomente de un proyecto ha sido mapeado a una carpeta del template, de ser necesario mas, se pueden crear. La estructura es la siguiente:

Fuera de Files
--------------
todo ceste ontenido se respalda con git, por lo que debe haber solo codigo, a los jupyternotebook se les borraran las figuras antes de realizar un commit automaticamente despues de hacer "nbstripout --install"

sandbox: codigos que no son parte del proyecto o son experimentos.
reports: codigos para generar reportes, pero no el reporte en si. los reportes van en files/modeling_output/reports
preprocesing: codigos para preprocesar y limpiar datos que seran utilizados en los modelos. los input i output de estos procesos deben estar en files/dataset (descrito en detalle mas adelante)
models: codigos que generan los modelos, los modelos deben ser guardados en files/modeling_output/model_fit
insight: pistas o descriptivos que aportan valor, los resultados van en files/modelong_output/insights
function: funciones del proyecto, estos archivos deben tener el mismo nombre que la funcion. las funciones son cargadas en el init.R
modules: clases y objetos de python


Files
-------
Este contenido se respalda en S3 usando los comando toS3 y fromS3, desde R o desde la consola (para usarlos desde la consola sacarlos de bitbucket y sarlo desde la raiz del proyecto)

files/datasets: son los datos utilizados para el proyecto, las 3 carpetas que están adentro corresponden al siguiente flujo:
    files/datasets/input: archivos entregados por el cliente que van a ser usados para modelar, pero aun necesitan procesamiento.
    files/datasets/intermedia: Archivos ya procesados que serán utilizados para crear datasets que seran utilizados para modelar, aca solo se eben escribir RDS o feather
    files/datasets/output: datasets listos para modelar en formato feather o RDS

files/documentation : son los documentos relacionados con el proyecto, pero que no contienen datos para modelar, como papers, presentaciones etc...
    files/documentation/docs_cliente: Documentos entregados por la contraparte
    files/documentation/presentation: presentaciones
    files/documentation/references: papers
    
files/modeling_output/ Aca se guardan los resultados del trabajo en los proyectos:
    files/modeling_output/figures : Graficos
    files/modeling_output/insights: notebooks con indicios, recordar que el contenido de los notebooks no se copia a GIT, por lo que si se quiere un respaldo, se debe copiar aca.
    files/modeling_output/model_fit: En esta carpeta se guardan los objetos con los modelos, ya sea un RDS o un h2o
    files/modeling_output/reports: Reportes de performance de modelos o avances, nuevamente puede ser un notebook.
    
    
    
    
