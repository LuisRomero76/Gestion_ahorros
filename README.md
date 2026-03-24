# 💰 Gestión de Ahorros

App Flutter para gestionar ahorros diarios de manera colaborativa. Permite registrar gastos, categorizar transacciones y gestionar personas participantes.

## 🚀 Tecnologías

- **Flutter** 3.11+
- **Firebase**: Authentication, Firestore, Cloud Messaging
- **Provider** para manejo de estado
- **Notificaciones** push y locales

## 📋 Requisitos Previos

- Flutter 3.11 o superior
- Cuenta de Firebase
- Android Studio / Xcode (para desarrollo móvil)

## ⚙️ Configuración Inicial

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd gestion_ahorros
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase

**Opción A: Usar configuración existente** (si tienes acceso al proyecto Firebase)
- Los archivos `firebase_options.dart` y `google-services.json` ya están incluidos
- Solo necesitas ejecutar la app

**Opción B: Configurar tu propio proyecto Firebase**

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)

2. Instala FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Configura Firebase para tu proyecto:
   ```bash
   flutterfire configure
   ```

4. Habilita servicios en Firebase Console:
   - **Authentication** → Sign-in method → Email/Password
   - **Firestore Database** → Crear base de datos
   - **Cloud Messaging** → Habilitar

5. Configura reglas de Firestore (en Firebase Console → Firestore → Rules):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### 4. Configuración de Notificaciones (Opcional)

#### Android
Ya está configurado. Las notificaciones funcionarán automáticamente.

#### iOS
1. Abrir `ios/Runner.xcworkspace` en Xcode
2. Habilitar **Push Notifications** en Capabilities
3. Habilitar **Background Modes** → Remote notifications

## 🏃 Ejecutar la App

```bash
# Verificar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device-id>
```

## 📱 Funcionalidades

- ✅ Autenticación con email/password
- ✅ Registro de gastos diarios
- ✅ Categorización de transacciones
- ✅ Vista de calendario mensual
- ✅ Gestión de personas participantes
- ✅ Notificaciones push
- ✅ Historial de transacciones

## 🗂️ Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── screens/                  # Pantallas de la app
│   ├── login_screen.dart
│   ├── main_nav_screen.dart
│   ├── day_detail_screen.dart
│   └── ...
├── services/                 # Servicios (Firebase, Auth, Notificaciones)
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── notification_service.dart
├── providers/                # Gestión de estado
│   └── app_provider.dart
└── firebase_options.dart     # Configuración Firebase
```

## 🔒 Seguridad

- Las API keys en `firebase_options.dart` son **públicas** (diseño de Firebase)
- La seguridad se maneja con Firestore Rules y Firebase Authentication
- **NUNCA** subas al repositorio:
  - Service Account Keys (`*-firebase-adminsdk-*.json`)
  - Archivos `.env` con secretos
  - Certificados privados (`.p12`, `.pem`)

## 🐛 Troubleshooting

### Error de Firebase no inicializado
```bash
flutter clean
flutter pub get
flutter run
```

### Notificaciones no funcionan en iOS
Verifica que hayas configurado Push Notifications en Xcode

### Error de compilación en Android
Verifica que `google-services.json` esté en `android/app/`

## 📄 Licencia

Este proyecto es privado y de uso personal.
