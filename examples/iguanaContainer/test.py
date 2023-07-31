#!/usr/bin/python3

from storage import Environment, Storage


environment = Environment(True)

storage = Storage(environment)
storage.probe()

probed = storage.get_probed()
disks = probed.get_all_disks()
reg = disks[0].get_region()
print(probed)
print(disks)
print(disks[0].get_name())
print(reg)
print(reg.get_length() * reg.get_block_size())
# system = storage.get_system()
# staging = storage.get_staging()

# print("PROBED")
# print(probed)
# print("SYSTEM")
# print(system)
# print("STAGING")
# print(staging)
