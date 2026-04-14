# Security-Linux-scripts
Les scripts permettant d'avoir une securité plus efficace sur les systemes linux



====

Ce script nommé script-anti-Ring-Reaper.sh
permet une stratégie de défense efficace (adaptée pour Debian 13) : 

- détecte usage suspect de io_uring
- surveille accès sensibles
- bloque comportements anormaux simples
- renforce le système


Pour une capacité :

- Désactivation / restriction de io_uring
- Détection comportementale
- Surveillance kernel (eBPF / auditd)
- Hardening système

Bloquer io_uring (radical mais efficace)

Ajoute au kernel boot :

`echo "kernel.io_uring_disabled = 1" >> /etc/sysctl.conf`
`sysctl -p`

Utiliser AppArmor / SELinux
RingReaper contourne les syscalls → il faut du contrôle kernel-level


Pour aller encore plus loin l'ideale serai : 
Si tu veux une vraie défense solide :

- auditd + eBPF
- AppArmor strict
- journald + SIEM
- désactivation io_uring si possible
- un monitoring comportemental (Falco, Tetragon)

====

Note : un simple antivirus ou script basé sur logs classiques ne suffit pas.
