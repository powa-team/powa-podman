# vim:set ft=dockerfile:
FROM debian:stable-slim
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

RUN apt-get update && apt-get install -y \
    libpq5 \
    postgresql \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*
