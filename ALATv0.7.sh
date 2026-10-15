#!/usr/bin/env bash

# ==========================================================
# COLORS
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RESET='\033[0m'

# ==========================================================
# ROOT CHECK
# ==========================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Ova skripta mora biti pokrenuta kao root.${RESET}"
    exit 1
fi

# ==========================================================
# PACKAGE MANAGER
# ==========================================================

if command -v apt-get >/dev/null 2>&1; then
    PKG="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG="yum"
elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
else
    PKG="unknown"
fi

# ==========================================================
# BASIC FUNCTIONS
# ==========================================================

pause() {
    echo
    echo
    read -rp "Press ENTER to continue..."
}

header() {
    clear
    echo -e "${MAGENTA}"
    echo "=========================================================="
    echo "            ADVANCED LINUX ADMIN TOOLKIT v$VERSION            "
    echo -e "==========================================================${RESET}"
}

confirm() {
    while true; do
        read -rp "$1 [y/n]: " odgovor

        case "$odgovor" in
            [yY]|[yY][eE][sS])
                return 0
                ;;
            [nN]|[nN][oO])
                return 1
                ;;
            *)
                echo "Unesi y/yes ili n/no."
                ;;
        esac
    done
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ==========================================================
# SYSTEM INFO
# ==========================================================

system_info_cpu() {
    clear
    echo -e "${CYAN}========== CPU INFORMATION ==========${RESET}"
    echo
    echo "CPU cores : $(nproc)"
    echo
    lscpu 2>/dev/null | grep -E \
        'Model name|Socket|Core|Thread|CPU MHz|Architecture' \
        || true
    pause
}

system_info_ram() {
    clear
    echo -e "${CYAN}========== MEMORY INFORMATION ==========${RESET}"
    echo
    free --mega
    pause
}

system_info_disk() {
    clear
    echo -e "${CYAN}========== DISK INFORMATION USAGE ==========${RESET}"
    echo
    lsblk
    pause
}

system_info_os() {

    clear
    echo -e "${CYAN}========== OS INFORMATION ==========${RESET}"
    echo
    if [[ -f /etc/os-release ]]; then
        cat /etc/os-release
    fi
    echo
    echo "Kernel:"
    uname -a
    echo
    echo "Hostname:"
    hostname
    echo
    echo "Uptime:"
    uptime -p 2>/dev/null || uptime
    pause
}

system_info_network() {

    clear

    echo -e "${CYAN}========== NETWORK INFORMATION ==========${RESET}"
    echo

    ip -brief address

    echo
    echo "Default route:"
    ip route | grep default || true

    pause
}

system_info_menu() {
    while true; do
        header
        echo -e "${WHITE}====================== SYSTEM INFO =======================${RESET}"
        echo
        echo "1) CPU"
        echo "2) RAM"
        echo "3) Disk"
        echo "4) OS/Kernel/Hostname/Uptime"
        echo "5) Network"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) system_info_cpu ;;
            2) system_info_ram ;;
            3) system_info_disk ;;
            4) system_info_os ;;
            5) system_info_network ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# PROCESS MONITOR
# ==========================================================

process_cpu() {
    clear
    echo -e "${CYAN}========== TOP PROCESSES BY CPU ==========${RESET}"
    echo
    ps -eo pid,user,stat,comm,%cpu,%mem \
        --sort=-%cpu | head -n 21
    pause
}

process_ram() {
    clear
    echo -e "${CYAN}========== TOP PROCESSES BY RAM ==========${RESET}"
    echo
    ps -eo pid,user,stat,comm,%cpu,%mem \
        --sort=-%mem | head -n 21
    pause
}

process_load() {
    clear
    echo -e "${CYAN}========== LOAD AVERAGE ==========${RESET}"
    echo
    uptime
    pause
}

process_live() {
    clear
    echo -e "${CYAN}========== LIVE MONITOR ==========${RESET}"
    echo
    echo "CTRL+C za izlaz."
    echo
    if command_exists top; then
        top
    else
        echo "top nije instaliran."
        pause
    fi
}

process_live_cpu() {
    clear
    echo -e "${CYAN}========== LIVE CPU MONITOR ==========${RESET}"
    echo
    echo "CTRL+C za izlaz."
    echo
    if command_exists top; then
        top -o %CPU
    else
        echo "top nije instaliran."
        pause
    fi
}

