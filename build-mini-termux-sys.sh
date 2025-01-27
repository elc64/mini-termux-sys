#!/system/bin/sh
#
# Minimal Termux System packaging script by Goran Katavić <gkatavic@protonmail.com>
# Version: 1.3
#
# This script should be run only from Android application Termux!
#
# Before running this script, install required packages:
# --
# pkg upgrade
# pkg install busybox ldd rsync openssh tmux wget
#
TERMUXROOT=/data/data/com.termux
TERMUXFILES="$TERMUXROOT/files"
#
# $MINITEMUXROOTROOT must be the same character/byte lenght as $TERMUXROOT
# 
MINITERMUXSYSROOT=/system/etc/comtermux
MINITERMUXSYSFILES="$MINITERMUXSYSROOT/files"
#
# $DATALINUXTERMUX must be the same character/byte lenght as $TERMUXROOT
#
DATALINUXTERMUX=/data/linux/comtermux
DATALINUXTERMUXFILES=$DATALINUXTERMUX/files
#
TERMUXPACK="$TERMUXROOT/files/home/comtermuxpack"
TERMUXPACKFILES="$TERMUXPACK/files"

TODAY=`date +%Y%m%d`

TM_BUSYBOX="$TERMUXFILES/usr/bin/busybox"
TM_CP="$TERMUXFILES/usr/bin/cp"
TM_CHMOD="$TERMUXFILES/usr/bin/chmod"
TM_GZIP="$TERMUXFILES/usr/bin/gzip"
TM_LDD="$TERMUXFILES/usr/bin/ldd"
TM_LN="$TERMUXFILES/usr/bin/ln"
TM_MKDIR="$TERMUXFILES/usr/bin/mkdir"
TM_RM="$TERMUXFILES/usr/bin/rm"
TM_RSYNC="$TERMUXFILES/usr/bin/rsync"
TM_SED="$TERMUXFILES/usr/bin/sed"
TM_TAR="$TERMUXFILES/usr/bin/tar"

# Check if the user is a non-root user
if [ "$(id -u)" -eq 0 ]; then
  echo
  echo "Error: You must run this script as a non-root user."
  exit 1
fi

# check for termux install
if [ ! -f "$TERMUXFILES/usr/lib/libandroid-support.so" ]; then 
  echo "Error: Termux not found!"
  exit 2
fi

# check for termux sed
if [ ! -f "$TERMUXFILES/usr/bin/sed" ]; then 
  echo "Error: Termux sed not found!"
  exit 3
fi

# check for ldd
if [ ! -f "$TM_LDD" ]; then
  echo "Error: The program ldd is not installed. Install it by executing:"
  echo " pkg install ldd"
  exit 4
fi

# check for rsync
if [ ! -f "$TM_RSYNC" ]; then
  echo "Error: The program rsync is not installed. Install it by executing:"
  echo " pkg install rsync"
  exit 5
fi

# check for busybox
if [ ! -f "$TM_RSYNC" ]; then
  echo "Error: The program busybox is not installed. Install it by executing:"
  echo " pkg install busybox"
  exit 6
fi

# check for sshd
if [ ! -f "$TERMUXFILES/usr/bin/sshd" ]; then
  echo "Error: The program sshd is not installed. Install it by executing:"
  echo " pkg install openssh"
  exit 7
fi

# check for tmux
if [ ! -f "$TERMUXFILES/usr/bin/tmux" ]; then
  echo "Error: The program tmux is not installed. Install it by executing:"
  echo " pkg install tmux"
  exit 8
fi

# check for wget
if [ ! -f "$TERMUXFILES/usr/bin/wget" ]; then
  echo "Error: The program wget is not installed. Install it by executing:"
  echo " pkg install wget"
  exit 9
fi

# create output directory
"$TM_MKDIR" -p "$TERMUXPACKFILES"
if [ ! -d "$TERMUXPACKFILES" ]; then
  echo "Can't create directory: $TERMUXPACKFILES!"
  exit 99
fi

SED_IN=$(echo "$TERMUXFILES" | "$TM_SED" 's/\//\\\//g')
SED_OUT=$(echo "$MINITERMUXSYSFILES" | "$TM_SED" 's/\//\\\//g')

# check for home symlink
if [ ! -L "$TERMUXPACKFILES/home" ]; then
  "$TM_RM" -fr "$TERMUXPACKFILES/home"
  "$TM_LN" -s "$DATALINUXTERMUXFILES/home" "$TERMUXPACKFILES/home" 
fi
# make main directories
"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/bin"
"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/etc"
"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/lib"
"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/libexec"
"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/share"

