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
    git \
    && git clone https://github.com/powa-team/powa-collector.git powa-collector.git \
    && pip install psycopg2 \
    && apt-get purge -y --auto-remove libpq-dev python-dev python-pip git \
    && rm -rf /var/lib/apt/lists/*

COPY powa-collector.conf /etc/

CMD ["powa-collector.git/powa-collector.py"]
