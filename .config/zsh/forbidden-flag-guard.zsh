# Guard interactive zsh sessions: if a command contains an argument exactly
# equal to the forbidden installer flag, shut the machine down before it runs.
# Installed by Hermes/Qantemir.

_qantemir_guard_forbidden_flag='--install-existing'
_qantemir_guard_shutdown() {
  print -u2 -- "Shell guard: forbidden flag detected; powering off now."
  command systemctl poweroff -i
}

_qantemir_guard_check_words() {
  emulate -L zsh
  local -a _qantemir_words
  local _qantemir_word

  # ${(z)1} tokenizes the command line using zsh lexical rules, so quoted
  # strings and escaped spaces are handled like shell words.
  _qantemir_words=(${(z)1})
  for _qantemir_word in "${_qantemir_words[@]}"; do
    if [[ "$_qantemir_word" == "$_qantemir_guard_forbidden_flag" ]]; then
      return 0
    fi
  done
  return 1
}

_qantemir_guard_accept_line() {
  if _qantemir_guard_check_words "$BUFFER"; then
    _qantemir_guard_shutdown
    BUFFER=''
    zle reset-prompt
    return 1
  fi

  zle .accept-line
}

# Override the normal Enter/accept-line widget so the bad command is never
# accepted into execution from an interactive zsh prompt.
zle -N accept-line _qantemir_guard_accept_line
