#!/bin/bash
# ===============================
# BUNGALOW – Linux Dev Toolkit
# Author: Eid Ali <eid.horus@gmail.com>
# ===============================

set -uo pipefail  # Exit on undefined vars and pipe failures (but not on command errors)

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT  # Cleanup on exit

# ===============================
# Detect package manager
# ===============================
detect_package_manager() {
    if command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        dialog --title "Error" --msgbox "Unsupported Linux distribution" 7 50
        exit 1
    fi
}

PKG_MANAGER=$(detect_package_manager)

# ===============================
# Check if dialog is installed
# ===============================
install_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Dialog is not installed. Installing..."
        case "$PKG_MANAGER" in
            apt) sudo apt update && sudo apt install -y dialog ;;
            dnf) sudo dnf install -y dialog ;;
            yum) sudo yum install -y dialog ;;
            pacman) sudo pacman -Sy --noconfirm dialog ;;
            zypper) sudo zypper install -y dialog ;;
            *) echo "Please install 'dialog' manually"; exit 1 ;;
        esac
        
        if ! command -v dialog &> /dev/null; then
            echo "Failed to install dialog"
            exit 1
        fi
    fi
}

install_dialog

# ===============================
# Request sudo password upfront
# ===============================
# Check if we need sudo
if [ "$EUID" -ne 0 ]; then
    dialog --title "Authentication Required" --msgbox "This script requires sudo privileges to install packages.\nYou will be prompted for your password." 8 60
    
    # Prompt for password (this caches it for subsequent sudo commands)
    sudo -v
    
    # Check if sudo was successful
    if [ $? -ne 0 ]; then
        dialog --title "Error" --msgbox "Authentication failed. Exiting." 7 40
        exit 1
    fi
    
    # Keep sudo session alive in background
    while true; do
        sudo -n true
        sleep 50
        kill -0 "$" 2>/dev/null || exit
    done 2>/dev/null &
fi

# ===============================
# Splash Screen
# ===============================
dialog --title "🏠 Bungalow – Linux Dev Toolkit" --msgbox "\
Welcome to Bungalow!
Author: Eid Ali <eid.horus@gmail.com>
For The Love Of Linux
May the Penguin be with you! 🐧" 15 60

# ===============================
# Package name mapping for cross-distro support
# ===============================
get_package_name() {
    local generic_name="$1"
    
    case "$PKG_MANAGER" in
        apt)
            case "$generic_name" in
                nodejs) echo "nodejs npm" ;;
                default-jdk) echo "default-jdk" ;;
                python-flask) echo "python3-flask" ;;
                python-django) echo "python3-django" ;;
                composer) echo "composer" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        pacman)
            case "$generic_name" in
                golang) echo "go" ;;
                default-jdk) echo "jdk-openjdk" ;;
                python-flask) echo "python-flask" ;;
                python-django) echo "python-django" ;;
                composer) echo "composer" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        dnf|yum)
            case "$generic_name" in
                default-jdk) echo "java-latest-openjdk-devel" ;;
                python-flask) echo "python3-flask" ;;
                python-django) echo "python3-django" ;;
                composer) echo "composer" ;;
                *) echo "$generic_name" ;;
            esac
            ;;
        *)
            echo "$generic_name"
            ;;
    esac
}

# ===============================
# Package installation function
# ===============================
install_pkg() {
    local package="$1"
    local actual_package
    actual_package=$(get_package_name "$package")
    local result=0
    
    case "$PKG_MANAGER" in
        apt) 
            sudo apt update &> /dev/null
            sudo apt install -y $actual_package 2>&1 | dialog --programbox "Installing $package..." 20 70
            result=${PIPESTATUS[0]}
            ;;
        dnf) 
            sudo dnf install -y $actual_package 2>&1 | dialog --programbox "Installing $package..." 20 70
            result=${PIPESTATUS[0]}
            ;;
        yum) 
            sudo yum install -y $actual_package 2>&1 | dialog --programbox "Installing $package..." 20 70
            result=${PIPESTATUS[0]}
            ;;
        pacman) 
            sudo pacman -Sy --noconfirm $actual_package 2>&1 | dialog --programbox "Installing $package..." 20 70
            result=${PIPESTATUS[0]}
            ;;
        zypper) 
            sudo zypper install -y $actual_package 2>&1 | dialog --programbox "Installing $package..." 20 70
            result=${PIPESTATUS[0]}
            ;;
    esac
    
    if [ $result -eq 0 ]; then
        dialog --title "Success" --msgbox "$package installed successfully!" 7 50
    else
        dialog --title "Error" --msgbox "Failed to install $package" 7 50
    fi
}

# ===============================
# Check if a package is installed
# ===============================
is_installed() {
    local package="$1"
    local actual_package
    actual_package=$(get_package_name "$package")
    
    case "$PKG_MANAGER" in
        apt) dpkg -s $actual_package &> /dev/null ;;
        dnf|yum) rpm -q $actual_package &> /dev/null ;;
        pacman) pacman -Q $actual_package &> /dev/null ;;
        zypper) rpm -q $actual_package &> /dev/null ;;
    esac
}

