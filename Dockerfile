# Cartes de visite numériques — Charlemagne Groupe
# Site 100 % statique servi par nginx.
FROM nginx:alpine

# curl sert au healthcheck (absent de l'image nginx:alpine par défaut).
RUN apk add --no-cache curl

# Configuration du serveur (URLs propres, gzip, cache, page 404, text/vcard)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Contenu du site
COPY static/ /usr/share/nginx/html/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
