FROM golang:1.10-alpine3.7 as builder
RUN apk --no-cache add git
COPY src /go/src/
WORKDIR /go/src/
RUN go get -d -v ./...
RUN go install -v route_guide/server
RUN go install -v route_guide/client

FROM alpine:3.7
COPY --from=builder /go/bin/server /server
COPY --from=builder /go/bin/client /client
CMD ["/server", "--port=10000"]
