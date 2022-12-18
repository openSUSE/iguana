#!/bin/bash

# Check we are in iguana container
if [ -z $iguana ]; then
    echo "Not running under iguana env"
    exit 1
fi

# Link reporting pipe
ln -s /iguana/progress /progress
ln -s /iguana/dc_progress /dc_progress

if ! declare -f Echo > /dev/null ; then
  Echo() {
    echo "$@"
    echo "$@" > /iguana/progress
  }
fi

if ! [ -s /etc/resolv.conf ] ; then
    Echo "No network, skipping saltboot"
    exit 0
fi

NEWROOT=${NEWROOT:-/sysroot}
export NEWROOT

# Parse saltboot entries from kernel command line
eval $(saltboot-args.py)

SALT_DEVICE=${SALT_DEVICE:-${root#block:}}

if [ -n "$KIWIDEBUG" ]; then
    cat <<EOF
# Salt minion modifiers
MASTER=$MASTER
MINION_ID_PREFIX=$MINION_ID_PREFIX
SALT_TIMEOUT=$SALT_TIMEOUT
SALT_DEVICE=$SALT_DEVICE

# Terminal naming modifiers
DISABLE_UNIQUE_SUFFIX=$DISABLE_UNIQUE_SUFFIX
DISABLE_HOSTNAME_ID=$DISABLE_HOSTNAME_ID
DISABLE_ID_PREFIX=$DISABLE_ID_PREFIX
USE_FQDN_MINION_ID=$USE_FQDN_MINION_ID

# Debugging
KIWIDEBUG=$KIWIDEBUG

# Salt autosign grains
SALT_AUTOSIGN_GRAINS=$SALT_AUTOSIGN_GRAINS

# Dracut generic
NEWROOT=$NEWROOT
EOF

    set -x
fi

systemIntegrity="unknown"

# Salt bundle vs salt minion support
if [ -f /usr/bin/venv-salt-call ] ; then
    INITRD_SALT_ETC=/etc/venv-salt-minion
    INITRD_SALT_LOG=/var/log/venv-salt-minion.log
    INITRD_SALT_CALL=venv-salt-call
    INITRD_SALT_MINION=venv-salt-minion
    INITRD_SALT_CACHE=/var/cache/venv-salt-minion
else
    INITRD_SALT_ETC=/etc/salt
    INITRD_SALT_LOG=/var/log/salt/minion
    INITRD_SALT_CALL=salt-call
    INITRD_SALT_MINION=salt-minion
    INITRD_SALT_CACHE=/var/cache/salt
fi

mkdir -p $NEWROOT
if [ -n "$SALT_DEVICE" ] && mount "$SALT_DEVICE" $NEWROOT ; then
    for sd in $NEWROOT/etc/venv-salt-minion $NEWROOT/venv-salt-minion $NEWROOT/etc/salt $NEWROOT/salt $NEWROOT ; do
        if [ -f $sd/minion_id ] ; then # find valid salt configuration
            mkdir -p /etc/salt
            cp -pr $sd/* /etc/salt
            # remove activation key grain copied from the disk with the rest of configuration
            rm -f /etc/salt/minion.d/kiwi_activation_key.conf
            # make sure we are not using venv config on normal minion
            rm -f /etc/salt/minion.d/00-venv.conf
            HAVE_MINION_ID=y
            break
        fi
    done
    umount $NEWROOT
fi

# Let Uyuni know we are in saltboot initrd
mkdir -p /etc/salt/minion.d
cat > /etc/salt/minion.d/grains-initrd.conf <<EOT
grains:
  saltboot_initrd: True
EOT

MACHINE_ID=`salt-call --local --out newline_values_only grains.get machine_id`

if [ -z "$MACHINE_ID" ]; then
    # Get machine id passed by iguana from the host. This happens on the first deployment
    MACHINE_ID=$(cat /iguana/machine-id)
fi

# store machine id in grains permanently so it does not change when we switch to
# initrd and back
# this is not needed for SALT but SUSE Manager seems to rely on it
cat > /etc/salt/minion.d/grains-machine_id.conf <<EOT
grains:
  machine_id: $MACHINE_ID
EOT

echo $MACHINE_ID > /etc/machine-id

curl -s http://salt/saltboot/defaults > /tmp/defaults
if [ \! -s /tmp/defaults ] && [ -n "$BOOTSERVERADD" ]; then
    curl -o /tmp/defaults "tftp://${BOOTSERVERADDR}/defaults"
fi

if [ -s /tmp/defaults ] ; then
    [ -z "$MINION_ID_PREFIX" ] && eval `grep ^MINION_ID_PREFIX= /tmp/defaults`
    [ -z "$DISABLE_ID_PREFIX" ] && eval `grep ^DISABLE_ID_PREFIX= /tmp/defaults`
    [ -z "$DISABLE_UNIQUE_SUFFIX" ] && eval `grep ^DISABLE_UNIQUE_SUFFIX= /tmp/defaults`
    if [ -z "$USE_FQDN_MINION_ID" -a -z "$DISABLE_HOSTNAME_ID" ] ; then
        eval `grep ^USE_FQDN_MINION_ID= /tmp/defaults`
        eval `grep ^DISABLE_HOSTNAME_ID= /tmp/defaults`
    fi
    [ -z "$DEFAULT_KERNEL_PARAMETERS" ] && eval `grep ^DEFAULT_KERNEL_PARAMETERS= /tmp/defaults`
    export DEFAULT_KERNEL_PARAMETERS
fi

if [ -n "$SALT_AUTOSIGN_GRAINS" ] ; then
    grains=
    agrains=
    readarray -d , -t grains_arr <<< "$SALT_AUTOSIGN_GRAINS"
    for g in "${grains_arr[@]}" ; do
        name=${g%%:*}
        agrains="$agrains    - $name"$'\n'
        if [[ $g == *:* ]]; then
            value=${g#*:}
            grains="$grains    $name: $value"$'\n'
        fi
    done
    cat > $INITRD_SALT_ETC/minion.d/autosign-grains-onetime.conf <<EOT
grains:
$grains

autosign_grains:
$agrains
EOT
fi

DIG_OPTIONS="+short"
if dig -h | grep -q '\[no\]cookie'; then
    DIG_OPTIONS="+nocookie +short"
fi

if [ -z "$HAVE_MINION_ID" ] ; then
    FQDN=`dig $DIG_OPTIONS -x "${IPADDR%/*}" | sed -e 's|;;.*||' -e 's|\.$||' `
    if [ -n "$USE_FQDN_MINION_ID" ]; then
        HOSTNAME="$FQDN"
    else
        HOSTNAME=${FQDN%%.*}
    fi

    if [ -n "$DISABLE_UNIQUE_SUFFIX" ] ; then
        UNIQUE_SUFFIX=
    else
        UNIQUE_SUFFIX="-${MACHINE_ID:0:4}"
    fi

    if [ -z "$HOSTNAME" ] || [ -n "$DISABLE_HOSTNAME_ID" ]; then
        SMBIOS_MANUFACTURER=`${INITRD_SALT_CALL} --local --out newline_values_only smbios.get system-manufacturer | tr -d -c 'A-Za-z0-9_-'`
        SMBIOS_PRODUCT=`${INITRD_SALT_CALL} --local --out newline_values_only smbios.get system-product-name | tr -d -c 'A-Za-z0-9_-'`
        SMBIOS_SERIAL=-`${INITRD_SALT_CALL} --local --out newline_values_only smbios.get system-serial-number | tr -d -c 'A-Za-z0-9_-'`

        if [ "x$SMBIOS_SERIAL" == "x-None" ] ; then
            SMBIOS_SERIAL=
        fi

        # MINION_ID_PREFIX can be specified on kernel cmdline
        if [ -n "$MINION_ID_PREFIX" ] && [ -z "$DISABLE_ID_PREFIX" ] ; then
            echo "$MINION_ID_PREFIX.$SMBIOS_MANUFACTURER-$SMBIOS_PRODUCT$SMBIOS_SERIAL$UNIQUE_SUFFIX" > $INITRD_SALT_ETC/minion_id
        else
            echo "$SMBIOS_MANUFACTURER-$SMBIOS_PRODUCT$SMBIOS_SERIAL$UNIQUE_SUFFIX" > $INITRD_SALT_ETC/minion_id
        fi
    else

        # MINION_ID_PREFIX can be specified on kernel cmdline
        if [ -n "$MINION_ID_PREFIX" ] && [ -z "$DISABLE_ID_PREFIX" ] ; then
            echo "$MINION_ID_PREFIX.$HOSTNAME$UNIQUE_SUFFIX" > $INITRD_SALT_ETC/minion_id
        else
            echo "$HOSTNAME$UNIQUE_SUFFIX" > $INITRD_SALT_ETC/minion_id
        fi
    fi

    cat > $INITRD_SALT_ETC/minion.d/grains-minion_id_prefix.conf <<EOT
grains:
  minion_id_prefix: $MINION_ID_PREFIX
EOT
fi

CUR_MASTER=`${INITRD_SALT_CALL} --local --out newline_values_only grains.get master`
# do we have master explicitly configured?
if [ -z "$CUR_MASTER" -o "salt" == "$CUR_MASTER" ] ; then
    # either we have MASTER set on commandline
    # or we try to resolve the 'salt' alias
    if [ -z "$MASTER" ] ; then
        MASTER=`dig $DIG_OPTIONS -t CNAME salt.$DNSDOMAIN | sed -e 's|;;.*||' -e 's|\.$||' `
    fi
fi

Echo "Using Salt master: ${MASTER:-$CUR_MASTER}"

if ! grep -q "^master: ${MASTER:-$CUR_MASTER}$" $INITRD_SALT_ETC/minion.d/susemanager.conf 2>/dev/null ; then
    cat > $INITRD_SALT_ETC/minion.d/susemanager.conf <<EOT
# This file was generated by saltboot
master: ${MASTER:-$CUR_MASTER}

server_id_use_crc: adler32
enable_legacy_startup_events: False
enable_fqdns_grains: False

start_event_grains:
  - machine_id
  - saltboot_initrd
  - susemanager

# Define SALT_RUNNING env variable for pkg modules
system-environment:
  modules:
    pkg:
      _:
        SALT_RUNNING: 1
EOT
    rm -f $INITRD_SALT_ETC/minion.d/master.conf
    rm -f $INITRD_SALT_ETC/minion.d/grains-startup-event.conf
fi

if [ -z "$kiwidebug" ];then
    salt-minion -d
else
    salt-minion -d --log-file-level all
fi

sleep 1

SALT_PID=`cat /var/run/salt-minion.pid`

if [ -z "$SALT_PID" ] ; then
    Echo "Salt Minion did not start. Stopping saltboot"
    sleep 10
    exit 1
fi

MINION_ID="`${INITRD_SALT_CALL} --local --out newline_values_only grains.get id`"
MINION_FINGERPRINT="`${INITRD_SALT_CALL} --local --out newline_values_only key.finger`"
while [ -z "$MINION_FINGERPRINT" ] ; do
  Echo "Waiting for salt key..."
  sleep 1
  MINION_FINGERPRINT="`${INITRD_SALT_CALL} --local --out newline_values_only key.finger`"
done

echo "SALT Minion ID:"
echo "$MINION_ID"
echo
echo "SALT Minion key fingerprint:"
echo "$MINION_FINGERPRINT"

# split line into two to fit to screen. Need triple \ to properly pass through
Echo "Terminal ID: $MINION_ID\\\nFingerprint: $MINION_FINGERPRINT"

SALT_TIMEOUT=${SALT_TIMEOUT:-60}
num=0
while kill -0 "$SALT_PID" >/dev/null 2>&1; do
  sleep 1
  num=$(( num + 1 ))
  if [ "$num" == "$SALT_TIMEOUT" -a -n "$root" -a ! -f '/var/cache/salt/minion/extmods/states/saltboot.py' ] && \
     ! grep 'The Salt Master has cached the public key for this node' /var/log/salt/minion && \
     mount ${root#block:} $NEWROOT && [ -f $NEWROOT/etc/ImageVersion ]; then
    systemIntegrity=fine
    imageName=`cat $NEWROOT/etc/ImageVersion`
    Echo "SUSE Manager server does not respond, trying local boot to\\\n$imageName"
    sleep 5
    kill "$SALT_PID"
    sleep 1
  fi
done

if [ -f /salt_config ] ; then
  # TODO: remove, only for debugging
  cp /salt_config /iguana/salt_config
  . /salt_config
fi

if [ "$systemIntegrity" = "unknown" ] ; then
    Echo "Saltboot did not create valid configuration"
    sleep 10
    exit 1
fi

cat > /etc/salt/minion.d/grains-initrd.conf <<EOT
grains:
  saltboot_initrd: False
EOT

rm -f /etc/salt/minion.d/autosign-grains-onetime.conf

if [ -e $NEWROOT/etc/venv-salt-minion ] ; then
    IMAGE_SALT_ETC=/etc/venv-salt-minion
else
    IMAGE_SALT_ETC=/etc/salt
fi

# copy salt and other config to deployed system
echo $MACHINE_ID > $NEWROOT/etc/machine-id
cp -pr $INITRD_SALT_ETC/* $NEWROOT/$IMAGE_SALT_ETC

# make sure we are not using venv config on normal minion
rm -f $NEWROOT/etc/salt/minion.d/00-venv.conf

# preserve salt log files
mkdir -p $NEWROOT/var/log/salt
num=1
while [ -e $NEWROOT/var/log/salt/saltboot_$num ] ; do
  num=$(( num + 1 ))
done
cp -pr $INITRD_SALT_LOG $NEWROOT/var/log/saltboot/saltboot_$num

# Create iguana output
echo "$imageDevice $NEWROOT" > /iguana/mountlist

[ -n "$kernelAction" ] && echo "$kernelAction" > /iguana/kernelAction

umount -a
sync