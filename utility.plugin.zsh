#!/usr/bin/env zsh

# ---
# Aliases
# ---

alias e="$EDITOR"
command -v nvim > /dev/null && alias ez='nvim +"Telescope oldfiles"' # Must have telescope plugin installed for neovim
alias :q="exit" # vim user be like
alias res="exec zsh" # source .zshrc but better
alias gist='gh gist'
alias grep='grep --color=auto'

# aliases for z.lua
alias zz='z -I'
alias zc='z -c'
alias zb='z -b'
alias zzb='zz -b'
alias zzc='zz -c'
alias zt='zz -t'

# use exa as ls if available
if (( ${+commands[exa]} )); then
  alias ls='exa --group-directories-first'
  alias l='ls -l --git'
  alias la='l -a'
  alias ltree='l -T'
  alias lx='l -s extension'
  alias lk='l -s size'
  alias lm='l -s modified'
  alias lc='l -s accessed'
else
  alias ls='ls --group-directories-first --color'
  alias l='ls -lh'
  alias lk='l -Sr'
  alias lm='l -tr'
fi

# a get command, taken from zim's
if (( ${+commands[aria2c]} )); then
  alias get='aria2c --max-connection-per-server=5 --continue'
elif (( ${+commands[axel]} )); then
  alias get='axel --num-connections=5 --alternate'
elif (( ${+commands[wget]} )); then
  alias get='wget --continue --progress=bar --timestamping'
fi

# Safer rm command
if (( ${+commands[trash-put]} )); then
  alias rm='trash-put'
else
  alias rm='rm -i'
fi

# ---
# Functions
# ---

# taken from https://github.com/peterhurford/up.zsh
function u(){
  if [[ "$#" -ne 1 ]]; then
    cd ..
  elif ! [[ $1 =~ '^[0-9]+$' ]]; then
    echo "Error: up should be called with the number of directories to go up. The default is 1."
  else
    local d=""
    limit=$1
    for ((i=1 ; i <= limit ; i++))
      do
        d=$d/..
      done
    d=$(echo $d | sed 's/^\///')
    cd $d
  fi
}

function ex() {
  if [ -f $1 ]; then
    case ${1} in
      *.tar) tar -xf $1 ;;
      *.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar -xjf $1 ;;
      *.tar.gz|*.tgz) tar -xzf $1 ;;
      *.tar.lzma|*.tlz) tar -xf $1 ;;
      *.tar.xz|*.txz) tar -xJf $1 ;;
      *.tar.zst|*.tzst) tar --use-compress-program=unzstd -xvf $1 ;;
      *.bz|*.bz2) bunzip2 $1 ;;
      *.gz) gunzip $1 ;;
      *.lzma) unlzma -T0 $1 ;;
      *.xz) unxz -T0 $1 ;;
      *.zst) zstd -T0 -d $1 ;;
      *.zip) unzip $1;;
      *.rar) unrar x -ad $1 ;;
      *.7z) 7z x $1 ;;
      *.Z) uncompress $1 ;;
      *) echo "'$1' cannot be extracted via ex" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ohmyzsh's stuff