# softlink usr/tmp to read-write location
if [ ! -L "$TERMUXPACKFILES/usr/tmp" ]; then
  "$TM_RM" -fr "$TERMUXPACKFILES/usr/tmp"
  "$TM_LN" -s "$DATALINUXTERMUXFILES/usr/tmp" "$TERMUXPACKFILES/usr/tmp" 
fi

"$TM_MKDIR" -p "$TERMUXPACKFILES/usr/var/spool/cron"

# softlink usr/var/empty to read-write location
if [ ! -L "$TERMUXPACKFILES/usr/var/empty" ]; then
  "$TM_RM" -fr "$TERMUXPACKFILES/usr/var/empty"
  "$TM_LN" -s "$DATALINUXTERMUXFILES/usr/var/empty" "$TERMUXPACKFILES/usr/var/empty" 
fi
# softlink usr/var/empty to read-write location
if [ ! -L "$TERMUXPACKFILES/usr/var/run" ]; then
  "$TM_RM" -fr "$TERMUXPACKFILES/usr/var/run"
  "$TM_LN" -s "$DATALINUXTERMUXFILES/usr/var/run" "$TERMUXPACKFILES/usr/var/run" 
fi

copyandpatch () {
  "$TM_CP" -a "$TERMUXFILES$1" "$TERMUXPACKFILES$1"
  "$TM_SED" -i "s/$SED_IN/$SED_OUT/g" "$TERMUXPACKFILES$1"
}

checksolibs () {
  for xsolib in `"$TM_LDD" "$1" | grep " => /data/data/com.termux/files/usr/lib/" | grep -v /libandroid-support.so | awk '{print $1}'`; do
    if [ ! -f "$TERMUXPACKFILES/usr/lib/$xsolib" ]; then
      echo $xsolib
      "$TM_CP" -p "$TERMUXFILES/usr/lib/$xsolib" "$TERMUXPACKFILES/usr/lib/$xsolib"
      "$TM_SED" -i "s/$SED_IN/$SED_OUT/g" "$TERMUXPACKFILES/usr/lib/$xsolib"
    fi
  done
}

copyandpatchandchecksolibs () {
  copyandpatch "$1"
  checksolibs "$TERMUXFILES/$1"
}

echo
echo Copying and patching ...
echo "--"

# libandroid-support.so
copyandpatch /usr/lib/libandroid-support.so

# libtermux-exec.so
copyandpatch /usr/lib/libtermux-exec.so

# terminfo
"$TM_RSYNC" -av --delete "$TERMUXFILES/usr/share/terminfo/" "$TERMUXPACKFILES/usr/share/terminfo/" >/dev/null
#
# etc/tls
"$TM_RSYNC" -av --delete "$TERMUXFILES/usr/etc/tls/" "$TERMUXPACKFILES/usr/etc/tls/" >/dev/null

# login
copyandpatch /usr/bin/login

# bash
copyandpatchandchecksolibs /usr/bin/bash

# sh -> bash
if [ ! -L "$TERMUXPACKFILES/usr/bin/sh" ]; then
  "$TM_RM" -fr "$TERMUXPACKFILES/usr/bin/sh"
  "$TM_LN" -s bash "$TERMUXPACKFILES/usr/bin/sh"
fi

# sshd
copyandpatchandchecksolibs /usr/bin/sshd
#
# sshd - config
"$TM_RSYNC" -av --delete "$TERMUXFILES/usr/etc/ssh/" "$TERMUXPACKFILES/usr/etc/ssh/" >/dev/null
"$TM_RM" -f "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_"*
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ecdsa_key" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_ecdsa_key"
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ecdsa_key.pub" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_ecdsa_key.pub"
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ed25519_key" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_ed25519_key"
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ed25519_key.pub" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_ed25519_key.pub"
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_rsa_key" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_rsa_key"
"$TM_LN" -s "$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_rsa_key.pub" "$TERMUXPACKFILES/usr/etc/ssh/ssh_host_rsa_key.pub"
"$TM_SED" -i "s/$SED_IN/$SED_OUT/g" "$TERMUXPACKFILES/usr/etc/ssh/sshd_config"
"$TM_SED" -i -E 's/^[[:space:]]*(#?Port).*$/Port 28282/g' "$TERMUXPACKFILES/usr/etc/ssh/sshd_config"
"$TM_SED" -i -E 's/^[[:space:]]*(#?PermitRootLogin).*$/PermitRootLogin yes/g' "$TERMUXPACKFILES/usr/etc/ssh/sshd_config"
#
# sshd - sftp-server
copyandpatch /usr/libexec/sftp-server
#
# sshd - sshd-session
copyandpatchandchecksolibs /usr/libexec/sshd-session
#
# sshd - passwd
copyandpatchandchecksolibs /usr/bin/passwd
#
# sshd - pwlogin
# copyandpatch /usr/bin/pwlogin

