FROM nginx:1.27-alpine

COPY food-delivery-azure/index.html /usr/share/nginx/html/index.html
COPY food-delivery-azure/styles.css /usr/share/nginx/html/styles.css
COPY food-delivery-azure/app.js /usr/share/nginx/html/app.js

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --spider -q http://127.0.0.1/ || exit 1

