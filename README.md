# Cartes de visite numériques — Charlemagne Groupe

Mini-site statique qui héberge les cartes de visite numériques des conseillers du
groupe Charlemagne (Guadeloupe). Chaque carte a une URL courte, partageable par
WhatsApp ou via un QR code imprimé sur la carte physique.

Les cartes sont classées **par pôle** : `/<pôle>/<prénom>`.

**En ligne :** https://charlemagne-groupe.fr
**Première carte :** https://charlemagne-groupe.fr/immobilier/beatrice

## Ce que contient une carte

- Le visuel de la carte physique (photo du recto)
- Nom, titre, marque et services
- 4 actions tactiles : **Appeler**, **WhatsApp**, **Envoyer un e-mail**,
  **Enregistrer le contact** (fichier vCard `.vcf`)
- Un bouton **Partager** (partage natif du téléphone, sinon copie du lien)
- Des métadonnées Open Graph pour un aperçu propre quand le lien est envoyé
  sur WhatsApp ou LinkedIn

## Arborescence

```
cartes-charlemagne/
├── Dockerfile              # nginx:alpine + config + contenu statique
├── nginx.conf              # URLs propres, redirections, gzip, cache, 404, text/vcard
├── README.md
└── static/
    ├── index.html          # accueil : les cartes regroupées par pôle
    ├── 404.html
    ├── immobilier/                     # un dossier par pôle
    │   └── beatrice/
    │       ├── index.html              # la carte de Béatrice ZENARRE
    │       └── beatrice.vcf            # vCard 3.0 (UTF-8, fins de ligne CRLF)
    └── assets/
        └── immobilier/
            └── beatrice/
                └── carte-recto.png     # photo du recto de la carte physique
```

### Anciennes URL

La carte de Béatrice a d'abord vécu à `/beatrice`. `nginx.conf` garde une
redirection **301** de `/beatrice` (et de `/beatrice/beatrice.vcf`) vers la
nouvelle adresse, pour que les liens et QR codes déjà diffusés continuent de
fonctionner. Ne pas supprimer ces règles.

## Technique

- HTML / CSS / JS **vanilla**, aucun framework, aucun CDN JavaScript.
  Seule ressource externe : Google Fonts (Cormorant Garamond + Inter).
- Tout le CSS et le JS d'une carte vivent dans son `index.html` : une carte =
  un fichier autonome, facile à dupliquer.
- Pas d'étape de build. Ce qui est dans `static/` est ce qui est servi.

## Tester en local

**Option 1 — serveur Python (le plus rapide)**

```bash
cd static
python3 -m http.server 8080
```

Puis ouvrir http://localhost:8080/immobilier/beatrice/
⚠️ Avec cette méthode il faut le **slash final** : les URLs propres sans slash
et les redirections des anciennes adresses sont gérées par nginx, pas par le
serveur Python.

**Option 2 — Docker (identique à la production)**

```bash
docker build -t cartes-charlemagne .
docker run --rm -p 8080:80 cartes-charlemagne
```

Puis ouvrir http://localhost:8080/immobilier/beatrice — l'URL propre fonctionne,
ainsi que les redirections, la page 404 et le bon type `text/vcard`.

Vérifications rapides :

```bash
curl -I http://localhost:8080/immobilier/beatrice              # 200
curl -I http://localhost:8080/immobilier/beatrice/beatrice.vcf # text/vcard; charset=utf-8
curl -I http://localhost:8080/beatrice                         # 301 -> /immobilier/beatrice
curl -I http://localhost:8080/nimportequoi                     # 404
curl    http://localhost:8080/healthz                          # ok
```

## Ajouter une nouvelle carte (exemple : Boris, pôle assurance)

1. **Créer le dossier de la page**, sous le pôle concerné

   ```bash
   mkdir -p static/assurance/boris static/assets/assurance/boris
   cp static/immobilier/beatrice/index.html static/assurance/boris/index.html
   cp static/immobilier/beatrice/beatrice.vcf static/assurance/boris/boris.vcf
   ```

2. **Modifier `static/assurance/boris/index.html`** — tout est dans ce seul
   fichier :
   - `<title>`, `<meta name="description">` et les balises `og:` / `twitter:`
     (dont `og:url` → `/assurance/boris` et `og:image` →
     `/assets/assurance/boris/carte-recto.png`, en **URL absolue**)
   - `og:image:width` / `og:image:height` : les dimensions réelles de la photo
   - le `<link rel="canonical">`
   - le chemin de l'image et son texte alternatif
   - `aspect-ratio` de `.card-visual` : le ratio réel de la photo
     (ex. `750 / 492`), sinon la carte est rognée
   - le bloc de repli (`card-fallback`) affiché si la photo ne charge pas
   - le nom, le titre, la marque et la liste des services
   - les 4 liens d'action : `tel:`, `wa.me/`, `mailto:` et
     `href="/assurance/boris/boris.vcf"` (garder l'attribut `download`)
   - l'objet `payload` du script de partage, en bas de page

3. **Modifier `static/assurance/boris/boris.vcf`** — nom, société, titre,
   téléphone, e-mail, URL. Le fichier doit rester en **UTF-8 avec des fins de
   ligne CRLF**. Pour le régénérer proprement :

   ```bash
   printf 'BEGIN:VCARD\r\nVERSION:3.0\r\n...\r\nEND:VCARD\r\n' \
     > static/assurance/boris/boris.vcf
   ```

4. **Déposer la photo** du recto de la carte dans
   `static/assets/assurance/boris/carte-recto.png` (format paysage, largeur
   conseillée ≥ 750 px, poids < 500 Ko). Reporter ses dimensions réelles dans
   `aspect-ratio`, `width`/`height` de la balise `<img>` et les balises
   `og:image:width` / `og:image:height`.

5. **Référencer la carte sur l'accueil** : dans `static/index.html`, ajouter un
   `<li>` en copiant celui de Béatrice. Si le pôle n'existe pas encore, ajouter
   un titre `<h2>` et une nouvelle liste.

6. **Tester** avec Docker, en 375 px de large **et** en 1440 px.

### Numéros de téléphone — piège Guadeloupe

En Guadeloupe, un mobile `0690…` / `0691…` a l'indicatif **+590**, pas +33.

| Affiché | `tel:` | WhatsApp |
|---|---|---|
| 06 91 24 71 85 | `tel:+590691247185` | `https://wa.me/590691247185` |

Le `0` initial est conservé après l'indicatif : `+590` **6** `91247185` →
`+590691247185`. WhatsApp veut le même numéro **sans** le `+`.

## Déploiement

Le site est déployé via Coolify à partir de ce dépôt (build Docker à la racine).
Aucune variable d'environnement n'est nécessaire. Le conteneur expose le port 80
et répond `ok` sur `/healthz` pour le healthcheck.

Après un déploiement, vérifier visuellement la page — un code HTTP 200 ne suffit
pas à prouver que la carte s'affiche correctement.
