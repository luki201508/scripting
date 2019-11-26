#!/bin/bash
#title           :Parseador de .csv a .ldif para servidores LDAP
#description     :Este script genera un archivo ldif pasándole el dominio y la ruta de un csv curado
#author		 :Lucas Galípolo Uriarte
#date            :26/11/2019
#version         :1.0
#usage		 :bash CSVtoLDIFparser.sh
#notes           :Tener un Servidor 'OpenLDAP' y el módulo 'dialog' instalados
#bash_version    :4.1.5(1)-release
#==============================================================================

## Titulo trasero, el cual será el mismo en todo el programa
BACKTITLE="Parseador de .csv a .ldif para OpenLDAP"
## Mensaje de texto que utiliza el menú
MSGBOX=$(cat << END
Ve eligiendo las diferentes opciones y asegurate
de tener todo listo antes de empezar
Es aconsejable ir en orden.
Elige una opción.
END
)
## Variable para determinar la posición en la que se encuentra en el menu
default_page=Nombre
## El nombre del admin tomará como valor por defecto admin (suele ser así)
admin_name=admin

## Variables no definidas, sin valor
let domain_name
let domain_extension
let csv_path

## Función para salir/abortar el programa
## Abort or terminated
exit_program() {
	# Eliminamos todos los archivos temporales relacionados a nuestro programa
        rm -f /tmp/csv-ldif-parser.tmp.*
        clear
        echo "Program $1"
        if [ "$1" == "aborted" ]
        then
                exit 1
        fi
        exit
}

## Función usada para determinar si el programa debe abortar o salir exitosamente (exit 0)
exit_case() {
        case $1 in
                1) exit_program "terminated" ;;
                255) exit_program "aborted"  ;;
        esac
}

## Menu principal que se servirá de navegador entre las distintas opciones del programa
main() {
        dialog --clear \
                --title "[CSV to LDIF Parser]" \
                --backtitle "$BACKTITLE" \
                --ok-label "Aceptar" \
                --cancel-label "Cancelar" \
		--default-item $default_page \
                --menu "$MSGBOX" 20 0 20 \
                Nombre "Indica el nombre del admin OpenLDAP" \
                Servidor "Indica el nombre del servidor" \
                Extension "Indica la extensión del servidor" \
                OrigenCSV "Indica el nombre del fichero CSV" \
                Script "Ver la información del script" \
                Salir "Salir del script" \
                2> /tmp/csv-ldif-parser.tmp.$$
        exit_status=$?

	# En caso de que se le de salir o abortar (Ctrl+C), ejecutará la función exit previa
        exit_case $exit_status

	# Variable usada para determinar la elección del usuario respecto al menu
        main_val=$(cat /tmp/csv-ldif-parser.tmp.$$)
}

## Input donde se mete el nombre del admin
## Tiene valor por defecto 'admin' pero si previamente se
## le ha asignado otro valor, se pondrá ese valor por defecto
input_admin_name() {
        dialog  --clear \
                --title "[Nombre Admin]" \
                --backtitle "$BACKTITLE" \
                --ok-label "Aceptar" \
                --cancel-label "Cancelar" \
                --inputbox "$2" 8 60 "$admin_name" \
                2> /tmp/csv-ldif-parser.tmp.$$
        exit_status=$?
	# En caso de que el usuario le de solo al botón de 'Aceptar'
	# Guardará el valor del input en un archivo temporal
        if [ $exit_status -eq 0 ]
        then
        	admin_name=$(cat /tmp/csv-ldif-parser.tmp.$$)
        fi
}

## Input donde se mete el nombre del dominio
## Valor por defecto el que se haya puesto previamente
input_domain_name() {
        dialog  --clear \
                --title "[Nombre Dominio]" \
                --backtitle "$BACKTITLE" \
                --ok-label "Aceptar" \
                --cancel-label "Cancelar" \
                --inputbox "$2" 8 60 "$domain_name" \
                2> /tmp/csv-ldif-parser.tmp.$$
        exit_status=$?
        if [ $exit_status -eq 0 ]
        then
        	domain_name=$(cat /tmp/csv-ldif-parser.tmp.$$)
        fi
}

## Input donde se mete la extensión del dominio
## Valor por defecto el que se haya puesto previamente
input_domain_extension() {
        dialog  --clear \
                --title "[Extensión Dominio]" \
                --backtitle "$BACKTITLE" \
                --ok-label "Aceptar" \
                --cancel-label "Cancelar" \
                --inputbox "$2" 8 60 "$domain_extension" \
                2> /tmp/csv-ldif-parser.tmp.$$
        exit_status=$?
        if [ $exit_status -eq 0 ]
        then
                domain_extension=$(cat /tmp/csv-ldif-parser.tmp.$$)
        fi
}

## Input donde se selecciona el fichero csv
csv_input() {
        dialog	--clear \
		--title "[Importar CSV]" \
		--backtitle "$BACKTITLE" \
		--ok-label "Aceptar" \
		--cancel-label "Cancelar" \
		--fselect $HOME/ 14 48 \
                2> /tmp/csv-ldif-parser.tmp.$$
        csv_path=$(cat /tmp/csv-ldif-parser.tmp.$$)
}

