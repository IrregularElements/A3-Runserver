#!/usr/bin/env bash
# Run as the arma user:
#   ./runserver Server/Vindicta-WW2-Chernarus

set -ex

atexit() {
  set +e
  [[ -n $HEADLESS_PID ]] && kill -- $HEADLESS_PID
  for (( i=${#FUSEMOUNTS[@]}-1 ; i>=0 ; i-- )) ; do
    fusermount -uz -- "${FUSEMOUNTS[i]}"
  done
}
trap atexit EXIT

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

MODDIR="$(readlink -f "$DIR/Mods")"

SERVERDIR="$1" ; shift 1
[[ -d Server/$SERVERDIR ]] && SERVERDIR="Server/$SERVERDIR"

if [[ -n $1 && -d $1 ]]; then
  ARMADIR="$1" ; shift 1
else
  if [[ -e default.txt ]]; then
    ARMADIR="$(readlink -f "$(cat default.txt)")"
  else
    ARMADIR="${DIR}/1.98.146373"
  fi
fi

export DISPLAY=:15
export WINEPREFIX=$HOME/.wine_armaserver
Xvfb $DISPLAY &
ulimit -n 10240
wineserver -p1

function join_by() {
  local d="$1"; shift
  echo -n "$1"
  shift || return
  printf "%s" "${@/#/$d}"
}


readarray -t _SERVERMODS <"$SERVERDIR/servermods.txt"
for M in "${_SERVERMODS[@]}" ; do
  SERVERMODS+=("$(winepath -w "$MODDIR/$M")")
done

readarray -t _MODS <"$SERVERDIR/mods.txt"
for M in "${_MODS[@]}" ; do
  MODS+=("$(winepath -w "$MODDIR/$M")")
done

HEADLESS=
[[ -e ${SERVERDIR}/headless.run ]] && HEADLESS=1

FUSEMOUNTS=()
mkdir -p -- "$SERVERDIR/Arma"
bindfs -o nonempty "$ARMADIR" "$SERVERDIR/Arma" && FUSEMOUNTS+=("$SERVERDIR"/Arma)
bindfs -o nonempty "$SERVERDIR/MPMissions" "$SERVERDIR/Arma/MPMissions" && FUSEMOUNTS+=("$SERVERDIR/Arma/MPMissions")
bindfs -o nonempty "$SERVERDIR/userconfig" "$SERVERDIR/Arma/userconfig" && FUSEMOUNTS+=("$SERVERDIR/Arma/userconfig")

HEADLESS_PID=
if [[ -n $HEADLESS ]] ; then
  wine "$SERVERDIR"/Arma/arma3_x64.exe \
    -client \
    -connect 127.0.0.1 \
    -mod="$(join_by ";" "${MODS[@]}")" &
  HEADLESS_PID=$!
  echo "Headless client PID: $HEADLESS_PID"
  sleep 1
  ps -f "$HEADLESS_PID"
  disown
fi

wine "$SERVERDIR"/Arma/arma3server_x64.exe \
  -nosplash \
  -port=2302 \
  -name=server \
  -profiles="$(winepath -w "$SERVERDIR")" \
  -cfg="$(winepath -w "$SERVERDIR"/basic.cfg)" \
  -config="$(winepath -w "$SERVERDIR"/server.cfg)" \
  -world=altis \
  -servermod="$(join_by ";" "${SERVERMODS[@]}")" \
  -mod="$(join_by ";" "${MODS[@]}")"