# ===============================
# Section: Compilers & Interpreters
# ===============================
section_compilers() {
    dialog --title "Compilers & Interpreters" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 20 70 10 \
    "gcc" "GNU C Compiler" $(is_installed gcc && echo "on" || echo "off") \
    "g++" "GNU C++ Compiler" $(is_installed g++ && echo "on" || echo "off") \
    "python3" "Python Interpreter" $(is_installed python3 && echo "on" || echo "off") \
    "rustc" "Rust Compiler" $(is_installed rustc && echo "on" || echo "off") \
    "golang" "Go Programming Language" $(is_installed golang && echo "on" || echo "off") \
    "clang" "LLVM C/C++ Compiler" $(is_installed clang && echo "on" || echo "off") \
    "default-jdk" "Java Development Kit (OpenJDK)" $(is_installed default-jdk && echo "on" || echo "off") \
    "ruby" "Ruby Interpreter" $(is_installed ruby && echo "on" || echo "off") \
    "perl" "Perl Interpreter" $(is_installed perl && echo "on" || echo "off") \
    2> "$TMP"
    
    # If user cancelled, just return to main menu
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    # If nothing selected, return to main menu
    if [ -z "$selections" ]; then
        return
    fi
    
    for pkg in $selections; do
        pkg=$(echo "$pkg" | tr -d '"')
        if ! is_installed "$pkg"; then
            install_pkg "$pkg"
        fi
    done
}

# ===============================
# Section: Web Development Stack
# ===============================
section_webdev() {
    dialog --title "Web Development Stack" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 20 70 12 \
    "nodejs" "Node.js JavaScript Runtime" $(is_installed nodejs && echo "on" || echo "off") \
    "nginx" "High-performance Web Server" $(is_installed nginx && echo "on" || echo "off") \
    "apache2" "Apache HTTP Server" $(is_installed apache2 && echo "on" || echo "off") \
    "php" "PHP Scripting Language" $(is_installed php && echo "on" || echo "off") \
    "composer" "PHP Dependency Manager" $(is_installed composer && echo "on" || echo "off") \
    "python-flask" "Flask - Python Web Framework" $(is_installed python-flask && echo "on" || echo "off") \
    "python-django" "Django - Python Web Framework" $(is_installed python-django && echo "on" || echo "off") \
    "mysql-server" "MySQL Database Server" $(is_installed mysql-server && echo "on" || echo "off") \
    "postgresql" "PostgreSQL Database" $(is_installed postgresql && echo "on" || echo "off") \
    "redis-server" "Redis In-Memory Database" $(is_installed redis-server && echo "on" || echo "off") \
    "mongodb" "MongoDB NoSQL Database" $(is_installed mongodb && echo "on" || echo "off") \
    2> "$TMP"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    if [ -z "$selections" ]; then
        return
    fi
    
    # Special handling for Symfony (requires Composer)
    if echo "$selections" | grep -q "composer"; then
        for pkg in $selections; do
            pkg=$(echo "$pkg" | tr -d '"')
            if ! is_installed "$pkg"; then
                install_pkg "$pkg"
            fi
        done
        
        # Offer to install Symfony after Composer is installed
        if is_installed "composer"; then
            dialog --title "Symfony Framework" --yesno "Composer is installed. Would you like to install Symfony CLI?" 7 60
            if [ $? -eq 0 ]; then
                dialog --title "Symfony Installation" --msgbox "Run this command to install Symfony CLI:\n\ncurl -sS https://get.symfony.com/cli/installer | bash" 10 70
            fi
        fi
    else
        for pkg in $selections; do
            pkg=$(echo "$pkg" | tr -d '"')
            if ! is_installed "$pkg"; then
                install_pkg "$pkg"
            fi
        done
    fi
}

# ===============================
# Section: IDEs & Editors
# ===============================
section_ides() {
    dialog --title "IDEs & Editors" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 22 70 12 \
    "vim" "Vi IMproved Text Editor" $(is_installed vim && echo "on" || echo "off") \
    "emacs" "GNU Emacs Text Editor" $(is_installed emacs && echo "on" || echo "off") \
    "nano" "Simple Terminal Text Editor" $(is_installed nano && echo "on" || echo "off") \
    "micro" "Modern Terminal Text Editor" $(is_installed micro && echo "on" || echo "off") \
    "gedit" "GNOME Text Editor" $(is_installed gedit && echo "on" || echo "off") \
    "kate" "KDE Advanced Text Editor" $(is_installed kate && echo "on" || echo "off") \
    "atom" "Atom Text Editor (GitHub)" $(is_installed atom && echo "on" || echo "off") \
    "vscode" "Visual Studio Code (Microsoft)" off \
    "sublime-text" "Sublime Text Editor" $(is_installed sublime-text && echo "on" || echo "off") \
    "geany" "Lightweight IDE" $(is_installed geany && echo "on" || echo "off") \
    2> "$TMP"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    if [ -z "$selections" ]; then
        return
    fi
    
    for pkg in $selections; do
        pkg=$(echo "$pkg" | tr -d '"')
        
        # Special handling for VS Code
        if [ "$pkg" = "vscode" ]; then
            dialog --title "Visual Studio Code" --msgbox "VS Code requires manual installation.\n\nOpening download page in your browser..." 9 60
            
            # Try to open browser (suppress output)
            if command -v xdg-open &> /dev/null; then
                xdg-open "https://code.visualstudio.com/download" &> /dev/null &
            elif command -v firefox &> /dev/null; then
                firefox "https://code.visualstudio.com/download" &> /dev/null &
            elif command -v chromium &> /dev/null; then
                chromium "https://code.visualstudio.com/download" &> /dev/null &
            elif command -v google-chrome &> /dev/null; then
                google-chrome "https://code.visualstudio.com/download" &> /dev/null &
            else
                dialog --title "VS Code" --msgbox "Could not open browser automatically.\n\nPlease visit:\nhttps://code.visualstudio.com/download" 10 60
            fi
            continue
        fi
        
        # Install other packages normally
        if ! is_installed "$pkg"; then
            install_pkg "$pkg"
        fi
    done
}

