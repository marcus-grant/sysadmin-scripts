#!/bin/bash

# A backup script that uses --link-dest to hardlink differences in changed files.
# This means that it will also preserve deletions.
# Basically after the first copy, all subsequent copies will have
# links created if the files haven't changed.
# If they have changed, then a new copy is created.
# These incremental changes are managed with a timestamped folder
# that is linked to the previous timestamped folder.

# BackupDir0        HardDrive       BackupDir1
# ============================================
#   FileA ----> | FileA Sectors  | <---- FileA
#   FileB0 ---> | FileB0 Sectors |
#               | FileB1 Sectors | <---- FileB1
#               | FileC Sectors  | <---- FileC
#   FileD ----> | FileD Sectors  |

# In the above example, the first backup (BackupDir0) has three files:
# FileA, FileB, & FileD.
# Then those are the only files pointing to hard drive sectors.
# When the second backup occurs (BackupDir1) a couple of things happen:
# First, FileD was removed from the backup source,
# That's known because (BackupDir1) doesn't point to any FileD sectors.
# However, because FileD gets pointed to by FileD inside BackupDir0,
# that link preserves the FileD sectors on disk.
# Once BackupDir0 gets deleted no link is pointing to FileD sectors,
# thus those sectors get marked for removal by the OS.
# Secondly, FileC isn't written to the hard disk until BackupDir1 is made.
# This means that the backup source has created FileC between the backups.
# Thirdly, FileB0 is a file that was included in the original backup.
# However, when BackupDir1 is created, FileB0 was changed.
# This means that a new FileB link needs to be created (FileB1).
# Even if only one character in a text file was changed,
# that will require new hard drive sectors to be created to
# preserve the new and old versions of the file.

# This has some implications:
# 1. File changes between backups saves new versions of the files.
#   * If a source file has an unwanted change or corruption
#       it's possible to restore it to a previous state.
#   * However it also means that files that frequently change will
#       require a lot of extra storage for their variations.
# 2. Deleted files from backup source remain on destination disk in older backups
#   * This will mean old files will continue to take disk space.
#   * But, they can be recovered if something goes wrong on the source.
# 3. Each backup directory represents a snapshot of the disk at backup time.
# 4. Deleting the oldest directory will only remove files from disk
#       that only existed during the first backup.

# Here is the basic structure of the command:
# rsync -aP --link-dest=PATH_OF/$PREVIOUS_BACKUP $SOURCE $CURRENTBACKUP
# -a: Archive mode - A macro parameter that includes a lot of useful parameters
#                   Includes:
#                               - recursion through directories
#                               - copy symlinks as symlinks
#                               - preserve permissions
#                               - preserve modification times
#                               - preserve user:group ownership
#                               - preserve device files
# -P: Allows rsync to continue interrupted transfers & shows progress of files.
# --link-dest: This is where the snapshot magic happens.
#               - Hardlinks use VERY little space to copy files by reference.
#               - Links unchanged files to previous backup '$PREVIOUS_BACKUP'
#               - Only claims space for changed or added files.
#               - This only works after a previous backup has been made
#               - This means that a simple rsync backup needs to be made first
# PATH_OF/$PREVIOUS_BACKUP: is the path on the destination disk to link with.
#               - Again, needs to be an existing destination backup to compare.
#               - This is a path on the destination, not the source.
# $SOURCE: is the directory to backup.
# $CURRENTBACKUP: is the directory to create the newest backup on destination.

# First let's create some helper functions to reduce amount of code
function print-usage() {
    echo "rsync-snapshot: An incremental snapshoting backup script using rsync"
    local commBar="========================================"
    local commBar="$commBar========================================"
    echo $commBar
    echo
    echo "usage: rsync-snapshot [options] SOURCE_DIR DEST_DIR"
    echo "SOURCE_DIR:   The source directory to create snapshoting backups of"
    echo "DEST_DIR:     The destination directory to store snapshoting backups"
    echo "              If a remote computer use form: DEST_ADDR:DEST_DIR"
    echo "              Here are the timestamped backup directories each..."
    echo "              ...containing a snapshot of the contents of SOURCE_DIR"
    echo "              example:"
    echo "              DEST_DIR/"
    echo "                  2018-02-10_23_30_59/"
    echo "                      FileA"
    echo "                      FileB0"
    echo "                      FileD"
    echo "                  2018-02-11_09_45_01/"
    echo "                      FileA"
    echo "                      FileB1"
    echo "                      FileC"
    echo "                  latest -> ./2018-02-11_09_45_01"
    echo
    echo " Optional options:"
    echo
    echo "-l PATH_TO_LOGFILE:       Enables logging output to a log"
    echo "                          - The log is located in PATH_TO_LOGFILE"
    echo "                          - The path has to be valid"
    echo
    echo "-i PATH_TO_SSH_ID:        Specify an SSH ID file to use"
    echo "                          - Throws error if not using remote host"
    echo
    echo "-p SSH_PORT:              Specify an SSH port to use"
    echo "                          - Defaults to 22"
    echo "                          - Throws error if not using remote host"
    echo
    echo "-c SSH_CONFIG_HOST:       Specify a HostName from SSH config file"
    echo "                          - If ssh config file exists, specify a host"
    echo "                          - Throws error if not using remote host"
    # TODO: Quiet mode where it can still log, by forking process
}

# Then, let's capture arguments for calling this script & set them to variables
sourceDir=""
destNewDir=""
destPrevDir=""
logDir=""
remoteHost=""
remotePort=""
remoteIDFile=""
remoteSSHHostName=""

function parse-args() {
    positional=()
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -l)
                extension="$2"
                shift # past argument
                shift # past value
            ;;
            -i)
                extension="$2"
                shift # past argument
                shift # past value
            ;;
            -p)
                extension="$2"
                shift # past argument
                shift # past value
            ;;
            -c)
                extension="$2"
                shift # past argument
                shift # past value
            ;;
        esac
    done
}

# Here is an a simple function that makes an incremental backup everytime it's called.
# rsync -Pav -e "ssh -i $HOME/.ssh/somekey" /from/dir/ username@hostname:/to/dir/
