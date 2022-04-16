#!/usr/bin/env zsh

# general
alias ze="$EDITOR ~/.zshrc"
alias e="$EDITOR"
alias zr="exec zsh"
alias asroot='sudo $(fc -ln -1)'

# file navigation
alias j="jump"
function mkcd() {
  if [[ ! -d ${1} ]]; then
    mkdir ${1} && builtin cd ${1}
  fi
}
alias ofm="exo-open --launch FileManager "$(pwd)""

# archiving
function unarchive() {
  if (( # < 1 )); then
    print -u2 "usage: ${0} <archive_name.ext>..."
    return 2
  fi
  setopt LOCAL_OPTIONS ERR_RETURN
  while (( # > 0 )); do
    case ${1} in
      (*.rar) (( ${+commands[unrar]} )) && unrar x -ad ${1} || rar x -ad ${1} ;;
      (*.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar -xvjf ${1} ;;
      (*.tar.gz|*.tgz) tar -xvzf ${1} ;;
      (*.tar.lzma|*.tlz) tar --lzma --help &>/dev/null && XZ_OPT=-T0 tar --lzma -xvf ${1} \
        || lzcat ${1} | tar -xvf - ;;
      (*.tar.xz|*.txz) tar -J --help &>/dev/null && XZ_OPT=-T0 tar -xvJf ${1} \
        || xzcat ${1} | tar -xvf - ;;
      (*.tar.zst|*.tzst) XZ_OPT=-T0 tar --use-compress-program=unzstd -xvf ${1} ;;
      (*.tar) tar -xvf ${1} ;;
      (*.zip) unzip ${1};;
      (*.bz|*.bz2) bunzip2 ${1} ;;
      (*.gz) gunzip ${1} ;;
      (*.lzma) unlzma -T0 ${1} ;;
      (*.xz) unxz -T0 ${1} ;;
      (*.zst) zstd -T0 -d ${1} ;;
      (*.Z) uncompress ${1} ;;
      (*) print -u2 "${0}: unknown archive type: ${1}" ;;
    esac
    shift
  done
}
function archive() {
  if (( # < 2 )); then
    print -u2 "usage: ${0} <archive_name.ext> <file>..."
    return 2
  fi
  case ${1} in
    (*.7z) 7za a "${@}" ;;
    (*.rar) rar a "${@}" ;;
    (*.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar --use-compress-program=${${(k)commands[pbzip2]}:-bzip2} -cvf "${@}" ;;
    (*.tar.gz|*.tgz) tar --use-compress-program=${${(k)commands[pigz]}:-gzip} -cvf "${@}" ;;
    (*.tar.lzma|*.tlz) tar --lzma --help &>/dev/null && XZ_OPT=-T0 tar --lzma -cvf "${@}" ;;
    (*.tar.xz|*.txz) tar -J --help &>/dev/null && XZ_OPT=-T0 tar -cvJf "${@}" ;;
    (*.tar.zst|*.tzst) XZ_OPT=-T0 tar --use-compress-program=zstd -cvf "${@}" ;;
    (*.tar) tar -cvf "${@}" ;;
    (*.zip) zip -r "${@}" ;;
    (*.bz|*.bz2) print -u2 "${0}: .bzip2 is only useful for single files, and does not capture permissions. Use .tar.bz2" ;;
    (*.gz) print -u2 "${0}: .gz is only useful for single files, and does not capture permissions. Use .tar.gz" ;;
    (*.lzma) print -u2 "${0}: .lzma is only useful for single files, and does not capture permissions. Use .tar.lzma" ;;
    (*.xz) print -u2 "${0}: .xz is only useful for single files, and does not capture permissions. Use .tar.xz" ;;
    (*.zst) print -u2 "${0}: .zst is only useful for single files, and does not capture permissions. Use .tar.zst" ;;
    (*.Z) print -u2 "${0}: .Z is only useful for single files, and does not capture permissions." ;;
    (*) print -u2 "${0}: unknown archive type: ${1}" ;;
  esac
}
function lsarchive() {
  if (( # < 1 )); then
    print -u2 "usage: ${0} <archive_name.ext>..."
    return 2
  fi
  setopt LOCAL_OPTIONS ERR_RETURN
  while (( # > 0 )); do
    case ${1} in
      (*.7z|*.001) 7za l ${1} ;;
      (*.rar) (( ${+commands[unrar]} )) && unrar l ${1} || rar l ${1} ;;
      (*.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar -tvjf ${1} ;;
      (*.tar.gz|*.tgz) tar -tvzf ${1} ;;
      (*.tar.lzma|*.tlz) tar --lzma --help &>/dev/null && XZ_OPT=-T0 tar --lzma -tvf ${1} \
        || lzcat ${1} | tar -tvf - ;;
      (*.tar.xz|*.txz) tar -J --help &>/dev/null && XZ_OPT=-T0 tar -tvJf ${1} \
        || xzcat ${1} | tar -tvf - ;;
      (*.tar.zst|*.tzst) XZ_OPT=-T0 tar --use-compress-program=unzstd -tvf "${@}" ;;
      (*.tar) tar -tvf ${1} ;;
      (*.zip) unzip -l ${1} ;;
      (*.gz) gunzip -l ${1} ;;
      (*.xz) unxz -T0 -l ${1} ;;
      (*.zst) zstd -T0 -l ${1} ;;
      (*) print -u2 "${0}: unknown archive type: ${1}" ;;
    esac
    shift
  done
}
alias ext='unarchive'
alias mkx='archive'
alias lsx='lsarchive'

# file listing
if (( ${+commands[exa]} )); then
  alias ls='exa'
  export EXA_COLORS='da=1;34:gm=1;34'
fi
alias ls='ls --group-directories-first'
alias ll='ls -l --git'        # Long format, git status
alias l='ll -a'               # Long format, all files
alias lr='ll -T'              # Long format, recursive as a tree
alias lx='ll -sextension'     # Long format, sort by extension
alias lk='ll -ssize'          # Long format, largest file size last
alias lt='ll -smodified'      # Long format, newest modification time last
alias lc='ll -schanged'       # Long format, newest status change (ctime) last

# networking
alias externalip='curl -s icanhazip.com'
alias localips='ip -brief -color address'
if (( ${+commands[aria2c]} )); then
  alias get='aria2c --max-connection-per-server=5 --continue'
elif (( ${+commands[axel]} )); then
  alias get='axel --num-connections=5 --alternate'
elif (( ${+commands[wget]} )); then
  alias get='wget --continue --progress=bar --timestamping'
fi
alias gist='gh gist'
function getxcd() {
  local data thedir
  data="$(mktemp)"
  get "$1" > "$data"
  unarchive "$data"
  thedir="$(archive "$data" | head -n 1)"
  rm "$data"
  cd "$thedir"
}
function gitcd() {
  git clone "$1"
  cd "$(basename ${1%%.git})"
}
alias gxd="getxcd"
alias gd="gitcd"

# colors
if (( terminfo[colors] >= 8 )); then
  # grep colours
  if (( ! ${+GREP_COLOR} )) export GREP_COLOR='37;45'               #BSD
  if (( ! ${+GREP_COLORS} )) export GREP_COLORS="mt=${GREP_COLOR}"  #GNU
  if [[ ${OSTYPE} == openbsd* ]]; then
    if (( ${+commands[ggrep]} )) alias grep='ggrep --color=auto'
  else
    alias grep='grep --color=auto'
  fi

  # less colours
  if (( ${+commands[less]} )); then
    if (( ! ${+LESS_TERMCAP_mb} )) export LESS_TERMCAP_mb=$'\E[1;31m'   # Begins blinking.
    if (( ! ${+LESS_TERMCAP_md} )) export LESS_TERMCAP_md=$'\E[1;31m'   # Begins bold.
    if (( ! ${+LESS_TERMCAP_me} )) export LESS_TERMCAP_me=$'\E[0m'      # Ends mode.
    if (( ! ${+LESS_TERMCAP_se} )) export LESS_TERMCAP_se=$'\E[27m'     # Ends standout-mode.
    if (( ! ${+LESS_TERMCAP_so} )) export LESS_TERMCAP_so=$'\E[7m'      # Begins standout-mode.
    if (( ! ${+LESS_TERMCAP_ue} )) export LESS_TERMCAP_ue=$'\E[0m'      # Ends underline.
    if (( ! ${+LESS_TERMCAP_us} )) export LESS_TERMCAP_us=$'\E[1;32m'   # Begins underline.
  fi
else
  # See https://no-color.org
  export NO_COLOR=1
fi



# vim:et sts=2 sw=2 ft=zsh
