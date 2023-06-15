# dracut-iguana
## dracut module to include container runtime in initrd

_part of [Iguana installer research project](https://github.com/openSUSE/iguana)._

Unstable software, use at your own risk.

## How to test

1) have an existing VM. Do not use your own machine!
2) install `dracut-iguana` package from [OBS](https://build.opensuse.org/package/show/systemsmanagement:Iguana:Devel/dracut-iguana)
3) call `dracut --verbose --force --no-hostonly --no-hostonly-cmdline --no-hostonly-default-device --no-hostonly-i18n --reproducible iguana-initrd $kernel_version`

  This will generate `iguana-initrd` file in your current directory.

4) Use new VM and boot directly to kernel and `iguana-initrd` created in previous steps.
5) To test with Agama, use `rd.iguana.control_url=https://raw.githubusercontent.com/openSUSE/iguana/main/examples/agama.yaml rd.iguana.debug=1` as kernel command line

### Submit to OBS

For Devel project OBS workflow automatically trigger package rebuild from git sources after accepting pull request. Per pull requests builds are also available.

Stable release procedure is WIP.
