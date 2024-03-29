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

MY_EDITOR='code'
MY_EDITOR_WAIT='code -w'

# Load overridden personalizations
if [ -f ~/.bash_profile_personalizations ]; then
  . ~/.bash_profile_personalizations
fi


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


### UTILITIES ###

BLACK="\033[0m"
BLACK_BOLD="\033[1;0m"
RED="\033[31m"
RED_BOLD="\033[1;31m"
GREEN="\033[32m"
GREEN_BOLD="\033[1;32m"
BLUE="\033[34m"
BLUE_BOLD="\033[1;34m"
MAGENTA="\033[95m"
MAGENTA_BOLD="\033[1;95m"

function blue_echo () {
  echo -e "${BLUE}$1${BLACK}"
}
function green_echo () {
  echo -e "${GREEN}$1${BLACK}"
}
function red_echo () {
  echo -e "${RED}$1${BLACK}"
}
function magenta_echo () {
  echo -e "${MAGENTA}$1${BLACK}"
}
function created_echo () {
  echo -e "${GREEN_BOLD}Created: ${BLACK}$1"
}
function error_echo () {
  echo -e "${RED_BOLD}ERROR: ${BLACK}$1"
}

array_contains () {
  for e in "${@:2}"; do
    [[ "$e" == "$1" ]] && return 0
  done
  return 1
}

find_file() {
  filename=$1
  start_dir="$2"
  cwd=$(pwd)

  if [ -n "$start_dir" ]; then
    cd "$start_dir"
  fi

  until [ -f "${filename}" ] || [ "$(pwd)" == "/" ]; do cd ..; done
  if [ "$(pwd)" == "/" ]; then
    echo ''
  else
    echo "$(pwd)/${filename}"
  fi

  cd $cwd
}

find_dir() {
  dir_name=$1
  start_dir="$2"
  cwd=$(pwd)

  if [ -n "$start_dir" ]; then
    cd "$start_dir"
  fi

  until [ -d "${dir_name}" ] || [ "$(pwd)" == "/" ]; do cd ..; done
  if [ "$(pwd)" == "/" ]; then
    echo ''
  else
    echo "$(pwd)/${dir_name}"
  fi

  cd $cwd
}

# Convert yaml to json
function yaml2json () {
  ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' $*
}

# Get a top-level json property. $1: file name, $2: property name
function get_json_property () {
  if [ -e $1 ]; then
    cat $1 \
      | grep $2 \
      | head -1 \
      | awk -F: '{ print $2 }' \
      | sed 's/[",]//g' \
      | tr -d '[[:space:]]'
  else
    echo "No file: ${1}"
  fi
}

function get_git_branch () {
  echo $(git rev-parse --abbrev-ref HEAD)
}


### PATH ###

function add_path () {
  if [ -f $1 ] || [ -d $1 ]; then
    export PATH="$1:$PATH"
  fi
}

add_path "/opt/local/bin:/opt/local/sbin"

# Go
if [ -d "$HOME/go" ]; then
  export GOPATH="$HOME/go"
else
  export GOPATH="$HOME"
fi
add_path "$GOPATH/bin"
add_path "/usr/local/go/bin"  # Default location
add_path "/usr/local/opt/go/libexec/bin"  # OSX + Homebrew
add_path "$HOME/.cargo/bin"
add_path "$HOME/.local/bin"
add_path "/opt/homebrew/bin"

# rbenv
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
add_path "$HOME/.rbenv/bin"
if command -v rbenv > /dev/null; then
  eval "$(rbenv init -)"
fi

# Google cloud SDK
# May need to also run gcloud auth application-default login
if [ -f "$HOME/.gcloud/path.bash.inc" ]; then source "$HOME/.gcloud/path.bash.inc"; fi  # Update PATH
if [ -f "$HOME/.gcloud/completion.bash.inc" ]; then source "$HOME/.gcloud/completion.bash.inc"; fi  # Command completion
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then source "$HOME/google-cloud-sdk/path.bash.inc"; fi  # Update PATH
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then source "$HOME/google-cloud-sdk/completion.bash.inc"; fi  # Command completion


### SETUP CONFIGS ###

if [ ! -f $HOME/.screenrc ]; then
  echo -e "# Use screen -R [pid] to reattach to previous screen if possible\n# May want to add the following to .bash_profile:\n#   alias screen='screen -x -U -R'\n# where U=utf8, R=reattach if possible, x=multiplex\n\n\n# SETTINGS\n\nshell -\$SHELL              # Treat shell as login shell\ndefscrollback 10000        # Allow scrollback to 10,000 lines\nstartup_message off        # Disable startup message\nautodetach on              # Detach if network connection fails\ntermcapinfo xterm* ti@:te@ # Enable scroll\naltscreen on               # Clear screen after quitting vim\ndefutf8 on                 # Display utf8\nmsgwait 0.1                # Show messages for only 2 seconds\n\n\n# KEYBINDINGS\n\nescape ^Xx        # ctrl+A is default escape command, on mac command+S is mapped to ctrl+X\nbind 'n' screen   # n for new\nbind ' ' next     # space because it is convenient and n is for new\nbind 'p' prev\nbind 'd' detatch\nbind 'h' help\nbind 'w' windows\n\n\n# Status bar that includes the name of the session, the current machine load, and the time.\n# hardstatus alwayslastline '%{= kG}[ %{G}%H | %{=kw}%?%-Lw%?%{g}%n*%f%t%?(%u)%? %{g}]%{w}%?%+Lw%?%?%=%{g}[ %{K}%l %{g}][ %{B}%Y-%m-%d %{W    }%c %{g}]'" > $HOME/.screenrc
  created_echo "$HOME/.screenrc"
fi

if [ ! -f $HOME/.gitconfig ]; then
  echo -e '[user]\n  name = David Eliahu\n  email = davideliahu@gmail.com\n[alias]\n  co = checkout\n  br = branch\n  st = status\n  ci = commit\n  a = add\n\n[core]\n  editor = vim\n\n[color]\n  branch = auto\n  diff = auto\n  status = auto\n\n[color "branch"]\n  current = yellow reverse\n  local = yellow\n  remote = green\n\n[color "diff"]\n  meta = yellow bold\n  frag = magenta bold\n  old = red bold\n  new = green bold\n\n[color "status"]\n  added = yellow\n  changed = green\n  untracked = cyan\n\n[pull]\n  rebase = false\n\n[push]\n  default = simple\n\n[filter "lfs"]\n  clean = git-lfs clean -- %f\n  smudge = git-lfs smudge -- %f\n  process = git-lfs filter-process\n  required = true\n\n[credential]\n  helper = cache' > $HOME/.gitconfig
  created_echo "$HOME/.gitconfig"
