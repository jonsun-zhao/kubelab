FROM golang:1.12-alpine3.9 as builder
RUN apk --no-cache add git openssl

RUN mkdir /go-web
WORKDIR /go-web
COPY src/go-web/go.mod .
COPY src/go-web/go.sum .

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download
# COPY the source code as the last step so the `go mod download` layer can be reused
COPY src/go-web .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/go-web

# Create default tls cert/key pair
RUN openssl req -x509 -newkey rsa:2048 \
  -subj "/C=US/ST=California/L=San Francisco/O=CPS/CN=localhost" \
  -keyout tls.key -out tls.crt -days 3650 -nodes -sha256

FROM alpine:3.9
RUN apk --no-cache add curl
COPY --from=builder /go/bin/go-web /go-web
COPY --from=builder /go-web/tls.crt /tls/tls.crt
COPY --from=builder /go-web/tls.key /tls/tls.key
VOLUME /data
ENTRYPOINT ["/go-web"]