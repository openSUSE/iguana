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

function guess_root_mount() {
  # look for first disk partitition with known root PARTUUIDs
  # see https://uapi-group.org/specifications/specs/discoverable_partitions_specification/
  # Supported currently are:
  #   AArch64:      b921b045-1df0-41c3-af44-4c6f280d3fae
  #                 SD_GPT_ROOT_ARM64
  #   amd64/x86_64: 4f68bce3-e8cd-4db1-96e7-fbcaf984b709
  #                 SD_GPT_ROOT_X86_64
  
}