fi

if [ -d "$HOME/Library/Application Support/k9s" ] && [ ! -f "$HOME/Library/Application Support/k9s/alias.yml" ]; then
  echo -e 'alias:\n  d: apps/v1/deployments\n  da: apps/v1/daemonsets\n  m: apps/v1/daemonsets\n  j: batch/v1/jobs\n  p: v1/pods\n  n: v1/nodes\n  no: v1/nodes\n  a: v1/namespaces\n  na: v1/namespaces\n  s: v1/services\n  c: v1/configmaps\n  e: v1/events\n  r: v1/secrets\n  v: networking.istio.io/v1beta1/virtualservices' > "$HOME/Library/Application Support/k9s/alias.yml"
  created_echo "$HOME/Library/Application Support/k9s/alias.yml"
fi
if [ -d $HOME/.config/k9s ] && [ ! -f $HOME/.config/k9s/alias.yml ]; then
  echo -e 'alias:\n  d: apps/v1/deployments\n  da: apps/v1/daemonsets\n  m: apps/v1/daemonsets\n  j: batch/v1/jobs\n  p: v1/pods\n  n: v1/nodes\n  no: v1/nodes\n  a: v1/namespaces\n  na: v1/namespaces\n  s: v1/services\n  c: v1/configmaps\n  e: v1/events\n  r: v1/secrets\n  v: networking.istio.io/v1beta1/virtualservices' > $HOME/.config/k9s/alias.yml
  created_echo $HOME/.config/k9s/alias.yml
fi

if [ -d "$HOME/Library/Application Support/k9s" ] && [ ! -f "$HOME/Library/Application Support/k9s/hotkey.yml" ]; then
  echo -e 'hotKey:\n  # cmd+shift+n\n  nodes:\n    shortCut:    Shift-0\n    description: View nodes\n    command:     nodes\n  # cmd+shift+p\n  pods:\n    shortCut:    Shift-1\n    description: View pods\n    command:     pods\n  # cmd+shift+d\n  deployments:\n    shortCut:    Shift-2\n    description: View deployments\n    command:     deployments\n  # cmd+shift+m\n  daemonsets:\n    shortCut:    Shift-3\n    description: View daemonsets\n    command:     daemonsets\n  # cmd+shift+j\n  jobs:\n    shortCut:    Shift-4\n    description: View jobs\n    command:     jobs\n  # cmd+shift+a\n  namespaces:\n    shortCut:    Shift-5\n    description: View namespace\n    command:     namespaces\n  # cmd+shift+s\n  services:\n    shortCut:    Shift-6\n    description: View services\n    command:     services\n  # cmd+shift+c\n  configmaps:\n    shortCut:    Shift-7\n    description: View configmaps\n    command:     configmaps\n  # cmd+shift+e\n  events:\n    shortCut:    Shift-8\n    description: View events\n    command:     events\n  # cmd+shift+r\n  secrets:\n    shortCut:    Shift-9\n    description: View secrets\n    command:     secrets\n  # cmd+shift+v\n  virtualservices:\n    shortCut:    Shift-W\n    description: View virtualservices\n    command:     virtualservices\n\n# Check for overlaps with built-in aliases (via ?)' > "$HOME/Library/Application Support/k9s/hotkey.yml"
  created_echo "$HOME/Library/Application Support/k9s/hotkey.yml"
fi
if [ -d $HOME/.config/k9s ] && [ ! -f $HOME/.config/k9s/hotkey.yml ]; then
  echo -e 'hotKey:\n  # cmd+shift+n\n  nodes:\n    shortCut:    Shift-0\n    description: View nodes\n    command:     nodes\n  # cmd+shift+p\n  pods:\n    shortCut:    Shift-1\n    description: View pods\n    command:     pods\n  # cmd+shift+d\n  deployments:\n    shortCut:    Shift-2\n    description: View deployments\n    command:     deployments\n  # cmd+shift+m\n  daemonsets:\n    shortCut:    Shift-3\n    description: View daemonsets\n    command:     daemonsets\n  # cmd+shift+j\n  jobs:\n    shortCut:    Shift-4\n    description: View jobs\n    command:     jobs\n  # cmd+shift+a\n  namespaces:\n    shortCut:    Shift-5\n    description: View namespace\n    command:     namespaces\n  # cmd+shift+s\n  services:\n    shortCut:    Shift-6\n    description: View services\n    command:     services\n  # cmd+shift+c\n  configmaps:\n    shortCut:    Shift-7\n    description: View configmaps\n    command:     configmaps\n  # cmd+shift+e\n  events:\n    shortCut:    Shift-8\n    description: View events\n    command:     events\n  # cmd+shift+r\n  secrets:\n    shortCut:    Shift-9\n    description: View secrets\n    command:     secrets\n  # cmd+shift+v\n  virtualservices:\n    shortCut:    Shift-W\n    description: View virtualservices\n    command:     virtualservices\n\n# Check for overlaps with built-in aliases (via ?)' > $HOME/.config/k9s/hotkey.yml
  created_echo $HOME/.config/k9s/hotkey.yml
fi

if [ -f "$HOME/Library/Application Support/k9s/config.yml" ]; then
  sed -i -e 's/logoless:.*/logoless: true/g' "$HOME/Library/Application Support/k9s/config.yml"
  sed -i -e 's/tail:.*/tail: 5000/g' "$HOME/Library/Application Support/k9s/config.yml"
  sed -i -e 's/buffer:.*/buffer: 5000/g' "$HOME/Library/Application Support/k9s/config.yml"
  sed -i -e 's/sinceSeconds:.*/sinceSeconds: -1/g' "$HOME/Library/Application Support/k9s/config.yml"
fi
if [ -f $HOME/.config/k9s/config.yml ]; then
  sed -i -e 's/logoless:.*/logoless: true/g' $HOME/.config/k9s/config.yml
  sed -i -e 's/tail:.*/tail: 5000/g' $HOME/.config/k9s/config.yml
  sed -i -e 's/buffer:.*/buffer: 5000/g' $HOME/.config/k9s/config.yml
  sed -i -e 's/sinceSeconds:.*/sinceSeconds: -1/g' $HOME/.config/k9s/config.yml
