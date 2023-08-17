# Partitioning Container Example for Iguana

## What does it do?

The container will partition the hard disk into a user specified number of partitions. The user can define the specific size of each partition and what type of partition it is _(eg. EFI, swap, root etc...)_. Users also have the option of specifying each partition's type through UUID (https://uapi-group.org/specifications/specs/discoverable_partitions_specification/) as well as its mount point. 

## Inputting Configurations
All of the configuration will be passed through a JSON file with the following format:
```json
    {
        "general": {
            "label": "gpt",
            "initial_gap": "2MB"
        },
        "devices": {
            "device_name": {
                "blkSize": "512B",
                "partitions": [{
                        "size": "512MiB",
                        "type": "efi"
                    },{
                        "size": "2GiB",
                        "type": "swap"   
                    },{
                        "size": "16GiB",
                        "type": "linux",
                        "optional": {
                            "UUID": "44479540-f297-41b2-9af7-d131d5f0458a",
                            "mountPoint": "/"
                        }    
                    }
                ]
            }
        }
    }
```

### Explanation:
Accepted units for sizes: B, KB, kB, MB, MiB, GB, GiB, TB, TiB
* **general**
    :(Optional) General settings, if not specified then **label** and **initial_gap** will be set to their default values.
    * **label**
    : (Optional, default value = "gpt") Partition table type, currently only supports the option "gpt".
    * **initial_gap**
    : (Optional, default value = "1MB") The amount of initial gap to leave at the beginning of storage.
* **devices**
: Contains the devices that users want to be partitioned
    * **device_name**
    : Name of each device, e.g. "/dev/sda".
        * **blkSize** 
        : (Optional, default value = "512B") Block size of the device.
        * **partitions**
        : List of partitions for the device.
            * **size**
            : Size of the partition.
            * **type**
            : (Optional, default value = "linux") Partition type, options are: linux, swap, efi, and boot. This will take priority over the optional settings below.
            * **optional**
            : (Optional) Configurable settings for each partition when the user wishes to modify them.
                * **UUID**
                : (Optional) Partition type UUID, taken from https://uapi-group.org/specifications/specs/discoverable_partitions_specification/, currently does not support the verity UUIDs. Note that this takes priority over the **mountPoint** option below.
                * **mountPoint**
                : (Optional) Specifies the mount point of the partition. However, if a valid **UUID** is specified, then this value is ignored and the mount point is set accordingly to the UUID.

### Passing Input File
Users can either pass the path of the JSON file, or they can pass a URL to the JSON file online. There are three ways to pass the path/URL to the program, and it is checked in the following order/priority:
1. Passed along the kernel command line as *rd.iguana.partitioning* (e.g. rd.iguana.partitioning=.../input.json).
2. Passed as environmental variable called PARTITIONING_URL in the .yaml workflow file:
```yaml
env:
        PARTITIONING_URL: /partitioning/input.json
```
3. If neither the kernel command line and the environment variable contains the path/URL, an interactive shell will launch and prompt the user to manually enter the path/URL.
