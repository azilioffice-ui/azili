#!/usr/bin/env bash
# Home Assistant + Mosquitto + Zigbee2MQTT kurulumu. Tekrar çalıştırmak güvenlidir.
# Kullanım: bash scripts/kurulum.sh
set -euo pipefail
cd "$(dirname "$0")/.."

hata() { echo "HATA: $*" >&2; exit 1; }

[ "$(uname -m)" = "aarch64" ] || echo "UYARI: 64-bit sistem değil ($(uname -m)). Raspberry Pi OS 64-bit önerilir."
command -v docker >/dev/null || hata "Docker kurulu değil."
docker compose version >/dev/null 2>&1 || hata "docker compose eklentisi yok."
docker info >/dev/null 2>&1 || hata "Docker'a erişilemiyor. 'sudo usermod -aG docker \$USER' sonra yeniden giriş yap."

# .env oluştur
if [ ! -f .env ]; then
  cp .env.example .env
  sed -i "s|^MQTT_PASSWORD=.*|MQTT_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)|" .env
  echo ".env oluşturuldu (MQTT şifresi otomatik üretildi)."
fi

# Zigbee çubuğunu bul
if grep -q 'BURAYA-CUBUK-ADI' .env; then
  mapfile -t cubuklar < <(ls /dev/serial/by-id/ 2>/dev/null || true)
  if [ "${#cubuklar[@]}" -eq 1 ]; then
    sed -i "s|^ZIGBEE_ADAPTER=.*|ZIGBEE_ADAPTER=/dev/serial/by-id/${cubuklar[0]}|" .env
    echo "Zigbee çubuğu bulundu: ${cubuklar[0]}"
    case "${cubuklar[0]}" in
      *ZBDongle-E*|*EFR32*|*SkyConnect*|*Connect_ZBT*) sed -i 's|^ZIGBEE_ADAPTER_TYPE=.*|ZIGBEE_ADAPTER_TYPE=ember|' .env ;;
      *ConBee*|*dresden*) sed -i 's|^ZIGBEE_ADAPTER_TYPE=.*|ZIGBEE_ADAPTER_TYPE=deconz|' .env ;;
    esac
  elif [ "${#cubuklar[@]}" -eq 0 ]; then
    echo "UYARI: Zigbee USB çubuğu bulunamadı. Şimdilik Zigbee2MQTT kurulmadan devam ediliyor."
    echo "       Çubuğu taktıktan sonra bu scripti tekrar çalıştır."
  else
    printf '  %s\n' "${cubuklar[@]}"
    hata "Birden fazla USB seri cihaz var. .env içinde ZIGBEE_ADAPTER'ı elle ayarla."
  fi
fi

set -a; . ./.env; set +a
if grep -q 'BURAYA-CUBUK-ADI' .env; then
  servisler=(homeassistant mosquitto)
else
  [ -e "$ZIGBEE_ADAPTER" ] || hata "$ZIGBEE_ADAPTER bulunamadı. Çubuk takılı mı? .env dosyasını kontrol et."
  echo "Zigbee çubuk tipi: $ZIGBEE_ADAPTER_TYPE (yanlışsa .env içinden değiştir)"
  servisler=(homeassistant mosquitto zigbee2mqtt)
fi

# Klasörler ve Zigbee2MQTT ayarı
mkdir -p homeassistant/config mosquitto/data mosquitto/log zigbee2mqtt/data
[ -f zigbee2mqtt/data/configuration.yaml ] || cp zigbee2mqtt/configuration.template.yaml zigbee2mqtt/data/configuration.yaml

# Mosquitto şifre dosyası (her çalıştırmada .env ile eşitlenir)
docker compose run --rm --no-deps mosquitto \
  mosquitto_passwd -b -c /mosquitto/config/passwd "$MQTT_USER" "$MQTT_PASSWORD"

docker compose pull "${servisler[@]}"
docker compose up -d "${servisler[@]}"

ip=$(hostname -I | awk '{print $1}')
cat <<MSG

Kurulum tamam.
  Home Assistant : http://$ip:8123   (ilk açılış birkaç dakika sürebilir)
  Zigbee2MQTT    : $( [ "${#servisler[@]}" -eq 3 ] && echo "http://$ip:8080" || echo "kurulmadı (Zigbee çubuğu yok)")
  MQTT (HA için) : sunucu 127.0.0.1, port 1883, kullanıcı $MQTT_USER, şifre .env içinde
MSG
