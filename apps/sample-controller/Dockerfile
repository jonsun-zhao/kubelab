FROM golang:1.12-alpine3.9 as builder
RUN apk --no-cache add git

RUN mkdir /sample-controller
WORKDIR /sample-controller

# COPY go.mod and go.sum files to the workspace
COPY src/go.mod . 
COPY src/go.sum .

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download
# COPY the source code as the last step
COPY src .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/sample-controller

FROM alpine:3.9
RUN apk --no-cache add curl
COPY --from=builder /go/bin/sample-controller /sample-controller
ENTRYPOINT ["/sample-controller"]
