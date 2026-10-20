#!/bin/bash

# Require one argument: beforePatch or afterPatch
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 {beforePatch|afterPatch}"
    exit 1
fi

OUTPUT_DIR="$1"

# Only allow the expected directory names
case "$OUTPUT_DIR" in
    beforePatch|afterPatch)
        ;;
    *)
        echo "Error: Invalid argument '$OUTPUT_DIR'."
        echo "Usage: $0 {beforePatch|afterPatch}"
        exit 1
        ;;
esac

# Create the selected directory if it does not exist
if ! mkdir -p "$OUTPUT_DIR"; then
    echo "Error: Unable to create directory: $OUTPUT_DIR"
    exit 1
fi

# Emit the common report header to stdout.
emit_header() {
    echo "Patch validation report"
    echo "Collection type : $OUTPUT_DIR"
    echo "Collection date : $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Executed by     : $(whoami)"
    echo
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# ---------------------------------------------------------------------------
# Group 0: Hardware
# ---------------------------------------------------------------------------
{
    emit_header "HARDWARE & DEVICES"

    echo "========================================"
    echo "PCI DEVICES"
    echo "========================================"
    lspci -vv 2>/dev/null || lspci

    echo
    echo "========================================"
    echo "HARDWARE INVENTORY"
    echo "========================================"
    lshw -short 2>/dev/null || lshw

    echo
    echo "========================================"
    echo "DKMS STATUS"
    echo "========================================"
    if command -v dkms >/dev/null 2>&1; then
        dkms status
    else
        echo "dkms command is not available."
    fi
    
    echo
    echo "========================================"
    echo "GPU STATUS"
    echo "========================================"
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi
    else
        echo "nvidia-smi is not available."
    fi

    echo
    echo "========================================"
    echo "LOADED KERNEL MODULES"
    echo "========================================"
    lsmod

} > "$OUTPUT_DIR/00-hardware.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 1: Host & Kernel
# ---------------------------------------------------------------------------
{
    emit_header "HOST & KERNEL"

    echo
    echo "========================================"
    echo "HOSTNAME"
    echo "========================================"
    hostname

    echo
    echo "========================================"
    echo "HOST INFORMATION"
    echo "========================================"
    hostnamectl

    echo
    echo "========================================"
    echo "TIME SYNCHRONIZATION"
    echo "========================================"
    date
    timedatectl
    chronyc tracking 2>/dev/null
    chronyc sources -v 2>/dev/null

    echo
    echo "========================================"
    echo "RED HAT RELEASE"
    echo "========================================"
    cat /etc/redhat-release
    cat /etc/os-release

    echo
    echo "========================================"
    echo "RUNNING KERNEL"
    echo "========================================"
    uname -r
    uname -a

    echo
    echo "========================================"
    echo "INSTALLED KERNEL PACKAGES"
    echo "========================================"
    rpm -qa | grep kernel | sort

    echo
    echo "========================================"
    echo "GRUB KERNEL INFORMATION"
    echo "========================================"
    if command -v grubby >/dev/null 2>&1; then
        grubby --info=ALL
    else
        echo "grubby command is not available."
    fi

    echo
    echo "========================================"
    echo "RPM DATABASE CHECK"
    echo "========================================"
    rpm -qa > /dev/null
    echo "RPM query return code: $?"

    echo
    echo "========================================"
    echo "/BOOT DIRECTORY"
    echo "========================================"
    ls -la /boot

    echo
    echo "========================================"
    echo "SUBSCRIPTION MANAGER STATUS"
    echo "========================================"
    subscription-manager identity
    subscription-manager status
    subscription-manager list
    subscription-manager list --consumed

} > "$OUTPUT_DIR/01-host-kernel.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 2: Storage
# ---------------------------------------------------------------------------
{
    emit_header "STORAGE"

    echo
    echo "========================================"
    echo "LOGs and LIBs"
    echo "========================================"
    ls -al /var/lib
    ls -al /var/log

    echo
    echo "========================================"
    echo "LVM INFORMATION"
    echo "========================================"
    pvs
    vgs
    lvs

    echo
    echo "========================================"
    echo "MOUNT INFORMATION"
    echo "========================================"
    mount

    echo
    echo "========================================"
    echo "FSTAB"
    echo "========================================"
    cat /etc/fstab

    echo
    echo "========================================"
    echo "FILESYSTEM USAGE"
    echo "========================================"
    df -h

    echo
    echo "========================================"
    echo "TOP DISK CONSUMERS"
    echo "========================================"
    du -xh / --max-depth=1 2>/dev/null | sort -hr
    du -xh /var --max-depth=1 2>/dev/null | sort -hr
    du -xh /opt --max-depth=1 2>/dev/null | sort -hr
    du -xh /boot --max-depth=1 2>/dev/null | sort -hr ## need to check if dir is full or not
    ## add dependency check must have before patch, 
    ## disk, repo, ssh, network dns resolver, boot, yum/dnf repo, mcafee,......

} > "$OUTPUT_DIR/02-storage.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 3: Resources
# ---------------------------------------------------------------------------
{
    emit_header "RESOURCES"

    echo
    echo "========================================"
    echo "MEMORY UTILIZATION"
    echo "========================================"
    free -h

    echo
    echo "========================================"
    echo "SWAP INFORMATION"
    echo "========================================"
    cat /proc/swaps
    swapon --show

    echo
    echo "========================================"
    echo "CPU INFORMATION"
    echo "========================================"
    lscpu
    nproc

} > "$OUTPUT_DIR/03-resources.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 4: Networking
# ---------------------------------------------------------------------------
{
    emit_header "NETWORKING"

    echo "========================================"
    echo "ETHERNET INTERFACE STATUS"
    echo "========================================"
    ip -br link
    nmcli device status

    echo "========================================"
    echo "NETWORK CONNECTIONS"
    echo "========================================"
    nmcli connection show

    echo "========================================"
    echo "NETWORK DEVICE DETAILS"
    echo "========================================"
    nmcli device show

    echo
    echo "========================================"
    echo "IP ADDRESS"
    echo "========================================"
    ip addr

    echo
    echo "========================================"
    echo "ROUTING TABLE"
    echo "========================================"
    ip route
    route -n

    echo
    echo "DNS CONFIGURATION"
    echo "========================================"
    cat /etc/resolv.conf
    resolvectl status

} > "$OUTPUT_DIR/04-network.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 5: Security
# ---------------------------------------------------------------------------
{
    emit_header "SECURITY"

    echo
    echo "========================================"
    echo "REALM INFORMATION"
    echo "========================================"
    realm list

    echo
    echo "========================================"
    echo "SSH CONFIGURATION"
    echo "========================================"
    cat /etc/ssh/sshd_config

    echo
    echo "========================================"
    echo "FIREWALL STATUS"
    echo "========================================"
    systemctl is-active firewalld
    firewall-cmd --list-all 2>/dev/null
    firewall-cmd --list-all-zones 2>/dev/null

    echo
    echo "========================================"
    echo "LISTENING PORTS"
    echo "========================================"
    ss -tulpn

    echo
    echo "========================================"
    echo "SELinux status"
    echo "========================================"
    sestatus
    getenforce
    grep ^SELINUX= /etc/selinux/config

} > "$OUTPUT_DIR/05-security.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 6: Services
# ---------------------------------------------------------------------------
{
    emit_header "SERVICES"

    echo
    echo "========================================"
    echo "RUNNING SERVICES"
    echo "========================================"
    systemctl list-units --type=service --state=running --no-pager

    echo
    echo "========================================"
    echo "RECENT ERRORS FROM CURRENT BOOT"
    echo "========================================"
    journalctl -p err -b --since "15 minutes ago" --no-pager

    echo
    echo "========================================"
    echo "CONTAINER STATUS"
    echo "========================================"
    docker ps -a
    #echoDocker check is disabled in this script

    echo
    echo "========================================"
    echo "FAILED SYSTEMD UNITS"
    echo "========================================"
    systemctl --failed --no-pager

    echo
    echo "========================================"
    echo "ALL SERVICEs STATUS"
    echo "========================================"
    for svc in $(systemctl list-units --type=service --state=running --no-legend --no-pager --plain | awk '{print $1}'); do
        echo "--- $svc ---"
        systemctl status "$svc" --no-pager --lines=10 2>/dev/null
    done

} > "$OUTPUT_DIR/06-services.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 7: Packages
# ---------------------------------------------------------------------------
{
    emit_header "PACKAGES"

    echo
    echo "========================================"
    echo "REPOSITORY LIST"
    echo "========================================"
    ls -la /etc/yum.repos.d
    dnf repolist --all

    echo
    echo "========================================"
    echo "MODULES LIST"
    echo "========================================"
    dnf module list

    echo
    echo "========================================"
    echo "INSTALLONLY PACKAGES"
    echo "========================================"
    dnf repoquery --installonly --latest-limit=-1

    echo
    echo "========================================"
    echo "DUPLICATE PACKAGES"
    echo "========================================"
    dnf repoquery --duplicates

    echo
    echo "========================================"
    echo "EXTRA PACKAGES"
    echo "========================================"
    dnf repoquery --extras

    echo
    echo "========================================"
    echo "UNNEEDED PACKAGES"
    echo "========================================"
    dnf repoquery --unneeded

    echo
    echo "========================================"
    echo "Installed packages full list"
    echo "========================================"
    rpm -qa --last

} > "$OUTPUT_DIR/07-packages.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 8: Runtime
# ---------------------------------------------------------------------------
{
    emit_header "RUNTIME"

    echo
    echo "========================================"
    echo "REBOOT REQUIREMENT"
    echo "========================================"
    if command -v needs-restarting >/dev/null 2>&1; then
        needs-restarting -r
        REBOOT_RC=$?

        case "$REBOOT_RC" in
            0)
                echo "Result: A reboot is not required."
                ;;
            1)
                echo "Result: A reboot is required."
                ;;
            *)
                echo "Result: Unable to determine reboot requirement."
                ;;
        esac
    else
        echo "needs-restarting command is not available."
    fi

    echo
    echo "========================================"
    echo "JAVA INFORMATION"
    echo "========================================"
    java -version
    javac -version
    #echoJava checks are disabled in this script

    echo "========================================"
    echo "PYTHON INFORMATION"
    echo "========================================"
    which python
    python --version 2>/dev/null
    which python3
    python3 --version 2>/dev/null

    echo "========================================"
    echo "Check cron job"
    echo "========================================"
    for user in $(cut -f1 -d: /etc/passwd); do echo "=== User: $user ==="; sudo crontab -u "$user" -l 2>/dev/null; done

    echo "========================================"
    echo "Sysctl information and limits"
    echo "========================================"
    ulimit -a
    sysctl -a

    echo
    echo "========================================"
    echo "END OF REPORT"
    echo "========================================"

} > "$OUTPUT_DIR/08-runtime.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 9: Users, Groups, Sudoers
# ---------------------------------------------------------------------------
{
    emit_header "USERS, GROUPS, SUDOERS"

    echo "========================================"
    echo "USERS"
    echo "========================================"
    cat /etc/passwd

    echo
    echo "========================================"
    echo "GROUPS"
    echo "========================================"
    cat /etc/group

    echo
    echo "========================================"
    echo "USER ACCOUNTS WITH LOGIN SHELL"
    echo "========================================"
    getent passwd | awk -F: '$7 ~ /bash|sh$/ {print}'

    echo
    echo "========================================"
    echo "SUDOERS"
    echo "========================================"
    cat /etc/sudoers
    ls -al /etc/sudoers.d/
    for f in /etc/sudoers.d/*; do echo "--- $f ---"; cat "$f" 2>/dev/null; done

    echo
    echo "========================================"
    echo "CURRENT USERS LOGGED IN"
    echo "========================================"
    who
    lastlog

    echo
    echo "========================================"
    echo "FOLDER PERMISSIONS"
    echo "========================================"
    ls -ld / /home /var /opt /etc /usr /tmp
    ls -la /home

} > "$OUTPUT_DIR/09-users-groups-sudoers.txt" 2>&1

# ---------------------------------------------------------------------------
# Group 10: Folder Permissions
# ---------------------------------------------------------------------------
{
    echo "========================================"
    echo "FOLDER PERMISSIONS"
    echo "========================================"
    df -hP | awk 'NR>1 {print $NF}' | while read -r mp; do
        echo "===== $mp ====="
        stat -c '%A %a %U:%G %n' "$mp"
        find "$mp" -mindepth 1 -maxdepth 1 -type d \
            -exec stat -c '%A %a %U:%G %n' {} \; 2>/dev/null
    done

} > "$OUTPUT_DIR/10-folder-permissions.txt" 2>&1

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
PART_FILES=(
    "$OUTPUT_DIR/00-hardware.txt"
    "$OUTPUT_DIR/01-host-kernel.txt"
    "$OUTPUT_DIR/02-storage.txt"
    "$OUTPUT_DIR/03-resources.txt"
    "$OUTPUT_DIR/04-network.txt"
    "$OUTPUT_DIR/05-security.txt"
    "$OUTPUT_DIR/06-services.txt"
    "$OUTPUT_DIR/07-packages.txt"
    "$OUTPUT_DIR/08-runtime.txt"
    "$OUTPUT_DIR/09-users-groups-sudoers.txt"
    "$OUTPUT_DIR/10-folder-permissions.txt"
)

echo "Information successfully collected."
echo "Reports written to: $OUTPUT_DIR"
echo
printf "%-30s %12s\n" "PART FILE" "SIZE"
printf "%-30s %12s\n" "---------" "----"
for f in "${PART_FILES[@]}"; do
    if [[ -s "$f" ]]; then
        printf "%-30s %12s\n" "$(basename "$f")" "$(du -h "$f" | cut -f1)"
    else
        printf "%-30s %12s\n" "$(basename "$f")" "MISSING"
    fi
done