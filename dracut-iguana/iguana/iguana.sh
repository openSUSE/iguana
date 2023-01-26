#!/bin/bash

[ -n "$IGUANA_DEBUG" ] && set -x

. /lib/dracut-iguana-lib.sh

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

Echo "Preparing Iguana boot environment"

if [ -n "$EXISTING_ROOT" ] && mount "$EXISTING_ROOT" "$NEWROOT"; then
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
IGUANA_CMDLINE_EXTRA="--newroot='${NEWROOT}' ${IGUANA_DEBUG:+--debug --log-level=debug}"

if [ -n "$IGUANA_CONTROL_URL" ]; then
  if ! curl --insecure -o control_url.yaml -L -- "$IGUANA_CONTROL_URL"; then
    Echo "[ERROR] Failed to download control file ${IGUANA_CONTROL_URL}."
    if [ -z "$IGUANA_DEBUG" ]; then
      Echo "Trying to continue without it in 10s"
      sleep 10
    else
      emergency_shell "iguana" "Failed to download control file ${IGUANA_CONTROL_URL}."
    fi
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
  for c in "${container_array[@]}"; do
    cat >> /control_containers.yaml << EOF
  job${N}:
    container:
      image: ${c}
EOF
  N=$(( N + 1 ))
  done
  $IGUANA_WORKFLOW $IGUANA_CMDLINE_EXTRA /control_containers.yaml
# control.yaml is buildin control file in initrd
elif [ -f "$IGUANA_BUILDIN_CONTROL" ]; then
  $IGUANA_WORKFLOW $IGUANA_CMDLINE_EXTRA "$IGUANA_BUILDIN_CONTROL"
fi

Echo "Containers run finished"

# First if workflow set kernelAction then do that
if [ -f /iguana/kernelAction ]; then
  KERNEL_ACTION=$(cat /iguana/kernelAction)
  iguana_reboot_action "$KERNEL_ACTION"
fi

# If we are still alive, mount new root for upcoming switch_root
if [ ! -f /iguana/mountlist ]; then
  # Call default root detection based on DPS in case workflow did not create it
  guess_root_mount
fi

# If we still do not have any mount list our only option is to reboot and hope for the best
if [ ! -f /iguana/mountlist ]; then
  Echo "No partitions to boot from detected! Rebooting in 5 seconds"
  sleep 5
  iguana_reboot_action "reboot"
fi

while read device mountpoint; do
  if [ "$mountpoint" == "$NEWROOT" ]; then
    root=$device
    if is_root_encrypted "$device"; then
      Echo "Encrypted root partition detected, rebooting"
      iguana_reboot_action "reboot"
    fi
  fi
  mount "$device" "$mountpoint" || Echo "Failed to mount ${device} as ${mountpoint}"
done < /iguana/mountlist

# TODO: add proper kernel action parsing
# TODO: this is really naive
# Scan $NEWROOT for installed kernel, initrd and command line
# in case installed system has different kernel then the one we are running we need to kexec to new one
if mount | grep -q "$NEWROOT"; then
  CUR_KERNEL=$(sed -n -e 's/^Linux version \([^ ]*\) .*$/\1/p' < /proc/version)
  NEW_KERNEL=$(ls "${NEWROOT}/lib/modules/")
  if [ "$CUR_KERNEL" != "$NEW_KERNEL" ]; then
    Echo "Initrd kernel '${CUR_KERNEL}' is different from installed kernel '${NEW_KERNEL}'. Trying kexec"
    kexec -l "${NEWROOT}/boot/vmlinuz" --initrd="${NEWROOT}/boot/initrd" --reuse-cmdline
    umount -a
    sync
    iguana_reboot_action "kexec"
  fi
else
  emergency_shell -n "iguana" "New root not mounted and no reboot requested!"
fi

[ -n "$PROGRESS_PID" ] && kill $PROGRESS_PID
[ -n "$DC_PROGRESS_PID" ] && kill $DC_PROGRESS_PID
