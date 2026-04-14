#!/bin/bash
# Script permettant de faire comme l'installation de 
# 1-installation-securite-linux-standard-soc.txt mais en version automatique.


set -e

echo "[+] Updating system..."
apt update && apt upgrade -y

echo "[+] Installing dependencies..."
apt install -y curl gnupg apt-transport-https auditd audispd-plugins

# =========================

# ELASTIC STACK

# =========================

echo "[+] Installing Elasticsearch stack..."

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic.gpg

echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" \

> /etc/apt/sources.list.d/elastic.list

apt update
apt install -y elasticsearch kibana filebeat

systemctl enable elasticsearch --now
systemctl enable kibana --now
systemctl enable filebeat --now

# =========================

# FILEBEAT CONFIG

# =========================

echo "[+] Configuring Filebeat..."

cat <<EOF > /etc/filebeat/filebeat.yml
filebeat.inputs:

* type: log
  paths:

  * /var/log/syslog
  * /var/log/auth.log
  * /var/log/audit/audit.log

output.elasticsearch:
hosts: ["localhost:9200"]
EOF

systemctl restart filebeat

# =========================

# AUDITD RULES

# =========================

echo "[+] Configuring auditd..."

cat <<EOF > /etc/audit/rules.d/soc.rules
-w /etc/passwd -p r -k passwd_access
-w /proc -p r -k proc_scan
-w /dev/pts -p rwxa -k pts_access
-a always,exit -F arch=b64 -S execve -k exec_monitor
-a always,exit -F arch=b64 -S openat -k file_open
EOF

augenrules --load

# =========================

# FALCO INSTALL

# =========================

echo "[+] Installing Falco..."

curl -s https://falco.org/repo/falcosecurity-packages.asc | apt-key add -

echo "deb https://download.falco.org/packages/deb stable main" \

> /etc/apt/sources.list.d/falco.list

apt update
apt install -y falco

systemctl enable falco --now

# =========================

# FALCO RULES

# =========================

echo "[+] Adding Falco rules..."

cat <<EOF > /etc/falco/falco_rules.local.yaml

* rule: Suspicious proc access
  condition: open_read and fd.name startswith /proc and not proc.name in (ps, top, htop)
  output: "Suspicious /proc access (cmd=%proc.cmdline)"
  priority: WARNING

* rule: Hidden network activity
  condition: outbound and not proc.name in (curl, wget, ssh, apt)
  output: "Hidden network activity (cmd=%proc.cmdline)"
  priority: CRITICAL

* rule: Self deleting binary
  condition: evt.type=unlink and proc.exe exists
  output: "Self deleting binary detected"
  priority: CRITICAL
  EOF

systemctl restart falco

# =========================

# HARDENING

# =========================

echo "[+] Applying hardening..."

echo "kernel.io_uring_disabled = 1" >> /etc/sysctl.conf
echo "kernel.kptr_restrict=2" >> /etc/sysctl.conf
sysctl -p

echo "[+] SOC installation completed!"
echo "Access Kibana: http://localhost:5601"
