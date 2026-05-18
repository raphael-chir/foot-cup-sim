FROM registry.access.redhat.com/ubi9/nodejs-20 AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build


FROM registry.access.redhat.com/ubi9/nginx-124

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /opt/app-root/src
COPY public/config.js /opt/app-root/src/config.js
COPY docker-entrypoint.sh /docker-entrypoint.sh

USER root
RUN chmod +x /docker-entrypoint.sh \
  && chown -R 1001:0 /opt/app-root/src /docker-entrypoint.sh \
  && chmod -R g=u /opt/app-root/src

USER 1001

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]