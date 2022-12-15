#!/bin/sh

if [ -z "$root" ] ; then
  root=iguanaboot
fi

rootok=1

# Handle command line options
# should be rd.iguana.$

export IGUANA_CONTAINERS=$(getarg rd.iguana.containers)
export IGUANA_CONTROL_URL=$(getarg rd.iguana.control_url)

if getargbool 0 rd.iguana.debug -o getargbool 0 rd.debug; then
  export IGUANA_DEBUG=1
fi