# ssh
copyandpatchandchecksolibs /usr/bin/ssh

# ssh-keygen
copyandpatchandchecksolibs /usr/bin/ssh-keygen

# rsync
copyandpatchandchecksolibs /usr/bin/rsync

# tmux
copyandpatchandchecksolibs /usr/bin/tmux

# wget
copyandpatchandchecksolibs /usr/bin/wget

# hostname
copyandpatchandchecksolibs /usr/bin/hostname

# less
copyandpatchandchecksolibs /usr/bin/less

# nano
copyandpatchandchecksolibs /usr/bin/nano

# busybox (must be after other programs)
copyandpatchandchecksolibs /usr/bin/busybox
for xprog in `"$TM_BUSYBOX" --list`; do
   if [ ! -f "$TERMUXPACKFILES/usr/bin/$xprog" -a ! -f "$TERMUXPACKFILES/usr/bin/$xprog" ]; then
     "$TM_LN" -s busybox "$TERMUXPACKFILES/usr/bin/$xprog"
   fi
done
# exclude some busybox links (use /system/bin's)
rm -f "$TERMUXPACKFILES/usr/bin/mount"
rm -f "$TERMUXPACKFILES/usr/bin/umount"

# etc/profile
copyandpatch /usr/etc/profile

# etc/bash.bashrc
echo "PS1=\"\\\n\[\e[0;34m\]{\[\e[0m\]\[\e[0;36m\]\h\[\e[0m\]\[\e[0;34m\]}\[\e[0m\] \[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]#\[\e[0m\] \"" > "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias bb='tmux -u a || tmux -u new'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias l='less -X'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias ll='ls --color=always -Flah | less -R -X'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias rootro='mount -o ro,remount /'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias rootrw='mount -o rw,remount /'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias sysro='mount -o ro,remount /system'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
echo "alias sysrw='mount -o rw,remount /system'" >> "$TERMUXPACKFILES/usr/etc/bash.bashrc"
"$TM_CHMOD" 644 "$TERMUXPACKFILES/usr/etc/bash.bashrc"

# etc/termux-login.sh
echo "export LANG=\"en_US.UTF-8\"" > "$TERMUXPACKFILES/usr/etc/termux-login.sh"
echo "TERM=linux" >> "$TERMUXPACKFILES/usr/etc/termux-login.sh"
echo "cd \"\$HOME\"" >> "$TERMUXPACKFILES/usr/etc/termux-login.sh"
"$TM_CHMOD" 644 "$TERMUXPACKFILES/usr/etc/termux-login.sh"


cat << __EOF > "$TERMUXPACK/start-minitermuxsys.sh"
#!/system/bin/sh
#
MINITERMUXSYS="$MINITERMUXSYSROOT"
MINITERMUXBINDIR="\$MINITERMUXSYS/files/usr/bin"
#
DATALINUXTERMUX="$DATALINUXTERMUX"
DATALINUXTERMUXFILES="\$DATALINUXTERMUX/files"
#
umask 022
trap '' HUP

# On some systems, allow time for full system initialization before proceeding
# sleep 24

checkdatatmdir () {
  if [ ! -d "\$DATALINUXTERMUXFILES/\$1" ]; then
    "\$MINITERMUXBINDIR/mkdir" -p "\$DATALINUXTERMUXFILES/\$1"
    "\$MINITERMUXBINDIR/chmod" "\$2" "\$DATALINUXTERMUXFILES/\$1"
  fi
}

checkdatatmdir . 755
checkdatatmdir home 700
checkdatatmdir usr 755
checkdatatmdir usr/etc 755
checkdatatmdir usr/etc/ssh 700
checkdatatmdir usr/tmp 1777
checkdatatmdir usr/var 755
checkdatatmdir usr/var/empty 755
checkdatatmdir usr/var/run 755
checkdatatmdir usr/var/spool 755
checkdatatmdir usr/var/spool/cron 755
checkdatatmdir usr/var/spool/cron/crontabs 755

if [ ! -f "\$DATALINUXTERMUXFILES/home/.termux_authinfo" ]; then
  # set password to 'minitermuxsys'
  echo "xO2F2MgnOdgkHvYP8Kyh6OMNyJE=" | "\$MINITERMUXBINDIR/busybox" base64 -d > "\$DATALINUXTERMUXFILES/home/.termux_authinfo"
  "\$MINITERMUXBINDIR/chmod" 600 "\$DATALINUXTERMUXFILES/home/.termux_authinfo"