fi

### SETUP BASH_COMPLETION ###

function custom_complete () {
  cmd=$1
  complete_like=$2
  alias __CUSTOM_COMPLETE_${cmd}="${complete_like}"
  complete -F _complete_alias $cmd
}

if ! shopt -oq posix; then
  if [ $(command -v brew) ]; then
    BREW_PREFIX=$(brew --prefix)
    if [ -f $BREW_PREFIX/share/bash-completion/bash_completion ]; then
      export BASH_COMPLETION_COMPAT_DIR=$BREW_PREFIX/etc/bash_completion.d
      BASH_COMPLETION=$BREW_PREFIX/share/bash-completion/bash_completion
      BASH_COMPLETION_DIR=$BREW_PREFIX/share/bash-completion/completions
    elif [ -f $BREW_PREFIX/etc/bash_completion ]; then
      BASH_COMPLETION=$BREW_PREFIX/etc/bash_completion
      BASH_COMPLETION_DIR=$BREW_PREFIX/etc/bash_completion.d
    fi
  elif [ -f /usr/share/bash-completion/bash_completion ]; then
    BASH_COMPLETION=/usr/share/bash-completion/bash_completion
    BASH_COMPLETION_DIR=/usr/share/bash-completion/completions
  elif [ -f /etc/bash_completion ]; then
    BASH_COMPLETION=/etc/bash_completion
    BASH_COMPLETION_DIR=/etc/bash_completion.d
  fi

  if [ ! -z "$BASH_COMPLETION" ]; then
    should_complete() {
      cmd=$1
      expected_file=${2-$cmd}
      if ! command -v $cmd > /dev/null; then
        return 1
      fi

      # return 0  # Re-generate all relevant bash completions

      if [ ! -z "$BASH_COMPLETION_COMPAT_DIR" ]; then
        if [ -f $BASH_COMPLETION_COMPAT_DIR/$expected_file ]; then
          return 1
        fi
      fi
      if [ -f $BASH_COMPLETION_DIR/$expected_file ]; then
        return 1
      fi
      return 0
    }

    command_completion() {
      install_cmd=$1
      filename=$2
      if ! eval $install_cmd | tee $BASH_COMPLETION_DIR/$filename > /dev/null &>/dev/null; then
        if ! eval $install_cmd | sudo tee $BASH_COMPLETION_DIR/$filename > /dev/null; then
          error_echo "Couldn't install $filename completion"
          return
        fi
      fi
      created_echo "$BASH_COMPLETION_DIR/$filename"
    }

    download_completion() {
      url=$1
      filename=$2
      if ! curl "$url" --silent --output "$BASH_COMPLETION_DIR/$filename"; then
        if ! sudo curl "$url" --silent --output "$BASH_COMPLETION_DIR/$filename"; then
          error_echo "Couldn't download $filename completion"
          return
        fi
      fi
      created_echo "$BASH_COMPLETION_DIR/$filename"
    }

    copy_completion() {
      src=$1
      filename=$2
      if [ -f "$src" ]; then
        /bin/cp -f "$src" "$BASH_COMPLETION_DIR/$filename"
        created_echo "$BASH_COMPLETION_DIR/$filename"
      fi
    }

    if ( should_complete "npm" ); then
      command_completion "npm completion" "npm"
    fi
    if ( should_complete "git" ); then
      download_completion "https://raw.githubusercontent.com/git/git/v$(git --version | awk '{print $3}')/contrib/completion/git-completion.bash" "git"
    fi
    if ( should_complete "git" "git-prompt.sh" ); then
      download_completion "https://raw.githubusercontent.com/git/git/v$(git --version | awk '{print $3}')/contrib/completion/git-prompt.sh" "git-prompt.sh"
    fi
    if ( should_complete "docker" ); then
      download_completion "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker" "docker"
    fi
    if ( should_complete "docker" "docker-machine" ); then
      download_completion "https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine.bash" "docker-machine"
    fi
    if ( should_complete "docker" "docker-compose" ); then
      download_completion "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose" "docker-compose"
    fi
    if ( should_complete "kubectl" ); then
      command_completion "kubectl completion bash" "kubectl"
    fi

    source $BASH_COMPLETION
  fi
fi


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


### BASH_PROFILE ###

function get_bash_profile () {
  bash_profile=$HOME/.bashrc
  if [ -f $HOME/.bash_profile ]; then
    bash_profile=$HOME/.bash_profile
  fi
  if [ -f $HOME/.usr_bash_profile ]; then
    bash_profile=$HOME/.usr_bash_profile
  fi
  echo $bash_profile
}

cb() {
  bash_profile=$(get_bash_profile)
  $MY_EDITOR $bash_profile
}

rb() {
  bash_profile=$(get_bash_profile)
  . $bash_profile
  blue_echo "-> $bash_profile updated"
}

bashprofilecp() {
  bash_profile=$(get_bash_profile)
  cat $bash_profile | pbcopy
}

bashprofilediff() {
  bash_profile=$(get_bash_profile)
  git clone https://github.com/mybashprofile/bashprofile.git .tmp_bash_profile
  cd .tmp_bash_profile
  rm .bash_profile
  cp $bash_profile .bash_profile
  git diff
  cd ..
  rm -rf .tmp_bash_profile
}

bashprofilecommit() {
  if [ -z "$1" ]; then
    echo "You must provide the commit message as a parameter"
    return
  fi
  bash_profile=$(get_bash_profile)
  git clone https://github.com/mybashprofile/bashprofile.git .tmp_bash_profile
  cd .tmp_bash_profile
  rm .bash_profile
  cp $bash_profile .bash_profile
  git -c "user.name=mybashprofile" -c "user.email=noemail" commit -am "$1" --author "mybashprofile <noemail>"
  git push https://mybashprofile:$BASH_PROFILE_GITHUB_PERSONAL_ACCESS_TOKEN@github.com/mybashprofile/bashprofile.git
  cd ..
  rm -rf .tmp_bash_profile
}

