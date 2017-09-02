#!/bin/bash - 
#===============================================================================
#
#          FILE: pacman-update-pgp.sh
# 
#         USAGE: ./pacman-update-pgp.sh 
# 
#   DESCRIPTION: Updates PGP keys for pacman
#                   Run if pacman -Syyu reports corrupted packages
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 09/02/2017 15:54
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

sudo pacman-key --init
sudo pacman-key --populate archlinux antergos
sudo pacman-key --refresh-keys
sudo pacman -Syyu
