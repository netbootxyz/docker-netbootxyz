#!/bin/bash

# Perform the initial configuration as root
/init.sh

echo "            _   _                 _                      "
echo " _ __   ___| |_| |__   ___   ___ | |_  __  ___   _ ____  "
echo "| '_ \ / _ \ __| '_ \ / _ \ / _ \| __| \ \/ / | | |_  /  "
echo "| | | |  __/ |_| |_) | (_) | (_) | |_ _ >  <| |_| |/ /   "
echo "|_| |_|\___|\__|_.__/ \___/ \___/ \__(_)_/\_\\__,  /___| "
echo "                                             |___/       "
echo 
echo "If you enjoy netboot.xyz projects, please support us at:"
echo
echo "https://opencollective.com/netbootxyz" 
echo "https://github.com/sponsors/netbootxyz"
echo

# Run supervisord as root
echo "[start] Starting supervisord (programs will run as nbxyz)"
exec supervisord -c /etc/supervisor.conf
