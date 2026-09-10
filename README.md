# Equine Control Monitor

Aplicación Flutter para propietarios de caballos, veterinarios y responsables de establos.

## Funciones disponibles

- Registro de usuarios con roles múltiples: propietario, veterinario y dueño de establo.
- Validación de cuentas desde el panel exclusivo del administrador.
- Saludo personalizado con nombre del usuario y del establo.
- Perfiles editables de propietario, caballo y veterinario.
- Fotografías persistentes en los perfiles.
- Plan de medicación con dosis, fecha y frecuencia.
- Historial clínico local.
- Dashboard de monitoreo ambiental demostrativo.
- Protocolo JSON preparado para lecturas del ESP32-S3.
- Firmware inicial BLE/Wi-Fi en `firmware/equine_sensor_node`.
- Informe PDF con perfiles, medicación e historial.
- Polaco por defecto y soporte para español, alemán, neerlandés, francés, inglés y portugués.

## Ejecución

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Próxima fase

1. Sustituir el repositorio local por Firebase o Supabase.
2. Conectar Bluetooth Low Energy con el ESP32-S3.
3. Enviar lecturas reales y guardar el historial online.
4. Añadir notificaciones locales para medicación y alertas de sensores.
5. Completar permisos por establo, propietario y veterinario.
6. Añadir diagnóstico, procedimientos, vacunas, alergias y firmas clínicas.

El monitoreo que aparece actualmente en la aplicación usa datos demostrativos hasta conectar el hardware real. Las decisiones clínicas deben ser revisadas por un veterinario.

## Hardware

La guía de carga, configuración de la placa ESP32-S3 y el protocolo BLE están en [firmware/README.md](firmware/README.md). El firmware inicial publica datos demostrativos cada cinco segundos hasta conocer los modelos exactos de los sensores.
