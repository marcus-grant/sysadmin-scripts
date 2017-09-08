#!/bin/bash - 
#===============================================================================
#
#          FILE: md5-check.sh
# 
#         USAGE: ./md5-check.sh 
# 
#   DESCRIPTION: A script that verifies an input file's md5 sum with a given one
# 
#       OPTIONS: $1 : an input file to check the md5 hash against
#                $0 : a string representing an md5 hash to verify against file
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Marcus Grant
#  ORGANIZATION: Pattern Buffer LLC
#       CREATED: 09/07/2017 21:46
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


# main function to contain execution order
main()
{
    #echo $@
	#valid-args "$@"

    #md5sum $1 | grep -i $2

	#md5=`md5sum ${$1} | awk '{ print $1 }'`
	
	#if [ $md5 == $2 ]; then
	#	echo "[SUCCESS]: The MD5 hash matches the computed one of the file"
	#	exit 0
	#else
	#	echo "[FAIL]: The MD5 hash doesn't match the computed one of the file"
	#	exit 1
    #fi

    md5sum $1 | grep -i $2
}

valid-args()
{
    # Check for correct number of args
    if [ $# != 2 ]; then
        echo "[ERROR]: This script requires the use of exactly 2 arguments"
        echo "======== First argument is a valid file path"
        echo "======== Second argument is a valid MD5 sum string"
        exit 126
    fi

    # Check if $1 is a valid file path
    if [ ! -e $1 ]; then
        echo "[ERROR]: This script requires that the first argument is a valid\
            file path to a file or link"
        exit 126
    fi

    # check if $2 is a valid MD5 string
    ## check that it is a 32 character string
    if [ $2 -ne 32 ]; then 
        echo "[ERROR]: The second argument needs to be a valid (32 character)\
            MD5 string" 
        exit 126
    fi

	case $2 in
      ( *[!0-9A-Fa-f]* | "" )  
		echo "[ERROR]: Second argument should be valid hexadecimal string"
		echo "======== String should only contain 0-9 or a-f"
		;;
      ( * )                
        case ${#1} in
          ( 32 | 40 ) return 0 ;;
          ( * )       
			echo "[ERROR]: Second argument should be valid hexadecimal string"
			echo "======== String should only contain 0-9 or a-f"
			exit 126
			;;
        esac
    esac 

	return 0
}


# call to main() to start execution after function definitions
main "$@"
