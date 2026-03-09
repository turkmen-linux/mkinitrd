#!/bin/sh
# Hook order
hooks="base modules filesystem privacy zram"
# Module list
# * most = copy all storage and filesystem modules
# * dep = copy all modules used by current system
# * all = copy all modules
# * none = do not copy any modules
modules="most"
# Filesystems
filesystems="ext4"