process_live_ram() {
    clear
    echo -e "${CYAN}========== LIVE RAM MONITOR ==========${RESET}"
    echo
    echo "CTRL+C za izlaz."
    echo
    if command_exists top; then
        top -o %MEM
    else
        echo "top nije instaliran."
        pause
    fi
}

process_search() {
    clear
    echo -e "${CYAN}========== PROCESS SEARCH ==========${RESET}"
    echo
    read -rp "Unesi ime procesa: " process_name
    if [[ -z "$process_name" ]]; then
        echo "Nisi unio ime procesa."
        pause
        return
    fi
    echo
    echo "Rezultati:"
    echo
    ps aux | grep -i -- "$process_name" | grep -v grep || \
        echo "Proces nije pronađen."
    pause
}

process_kill() {
    clear
    echo -e "${YELLOW}========== PROCESS SEARCH & KILL ==========${RESET}"
    echo

    read -rp "Unesi ime procesa za pretragu: " process_name

    if [[ -z "$process_name" ]]; then
        echo "Nisi unio ime procesa."
        pause
        return
    fi

    echo
    echo "Rezultati pretrage:"
    echo

    ps aux | grep -i -- "$process_name" | grep -v grep

    if ! ps aux | grep -i -- "$process_name" | grep -v grep >/dev/null; then
        echo "Proces nije pronađen."
        pause
        return
    fi

    echo

    if ! confirm "Želiš li ubiti neki od pronađenih procesa?"; then
        pause
        return
    fi

    echo
    read -rp "Unesi PID procesa koji želiš ubiti: " process_pid

    if [[ -z "$process_pid" ]]; then
        echo "Nisi unio PID procesa."
        pause
        return
    fi

    if ! [[ "$process_pid" =~ ^[0-9]+$ ]]; then
        echo "PID mora biti broj."
        pause
        return
    fi

    if ! kill -0 "$process_pid" 2>/dev/null; then
        echo "Proces s PID-om $process_pid ne postoji."
        pause
        return
    fi

    echo
    if ! confirm "Sigurno želiš ugasiti proces PID $process_pid?"; then
        echo "Gašenje procesa otkazano."
        pause
        return
    fi

    if kill -9 "$process_pid" 2>/dev/null; then
        echo "Proces $process_pid je ugašen."
    else
        echo "Greška: nije moguće ugasiti proces $process_pid."
    fi

    pause
}

process_monitor() {
    while true; do
        header
        echo -e "${WHITE}==================== PROCESS MONITOR =====================${RESET}"
        echo
        echo "1) Top processes by CPU"
        echo "2) Top processes by RAM"
        echo "3) Load average"
        echo "4) Live monitor"
        echo "5) Live CPU monitor"
        echo "6) Live RAM monitor"
        echo "7) Search process"
        echo "8) Kill PID"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) process_cpu ;;
            2) process_ram ;;
            3) process_load ;;
            4) process_live ;;
            5) process_live_cpu ;;
            6) process_live_ram ;;
            7) process_search ;;
            8) process_kill ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# DISK ANALYSIS
# ==========================================================

disk_usage() {
    
    clear
    echo -e "${CYAN}========== DISK INFORMATION USAGE ==========${RESET}"
    echo
    df -hT
    echo
    echo
    echo -e "${CYAN}========== DISK INFORMATION INODES==========${RESET}"
    echo
    df -hi
    pause
}

disk_directories() {
    clear

    echo -e "${CYAN}========== LARGEST DIRECTORIES ==========${RESET}"
    echo
    echo -e "${WHITE}==== /var ====${RESET}"
    echo
    du -xh /var 2>/dev/null | sort -h | tail -n 20
    echo
    echo -e "${WHITE}==== /home ====${RESET}"
    echo
    if [[ -d /home ]]; then
        du -xh /home 2>/dev/null | sort -h | tail -n 20
    else
        echo -e "${RED}Direktorij /home ne postoji.${RESET}"
    fi
    echo
    echo -e "${WHITE}==== /opt ====${RESET}"
    echo
    if [[ -d /opt ]]; then
        du -xh /opt 2>/dev/null | sort -h | tail -n 20
    else
        echo -e "${RED}Direktorij /opt ne postoji.${RESET}"
    fi
    pause
}

