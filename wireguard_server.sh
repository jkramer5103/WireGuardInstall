#!/bin/bash

# Prüfen, ob das Skript mit Root-Rechten ausgeführt wird
if [[ $EUID -ne 0 ]]; then
   echo "Dieses Skript muss mit Root-Rechten ausgeführt werden" 
   exit 1
fi

# Standardwerte für Variablen
DEFAULT_WG_IPV4="10.0.0.1"
DEFAULT_WG_IPV6="fd42:42:42::1"
DEFAULT_WG_PORT="51820"
DEFAULT_WG_DNS="1.1.1.1,1.0.0.1"

# Einstellungen ohne Abfrage setzen
WG_IPV4="${WG_IPV4:-$DEFAULT_WG_IPV4}"
WG_IPV6="${WG_IPV6:-$DEFAULT_WG_IPV6}"
WG_PORT="${WG_PORT:-$DEFAULT_WG_PORT}"
WG_DNS="${WG_DNS:-$DEFAULT_WG_DNS}"

# Funktion, um Einstellungen im WireGuard-Konfigurationsdatei festzulegen
set_config() {
    sed -i "s/.*$1.*/$1 = $2/g" /etc/wireguard/wg0.conf
}

# Installation von WireGuard
echo "Installation von WireGuard..."
apt update
apt install -y wireguard qrencode

# Konfigurationsdatei für den WireGuard-Server erstellen
umask 077
mkdir -p /etc/wireguard/
touch /etc/wireguard/wg0.conf
WG_PRIV_KEY=$(wg genkey)
WG_PUB_KEY=$(echo $WG_PRIV_KEY | wg pubkey)
echo "[Interface]
PrivateKey = $WG_PRIV_KEY
Address = $WG_IPV4,$WG_IPV6
ListenPort = $WG_PORT" > /etc/wireguard/wg0.conf

# DNS-Server in der WireGuard-Konfigurationsdatei festlegen
echo "DNS = $WG_DNS" >> /etc/wireguard/wg0.conf

# WireGuard-Dienst starten
wg-quick up wg0
systemctl enable wg-quick@wg0

# Ausgabe der WireGuard-Konfiguration
echo "Konfigurationsdatei für den WireGuard-Client (/etc/wireguard/wg0.conf):"
cat /etc/wireguard/wg0.conf

# QR-Code für den Client erstellen
qrencode -t ansiutf8 < /etc/wireguard/wg0.conf

# Abschlussmeldung
echo "WireGuard wurde erfolgreich installiert und konfiguriert."
echo "Die Konfigurationsdatei wurde unter /etc/wireguard/wg0.conf gespeichert."
echo "Ein QR-Code für den WireGuard-Client wurde ebenfalls erstellt."
