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

echo -e "[ i ] Updating core dump configuration..."
cp coredump.conf /etc/systemd/coredump.conf
overwrite "${YES} Updated core dump configuration"

echo -e "[ i ] Ensuring address space layout randomization (ASLR) is enabled..."
echo 2 > /proc/sys/kernel/randomize_va_space
overwrite "${YES} Ensured address space layout randomization (ASLR) is enabled"

echo -e "[ i ] Ensuring message of the day (MOTD) is configured..."
cp motd /etc/motd
overwrite "${YES} Ensured message of the day (MOTD) is configured"

echo -e "[ i ] Ensuring local login warning banner is configured..."
cp issue /etc/issue
overwrite "${YES} Ensured local login warning banner is configured"

echo -e "[ i ] Ensuring remote login warning banner is configured..."
cp issue.net /etc/issue.net
overwrite "${YES} Ensured remote login warning banner is configured"

echo -e "[ i ] Ensuring permissions on /etc/motd are configured..."
chown root:root /etc/motd
chmod u-x,go-wx /etc/motd
overwrite "${YES} Ensured permissions on /etc/motd are configured"

echo -e "[ i ] Ensuring permissions on /etc/issue are configured..."
chown root:root /etc/issue
chmod u-x,go-wx /etc/issue
overwrite "${YES} Ensured permissions on /etc/issue are configured"

echo -e "[ i ] Ensuring permissions on /etc/issue.net are configured..."
chown root:root /etc/issue.net
chmod u-x,go-wx /etc/issue.net
overwrite "${YES} Ensured permissions on /etc/issue.net are configured"

echo -e "[ i ] Ensuring GDM login banner is configured..."
cp gdm /etc/dconf/profile/gdm
cp 01-banner-message /etc/dconf/db/gdm.d/01-banner-message
dconf update
overwrite "${YES} Ensured GDM login banner is configured"

echo -e "[ i ] Ensuring last logged in user display is disabled..."
cp 00-login-screen /etc/dconf/db/gdm.d/00-login-screen
dconf update
overwrite "${YES} Ensured last logged in user display is disabled"

echo -e "[ i ] Ensuring XDMCP is not enabled..."
cp custom.conf /etc/gdm/custom.conf
overwrite "${YES} Ensured XDMCP is not enabled"

echo -e "[ i ] Ensuring automatic mounting of removable media is disabled..."
cp 00-media-automount /etc/dconf/db/local.d/00-media-automount
dconf update
overwrite "${YES} Ensured automatic mounting of removable media is disabled"

echo -e "[ i ] Ensuring system-wide crypto policy is not legacy..."
update-crypto-policies --set DEFAULT > /dev/null
update-crypto-policies
overwrite "${YES} Ensured system-wide crypto policy is not legacy"

echo -e "[ i ] Ensuring xinetd is not installed..."
dnf remove -y xinetd &> /dev/null
overwrite "${YES} Ensured xinetd is not installed"

echo -e "[ i ] Ensuring xorg-x11-server-common is not installed..."
dnf remove -y xorg-x11-server-common &> /dev/null
overwrite "${YES} Ensured xorg-x11-server-common is not installed"

echo -e "[ i ] Ensuring Avahi Server is not installed..."
systemctl stop avahi-daemon.socket avahi-daemon.service
dnf remove -y avahi-autoipd avahi &> /dev/null
overwrite "${YES} Ensured Avahi Server is not installed"

echo -e "[ i ] Ensuring CUPS is not installed..."
dnf remove -y cups &> /dev/null
overwrite "${YES} Ensured CUPS is not installed"

echo -e "[ i ] Ensuring DHCP Server is not installed..."
dnf remove -y dhcp &> /dev/null
overwrite "${YES} Ensured DHCP Server is not installed"

echo -e "[ i ] Ensuring DNS Server is not installed..."
dnf remove -y bind &> /dev/null
overwrite "${YES} Ensured DNS Server is not installed"

echo -e "[ i ] Ensuring FTP Server is not installed..."
dnf remove -y ftp &> /dev/null
overwrite "${YES} Ensured FTP Server is not installed"

echo -e "[ i ] Ensuring VSFTP Server is not installed..."
dnf remove -y vsftpd &> /dev/null
overwrite "${YES} Ensured VSFTP Server is not installed"

echo -e "[ i ] Ensuring TFTP Server is not installed..."
dnf remove -y tftp-server &> /dev/null
overwrite "${YES} Ensured TFTP Server is not installed"

echo -e "[ i ] Ensuring a web server is not installed..."
dnf remove -y httpd nginx &> /dev/null
overwrite "${YES} Ensured a web server is not installed"

