#! /bin/bash
# this script will clear out space on a GHub device
# in specific:
# - tempory Docker files
# - media data files (pictures only, video models are left alone)
# - HttpRequestComponent request/receive output

set -ueEo pipefail  # basic script hygine for errors
spaceSaved=0 # total space deleted, in bytes
filesDeleted=0
cdir=`pwd` # store the current directory
clear_docker=false
clear_images=false
clear_action=false
clear_root=false
clear_logs=false
do_update=false

print_usage() {
  printf "Usage: 
    -u Updates this script to the ltest version (must be run with Sudo. Cannto be combined with other flags)
    -a Deletes logged HttpRequestComponent Request/Response dump files
    -i Deletes stored image media data
    -r Deletes old files in the /root directory, including unused .zip and .tar files
    -d Deletes old docker temporary data [nb: if used, you must restart the GHub after the script finished]
    -l Compresses important logs to a .tar.gz file, and deletes the uncompressed ones

    Example (full usage):
        ./clear.sh -a -i -r -d -l
    Example (just actions):
        ./clear.sh -a
  "
}

while getopts ':adrlivu' flag; do
case "${flag}" in
    u) do_update=true ;;
    a) clear_action=true ;;
    d) clear_docker=true ;;
    i) clear_images=true ;;
    r) clear_root=true ;;
    l) clear_logs=true ;;
    v) verbose=true ;;
    *) print_usage
    exit 1 ;;
esac
done

timestamp() {
  date +"%Y_%m_%d_%H_%M_%S" # current time
}

clearLogs() {
    echo "Clearing log files..."    
    # first check that we have space
    # if no space, then we delete fail?
    # then we .tar.gz all our log files
    glogs="/home/gravio/hubkitrepo/log"
    syslog="/var/log/syslog"
    if [[ -d "$glogs" ]]
    then
        
        del=`find $glogs -type f | wc -l`
        filesDeleted=$(($filesDeleted + $del))
        size=`du -b $glogs | cut -f1 | head -n 1`
        spaceSaved=$(($spaceSaved + $size))

        logName=~/logbackup_$(timestamp).tar.gz
        tar -czf $logName $glogs $syslog
        # then delete the original logs
        rm -rf $glogs
        rm -r /var/log/syslog*
        rm -r /var/log/*.gz
        # then tell user where we stored the log zip
        b2mb=$(bytes2mb $size)
        echo -e "\tFinished removing log data - removed $b2mb MB and $del files" 
        echo "Backup log files have been stored at $logName"
    else
        echo "No log files existed, nothing to clear"
    fi
}

clearMiscFromRoot() {
    ddir="/root"
    echo "Clearing out old root folder data from $ddir..."
    if compgen -G "/tmp/someFiles*" > /dev/null; then
        size=`sudo du -b $ddir/*.tar | cut -f1 | awk '{s+=$1} END {printf "%.0f\n", s}'`
        spaceSaved=$(($spaceSaved + $size))
        del=`find $ddir/*.tar -type f | wc -l`
        filesDeleted=$(($filesDeleted + $del))

        rm -f $ddir/*.tar

        b2mb=$(bytes2mb $size)
        echo -e "\tFinished clearing out old root folder data - removed $b2mb MB and $del files"
    else
        echo -e "\tNo old files were found in $ddir, nothing to clean"
    fi
}

clearDockerTemp() {
    ddir="/var/lib/docker/tmp"
    echo "Clearing out docker temporary data located at $ddir..."
    if [[ -d "$ddir" ]]
    then
        del=`find $ddir -type f | wc -l`
        filesDeleted=$(($filesDeleted + $del))
        size=`du -b $ddir | cut -f1 | head -n 1`
        spaceSaved=$(($spaceSaved + $size))
        docker-compose down
        rm -rf $ddir/*
        b2mb=$(bytes2mb $size)
        echo -e "\tFinished clearing out docker temporary data - removed $b2mb MB and $del files" 
    else
        echo -e "\tdocker temporary directory did not exist, nothing to clean."
    fi
}

clearSavedImages() {
    ddir="/home/gravio/hubkitrepo/data/mediadata"
    echo "Clearing out media images located at $ddir..."
    if [[ -d "$ddir" ]]
    then
        del=`find $ddir -type f | wc -l`
        filesDeleted=$(($filesDeleted + $del))
        size=`du -b $ddir | cut -f1 | head -n 1`
        spaceSaved=$(($spaceSaved + $size))
        rm -rf $ddir/*
        b2mb=$(bytes2mb $size)
        echo -e "\tFinished clearing out media data directory - removed $b2mb MB and $del files" 
    else
        echo -e "\tmedia data directory did not exist, nothing to clean."
    fi
}

clearActionHttpRequestLogs() {
    ddir="/home/gravio/hubkitrepo/data/action/data/Engine.Components.Action.SendHttpRequestdump"
    echo "Clearing out action execution http request dumps located at $ddir..."
    if [[ -d "$ddir" ]]
    then
        del=`find $ddir -type f | wc -l`
        filesDeleted=$(($filesDeleted + $del))
        size=`du -b $ddir | cut -f1 | head -n 1`
        spaceSaved=$(($spaceSaved + $size))
        mv $ddir ./delme # move folder to temp folder because highly active components will write to the folder often enough to cause rm to fail
        rm -rf ./delme # purposefully deleting the whole folder. Argument list may get too long otherwise.
        b2mb=$(bytes2mb $size)
        echo -e "\tFinished clearing out media data directory - removed $b2mb MB and $del files" 
    else
        echo -e "\taction data directory did not exist, nothing to clean."
    fi
}

update() {
    # only root can run the update because we need to do a chmod +x on it
    if [ "$EUID" -ne 0 ]
        then echo "Please run as root to update this script"
        exit
    fi
    
    rm -f ~/ghcu.sh
    wget -P ~/ https://raw.githubusercontent.com/0xNF/ghcu/master/src/ghcu.sh
    chmod +x ~/ghcu.sh
    echo "Updated to latest version of ghcu"
}



bytes2mb() {
    f=$(($1/1024))
    f=$(($f/1024))
    echo $f
}

finish() {
    b2mb=$(bytes2mb spaceSaved)
    echo "Clear Unusued has finished successfully. A total of $b2mb MB and $filesDeleted files were deleted"
    if $clear_docker; then
        echo -e "\e[41mPlease reboot this GHub with 'sudo reboot -f'\e[0m"
    fi
}

main() {
    # Get Flags
    if $do_update; then
        update
        exit
    fi
    if $clear_root; then
        clearMiscFromRoot
    fi
    if $clear_images; then
        clearSavedImages
    fi
    if $clear_action; then
        clearActionHttpRequestLogs
    fi
    if $clear_docker; then
        clearDockerTemp
    fi
    if $clear_logs; then
        clearLogs
    fi
    finish
}

main
echo "testing"