bashprofilepull() {
  bash_profile=$(get_bash_profile)
  rm -rf $bash_profile.old
  mv $bash_profile $bash_profile.old
  wget --no-check-certificate https://raw.githubusercontent.com/mybashprofile/bashprofile/master/.bash_profile -O $bash_profile &> /dev/null
  . $bash_profile
  echo "$bash_profile updated"
}

alias bashprofileupdate='bashprofilepull'


### MISC FUNCTIONS ###

# Delete the last line of terminal output
function clearLastLine() {
  tput cuu 1 && tput el
}

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

# Returns "darwin", "linux", "windows", or "$OSTYPE"
function get_os() {
  case "$OSTYPE" in
    darwin*)  echo "darwin" ;;
    linux*)   echo "linux" ;;
    msys*)    echo "windows" ;;
    *)        echo "$OSTYPE" ;;
  esac
}

# Alert on completion of long running commands. Ubuntu only. Usage: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Count lines in code directory
alias countlines='find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" | xargs wc -l'

# Update packages and restart (Ubuntu only)
alias UPDATE='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get autoremove -y && sudo reboot'

# Cleanup apt
alias apt-cleanup='sudo apt-get autoclean && sudo apt-get autoremove && sudo apt-get clean && sudo apt-get remove && orphand'


### ALIASES ###

alias sudo='sudo '  # Enable aliases to be sudo'd

# Paths
if [ -x /usr/bin/dircolors ]; then # We are in Linux
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

alias l='ls'
alias lls='ll -S' #  Sort by size, biggest first (use -r to reverse order)
alias llm='ll -t' #  Sort by date modified, most recent first (use -r to reverse order)
alias lla='ll -tu' #  Sort by date accessed, most recent first (use -r to reverse order)
alias llc='ll -tU' #  Sort by date created, most recent first (use -r to reverse order)

alias lss='lls'
alias lsm='llm'
alias lsa='lla'
alias lsc='llc'

alias -- -="cd $OLDPWD"
alias -- ~="cd $HOME"

alias cd..="cd .."
alias cd...="cd ../.."
alias cd....="cd ../../.."
alias cd.....="cd ../../../.."
alias cd......="cd ../../../../.."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."


# Misc
alias c='code'
# alias c='clear'
alias finder='open .'
alias f='open .'
alias o='open'
alias m='make'
alias cp='cp -i' # Ask to overwrite
alias ff='find . -name' # Find
alias ffi='find . -iname' # Find (ignore case)
alias df='df -kh' # Filesystem info
alias du='du -kh' # Directory info
alias du-size='sudo du -shx * | sort -rh' # Directory info sorted by size
alias ssh='ssh -oServerAliveInterval=10'
alias screen='screen -x -U -R' # U=utf8, R=reattach if possible, x=multiplex
alias watch='watch -n 1 '  # The trailing space allows second word aliases to be expanded
alias unmount='umount ~/mnt/*'
alias unmount2='diskutil unmount ~/mnt/*'
alias gssh='gcloud compute ssh'
alias logoutall="pkill -u $(whoami)"

alias deletetrailingnewline="truncate -s -1"
alias trimtrailingnewline="truncate -s -1"
alias removetrailingnewline="truncate -s -1"
alias deletetrailingchar="truncate -s -1"
alias trimtrailingchar="truncate -s -1"
alias removetrailingchar="truncate -s -1"

# alias mv='mv -i' # Ask to overwrite
function mv() {
  if [ "$#" -ne 1 ] || [ ! -e "$1" ]; then
    command mv -i "$@"
    return
  fi
  read -ei "$1" newfilename
  mkdir -p $(dirname $newfilename)
  command mv -i -v -- "$1" "$newfilename"
}

# Make "less" pretty
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)" # make less more friendly for non-text input files, see lesspipe(1)


# NPM
alias nr='npm run'
alias npmnuke='rm -rf ./node_modules && npm install'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Virtualenv
function venv-init() {
  if [ -d ".env" ]; then
    echo '.env already exists in the current directory'
  else
    virtualenv -p python .env && source .env/bin/activate
  fi
}

function venv() {
  if [ -n "$1" ]; then
    start_dir="$1"
  else
    start_dir="$(pwd)"
  fi

  env_path=$(find_dir '.env' $start_dir)

  if [ -z "${env_path}" ]; then
    echo "ERROR: no .env found in ${start_dir} (or any parents)"
  else
    source "${env_path}/bin/activate"
  fi
}

# Kubernetes
alias k='kubectl'
alias K='k9s'
alias Kc='k9s --context'

alias kc='kubectl config use-context'

alias kp='kubectl get pod'
alias kj='kubectl get job'
alias ks='kubectl get service'
alias kd='kubectl get deployment'
alias km='kubectl get daemonset'
alias ki='kubectl get ingress'
alias kv='kubectl get virtualservices'
alias kn='kubectl get node'

alias kpw='watch kubectl get pod'
alias kjw='watch kubectl get job'
alias ksw='watch kubectl get service'
alias kdw='watch kubectl get deployment'
alias kmw='watch kubectl get daemonset'
alias kiw='watch kubectl get ingress'
alias kvw='watch kubectl get virtualservices'
alias knw='watch kubectl get node'

alias kpa='kubectl get --all-namespaces pod'
alias kja='kubectl get --all-namespaces job'
alias ksa='kubectl get --all-namespaces service'
alias kda='kubectl get --all-namespaces deployment'
alias kma='kubectl get --all-namespaces daemonset'
alias kia='kubectl get --all-namespaces ingress'
alias kva='kubectl get --all-namespaces virtualservices'

alias kpwa='watch kubectl get --all-namespaces pod'
alias kpaw='watch kubectl get --all-namespaces pod'
alias kjwa='watch kubectl get --all-namespaces job'
alias kjaw='watch kubectl get --all-namespaces job'
alias kswa='watch kubectl get --all-namespaces service'
alias ksaw='watch kubectl get --all-namespaces service'
alias kdwa='watch kubectl get --all-namespaces deployment'
alias kdaw='watch kubectl get --all-namespaces deployment'
alias kmwa='watch kubectl get --all-namespaces daemonset'
alias kmaw='watch kubectl get --all-namespaces daemonset'
alias kiwa='watch kubectl get --all-namespaces ingress'
alias kiaw='watch kubectl get --all-namespaces ingress'
alias kvwa='watch kubectl get --all-namespaces virtualservices'
alias kvaw='watch kubectl get --all-namespaces virtualservices'

