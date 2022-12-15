# Iguana workflow

_part of [Iguana installer research project](https://github.com/openSUSE/iguana)._

Implementation of iguana workflow parser. Iguana workflow is a YAML document loosely based on GitHub workflow YAML designed to specify order and dependencies between different containers. See [examples](examples) for example usage.

## Usage

### Building

To build the tool you will need rust 2021 edition (v1.56 and newer) and related cargo binary.

```
git clone https://github.com/openSUSE/iguana
cd iguana/iguana-workflow
cargo build
```

To build release target use
```
cargo build --release
```

### Submit to OBS

[osc](https://openbuildservice.org/help/manuals/obs-user-guide/art.obs.bg.html#sec.obsbg.req) tool is required for submitting to the [OBS project](https://build.opensuse.org/package/show/home:oholecek:iguana/iguana-workflow)

Project is configured to follow [iguana-workflow GitHub repo](https://github.com/openSUSE/iguana). For contributions please create pull requests.

Follow this guide if you want to create your own testing package.

1) checkout package to your project space

    `osc bco home:oholecek iguana-workflow`

2) in checked out project, edit `_service` file and change `url` parameter to follow your git repository

3) from withing checked out project update service file and update cargo services

    `osc service ra`

4) remove old source tarballs
5) add new and remove old files

    `osc ar`

6) submit changes to your package

    `osc ci`

If you are maintainer updating package in OBS, skip step 2)



## Testing

Tool is designed to be run as part of the iguana initrd, however for testing it can be run on normal system as well. VM system is strongly recommended as iguana-workflow runs containers in privileged mode by default.

Log level can be set either by using `--log-level` option or using `RUST_LOG=debug` environmental variable.

Use `--dry-run` together with `--log-level` to see what iguana-workflow would do based on provided workflow yaml file.

    cargo run -- --dry-run --log-level=debug workflow_file

See `iguana-workflow --help` for complete argument overview.

## Workflow syntax

See [workflow syntax overview](Workflow.md) for details about workflow file.
