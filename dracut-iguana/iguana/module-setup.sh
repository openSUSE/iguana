#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    echo network
    return 0
}

IPTABLES_MODULES="ip6_tables ip6table_nat ip_tables iptable_filter iptable_nat nf_conntrack nf_defrag_ipv4 nf_defrag_ipv6 nf_nat xt_MASQUERADE xt_comment xt_conntrack"

# called by dracut
installkernel() {
    # for raid and crypt support, the kernel module is needed unconditionally, even in hostonly mode
    hostonly='' instmods br_netfilter $IPTABLES_MODULES dm_crypt =crypto
}

get_pkg_deps() {
    deps=$(rpm -q --requires "$@" | while read req ver; do
        p=$(rpm -q --whatprovides "$req")
        [ $? -eq 0 ] && echo $p
    done | sort -u)
    echo "$@ $deps"
}

container_reqs() {
    packages=$(get_pkg_deps podman util-linux procps podman-cni-config iptables)
    for p in $packages; do
      rpm -ql $p | grep -E -v "(/man/)|(/bash-completion/)|(/doc/)" | sed -e 's/\n/ /g'
    done | sort -u
}


# called by dracut
install() {
    # container requires
    inst_multiple -o $(container_reqs)

    inst_multiple grep ldconfig date dbus-uuidgen systemd-machine-id-setup seq \
                  curl head sync tail kexec

    # needed for partition discovery
    inst_multiple lsblk jq

    # standard iguana
    inst_single iguana-workflow

    #TODO
    #install SUSE CA as a trust anchor


    inst_hook cmdline 91 "$moddir/iguana-root.sh"
    inst_hook pre-mount 99 "$moddir/iguana.sh"
    inst_simple "$moddir/iguana-lib.sh" "/lib/dracut-iguana-lib.sh"
    inst_hook initqueue/timeout 99 "$moddir/iguana-timeout.sh"

    #TODO: make network requirement optional, e.g. for ISO use
    echo "rd.neednet=1 rd.auto" > "${initdir}/etc/cmdline.d/50iguana.conf"
}

