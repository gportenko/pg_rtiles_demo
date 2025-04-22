FROM rust:1.85-slim-bookworm as tileserver

RUN apt update && \
    apt install -y wget unzip

RUN wget https://github.com/gportenko/pg_rtiles/archive/refs/heads/master.zip -O pg_rtiles.zip && \
    unzip pg_rtiles.zip

WORKDIR /pg_rtiles-master/tileserver

RUN cargo build --release

FROM rust:1.85-slim-bookworm

COPY --from=tileserver /pg_rtiles-master/tileserver/target/release/tileserver /tileserver

ENTRYPOINT /tileserver