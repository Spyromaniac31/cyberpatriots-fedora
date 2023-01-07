#!/bin/bash

YES="[\033[0;32m ✓ \033[0m]"
NO="[\033[0;31m ✗ \033[0m]"

overwrite() { echo -e "\r\033[1A\033[0K$@"; }

if [ $EUID -ne 0 ]; then
  echo -e "${NO} Script called with non-root privileges"
  exit 1
fi
echo -e "${YES} Root user check"

if [[ -f "users.txt" ]]; then
  echo -e "${YES} Users file found"
else
  echo -e "${NO} Users file not found"
  exit 1
fi

if [[ -f "admins.txt" ]]; then
  echo -e "${YES} Admins file found"
else
  echo -e "${NO} Admins file not found"
  exit 1
fi

echo -e "[ i ] Adding specified users..."
while read line; do 
  useradd -m $line &> /dev/null
done < users.txt
overwrite "${YES} All users added"

echo -e "[ i ] Removing unauthorized users..."
IFS=':'
while read -r user pass uid gid desc home shell; do
  if (($uid >= 1000)) && !(grep -q $user "users.txt"); then
    userdel -r $user &> /dev/null
  fi
done < /etc/passwd
overwrite "${YES} Unauthorized users removed"

# UPDATE THIS PASSWORD BEFORE RUNNING THE SCRIPT
echo -e "[ i ] Updating user passwords..."
while read line; do
  echo $line':Cyb3rP@triot' | chpasswd &> /dev/null
  chage -m 7 -M 90 -W 14 &> /dev/null
done < users.txt
overwrite "${YES} User passwords updated"

echo -e "[ i ] Disabling root account..."
passwd -l root > /dev/null
overwrite "${YES} Disabled root account"

echo -e "[ i ] Configuring admin privileges"
while read -r user pass uid gid desc home shell; do
  if (($uid >= 1000)); then
    if grep -q $user "admins.txt"; then
      usermod -aG wheel $user > /dev/null
    else
      gpasswd -d $user wheel &> /dev/null
    fi
  fi
done < /etc/passwd
overwrite "${YES} Admin priviliges configured"

echo -e "[ i ] Restricting home directory access..."
while read -r user pass uid gid desc home shell; do
  if (($uid >= 1000)); then
    chmod 750 $home
  fi
done < /etc/passwd
overwrite "${YES} Home directory access restricted"

echo -e "[ i ] Updating cache of available packages..."
dnf check-update > /dev/null
overwrite "${YES} Updated cache of available packages"

echo -e "[ i ] Upgrading installed packages..."
dnf upgrade -y > /dev/null
overwrite "${YES} Updated installed packages"

echo -e "[ i ] Enabling firewall..."
firewall-cmd --set-default-zone=public > /dev/null
firewall-cmd --reload > /dev/null
overwrite "${YES} Enabled firewall"

echo -e "[ i ] Ensuring mounting of cramfs is disabled..."
printf "install cramfs /bin/false
blacklist cramfs
" >> /etc/modprobe.d/cramfs.conf
modprobe -r cramfs
overwrite "${YES} Ensured mounting of cramfs is disabled"

echo -e "[ i ] Ensuring mounting of squashfs is disabled..."
printf "install squashfs /bin/false
blacklist squashfs
" >> /etc/modprobe.d/squashfs.conf
modprobe -r squashfs
overwrite "${YES} Ensured mounting of squashfs is disabled"

echo -e "[ i ] Ensuring mounting of udf is disabled..."
printf "install udf /bin/false
blacklist udf
" >> /etc/modprobe.d/udf.conf
modprobe -r udf
overwrite "${YES} Ensured mounting of udf is disabled"

echo -e "[ i ] Disabling automounting..."
dnf remove -y autofs &> /dev/null
overwrite "${YES} Disabled automounting"

echo -e "[ i ] Disabling USB storage..."
dnf remove -y usbutils &> /dev/null
overwrite "${YES} Disabled USB storage"

