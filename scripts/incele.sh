#!/usr/bin/env bash
# Pi'nin durumunu raporlar. Şifre veya gizli bilgi toplamaz.
# Kullanım: bash scripts/incele.sh
section() { printf '\n== %s ==\n' "$1"; }

section SISTEM
uname -a
grep -E '^(PRETTY_NAME|VERSION_CODENAME)=' /etc/os-release
echo "Mimari: $(uname -m)  (aarch64 olmalı = 64-bit)"
tr -d '\0' < /proc/device-tree/model 2>/dev/null; echo
echo "CPU: $(nproc) çekirdek"
free -h
df -h /
command -v vcgencmd >/dev/null && vcgencmd measure_temp && vcgencmd get_throttled

section DOCKER
if command -v docker >/dev/null; then
  docker version --format 'Docker: {{.Server.Version}}' 2>&1
  docker compose version 2>&1
  id -nG | grep -qw docker && echo "Kullanıcı docker grubunda: evet" || echo "Kullanıcı docker grubunda: HAYIR (sudo gerekebilir)"
  docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>&1
else
  echo "Docker kurulu değil"
fi

section AG
hostname -I
ip -4 route | grep default
for p in 1883 8080 8123; do
  (ss -ltn 2>/dev/null | grep -q ":$p ") && echo "Port $p: KULLANIMDA" || echo "Port $p: boş"
done

section USB
lsusb 2>/dev/null
ls -l /dev/serial/by-id/ 2>/dev/null || echo "USB seri cihaz (Zigbee çubuğu) bulunamadı"
