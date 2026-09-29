# Azili — Dükkan Akıllı Ev Sistemi

Raspberry Pi 4 üzerinde Docker ile çalışır:

| Servis | Görevi | Adres |
|---|---|---|
| Home Assistant | Ana kontrol paneli ve otomasyonlar | `http://<pi-ip>:8123` |
| Zigbee2MQTT | Zigbee cihazlarını USB çubuk üzerinden yönetir | `http://<pi-ip>:8080` |
| Mosquitto | Zigbee2MQTT ile Home Assistant arasındaki MQTT sunucusu | port `1883` |

## Gerekenler

- Raspberry Pi OS **64-bit** (Bookworm veya sonrası), Docker ve `docker compose`
- Zigbee USB çubuğu (ör. Sonoff ZBDongle-P / ZBDongle-E). Parazit olmaması için
  bir USB uzatma kablosuyla Pi'den ve USB 3 (mavi) portlardan uzak tut.

## Kurulum

```bash
git clone https://github.com/azilioffice-ui/azili.git
cd azili
bash scripts/incele.sh     # önce sistemi kontrol et
bash scripts/kurulum.sh    # sonra kur
```

`kurulum.sh` şunları yapar:
1. `.env` dosyasını oluşturur, MQTT şifresini rastgele üretir
2. Zigbee çubuğunu `/dev/serial/by-id/` altında bulur, tipini tahmin eder
3. Mosquitto kullanıcısını oluşturur, tüm servisleri başlatır

## Kurulumdan sonra

1. `http://<pi-ip>:8123` adresinden Home Assistant hesabını oluştur.
2. **Ayarlar → Cihazlar ve Servisler → Entegrasyon ekle → MQTT**
   - Sunucu: `127.0.0.1`, port `1883`
   - Kullanıcı / şifre: `.env` içindeki `MQTT_USER` / `MQTT_PASSWORD`
3. Zigbee cihaz eklemek için `http://<pi-ip>:8080` → **Permit join** → cihazı eşleştirme
   moduna al. Cihazlar Home Assistant'ta otomatik görünür.

## Günlük işlemler

```bash
docker compose ps                  # durum
docker compose logs -f zigbee2mqtt # canlı log
docker compose pull && docker compose up -d   # güncelleme
```

## Dükkana taşırken

Kurulum ağdan bağımsızdır; Pi dükkan ağına geçince yeni IP'den erişilir.
Router'da Pi'ye sabit IP (DHCP rezervasyonu) vermek önerilir.
`homeassistant/`, `zigbee2mqtt/data/` ve `.env` yedeklenmeli — Zigbee ağ anahtarı
`zigbee2mqtt/data/configuration.yaml` içindedir, kaybolursa tüm cihazlar yeniden eşleştirilir.

## Not

Bu Home Assistant **Container** kurulumudur; Eklenti Mağazası (Add-on Store) yoktur.
Ek servisler (Node-RED, Frigate vb.) `docker-compose.yml` dosyasına eklenir.
