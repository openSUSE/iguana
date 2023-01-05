#!/bin/bash

if ! declare -f Echo > /dev/null ; then
  Echo() {
    echo -e "$@"
    echo -e "$@" > /iguana/progress
  }
fi

function iguana_reboot_action() {
  # Always do reboot, only in case of kexec action try kexec first
  # Kexec must be already prepared
  if [ "kexec" == "$1"]; then
    umount -a
    sync
    kexec -e
    Echo "Kexec failed, trying reboot"
    sleep 5
  fi
  reboot -f -d -n
}

function guess_root_mount(newroot) {
  # look for first disk partitition with known root PARTUUIDs
  # see https://uapi-group.org/specifications/specs/discoverable_partitions_specification/
  # Supported currently are:
  #   AArch64:      b921b045-1df0-41c3-af44-4c6f280d3fae
  #                 SD_GPT_ROOT_ARM64
  #   amd64/x86_64: 4f68bce3-e8cd-4db1-96e7-fbcaf984b709
  #                 SD_GPT_ROOT_X86_64
  local supported_uuids = "b921b045-1df0-41c3-af44-4c6f280d3fae SD_GPT_ROOT_ARM64 4f68bce3-e8cd-4db1-96e7-fbcaf984b709 SD_GPT_ROOT_X86_64"
  local found_root=`lsblk -o PARTUUID,FSTYPE -n -l -J | jq '.blockdevices | map(select(.partuuid != null)) | .[0].partuuid'`

  if echo "$supported_uuids" | grep -q "$found_root"; then
    # First found partition with UUID is known UUID for root partition.
    echo "UUID=$found_root $newroot" > /iguana/mountlist
    return 0
  fi
  return 1
}

function is_root_encrypted(device) {
  local parsed_device="$device"
  if echo "$device" | grep -q "^UUID="; then
      parsed_device="/dev/disk/by-partuuid/${device#UUID=}"
  fi
  local partFS=`lsblk -o FSTYPE -n -l $parsed_device`
  [ $partFS == "crypto_LUKS" ] && return 0
  return 1
}