# Iguana generation makefile

target_dir := ${DESTDIR}/usr/share/iguana
build_dir := out

kernel_filepath := $(shell find /boot -name 'vmlinuz*' | sort -r -V | head -1)

file_split := $(subst -, ,${kernel_filepath})
kernel_prefix := $(word 1, ${file_split})

kernel_file := $(notdir ${kernel_filepath})
kernel_version := $(subst ${kernel_prefix}-,,${kernel_filepath})

.PHONY: build
build: ${build_dir} ${target_dir}/iguana-initrd ${target_dir}/${kernel_file}
	@echo "All done"

${build_dir}:
	@mkdir ${build_dir}

${target_dir}/iguana-initrd:
	@echo "Generating initrd"
	dracut --force --no-hostonly --no-hostonly-cmdline \
	       --no-hostonly-default-device --no-hostonly-i18n \
		   --reproducible ${build_dir}/iguana-initrd ${kernel_version}

${target_dir}/${kernel_file}:
	@echo "Collecting kernel used for initrd build"
	@cp ${kernel_filepath} ${build_dir}/${kernel_file}

install:
	install -d -m 755 ${target_dir}
	for f in ${build_dir}/*; do \
		install -m 644 $$f ${target_dir} ;\
	done

all: build install

clean:
	rm -r ${build_dir}
