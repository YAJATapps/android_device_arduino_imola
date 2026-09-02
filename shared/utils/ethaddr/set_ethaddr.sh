#! /vendor/bin/sh
# Set eth0 mac address.
#
# Get the unique board serial number from /proc/cmdline or
# /proc/bootconfig, prepend '0's to the serial number to
# fill 5 LSBs of the MAC address and prepend "02" as MSB to
# prepare a 6 byte locally administered unicast MAC address.
#
# Format the output in xx:xx:xx:xx:xx:xx format for the "ip"
# set address command to work.

ETHADDR=`/vendor/bin/cat /proc/cmdline | /vendor/bin/grep -o serialno.* |\
	 /vendor/bin/cut -f2 -d'=' | /vendor/bin/awk '{printf("02%010s\n", $1)}' |\
	 /vendor/bin/sed 's/\(..\)/\1:/g' | /vendor/bin/sed '$s/:$//'`
if [ -z "${ETHADDR}" ]
then
  ETHADDR=`/vendor/bin/cat /proc/bootconfig | /vendor/bin/grep -o serialno.* |\
	   /vendor/bin/cut -f2 -d'=' | /vendor/bin/cut -c 3-10 |\
	   /vendor/bin/awk '{printf("02%010s\n", $1)}' |\
	   /vendor/bin/sed 's/\(..\)/\1:/g' | /vendor/bin/sed '$s/:$//'`
fi

/vendor/bin/ifconfig eth0 down
/vendor/bin/ifconfig eth0 hw ether "${ETHADDR}"
/vendor/bin/ifconfig eth0 up
