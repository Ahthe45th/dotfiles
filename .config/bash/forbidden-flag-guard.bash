# Guard interactive bash sessions: if a command contains an argument exactly
# equal to the forbidden installer flag, shut the machine down before it runs.
# Installed by Hermes/Qantemir.

_qantemir_guard_forbidden_flag='--install-existing'

# With extdebug, a non-zero DEBUG trap return prevents the command from running.
shopt -s extdebug

_qantemir_guard_shutdown() {
  printf '%s\n' 'Shell guard: forbidden flag detected; powering off now.' >&2
  command systemctl poweroff -i
}

_qantemir_guard_command_has_forbidden_flag() {
  local _qantemir_cmd=$1

  # Fast path: avoid invoking Python on every DEBUG trap unless the string
  # actually appears in the command line.
  [[ $_qantemir_cmd == *"$_qantemir_guard_forbidden_flag"* ]] || return 1

  python -c '
import shlex, sys
cmd = sys.argv[1]
flag = sys.argv[2]
try:
    words = shlex.split(cmd, posix=True)
except ValueError:
    # If the interactive line is malformed but plainly contains the flag,
    # fail closed.
    sys.exit(0 if flag in cmd else 1)
sys.exit(0 if flag in words else 1)
' "$_qantemir_cmd" "$_qantemir_guard_forbidden_flag"
}

_qantemir_guard_bash_debug_trap() {
  # Avoid recursion while the guard itself runs.
  [[ ${_qantemir_guard_active:-0} == 1 ]] && return 0
  _qantemir_guard_active=1

  if _qantemir_guard_command_has_forbidden_flag "$BASH_COMMAND"; then
    _qantemir_guard_shutdown
    _qantemir_guard_active=0
    return 130
  fi

  _qantemir_guard_active=0
  return 0
}

trap '_qantemir_guard_bash_debug_trap' DEBUG
