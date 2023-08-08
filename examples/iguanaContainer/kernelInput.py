if __name__ == "__main__":
    cmdline = ""
    with open("/proc/cmdline", "r") as cmdfile:
        cmdline = cmdfile.readline()

    result = ""
    options = cmdline.split(" ")
    for opt in options:
        keyval = opt.split("=", 2)
        key = keyval[0]
        if key.upper() != "PARTITIONING":
            continue
        val = "1"
        if len(keyval) > 1:
            val = keyval[1]
        result += f"{key.upper()}={val}\n"
    print(result)