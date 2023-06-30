#!/bin/sh

if [ -z "$root" ] ; then
  root=iguanaboot
fi

# shellcheck disable=SC2034
rootok=1

# Handle command line options
# should be rd.iguana.$

IGUANA_CONTAINERS=$(getarg rd.iguana.containers)
IGUANA_CONTROL_URL=$(getarg rd.iguana.control_url)
export IGUANA_CONTAINERS
export IGUANA_CONTROL_URL

if getargbool 0 rd.iguana.debug -o getargbool 0 rd.debug; then
  export IGUANA_DEBUG=1
fi
