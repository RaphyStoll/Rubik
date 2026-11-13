# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# escape=\
# check=error=true

FROM rust:1.99.1-alpine3.24@sha256:44819b27be4c97b0e4d7203bd2e02c4820f97700211b6a37fb4c246a2de59383 AS chef
WORKDIR /app
RUN apk add --no-cache musl-dev
RUN cargo install cargo-chef --locked --version 0.1.78

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release --bin rubik

FROM chef AS dev
RUN cargo install watchexec-cli --locked --version 2.8.0
CMD ["watchexec", "-r", "-e", "rs,toml", "--", "cargo", "run"]

FROM scratch AS prod
COPY --from=builder /app/target/release/rubik /app
USER 10001:10001
ENTRYPOINT ["/app"]
