FROM nginx
COPY dist/ /usr/share/nginx/html/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

LABEL version = $TAG_VERSION
EXPOSE 80
