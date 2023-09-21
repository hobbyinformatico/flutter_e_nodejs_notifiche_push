import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// Gestione semplificata notifiche:
/// 1. flutter pub add => flutter_local_notifications, firebase_core
/// 2. Notifica interna:
///   - avvia badge notifica da app (non si attiva ad app chiusa)
///   - recupera payload messaggio (su click badge SOLO ad app aperta):
///     - "_onClickBadgeNotifica()"
///       - scatta da solo senza richiamarlo direttamente
///     - showNotification()
///       - avvia la notifica (visibile solo ad app aperta)
///       - assegnamo manualmente un "payload" al messaggio, che servirà per comunicare
///         qualcosa a "_onClickBadgeNotifica()" che altrimenti al click del badge
///         non troverà nulla
class UtilNotificationsLocal {
  static FlutterLocalNotificationsPlugin? flnp;
  // android/app/src/main/res/drawable/icona_notifiche.png
  static const String ICON = 'ic_launcher_notifiche'; //'@mipmap/ic_launcher'; //'icona_notifiche'; //


  /// Mostra badge con la notifica (notifiche locali ad app aperta)
  static Future<void> showNotification(int id, String title, String body) async {
    // init servizi (se non fossero già istanziati)
    await UtilNotificationsLocal._autoinit();

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
  /// Inizializza i servizi necessari al funzionamento delle notifiche (LOCALI, ad app aperta)
  static Future<void> _autoinit() async {
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
        onDidReceiveNotificationResponse: UtilNotificationsLocal._onClickBadgeNotifica,
        onDidReceiveBackgroundNotificationResponse: UtilNotificationsLocal._onClickBadgeNotifica
    );
  }
}

class MiaClasseStatica {
  // Variabile statica
  static String message = "null";
}