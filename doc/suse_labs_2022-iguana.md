---
title:  'Iguana - installer initrd with containers'
author:
- Ondrej Holecek <oholecek@suse.com>
...

# Iguana - installer initrd with containers

## Introduction

General purpose linux system such as ALP have vastly different target users and their use cases. This affect installation methods as well. In SLE world, our installer can do many things, but still not enough to cover everything and many times our users use specially build initrds for example for image based deployments.

With ALP we want to try something different in how our systems are prepared. In line with ALP concepts of small core and containers workloads we come up with Iguana - smallish initrd where actual functionality is provided by installation containers.

## Concept

Creating anything universal is arguably an ambition task. Our approach to tackle this goal is to focus on two main topics:

- Minimal and stable core
- Extreme expandability

Minimal core in a functionality sense, not necessarily in binary size as currently used go based container runtime is rather large. The goal in this topic is to be able to have initrd which could be signed and used by our users and us for anything installation and deployment related. Once stable version of iguana is released, initrd itself should not require almost any further updates.

Expandability is essential to cover all expected usages and more. With Iguana we are trying to use installation containers to provide desired functionality and also using signed containers some level of supply chain security. 

## Components

Iguana consists of components:

- dracut module
- iguana workflow and workflow module
- iguana glue
- installation containers

### Iguana dracut module

Iguana is using dracut for preparing initrd, iguana provides its own dracut module. This module uses standard dracut mechanism to ensure container runtime and its dependencies are installed in the initrd.

This is also entry point for whole iguana, starts workflow module and handles mounting of new root partition before switching root out of initrd.

### Workflow module

Iguana itself contains very limited logic and almost nothing related to actual system installation or deployment or what is needed to do. All of this functionality is taken from [installation containers](#installation-containers). For orchestrating these containers there is Workflow module.

This module parses workflow file which describes what container or containers to pull and in what order they are supposed to run and other details.

Workflow file is YAML file containing [iguana workflow](#iguana-workflow).

### Iguana workflow

Describing what, how and when various containers are to be run we use Iguana workflow. Workflow syntax is loosely based on GitHub Workflow syntax, but is still in active development so it is inherently unstable for now.

Example of workflow file for D-Installer
```yaml
name: D-Installer workflow

jobs:
  dinstaller:
    container:
      image: registry.opensuse.org/yast/head/containers/containers_tumbleweed/opensuse/dinstaller-web
      volumes:
        - dbus_run:/var/run/dbus
    services:
      backend:
        image: registry.opensuse.org/yast/head/containers/containers_tumbleweed/opensuse/dinstaller-backend
        volumes:
          - dbus_run:/var/run/dbus
```

### Iguana glue

To build actual usable initrd for user consumption, there is glue component. It exists primarily for packaging purposes so we can create *iguana* package containing ready for use initrd and related kernel. GitHub project of this component also acts as a central place for documentation and examples.

### Installation containers

The most important part, which is also not part of Iguana, is installation container. Installation container is responsible for the actual actions, be it installation of new system, deploying pre-build images or rescue system.

OCI and docker containers are supported.

Installation container(s) together with iguana workflow file creates iguana installation bundle.

Difference between general purpose containers and installation containers is in what container can expect for configuration and what should be end result of container run.

Because Iguana is expected to perform various changes on host system, installation containers are always started in privileged mode with shared networking with host system. From this it is clear that in Iguana context we do not use containers for isolation of workloads, rather look at them solely from distribution mechanism point of view.


## Iguana run

On Iguana start, it needs to locate workflow file. For now we look for `rd.iguana.control_url` kernel command line option or if that is missing for bundled `control.yaml` file.

Once workflow file is downloaded and parsed, Iguana will start executing containers specified in workflow. Job containers are run in interactive mode and Iguana waits until they are finished. Service containers are run as detached and parallel to the job containers.

Iguana provides shared volume `/iguana` to each container started. This shared volume is used for data sharing between containers and host and is used also for results storage.

Each Iguana installation container is started with environmental variable `IGUANA` set to true. On top of that, workflow file can provide additional environmental variable.

Iguana does not care about interim results between various container runs, but after all containers specified in the workflow are finished, Iguana expects `/iguana/mountlist` file. This file must contain what devices should be mounted and where. New root filesystem must be included in the list. Dracut will then switch root to the new root filesystem.

In case kernel versions differ between Iguana kernel and installed kernel, Iguana will try to kexec to new kernel or reboot. What should Iguana do in this case can also be influenced by containers by setting preferred action in `/iguana/kernelAction` file.

## Limitations and drawbacks

Iguana is in very early development and thus many things can change abruptly.

We need to carefully monitor memory usage of the workflow as we store all data in RAM. Individual container images are deleted after container finished its run, but installation containers should take extra considerations about their size.

As the design is not yet finalized, security measures are not yet included, such as validation of workflow file downloads and container images verification enforcement. This is however must have for initial release.

Size of the initrd itself is as writing this text quite large because underlying container runtime is based on `podman` binary. Podman go binary is large (approximately 40MiB) and there are advantages to switch to different mechanisms, for example using `skopeo` for container image management and `runc` or other mechanisms to run containers can help with size benefits.

## Call to action

Iguana cannot and will not do much on its own. It needs installation containers to expand its capabilities. Currently there is only `D-Installer` and `Saltboot` installation containers to test drive the concept. This is the time for other interested parties to come and talk to us so we can help with preparing more containers and adapt Iguana to allow them if needed.

## Resources

- [Iguana GitHub project](https://github.com/aaannz/iguana)
- [Workflow syntax description](https://github.com/aaannz/iguana-workflow/blob/main/Workflow.md)
- [Uyuni Saltboot container and workflow](https://github.com/aaannz/iguana/pull/1/files)