disk_files() {
    clear

    echo -e "${CYAN}========== LARGEST FILES ==========${RESET}"
    echo

    echo "Traženje najvećih datoteka..."
    echo "Ovo može potrajati."
    echo

    find / \
        -xdev \
        -type f \
        -printf '%s %p\n' \
        2>/dev/null |
        sort -nr |
        head -n 20 |
        numfmt --field=1 --to=iec

    pause
}

find_file() {
    clear
    echo -e "${CYAN}========== FIND FILE BY NAME ==========${RESET}"
    echo

    read -rp "Unesi ime datoteke: " file_name

    if [[ -z "$file_name" ]]; then
        echo "Nisi unio ime datoteke."
        pause
        return
    fi

    echo
    echo "Pretražujem datoteke na serveru..."
    echo

    find / -type f -iname "*${file_name}*" 2>/dev/null

    pause
}

find_dir() {
    clear
    echo -e "${CYAN}========== FIND DIRECTORY BY NAME ==========${RESET}"
    echo

    read -rp "Unesi ime direktorija: " dir_name

    if [[ -z "$dir_name" ]]; then
        echo "Nisi unio ime direktorija."
        pause
        return
    fi

    echo
    echo "Pretražujem direktorije na serveru..."
    echo

    find / -type d -iname "*${dir_name}*" 2>/dev/null

    pause
}

disk_analysis() {
    while true; do
        header
        echo -e "${WHITE}===================== DISK ANALYSIS ======================${RESET}"
        echo
        echo "1) Disk usage"
        echo "2) Largest directories"
        echo "3) Largest files"
        echo "4) Find file"
        echo "5) Find directory"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) disk_usage ;;
            2) disk_directories ;;
            3) disk_files ;;
            4) find_file ;;
            5) find_dir ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# SERVICES
# ==========================================================

service_running() {
    echo -e "${MAGENTA}========== RUNNING SERVICES ==========${RESET}"
    echo

    systemctl list-units \
        --type=service \
        --state=running \
        --no-pager

    pause
}

service_failed() {
    echo -e "${RED}========== FAILED SERVICES ==========${RESET}"
    echo

    systemctl --failed --no-pager

    pause
}

service_manage() {
    local service query action choice rc cmd
    local -a matches=()
    local i

    clear

    while true; do
        echo -e "${CYAN}========== SERVICE MANAGEMENT ==========${RESET}"
        echo

        read -rp "Upiši ime servisa: " query

        # Provjera praznog unosa.
        if [[ -z "${query//[[:space:]]/}" ]]; then
            echo
            echo -e "${RED}[!]Neispravna opcija.${RESET}"
            pause
            return
        fi

        # Pretraži servise bez obzira na velika i mala slova.
        mapfile -t matches < <(
            {
                systemctl list-unit-files --type=service --no-legend --no-pager 2>/dev/null |
                    awk '{print $1}'

                systemctl list-units --all --type=service --no-legend --no-pager 2>/dev/null |
                    awk '{print $1}'
            } | sort -u | grep -iF -- "$query"
        )

        # Ako servis nije pronađen, vrati se u glavni izbornik.
        if (( ${#matches[@]} == 0 )); then
            echo
            echo -e "${RED}[!] Servis '$query' nije pronađen.${RESET}"
            pause
            return
        fi

        # Izbornik za odabir servisa.
        while true; do
            clear

            echo -e "${CYAN}========== SERVICE MANAGEMENT ==========${RESET}"
            echo
            echo "Pronađeni servisi:"
            echo

            for i in "${!matches[@]}"; do
                printf "%d) %s\n" "$((i + 1))" "${matches[$i]}"
            done

            echo "0) Natrag"
            echo

            read -rp "Odaberi servis: " choice

            # Povratak u glavni izbornik.
            if [[ "$choice" == "0" ]]; then
                return
            fi

            # Provjera valjanosti odabira.
            if [[ ! "$choice" =~ ^[0-9]+$ ]] ||
               (( choice < 1 || choice > ${#matches[@]} )); then
                echo
                echo -e "${RED}[!]Neispravna opcija.${RESET}"
                pause
                continue
            fi

            service="${matches[$((choice - 1))]}"
            break
        done

        # Izbornik akcija za odabrani servis.
        while true; do
            clear

            echo -e "${CYAN}========== SERVICE MANAGEMENT ==========${RESET}"
            echo
            echo "Odabrani servis: $service"
            echo
            echo "1) Status"
            echo "2) Start"
            echo "3) Stop"
            echo "4) Restart"
            echo "5) Enable"
            echo "6) Disable"
            echo "7) Chose another service"
            echo "0) Back"
            echo

            read -rp "Odaberi akciju: " action

            case "$action" in
                1)
                    systemctl status "$service" --no-pager
                    pause
                    ;;

                2|3|4|5|6)
                    case "$action" in
                        2) cmd="start" ;;
                        3) cmd="stop" ;;
                        4) cmd="restart" ;;
                        5) cmd="enable" ;;
                        6) cmd="disable" ;;
                    esac

                    if confirm "Izvršiti '$cmd' nad servisom '$service'?"; then
                        systemctl "$cmd" "$service"
                        rc=$?

                        if (( rc == 0 )); then
                            echo
                            echo -e "${GREEN}[+] Akcija '$cmd' uspješno izvršena.${RESET}"
                        else
                            echo
                            echo -e "${RED}[!] Akcija '$cmd' nije uspjela (kod: $rc).${RESET}"
                        fi

                        echo
                        systemctl status "$service" --no-pager

                    else
                        echo
                        echo -e "${RED}[!]Akcija '$cmd' je obustavljena.${RESET}"
                    fi

                    echo
                    pause
                    ;;

                7)
                    clear
                    break
                    ;;

                0)
                    return
                    ;;

                *)
                    echo
                    echo -e "${RED}[!] Neispravna opcija.${RESET}"
                    sleep 1
                    ;;
            esac
        done
    done
}

