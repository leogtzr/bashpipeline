bash pipeline v1.0
------------------
## Leo Gutiérrez R. | leogutierrezramirez@gmail.com

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

1.sh:
```
#!/bin/bash
# complex commands
...
```

2.sh:
```
#!/bin/bash
# complex commands
...
```

3.sh:
```
#!/bin/bash
# complex commands
...
```

4.sh:
```
#!/bin/bash
# complex commands
...
```

5.sh:
```
#!/bin/bash
# complex commands
...
```

Si la ejecución de alguno de estos scripts falla, podemos continuar la ejecución utilizar el comando bp_continue.sh de la siguiente
manera:
```
	$ bp_continue.sh 2.sh
```

El script se encargará de continuar la ejecución de los siguientes scripts (*3.sh, 4.sh, 5.sh ... *) secuencialmente 
dentro del directorio del proyecto.

## DOC FLOW