alias kdp='kubectl describe pod'
alias kdj='kubectl describe job'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kdm='kubectl describe daemonset'
alias kdi='kubectl describe ingress'
alias kdv='kubectl describe virtualservices'
alias kdn='kubectl describe node'

alias kjp='kubectl get -o json pod'
alias kjj='kubectl get -o json job'
alias kjs='kubectl get -o json service'
alias kjd='kubectl get -o json deployment'
alias kjm='kubectl get -o json daemonset'
alias kji='kubectl get -o json ingress'
alias kjv='kubectl get -o json virtualservices'
alias kjn='kubectl get -o json node'

alias kyp='kubectl get -o yaml pod'
alias kyj='kubectl get -o yaml job'
alias kys='kubectl get -o yaml service'
alias kyd='kubectl get -o yaml deployment'
alias kym='kubectl get -o yaml daemonset'
alias kyi='kubectl get -o yaml ingress'
alias kyv='kubectl get -o yaml virtualservices'
alias kyn='kubectl get -o yaml node'

alias kDp='kubectl delete pod --grace-period=0 --force'
alias kDj='kubectl delete job --grace-period=0 --force'
alias kDs='kubectl delete service --grace-period=0 --force'
alias kDd='kubectl delete deployment --grace-period=0 --force'
alias kDm='kubectl delete daemonset --grace-period=0 --force'
alias kDi='kubectl delete ingress --grace-period=0 --force'
alias kDv='kubectl delete virtualservices --grace-period=0 --force'

alias ns="kubectl node-shell -n kube-system"
alias kns="kubectl node-shell -n kube-system"

function kl() {
  until kubectl logs -f "$@"; do
    sleep 2
    clearLastLine
  done
}
custom_complete 'kl' 'kubectl logs'


### GIT ###

alias gst='git status'
alias st='git status'
alias gstu='git status -uno'
alias stu='git status -uno'
alias d='git diff'
alias gd='git diff'
alias gdiff='git diff'
alias dif='git diff'
alias gdif='git diff'
alias diff='git diff' # Overwrites built-in diff
alias di='/usr/bin/diff' # Built-in diff
alias difff='/usr/bin/diff' # Built-in diff
alias a='git add'
alias add='git add'
alias ga='git add'
alias grm='git rm'
alias gbr='git branch'
alias gci='git commit'
alias gcm='git commit -m'
alias gcim='git commit -m'
alias gcam='git commit -am'
alias gciam='git commit -am'
alias stash='git stash'
alias merge='git merge'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gcom='git checkout master'
alias log='git log'
alias glog='git log'
alias pull='echo "git pull origin $(get_git_branch)"; git pull origin $(get_git_branch)'
alias pullr='echo "git pull --rebase origin $(get_git_branch)"; git pull --rebase origin $(get_git_branch)'
alias pullm='git pull origin master'
alias pullmr='git pull --rebase origin master'
alias pullrm='pullmr'
alias push='echo "git push origin $(get_git_branch)"; git push origin $(get_git_branch)'
alias pushf='echo "git push -f origin $(get_git_branch)"; git push -f origin $(get_git_branch)'
alias fetch='git fetch'
alias gitpruneall='git checkout master && git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'
alias gpruneall='git checkout master && git fetch --prune && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'
alias gitpruneremote='git fetch --prune'
alias gpruneremote='git fetch --prune'
alias gitprunelocal='git checkout master && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'
alias gprunelocal='git checkout master && git branch -r | awk "{print \$1}" | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk "{print \$1}" | xargs git branch -D'

function rmbranch() {
  git branch -D $1
  git branch -Dr origin/$1
}
function rmbranchremote() {
  rmbranch $1
  git push origin --delete $1  # Delete the remote branch
}
alias grmb='rmbranch'
alias grmbr='rmbranchremote'
custom_complete 'rmbranch' 'git br -d'
custom_complete 'rmbranchremote' 'git br -d'
custom_complete 'grmb' 'git branch -D'
custom_complete 'grmbr' 'git branch -D'

# To install LFS for first time: `brew install git-lfs` followed by `git lfs install`
# To initialize in repo: `git lfs install`
# To track new files: `git lfs track "*.ogg"`
# To list tracked files: `git lfs ls-files`
function lfs-template() {
  cat >./.gitattributes <<EOL
# Folder paths
# assets/ filter=lfs diff=lfs merge=lfs -text

# Generic file types
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.avi filter=lfs diff=lfs merge=lfs -text
*.flv filter=lfs diff=lfs merge=lfs -text
*.wmv filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
*.csv filter=lfs diff=lfs merge=lfs -text
EOL
}

function git_branch_helper {
  cmd=$1
  git stash 1> /dev/null
  branch_current=$(git rev-parse --abbrev-ref HEAD)
  git fetch --all
  for branch_origin in $(git branch -r | grep -v -- "->"); do
    branch="${branch_origin##origin/}"
    echo "==== ${branch} ===="

    git branch --track $branch $branch_origin 2> /dev/null
    git checkout $branch &> /dev/null
    eval $cmd
  done
  git checkout $branch_current &> /dev/null
  git stash pop &> /dev/null
}
alias pullall="git_branch_helper 'git pull'"
alias pushall="git_branch_helper 'git pull; git push'"
alias syncall="git_branch_helper 'git pull; git push'"

function diff_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  changed_files=( $(git diff --name-only) )
  echo "Diff: ${changed_files[index]}"
  git diff "${git_top_level}/${changed_files[index]}"
}
alias diff1='diff_num 0'; alias d1='diff_num 0'
alias diff2='diff_num 1'; alias d2='diff_num 1'
alias diff3='diff_num 2'; alias d3='diff_num 2'
alias diff4='diff_num 3'; alias d4='diff_num 3'
alias diff5='diff_num 4'; alias d4='diff_num 4'

# git add tracked file
function add_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  changed_files=( $(git diff --name-only) )
  echo "Add: ${changed_files[index]}"
  git add "${git_top_level}/${changed_files[index]}"
}
alias add1='add_num 0'; alias a1='add_num 0'
alias add2='add_num 1'; alias a2='add_num 1'
alias add3='add_num 2'; alias a3='add_num 2'
alias add4='add_num 3'; alias a4='add_num 3'
alias add5='add_num 4'; alias a4='add_num 4'

