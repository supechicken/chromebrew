#!/bin/bash
# main
GREEN='\e[1;32m';
RED='\e[1;31m';
BLUE='\e[1;34m';
YELLOW='\e[1;33m';
RESET='\e[0m'
CREW_PREFIX=/usr/local
CREW_LIB_PREFIX=${CREW_PREFIX}/lib
EXTENSION_PREFIX=~/.extension
PWA_PREFIX=${CREW_LIB_PREFIX}/pwa
SERVER=${PWA_PREFIX}/server.rb
app_path=${EXTENSION_PREFIX}/apps/${2}
help='
===================================
    Chromebrew integration
  -s (Default option) Start shortcut server
  -n (App Name)       Make a new shortcut
  -h                  Show this message
  -g                  PWA icon chooser
  -i                  Available preinstalled icons for PWA icon chooser
  -d                  Generate shortcuts from .desktop files (stable but not recommended)
==================================='
case ${1} in
  -s)
       ruby ${SERVER}
       ;;
  -n)
       mkdir -p ${app_path}
       cp $PWA_PREFIX/tools/* ${app_path}
       manifest=${app_path}/manifest.json
       installer=${app_path}/installer.html
       starter=${app_path}/starter.html
       js=${app_path}/starter.js
       
       sed -i "s/linuxapp/${2^}/g" ${manifest}
       sed -i "s/unixapp/${2}/g" ${manifest} 
       
       sed -i "s/app/${2^}/g" ${installer}
       
       sed -i "s/app/${2}/g" ${starter}
       
       sed -i "s/app/${2}/g" ${js}
       #######################################
       # icon
       if [ -f ${PWA_PREFIX}/tools/icons/}]
       icon () { ls -1 ${CREW_PREFIX}/share/pixmaps 2> /dev/null | grep "${2}"; }
       if [[ $(icon) != '' ]]; then
         num=$(icon | wc -l)
         if [[ num = 1 ]]; then
           convert $(icon) ${app_path}/icon.png
         else
           echo -e "${BLUE}${num} icons were found for ${2^}, here is the path of them"
           icon
           read -r -p "Which icon do you want to use (Enter the path): " icon_path
           convert ${iconpath} ${app_path}/icon.png
           echo -e "${RESET}"
         fi
       else
         echo -e "${RED}${2^} does not provide any icon :/ Using default Chromebrew icon."
         cp $PWA_PREFIX/icons/brew.png $app_prefix
       fi
       echo -e "${GREEN}Shortcut for ${2^} deployed!${RESET}"
       exec ruby $PWA_PREFIX/sender.rb "chrome-extension://${extension_id}/apps/${2}/installer.html"
       ;;
  -h)
       echo -e "${BLUE}${help}${RESET}"
       ;;
esac