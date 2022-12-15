# Iguana research project

## What is Iguana about

Universal Linux distributions, such as SLES or openSUSE, have vastly different usages and are running on very different types of hardware. Different usages and hardwares have different installation methods, deployments, configurations. With Iguana we are trying to create ambitious universal initial ramdisk which actual functionality is provided in containers.

Iguana itself strives to contain as little logic as possible just to prepare environment to run containers and provide simple orchestration of them.

Iguana is split in multiple packages:

- Dracut module [dracut-iguana](https://github.com/openSUSE/iguana/tree/main/dracut-iguana)
- Iguana orchestrator [iguana-workflow](https://github.com/openSUSE/iguana/tree/main/iguana-workflow)
- This overall project

Packages are available for openSUSE systems at [OBS](https://build.opensuse.org):

- [dracut-iguana](https://build.opensuse.org/package/show/home:oholecek:iguana/dracut-iguana)
- [iguana-workflow](https://build.opensuse.org/package/show/home:oholecek:iguana/iguana-workflow)
- [iguana initrd](https://build.opensuse.org/package/show/home:oholecek:iguana/iguana)

## Testing iguana

VM machine is recommended for testing because Iguana is in early stages of development and unstable.
`iguana` package can be installed on regular system as it does no changes to the system itself except to provide kernel and initrd file.
After installing `iguana` package, there will be two files:

- /usr/share/iguana/iguana-initrd
- /usr/share/iguana/vmlinuz-<version>-default

These can be used for direct kernel boot of VM or for PXE booting. This will start iguana initrd on boot of the VM.

## Configuring Iguana

Iguana understands three kernel command line options which are used for influencing Iguana run:

- rd.iguana.containers <container_image>, ...
    Use to manually set what container(s) to run. This will make Iguana to pull and start containers.
- rd.iguana.control_url
    Use to point Iguana to [iguana workflow file](https://github.com/openSUSE/iguana/blob/main/iguana-workflow/Workflow.md) on some URL. For example running containerized d-installer use `rd.iguana.control_url=https://raw.githubusercontent.com/openSUSE/iguana/main/iguana-workflow/examples/d-installer.yaml`
- rd.iguana.debug
    Set to 1 to enable verbose logging


## Writing iguana aware containers

For Iguana to work correctly and enable correct boot after containers run is finished there are couple assumptions and expectations.
Every container started by iguana is running in **privileged** mode with host networking. They will have `/iguana` volume bind mounted to provide sharing configuration and results between containers and host.

### Expectations and provides

- Machine ID is provided in `/iguana/machine-id` file.
- Iguana **expects** `/iguana/mountlist` file after last container is finished. Each line contains device and mountpoint and Iguana will mount all mounts in order specified.

```
    device mountpoint
    device2 mountpoint2
    ...
```

- Iguana reads `/iguana/kernelAction` file if exists and if it has value `kexec` then iguana will call `kexec -e` before finishing.

## Contributing
