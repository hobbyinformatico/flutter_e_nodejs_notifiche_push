import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MessagesNotifications{
  dynamic user;
  dynamic tokenPushNotification;
  FlutterLocalNotificationsPlugin flnp = FlutterLocalNotificationsPlugin();

  setNotificationInstance(FlutterLocalNotificationsPlugin flnpInstance) {
    flnp = flnpInstance;
  }

  updateToken(token) {
    tokenPushNotification = token;
  }

  Future<void> testGet() async {
    // testando in localhost, Android non riesce a connettersi se non fornisci
    // l'ip della rete interna di questo pc (lo trovi con "ip addr" su linux)
    final uri = Platform.isAndroid ? 'http://192.168.1.202:3000/test' : 'http://localhost:3000/test';
    final url = Uri.parse(uri);
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.get(
        url,
        //headers: headers,
        //body: jsonEncode(data), // Converti i dati in JSON
      );

      if (response.statusCode == 200) {
        // La richiesta è andata a buon fine, puoi gestire la risposta qui
        print('Risposta: ${response.body}');
      } else {
        // La richiesta ha restituito un errore, gestisci l'errore qui
        print('Errore: ${response.reasonPhrase}');
      }
    } catch(e) {
      print(e);
    }
  }

  Future<void> postData() async {
    final uri = Platform.isAndroid ? 'http://192.168.1.202:3000/salva-token' : 'http://localhost:3000/salva-token';
    final url = Uri.parse(uri);
    final headers = {
      'Content-Type': 'application/json', // Specifica il tipo di dati inviati (JSON in questo caso)
    };

    final data = {
      'token': tokenPushNotification ?? "",
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data), // Converti i dati in JSON
      );

      if (response.statusCode == 200) {
        // La richiesta è andata a buon fine, puoi gestire la risposta qui
        print('Risposta: ${response.body}');
      } else {
        // La richiesta ha restituito un errore, gestisci l'errore qui
        print('Errore: ${response.reasonPhrase}');
      }
    } catch(e) {
      print(e);
    }
  }

  /// listeners che si attivano alla recezione di una notifica push da Firebase
  Future<void> listenNotifichePush() async {
    // richiedo all'utente il permesso di inviare notifiche
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (Platform.isIOS) {
      settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // L'utente ha autorizzato le notifiche
      String? token = await messaging.getToken();
      print("token notifiche: " + (token ?? "nessuno"));
      updateToken(token);
      await postData();
      //await testGet();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è in primo piano.
        //print("***** App in primo piano *****");
        //await MyApp.selfInstance.mn.showNotification(message.notification?.title, message.notification?.body, message.data);
        await MyApp.selfInstance.mn.dispatcherNotifichePush(message);
        //print(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è in background o chiusa.
        //print("***** App in background *****");
        //await MyApp.selfInstance.mn.showNotification(message.notification?.title, message.notification?.body, message.data);
        await MyApp.selfInstance.mn.dispatcherNotifichePush(message);
        //print(message);
      });

      FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è chiusa.
        await Firebase.initializeApp();
      });
    }
  }

  /// mostra notifiche push
  Future<void> dispatcherNotifichePush(RemoteMessage message) async {

    //print(message.data);
    /*
      {this.android,
      this.apple,
      this.web,
      this.title,
      this.titleLocArgs = const <String>[],
      this.titleLocKey,
      this.body,
      this.bodyLocArgs = const <String>[],
      this.bodyLocKey}
    */
    print("----------");
    print(message.notification?.title);
    print(message.notification?.body);
    print("----------");

    // rimuovi tutte le notifiche esistenti
    await flnp.cancelAll();
    // Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel_description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker'
    );
    // iOS
    const DarwinNotificationDetails iosNotificationsDetail =
    DarwinNotificationDetails(
        categoryIdentifier: 'textCategory'
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosNotificationsDetail
    );

    await flnp.show(
      1,
      message.notification?.title, //"title",
      message.notification?.body, //"body",
      platformChannelSpecifics,
    );
  }
}