## Mostrará una ventana donde enseñará todos los datos pasados previamente
## En caso de no tener alguno de los parámetros con algún valor, lanzará
## Un mensaje diciendo el texto que le falta
script_info() {
        if [ -z "$admin_name" ]
        then
                script_info_case "admin_name"
        elif [ -z "$domain_name" ]
        then
                script_info_case "domain_name"
        elif [ -z "$domain_extension" ]
        then
                script_info_case "domain_extension"
        elif [ -z "$csv_path" ]
        then
                script_info_case "csv_path"
        else
		# Variable que se usa como texto del mensaje
                SCRIPT_INFO=" Nombre del admin: $admin_name
                Dominio: $domain_name.$domain_extension
                Ruta del CSV: $csv_path"

                dialog  --clear \
                        --title "[Script info]" \
                        --backtitle "$BACKTITLE" \
                        --ok-label "Crear LDIF" \
                        --extra-button \
                        --extra-label "Cancelar" \
                        --msgbox "$SCRIPT_INFO" 10 40
                exit_status=$?

                ## En caso de darle a 'Crear LDIF' se mostrará una advertencia
		## Preguntando si está seguro de que se quiere crear el archivo
                if [ $exit_status -eq 0 ]
                then
                        dialog  --clear \
                                --title "[Crear Script]" \
                                --backtitle "$BACKTITLE" \
                                --yes-label "Segurísimo" \
                                --yesno "¿Esta seguro de que quiere crear el script?" 10 40
                        script_option=$?
                        ## Si el usuario le da a 'Segurísimo' se ejecutará la función que crea el ldif
                        if [ $script_option -eq 0 ]
                        then
				## Genera un archivo ldif a partir del pasado csv
                                csv_to_ldif

				## Muestra la primera y la última entrada del archivo ldif
				show_ldif_file_info

				## Agregamos todos los usuarios del ldif al dominio mediante este comando
				ldapadd -x -D cn=$admin_name,dc=$domain_name,dc=$domain_extension -W -f $HOME/add_users.ldif

				## Guardar la última entrada del ldap en un archivo temporal
				slapcat | tail -21 > $temp_file

				## Mostrar la última entrada del ldap
				dialog  --clear \
					--title "[OpenLDAP última entrada]" \
					--backtitle "$BACKTITLE" \
					--exit-label "Atrás" \
					--textbox $temp_file 20 20
                        fi
                fi
        fi
}

## Función utilizada para mostrar la primera y última entrada del
## ldif, a parte del número total de entradas del mismo
show_ldif_file_info() {
	# Definir el archivo temporal
	temp_file=/tmp/csv-ldif-parser.tmp.$$

	echo "[Primera entrada del ldif]" > $temp_file
	# Mostrar las primera 13 líneas del archivo
	head -13 $HOME/add_users.ldif >> $temp_file
	printf "\n" >> $temp_file
	echo "[Segunda entrada del ldif]" >> $temp_file
	# Mostrar las últimas 13 líneas del archivo
	tail -13 $HOME/add_users.ldif >> $temp_file
	printf "\n" >> $temp_file
	echo "[Numero de entradas totales]" >> $temp_file
	# Contar todos los saltos de línea del archivo
	grep -c ^$ $HOME/add_users.ldif >> $temp_file

	dialog  --clear \
		--title "[Script content]" \
		--backtitle "$BACKTITLE" \
		--exit-label "Atrás" \
		--textbox $temp_file 40 70
}

## Función usada para mostrar el error en la opción 'Script' del menú
script_info_case() {
        case "$1" in
                admin_name) script_info_error "Nombre del admin" ;;
                domain_name) script_info_error "Nombre del dominio" ;;
                domain_extension) script_info_error "Extensión del dominio" ;;
                csv_path) script_info_error "Ruta del archivo .csv" ;;
        esac
}

## Mensaje de error si alguno de los Input está vacío
script_info_error() {
        dialog  --clear \
                --title "[Script info]" \
                --backtitle "$BACKTITLE" \
                --msgbox "Falta información: $1" 7 40
}

## Función que parsea el CSV y crea un LDIF a partir de éste
csv_to_ldif() {
	# Con IFS separamos por comas
	# Con read metemos cada parámetro del csv en una variable
	# Bucle para recorrer todo el csv
	while IFS=, read -r uidNumber description name name_id
	do
		# Variable para definir la ubicación del ldif
		ldif_file=$HOME/add_users.ldif
		echo dn: uid=$name,ou=script,dc=$domain_name,dc=$domain_extension >> $ldif_file
		echo uid: $name >> $ldif_file
		echo cn: $name >> $ldif_file
		echo givenName: $description >> $ldif_file
		echo sn: $name-$uidNumber >> $ldif_file
		echo objectClass: inetOrgPerson >> $ldif_file
		echo objectClass: posixAccount >> $ldif_file
		echo objectClass: top >> $ldif_file
		echo loginShell: /bin/bash >> $ldif_file
		echo uidNumber: $uidNumber >> $ldif_file
		echo gidNumber: 1 >> $ldif_file
		echo homeDirectory: /home/$name >> $ldif_file
		# Generamos un contraseña con la encriptación SHA con el nombre pasado por el csv
		echo userPassword: $(slappasswd -h {SHA} -s "$name") >> $ldif_file
		echo "" >> $ldif_file
	done < $csv_path ## Fichero csv
	## Mensaje de información, donde se encuentra el archivo generado
	dialog 	--clear \
		--title "[ldif path]" \
		--backtitle "$BACKTITLE" \
		--msgbox "Archivo ldif generado en $HOME/add_users.ldif" 0 0
}


#################################################################
######                      MAIN LOOP                     #######
#################################################################
while true; do
        main
        case $main_val in
                0) exit_program "terminated" ;;

                Nombre) input_admin_name
			default_page=Nombre ;;

                Servidor) input_domain_name
			default_page=Servidor ;;

                Extension) input_domain_extension
			default_page=Extension ;;

                OrigenCSV) csv_input
			default_page=OrigenCSV ;;

                Script) script_info
			default_page=Script ;;

                Salir) exit_program "terminated" ;;
        esac
done

exit 0
