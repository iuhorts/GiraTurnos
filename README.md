# TurnosFamilia

App para gestionar turnos laborales de toda la familia, sin publicidad, con sincronización automática via Google Drive.

## Características

- Calendario mensual visual con colores por turno
- Múltiples perfiles (familiares)
- Contador de horas trabajadas
- Sincronización Google Drive (todos los dispositivos con la misma cuenta)
- Notas diarias
- Exportar/Importar (JSON, CSV, PDF)
- Widget de pantalla de inicio
- Sin publicidad

## Cómo instalar

1. Ve a **Actions** > **Build APK** > **Run workflow**
2. Descarga el APK de **arm64-v8a** (la mayoría de móviles) o **universal**
3. Activa "Instalar apps de orígenes desconocidos" en Android
4. Instala el APK

## Compilar localmente

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

## Google Drive Sync

1. Crea un proyecto en [Google Cloud Console](https://console.cloud.google.com/)
2. Activa **Google Drive API**
3. Crea credenciales OAuth 2.0 para Android (necesitas tu keystore fingerprint)
4. Configura en `android/app/build.gradle`

## Stack

- Flutter 3.27+
- sqflite (datos locales)
- google_sign_in + googleapis (Drive sync)
- table_calendar
- provider (estado)
- home_widget (widget Android)
