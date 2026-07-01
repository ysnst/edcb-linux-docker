#!/usr/bin/env bash
set -Eeuo pipefail

if [ -z "$(find /var/local/edcb -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "[INFO] /var/local/edcb is empty. Copying initial template."
  cp -a /var/local/edcb.template/. /var/local/edcb/
elif [ ! -f /var/local/edcb/EpgTimerSrv.ini ]; then
  echo "[WARN] /var/local/edcb is not empty, but EpgTimerSrv.ini was not found. Existing files were left untouched."
fi

exec /usr/local/bin/EpgTimerSrv
