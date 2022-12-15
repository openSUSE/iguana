#!/bin/bash

[ -n "$IGUANA_DEBUG" ] && set -x

if [ "$root"x != "iguanabootx" ]; then
  if [ -z "${IGUANA_CONTAINERS}${IGUANA_CONTROL_URL}" ]; then
    # only boot iguana on existing root if we really intend to
    echo "Root device is set, but iguana control not set explicitelly. Skipping Iguana."
    exit 0
  fi
  EXISTING_ROOT=1
fi

IGUANA_WORKFLOW="/usr/bin/iguana-workflow"

if [ ! -x "$IGUANA_WORKFLOW" ]; then
  echo "Missing Iguana workflow binary!"
  sleep 10
  exit 1
fi

NEWROOT="${NEWROOT:-/sysroot}"
export NEWROOT

# Directories for container data sharing and results
mkdir -p /iguana
mkdir -p "$NEWROOT"

# Open reporting fifo
if [ -e /usr/bin/plymouth ] ; then
    mkfifo /iguana/progress
    bash -c 'while true ; do read msg < /iguana/progress ; plymouth message --text="$msg" ; done' &
    PROGRESS_PID=$!
else
    mkfifo /iguana/progress
    bash -c 'while true ; do read msg < /iguana/progress ; echo -n -e "\033[2K$msg\015" > /dev/console ; done' &
    PROGRESS_PID=$!
fi

echo -n > /iguana/dc_progress
bash -c 'tail -f /iguana/dc_progress | while true ; do read msg ; echo "$msg" > /iguana/progress ; done' &
DC_PROGRESS_PID=$!

if ! declare -f Echo > /dev/null ; then
  Echo() {
    echo -e "$@"
    echo -e "$@" > /iguana/progress
  }
fi

Echo "Preparing Iguana boot environment"

if [ -n "$EXISTING_ROOT"] && mount "$EXISTING_ROOT" "$NEWROOT"; then
  # We have already existing root, mount it and copy persistent data
  cp "$NEWROOT/etc/machine-id" /etc/machine-id
  # .. add anything to be machine stable here
  umount "$NEWROOT"
else
  # Either empty root or cannot mount it.
  # clear preexisting machine id from initrd build if present and setup new so we have something
  rm -f /etc/machine-id
  rm -f /etc/hostname
  rm -f /var/lib/dbus/machine-id
  systemd-machine-id-setup
fi

# Pass machine id to the containers through shared dir
cp /etc/machine-id /iguana/machine-id

# make sure there are no pending changes in devices
udevadm settle -t 60

# from now on, disable automatic RAID assembly
udevproperty rd_NO_MD=1

# config podman
mkdir -p /etc/containers/containers.conf.d
cat << 'EOF' > /etc/containers/containers.conf.d/no_pivot_root.conf
# We are running in initramfs and cannot pivout out
[engine]
no_pivot_root = true
EOF

# TODO: add local image stores for when using DVD/ISO.
# ensure we are using overlay driver, SLE was forcing btrfs
cat << 'EOF' >/etc/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/var/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
additionalimagestores = []

size = ""
EOF

# what we need:
# - registry (hardcode registry.suse.com?, take from control file? opensuse will want registry.opensuse.org. Others would want different
# - image name
# - how to start the image:
#   - bind mounts, volumes, priviledged, ports published
# - directory with results

IGUANA_BUILDIN_CONTROL="/etc/iguana/control.yaml"
IGUANA_CMDLINE_EXTRA="--newroot=${NEWROOT} ${IGUANA_DEBUG:+--debug --log-level=debug}"

if [ -n "$IGUANA_CONTROL_URL" ]; then
  curl --insecure -o control_url.yaml -L -- "$IGUANA_CONTROL_URL"
  if [ $? -ne 0 ]; then
    Echo "Failed to download provided control file, ignoring"
    sleep 5
  fi
fi

if [ -f control_url.yaml ]; then
  $IGUANA_WORKFLOW $IGUANA_CMDLINE_EXTRA control_url.yaml
elif [ -n "$IGUANA_CONTAINERS" ]; then
  Echo "Using container list from kcmdline: ${IGUANA_CONTAINERS}"
  readarray -d , -t container_array <<< "$IGUANA_CONTAINERS"

  cat > /control_containers.yaml << EOH
name: Dynamic containers yaml

jobs:
EOH
  N=0
  for c in "${container_array}"; do
    cat >> /control_containers.yaml << EOF
  job${N}:
    container:
      image: ${c}
EOF
  let N=$N+1
  done
  $IGUANA_WORKFLOW $IGUANA_CMDLINE_EXTRA /control_containers.yaml
# control.yaml is buildin control file in initrd
elif [ -f "$IGUANA_BUILDIN_CONTROL" ]; then
  $IGUANA_WORKFLOW $IGUANA_CMDLINE_EXTRA "$IGUANA_BUILDIN_CONTROL"
fi

Echo "Containers run finished"

# Mount new roots for upcoming switch_root
if [ -f /iguana/mountlist ]; then
  cat /iguana/mountlist | while read device mountpoint; do
    mount "$device" "$mountpoint" || Echo "Failed to mount ${device} as ${mountpoint}"
    if [ "$mountpoint" == "$NEWROOT" ]; then
      root=$device
    fi
  done
fi

[ -f /iguana/kernelAction ] && KERNEL_ACTION=$(cat /iguana/kernelAction)

if [ "$KERNEL_ACTION" == "kexec" ]; then
  umount -a
  sync
  kexec -e
  Echo "Preloaded kexec failed!"
fi

# TODO: add proper kernel action parsing
# TODO: this is really naive
# Scan $NEWROOT for installed kernel, initrd and command line
# in case installed system has different kernel then the one we are running we need to kexec to new one
if mount | grep -q "$NEWROOT"; then
  CUR_KERNEL=$(cat /proc/version | sed -n -e 's/^Linux version \([^ ]*\) .*$/\1/p')
  NEW_KERNEL=$(ls ${NEWROOT}/lib/modules/)
  if [ "$CUR_KERNEL" != "$NEW_KERNEL" ]; then
    Echo "Initrd kernel '${CUR_KERNEL}' is different from installed kernel '${NEW_KERNEL}'. Trying kexec"
    kexec -l "${NEWROOT}/boot/vmlinuz" --initrd="${NEWROOT}/boot/initrd" --reuse-cmdline
    umount -a
    sync
    kexec -e
    Echo "Kexec failed, rebooting with correct kernel version in 5s"
    sleep 5
    reboot -f
  fi
else
  Echo "[WARN] New root not mounted!"
fi

[ -n "$PROGRESS_PID" ] && kill $PROGRESS_PID
[ -n "$DC_PROGRESS_PID" ] && kill $DC_PROGRESS_PID
