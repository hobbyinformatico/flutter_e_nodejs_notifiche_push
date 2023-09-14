# Installazione venv
Usato con versione Python 3.10.7
```
python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
```

# Avvio
Il programma prende automaticamente un file ic_launcher.png nella stessa
directory del main.py (crealo con la trasparenza) e genera la struttura
con tutte le versioni di icone ridimensionate come serve a Flutter.
```
source venv/bin/activate

python3 main.py
```
