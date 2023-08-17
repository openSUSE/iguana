from storage import *
from commitHelper import *
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
        "kB": 2**10,
        "KB": 10**3,
        "MiB": 2**20,
        "MB": 10**6,
        "GiB": 2**30,
        "GB": 10**9,
        "TiB": 2**40,
        "TB": 10**12
    }
    return value * multipliers.get(unit)


# Setup

filename = sys.argv[1]

environment = Environment(True)

storage = Storage(environment)
storage.probe()
probed = storage.get_probed()
staging = storage.get_staging()


# Processes input, outputs a normalized list of devices and the initial gap
devList, initial_gap = inputParser.processInput(filename)
# print(devList, initial_gap)


# Begins partitioning the regions at the initial gap
startingPoint = convertToBytes(units(initial_gap)[0], units(initial_gap)[1])

for device_name, device_info in devList.items():

    # Creates a temporary device with the its name
    tempDevice = Partitionable.find_by_name(staging, device_name)
    tempDevice.remove_descendants()
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
            disk = Disk.find_by_name(probed, device_name)
            dev_size = disk.get_size() - convertToBytes(units(initial_gap)[0], units(initial_gap)[1])
            partSizeBytes = int(dev_size * (part_size / 100))
        # Creates a region based on the starting point, size, and block size.
        reg = Region(int(startingPoint / blockSizeBytes), int(partSizeBytes / blockSizeBytes), int(blockSizeBytes))

        # Creates the partition on the partition table
        part = gpt.create_partition(partition["partition_name"], reg, PartitionType_PRIMARY)
        try:
            part.set_id(int(partition["type"]))
        except Exception as e:
            part.set_id(ID_LINUX)

        startingPoint += partSizeBytes


# Prints all the information after partitioning

print(staging)     


print(devList)
# NOTE: Uncommenting the line below will cause the program
# to impact your current hardware.
# commit(storage)