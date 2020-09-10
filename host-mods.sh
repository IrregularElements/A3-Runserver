#!/usr/bin/env bash
# For write access, run
#   ./host-mods.sh --write

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"
cleanup() {
  pkill -f -INT pyftpdlib
  sleep 1
}
cleanup
trap cleanup EXIT
python3 -m pyftpdlib --directory=Mods --port=21 "$@"