services_menu() {
    while true; do
        header
        echo -e "${WHITE}======================= SERVICES =========================${RESET}"
        echo
        echo "1) Running services"
        echo "2) Failed services"
        echo "3) Service Management"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) service_running ;;
            2) service_failed ;;
            3) service_manage ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# NETWORK
# ==========================================================

network_interfaces() {
    clear
    echo -e "${CYAN}========== NETWORK INTERFACES ==========${RESET}"
    echo
    ip -brief link
    pause
}

network_addresses() {
    clear
    echo -e "${CYAN}========== IP ADDRESSES ==========${RESET}"
    echo
    ip a
    pause
}

network_dns() {
    clear
    echo -e "${CYAN}========== DNS ==========${RESET}"
    echo
    cat /etc/resolv.conf
    pause
}

network_menu() {
    while true; do
        header
        echo -e "${WHITE}======================== NETWORK =========================${RESET}"
        echo
        echo "1) Interfaces"
        echo "2) IP addresses"
        echo "3) DNS"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) network_interfaces ;;
            2) network_addresses ;;
            3) network_dns ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# USER AUDIT
# ==========================================================

users_logged() {
    clear
    echo -e "${CYAN}========== LOGGED IN USERS ==========${RESET}"
    echo
    who
    echo
    echo "Active sessions:"
    w
    pause
}

users_all() {
    clear
    echo -e "${CYAN}========== ALL LOCAL USERS ==========${RESET}"
    echo

    printf "%-20s %-8s %-8s %-25s %s\n" \
        "USERNAME" "UID" "GID" "HOME" "SHELL"
    echo "--------------------------------------------------------------------------------"
    awk -F: '{
        printf "%-20s %-8s %-8s %-25s %s\n",
        $1, $3, $4, $6, $7
    }' /etc/passwd
    pause
}

users_search() {
    clear
    echo -e "${CYAN}========== USER SEARCH ==========${RESET}"
    echo
    read -rp "Unesi dio imena usera: " search_term
    if [[ -z "$search_term" ]]; then
        echo "Nisi unio tekst za pretragu."
        pause
        return
    fi
    echo
    echo "Pretraga za: $search_term"
    echo
    local found=0
    while IFS=: read -r username uid gid; do
        if [[ "${username,,}" == *"${search_term,,}"* ]]; then

            found=1
            

            echo -e "${WHITE}============================================================${RESET}"
            echo "Username : $username"
            echo "UID      : $uid"
            echo "GID      : $gid"
            echo
            echo "Groups:"
            id "$username" 2>/dev/null
            echo
            echo "Last login:"
            lastlog -u "$username" 2>/dev/null | tail -n 1
            echo -e "${WHITE}============================================================${RESET}"
            echo
            echo
        fi
    done < /etc/passwd

    if [[ "$found" -eq 0 ]]; then
        echo "Nijedan user nije pronađen."
    fi
    pause
}

