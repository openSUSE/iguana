FROM opensuse/tumbleweed

RUN zypper --non-interactive --gpg-auto-import-keys install --auto-agree-with-licenses --no-recommends \
	salt-minion bind-utils curl dmidecode parted cryptsetup e2fsprogs device-mapper kiwi-tools util-linux-systemd mdadm \
	dosfstools xfsprogs btrfsprogs kexec-tools

COPY saltboot.sh saltboot-args.py /usr/bin/
RUN chmod +x /usr/bin/saltboot.sh /usr/bin/saltboot-args.py

ENTRYPOINT ["/usr/bin/saltboot.sh"]
