#!/bin/bash
# Demo-menu shell script
## --------------------
# Variables
# ---------------
EDITOR=nano
PASSWD=/etc/passwd

# --------------------
# User functino
# --------------------
pause() {
	read -p "Press [Enter] key to continue..." fackEnterKey
}

one() {
	echo "one() called"
		pause
}

two() {
	echo "two() called"
		pause
}

# display menus
show_menus() {
	clear
	echo "-----------------"
	echo "    MENU CACA    "
	echo "-----------------"
	echo "1. blabla"
	echo "2. popo"
}
