#!/bin/bash

# called by dracut
check() {
    require_binaries iguana-workflow || return 1

    #do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo bash network network-manager
    return 0
}

IPTABLES_MODULES="ip6_tables ip6table_nat ip_tables iptable_filter iptable_nat nf_conntrack nf_defrag_ipv4 nf_defrag_ipv6 nf_nat xt_MASQUERADE xt_comment xt_conntrack"

# called by dracut
installkernel() {
    hostonly='' instmods br_netfilter $IPTABLES_MODULES
}

get_pkg_deps() {
    deps=$(rpm -q --requires "$@" | while read req _; do
        p=$(rpm -q --whatprovides "$req")
        [ $? -eq 0 ] && echo $p
    done | sort -u)
    echo "$* $deps"
}

container_reqs() {
    packages=$(get_pkg_deps podman libcontainers-common util-linux procps podman-cni-config iptables)
    for p in $packages; do
      rpm -ql $p | grep -E -v "(contains no files)|(/man/)|(/bash-completion/)|(/doc/)" | sed -e 's/\n/ /g'
    done | sort -u
}


# called by dracut
install() {
    # container requires
    # shellcheck disable=SC2046
    inst_multiple -o $(container_reqs)

    inst_multiple grep ldconfig date systemd-machine-id-setup \
                  curl sync tail kexec

    # needed for partition discovery
    inst_multiple lsblk jq

    # standard iguana
    inst iguana-workflow

    #TODO
    #install SUSE CA as a trust anchor

    # shellcheck disable=SC2154
    inst_hook cmdline 91 "${moddir}/iguana-root.sh"
    inst_hook pre-mount 99 "${moddir}/iguana.sh"
    inst_simple "${moddir}/iguana-lib.sh" "/lib/dracut-iguana-lib.sh"
    inst_hook initqueue/timeout 99 "${moddir}/iguana-timeout.sh"

    #TODO: make network requirement optional, e.g. for ISO use
    # shellcheck disable=SC2154
    echo "rd.neednet=1 rd.auto" > "${initdir}/etc/cmdline.d/50iguana.conf"
}

