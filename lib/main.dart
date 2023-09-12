import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notifiche_push/providers/provider_notifications.dart';
import 'package:flutter_notifiche_push/utils/messages_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

Future<void> onSelectNotification(NotificationResponse payload) async {
  // operazioni extra => al click della notifica
  MyApp.selfInstance.mn.actionNotifichePush(payload);
  MiaClasseStatica.message = payload.payload ?? "click vuoto";
  // adesso bisognerebbe far scattare il refresh della MAIN altrimenti
  // il titolo non si aggiorna
}

Future <void> main({back = ""}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // main modificato per implementare notifiche
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Android settings
  const AndroidInitializationSettings androidSetting = AndroidInitializationSettings('@mipmap/ic_launcher'); //AndroidInitializationSettings('icona_notifiche');
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
  bool? init = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: onSelectNotification
  );

  /// aaaaaaaaaa
  //flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  // utilità per gestione notifiche e listener modifiche al db di Firebase
  MessagesNotifications mn = MessagesNotifications();
  mn.setNotificationInstance(flutterLocalNotificationsPlugin);

  // devo interagire con l'istanza di MyApp quindi mi salvo il riferimento e
  // la rendo disponibile come campo statico in MyApp stessa (è fattibile
  // perchè comunque avrò sempre e solo 1 istanza di MyApp)
  dynamic selfMyApp = MyApp(mn);
  MyApp.selfInstance = selfMyApp;
  MyApp.back = back;
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProviderNotifications>(create: (_) => ProviderNotifications()),
        ],
        child: selfMyApp,
      )
  );
}

Future<void> _runWhileAppIsTerminated(FlutterLocalNotificationsPlugin flnp) async {
  //var details = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  //NotificationAppLaunchDetails

  var details = await flnp.getNotificationAppLaunchDetails();

  if (details != null){
    if (details.didNotificationLaunchApp) {
      if (details?.notificationResponse != null){
        await saveTest(details?.notificationResponse?.payload ?? "niente boh");
      }
    }
  }
}

//Future<String> run(FlutterLocalNotificationsPlugin flnp) async {
Future<String> run() async {
  //var details = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
  //NotificationAppLaunchDetails

  print("-------------- INIT");
  /*
  //open notif content from terminated state of the app
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    print("-------------- TERMINATED");
    if (message != null) {
      print(message.notification);
      print("------ Notifica TERMINATED: " + (message.notification?.body ?? "BODY VUOTO"));
      MiaClasseStatica.message = (message.notification?.body ?? "BODY VUOTO");
    }
  });
  */

  RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
  print("-------------- TERMINATED");
  if (message != null) {
    print(message.notification);
    print("------ Notifica TERMINATED: " + (message.notification?.body ?? "BODY VUOTO"));
    MiaClasseStatica.message = (message.notification?.body ?? "BODY VUOTO");
  }

  return MiaClasseStatica.message;
  /*
  print("----------- RUN");

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    print(message);
    if (message != null) {
      // DO YOUR THING HERE
      print(message.notification);
      return message.notification?.body;
      return message.notification?.title;
    }
  });

  return "NO: FirebaseMessaging.instance.getInitialMessage()";

  NotificationAppLaunchDetails? details = await flnp.getNotificationAppLaunchDetails();
  return details?.notificationResponse?.payload ?? "non va";

  if (details != null){
    if (details.didNotificationLaunchApp) {
      if (details?.notificationResponse != null){
        return details?.notificationResponse?.payload ?? "niente boh";
        //await saveTest(details?.notificationResponse?.payload ?? "niente boh");
      }
      return "perchè:  details?.notificationResponse == null";
    }
    return "perchè:  details.didNotificationLaunchApp == null";
  }
  return "perchè:  details == null";
  */
}

class MyApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  // riferimento istanza MyApp (accessibile da qualsiasi parte
  // dell'app)
  static dynamic selfInstance;
  static String back = "init";
  // quando viene istanziato
  final MessagesNotifications mn;

  Future<void> init() async {
    await mn.listenNotifichePush();
    await _runWhileAppIsTerminated(mn.flnp);
  }

  MyApp(this.mn, {super.key}) {
    init();

    /*
    print("-------------- INIT");
    //open notif content from terminated state of the app
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print("-------------- TERMINATED");
      if (message != null) {
        print(message.notification);
        print("------ Notifica TERMINATED: " + (message.notification?.body ?? "BODY VUOTO"));
        MiaClasseStatica.message = (message.notification?.body ?? "BODY VUOTO");
      }
    });
    */
  }

  /*.
  @override
  Widget build(BuildContext context) {
    final data = mn.loadNoticationFromOnBackgroundMessage();

     return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(title: data),
        );
  }
  */
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: run(), //run(mn.flnp), //mn.loadTest(), //mn.loadNoticationFromOnBackgroundMessage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Mostra un indicatore di caricamento durante l'attesa
        } else if (snapshot.hasError) {
          return Text("Errore: ${snapshot.error}");
        } else {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: MyHomePage(title: MiaClasseStatica.message), //snapshot.data), //snapshot.data["body"]),

          );
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() async {
      _counter++;
      await MyApp.selfInstance.mn.postData();
    });
  }

  @override
  Widget build(BuildContext context) {
    /*
    var details = await NotificationService()
        .flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    if (details.didNotificationLaunchApp) {
      print(details.payload);
    }
    */

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}