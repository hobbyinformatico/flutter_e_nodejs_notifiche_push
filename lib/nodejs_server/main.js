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
  //console.log(req);
  //console.log(res);
  console.log(req.body);
  //const { token, messaggio } = req.body;
  res.send('Risposta dalla richiesta POST');

  //const { token, messaggio } = req.body;
  const token = req.body.token;
  lastToken = token;

  console.log("invio notifica al device: " + token);

    const payload = {
      notification: {
        title: 'Titolo della notifica',
        body: "messaggio",
      },
    };

    admin.messaging().sendToDevice(token, payload)
      .then(response => {
        console.log('Notifica inviata:', response);
        return res.json({ success: true, message: 'Notifica inviata con successo' });
      })
      .catch(error => {
        console.error('(500) Errore nell\'invio della notifica:', error);
        //res.status(500).json({ success: false, error: 'Errore nell\'invio della notifica' });
      });
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

      const payload = {
        notification: {
          title: 'Titolo della notifica',
          body: 'messaggio ' + indexNotifica,
          android: {
            imageUrl: 'https://png.pngtree.com/element_our/png/20180928/beautiful-hologram-water-color-frame-png_119551.jpg'
          },
          apple: {
            imageUrl: 'https://png.pngtree.com/element_our/png/20180928/beautiful-hologram-water-color-frame-png_119551.jpg'
          },
        },
      };

      admin.messaging().sendToDevice(token, payload)
        .then(response => {
          console.log('Notifica inviata:', response);
          res.json({ success: true, message: 'Notifica inviata con successo' });
        })
        .catch(error => {
          console.error('Errore nell\'invio della notifica:', error);
          res.status(500).json({ success: false, error: 'Errore nell\'invio della notifica' });
        }
      );
      indexNotifica++;
  }
);


const intervalloNotificaInMs = 20000;
const intervallo = setInterval(() => {
    if(lastToken != "") {
      const payload = {
        notification: {
          title: 'Titolo della notifica',
          body: 'messaggio ' + indexNotifica,
        },
      };

      admin.messaging().sendToDevice(lastToken, payload)
        .then(response => {
          console.log('Notifica inviata:', response);
          //res.json({ success: true, message: 'Notifica inviata con successo' });
        })
        .catch(error => {
          console.error('Errore nell\'invio della notifica:', error);
          //res.status(500).json({ success: false, error: 'Errore nell\'invio della notifica' });
        });
      indexNotifica++;
    }
   } , intervalloNotificaInMs);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server in ascolto sulla porta ${PORT}`);
});
