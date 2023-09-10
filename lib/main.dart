import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notifiche_push/utils/messages_notifications.dart';

Future<void> onSelectNotification(NotificationResponse payload) async {
  // operazioni extra => al click della notifica
  MyApp.selfInstance.mn.actionNotifichePush(payload);
}

Future <void> main() async {
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

  // utilità per gestione notifiche e listener modifiche al db di Firebase
  MessagesNotifications mn = MessagesNotifications();
  mn.setNotificationInstance(flutterLocalNotificationsPlugin);

  // devo interagire con l'istanza di MyApp quindi mi salvo il riferimento e
  // la rendo disponibile come campo statico in MyApp stessa (è fattibile
  // perchè comunque avrò sempre e solo 1 istanza di MyApp)
  dynamic selfMyApp = MyApp(mn);
  MyApp.selfInstance = selfMyApp;
  runApp(selfMyApp);

}

class MyApp extends StatelessWidget {
  // riferimento istanza MyApp (accessibile da qualsiasi parte
  // dell'app)
  static dynamic selfInstance;
  // quando viene istanziato
  final MessagesNotifications mn;

  Future<void> init() async {
    await mn.listenNotifichePush();
  }

  MyApp(this.mn, {super.key}) {
    init();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
