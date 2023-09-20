/*
    Admin Node.js SDK — Node.js 14+
*/

const sqlite3 = require('sqlite3').verbose();
const admin = require('firebase-admin');
// Inizializza Firebase
const serviceAccount = require('./firebase-adminsdk.json'); // Configura il tuo percorso


admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const express = require('express');
const app = express();

// Specifica il nome del file del database
const dbPath = 'mydatabase.db';
// Crea una nuova istanza di database e connettiti
const db = new sqlite3.Database(dbPath, sqlite3.OPEN_CREATE | sqlite3.OPEN_READWRITE, (err) => {
  if (err) {
    console.error('Errore nella connessione al database:', err.message);
  } else {
    console.log('Connesso al database SQLite.');
  }
});

var lastToken = "";
var indexNotifica = 0;

// Middleware per analizzare dati JSON
app.use(express.json());

// salva token device su db
app.post('/salva-token', (req, res) => {

        const token = req.body.token;
        lastToken = token;
        console.log("invio notifica al device: " + token);

        (async () => {
            const payload = {
                //token: lastToken // con "send(payload)"
                tokens: [lastToken], // con "sendMulticast(payload)"
                notification: {
                    title: 'Titolo della notifica',
                    body: '(salva-token) messaggio ' + indexNotifica,
                },
                /*
                android: {
                  notification: {
                    //default_sound: true,
                    //notification_count: 1,
                  }
                }
                */
            };

            //admin.messaging().sendToDevice(lastToken, payload)
            //admin.messaging().send(payload)
            await admin.messaging().sendMulticast(payload);
            indexNotifica++;
        }) ();
    }
);

app.get('/test', (req, res) => {
  // La logica per gestire la richiesta GET va qui
  console.log("GET: /test");
  res.send('Risposta dalla richiesta GET');
});


// Gestisci una richiesta di invio di notifica
app.post('/invia-notifica', (req, res) => {

        console.log("POST: /invia-notifica");
        const { token, messaggio } = req.body;

        (async () => {
            const payload = {
                //token: lastToken // con "send(payload)"
                tokens: [lastToken], // con "sendMulticast(payload)"
                notification: {
                    title: 'Titolo della notifica',
                    body: '(invia-notifica) messaggio ' + indexNotifica,
                },
                /*
                android: {
                  notification: {
                    //default_sound: true,
                    //notification_count: 1,
                  }
                }
                */
            };

            //admin.messaging().sendToDevice(lastToken, payload)
            //admin.messaging().send(payload)
            await admin.messaging().sendMulticast(payload);
            indexNotifica++;
        }) ();
    }
);


const intervalloNotificaInMs = 20000;
const intervallo = setInterval(() => {
        if(lastToken != "") {
            (async () => {
                const payload = {
                    //token: lastToken // con "send(payload)"
                    tokens: [lastToken], // con "sendMulticast(payload)"
                    notification: {
                        title: 'Titolo della notifica',
                        body: '(job) messaggio ' + indexNotifica,
                    },
                    /*
                    android: {
                      notification: {
                        //default_sound: true,
                        //notification_count: 1,
                      }
                    }
                    */
                };

                //admin.messaging().sendToDevice(lastToken, payload)
                //admin.messaging().send(payload)
                await admin.messaging().sendMulticast(payload);
                indexNotifica++;
            }) ();
        }
    }, intervalloNotificaInMs
);



const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server in ascolto sulla porta ${PORT}`);
});