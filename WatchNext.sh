#!/bin/bash
# Watch next episode in the dir.  We'll assume the filenames will contain the
# needed information to stay chronological.

DIRS=~/.watched_what
DRYRUN=false
CURDIR=`pwd`
DONTRUN=false
DEFAULT_PLAYER='mplayer -fs'
EXTENSIONS='avi|mkv|ts|mp4|mpg|mpeg|flv'
FINDPREARGS=' -L '
FINDARGS="-regextype posix-extended -maxdepth 1 -type f \
    -iregex .*\.($EXTENSIONS)$"

if [ -z "$WATCHNEXT_PLAYER" ]
then
    PLAYER="$DEFAULT_PLAYER"
else
    PLAYER="$WATCHNEXT_PLAYER"
fi

###
###
play() {
    mpc pause >> /dev/null 2>&1
    $PLAYER "$1"
}

# fn: Check if directory is on $DIRS {{{
is_dir_on() {
    # check if there's a record in $DIRS. We'll act according to that.
    LASTWATCHED=`grep "$CURDIR	" $DIRS|cut -f 2`
    [ ! -z "$LASTWATCHED" ]
}
#}}}
# fn: Rewatch the recently watched video. {{{
rewatch() {
    LASTWATCHED=`grep "$CURDIR	" $DIRS|cut -f 2`
    if $DRYRUN ;then
        echo "Rewatching $LASTWATCHED"
        exit
    fi
    play "$LASTWATCHED"
    exit
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
    echo "   -w         watch the last video again"
    echo "   -m         don't play; just print the next (advances the pointer)"
    echo "   -f         ignore \$WATCHNEXT_PLAYER, use default ($DEFAULT_PLAYER)"
    echo
    echo "Use env variable \$WATCHNEXT_PLAYER to setup your preferred app."
    exit
}
while getopts ":hdr:mwf" flag
do
    case "$flag" in
        d) DRYRUN=true ;;
        h) usage ;;
        r) doreset "$OPTARG" ;;
        w) DO_REWATCH=true ;;
        m) DONTRUN=true ;;
        f) PLAYER="$DEFAULT_PLAYER" ;;
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

# Check if we don't want to advance pointers.
[ -n "$DO_REWATCH" ] && rewatch

# check if there's a record in $DIRS. We'll act according to that.
LASTWATCHED=`grep "$CURDIR	" $DIRS|cut -f 2`

if [ -z "$LASTWATCHED" ]
then
    # Directory with no records. We'll pick the first one
    UPNEXT=`find $FINDPREARGS . $FINDARGS|sort -f |head -n 1 | sed -e "s#^\./##"`
    LASTWATCHED='(none, starting from beginning)'

    # mark the spot
    if $DRYRUN ; then
        echo -e "$CURDIR	$UPNEXT"
    else
        echo -e "$CURDIR	$UPNEXT" >> $DIRS
    fi



else
    # we have a record
    UPNEXT=`find $FINDPREARGS . $FINDARGS|sort -f |
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
    play "$UPNEXT"
fi
