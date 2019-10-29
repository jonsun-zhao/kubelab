FROM alpine:edge as builder
ARG K8S_VERSION=v1.14.3
RUN set -x                  && \
    apk --update upgrade    && \
    apk add ca-certificates && \
    rm -rf /var/cache/apk/* && \
    wget -O /kubectl https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    chmod +x /kubectl

FROM alpine:edge
RUN apk --no-cache add openssl
COPY --from=builder /kubectl /bin/kubectl
COPY src/ /
CMD ["kubectl"]