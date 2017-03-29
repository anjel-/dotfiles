#!/bin/bash
### file header ###############################################################
#: NAME:          dotfiles-mgr.sh
#: SYNOPSIS:      dotfiles-mgr.sh command [arguments]
#: DESCRIPTION:   manages the dotfiles of current user
#: RETURN CODES:  0-SUCCESS, 1-FAILURE
#: RUN AS:        any user
#: AUTHOR:        anjel- <anjel-@users.noreply.github.com>
#: VERSION:       1.0-SNAPSHOT
#: URL:           https://github.com/anjel-/dotfiles/dotfiles-mgr.sh
#: CHANGELOG:
#: DATE:          AUTHOR:          CHANGES:
#: 28-03-2017     anjel-           initial implementation
### external parameters #######################################################
set +x
declare GIT_URL="${GIT_URL:-https://github.com/anjel-}"  # GIT URL
declare PROJECT="dotfiles"
declare ARCHIVE_DIR="$HOME/.archive"
### internal parameters #######################################################
readonly SUCCESS=0 FAILURE=1
readonly FALSE=0  TRUE=1
exitcode=$SUCCESS
### service parameters ########################################################
set +x
_TRACE="${_TRACE:-0}"       # 0-FALSE, 1-print traces
_DEBUG="${_DEBUG:-1}"       # 0-FALSE, 1-print debug messages
_FAILFAST="${_FAILFAST:-1}" # 0-run to the end, 1-stop at the first failure
_DRYRUN="${_DRYRUN:-0}"     # 0-FALSE, 1-send no changes to remote systems
_UNSET="${_UNSET:-0}"       # 0-FALSE, 1-treat unset parameters as an error
TIMEFORMAT='[TIME] %R sec %P%% util'
(( _DEBUG )) && echo "[DEBUG] _TRACE=\"$_TRACE\" _DEBUG=\"$_DEBUG\" _FAILFAST=\"$_FAILFAST\""
# set shellopts ###############################################################
(( _TRACE )) && set -x || set +x
(( _FAILFAST )) && { set -o pipefail; } || true
(( _UNSET )) && set -u || set +u
### functions #################################################################
###
function die { #@ print ERR message and exit
	(( _FAILFAST )) && printf "[ERR] %s\n" "$@" >&2 || printf "[WARN] %s\n" "$@" >&2
	(( _FAILFAST )) && exit $FAILURE || { exitcode=$FAILURE; true; }
} #die
###
function print { #@ print qualified message
  local level="INFO"
  (( _DEBUG )) && level="DEBUG"
  (( _DRYRUN )) && level="DRYRUN+$level"||true
  printf "[$level] %s\n" "$@"
} #print
###
function usage { #@ USAGE:
  echo "
  [INFO] manages the dotfiles for current user :
  [INFO] INSTALL         - install dot files
  [INFO] BACKUP          - backup initial dot files
  [INFO] RESTORE         - restore initial dot files
  [INFO] Usage: $_SCRIPT_NAME INSTALL|BACKUP|RESTORE
  "
} #usage
###
function initialize { #@ initialization of the script
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
	(( _DEBUG )) && print "Initializing the variables"
  local ostype="$(uname -o)"
  export _LOCAL_HOSTNAME=$(hostname -s);
  case $_OS_TYPE in
    "Cygwin")
      _SCRIPT_DIR="${0%\\*}"
      _SCRIPT_NAME="${0##*\\}"
    ;;
    *)
      local tempvar="$(readlink -e "${BASH_SOURCE[0]}")"
      _SCRIPT_DIR="${tempvar%/*}"
      _SCRIPT_NAME="${tempvar##/*/}"
    ;;
  esac
} #initialize
###
function checkPreconditions { #@ prerequisites for the whole script
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
	(( _DEBUG )) && print "Checking the preconditions for the whole script"
  (( _DEBUG )) && print "_SCRIPT_DIR=\"$_SCRIPT_DIR\" _SCRIPT_NAME=\"$_SCRIPT_NAME\" "
} #checkPreconditions
###
function backup_dotfiles { #@ 
	(( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  (( _DEBUG )) && print "Backing up the existing dot files"
  [[ ! -d $ARCHIVE_DIR ]] && mkdir -p $ARCHIVE_DIR||true
  local _cp="$(command -v cp)"
  for i in ~/.?* ;do
    if [[ -f $i ]];then
      [[ ! -f $ARCHIVE_DIR/${i##*/} ]] && { (( _DEBUG ))&& $_cp -v $i $ARCHIVE_DIR/|| $_cp $i $ARCHIVE_DIR/; }||{ (( _DEBUG ))&&print "${i##*/} already saved"||true; }
    fi
  done
} #backup_dotfiles
###
function restore_dotfiles { #@ 
	(( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  (( _DEBUG )) && print "Restoring the archived dot files"
  [[ ! -d $ARCHIVE_DIR ]] && die "archive \"$ARCHIVE_DIR\" not found"
  local _cp="$(command -v cp)"
  for i in $ARCHIVE_DIR/.?* ;do
    [[ -f $i ]] && { (( _DEBUG )) && $_cp -vf $i ~/ || $_cp -f $i ~/; } ||true
  done
} #restore_dotfiles

### function main #############################################################
function main {
  (( _DEBUG )) && echo "[DEBUG] enter $FUNCNAME"
  initialize
  checkPreconditions "$CMD"
  case $CMD in
  INSTALL|install)
  install_dotfiles "$@"
  ;;
  BACKUP|backup)
  backup_dotfiles "$@"
  ;;
  RESTORE|restore)
  restore_dotfiles "$@"
  ;;
  HELP|help)
  usage
  ;;
  *) die "unknown command \"$CMD\" "
  ;;
  esac
} #main
### call main #################################################################
(( $# < 1 )) && die "$(basename $0) needs a command to operate"
declare CMD="$1" ;shift
set -- "$@"
declare VAR
main "$@"
exit $exitcode
