FROM nginx:1.21.0-alpine

RUN chown -R 1012130000:1012130000 /var/cache/nginx && \
    chown -R 1012130000:1012130000 /var/log/nginx && \
    chown -R 1012130000:1012130000 /etc/nginx/conf.d
RUN mkdir /tmp/run/ && \
    touch /tmp/run/nginx.pid && \
    chown -R 1012130000:1012130000 /tmp/run

COPY ./nginx.conf /etc/nginx/nginx.conf

USER 1012130000

EXPOSE 8080 8443

CMD ["nginx", "-g", "daemon off;"]
