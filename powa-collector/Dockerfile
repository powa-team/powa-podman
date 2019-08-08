#vim:set ft=dockerfile
FROM debian:stretch-slim
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    libpq5 \
    libpq-dev \
    python \
    python-dev \
    python-pip \
    && pip install powa-collector \
    && apt-get purge -y --auto-remove libpq-dev python-dev python-pip \
    && rm -rf /var/lib/apt/lists/*

COPY powa-collector.conf /etc/

EXPOSE 8888
CMD ["powa-collector.py"]
