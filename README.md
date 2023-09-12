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

# Recupero dati da click notifica ad app chiusa
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