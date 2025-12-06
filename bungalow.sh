#!/bin/bash

# ===============================
# BUNGALOW – Linux Dev Toolkit
# Author: Eid Ali <eid.horus@gmail.com>
# ===============================

TMP=$(mktemp)

# ===============================
# Splash Screen
# ===============================
dialog --title "🏠 Bungalow – Linux Dev Toolkit" --msgbox "\
Welcome to Bungalow!
Author: Eid Ali <eid.horus@gmail.com>
For The Love Of Linux
May the Penguin be with you! 🐧" 15 60

# ===============================
# Check if dialog is installed
# ===============================
if ! command -v dialog &> /dev/null; then
    echo "Dialog is not installed. Installing..."
    if command -v apt &> /dev/null; then
        sudo apt install -y dialog
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dialog
    else
        echo "Cannot install dialog. Unsupported distro."
        exit 1
    fi
fi

# ===============================
# Detect package manager
# ===============================
if command -v apt &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
elif command -v zypper &> /dev/null; then
    PKG_MANAGER="zypper"
else
    echo "Unsupported Linux distribution"
    exit 1
fi

# ===============================
# Package installation function
# ===============================
install_pkg() {
    PACKAGE=$1
    case $PKG_MANAGER in
        apt) sudo apt install -y $PACKAGE ;;
        dnf) sudo dnf install -y $PACKAGE ;;
        yum) sudo yum install -y $PACKAGE ;;
        pacman) sudo pacman -S --noconfirm $PACKAGE ;;
        zypper) sudo zypper install -y $PACKAGE ;;
    esac
}

# ===============================
# Check if a package is installed
# ===============================
is_installed() {
    PACKAGE=$1
    case $PKG_MANAGER in
        apt) dpkg -s $PACKAGE &> /dev/null ;;
        dnf|yum) rpm -q $PACKAGE &> /dev/null ;;
        pacman) pacman -Q $PACKAGE &> /dev/null ;;
        zypper) rpm -q $PACKAGE &> /dev/null ;;
    esac
}

# ===============================
# Section: Compilers & Interpreters
# ===============================
section_compilers() {
    C_STATUS="off"; PYTHON_STATUS="off"; JAVA_STATUS="off"
    is_installed gcc && C_STATUS="on"; is_installed g++ && C_STATUS="on"
    is_installed python3 && PYTHON_STATUS="on"
    is_installed default-jdk && JAVA_STATUS="on"

    dialog --title "Compilers & Interpreters" --checklist "Select tools to install:" 20 60 10 \
    1 "C / C++ (gcc / g++)" $C_STATUS \
    2 "Python 3 + pip" $PYTHON_STATUS \
    3 "Java (default JDK)" $JAVA_STATUS \
    4 "Maven (Java build tool)" off \
    5 "Gradle (optional)" off \
    6 "C# (Mono)" off \
    7 "Ruby" off \
    8 "Install everything in this section" off 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1) install_pkg gcc; install_pkg g++ ;;
            2) install_pkg python3; install_pkg python3-pip ;;
            3) install_pkg default-jdk ;;
            4) install_pkg maven ;;
            5) install_pkg gradle ;;
            6) install_pkg mono-complete ;;
            7) install_pkg ruby ;;
            8) install_pkg gcc; install_pkg g++; install_pkg python3; install_pkg python3-pip; install_pkg default-jdk; install_pkg maven; install_pkg gradle; install_pkg mono-complete; install_pkg ruby ;;
        esac
    done
}

# ===============================
# Section: Web Development Stack
# ===============================
section_webdev() {
    NODE_STATUS="off"; PHP_STATUS="off"; DJANGO_STATUS="off"; APACHE_STATUS="off"; NGINX_STATUS="off"; MYSQL_STATUS="off"
    is_installed nodejs && NODE_STATUS="on"
    is_installed php && PHP_STATUS="on"
    is_installed python3-django && DJANGO_STATUS="on"
    is_installed httpd && APACHE_STATUS="on"
    is_installed nginx && NGINX_STATUS="on"
    is_installed mariadb-server && MYSQL_STATUS="on"

    dialog --title "Web Development Stack" --checklist "Select tools to install:" 25 70 12 \
    1 "Node.js + npm" $NODE_STATUS \
    2 "PHP + CLI + FPM" $PHP_STATUS \
    3 "Django (Python pip)" $DJANGO_STATUS \
    4 "Apache HTTP Server" $APACHE_STATUS \
    5 "Nginx" $NGINX_STATUS \
    6 "MariaDB / MySQL" $MYSQL_STATUS \
    7 "PostgreSQL" off \
    8 "SQLite3" off \
    9 "phpMyAdmin" off \
    10 "Composer (PHP dependency manager)" off \
    11 "Install everything in this section" off 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1) install_pkg nodejs; install_pkg npm ;;
            2) install_pkg php; install_pkg php-cli; install_pkg php-fpm ;;
            3) install_pkg python3-django ;;
            4) install_pkg httpd ;;
            5) install_pkg nginx ;;
            6) install_pkg mariadb-server ;;
            7) install_pkg postgresql ;;
            8) install_pkg sqlite3 ;;
            9) install_pkg phpmyadmin ;;
            10) install_pkg composer ;;
            11) install_pkg nodejs; install_pkg npm; install_pkg php; install_pkg php-cli; install_pkg php-fpm; install_pkg python3-django; install_pkg httpd; install_pkg nginx; install_pkg mariadb-server; install_pkg postgresql; install_pkg sqlite3; install_pkg phpmyadmin; install_pkg composer ;;
        esac
    done
}

