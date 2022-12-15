#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

if [ -z "$root" ] || [ "$root"x == "iguanabootx" ]; then
  exit 0
fi

_name="$(str_replace "${root#block:}" '/' '\x2f')"
for f in wait-network.sh "devexists-$_name.sh"; do
  if [ ! -e "$hookdir/initqueue/finished/\$f" ] || ( . "$hookdir/initqueue/finished/\$f" ); then
    rm -f -- "$hookdir/initqueue/finished/wait-network.sh"
    rm -f -- "$hookdir/initqueue/finished/devexists-$_name.sh"
  fi
done
