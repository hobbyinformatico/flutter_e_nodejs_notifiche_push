import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessagesNotifications {
  static FlutterLocalNotificationsPlugin? flnp;
  static String? token;
  static const String ICON = '@mipmap/ic_launcher';

  /// Recupera Notifica se badge di notifica cliccata (da app chiusa),
  /// altrimenti NULL
  static Future<RemoteMessage?> checkClickBadgeNotificaAppChiusa() async {
    return await FirebaseMessaging.instance.getInitialMessage();
  }

  /// Listener click badge di notifica (da app aperta o in background)
  static Future<void> _onClickBadgeNotifica(NotificationResponse payload) async {
    // operazioni extra => al click della notifica
    //MyApp.selfInstance.mn.actionNotifichePush(payload);
    MiaClasseStatica.message = payload.payload ?? "click vuoto";
    // adesso bisognerebbe far scattare il refresh della MAIN altrimenti
    // il titolo non si aggiorna
  }

  /// Chiedo al servizio di Google FirebaseMessaging (FCM) di generarmi un
  /// token valido che identifica questo dispositivo per la recezione di
  /// notifiche
  static Future<void> generaToken() async {
    // init servizi (se non fossero già istanziati)
    await MessagesNotifications._autoinit();

    // Richiedo nuovo token a servizio Push Notification FCM
    token = await FirebaseMessaging.instance.getToken();
    print("token notifiche: " + (token ?? "nessuno"));
    await MessagesNotifications._postData();
    //await testGet();
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Mostra il badge di notifica (customizzabile)
  static Future<void> _gestioneNotificaRicevuta(RemoteMessage msg) async {
    // init servizi (se non fossero già istanziati)
    await MessagesNotifications._autoinit();

    // rimuovi tutte le notifiche esistenti
    await flnp!.cancelAll();
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

    // mostra badge notifica
    await flnp!.show(
        0,
        msg.notification?.title,
        msg.notification?.body,
        platformChannelSpecifics,
        payload: msg.notification?.body
    );
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Registrazione token nel nostro server (customizzabile in base al backend)
  static Future<void> _postData() async {
    final uri = Platform.isAndroid ? 'http://192.168.1.202:3000/salva-token' : 'http://localhost:3000/salva-token';
    final url = Uri.parse(uri);
    final headers = {
      'Content-Type': 'application/json',
    };

    final data = {
      'token': token ?? "",
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

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Listeners che si attivano alla recezione di una notifica push da Firebase
  static Future<void> _listenNotifichePush() async {
    // richiedo all'utente il permesso di inviare notifiche
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    if (Platform.isIOS) {
      settings = await FirebaseMessaging.instance.requestPermission(
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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è in primo piano.
        await MessagesNotifications._gestioneNotificaRicevuta(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        // Gestisci la notifica quando l'app è in background o chiusa.
        await MessagesNotifications._gestioneNotificaRicevuta(message);
      });

      /*
      /// Gestisci la notifica quando l'app è chiusa
      FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
        await Firebase.initializeApp();
      });
      */
    }
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Inizializza i servizi necessari al funzionamento delle notifiche
  static Future<void> _autoinit() async {
    if(flnp != null) {
      // servizi già inizializzati => esco
      return;
    }

    flnp = FlutterLocalNotificationsPlugin();

    // Android settings
    //const AndroidInitializationSettings androidSetting = AndroidInitializationSettings('icona_notifiche');
    const AndroidInitializationSettings androidSetting = AndroidInitializationSettings(ICON);
    // iOS settings
    const iosSetting = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSetting,
        iOS: iosSetting
    );

    // ATTENZIONE!!
    //    Rimuovendo "bool? init = " le notifiche SMETTONO di funzionare ad app CHIUSA
    bool? init = await flnp!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: MessagesNotifications._onClickBadgeNotifica,
        onDidReceiveBackgroundNotificationResponse: MessagesNotifications._onClickBadgeNotifica
    );

    // registro listener notifiche
    await MessagesNotifications._listenNotifichePush();
  }
}

class MiaClasseStatica {
  // Variabile statica
  static String message = "null";
}