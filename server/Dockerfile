FROM debian:stable-slim
RUN \
  apt-get update && \
  apt-get install -y ca-certificates && \
  apt-get clean

ADD output/lumina_server /server

WORKDIR /
CMD ["bash", "-c", "/server"]