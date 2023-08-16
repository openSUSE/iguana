import json
import translateUUID
from storage import *

def processInput(fileName):

    # Loads JSON file into a dictionary

    with open(fileName, 'r') as f:
        input_dict = json.load(f)

    # Processes the general information
    # Such as partition table type (only supports GPT right now)
    # And the initial gap

    # If not specified then the initial gap defaults to 1 MB
    general = input_dict.get("general", {})

    label = general.get("label", "gpt")
    initial_gap = general.get("initial_gap", "1MB")
   
    deviceList = {}
    
    for device_name, device_content in input_dict["devices"].items():
        temp_device = {
            "label": label,
            "blockSize": device_content.get("blockSize", "512B"),
            "partitions": []
        }

        # For when the user wants to partition a disk into multiple equal partitions
        # Not functioning

        # eqPart = device_content.get("equalPartitions", "")
        # if eqPart:
        #     for i in range(eqPart.get("number", 1)):
        #         partition_name = "{}{}".format(device_name,i+1)
        #         optionalSettings = eqPart.get("optional", {})
        #         partitionType = eqPart.get("type", "linux")
        #         mountPoint = None
        #         if partitionType == "linux":
        #             uuid = optionalSettings.get("UUID", "").lower()
        #             if uuid:
        #                 mountPoint = translateUUID.convertUUID(uuid)
        #             elif optionalSettings.get("mountPoint", ""):
        #                 mountPoint = optionalSettings.get("mountPoint", "")                   

        #         elif partitionType == "boot":
        #             mountPoint = "/boot/"
        #         elif partitionType == "efi":
        #             mountPoint = "/efi/"
        #         elif partitionType != "swap":
        #             raise Exception()

        for index, partition in enumerate(device_content["partitions"]):
            # Names the partition
            partition_name = "{}{}".format(device_name,index+1)


            # Retrieves any optional information: specifies UUID or mount point
            optionalSettings = partition.get("optional", {})

            # Gets the partition type, defaults to linux otherwise
            partitionType = partition.get("type", "linux")

            # Default mount point if unspecified
            mountPoint = None




            if partitionType == "linux":
                # Gets the UUID if specified
                partID = ID_LINUX
                uuid = optionalSettings.get("UUID", "").lower()
                if uuid:
                    # If invalid UUID, use the specified mountpoint instead
                    try:
                        tempID = translateUUID.convertUUID(uuid)[1]
                        # Since type was specified to be linux already, the UUID cannot be that of
                        # a swap, boot or efi partition.
                        if tempID == ID_SWAP or tempID == ID_BIOS_BOOT or tempID == ID_ESP:
                            print("type is defined as 'linux', but %s is not a linux partition UUID" %uuid )
                        else:
                            partID = tempID
                            mountPoint = translateUUID.convertUUID(uuid)[0]
                        
                    except:
                        print("invalid uuid inputted: "+uuid)
                        mountPoint = optionalSettings.get("mountPoint", "")     
                elif optionalSettings.get("mountPoint", ""):
                    # If no UUID specified also use the specified mountpoint instead
                    mountPoint = optionalSettings.get("mountPoint", "")                   

            # Special partition type cases
            elif partitionType == "boot":
                mountPoint = "/boot/"
                partID = ID_BIOS_BOOT
            elif partitionType == "efi":
                mountPoint = "/efi/"
                partID = ID_ESP
            elif partitionType == "swap":
                partID = ID_SWAP
            else:
                print("invalid type specified: %s" %partitionType)
                raise Exception()

            # Adds a normalized partition info to the device
            temp_device["partitions"].append({
                "partition_name": partition_name,
                "type": partID,
                "mountPoint": mountPoint,
                "size": partition["size"],
            })
        # Adds a normalized device info to the list of devices
        deviceList[device_name] = temp_device

    # Returns the normalized device list and the initial gap
    return deviceList, initial_gap