users_wheel() {
    clear
    echo -e "${CYAN}========== SUDO / WHEEL GROUPS ==========${RESET}"
    echo
    echo "Grupe koje u imenu sadrže 'wheel':"
    echo

    local wheel_groups
    wheel_groups="$(getent group | awk -F: 'tolower($1) ~ /wheel/ {print $1}')"

    if [[ -z "$wheel_groups" ]]; then
        echo "Nijedna wheel grupa nije pronađena."
    else

        while read -r group; do

            [[ -z "$group" ]] && continue

            echo
            echo "Group: $group"
            echo "--------------------------------"

            getent group "$group"

        done <<< "$wheel_groups"

    fi

    echo
    echo "Sudo grupa:"

    if getent group sudo >/dev/null 2>&1; then
        echo "--------------------------------"
        getent group sudo
    else
        echo "--------------------------------"
        echo "sudo grupa nije pronađena."
    fi

    echo
    echo "Sudo konfiguracija:"
    echo

    grep -R "^[^#]" /etc/sudoers /etc/sudoers.d \
    2>/dev/null | grep -vE '^[^:]+:Defaults[[:space:]]' | head -n 50

    pause
}

users_menu() {
    while true; do
        header
        echo -e "${WHITE}========================= USERS ==========================${RESET}"
        echo
        echo "1) Logged-in users"
        echo "2) All users"
        echo "3) Search user"
        echo "4) Sudo / wheel groups"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in
            1) users_logged ;;
            2) users_all ;;
            3) users_search ;;
            4) users_wheel ;;
            0) return ;;
            *) echo -e "${RED}[!]Neispravna opcija.${RESET}"; sleep 1 ;;
        esac
    done
}

# ==========================================================
# SSH AUDIT
# ==========================================================

ssh_audit() {
    clear
    echo -e "${CYAN}========== SSH AUDIT ==========${RESET}"
    echo
    echo -e "${WHITE}========== RECENT LOGINS  ==========${RESET}"
    last -n 15 2>/dev/null

    echo
    echo -e "${WHITE}========== FAILED SSH AUTHENTICATION ==========${RESET}"
    journalctl -u ssh -u sshd \
        --since "24 hours ago" \
        --no-pager 2>/dev/null |
        grep -Ei "failed|invalid|authentication failure" |
        tail -30 || true
    pause
}

# ==========================================================
# SECURITY AUDIT
# ==========================================================

firewall_firewalld() {

    echo "Firewall status: running"
    echo
    echo "Backend: firewalld"
    echo

    local active_zones
    active_zones="$(firewall-cmd --get-active-zones 2>/dev/null)"

    if [[ -n "$active_zones" ]]; then
        echo "$active_zones"
    else
        echo "Active zones: none"
    fi

    echo

    local zones
    zones="$(firewall-cmd --get-active-zones 2>/dev/null |
        awk '/^[[:alnum:]_-]+$/ {print}')"

    if [[ -z "$zones" ]]; then
        zones="$(firewall-cmd --get-zones 2>/dev/null)"
    fi

    while read -r zone; do

        [[ -z "$zone" ]] && continue

        echo
        echo "$zone"
        echo "--------------------------------"

        firewall-cmd --zone="$zone" --list-all 2>/dev/null

    done <<< "$zones"
}

firewall_ufw() {

    local ufw_status

    ufw_status="$(ufw status 2>/dev/null | head -n 1)"

    if echo "$ufw_status" | grep -qi "active"; then

        echo "Firewall status: running"
        echo
        echo "Backend: ufw"
        echo
        echo "Status: active"

        echo
        echo "Default:"
        ufw status verbose 2>/dev/null |
            grep -i "Default:" ||
            echo "nije dostupno"

        echo
        echo "Rules"
        echo "--------------------------------"

        ufw status 2>/dev/null |
            tail -n +2

    else

        echo "Firewall status: stopped"
        echo
        echo "Backend: ufw"
        echo
        echo "Status: inactive"

    fi
}

