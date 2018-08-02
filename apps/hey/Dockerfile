FROM golang:1.10-alpine3.7 as builder
RUN apk add --no-cache git
RUN go get -u github.com/rakyll/hey

FROM alpine:3.7
COPY --from=builder /go/bin/hey /hey
ENTRYPOINT ["/hey"]
