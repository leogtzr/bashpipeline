bash pipeline v1.0
------------------
Leo Gutiérrez R. | leogutierrezramirez@gmail.com

This small library helps to modularize the execution of a script.

## SEQUENTIAL FLOW

Example:

```
#!/bin/bash
# 1) complex commands
...
# 2) complex commands
...
# 3) complex commands
...
# 4) complex commands
...
# 5) complex commands
...
exit 0
```

The problem with this script is that we don't have a "save point", a save point that we can use to continue with the script execution.
We need to fix the issue and start from scratch ... (or modify the current script and comment out some lines ... )
With this small library we can modularize our complex script with little sequential scripts in a work directory and let the library to handle the execution.


**1.sh:**
```
#!/bin/bash
# complex commands
...
```

**2.sh:**
```
#!/bin/bash
# complex commands
...
```

**3.sh:**
```
#!/bin/bash
# complex commands
...
```

**4.sh:**
```
#!/bin/bash
# complex commands
...
```

**5.sh:**
```
#!/bin/bash
# complex commands
...
```

If any of these script fails, we can continue the execution with the *bp_continue.sh* command:
```
	$ ./bp_continue.sh 2.sh
```	

The script will execute the other scripts sequentially.

Example:
1. Create our scripts in a specific directory:
```
[0 [17:06][leo@feed]$ ls
1.sh  2.sh  3.sh  4.sh  5.sh
[0 [17:06][leo@feed]$ cat *
#!/bin/bash
echo "Running $0"
exit 0
#!/bin/bash
echo "Running $0"
exit 0
#!/bin/bash
echo "Running $0"
exit 0
#!/bin/bash
echo "Running $0"
exit 0
#!/bin/bash
echo "Running $0"
exit 0
```
2. Modify the *bp_flow.env* configuration file:
```
export PROJECT_NAME="Data Feed Process"
export FLOW_TYPE=SEQ
export WORKING_DIR=feed
export DEBUG=1
export DEBUG_FILE=log_$(date '+%Y%m%S_%H%M%S').log
export INCLUDE_DATE_LOG=1
```

**PROJECT_NAME** The name of our project.

**FLOW_TYPE** Flow execution type, we can use _SEQ_ or _DOC_.

**WORKING_DIR** path where we have our scripts to execute.

**DEBUG** enable debug. (0=DISABLED, 1=ENABLED).

**DEBUG_FILE** path of our debug file.

**INCLUDE_DATE_LOG** to see a datetime in out debug files (0=DISABLED, 1=ENABLED).

To include **bashpipeline** in our main script we need to do this:
run_feed.sh
```
#!/bin/bash

if [ -f ./bplib.sh ]; then
    . ./bplib.sh
else
    echo "[`date '+%F %T'`] [ERROR] bplib.sh NOT found."
    exit 76
fi

start_scripts && {
    echo "$? ... finished ... "
}
exit 0

```
La función start_scripts se encarga de empezar la ejecución de nuestro scripts en el directorio
*WORKING_DIR*.