firewall_iptables() {

    local rules

    rules="$(iptables -L -n -v 2>/dev/null)"

    if [[ -z "$rules" ]]; then

        echo "Firewall status: stopped"
        echo
        echo "Backend: iptables"
        echo
        echo "Nema aktivnih iptables pravila."

        return

    fi

    echo "Firewall status: running"
    echo
    echo "Backend: iptables"
    echo
    echo "iptables rules"
    echo "--------------------------------"

    echo "$rules"
}

firewall_nftables() {

    local rules

    rules="$(nft list ruleset 2>/dev/null)"

    if [[ -z "$rules" ]]; then

        echo "Firewall status: stopped"
        echo
        echo "Backend: nftables"
        echo
        echo "Nema aktivnog nftables ruleseta."

        return

    fi

    echo "Firewall status: running"
    echo
    echo "Backend: nftables"
    echo
    echo "nftables rules"
    echo "--------------------------------"

    echo "$rules"
}

firewall_audit() {

    echo -e "${WHITE}========== FIREWALL ==========${RESET}"
    echo

    # ------------------------------------------------------
    # FIREWALLD
    # ------------------------------------------------------

    if command_exists firewall-cmd; then

        if systemctl is-active --quiet firewalld 2>/dev/null; then
            firewall_firewalld
        else
            echo "Firewall status: stopped"
            echo
            echo "Backend: firewalld"
        fi

        return
    fi

    # ------------------------------------------------------
    # UFW
    # ------------------------------------------------------

    if command_exists ufw; then
        firewall_ufw
        return
    fi

    # ------------------------------------------------------
    # IPTABLES
    # ------------------------------------------------------

    if command_exists iptables; then
        firewall_iptables
        return
    fi

    # ------------------------------------------------------
    # NFTABLES
    # ------------------------------------------------------

    if command_exists nft; then
        firewall_nftables
        return
    fi

    # ------------------------------------------------------
    # NOTHING FOUND
    # ------------------------------------------------------

    echo "Firewall status: not installed"
}

selinux_audit() {

    echo -e "${WHITE}========== SELINUX ==========${RESET}"
    echo

    if ! command_exists getenforce &&
       [[ ! -f /sys/fs/selinux/enforce ]]; then

        echo "SELinux status: not installed"
        return
    fi

    if command_exists getenforce; then

        local selinux_mode
        selinux_mode="$(getenforce 2>/dev/null)"

        case "$selinux_mode" in

            Enforcing)
                echo "SELinux status: enabled"
                echo "Mode: enforcing"
                ;;

            Permissive)
                echo "SELinux status: enabled"
                echo "Mode: permissive"
                ;;

            Disabled)
                echo "SELinux status: disabled"
                ;;

            *)
                echo "SELinux status: unknown"
                ;;

        esac

    else

        if [[ -f /sys/fs/selinux/enforce ]]; then

            local enforce_value
            enforce_value="$(cat /sys/fs/selinux/enforce 2>/dev/null)"

            if [[ "$enforce_value" == "1" ]]; then
                echo "SELinux status: enabled"
                echo "Mode: enforcing"
            else
                echo "SELinux status: enabled"
                echo "Mode: permissive"
            fi

        else
            echo "SELinux status: disabled"
        fi

    fi
}

security_audit() {

    clear

    echo -e "${CYAN}========== SECURITY AUDIT ==========${RESET}"
    echo
    echo
    firewall_audit
    echo
    echo
    selinux_audit

    pause
}

# ==========================================================
# PACKAGE MANAGER
# ==========================================================

package_update() {

    clear
    echo -e "${YELLOW}========== UPDATE SYSTEM ==========${RESET}"
    echo
    echo "Package manager: $PKG"
    echo

    if ! confirm "Želiš ažurirati sistem?"; then
        echo
        echo -e "${RED}[!]Task canceled.${RESET}";
        pause
        return
    fi

    case "$PKG" in

        apt)
            apt update
            apt upgrade
            ;;

        dnf)
            dnf upgrade
            ;;

        yum)
            yum update
            ;;

        pacman)
            pacman -Syu
            ;;

        *)
            echo "Nepoznat package manager."
            ;;

    esac

    pause
}

