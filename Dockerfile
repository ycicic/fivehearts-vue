FROM nginx
ENV TAG_VERSION=0.0.2
COPY dist/ /usr/share/nginx/html/
COPY nginx/nginx.conf /etc/nginx/nginx.conf

LABEL version = $TAG_VERSION
EXPOSE 80
