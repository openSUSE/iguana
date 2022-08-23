#!/usr/bin/python3

# Parse saltboot entries from kernel command line
_ALLOWED_OPTIONS= [
    "MASTER",
    "MINION_ID_PREFIX",
    "SALT_TIMEOUT",
    "SALT_DEVICE",
    "SALT_AUTOSIGN_GRAINS",
    "DISABLE_UNIQUE_SUFFIX",
    "DISABLE_HOSTNAME_ID",
    "DISABLE_ID_PREFIX",
    "USE_FQDN_MINION_ID",
    "KIWIDEBUG",
    ]

if __name__ == "__main__":
    cmdline = ""
    with open("/proc/cmdline", "r") as cmdfile:
        cmdline = cmdfile.readline()

    result = ""
    options = cmdline.split(" ")
    for opt in options:
        keyval = opt.split("=", 2)
        key = keyval[0]
        if key.upper() not in _ALLOWED_OPTIONS:
            continue
        val = "1"
        if len(keyval) > 1:
            val = keyval[1]
        result += f"{key.upper()}={val}\n"

    print(result)