# ===============================
# Section: Debuggers & Tools
# ===============================
section_debuggers() {
    dialog --title "Debuggers & Development Tools" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 20 70 10 \
    "gdb" "GNU Debugger" $(is_installed gdb && echo "on" || echo "off") \
    "valgrind" "Memory Debugger & Profiler" $(is_installed valgrind && echo "on" || echo "off") \
    "strace" "System Call Tracer" $(is_installed strace && echo "on" || echo "off") \
    "ltrace" "Library Call Tracer" $(is_installed ltrace && echo "on" || echo "off") \
    "git" "Version Control System" $(is_installed git && echo "on" || echo "off") \
    "make" "Build Automation Tool" $(is_installed make && echo "on" || echo "off") \
    "cmake" "Cross-platform Build System" $(is_installed cmake && echo "on" || echo "off") \
    "docker.io" "Container Platform" $(is_installed docker.io && echo "on" || echo "off") \
    2> "$TMP"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    if [ -z "$selections" ]; then
        return
    fi
    
    for pkg in $selections; do
        pkg=$(echo "$pkg" | tr -d '"')
        if ! is_installed "$pkg"; then
            install_pkg "$pkg"
        fi
    done
}

# ===============================
# Section: Game Engines
# ===============================
section_gameengines() {
    dialog --title "Game Development" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 20 70 10 \
    "godot" "Godot Game Engine" $(is_installed godot && echo "on" || echo "off") \
    "libsdl2-dev" "SDL2 Development Library" $(is_installed libsdl2-dev && echo "on" || echo "off") \
    "libsfml-dev" "SFML Game Library" $(is_installed libsfml-dev && echo "on" || echo "off") \
    2> "$TMP"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    if [ -z "$selections" ]; then
        dialog --title "Note" --msgbox "Unity and Unreal Engine require manual installation from their websites." 8 60
        return
    fi
    
    for pkg in $selections; do
        pkg=$(echo "$pkg" | tr -d '"')
        if ! is_installed "$pkg"; then
            install_pkg "$pkg"
        fi
    done
}

# ===============================
# Section: Graphics & Design
# ===============================
section_graphics() {
    dialog --title "Graphics & Design Tools" --checklist \
    "Select packages to install (Space to select, Enter to confirm):" 20 70 10 \
    "gimp" "Image Editor (Photoshop Alternative)" $(is_installed gimp && echo "on" || echo "off") \
    "inkscape" "Vector Graphics (Illustrator Alternative)" $(is_installed inkscape && echo "on" || echo "off") \
    "blender" "3D Modeling & Animation" $(is_installed blender && echo "on" || echo "off") \
    "krita" "Digital Painting (Photoshop Alternative)" $(is_installed krita && echo "on" || echo "off") \
    "darktable" "Photo Editor (Lightroom Alternative)" $(is_installed darktable && echo "on" || echo "off") \
    "kdenlive" "Video Editor (Premiere Alternative)" $(is_installed kdenlive && echo "on" || echo "off") \
    "audacity" "Audio Editor (Audition Alternative)" $(is_installed audacity && echo "on" || echo "off") \
    "openscad" "3D CAD Modeler" $(is_installed openscad && echo "on" || echo "off") \
    2> "$TMP"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    selections=$(cat "$TMP")
    
    if [ -z "$selections" ]; then
        return
    fi
    
    for pkg in $selections; do
        pkg=$(echo "$pkg" | tr -d '"')
        if ! is_installed "$pkg"; then
            install_pkg "$pkg"
        fi
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
    
    # Check if user cancelled (ESC)
    if [ $? -ne 0 ]; then
        break
    fi
    
    CHOICE=$(cat "$TMP")
    
    case "$CHOICE" in
        1) section_compilers ;;
        2) section_webdev ;;
        3) section_ides ;;
        4) section_debuggers ;;
        5) section_gameengines ;;
        6) section_graphics ;;
        7) break ;;
        *) continue ;;
    esac
done

# ===============================
# Exit cleanup
# ===============================
dialog --title "Finished" --yesno "Do you want to clear the terminal screen?" 7 50
[ $? -eq 0 ] && clear

echo "May the Penguin be with you! 🐧"
