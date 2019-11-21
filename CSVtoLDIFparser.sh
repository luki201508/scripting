#!/bin/bash
TITLE="[CSV to LDIF Parser]"
BACKTITLE="Parseador de .csv a .ldif para OpenLDAP"
MSGBOX=$(cat << END
Ve eligiendo las diferentes opciones y asegurate
de tener todo listo antes de empezar
Es aconsejable ir en orden.
Elige una opción.
END
)

display_result() {
	dialog 	--clear \
		--title "$1" \
		--msgbox "$result" 0 0
}


while true; do
#exec 3>&1
	dialog --clear \
		--title "$TITLE" \
		--backtitle "$BACKTITLE" \
		--ok-label "Aceptar" \
		--cancel-label "Cancelar" \
	       	--menu "$MSGBOX" 20 0 20 \
		Nombre "Indica el nombre del admin OpenLDAP" \
		Servidor "Indica el nombre del servidor" \
		Extension "Indica la extensión del servidor" \
		OrigenCSV "Indica el nombre del fichero CSV" \
		Salir "Salir del script" \
		2> /tmp/csv-ldif-parser.tmp.$$
	exit_status=$?
	case $exit_status in
		1) clear
		   echo "Program terminated"
		   exit ;;
		255) clear
		   echo "Program aborted"
		   exit 1
		   ;;
	esac
	main_val=`cat /tmp/csv-ldif-parser.tmp.$$`
	rm -f /tmp/csv-ldif-parser.tmp.$$
	case $main_val in
		0)
		clear
		echo "Program terminated"
		;;
		Nombre)
		result="Nombre selected"
		display_result "Nombre"
		;;
	esac
done

exit 0