# git add untracked file
function addu_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  new_files=( $(git ls-files --others --exclude-standard $git_top_level) )
  echo "Add: ${new_files[index]}"
  git add "$(pwd)/${new_files[index]}"
}
alias addu1='addu_num 0'; alias au1='addu_num 0'
alias addu2='addu_num 1'; alias au2='addu_num 1'
alias addu3='addu_num 2'; alias au3='addu_num 2'
alias addu4='addu_num 3'; alias au4='addu_num 3'
alias addu5='addu_num 4'; alias au4='addu_num 4'

function gco_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  changed_files=( $(git diff --name-only) )
  echo "Reset: ${changed_files[index]}"
  git checkout -- "${git_top_level}/${changed_files[index]}"
}
alias gco1='gco_num 0'; alias gco2='gco_num 1'; alias gco3='gco_num 2'; alias gco4='gco_num 3'

function grm_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  changed_files=( $(git diff --name-only) )
  git rm "${git_top_level}/${changed_files[index]}"
}
alias grm1='grm_num 0'; alias grm2='grm_num 1'; alias grm3='grm_num 2'; alias grm4='grm_num 3'

function c_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  changed_files=( $(git diff --name-only) )
  code "${git_top_level}/${changed_files[index]}"
}
alias s1='s_num 0'; alias s2='s_num 1'; alias s3='s_num 2'; alias s4='s_num 3'

function cu_num() {
  index=$1
  git_top_level=$(git rev-parse --show-toplevel)
  new_files=( $(git ls-files --others --exclude-standard) )
  code "$(pwd)/${new_files[index]}"
}
alias su1='su_num 0'; alias su2='su_num 1'; alias su3='su_num 2'; alias su4='su_num 3'


### DOCKER ###

alias dl='docker logs -f'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"'
alias dpsa='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" -a'
alias dimages='docker images'
alias dstop='docker stop'
alias dprune='docker container prune -f'
alias dkill='docker kill'
alias dpush='docker push'
alias dinspect='docker inspect'
alias drun='docker run --rm -it --entrypoint=/bin/bash'
alias drunsh='docker run --rm -it --entrypoint=/bin/sh'
function dattach() {
  docker exec -it $1 /bin/bash
}
custom_complete 'dattach' 'docker exec'
function dattachsh() {
  docker exec -it $1 /bin/sh
}
custom_complete 'dattachsh' 'docker exec'
function drm() {
  docker rm $1 >/dev/null 2>/dev/null
}
custom_complete 'drm' 'docker rm'
function drmf() {
  docker rm -f $1 >/dev/null 2>/dev/null
}
custom_complete 'drmf' 'docker rm'
alias drmi='docker rmi'
alias drmcontainers='docker rm -v $(docker ps --no-trunc -aq -f status=exited) 2>/dev/null'
alias drmcontainersall='docker rm -f -v $(docker ps --no-trunc -aq) 2>/dev/null'
alias drmimages='docker rmi $(docker images --no-trunc -q -f "dangling=true") 2>/dev/null'
alias drmimagesall='docker rmi -f $(docker images --no-trunc -q) 2>/dev/null'
alias drmvolumes='docker run -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker:/var/lib/docker --rm martin/docker-cleanup-volumes'
alias dnuke='drmvolumes; drmcontainersall; drmimagesall; docker system prune --all --volumes --force; docker buildx prune --all --force'


### MISC ###

mounttemp() {
  MOUNT_DIR=$HOME/mnt/temp
  LOGIN=ubuntu
  IP=54.212.212.117
  KEY="~/.ssh/key.pem"
  REMOTE_DIR=/home/$LOGIN

  mkdir -p $MOUNT_DIR
  sshfs -o local -o IdentityFile=$KEY $LOGIN@$IP:$REMOTE_DIR $MOUNT_DIR/
  echo "mounted to ${MOUNT_DIR/${HOME}/\~}"
}


### INSTALLATION HELPERS ###  (most are idempotent and will update if already installed)

function install-go-linux () {
  sudo rm -rf /usr/local/go
  version=$(curl --silent https://golang.org/doc/devel/release | grep -Eo 'go[0-9]+(\.[0-9]+)+' | sort -V | uniq | tail -1)
  wget "https://dl.google.com/go/${version}.linux-amd64.tar.gz"
  sudo tar -C /usr/local -xzf "${version}.linux-amd64.tar.gz"
  rm -rf "${version}*"
}

function install-tools-linux () {
  sudo apt update
  sudo apt install -y python3-pip jq bash-completion
  pip3 install yq
  pip3 install awscli --upgrade --user
}

function install-awscli () {
  pip3 install awscli --upgrade --user
}

function install-docker-linux () {
  sudo apt update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo usermod -aG docker $USER
}

function install-eksctl-linux () {
  rm -rf /usr/local/bin/eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/
}

function install-kubectl-linux () {
  sudo rm -rf /usr/local/bin/kubectl
  curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl
}

function install-k9s-linux () {
  sudo rm -rf /usr/local/bin/k9s
  wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
  tar xvzf k9s_Linux_amd64.tar.gz
  sudo mv k9s /usr/local/bin/
  rm LICENSE README.md k9s_*
}

function install-gcloud-linux () {
  # https://cloud.google.com/sdk/docs/quickstart
  # https://stackoverflow.com/questions/46236580/how-to-enable-shell-command-completion-for-gcloud
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  sudo apt-get update
  sudo apt-get install google-cloud-sdk -y
}

function install-minikube-linux () {
  rm -rf /usr/local/bin/minikube
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  chmod +x minikube
  sudo install minikube /usr/local/bin/
}

function install-node-shell () {
  curl -LO https://github.com/kvaps/kubectl-node-shell/raw/master/kubectl-node_shell
  chmod +x ./kubectl-node_shell
  sudo mv ./kubectl-node_shell /usr/local/bin/kubectl-node_shell
}


### CUSTOM COMPLETIONS ###

# _deploy() {
#   local cur=${COMP_WORDS[COMP_CWORD]}
#   if [ "${COMP_CWORD}" == "1" ]; then
#     COMPREPLY=($(compgen -W "registry cluster operator" "${cur}"))
#   elif [ "${COMP_CWORD}" == "2" ] && [ "${COMP_WORDS[1]}" == "registry" ]; then
#     COMPREPLY=($(compgen -W "operator" ${cur}))
#   elif [ "${COMP_CWORD}" == "2" ] && [ "${COMP_WORDS[1]}" == "cluster" ]; then
#     COMPREPLY=($(compgen -W "stop" ${cur}))
#   elif [ "${COMP_CWORD}" == "2" ] && [ "${COMP_WORDS[1]}" == "operator" ]; then
#     COMPREPLY=($(compgen -W "cluster local stop" ${cur}))
#   elif [ "${COMP_CWORD}" == "3" ] && [ "${COMP_WORDS[1]}" == "operator" ] && [ "${COMP_WORDS[2]}" == "cluster" ]; then
#     COMPREPLY=($(compgen -W "stop" ${cur}))
#   else
#     COMPREPLY=($(compgen -f -- "${cur}"))
#   fi
# }
# complete -F _deploy deploy
# OR
# complete -o filenames -F _deploy deploy


# SSH
if [ -f ~/.ssh/config ]; then
  _ssh() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    hosts=$(awk '$1=="Host"{$1="";H=substr($0,2)};$1=="HostName"{print H,"$"}' ~/.ssh/config | column -s '$' -t)
    COMPREPLY=( $(compgen -W "${hosts}" -- $cur) )
  }
  complete -F _ssh ssh