echo -e "[ i ] Ensuring IMAP and POP3 server is not installed..."
dnf remove -y dovecot cyrus-imapd &> /dev/null
overwrite "${YES} Ensured IMAP and POP3 server is not installed"

echo -e "[ i ] Ensuring Samba is not installed..."
dnf remove -y samba &> /dev/null
overwrite "${YES} Ensured Samba is not installed"

echo -e "[ i ] Ensuring HTTP Proxy Server is not installed..."
dnf remove -y squid &> /dev/null
overwrite "${YES} Ensured HTTP Proxy Server is not installed"

echo -e "[ i ] Ensuring net-snmp is not installed..."
dnf remove -y net-snmp &> /dev/null
overwrite "${YES} Ensured net-snmp is not installed"

echo -e "[ i ] Ensuring NIS Server is not installed..."
dnf remove -y ypserv &> /dev/null
overwrite "${YES} Ensured NIS Server is not installed"

echo -e "[ i ] Ensuring telnet-server is not installed..."
dnf remove -y telnet-server &> /dev/null
overwrite "${YES} Ensured telnet-server is not installed"

echo -e "[ i ] Ensuring mail transfer agent is configured for local-only mode..."
cp main.cf /etc/postfix/main.cf
systemctl restart postfix
overwrite "${YES} Ensured mail transfer agent is configured for local-only mode"

echo -e "[ i ] Ensuring nfs-utils is not installed or the nfs-server service is masked..."
dnf remove -y nfs-utils &> /dev/null
overwrite "${YES} Ensured nfs-utils is not installed or the nfs-server service is masked"

echo -e "[ i ] Ensuring rpcbind is not installed or the rpcbind service is masked..."
dnf remove -y rpcbind &> /dev/null
overwrite "${YES} Ensured rpcbind is not installed or the rpcbind service is masked"

echo -e "[ i ] Ensuring rsync is not installed or the rsyncd service is masked..."
dnf remove -y rsync &> /dev/null
overwrite "${YES} Ensured rsync is not installed or the rsyncd service is masked"

echo -e "[ i ] Ensuring NIS Client is not installed..."
dnf remove -y ypbind &> /dev/null
overwrite "${YES} Ensured NIS Client is not installed"

echo -e "[ i ] Ensuring rsh client is not installed..."
dnf remove -y rsh &> /dev/null
overwrite "${YES} Ensured rsh client is not installed"

echo -e "[ i ] Ensuring talk client is not installed..."
dnf remove -y talk &> /dev/null
overwrite "${YES} Ensured talk client is not installed"

echo -e "[ i ] Ensuring telnet client is not installed..."
dnf remove -y telnet &> /dev/null
overwrite "${YES} Ensured telnet client is not installed"

echo -e "[ i ] Ensuring LDAP client is not installed..."
dnf remove -y openldap-clients &> /dev/null
overwrite "${YES} Ensured LDAP client is not installed"

echo -e "[ i ] Ensuring TFTP client is not installed..."
dnf remove -y tftp &> /dev/null
overwrite "${YES} Ensured TFTP client is not installed"

echo -e "[ i ] Ensuring SCTP is disabled..."
printf "
install sctp /bin/true
" >> /etc/modprobe.d/sctp.conf
overwrite "${YES} Ensured SCTP is disabled"

echo -e "[ i ] Ensuring DCCP is disabled..."
printf "
install dccp /bin/true
" >> /etc/modprobe.d/dccp.conf
overwrite "${YES} Ensured DCCP is disabled"

echo -e "[ i ] Ensuring network forwarding is disabled..."
printf "
net.ipv4.ip_forward = 0
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.ip_forward=0 &> /dev/null
sysctl -w net.ipv4.route.flush=1 &> /dev/null
printf "
net.ipv6.conf.all.forwarding = 0
" >> /etc/sysctl.d/60-netipv6_sysctl.conf
sysctl -w net.ipv6.conf.all.forwarding=0 &> /dev/null
sysctl -w net.ipv6.route.flush=1 &> /dev/null
overwrite "${YES} Ensured network forwarding is disabled"

echo -e "[ i ] Ensuring packet redirect sending is disabled..."
printf "
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured packet redirect sending is disabled"

echo -e "[ i ] Ensuring source routed packets are not accepted..."
printf "
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0
sysctl -w net.ipv4.route.flush=1
printf "
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
" >> /etc/sysctl.d/60-netipv6_sysctl.conf
sysctl -w net.ipv6.conf.all.accept_source_route=0
sysctl -w net.ipv6.conf.default.accept_source_route=0
sysctl -w net.ipv6.route.flush=1
overwrite "${YES} Ensured source routed packets are not accepted"