```
[0 [17:14][leo@simplebashpipeline]$ ./run_feed.sh 
[2015-06-13 17:14:43] [DEBUG] Beginning Data Feed Process project
[2015-06-13 17:14:43] [DEBUG] Running: 1.sh  SCRIPT
Running feed/1.sh
[2015-06-13 17:14:43] [DEBUG] exit status: 0
[2015-06-13 17:14:43] [DEBUG] Running: 2.sh  SCRIPT
Running feed/2.sh
[2015-06-13 17:14:43] [DEBUG] exit status: 0
[2015-06-13 17:14:43] [DEBUG] Running: 3.sh  SCRIPT
Running feed/3.sh
[2015-06-13 17:14:43] [DEBUG] exit status: 0
[2015-06-13 17:14:43] [DEBUG] Running: 4.sh  SCRIPT
Running feed/4.sh
[2015-06-13 17:14:43] [DEBUG] exit status: 0
[2015-06-13 17:14:43] [DEBUG] Running: 5.sh  SCRIPT
Running feed/5.sh
[2015-06-13 17:14:43] [DEBUG] exit status: 0
[2015-06-13 17:14:43] [DEBUG] Finished Data Feed Process project
0 ... finished ... 
```
### Cómo corregir errores cuando hay un error en uno de los scripts
```
[0 [17:18][leo@simplebashpipeline]$ ./run_feed.sh 
[2015-06-13 17:18:27] [DEBUG] Beginning Data Feed Process project
[2015-06-13 17:18:27] [DEBUG] Running: 1.sh  SCRIPT
Running feed/1.sh
[2015-06-13 17:18:27] [DEBUG] exit status: 0
[2015-06-13 17:18:27] [DEBUG] Running: 2.sh  SCRIPT
Running feed/2.sh
[2015-06-13 17:18:27] [DEBUG] exit status: 78

FAILED_SCRIPT ===> 2.sh
EXIT_CODE =======> 78
ERROR_MSG ======> ''
Use bp_continue.sh once the problem has been fixed.
```
en el ejemplo anterior, el script *2.sh* no ha finalizado correctamente.
Una vez que hayamos arreglado el error, podemos continuar la ejecución de los scripts
usando el comando *bp_continue.sh*:
```
[0 [17:21][leo@simplebashpipeline]$ ./bp_continue.sh 2.sh
[2015-06-13 17:21:10] [DEBUG] Running: 2.sh
Running feed/2.sh
[2015-06-13 17:21:10] [DEBUG] status: 0
[2015-06-13 17:21:10] [DEBUG] Running: 3.sh
Running feed/3.sh
[2015-06-13 17:21:10] [DEBUG] status: 0
[2015-06-13 17:21:10] [DEBUG] Running: 4.sh
Running feed/4.sh
[2015-06-13 17:21:10] [DEBUG] status: 0
[2015-06-13 17:21:10] [DEBUG] Running: 5.sh
Running feed/5.sh
[2015-06-13 17:21:10] [DEBUG] status: 0
[2015-06-13 17:21:10] [DEBUG] Finished ... 
```

## DOC FLOW

Doc flow es otro tipo de ejecución modular de scripts en nuestro proyecto.
El flujo de ejecución es definido en un archivo externo (FLOW_FILE). 
Los scripts dentro de este archivo son ejecutados en cadena. Podemos imaginar una estructura de árbol
como la siguiente:

```
                                > (d0) 
                              ~
                            ~
                          ~
                     > (c1) ~ ~ ~ > (d1) 
                   ~                  ~
                 ~                      ~
               ~                          ~
(a) ~ ~ ~ ~ > (b)                           > (e) 
               ~                          ~
                 ~                      ~
                   ~                  ~
                     > (c2) ~ ~ ~ > (d2)
```

El script (a) es ejecutado primero, si su ejecución es exitosa, se ejecuta (b), si la ejecución
de (b) es exitosa, entonces se ejecuta (c1), luego (d0) y (d1), después de (d1) se ejecuta finalmente a 
(e). Luego la ejecución continua con (c2), luego (d2) y finalmente (e).
Como se puede ver, la ejecución de scripts se puede dividir y mezclar entre ellos.

El archivo donde dicha ejecución es definida tiene el formato siguiente:

```
# syntax:
# script:description:return value:script[,script]
# more lines ...
```

El primer campo es el nombre del script a ejecutar.
El segundo campo es una descripción sobre el script a ejecutar (opcional).
El tercer campo es el valor de retorno que se espera del script a ejecutar. 
El cuarto campo son los siguientes scripts a ejecutar.

Ejemplo:
```
a:a script:0:b
b:b script:0:c1,c2
c1:c1 script:2:d0,d1
c2:c2 script:0:d2
d0:d0 script:0:
d1:d1 script:0:e
d2:d2 script:0:e
e:e script:0:
```

Para habilitar este tipo de ejecución, solo debemos de especificar el tipo de ejecución **DOC** en el archivo 
bp_flow.env:

```
export FLOW_TYPE=DOC
export FLOW_FILE=project2.flow
```

https://github.com/leogtzr/bashpipeline.wiki.git
