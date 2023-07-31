from storage import *

def convertUUID(uuid):
    table = {

        #/
        # Alpha
        "6523f8ae-3eb1-4e2a-a05a-18b695ae656f": "/",
        # ARC
        "d27f46ed-2919-4cb8-bd25-9531f3c16534": "/",
        # 64-bit ARM/AArch64
        "69dad710-2ce4-4e3c-b16c-21a1d49abed3": "/",
        # Itanium/IA-64
        "b921b045-1df0-41c3-af44-4c6f280d3fae": "/",
        # LoongArch 64-bit
        "77055800-792c-4f94-b39a-98c91b762bb6": "/",
        # mipsel
        "37c58c8a-d913-4156-a25f-48b1b64e07f0": "/",
        # mipsel64el
        "700bda43-7a34-4507-b179-eeb93d7a7ca3": "/",
        # HPPA/PARISC
        "1aacdb3b-5444-4138-bd9e-e5c2239b2346": "/",
        # 32-bit PowerPC
        "1de3f1ef-fa98-47b5-8dcd-4a860a654d78": "/",
        # 64-bit PowerPC BigEndian
        "912ade1d-a839-4913-8964-a10eee08fbd2": "/",
        # 64-bit PowerPC LittleEndian
        "c31c45e6-3f39-412e-80fb-4809c4980599": "/",
        # RISC-V 32-bit
        "60d5a7fe-8e7d-435c-b714-3dd8162144e1": "/",
        # RISC-V 64-bit
        "72ec70a6-cf74-40e6-bd49-4bda08e8f224": "/",
        # s390
        "08a7acea-624c-4a20-91e8-6e0fa67d23f9": "/",
        # s390x
        "5eead9a9-fe09-4a1e-a1d7-520d00531306": "/",
        # TILE-Gx
        "c50cdd70-3862-4cc3-90e1-809a8c93ee2c": "/",
        # x86
        "44479540-f297-41b2-9af7-d131d5f0458a": "/",
        # x86_64
        "4f68bce3-e8cd-4db1-96e7-fbcaf984b709": "/",
        
        # /usr/
        # Alpha
        "e18cf08c-33ec-4c0d-8246-c6c6fb3da024": "/usr/",
        # ARC
        "7978a683-6316-4922-bbee-38bff5a2fecc": "/usr/",
        #32-bit ARM
        "7d0359a3-02b3-4f0a-865c-654403e70625": "/usr/",
        # 64-bit ARM/AArch64
        "b0e01050-ee5f-4390-949a-9101b17104e9": "/usr/",
        #Itanium/IA-64
        "4301d2a6-4e3b-4b2a-bb94-9e0b2c4225ea": "/usr/",
        # LoongArch 64-bit
        "e611c702-575c-4cbe-9a46-434fa0bf7e3f": "/usr/",
        # mipsel
        "0f4868e9-9952-4706-979f-3ed3a473e947": "/usr/",
        # mips64el
        "c97c1f32-ba06-40b4-9f22-236061b08aa8": "/usr/",
        # HPPA/PARISC 
        "dc4a4480-6917-4262-a4ec-db9384949f25": "/usr/",
        # 32-bit PowerPC
        "7d14fec5-cc71-415d-9d6c-06bf0b3c3eaf": "/usr/",
        # 64-bit PowerPC BigEndian
        "2c9739e2-f068-46b3-9fd0-01c5a9afbcca": "/usr/",
        # 64-bit PowerPC LittleEndian
        "15bb03af-77e7-4d4a-b12b-c0d084f7491c": "/usr/",
        # RICS-V 32-bit
        "b933fb22-5c3f-4f91-af90-e2bb0fa50702": "/usr/",
        # RISC-V 64-bit
        "beaec34b-8442-439b-a40b-984381ed097d": "/usr/",
        # s390
        "cd0f869b-d0fb-4ca0-b141-9ea87cc78d66": "/usr/",
        # s390x
        "8a4f5770-50aa-4ed3-874a-99b710db6fea": "/usr/",
        # TILE-Gx
        "55497029-c7c1-44cc-aa39-815ed1558630": "/usr/",
        # x86
        "75250d76-8cc6-458e-bd66-bd47cc81a812": "/usr/",
        # amd64/x86_64
        "8484680c-9521-48c6-9c11-b0720656f69e": "/usr/",

        # EFI System
        "c12a7328-f81f-11d2-ba4b-00a0c93ec93b": "/efi/",

        # Extended Boot Loader Partition
        "bc13c2ff-59e6-4262-a352-b275fd6f7172": "/boot/",

        # SWAP
        "0657fd6d-a4ab-43c4-84e5-0933c84b4f4f": None,

        # Home
        "933ac7e1-2eb4-4f13-b844-0e14e2aef915": "/home/",

        #Server Data
        "3b8f8425-20e0-4f3b-907f-1a25a76f98e8": "/srv/",

        # Variabale Data
        "4d21b016-b534-45c2-a9fb-5c16e091fd2d": "/var/",

        # Temporary Data Partition
        "7ec6f557-3bc5-4aca-b293-16ef5df639d1": "/var/tmp",

        # Generic Linux Data Partition
        "0fc63daf-8483-4772-8e79-3d69d8477de4": None

    }
    return table[uuid]