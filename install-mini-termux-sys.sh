#!/system/bin/sh
#
# Minimal Termux System installer script by Goran Katavić <gkatavic@protonmail.com>
# Version: 1.3
#

# Check if the user is root
if [ "$(id -u)" -ne 0 ]; then
  echo
  echo "Error: You must run this script as root."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo
  echo "Usage: $0 <filename>"
  exit 2
fi

case "$1" in
  mini-termux-sys-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-*.tar.gz)
    ;;
  *)
    echo
    echo "The input filename does not match format: mini-termux-sys-{yyyymmdd}-{arch}.tar.gz"
    exit 3
    ;;
esac

MINITERMUXSYS=/system/etc/comtermux
DATALINUXTERMUX=/data/linux/comtermux
TESTFILE=`date +testfile%Y%m%d%H%M%S`

if [ -z "$TESTFILE" ]; then
    echo
    echo "Date command failed!"
    exit 4
fi

MOUNTCMD=/system/bin/mount
if [ ! -x "$MOUNTCMD" ]; then
  MOUNTCMD=mount
fi

# Remount system read-write
ANDMOUNT=/system
"$MOUNTCMD" -o rw,remount /system 2>/dev/null
if [ $? -ne 0 ]; then
  # remount /system failed, on some devices there is no separate /system mount
  "$MOUNTCMD" -o rw,remount / 2>/dev/null
  if [ $? -ne 0 ]; then
    echo
    echo "Remounting system with read-write priviledges failed!"
    exit 5
  else
    ANDMOUNT=/
  fi
fi

# Test if destination folder is writable
#
mkdir -p "$MINITERMUXSYS"
echo -n > "$MINITERMUXSYS/$TESTFILE"
if [ ! -f "$MINITERMUXSYS/$TESTFILE" ]; then
    echo
    echo Create file: "$MINITERMUXSYS/$TESTFILE" failed!
#    exit 6
fi
rm -f "$MINITERMUXSYS/$TESTFILE"

# Extract .tar.gz package
echo
echo Extracting package "$1" to "$MINITERMUXSYS" ...
echo --
gzip -c -d "$1" | tar xvf - -C "$MINITERMUXSYS" >/dev/null
if [ $? -ne 0 ]; then
  echo
  echo "Extraction failed!"
  "$MOUNTCMD" -o ro,remount "$ANDMOUNT" 2>/dev/null
  exit 7
else
  echo Done.
fi

if [ ! -L "$MINITERMUXSYS/files/usr/var/spool/cron/crontabs" ]; then
  if [ ! -d "$MINITERMUXSYS/files/usr/var/spool/cron/crontabs" ]; then
    echo nije dir
    ln -s "$DATALINUXTERMUX/files/usr/var/spool/cron/crontabs" "$MINITERMUXSYS/files/usr/var/spool/cron/crontabs"
  fi
fi

DONE=0
echo
echo Trying to create auto-boot-script ...
echo --

# /system/etc/init/
RC_NAME=minitermuxsys.rc
HAS_RC=`ls /system/etc/init/*.rc 2>/dev/null`
if [ -n "$HAS_RC" ]; then
  echo /system/etc/init/$RC_NAME
  echo "service minitermuxsys /system/etc/comtermux/start-minitermuxsys.sh -D" > /system/etc/init/$RC_NAME
  echo "    class late_start" >> /system/etc/init/$RC_NAME
  echo "    user root" >> /system/etc/init/$RC_NAME
  echo "    group root" >> /system/etc/init/$RC_NAME
  echo "    seclabel u:r:init:s0" >> /system/etc/init/$RC_NAME
  echo "    oneshoot" >> /system/etc/init/$RC_NAME
  chmod 644 /system/etc/init/$RC_NAME
  DONE=1
fi

echo --
echo Done.
echo

# Remount system read-only
"$MOUNTCMD" -o ro,remount "$ANDMOUNT" 2>/dev/null

echo "# You can now test the SSHD by executing the following command:"
echo "#"
echo "# /system/etc/comtermux/start-minitermuxsys.sh"
echo "#"
echo "# The SSHD TCP port is 28282."
echo "# Username is 'root', and the default password is 'minitermuxsys'."
echo "#"
echo "# Once logged in, you can change the password using the passwd command."
echo "#"
echo "# The password is stored in the file \$HOME/.termux_authinfo."
echo
