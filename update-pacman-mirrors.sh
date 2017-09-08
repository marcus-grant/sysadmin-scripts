#!/bin/bash - 
#===============================================================================
#
#          FILE: update-pacman-mirrors.sh
# 
#         USAGE: ./update-pacman-mirrors.sh 
# 
#   DESCRIPTION: A script that updates arch mirrors based on countries then
#                   sorts by bandwidth
# 
#       OPTIONS: None
#  REQUIREMENTS: Must be an Arch installation, DUH
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Marcus Grant, marcus.grant@patternbuffer.io
#  ORGANIZATION: 
#       CREATED: 09/07/2017 22:57
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#sudo reflector --verbose --country 'United States' -l 10 -p http --sort rate --save /etc/pacman.d/mirrorlist

sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

sudo rankmirrors -v -n 10 /etc/pacman.d/mirrorlist.usca > /etc/pacman.d/mirrorlist
