#!/bin/bash

if ! declare -f Echo > /dev/null ; then
  Echo() {
    echo -e "$@"
    echo -e "$@" > /iguana/progress
  }
fi

if [ -n "$IGUANA_DEBUG" ]; then
  echo "export PS1='iguana@\h:\w> '" > /root/.bashrc
  setsid sh -c 'exec /bin/bash </dev/tty2 >/dev/tty2 2>&1'
fi

function iguana_reboot_action() {
  # Always do reboot, only in case of kexec action try kexec first
  # Kexec must be already prepared
  if [ "kexec" == "$1" ]; then
    umount -a
    sync
    kexec -e
    Echo "Kexec failed, trying reboot"
    sleep 5
  fi
  if [ "unless-debug" == "$2" ] && [ -n "$IGUANA_DEBUG" ]; then
    Echo "Debug mode enabled, dropping to emergency shell instead of reboot"
    emergency_shell -n "iguana"
  else
    reboot -f -d -n
  fi
}

function guess_root_mount() {
  # look for first disk partitition with known root PARTUUIDs
  # see https://uapi-group.org/specifications/specs/discoverable_partitions_specification/
  # Supported currently are:
  #   AArch64:      b921b045-1df0-41c3-af44-4c6f280d3fae
  #                 SD_GPT_ROOT_ARM64
  #   amd64/x86_64: 4f68bce3-e8cd-4db1-96e7-fbcaf984b709
  #                 SD_GPT_ROOT_X86_64
  newroot="$1"
  supported_uuids=""
  arch=$(LANG=C lscpu -J | jq '.lscpu | map(select(.field == "Architecture:")) | .[].data')
  case "$arch" in
    x86_64)
      supported_uuids="4f68bce3-e8cd-4db1-96e7-fbcaf984b709 SD_GPT_ROOT_X86_64"
      ;;
    aarch64)
      supported_uuids="b921b045-1df0-41c3-af44-4c6f280d3fae SD_GPT_ROOT_ARM64"
      ;;
  esac

  # Lookup based on PARTUUID, but return UUID as only that should be unique
  found_root=$(lsblk -o UUID,PARTUUID,FSTYPE -n -l -J | jq ".blockdevices |
        map(select(.partuuid != null) | select(.partuuid | ascii_downcase | inside(\"${supported_uuids}\"))) | .[0].uuid")

  uuid_prefix="/dev/disk/by-uuid/"
  if [ -b "${uuid_prefix}${found_root}" ]; then
    echo "${uuid_prefix}${found_root} $newroot" > /iguana/mountlist
    return 0
  fi
  return 1
}

function is_root_encrypted() {
  local device
  device="$1"
  if [ -z "$device" ]; then
      Echo "[CRITICAL] is_root_encrypted check: Invalid call: no device passed! Rebooting in 10s"
      sleep 10
      iguana_reboot_action "reboot"
  fi
  if echo "$device" | grep -q "^UUID="; then
      local uuid
      uuid=$(sed -E -e 's/^UUID="?//' -e 's/"$//' <<< "$device")
      device="/dev/disk/by-uuid/${uuid}"
  fi
  lsblk -o FSTYPE -n -l "$device" | grep -q "crypto_LUKS" && return 0
  return 1
}
