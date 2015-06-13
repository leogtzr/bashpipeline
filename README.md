bash pipeline v1.0
------------------
Leo Gutiérrez R. | leogutierrezramirez@gmail.com

Esta librería ayudar a modularizar la ejecución de un script.

## SEQUENTIAL FLOW

Ejemplo:

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

El problema con este script es que si en algún punto este script falla, para recuperar la ejecución, se tiene que ejecutar
el script completamente, es decir, desde el principio, no hay un punto en el cuál podamos continuar la ejecución luego de 
que el problema en el script ha sido resuelto.

Con bash pipeline podemos modularizar el script en archivos secuenciales en un directorio y dejar que la
librería se encargue de ejecutarlos secuencialmente

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

Si la ejecución de alguno de estos scripts falla, podemos continuar la ejecución utilizar el comando *bp_continue.sh* de la siguiente
manera:
```
	$ bp_continue.sh 2.sh
```

El script se encargará de continuar la ejecución de los siguientes scripts (3.sh, 4.sh, 5.sh ... ) secuencialmente 
dentro del directorio del proyecto.

EJEMPLO DE USO:
1. Crear nuestros scripts secuenciales en un directorio:
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
2. Modificar el archivo bp_flow.env:
```
export PROJ_NAME="Data Feed Process"
export FLOW_TYPE=SEQ
export WORKING_DIR=feed
export DEBUG=1
export DEBUG_FILE=log_`date '+%Y%m%S_%H%M%S'`.log
export INCLUDE_DATE_LOG=1
```
*PROJ_NAME* almacena el nombre del proyecto actual.
*FLOW_TYPE* almacena el tipo de flujo de ejecución, pueden ser SEQ o DOC.
*WORKING_DIR* almacena el directorio donde se encuentran los scripts a ejecutar.
*DEBUG* para configurar debug en la ejecución de los scripts. (0=DISABLED, 1=ENABLED).
*DEBUG_FILE* almacena el nombre del archivo donde se almacenarán las líneas de debug.
*INCLUDE_DATE_LOG* para configurar si las líneas de debug incluirán fecha o no. (0=DISABLED, 1=ENABLED).

Para incluir la librería en nuestro script principal hacemos esto:
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
