FROM python:3.11-alpine

RUN adduser -D -u 54000 radio && \
        apk update && \
        apk add git gcc musl-dev && \
        mkdir -p /opt/adn-server && \
        pip install --no-cache-dir bitstring bitarray Twisted dmr_utils3 configparser resettabletimer \
        setproctitle Pyro5 spyne && \
        apk del git gcc musl-dev && \
        chown -R radio: /opt/adn-server

COPY entrypoint /entrypoint

USER radio

ENTRYPOINT [ "/entrypoint" ]
