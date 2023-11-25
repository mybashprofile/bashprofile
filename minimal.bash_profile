### REQUIREMENTS ###

# bash version 4.1+ (check with echo $BASH_VERSION)
#   OSX instructions:
#     brew install bash
#     (add "/usr/local/bin/bash" to the end of /etc/shells)
#     chsh -s /usr/local/bin/bash
#     (reload shell and check: echo $BASH_VERSION)
#
# bash-completion version 4.1+
#   OSX instructions:
#     brew install bash-completion@2

if ((BASH_VERSINFO[0] < 4)); then
  echo "WARNING: You are running an older version of bash; upgrade to >= 4.1"
fi

### CHECK IF RUNNING INTERACTIVELY ###

[ -z "$PS1" ] && return
case $- in
    *i*) ;;
      *) return;;
esac


### PERSONALIZATIONS ###

MY_EDITOR='subl'
MY_EDITOR_WAIT='subl -w'


### CONFIGURATION ###

HISTSIZE=100000  # set in-memory history size
HISTFILESIZE=100000  # set history file size
PROMPT_COMMAND='history -a'  # Record each line as it gets issued
HISTCONTROL="ignorespace"  # don't put lines starting with space in the history
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"  # Don't record some commands
HISTTIMEFORMAT='%F %T '  # Use standard ISO 8601 timestamp

# Use history to complete already-typed prefix on up arrow (https://codeinthehole.com/tips/the-most-important-command-line-tip-incremental-history-searching-with-inputrc/)
if [[ $- == *i* ]]; then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\e[C": forward-char'
    bind '"\e[D": backward-char'
fi

# export IGNOREEOF=1  # need to press ctrl+D twice to exit
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'  # colored GCC warnings and errors
export CLICOLOR=1  # ls colors for mac
export LSCOLORS=ExFxBxDxCxegedabagacad  # ls colors for mac

if command -v ${MY_EDITOR_WAIT% *} > /dev/null; then
  export EDITOR=$MY_EDITOR_WAIT
elif command -v ${MY_EDITOR% *} > /dev/null; then
  export EDITOR=$MY_EDITOR
elif command -v vim > /dev/null; then
  export EDITOR=vim
fi

shopt -s histappend  # append to the history file, don't overwrite it
shopt -s checkwinsize  # check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
# shopt -s cdable_vars  # if cd arg is not valid, assumes its a var defining a dir
shopt -s cmdhist  # save multi-line commands in history as single line
shopt -s extglob  # enable extended pattern-matching features
# shopt -s dotglob  # include dotfiles in pathname expansion
shopt -s extglob  # necessary for programmable completion.
shopt -s globstar 2> /dev/null  # (LINUX only) the pattern "**" used in a pathname expansion context will match all files and zero or more directories and subdirectories.
shopt -s progcomp  # programmable completion (should be enabled by default)
shopt -s expand_aliases  # use aliases (enabled by default)
shopt -s autocd 2> /dev/null  # Prepend cd to directory names automatically
shopt -s dirspell 2> /dev/null  # Correct spelling errors during tab-completion
shopt -s cdspell 2> /dev/null  # Correct spelling errors in arguments supplied to cd

set visible-stats on  # when listing possible file completions, put / after directory names and * after programs

bind "set enable-bracketed-paste off"  # Don't highlight text when pasting
bind Space:magic-space  # Enable history expansion with space (typing !!<space> will replace the !! with your last command)
bind "set mark-symlinked-directories on"  # Immediately add a trailing slash when autocompleting symlinks to directories
# bind "set show-all-if-ambiguous on"  # Display matches for ambiguous patterns at first tab press
# bind "set completion-ignore-case on"  # Perform file completion in a case insensitive fashion
# bind "set completion-map-case on"  # Treat hyphens and underscores as equivalent

bind 'TAB:menu-complete'  # If there are multiple matches for completion, Tab should cycle through them
bind "set show-all-if-ambiguous on"  # Display a list of the matching files at first tab press
bind "set menu-complete-display-prefix on"  # Perform partial (common) completion on the first Tab press, only start cycling full results on the second Tab press (from bash version 5)
bind "set completion-display-width 1"  # Show the matches on a single line


### PATH ###

function add_path () {
  if [ -f $1 ] || [ -d $1 ]; then
    export PATH="$1:$PATH"
  fi
}

add_path "/opt/local/bin:/opt/local/sbin"


### PROMPT ###

force_color_prompt=yes # Comment for a non-colored prompt

function shorten_dir () {
  dir=$1
  home_esc=$(sed -e 's/\//\\\//g' <<< ${HOME})
  dir=$(sed -e "s/${home_esc}/~/g" <<< ${dir})
  echo $dir
}

function parse_virtualenv_prompt () {
  if test -n "$VIRTUAL_ENV" ; then
    echo " ($(basename $VIRTUAL_ENV))"
  fi
}
export VIRTUAL_ENV_DISABLE_PROMPT=1

function parse_git_branch_prompt () {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function colorize_host_name () {
  if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    echo -e "${BLUE}${USER}@${HOSTNAME}${BLACK}"
  else
    echo -e "${GREEN}${USER}@${HOSTNAME}${BLACK}"
  fi
}

if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
  xterm-color|*-256color) color_prompt=yes;;  # set a fancy prompt (non-color, unless we know we "want" color)
esac

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  color_prompt=yes  # We have color support; assume it's compliant with Ecma-48 (ISO/IEC-6429)
  else
  color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}$(colorize_host_name):\[\033[01;36m\]$(shorten_dir "$(pwd)")\[\033[00;95m\]$(parse_virtualenv_prompt)\[\033[00;34m\]$(parse_git_branch_prompt)\[\033[00m\]\n\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:$(shorten_dir "$(pwd)")$(parse_virtualenv_prompt)$(parse_git_branch_prompt)\n\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"  # If this is an xterm set the title to user@host:dir
  ;;
*)
  ;;
esac


### MISC FUNCTIONS ###

# Extract zipped file. Usage: extract filename
function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2) tar xvjf $1   ;;
      *.tar.gz)  tar xvzf $1   ;;
      *.tar.xz)  tar xvJf $1   ;;
      *.bz2)     bunzip2 $1    ;;
      *.rar)     unrar x $1    ;;
      *.gz)      gunzip $1     ;;
      *.tar)     tar xvf $1    ;;
      *.tbz2)    tar xvjf $1   ;;
      *.tgz)     tar xvzf $1   ;;
      *.zip)     unzip $1      ;;
      *.Z)       uncompress $1 ;;
      *.7z)      7z x $1       ;;
      *)         echo "'$1' cannot be extracted via \"extract\"" ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}