fi

# NPM: This overrides the default. It is faster but may be less complete.
get_npm_script_names() {
  packageJson=$(find_file package.json)
  if [ -z "${packageJson}" ]; then
    echo ''
  else
    arr=$(cat $packageJson | jq '.scripts' | jq -c keys)
    arr=${arr//[/}
    arr=${arr//]/}
    arr=${arr//,/ }
    arr=${arr//\"/}
    echo $arr
  fi
}
get_serverless_functions() {
  serverlessYaml=$(find_file serverless.yml)
  if [ -z "${serverlessYaml}" ]; then
    echo ''
  else
    arr=$(yaml2json $serverlessYaml | jq '.functions' | jq -c keys)
    arr=${arr//[/}
    arr=${arr//]/}
    arr=${arr//,/ }
    arr=${arr//\"/}
    echo $arr
  fi
}
_npm() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  if [ "${COMP_CWORD}" == "1" ]; then
    commands='access config find-dupes issues outdated remove set test v add-user ddp get it owner repo show tst version adduser dedupe help la pack restart shrinkwrap un view apihelp deprecate help-search link ping rm star uninstall whoami author dist-tag home list prefix root stars unlink bin dist-tags i ll prune run start unpublish bugs docs info ln publish run-script stop unstar c edit init login r s t up cache explore install logout rb se tag update completion find install-test ls rebuild search team upgrade'
    COMPREPLY=($(compgen -W "${commands}" ${cur}))
  elif [ "${COMP_CWORD}" == "2" ] && [ "${COMP_WORDS[1]}" == "run" ]; then
    script_names=$(get_npm_script_names)
    if [ -n "${script_names}" ]; then
      COMPREPLY=($(compgen -W "${script_names}" ${cur}))
    fi
  elif [ "${COMP_CWORD}" == "3" ] && [ "${COMP_WORDS[1]}" == "run" ]; then
    if [ "${COMP_WORDS[2]}" == "deployf" ] || [ "${COMP_WORDS[2]}" == "logs" ]; then
      function_names=$(get_serverless_functions)
      if [ -n "${function_names}" ]; then
        COMPREPLY=($(compgen -W "${function_names}" ${cur}))
      fi
    fi
  else
    COMPREPLY=()
  fi
}
complete -F _npm npm


### AUTOCOMPLETE BASH ALIASES ###

alias_blacklist=( ssh "--" "-" "~" )

if ! shopt -oq posix; then
  # SOURCE: https://github.com/cykerway/complete-alias
  _retval=0
  _use_alias=0

  _in () {
    for e in "${@:2}"; do
      [[ "$e" == "$1" ]] && return 0
    done
    return 1
  }

  _expand_alias () {
    local beg="$1" end="$2" ignore="$3" n_used="$4"; shift 4
    local used=( "${@:1:$n_used}" ); shift $n_used

    if [[ "$beg" -eq "$end" ]]; then
      _retval=0
    elif [[ -n "$ignore" ]] && [[ "$beg" -eq "$ignore" ]]; then
      _expand_alias "$(( $beg+1 ))" "$end" "$ignore" "${#used[@]}" "${used[@]}"
      _retval="$_retval"

    #### My version

    elif ! ( ( alias "${COMP_WORDS[$beg]}" &>/dev/null ) || ( alias "__CUSTOM_COMPLETE_${COMP_WORDS[$beg]}" &>/dev/null ) ) || ( _in "${COMP_WORDS[$beg]}" "${used[@]}" ); then
      _retval=0
    else
      local cmd="${COMP_WORDS[$beg]}"

      if ( alias "__CUSTOM_COMPLETE_${cmd}" &>/dev/null ); then
        expanded=$(alias "__CUSTOM_COMPLETE_${cmd}")
      else
        expanded=$(alias "$cmd")
      fi

      local str0="$( echo "$expanded" | sed -E 's/[^=]*=//' | xargs )"

    #### End
    #### His version

    # elif ! ( alias "${COMP_WORDS[$beg]}" &>/dev/null ) || ( _in "${COMP_WORDS[$beg]}" "${used[@]}" ); then
    #   _retval=0
    # else
    #   local cmd="${COMP_WORDS[$beg]}"
    #   local str0="$( alias "$cmd" | sed -E 's/[^=]*=//' | xargs )"

    #### End

      {
        words0=()
        local sta=()
        local i=0 j=0
        for (( j=0;j<${#str0};j++ )); do
          if [[ $' \t\n' == *"${str0:j:1}"* ]]; then
            if [[ ${#sta[@]} -eq 0 ]]; then
              if [[ $i -lt $j ]]; then
                words0+=("${str0:i:j-i}")
              fi
              (( i=j+1 ))
            fi
          elif [[ "><=;|&:" == *"${str0:j:1}"* ]]; then
            if [[ ${#sta[@]} -eq 0 ]]; then
              if [[ $i -lt $j ]]; then
                words0+=("${str0:i:j-i}")
              fi
              words0+=("${str0:j:1}")
              (( i=j+1 ))
            fi
          elif [[ "\"')}" == *"${str0:j:1}"* ]]; then
            if [[ ${#sta[@]} -ne 0 ]] && [[ "${str0:j:1}" == ${sta[-1]} ]]; then
              unset sta[-1]
            fi
          elif [[ "\"'({" == *"${str0:j:1}"* ]]; then
            if [[ "${str0:j:1}" == "\"" ]]; then
              sta+=("\"")
            elif [[ "${str0:j:1}" == "'" ]]; then
              sta+=("'")
            elif [[ "${str0:j:1}" == "(" ]]; then
              sta+=(")")
            elif [[ "${str0:j:1}" == "{" ]]; then
              sta+=("}")
            fi
          fi
        done
        if [[ $i -lt $j ]]; then
          words0+=("${str0:i:j-i}")
        fi
        unset sta
      }
      local i j=0
      for (( i=0; i < $beg; i++ )); do
        for (( ; j <= ${#COMP_LINE}; j++ )); do
          [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break
        done
        (( j+=${#COMP_WORDS[i]} ))
      done
      for (( ; j <= ${#COMP_LINE}; j++ )); do
        [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break
      done
      COMP_LINE="${COMP_LINE[@]:0:j}""$str0""${COMP_LINE[@]:j+${#cmd}}"
      if [[ $COMP_POINT -lt $j ]]; then
        :
      elif [[ $COMP_POINT -lt $(( j+${#cmd} )) ]]; then
        (( COMP_POINT=j+${#str0} ))
      else
        (( COMP_POINT+=${#str0}-${#cmd} ))
      fi
      COMP_WORDS=( "${COMP_WORDS[@]:0:beg}" "${words0[@]}" "${COMP_WORDS[@]:beg+1}" )
      if [[ $COMP_CWORD -lt $beg ]]; then
        :
      elif [[ $COMP_CWORD -lt $(( $beg+1 )) ]]; then
        (( COMP_CWORD=beg+${#words0[@]} ))
      else
        (( COMP_CWORD+=${#words0[@]}-1 ))
      fi
      if [[ -n "$ignore" ]] && [[ $ignore -gt $beg ]]; then
        (( ignore+=${#words0[@]}-1 ))
      fi
      local used0=( "${used[@]}" "$cmd" )
      _expand_alias "$beg" "$(( $beg+${#words0[@]} ))" "$ignore" "${#used0[@]}" "${used0[@]}"
      local diff0="$_retval"

      if [[ -n "$str0" ]] && [[ "${str0: -1}" == ' ' ]]; then
        local used1=( "${used[@]}" )
        _expand_alias "$(( $beg+${#words0[@]}+$diff0 ))" "$(( $end+${#words0[@]}-1+$diff0 ))" "$ignore" "${#used1[@]}" "${used1[@]}"
        local diff1="$_retval"
      else
        local diff1=0
      fi

      _retval=$(( ${#words0[@]}-1+diff0+diff1 ))
    fi
  }

  _set_default_completion () {
    local cmd="$1"

    case "$cmd" in
      bind)
        complete -A binding "$cmd"
        ;;
      help)
        complete -A helptopic "$cmd"
        ;;
      set)
        complete -A setopt "$cmd"
        ;;
      shopt)
        complete -A shopt "$cmd"
        ;;
      bg)
        complete -A stopped -P '"%' -S '"' "$cmd"
        ;;
      service)
        complete -F _service "$cmd"
        ;;
      unalias)
        complete -a "$cmd"
        ;;
      builtin)
        complete -b "$cmd"
        ;;
      command|type|which)
        complete -c "$cmd"
        ;;
      fg|jobs|disown)
        complete -j -P '"%' -S '"' "$cmd"
        ;;
      groups|slay|w|sux)
        complete -u "$cmd"
        ;;
      readonly|unset)
        complete -v "$cmd"
        ;;
      traceroute|traceroute6|tracepath|tracepath6|fping|fping6|telnet|rsh|\
        rlogin|ftp|dig|mtr|ssh-installkeys|showmount)
        complete -F _known_hosts "$cmd"
        ;;
      aoss|command|do|else|eval|exec|ltrace|nice|nohup|padsp|then|time|tsocks|vsound|xargs)
        complete -F _command "$cmd"
        ;;
      fakeroot|gksu|gksudo|kdesudo|really)
        complete -F _root_command "$cmd"
        ;;
      a2ps|awk|base64|bash|bc|bison|cat|chroot|colordiff|cp|csplit|cut|date|\
        df|diff|dir|du|enscript|env|expand|fmt|fold|gperf|grep|grub|head|\
        irb|ld|ldd|less|ln|ls|m4|md5sum|mkdir|mkfifo|mknod|mv|netstat|nl|\
        nm|objcopy|objdump|od|paste|pr|ptx|readelf|rm|rmdir|sed|seq|\
        sha{,1,224,256,384,512}sum|shar|sort|split|strip|sum|tac|tail|tee|\
        texindex|touch|tr|uname|unexpand|uniq|units|vdir|wc|who)
        complete -F _longopt "$cmd"
        ;;
      *)
        _completion_loader "$cmd"
        ;;
    esac
  }

  _complete_alias () {
    local cmd="${COMP_WORDS[0]}"

    if [[ $_use_alias -eq 0 ]]; then

      local i j=0
      for (( i=0; i < $COMP_CWORD; i++ )); do
        for (( ; j <= ${#COMP_LINE}; j++ )); do
          [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break
        done
        (( j+=${#COMP_WORDS[i]} ))
      done
      for (( ; j <= ${#COMP_LINE}; j++ )); do
        [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break
      done

      if [[ $j -le $COMP_POINT ]] && [[ $COMP_POINT -le $(( $j+${#COMP_WORDS[$COMP_CWORD]} )) ]]; then
        local ignore="$COMP_CWORD"
      else
        local ignore=""
      fi

      _expand_alias 0 "${#COMP_WORDS[@]}" "$ignore" 0
    fi
    (( _use_alias++ ))
    _set_default_completion "$cmd"
    _command_offset 0
    (( _use_alias-- ))
    complete -F _complete_alias "$cmd"
  }

  # Complete all aliases
  alias_strs=$(alias -p | sed -Ene "s/alias ([^=]+)=.+/\1/p")
  for alias_str in $alias_strs; do
    if ! ( array_contains "${alias_str}" "${alias_blacklist[@]}" ); then
      complete -F _complete_alias $alias_str
    fi
  done
fi
