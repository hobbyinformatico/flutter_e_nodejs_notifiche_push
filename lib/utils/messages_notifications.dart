import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


/// Gestione semplificata notifiche:
/// 1. flutter pub add => flutter_local_notifications, firebase_core, firebase_messaging
/// 2. Notifiche push (firebase_messaging, NON SERVE flutter_local_notifications):
///   - registra token device su FCM con "generaToken()"
///   - attendi notifiche da server
///   - avvia badge notifica sia ad app aperta che chiusa
///   - recupera messaggio (su click badge SOLO ad app chiusa):
///     - "checkClickBadgeNotificaAppChiusa()" restituisce "RemoteMessage msg != null"
/// 3. Notifica interna (flutter_local_notifications, NON SERVE firebase_messaging):
///   - avvia badge notifica da app (non si attiva ad app chiusa)
///   - recupera payload messaggio (su click badge SOLO ad app aperta):
///     - "_onClickBadgeNotifica()"
///       - scatta da solo senza richiamarlo direttamente
///     - showNotification()
///       - avvia la notifica (visibile solo ad app aperta)
///       - assegnamo manualmente un "payload" al messaggio, che servirà per comunicare
///         qualcosa a "_onClickBadgeNotifica()" che altrimenti al click del badge
///         non troverà nulla
class MessagesNotifications {
  static FlutterLocalNotificationsPlugin? flnp;
  static bool pushNotifications = false;
  static String? token;
  // android/app/src/main/res/drawable/icona_notifiche.png
  static const String ICON = 'ic_launcher_notifiche'; //'@mipmap/ic_launcher'; //'icona_notifiche'; //


  /// Mostra badge con la notifica (notifiche locali ad app aperta)
  static Future<void> showNotification(int id, String title, String body) async {
    // init servizi (se non fossero già istanziati)
    await MessagesNotifications._autoinit_localNotifications();

    // rimuovi tutte le notifiche esistenti
    await flnp!.cancelAll();
    // Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        icon: ICON,
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
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: body
    );
  }

  /// Chiedo al servizio di Google FirebaseMessaging (FCM) di generarmi un
  /// token valido che identifica questo dispositivo per la recezione di
  /// notifiche su Android e iOS (se ho dato il permesso a FCM di gestire APN) .
  /// Questo token non scadrà MAI, a meno che:
  /// - The app deletes Instance ID
  /// - The app is restored on a new device
  /// - The user uninstalls/reinstall the app
  /// - The user clears app data
  /// Conviene salvarlo su SharedPreferences per evitare di richiederne uno
  /// nuovo ad ogni avvio dell'app
  static Future<void> generaToken({forceRefreshToken = false}) async {
    // init servizi (se non fossero già istanziati):
    //  1. notifiche locali (ad app aperta)
    await MessagesNotifications._autoinit_localNotifications();
    //  2. notifiche push (ad app aperta o chiusa)
    await MessagesNotifications._autoinit_pushNotifications();

    // messaggio (presente solo se l'app era chiusa ed è stato cliccato il badge)
    RemoteMessage? msg = await MessagesNotifications.checkClickBadgeNotificaAppChiusa();
    if(msg != null) {
      // azioni da compiere ad app aperta dal click del badge
    }

    if(forceRefreshToken == false) {
      // controllo che il token non sia già presente
      String? tokenSaved = (await SharedPreferences.getInstance()).getString('tokenSaved');
      print("(OLD) token notifiche: " + (tokenSaved ?? "nessuno"));
      print("(NEW) token notifiche: " + (token ?? "nessuno"));
      if(tokenSaved != null) {
        // token già presente non serve richiederne uno nuovo
        token = tokenSaved;
        return;
      }
    }

    // Richiedo nuovo token a servizio Push Notification FCM
    token = await FirebaseMessaging.instance.getToken();
    print("token notifiche: " + (token ?? "nessuno"));
    if(token != null) {
      // token ricevuto, salviamolo su backend e in locale
      await MessagesNotifications._saveTokenOnBackend();
      (await SharedPreferences.getInstance()).setString('tokenSaved', token!);
    }
  }

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

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Mostra il badge di notifica (customizzabile)
  static Future<void> _gestioneNotificaRicevuta(RemoteMessage msg) async {
    // init servizi (se non fossero già istanziati)
    await MessagesNotifications._autoinit_localNotifications();
    // mostra badge con la notifica
    await showNotification(0, msg.notification?.title ?? "", msg.notification?.body ?? "");
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Registrazione token nel nostro server (customizzabile in base al backend)
  static Future<void> _saveTokenOnBackend() async {
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

      pushNotifications = true;
    }
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Inizializza i servizi necessari al funzionamento delle notifiche (LOCALI, ad app aperta)
  static Future<void> _autoinit_localNotifications() async {
    if(flnp != null) {
      // servizio (notifiche locali) già inizializzato => esco
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
    //    Rimuovendo "bool? init = " le notifiche SMETTONO di funzionare ad app in BACKGROUND
    bool? init = await flnp!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: MessagesNotifications._onClickBadgeNotifica,
        onDidReceiveBackgroundNotificationResponse: MessagesNotifications._onClickBadgeNotifica
    );
  }

  /// ( PRIVATO => Non richiamare direttamente! )
  /// Inizializza i servizi necessari al funzionamento delle notifiche (NOTIFICHE PUSH, ad app aperta e chiusa)
  static Future<void> _autoinit_pushNotifications() async {
    if(pushNotifications == true) {
      // servizio (notifiche push) già inizializzato => esco
      return;
    }

    // registro listener notifiche
    await MessagesNotifications._listenNotifichePush();
  }
}

class MiaClasseStatica {
  // Variabile statica
  static String message = "null";
}