fi

if [ ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ecdsa_key" -o ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ecdsa_key.pub" ]; then
  "\$MINITERMUXBINDIR/ssh-keygen" -t ecdsa -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ecdsa_key" -N "" >/dev/null
fi

if [ ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ed25519_key" -o ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ed25519_key.pub" ]; then
  "\$MINITERMUXBINDIR/ssh-keygen" -t ed25519 -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_ed25519_key" -N "" >/dev/null
fi

if [ ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_rsa_key" -o ! -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_rsa_key.pub" ]; then
  "\$MINITERMUXBINDIR/ssh-keygen" -t rsa -f "\$DATALINUXTERMUXFILES/usr/etc/ssh/ssh_host_rsa_key" -N "" >/dev/null
fi

export PATH=$MINITERMUXSYSROOT/files/usr/bin:$DATALINUXTERMUX/files/usr/bin:/system/bin:/system/xbin:/system/sbin:/vendor/bin:/vendor/xbin
# !!! IMPORTANT: The sftp-server fails without LD_PRELOAD, and .termux_authinfo is used from another location during authentication. !!! #
export LD_PRELOAD=$MINITERMUXSYSROOT/files/usr/lib/libtermux-exec.so

if [ -x "\$MINITERMUXSYS/start-local.sh" ]; then
  "\$MINITERMUXSYS/start-local.sh" &
fi

"\$MINITERMUXBINDIR/crond" -b -l 8 -L "\$DATALINUXTERMUXFILES/usr/tmp" -c "\$MINITERMUXSYS/files/usr/var/spool/cron/crontabs" &

if [ "$1" != "-D" ]; then
  "\$MINITERMUXBINDIR/sshd" "\$@"
  exit 0
fi

while [ 1 = 1 ]; do
  "\$MINITERMUXBINDIR/sshd" -D
  sleep 64
  if [ ! -d /data/local/tmp/ ]; then
    "\$MINITERMUXBINDIR/busybox" mkdir -p /data/local/tmp
    "\$MINITERMUXBINDIR/chown" shell:shell /data/local/tmp
    "\$MINITERMUXBINDIR/chmod" 775 /data/local/tmp
  fi
  echo >> /data/local/tmp/sshdrestart.log
  echo SSHD restart ... >> /data/local/tmp/sshdrestart.log
  date >> /data/local/tmp/sshdrestart.log
done
__EOF
"$TM_CHMOD" 700 "$TERMUXPACK/start-minitermuxsys.sh"


cat << __EOF > "$TERMUXPACK/start-local-example.sh"
#!/system/bin/sh
#
# To execute this script, copy it to: $MINITERMUXSYSROOT/start-local.sh
# Ensure the file has executable permissions: chmod +x $MINITERMUXSYSROOT/start-local.sh
#
# NOTE: To write to the /system directory, you must remount it with read-write permissions.
# Use the following command to remount /system:
# mount -o rw,remount /system
#
# After making changes, remount the /system directory as read-only for security:
# mount -o ro,remount /system
#
# Change the hostname, as many Android devices default to 'localhost'
# hostname myhostname
__EOF
"$TM_CHMOD" 700 "$TERMUXPACK/start-local-example.sh"


cat << __EOF > "$TERMUXPACK/README.txt"
These files should only be extracted on Android devices to: $MINITERMUXSYSROOT
__EOF


echo Done.

PACKAGENAME=mini-termux-sys
ARCH=`"$TM_BUSYBOX" arch`
if [ "$ARCH" = "" ]; then
  ARCH=unknown
fi

echo
echo Packing to "$TERMUXROOT/files/home/$PACKAGENAME-$TODAY-$ARCH.tar.gz" ...
echo "--"
"$TM_RM" -f "$TERMUXROOT/files/home/$PACKAGENAME-$TODAY-$ARCH.tar"
"$TM_RM" -f "$TERMUXROOT/files/home/$PACKAGENAME-$TODAY-$ARCH.tar.gz"
cd "$TERMUXPACK"
"$TM_TAR" cvf "$TERMUXROOT/files/home/$PACKAGENAME-$TODAY-$ARCH.tar" files README.txt start-local-example.sh start-minitermuxsys.sh --owner=0 --group=0 >/dev/null
"$TM_GZIP" -9 "$TERMUXROOT/files/home/$PACKAGENAME-$TODAY-$ARCH.tar"
echo Done.
echo
