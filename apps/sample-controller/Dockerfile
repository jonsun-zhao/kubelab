FROM golang:1.12-alpine3.9 as builder
RUN apk --no-cache add git

RUN git clone -q https://github.com/neoseele/sample-controller.git /sample-controller
WORKDIR /sample-controller

# Get dependencies - will also be cached if we won't change mod/sum
RUN go mod download

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/sample-controller

FROM alpine:3.9
RUN apk --no-cache add curl
COPY --from=builder /go/bin/sample-controller /sample-controller
ENTRYPOINT ["/sample-controller"]
