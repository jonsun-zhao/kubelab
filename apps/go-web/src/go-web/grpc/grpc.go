/*
 *
 * Original work Copyright 2015 gRPC authors
 * Modified work Copyright 2019 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

/*
 * Changes:
 * 2019-06-24: SayHello returns hostname in response header
 */

//go:generate protoc -I ../helloworld --go_out=plugins=grpc:../helloworld ../helloworld/helloworld.proto

package grpc

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"go.opencensus.io/plugin/ocgrpc"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	pb "google.golang.org/grpc/examples/helloworld/helloworld"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// GreeterServer is the server API for Greeter service
type GreeterServer struct{}

// SayHello implements helloworld.GreeterServer
func (s *GreeterServer) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	log.Printf("Received: %v", in.Name)
	// [START istio_samples_app_grpc_greeter_server_hostname]
	hostname, err := os.Hostname()
	if err != nil {
		log.Printf("Unable to get hostname %v", err)
	}
	if hostname != "" {
		grpc.SendHeader(ctx, metadata.Pairs("hostname", hostname))
	}
	// [END istio_samples_app_grpc_greeter_server_hostname]
	return &pb.HelloReply{Message: "Hello " + in.Name}, nil
}

// HealthServer is the health check API
type HealthServer struct{}

// Check is used for health checks
func (s *HealthServer) Check(ctx context.Context, in *healthpb.HealthCheckRequest) (*healthpb.HealthCheckResponse, error) {
	log.Printf("Handling Check request [%v]", in)
	return &healthpb.HealthCheckResponse{Status: healthpb.HealthCheckResponse_SERVING}, nil
}

// Watch is not implemented
func (s *HealthServer) Watch(in *healthpb.HealthCheckRequest, srv healthpb.Health_WatchServer) error {
	return status.Error(codes.Unimplemented, "Watch is not implemented")
}

// PingBackend probes the specificed grpc server
func PingBackend(ctx context.Context, grpcBeAddr string, cert string) *[]string {
	// Set up a connection to the server.
	var conn *grpc.ClientConn
	var err error
	if cert == "" {
		conn, err = grpc.Dial(grpcBeAddr, grpc.WithInsecure(), grpc.WithStatsHandler(&ocgrpc.ClientHandler{}))
	} else {
		tc, err := credentials.NewClientTLSFromFile(cert, "")
		if err != nil {
			log.Fatalf("Failed to generate credentials %v", err)
		}
		conn, err = grpc.Dial(grpcBeAddr, grpc.WithTransportCredentials(tc), grpc.WithStatsHandler(&ocgrpc.ClientHandler{}))
	}
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	// Determine name to send to server.
	name, _ := os.Hostname()
	nonFlagArgs := make([]string, 0)
	for _, arg := range os.Args {
		if !strings.HasPrefix(arg, "--") {
			nonFlagArgs = append(nonFlagArgs, arg)
		}
	}
	if len(nonFlagArgs) > 1 {
		name = nonFlagArgs[1]
	}

	timeout := 5 * time.Second
	repeat := 9

	var results []string

	// Contact the server and print out its response multiple times.
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	results = append(results, "== Result ==")

	for i := 0; i < repeat; i++ {
		var header metadata.MD
		r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name}, grpc.Header(&header))
		if err != nil {
			log.Fatalf("could not greet: %v", err)
		}
		hostname := "unknown"
		// [START istio_samples_app_grpc_greeter_client_hostname]
		if len(header["hostname"]) > 0 {
			hostname = header["hostname"][0]
		}
		log.Printf("%s from %s", r.Message, hostname)
		results = append(results, fmt.Sprintf("%s from %s", r.Message, hostname))
		// [END istio_samples_app_grpc_greeter_client_hostname]
	}

	return &results
}
