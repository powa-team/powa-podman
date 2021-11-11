#vim:set ft=dockerfile
FROM debian:stable-slim
MAINTAINER Julien Rouhaud <rjuju123@gmail.com>

WORKDIR /usr/local/src

RUN apt-get update && apt-get install -y \
    libpq5 \
    libpq-dev \
    python3 \
    python3-dev \
    python3-pip \
    git \
    && git clone https://github.com/powa-team/powa-web.git powa-web.git \
    && pip3 install psycopg2 sqlalchemy tornado \
    && apt-get purge -y --auto-remove libpq-dev python3-dev python3-pip git \
    && rm -rf /var/lib/apt/lists/*

COPY powa-web.conf /etc/

EXPOSE 8888
CMD ["python3", "powa-web.git/run_powa.py"]