cleanup() {

    clear

    echo -e "${YELLOW}========== SYSTEM CLEANUP ==========${RESET}"
    echo

    echo "Ova funkcija može obrisati package cache i stare journal logove."
    echo

    if ! confirm "Nastaviti s cleanupom?"; then
        echo
        echo -e "${RED}[!]Task canceled.${RESET}";
        return
    fi

    case "$PKG" in

        apt)
            apt clean
            apt autoremove
            ;;

        dnf)
            dnf clean all
            dnf autoremove
            ;;

        yum)
            yum clean all
            ;;

        pacman)
            if command_exists paccache; then
                paccache -r
            else
                echo "paccache nije instaliran."
            fi
            ;;

        *)
            echo "Nepoznat package manager."
            ;;

    esac

    journalctl --vacuum-time=14d 2>/dev/null || true

    echo
    echo -e "${GREEN}[+] Cleanup finished.${RESET}"

    pause
}

list_packages() {
    
    local HOSTNAME
    local FILE

    HOSTNAME=$(hostname)
    FILE="/tmp/list_packages_${HOSTNAME}.txt"

    clear
    echo -e "${WHITE}========== INSTALLED PACKAGES ==========${RESET}"
    echo
    if ! confirm "Želiš spremiti popis paketa u $FILE?"; then
        echo
        echo -e "${RED}[!]Task canceled.${RESET}";
        pause
        return
    fi

    case "$PKG" in
        apt)
            dpkg-query -W -f='${binary:Package}\n' > "$FILE"
            ;;
        dnf|yum)
            rpm -qa --qf '%{NAME}\n' > "$FILE"
            ;;
        pacman)
            pacman -Qq > "$FILE"
            ;;
        apk)
            apk info > "$FILE"
            ;;
        zypper)
            rpm -qa --qf '%{NAME}\n' > "$FILE"
            ;;
        *)
            echo "Nepoznat package manager: $PKG"
            pause
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        chmod 775 "$FILE" || {
            echo "Greška pri postavljanju prava na file."
            pause
            return 1
        }

        echo
        echo "Datoteka: $FILE"
        echo "Broj paketa: $(wc -l < "$FILE")"
        echo
        echo -e "${GREEN}[+] Popis paketa uspješno spremljen!${RESET}"
        
    else
        echo -e "${RED}[!]Greška prilikom izlistavanja paketa.${RESET}"
        rm -f "$FILE"
        pause
        return 1
    fi

    pause
}

package_menu() {

    while true; do

        header
        echo -e "${WHITE}==================== PACKAGE MANAGER =====================${RESET}"
        echo
        echo "1) Update system"
        echo "2) Cleanup"
        echo "3) List packages"
        echo "0) Back"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice

        case "$choice" in

            1) package_update ;;
            2) cleanup ;;
            3) list_packages ;;
            0) return ;;
            *)
                echo -e "${RED}[!]Neispravna opcija.${RESET}"
                sleep 1
                ;;

        esac

    done
}

# ==========================================================
# MAIN MENU
# ==========================================================

main_menu() {

    while true; do

        header
        echo -e "${WHITE}======================= MAIN MENU ========================${RESET}"
        echo
        echo "1) System Info"
        echo "2) Process Monitor"
        echo "3) Disk Analysis"
        echo "4) Services"
        echo "5) Network"
        echo "6) Users"
        echo "7) SSH Audit"
        echo "8) Security Audit"
        echo "9) Package Manager"
        echo "0) Exit"
        echo
        echo -e "${WHITE}==========================================================${RESET}"
        echo -e "${MAGENTA}==========================================================${RESET}"
        echo
        read -rp "Chose option: " choice
        
        case "$choice" in

            1) system_info_menu ;;
            2) process_monitor ;;
            3) disk_analysis ;;
            4) services_menu ;;
            5) network_menu ;;
            6) users_menu ;;
            7) ssh_audit ;;
            8) security_audit ;;
            9) package_menu ;;
            0) clear
                echo -e "${GREEN}[+]ALAT closed.${RESET}"
                exit 0
                ;;

            *)
                echo -e "${RED}[!]Neispravna opcija.${RESET}"
                sleep 1
                ;;
        esac
            
    done
}

# ==========================================================
# START
# ==========================================================

set -u
VERSION="0.7"
main_menu