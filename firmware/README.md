# Firmware ESP32-S3

## Primera carga

1. Instala Arduino IDE 2.x.
2. En `Boards Manager`, instala `esp32 by Espressif Systems`.
3. Selecciona `ESP32S3 Dev Module`.
4. Para la placa N16R8 selecciona Flash `16MB`, PSRAM `OPI PSRAM` y USB CDC On Boot `Enabled`.
5. Abre `equine_sensor_node/equine_sensor_node.ino`.
6. Cambia `WIFI_SSID`, `WIFI_PASSWORD`, `DEVICE_ID` y `HORSE_ID`.
7. Selecciona el puerto USB-C de la placa y pulsa Upload.
8. Abre Serial Monitor a `115200` baudios.

El gateway publica una lectura JSON cada cinco segundos y, si se configura una URL, también por HTTP. La arquitectura prevista es: submódulos BLE -> gateway ESP32-S3 -> Internet/app. Las lecturas actuales son demostrativas hasta conectar los sensores físicos.

## BLE

- Nombre del dispositivo: `esp32s3-node-01`.
- Servicio: `7f8f0001-5d4c-4d9d-9c10-ec0000000001`.
- Característica de lecturas: `7f8f0002-5d4c-4d9d-9c10-ec0000000002`.
- Propiedades: lectura y notificaciones.

## A7670 GSM

- `GSM_RX_PIN` y `GSM_TX_PIN` son valores iniciales y deben coincidir con tu cableado.
- Cambia `ADMIN_PHONE` por el número del administrador en formato internacional.
- El gateway envía SMS solo por alertas ambientales.
- Hay un límite de diez minutos entre SMS para evitar spam.
- Las alertas fisiológicas futuras deben usar otra categoría y destinatarios autorizados.

El A7670 necesita alimentación estable y antena adecuada; no debe alimentarse directamente desde un pin de 3.3 V del ESP32.

## Formato enviado

```json
{
  "moduleType": "central",
  "sourceModuleId": "submodule-demo-01",
  "deviceId": "esp32s3-node-01",
  "horseId": "horse-01",
  "timestamp": "unix-time",
  "temperature": 22.4,
  "humidity": 58.0,
  "ammonia": 2.1,
  "airQuality": 86.0,
  "dust": 0.0,
  "pollen": 0.0
}
```

## Antes de conectar sensores

Necesitamos confirmar el modelo y voltaje de cada sensor. No se deben conectar directamente sensores desconocidos al ESP32: primero hay que identificar si usan I2C, UART, ADC o GPIO, su voltaje y su dirección/pin.
