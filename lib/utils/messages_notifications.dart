import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notifiche_push/providers/provider_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MiaClasseStatica {
  // Variabile statica
  static String message = "null";
}

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

  Future<void> saveTest(String? payload) async {
    var onBackgroundMessageData = {
      'title': payload, //message.notification?.title,
      'body': payload, //message.notification?.body
    };
    //SharedPreferences prefs = (await SharedPreferences.getInstance());
    //await prefs.reload();
    (await SharedPreferences.getInstance()).setString('onBackgroundMessageData', payload ?? "niente");
  }

  Future<dynamic> loadTest() async {
    var onBackgroundMessageData = {
      'title': "niente titolo",
      'body': "niente body"
    };
    var dataSaved = (await SharedPreferences.getInstance()).getString('onBackgroundMessageData');
    if(dataSaved != null) {
      onBackgroundMessageData['body'] = dataSaved;
    }
    return onBackgroundMessageData;
  }

  /// salva in SharedPreferences la notifica push arrivata ad app chiusa
  Future<void> saveNoticationFromOnBackgroundMessage(RemoteMessage message) async {
    var onBackgroundMessageData = {
      'title': message.notification?.title,
      'body': message.notification?.body
    };
    //SharedPreferences prefs = (await SharedPreferences.getInstance());
    //await prefs.reload();
    (await SharedPreferences.getInstance()).setString('onBackgroundMessageData', json.encode(onBackgroundMessageData));
  }

  /// recupera da SharedPreferences la notifica push arrivata ad app chiusa
  Future<dynamic> loadNoticationFromOnBackgroundMessage() async {
    //MiaClasseStatica.message
    var onBackgroundMessageData = {
      'title': "",
      'body': ""
    };
    if(MiaClasseStatica.message != null) {
      onBackgroundMessageData['body'] = MiaClasseStatica.message ?? "body_vuoto";
      return;
    }

    try {
      var dataSaved = (await SharedPreferences.getInstance()).getString('onBackgroundMessageData');
      if(dataSaved != null) {
        var dataDecoded = json.decode(dataSaved);
        onBackgroundMessageData['title'] = dataDecoded.title;
        onBackgroundMessageData['body'] = dataDecoded.body;
      } else {
        onBackgroundMessageData['body'] = "null";
      }
    } catch (e) {
      onBackgroundMessageData['body'] = e.toString();
    }
    return onBackgroundMessageData;
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
        //await MyApp.selfInstance.mn.dispatcherNotifichePush(message);
        await MyApp.selfInstance.mn.dispatcherNotifichePush(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è in background o chiusa.
        //print("***** App in background *****");
        //await MyApp.selfInstance.mn.showNotification(message.notification?.title, message.notification?.body, message.data);
        await MyApp.selfInstance.mn.dispatcherNotifichePush(message);
      });

      /// Gestisci la notifica quando l'app è chiusa
      FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
        // Il dato "message" è visibile solo da qui dentro. L'app è chiusa e non posso
        // comunicarle eventuali azioni da fare in base ai valori di "message".
        // Per risolvere questo problema possiamo memorizzare temporaneamente in
        // SharedPreferences i dati utili di "message".
        // Quando l'app verrà aperta possiamo controllare la presenza di dati su
        // SharedPreferences sotto una certa key e in questo modo capire se dobbiamo
        // fare o meno qualcosa.
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
      payload: message.notification?.body
    );
  }
}
