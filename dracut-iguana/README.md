# dracut-iguana
## dracut module to include container runtime in initrd

_part of [Iguana installer research project](https://github.com/openSUSE/iguana)._

Unstable software, use at your own risk.

## Configuration options:

Iguana dracut modules is using `rd.iguana` namespace and following options are recognized.

### rd.iguana.control_url

URL or local path to the [Iguana workflow file](https://github.com/openSUSE/iguana/blob/main/iguana-workflow/Workflow.md). Iguana module will try to download file from provided location and then pass it to the iguana-workflow.

### rd.iguana.containers

Provide container image directly instead of using workflow file. Registry must be included in the URL. More containers can be specified, delimited by `,`.

### rd.iguana.debug

Starts iguana debug mode:

* Enables verbose logging for iguana dracut module.
* Do not remove containers after their run
* Instead of rebooting on failure drop to the emergency shell
* Starts debug console on tty2

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
