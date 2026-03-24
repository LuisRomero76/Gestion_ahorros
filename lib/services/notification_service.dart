import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Manejador para mensajes en segundo plano (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Mensaje recibido en segundo plano: ${message.messageId}');
}

/// Servicio de notificaciones simplificado.
///
/// RESPONSABILIDADES:
/// - Solicitar permisos de notificación al usuario
/// - Obtener y guardar el token FCM en Firestore
/// - Mostrar notificaciones locales cuando la app está en primer plano
///
/// NOTA: El ENVÍO de notificaciones push se maneja desde Cloud Functions,
/// que se disparan automáticamente al crear un nuevo registro en Firestore.
class NotificationService {
  static final NotificationService instance = NotificationService._init();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentToken;

  NotificationService._init();

  /// Obtener el token FCM actual
  String? get currentToken => _currentToken;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // Configurar manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Solicitar permisos de notificación
    await _requestPermissions();

    // Configurar notificaciones locales
    await _setupLocalNotifications();

    // Escuchar mensajes cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);
  }

  /// Solicitar permisos de notificación al usuario
  Future<bool> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized;

    if (granted) {
      print('Permisos de notificación concedidos');
    } else {
      print('Permisos de notificación denegados');
    }

    return granted;
  }

  /// Configurar notificaciones locales
  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones de Ahorros',
      description: 'Notificaciones de nuevos registros de ahorro',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Obtener el token FCM del dispositivo y guardarlo en Firestore
  ///
  /// Debe llamarse después de que el usuario inicie sesión.
  Future<String?> getAndSaveToken() async {
    try {
      final userId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No hay usuario autenticado para guardar token');
        return null;
      }

      // Obtener el token FCM
      _currentToken = await _messaging.getToken();
      if (_currentToken == null) {
        print('No se pudo obtener el token FCM');
        return null;
      }

      print('Token FCM obtenido: $_currentToken');

      // Buscar el perfil del usuario actual y guardar el token
      final profileSnapshot = await _firestore
          .collection('profiles')
          .where('authUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        await profileSnapshot.docs.first.reference.update({
          'fcmToken': _currentToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('Token FCM guardado en Firestore');
      }

      // Escuchar actualizaciones del token
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      return _currentToken;
    } catch (e) {
      print('Error al obtener/guardar token FCM: $e');
      return null;
    }
  }

  /// Manejar la actualización del token FCM
  void _onTokenRefresh(String newToken) async {
    print('Token FCM actualizado: $newToken');
    _currentToken = newToken;

    try {
      final userId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profileSnapshot = await _firestore
          .collection('profiles')
          .where('authUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        await profileSnapshot.docs.first.reference.update({
          'fcmToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('Token FCM actualizado en Firestore');
      }
    } catch (e) {
      print('Error al actualizar token FCM: $e');
    }
  }

  /// Manejar mensajes cuando la app está en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.messageId}');

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Nuevo registro',
        body: notification.body ?? '',
      );
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones de Ahorros',
      channelDescription: 'Notificaciones de nuevos registros de ahorro',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  /// Manejar cuando el usuario toca una notificación local
  void _onLocalNotificationTapped(NotificationResponse response) {
    print('Notificación local tocada: ${response.payload}');
  }

  /// Manejar cuando el usuario toca una notificación push
  void _handleNotificationTapped(RemoteMessage message) {
    print('Notificación push abierta: ${message.messageId}');
  }

  /// Limpiar token cuando el usuario cierra sesión
  Future<void> clearDeviceToken() async {
    try {
      final userId = auth.FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final profileSnapshot = await _firestore
          .collection('profiles')
          .where('authUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (profileSnapshot.docs.isNotEmpty) {
        await profileSnapshot.docs.first.reference.update({
          'fcmToken': FieldValue.delete(),
          'tokenUpdatedAt': FieldValue.delete(),
        });
        print('Token FCM eliminado de Firestore');
      }

      _currentToken = null;
    } catch (e) {
      print('Error al limpiar token FCM: $e');
    }
  }
}
