FROM ubuntu:22.04 AS builder
LABEL stage=builder

WORKDIR /indexify-build

COPY ./ .

RUN apt-get update

RUN apt-get install -y \
    build-essential \
    curl pkg-config python3 python3-dev python3-venv 

RUN apt -y install protobuf-compiler protobuf-compiler-grpc sqlite3 libssl-dev

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"

ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse

RUN cargo build --release

RUN cargo build --package migration --release

RUN python3 -m "venv" /venv

RUN /venv/bin/pip install .

FROM ubuntu:22.04

RUN apt update

RUN apt install -y libssl-dev gcc python3-dev

WORKDIR /indexify

COPY --from=builder /indexify-build/target/release/indexify ./

COPY --from=builder /indexify-build/target/release/migration ./

COPY --from=builder /indexify-build/sample_config.yaml ./config/indexify.yaml

COPY ./scripts/docker_compose_start.sh .

COPY --from=builder /venv /venv

ENV PATH=/venv/bin:$PATH

# This serves as a test to ensure the binary actually works
CMD [ "/indexify/indexify", "start", "-c", "./config/indexify.yaml" ]
