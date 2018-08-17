FROM golang:1.10-alpine3.7 as builder
RUN apk --no-cache add git
COPY src /go/src/
RUN go get ./...
RUN go install ./...

FROM alpine:3.7
RUN apk --no-cache add curl
COPY --from=builder /go/bin/go-log /go-log
ENTRYPOINT ["/go-log"]