function copypath {
  # If no argument passed, use current directory
  local file="${1:-.}"

  # If argument is not an absolute path, prepend $PWD
  [[ $file = /* ]] || file="$PWD/$file"

  # Copy the absolute path without resolving symlinks
  # If clipcopy fails, exit the function with an error
  print -n "${file:a}" | pbcopy || return 1

  echo ${(%):-"%B${file:a}%b copied to clipboard."}
}

function __sudo-replace-buffer() {
  local old=$1 new=$2 space=${2:+ }

  # if the cursor is positioned in the $old part of the text, make
  # the substitution and leave the cursor after the $new text
  if [[ $CURSOR -le ${#old} ]]; then
    BUFFER="${new}${space}${BUFFER#$old }"
    CURSOR=${#new}
  # otherwise just replace $old with $new in the text before the cursor
  else
    LBUFFER="${new}${space}${LBUFFER#$old }"
  fi
}

function sudo-command-line() {
  # If line is empty, get the last run command from history
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"

  # Save beginning space
  local WHITESPACE=""
  if [[ ${LBUFFER:0:1} = " " ]]; then
    WHITESPACE=" "
    LBUFFER="${LBUFFER:1}"
  fi

  {
    # If $SUDO_EDITOR or $VISUAL are defined, then use that as $EDITOR
    # Else use the default $EDITOR
    local EDITOR=${SUDO_EDITOR:-${VISUAL:-$EDITOR}}

    # If $EDITOR is not set, just toggle the sudo prefix on and off
    if [[ -z "$EDITOR" ]]; then
      case "$BUFFER" in
        sudo\ -e\ *) __sudo-replace-buffer "sudo -e" "" ;;
        sudo\ *) __sudo-replace-buffer "sudo" "" ;;
        *) LBUFFER="sudo $LBUFFER" ;;
      esac
      return
    fi

    # Check if the typed command is really an alias to $EDITOR

    # Get the first part of the typed command
    local cmd="${${(Az)BUFFER}[1]}"
    # Get the first part of the alias of the same name as $cmd, or $cmd if no alias matches
    local realcmd="${${(Az)aliases[$cmd]}[1]:-$cmd}"
    # Get the first part of the $EDITOR command ($EDITOR may have arguments after it)
    local editorcmd="${${(Az)EDITOR}[1]}"

    # Note: ${var:c} makes a $PATH search and expands $var to the full path
    # The if condition is met when:
    # - $realcmd is '$EDITOR'
    # - $realcmd is "cmd" and $EDITOR is "cmd"
    # - $realcmd is "cmd" and $EDITOR is "cmd --with --arguments"
    # - $realcmd is "/path/to/cmd" and $EDITOR is "cmd"
    # - $realcmd is "/path/to/cmd" and $EDITOR is "/path/to/cmd"
    # or
    # - $realcmd is "cmd" and $EDITOR is "cmd"
    # - $realcmd is "cmd" and $EDITOR is "/path/to/cmd"
    # or
    # - $realcmd is "cmd" and $EDITOR is /alternative/path/to/cmd that appears in $PATH
    if [[ "$realcmd" = (\$EDITOR|$editorcmd|${editorcmd:c}) \
      || "${realcmd:c}" = ($editorcmd|${editorcmd:c}) ]] \
      || builtin which -a "$realcmd" | command grep -Fx -q "$editorcmd"; then
      __sudo-replace-buffer "$cmd" "sudo -e"
      return
    fi

    # Check for editor commands in the typed command and replace accordingly
    case "$BUFFER" in
      $editorcmd\ *) __sudo-replace-buffer "$editorcmd" "sudo -e" ;;
      \$EDITOR\ *) __sudo-replace-buffer '$EDITOR' "sudo -e" ;;
      sudo\ -e\ *) __sudo-replace-buffer "sudo -e" "$EDITOR" ;;
      sudo\ *) __sudo-replace-buffer "sudo" "" ;;
      *) LBUFFER="sudo $LBUFFER" ;;
    esac
  } always {
    # Preserve beginning space
    LBUFFER="${WHITESPACE}${LBUFFER}"

    # Redisplay edit buffer (compatibility with zsh-syntax-highlighting)
    zle redisplay
  }
}

function copybuffer () {
  if which pbcopy &>/dev/null; then
    printf "%s" "$BUFFER" | pbcopy
  else
    zle -M "pbcopy not found. Please make sure you have https://github.com/zpm-zsh/clipboard installed correctly."
  fi
}

function symmetric-ctrl-z () {
  local usage=(
    "Use CTRL-z to bring background processes back to the foreground"
  )
  [[ $1 == "-h" ]] && printf "%s\n" $usage && return
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}

zle -N sudo-command-line
zle -N copybuffer
zle -N symmetric-ctrl-z

bindkey '\e\e' sudo-command-line
bindkey "^O" copybuffer
bindkey '^Z' symmetric-ctrl-z

# vim:et sts=2 sw=2 ft=zsh
