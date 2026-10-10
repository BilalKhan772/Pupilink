
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_messaging_client.dart';

class ForegroundNotificationService {
  ForegroundNotificationService({
    FirebaseMessagingClient? messagingClient,
  }) : _messagingClient =
            messagingClient ?? FirebaseMessagingClient();

  final FirebaseMessagingClient _messagingClient;

  Stream<RemoteMessage> get messages => _messagingClient.onMessage;

  Stream<RemoteMessage> get notificationTaps =>
      _messagingClient.onMessageOpenedApp;

  Future<RemoteMessage?> getNotificationOpenedFromTerminatedState() {
    return _messagingClient.getInitialMessage();
  }

  Future<void> configureForegroundPresentation({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) {
    return _messagingClient.setForegroundPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }
}
