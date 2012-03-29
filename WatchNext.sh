#!/bin/bash
# Watch next episode in the dir.  We'll assume the filenames will contain the
# needed information to stay chronological.

DIRS=~/.watched_what
DRYRUN=false
CURDIR=`pwd`
DONTRUN=false
PLAYER='mplayer -fs'

# Force current file in curdir to this {{{
doreset() {
    if $DRYRUN ; then
        echo Reset to $1.
    else
        sed -i "s|^$CURDIR	.*$|$CURDIR	$1|" $DIRS
    fi
    exit 0
    # TODO case of new dir
}

# }}}
# Arguments {{{
usage() {
    echo "Watch shows and this keeps record of them for you."
    echo "Usage: `basename $0` [options] "
    echo "   -h         this help"
    echo "   -d         do a dry run"
    echo "   -r <file>  reset to this file"
    echo "   -m         don't run mplayer; just print the next"
    echo "   -v         run vlc instead"
    exit
}
while getopts ":hdr:mv" flag
do
    case "$flag" in
        d) DRYRUN=true ;;
        h) usage ;;
        r) doreset "$OPTARG" ;;
        m) DONTRUN=true ;;
        v) PLAYER='vlc' ;;
       \?) echo "Invalid option -$OPTARG"
           echo
           usage ;;
        :) echo "Option -$OPTARG needs an argument!"
           echo
           usage ;;
    esac
done
shift $((OPTIND-1))

#}}}

# check if there's a record in $DIRS. We'll act according to that.
LASTWATCHED=`grep "$CURDIR	" $DIRS|cut -f 2`

if [ -z "$LASTWATCHED" ]
then
    # Directory with no records. We'll pick the first one
    UPNEXT=`find . -maxdepth 1 -type f|sort -f |head -n 1 | sed -e "s#^\./##"`
    LASTWATCHED='(none, starting from beginning)'

    # mark the spot
    if $DRYRUN ; then
        echo -e "$CURDIR	$UPNEXT"
    else
        echo -e "$CURDIR	$UPNEXT" >> $DIRS
    fi



else
    # we have a record
    UPNEXT=`find . -maxdepth 1 -type f|sort -f |
        sed "0,/$LASTWATCHED/d" | head -n 1 | sed -e "s#^\./##"`
    
    # update on the spot
    if ! $DRYRUN ; then
        # ok, this fails with & chars in there
        # i'd prefer a non-regexp solution to this anyway
        sed -i "s|^$CURDIR	$LASTWATCHED$|$CURDIR	$UPNEXT|" $DIRS
    fi
fi

# Dryrun
if $DRYRUN ; then
    echo Last watched: $LASTWATCHED
    echo Up next: $UPNEXT
    exit 0
fi

if $DONTRUN ; then
    echo Up next: $UPNEXT
else
    $PLAYER "$UPNEXT"
fi
