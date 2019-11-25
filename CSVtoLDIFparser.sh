#!/bin/bash

BACKTITLE="Parseador de .csv a .ldif para OpenLDAP"
MSGBOX=$(cat << END
Ve eligiendo las diferentes opciones y asegurate
de tener todo listo antes de empezar
Es aconsejable ir en orden.
Elige una opción.
END
)
default_page=Nombre

# not defined variable
let admin_name
let domain_name
let domain_extension
let csv_path

# Exit program function
# Abort or terminated
exit_program() {
        rm -f /tmp/csv-ldif-parser.tmp.*
        clear
        echo "Program $1"
        if [ "$1" == "aborted" ]
        then
                exit 1
        fi
        exit
}

# Used to decide the exit type
exit_case() {
        case $1 in
                1) exit_program "terminated" ;;
                255) exit_program "aborted"  ;;
        esac
}

# Main menu
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
        exit_case $exit_status
        main_val=`cat /tmp/csv-ldif-parser.tmp.$$`
}

# input "title" "message" "var_name"
input() {
        # this 'variable' is for putting the default value to the value of the variable
        variable=$3
        dialog  --clear \
                --title "[$1]" \
                --backtitle "$BACKTITLE" \
                --ok-label "Aceptar" \
                --cancel-label "Cancelar" \
                --inputbox "$2" 8 60 "${!variable}" \
                2> /tmp/csv-ldif-parser.tmp.$$
        exit_status=$?
        if [ $exit_status -eq 0 ]
        then
        case $3 in
                admin_name)
                        admin_name=`cat /tmp/csv-ldif-parser.tmp.$$`  ;;
                domain_name)
                        domain_name=`cat /tmp/csv-ldif-parser.tmp.$$` ;;
                domain_extension)
                        domain_extension=`cat /tmp/csv-ldif-parser.tmp.$$`;;
        esac
        fi
}

# select file in system
csv_input() {
        dialog	--clear \
		--title "[Importar CSV]" \
		--backtitle "$BACKTITLE" \
		--ok-label "Aceptar" \
		--cancel-label "Cancelar" \
		--fselect $HOME/ 14 48 \
                2> /tmp/csv-ldif-parser.tmp.$$
        csv_path=`cat /tmp/csv-ldif-parser.tmp.$$`
}

# show the final script brief information
# if any of the inputs is empty, it shows error
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
                # if create ldif is tapped, show a confirmation dialog
                if [ $exit_status -eq 0 ]
                then
                        dialog  --clear \
                                --title "[Crear Script]" \
                                --backtitle "$BACKTITLE" \
                                --yes-label "Segurísimo" \
                                --yesno "¿Esta seguro de que quiere crear el script?" 10 40
                        script_option=$?
                        # if confirm equals yes, make the magic ;D
                        if [ $script_option -eq 0 ]
                        then
                                csv_to_ldif
				echo "[Primera entrada del ldif]" >> /tmp/csv-ldif-parser.tmp.$$
				head -13 $HOME/add_users.ldif >> /tmp/csv-ldif-parser.tmp.$$
				printf "\n" >> /tmp/csv-ldif-parser.tmp.$$
				echo "[Segunda entrada del ldif]" >> /tmp/csv-ldif-parser.tmp.$$
				tail -13 $HOME/add_users.ldif >> /tmp/csv-ldif-parser.tmp.$$
				printf "\n" >> /tmp/csv-ldif-parser.tmp.$$
				echo "[Numero de entradas totales]" >> /tmp/csv-ldif-parser.tmp.$$
				grep -c ^$ $HOME/add_users.ldif >> /tmp/csv-ldif-parser.tmp.$$
				dialog  --clear \
					--title "[Script content]" \
					--backtitle "$BACKTITLE" \
					--exit-label "Atrás" \
					--textbox /tmp/csv-ldif-parser.tmp.$$ 40 70
                        fi
                fi
        fi
}


script_info_case() {
        case "$1" in
                admin_name) script_info_error "Nombre del admin" ;;
                domain_name) script_info_error "Nombre del dominio" ;;
                domain_extension) script_info_error "Extensión del dominio" ;;
                csv_path) script_info_error "Ruta del archivo .csv" ;;
        esac
}
# show error message box if any inputs is not defined
script_info_error() {
        dialog  --clear \
                --title "[Script info]" \
                --backtitle "$BACKTITLE" \
                --msgbox "Falta información: $1" 7 40
}


csv_to_ldif() {
	#ou exists
	while IFS=, read -r uidNumber description name name_id
	do
		echo dn: uid=$name,ou=prueba,dc=$domain_name,dc=$domain_extension >> $HOME/add_users.ldif
		echo uid: $name >> $HOME/add_users.ldif
		echo cn: $name >> $HOME/add_users.ldif
		echo givenName: $description >> $HOME/add_users.ldif
		echo sn: $name-$uidNumber >> $HOME/add_users.ldif
		echo objectClass: inetOrgPerson >> $HOME/add_users.ldif
		echo objectClass: posixAccount >> $HOME/add_users.ldif
		echo objectClass: top >> $HOME/add_users.ldif
		echo loginShell: /bin/bash >> $HOME/add_users.ldif
		echo uidNumber: $uidNumber >> $HOME/add_users.ldif
		echo gidNumber: 1 >> $HOME/add_users.ldif
		echo homeDirectory: /home/$name >> $HOME/add_users.ldif
		echo userPassword: $(slappasswd -h {SHA} -s "$name") >> $HOME/add_users.ldif
		echo "" >> $HOME/add_users.ldif
	done < $csv_path
	dialog 	--clear \
		--title "[ldif path]" \
		--backtitle "$BACKTITLE" \
		--msgbox "Archivo ldif generado en $HOME/add_users.ldif" 0 0
}

ou_exists() {
	ldapsearch -H ldap://$domain_name.$domain_extension \
	-x -LLL -b "dc=$domain_name,dc=$domain_extension" "(ou=people)" dn \
	>> /tmp/csv-ldif-parser.tmp.$$
	ou_content=`cat /tmp/csv-ldif-parser.tmp.$$`
	if [ -z "$ou_content" ]
	then
		return false
	else
		return true
	fi
}



#################################################################
######                      MAIN LOOP                     #######
#################################################################
while true; do
        main
        case $main_val in
                0) exit_program "terminated" ;;

                Nombre) input "Admin OpenLDAP" "Pon el nombre del administrador del dominio:" "admin_name"
			default_page=Nombre ;;

                Servidor) input "Dominio" "Ponga el nombre del dominio:" "domain_name"
			default_page=Servidor ;;

                Extension) input "Dominio" "Ponga la extensión del dominio:" "domain_extension"
			default_page=Extension ;;

                OrigenCSV) csv_input
			default_page=OrigenCSV ;;

                Script) script_info
			default_page=Script ;;

                Salir) exit_program "terminated" ;;
        esac
done

exit 0