# Creates an archive (*.tar.gz) from given directory. Usage: maketar test/
function maketar() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }

# Create a ZIP archive of a file or folder. Usage: makezip test/
function makezip() { zip -r "${1%%/}.zip" "$1" ; }

alias encrypt='encrypt-gpg'
alias decrypt='decrypt-gpg'

function encrypt-gpg() {
  if [ -f $1 ] ; then
    gpg --output "${1}-encrypted" --symmetric --cipher-algo AES256 --no-symkey-cache "$1"

    if [ "$2" == "-o" ]; then  # overwrite
      rm -rf "$1"
      mv "${1}-encrypted" "$1"
      echo "overwrote ${1}"
    else
      echo "created ${1}-encrypted"
    fi
  else
    echo "'${1}' is not a valid file!"
  fi
}

function decrypt-gpg() {
  if [ -f $1 ] ; then
    if [[ "$1" == *-encrypted ]]; then
      out_path=${1::-10}
    else
      out_path="${1}-decrypted"
    fi

    gpg --output "$out_path" --decrypt "$1"

    if [ "$2" == "-o" ]; then  # overwrite
      rm -rf "${1}"
      mv "$out_path" "$1"
      echo "overwrote ${1}"
    else
      echo "created ${out_path}"
    fi
  else
    echo "'${1}' is not a valid file!"
  fi
}

function encrypt-openssl() {
  if [ -f $1 ] ; then
    gpg --output "${1}-encrypted" --symmetric --cipher-algo AES256 --no-symkey-cache "$1"

    if [ "$2" == "-o" ]; then  # overwrite
      rm -rf "$1"
      mv "${1}-encrypted" "$1"
      echo "overwrote ${1}"
    else
      echo "created ${1}-encrypted"
    fi
  else
    echo "'${1}' is not a valid file!"
  fi
}

function decrypt-openssl() {
  if [ -f $1 ] ; then
    if [[ "$1" == *-encrypted ]]; then
      out_path=${1::-10}
    else
      out_path="${1}-decrypted"
    fi

    openssl aes-256-cbc -d -a -salt -in "${1}" -out "$out_path"

    if [ "$2" == "-o" ]; then  # overwrite
      rm -rf "${1}"
      mv "$out_path" "$1"
      echo "overwrote ${1}"
    else
      echo "created ${out_path}"
    fi
  else
    echo "'${1}' is not a valid file!"
  fi
}

### ALIASES ###

alias sudo='sudo '  # Enable aliases to be sudo'd

# Paths
if [ -x /usr/bin/dircolors ]; then  # We are in Linux
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls -F --color=auto'
  alias ll='ls -AoFh --color=auto'
  alias la='ls -AF --color=auto'
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
else
  alias ls='ls -F'
  alias ll='ls -AoFh'
  alias la='ls -AF'
fi

alias cp='cp -i' # Ask to overwrite
alias mv='mv -i' # Ask to overwrite
alias df='df -kh' # Filesystem info
alias du='du -kh' # Directory info
alias du-size='sudo du -shx * | sort -rh' # Directory info sorted by size
