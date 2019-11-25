# Parseador de .CSV a .LDIF

Es un script escrito en *bash*. Tiene una interfaz gráfica bastante amigable para aquellos informáticos que no sepan crear un archivo .ldif de cero. Su función es crear un único archivo *.ldif* con todos los datos pasados mediante un archivo *.csv* previamente curado.

El programa pedirá al usuario los siguientes parámetros:
  - Nombre del administrador del ***LDAP***
  - Nombre del dominio
  - Extensión del dominio
  - La ruta donde se encuentra en alchivo *.csv*

### Requisitos
Para poder ejecutar correctamente este script, se necesitará lo siguiente:
  - Un ordenador con terminal ***Linux***
  - Un servidor ***LDAP*** isntalado y correctamente funcionando
  - Modulo de dialog `apt-get install dialog`

### Instalación 
Primero nos descargamos el script. Este repositorio trae un *.csv* de prueba para poder realizar tests.
`git clone https://github.com/luki201508/scripting.git`
Se nos descargará una carpeta *scripting*.
`cd scripting`
Finalmente ejecutaremos el script. Da igual como se haga, aquí te muestro una manera de ejecutarlo:
`bash CSVtoLDIFparser.sh`
