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
COPY --from=builder /go/src/google.golang.org/grpc/testdata/ca.pem /ca.pem
COPY --from=builder /go/src/google.golang.org/grpc/testdata/server1.pem /server1.pem
COPY --from=builder /go/src/google.golang.org/grpc/testdata/server1.key /server1.key
ENTRYPOINT ["/server"]
CMD ["--port=10000"]
