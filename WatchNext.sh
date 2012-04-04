#!/bin/bash
# Watch next episode in the dir.  We'll assume the filenames will contain the
# needed information to stay chronological.

DIRS=~/.watched_what
DRYRUN=false
CURDIR=`pwd`
DONTRUN=false
PLAYER='mplayer -fs'
EXTENSIONS='avi|mkv|ts|mp4|mpg|mpeg|flv'
FINDARGS="-regextype posix-extended -maxdepth 1 -type f \
    -iregex .*\.($EXTENSIONS)$"

# fn: Check if directory is on $DIRS {{{
is_dir_on() {
    # check if there's a record in $DIRS. We'll act according to that.
    LASTWATCHED=`grep "$CURDIR	" $DIRS|cut -f 2`
    [ ! -z "$LASTWATCHED" ]
}
#}}}
# fn: Force current file in curdir to this {{{
doreset() {
    if $DRYRUN ; then
        echo "Reset to $1. (Didn't do anything during dry run.)"
        exit 0
    fi

    if is_dir_on ; then
        sed -i "s|^$CURDIR	.*$|$CURDIR	$1|" $DIRS
    else
        echo "$CURDIR	$1" >> $DIRS
    fi
    exit 0
}

# }}}
# do arguments {{{
usage() {
    echo "Watch shows and keep a pointer of recently viewed ones."
    echo "Usage: `basename $0` [options] "
    echo "   -h         this help"
    echo "   -d         do a dry run"
    echo "   -r <file>  reset pointer to this file"
    echo "   -m         don't play; just print the next. Advances the pointer."
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
    UPNEXT=`find . $FINDARGS|sort -f |head -n 1 | sed -e "s#^\./##"`
    LASTWATCHED='(none, starting from beginning)'

    # mark the spot
    if $DRYRUN ; then
        echo -e "$CURDIR	$UPNEXT"
    else
        echo -e "$CURDIR	$UPNEXT" >> $DIRS
    fi



else
    # we have a record
    UPNEXT=`find . $FINDARGS|sort -f |
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
