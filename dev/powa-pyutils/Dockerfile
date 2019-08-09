#vim:set ft=dockerfile
FROM debian:stable-slim
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    libpq5 \
    libpq-dev \
    python \
    python-dev \
    python-pip \
    && pip install psycopg2 sqlalchemy tornado \
    && apt-get purge -y --auto-remove libpq-dev python-dev python-pip \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8888
