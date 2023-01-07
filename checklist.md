# Checklist

## 1. Forensic Questions

- Solve the forensic questions. These may rely on files or programs you will eventually delete, which is why we do them first.

## 2. Updates

- Open the Software app and download all available updates.

### Automatic updates

- Run `sudo dnf install dnf-automatic` to install the automatic updater
- Run `env EDITOR='gedit -w' sudoedit /etc/dnf/automatic.conf` and change `apply_updates` to `yes` so that updates are automatically installed after being downloaded
- Run `systemctl enable --now dnf-automatic.timer` to enable the automatic update process

## 3. Services

- Run `systemctl list-units --type=service` to list all active system services

## 4. Check Ports

- Run `sudo lsof -i -P -n | grep -v "(ESTABLISHED)"`
- Review the output to ensure that all services listed are required on the system. If a listed service is not required, remove the package containing the service. If the package containing the service is required, stop and mask the service

## 5. Rootkits and malware

- Run `sudo dnf install rkhunter` to install Rootkit Hunter
- Run `sudo rkhunter --update` to ensure Rootkit Hunter has the latest information
- Run Rootkit Hunter with `sudo rkhunter -c`
