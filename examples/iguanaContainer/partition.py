from storage import *
import json
import platform
import inputParser
import re
import sys


# This function is from yomi, can be found at https://github.com/openSUSE/yomi/blob/f3f4ac60852fa79665e77ede90960860ddd684fb/salt/_utils/disk.py#L31
def units(value, default="MB"):
    """
    Split a value expressed (optionally) with units.

    Returns the tuple (value, unit)
    """
    valid_units = (
        "B",
        "KB",
        "kB",
        "MB",
        "MiB",
        "GB",
        "GiB",
        "TB",
        "TiB",
        "%",
    )
    match = re.search(r"^([\d.]+)(\D*)$", str(value))
    if match:
        value, unit = match.groups()
        unit = unit if unit else default
        if unit in valid_units:
            return float(value), unit
        else:
            raise Exception("{} not recognized as a valid unit".format(unit))
    raise Exception("{} cannot be parsed".format(value))

def convertToBytes(value, unit):
    multipliers = {
        "B": 1,
        "kB": 10**3,
        "KB": 2**10,
        "MiB": 10**6,
        "MB": 2**20,
        "GiB": 10**9,
        "GB": 2**30,
        "TiB": 10**12,
        "TB": 2**40
    }
    return value * multipliers.get(unit)


# Setup

filename = sys.argv[1]

environment = Environment(True)

storage = Storage(environment)

staging = storage.get_staging()


# Processes input, outputs a normalized list of devices and the initial gap
devList, initial_gap = inputParser.processInput('input.json')
# print(devList, initial_gap)


# Begins partitioning the regions at the initial gap
startingPoint = convertToBytes(units(initial_gap)[0], units(initial_gap)[1])


for device_name, device_info in devList.items():

    # Creates a temporary device with the its name
    tempDevice = Disk.create(staging, device_name)

    # For now it automatically creates a GPT partition table
    # Hope to supporst MSDOS in the future
    gpt = tempDevice.create_partition_table(PtType_GPT)

    # Separates the block size and block size unit
    block_size, block_unit = units(device_info.get("blockSize", "512B"))
    
    # Converts the block size into bytes if not already in bytes
    # Since libstorage uses bytes for its Regions
    blockSizeBytes = convertToBytes(block_size, block_unit)

    for partition in device_info.get("partitions", []):
        # Separates the partition size value and its unit
        part_size, part_unit =  units(partition["size"])
        if part_unit != "%":
            partSizeBytes = convertToBytes(part_size, part_unit)
        else:
            print("Does not support percentage unit currently")

        # Code breaks if probing occurs, but using the percentage unit requires probing
        # else:
        #     storage.probe()
        #     probed = storage.get_probed()
        #     disks = probed.get_all_disks()
        #     for d in disks:
        #         print(d.get_name())

        # Creates a region based on the starting point, size, and block size.
        reg = Region(int(startingPoint / blockSizeBytes), int(partSizeBytes / blockSizeBytes), int(blockSizeBytes))

        # Creates the partition on the partition table
        gpt.create_partition(partition["partition_name"], reg, PartitionType_PRIMARY)

        startingPoint += partSizeBytes


# Prints all the information after partitioning

print(staging)

# Prints the partitions on the last device in the list
print("partitions on gpt:")
for partition in gpt.get_partitions():
    print("  %s %s" % (partition, partition.get_number()))
print()

# Prints info about the /dev/sda1 device partition specifically
tmp1 = BlkDevice.find_by_name(staging, "/dev/sda1")
print(tmp1)        