echo -e "[ i ] Ensuring ICMP redirects are not accepted..."
printf "
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
sysctl -w net.ipv4.route.flush=1
printf "
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
" >> /etc/sysctl.d/60-netipv6_sysctl.conf
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.default.accept_redirects=0
sysctl -w net.ipv6.route.flush=1
overwrite "${YES} Ensured ICMP redirects are not accepted"

echo -e "[ i ] Ensuring secure ICMP redirects are not accepted..."
printf "
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.secure_redirects=0
sysctl -w net.ipv4.conf.default.secure_redirects=0
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured secure ICMP redirects are not accepted"

echo -e "[ i ] Ensuring suspicious packets are logged..."
printf "
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.log_martians=1
sysctl -w net.ipv4.conf.default.log_martians=1
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured suspicious packets are logged"

echo -e "[ i ] Ensuring broadcast ICMP requests are ignored..."
printf "
net.ipv4.icmp_echo_ignore_broadcasts = 1
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured broadcast ICMP requests are ignored"

echo -e "[ i ] Ensuring bogus ICMP responses are ignored..."
printf "
net.ipv4.icmp_ignore_bogus_error_responses = 1
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured bogus ICMP responses are ignored"

echo -e "[ i ] Ensuring reverse path filtering is enabled..."
printf "
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.conf.all.rp_filter=1
sysctl -w net.ipv4.conf.default.rp_filter=1
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured reverse path filtering is enabled"

echo -e "[ i ] Ensuring TCP SYN Cookies is enabled..."
printf "
net.ipv4.tcp_syncookies = 1
" >> /etc/sysctl.d/60-netipv4_sysctl.conf
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.route.flush=1
overwrite "${YES} Ensured TCP SYN Cookies is enabled"

echo -e "[ i ] Ensuring IPv6 router advertisements are not accepted..."
printf "
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
" >> /etc/sysctl.d/60-netipv6_sysctl.conf
sysctl -w net.ipv6.conf.all.accept_ra=0
sysctl -w net.ipv6.conf.default.accept_ra=0
sysctl -w net.ipv6.route.flush=1
overwrite "${YES} Ensured IPv6 router advertisements are not accepted"

echo -e "[ i ] Ensuring IPv6 redirects are not accepted..."
printf "
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
" >> /etc/sysctl.d/60-netipv6_sysctl.conf
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.default.accept_redirects=0
sysctl -w net.ipv6.route.flush=1
overwrite "${YES} Ensured IPv6 redirects are not accepted"

echo -e "[ i ] Ensuring firewalld is installed..."
dnf install firewalld iptables
overwrite "${YES} Ensured firewalld is installed"

echo -e "[ i ] Ensuring iptables-services is not installed with firewalld..."
systemctl stop iptables
systemctl stop ip6tables
dnf remove iptables-services
overwrite "${YES} Ensured iptables-services is not installed with firewalld"

echo -e "[ i ] Ensuring nftables is not installed or masked with firewalld..."
dnf remove nftables
overwrite "${YES} Ensured nftables is not installed or masked with firewalld"

echo -e "[ i ] Ensuring firewalld service is enabled and running..."
systemctl unmask firewalld
systemctl --now enable firewalld
overwrite "${YES} Ensured firewalld service is enabled and running"

echo -e "[ i ] Ensuring firewalld default zone is set..."
firewall-cmd --set-default-zone=work
overwrite "${YES} Ensured firewalld default zone is set"

echo -e "[ i ] Ensuring auditd is installed..."
dnf install audit
overwrite "${YES} Ensured auditd is installed"

echo -e "[ i ] Ensuring auditd service is enabled..."
systemctl --now enable auditd
overwrite "${YES} Ensured auditd service is enabled"

echo -e "[ i ] Ensuring auditing for processes that start prior to auditd is enabled..."
grubby --update-kernel ALL --args 'audit=1'
overwrite "${YES} Ensured auditing for processes that start prior to auditd is enabled"

echo -e "[ i ] Ensuring audit_backlog_limit is sufficient..."
grubby --update-kernel ALL --args 'audit_backlog_limit=8192'
overwrite "${YES} Ensured audit_backlog_limit is sufficient"

echo -e "[ i ] Updating auditd configuration file..."
cp auditd.conf /etc/audit/auditd.conf
overwrite "${YES} Updated auditd configuration file"

echo -e "[ i ] Ensuring changes to system administration scope (sudoers) is collected..."
printf "
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
" >> /etc/audit/rules.d/50-scope.rules
augenrules --load
overwrite "${YES} Ensured changes to system administration scope (sudoers) is collected"

echo -e "[ i ] Ensuring actions as another user are always logged..."
printf "
-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k
user_emulation
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k
user_emulation
" >> /etc/audit/rules.d/50-user_emulation.rules
augenrules --load
overwrite "${YES} Ensured actions as another user are always logged"
