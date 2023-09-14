from PIL import Image
import os


config = {
    'inputPng': 'ic_launcher.png',
    'outputName': 'ic_launcher.png',
    'riduciProfonditaColore': False,
    'outputRootDir': 'res',
    'outputRules': [
        # output dir, size
        ['mipmap-hdpi', (72, 72)],
        ['mipmap-mdpi', (48, 48)],
        ['mipmap-xhdpi', (96, 96)],
        ['mipmap-xxhdpi', (144, 144)],
        ['mipmap-xxxhdpi', (192, 192)]
    ]
}

# Apri l'immagine PNG
immagine = Image.open(config['inputPng'])

# Creo cartella root che contiene le altre
os.mkdir(config['outputRootDir'])

# creo le cartelle con dentro le icone ridimensionate
for o in config['outputRules']:
    # creo subdir
    new_dir = '{}/{}'.format(config['outputRootDir'], o[0])
    os.mkdir(new_dir)

    if config['reduceDeepColor']:
        # riduco la profondita del colore, 2^(8 bit) => 256 colori
        new_img = immagine.convert('P', palette=Image.ADAPTIVE, colors=256)
        
    # resize dell'immagine
    new_img = new_img.resize(o[1])
    # salva immagine nella directory
    new_img.save('{}/{}'.format(new_dir, config['outputName']))
    new_img.close()

'''
# Converte l'immagine in 8 bit (256 colori)
immagine = immagine.convert('P', palette=Image.ADAPTIVE, colors=256)

# Esegui il resize dell'immagine
immagine = immagine.resize((64, 64))

# Salva l'immagine ridotta in 8 bit
immagine.save('ic_launcher_64.png')
'''

# Chiudi l'immagine
immagine.close()
