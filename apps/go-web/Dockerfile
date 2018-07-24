FROM golang:1.10-alpine3.7 as builder
COPY src /go/src/
RUN go install ./...

FROM alpine:3.7
COPY --from=builder /go/bin/go-web /go-web
COPY resources /
VOLUME /data
ENTRYPOINT ["/go-web"]
