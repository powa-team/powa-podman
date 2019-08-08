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
    && git clone https://github.com/powa-team/powa-web.git powa-web.git \
    && pip install psycopg2 sqlalchemy tornado \
    && apt-get purge -y --auto-remove libpq-dev python-dev python-pip git \
    && rm -rf /var/lib/apt/lists/*

COPY powa-web.conf /etc/

EXPOSE 8888
CMD ["powa-web.git/run_powa.py"]
