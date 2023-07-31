import json
import translateUUID

def processInput(fileName):
    with open(fileName, 'r') as f:
        input_dict = json.load(f)


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
                uuid = optionalSettings.get("UUID", "").lower()
                if uuid:
                    mountPoint = translateUUID.convertUUID(uuid)
                elif optionalSettings.get("mountPoint", ""):
                    mountPoint = optionalSettings.get("mountPoint", "")                   

            elif partitionType == "boot":
                mountPoint = "/boot/"
            elif partitionType == "efi":
                mountPoint = "/efi/"
            elif partitionType != "swap":
                raise Exception()

            temp_device["partitions"].append({
                "partition_name": partition_name,
                "type": partition["type"],
                "mountPoint": mountPoint,
                "size": partition["size"],
            })
        deviceList[device_name] = temp_device
    return deviceList, initial_gap


