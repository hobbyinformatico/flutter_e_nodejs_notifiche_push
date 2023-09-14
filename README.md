# flutter_e_nodejs_notifiche_push
Esempio di integrazione Notifiche push con FCM (Firebase Cloud Messaging) su client-server (app Flutter + Node.js)

# Configurare Notifiche Push
```
flutter pub add flutter_local_notifications
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add http
flutter pub add shared_preferences
```

# Firebase
- https://console.firebase.google.com/
- vai sul progetto ed entraci
- (ingranaggio) => Impostazioni progetto =>
  - Account di servizio => SDK Firebase Admin
    - Node.js => Genera nuova chiave privata
    - questo genera un JSON che va caricato da Node.js per autenticarsi
      - crea il file in  lib/nodejs_server/firebase-adminsdk.json  e incolla il contenuto del JSON
        - usa la guida per Node.js per capire come importare nel codice il file
  - Cloud Messaging => abilita "API Cloud Messaging (legacy)"
    - per abilitare l'invio di messaggi tramite la più vecchia "legacy" API

# Server NodeJs
1. Node.js + notifiche Firebase (FCM)
```
npm install express firebase-admin
```
2. notifiche Apple
```
npm install apn
```
3. integrazione database per gestire il salvataggio token
```
npm install sqlite3
```
4. icone badge di notifica
  - su iOS c'è sempre quella dell'app (attualmente come impostazione di stile Apple, in futuro non si sa)
  - Su Android (attualmente, in futuro non si sa) ci sono 2 visualizzazioni dell'icona del badge di modifica:
    1. quella dell'app (a colori) quando il badge delle notifiche per
       l'app non è esploso (il raggruppamento può contenerne una o più)
    2. quella dell'app (tutta nera) quando il badge che raggruppa le notifiche
       viene esploso. Le parti diverse da trasparente diventano nere quindi se non
       ha una forma visibile si confonde tutto con lo sfondo (conviene crearne una ad hoc).
       La PNG creata può essere messa in in android/app/src/main/res/drawable e richiamata
       con 'ic_launcher_notifiche' (se si chiama ic_launcher_notifiche.png).
       Va richiamata in 2 punti:
```
const String ICON = 'ic_launcher_notifiche';

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
    
const AndroidInitializationSettings androidSetting = AndroidInitializationSettings(ICON);
```
5. le icone creale con l'applicazione python crea_icone/main.py e mettile in android/app/src/main/res

# Recupero dati da click notifica ad app chiusa
Richiamare questa funzione all'interno dell'app (se l'app è stata aperta
da un badge arrivato quando era chiusa verrà popolato, altrimenti NULL):
```
  RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
  if (message != null) {
    // dati notifica cliccata (da app chiusa)
    // se le notifiche arrivavano ad APP aperta non passa da qui ma da "onSelectNotification"
    // e bisogna interagire con "payload" valorizzato dallo "show" della notifica
    print(message.notification);
    print(message.notification?.body ?? "BODY VUOTO");
  }
```