# ===============================
# Section: IDEs & Editors
# ===============================
section_ides() {
    VIM_STATUS="off"; MICRO_STATUS="off"; EMACS_STATUS="off"; ECLIPSE_STATUS="off"; NETBEANS_STATUS="off"

    is_installed vim && VIM_STATUS="on"
    is_installed micro && MICRO_STATUS="on"
    is_installed emacs && EMACS_STATUS="on"
    is_installed eclipse && ECLIPSE_STATUS="on"
    is_installed netbeans && NETBEANS_STATUS="on"

    dialog --title "IDEs & Editors" --checklist "Select tools to install:" 20 60 8 \
    1 "Vim" $VIM_STATUS \
    2 "Micro" $MICRO_STATUS \
    3 "Emacs" $EMACS_STATUS \
    4 "Eclipse" $ECLIPSE_STATUS \
    5 "NetBeans" $NETBEANS_STATUS \
    6 "VS Code (opens browser)" off \
    7 "Install everything in this section" off 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1) install_pkg vim ;;
            2) install_pkg micro ;;
            3) install_pkg emacs ;;
            4) install_pkg eclipse ;;
            5) install_pkg netbeans ;;
            6) command -v xdg-open &>/dev/null && xdg-open https://code.visualstudio.com/download ;;
            7) install_pkg vim; install_pkg micro; install_pkg emacs; install_pkg eclipse; install_pkg netbeans ;;
        esac
    done
}

# ===============================
# Section: Debuggers & Tools
# ===============================
section_debuggers() {
    GDB_STATUS="off"; STRACE_STATUS="off"; LTRACE_STATUS="off"; VALGRIND_STATUS="off"; CMAKE_STATUS="off"; GIT_STATUS="off"; HTOP_STATUS="off"

    is_installed gdb && GDB_STATUS="on"
    is_installed strace && STRACE_STATUS="on"
    is_installed ltrace && LTRACE_STATUS="on"
    is_installed valgrind && VALGRIND_STATUS="on"
    is_installed cmake && CMAKE_STATUS="on"
    is_installed git && GIT_STATUS="on"
    is_installed htop && HTOP_STATUS="on"

    dialog --title "Debuggers & Tools" --checklist "Select tools to install:" 20 60 8 \
    1 "GDB" $GDB_STATUS \
    2 "strace" $STRACE_STATUS \
    3 "ltrace" $LTRACE_STATUS \
    4 "Valgrind" $VALGRIND_STATUS \
    5 "CMake" $CMAKE_STATUS \
    6 "Git" $GIT_STATUS \
    7 "htop" $HTOP_STATUS \
    8 "Install everything in this section" off 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1) install_pkg gdb ;;
            2) install_pkg strace ;;
            3) install_pkg ltrace ;;
            4) install_pkg valgrind ;;
            5) install_pkg cmake ;;
            6) install_pkg git ;;
            7) install_pkg htop ;;
            8) install_pkg gdb; install_pkg strace; install_pkg ltrace; install_pkg valgrind; install_pkg cmake; install_pkg git; install_pkg htop ;;
        esac
    done
}

# ===============================
# Section: Game Engines
# ===============================
section_gameengines() {
    GODOT_STATUS="off"
    is_installed godot && GODOT_STATUS="on"

    dialog --title "Game Engines" --checklist "Select tools to install:" 10 50 3 \
    1 "Godot" $GODOT_STATUS \
    2 "Install everything in this section" $GODOT_STATUS 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1|2) install_pkg godot ;;
        esac
    done
}

# ===============================
# Section: Graphics & Design
# ===============================
section_graphics() {
    BLENDER_STATUS="off"; GIMP_STATUS="off"; INKSCAPE_STATUS="off"; KRITA_STATUS="off"

    is_installed blender && BLENDER_STATUS="on"
    is_installed gimp && GIMP_STATUS="on"
    is_installed inkscape && INKSCAPE_STATUS="on"
    is_installed krita && KRITA_STATUS="on"

    dialog --title "Graphics & Design Tools" --checklist "Select tools to install:" 15 60 6 \
    1 "Blender 3D" $BLENDER_STATUS \
    2 "GIMP (Photoshop Alternative)" $GIMP_STATUS \
    3 "Inkscape (Illustrator Alternative)" $INKSCAPE_STATUS \
    4 "Krita (Photoshop Alternative)" $KRITA_STATUS \
    5 "Install everything in this section" off 2> "$TMP"

    [ $? -ne 0 ] && return 1
    read -r -a ITEMS <<< "$(cat "$TMP")"
    for i in "${ITEMS[@]}"; do
        case $i in
            1) install_pkg blender ;;
            2) install_pkg gimp ;;
            3) install_pkg inkscape ;;
            4) install_pkg krita ;;
            5) install_pkg blender; install_pkg gimp; install_pkg inkscape; install_pkg krita ;;
        esac
    done
}

# ===============================
# Main menu loop
# ===============================
while true; do
    dialog --title "Bungalow – Main Menu" --menu "Choose a section to configure:" 20 60 8 \
    1 "Compilers & Interpreters" \
    2 "Web Development Stack" \
    3 "IDEs & Editors" \
    4 "Debuggers & Tools" \
    5 "Game Engines" \
    6 "Graphics & Design" \
    7 "Exit" 2> "$TMP"

    [ $? -ne 0 ] && break

    CHOICE=$(cat "$TMP")
    case $CHOICE in
        1) section_compilers ;;
        2) section_webdev ;;
        3) section_ides ;;
        4) section_debuggers ;;
        5) section_gameengines ;;
        6) section_graphics ;;
        7) break ;;
    esac
done

# ===============================
# Clear screen at exit
# ===============================
dialog --title "Finished" --yesno "Do you want to clear the terminal screen after exiting?" 7 50
[ $? -eq 0 ] && clear

rm "$TMP"
echo "May the Penguin be with you! 🐧"
