#!/bin/bash

# ============================
# RingReaper Defense Script
# Systeme : Debian 13
# Creer par indomptablebBar
# ============================

LOGFILE="/var/log/ringreaper_defense.log"

echo "[+] Starting RingReaper defense..." | tee -a $LOGFILE

# 1. Vérifier modules io_uring
echo "[+] Checking io_uring usage..." | tee -a $LOGFILE
lsmod | grep io_uring >> $LOGFILE

# Option : désactivation (si non critique)
if lsmod | grep -q io_uring; then
    echo "[!] io_uring detected - consider disabling" | tee -a $LOGFILE
fi

# 2. Détection accès suspects à /proc
echo "[+] Monitoring suspicious /proc access..." | tee -a $LOGFILE

find /proc/*/fd -type l 2>/dev/null | while read f; do
    target=$(readlink $f)
    if [[ "$target" == *"passwd"* ]]; then
        echo "[ALERT] Suspicious passwd access via $f" | tee -a $LOGFILE
    fi
done

# 3. Process suspects (pas de commande classique)
echo "[+] Checking suspicious processes..." | tee -a $LOGFILE

ps aux --sort=-%cpu | head -20 | while read line; do
    if [[ "$line" != *"bash"* && "$line" != *"systemd"* ]]; then
        echo "[INFO] Process: $line" >> $LOGFILE
    fi
done

# 4. Détection binaire auto-supprimé
echo "[+] Checking deleted binaries..." | tee -a $LOGFILE

lsof | grep deleted | tee -a $LOGFILE

# 5. Audit règles (si auditd installé)
echo "[+] Setting audit rules..." | tee -a $LOGFILE

auditctl -w /etc/passwd -p r -k passwd_watch 2>/dev/null
auditctl -w /proc -p r -k proc_watch 2>/dev/null

# 6. Permissions critiques
echo "[+] Hardening permissions..." | tee -a $LOGFILE

chmod 640 /etc/passwd
chmod 600 /etc/shadow

# 7. Détection SUID suspects
echo "[+] Scanning SUID binaries..." | tee -a $LOGFILE

find / -perm -4000 -type f 2>/dev/null | tee -a $LOGFILE

echo "[+] Defense scan completed." | tee -a $LOGFILE 
