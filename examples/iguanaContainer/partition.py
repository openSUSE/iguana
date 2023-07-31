from storage import *
import json
import platform
import inputParser
import re


# This function is from yomi, can be found at https://github.com/openSUSE/yomi/blob/f3f4ac60852fa79665e77ede90960860ddd684fb/salt/_utils/disk.py#L31
def units(value, default="MB"):
    """
    Split a value expressed (optionally) with units.

    Returns the tuple (value, unit)
    """
    valid_units = (
        "B",
        "KB"
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
        "kB": 10 ** 3,
        "KB": 2**10,
        "MiB": 10 ** 6,
        "MB": 2**20,
        "GiB": 10**9,
        "GB": 2**30,
        "TiB": 10**12,
        "TB": 2**40
    }
    return value * multipliers.get(unit)

environment = Environment(True)

storage = Storage(environment)

staging = storage.get_staging()



with open('input.json', 'r') as f:
    input_dict = json.load(f)


print(platform.uname().machine)

devList, initial_gap = inputParser.processInput('input.json')
# print(devList, initial_gap)

# storage.probe()
# probed = storage.get_probed()

# probed = storage.get_probed()
# print("PROBE1")
# print(probed)

# startingPoint = convertToBytes(units(initial_gap)[0], units(initial_gap)[1])

# for device, device_info in devList.items():
#     tempDevice = Disk.create(staging, device)
#     gpt = tempDevice.create_partition_table(PtType_GPT)

#     block_size, block_unit = units(device_info.get("blockSize", "512B"))
#     blockSizeBytes = convertToBytes(block_size, block_unit)

#     for partition in device_info.get("partitions", []):
#         part_size, part_unit =  units(partition["size"])
#         partSizeBytes = convertToBytes(part_size, part_unit)
#         gpt.create_partition(partition["partition_name"], Region(int(startingPoint / blockSizeBytes), int(partSizeBytes / blockSizeBytes), int(blockSizeBytes)), PartitionType_PRIMARY)

#         startingPoint += partSizeBytes


# print(probed)


# print("partitions on gpt:")
# for partition in gpt.get_partitions():
#     print("  %s %s" % (partition, partition.get_number()))
# print()

tmp1 = BlkDevice.find_by_name(staging, "/dev/sda1")
print(tmp1)        