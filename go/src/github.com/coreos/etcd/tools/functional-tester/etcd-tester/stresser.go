// Copyright 2015 CoreOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/Godeps/_workspace/src/google.golang.org/grpc"
	"github.com/coreos/etcd/Godeps/_workspace/src/google.golang.org/grpc/grpclog"
	clientV2 "github.com/coreos/etcd/client"
	pb "github.com/coreos/etcd/etcdserver/etcdserverpb"
)

func init() {
	grpclog.SetLogger(log.New(ioutil.Discard, "", 0))
}

type Stresser interface {
	// Stress starts to stress the etcd cluster
	Stress() error
	// Cancel cancels the stress test on the etcd cluster
	Cancel()
	// Report reports the success and failure of the stress test
	Report() (success int, failure int)
}

type stresser struct {
	Endpoint string

	KeySize        int
	KeySuffixRange int

	N int

	mu     sync.Mutex
	wg     *sync.WaitGroup
	cancel func()
	conn   *grpc.ClientConn

	success int
}

func (s *stresser) Stress() error {
	conn, err := grpc.Dial(s.Endpoint, grpc.WithInsecure(), grpc.WithTimeout(5*time.Second))
	if err != nil {
		return fmt.Errorf("%v (%s)", err, s.Endpoint)
	}
	defer conn.Close()
	ctx, cancel := context.WithCancel(context.Background())

	wg := &sync.WaitGroup{}
	wg.Add(s.N)

	s.mu.Lock()
	s.conn = conn
	s.cancel = cancel
	s.wg = wg
	s.mu.Unlock()

	kvc := pb.NewKVClient(conn)

	for i := 0; i < s.N; i++ {
		go func(i int) {
			defer wg.Done()
			for {
				// TODO: 10-second is enough timeout to cover leader failure
				// and immediate leader election. Find out what other cases this
				// could be timed out.
				putctx, putcancel := context.WithTimeout(ctx, 10*time.Second)
				_, err := kvc.Put(putctx, &pb.PutRequest{
					Key:   []byte(fmt.Sprintf("foo%d", rand.Intn(s.KeySuffixRange))),
					Value: []byte(randStr(s.KeySize)),
				})
				putcancel()
				if err != nil {
					if grpc.ErrorDesc(err) == context.DeadlineExceeded.Error() {
						// This retries when request is triggered at the same time as
						// leader failure. When we terminate the leader, the request to
						// that leader cannot be processed, and times out. Also requests
						// to followers cannot be forwarded to the old leader, so timing out
						// as well. We want to keep stressing until the cluster elects a
						// new leader and start processing requests again.
						continue
					}
					return
				}
				s.mu.Lock()
				s.success++
				s.mu.Unlock()
			}
		}(i)
	}

	<-ctx.Done()
	return nil
}

func (s *stresser) Cancel() {
	s.mu.Lock()
	cancel, conn, wg := s.cancel, s.conn, s.wg
	s.mu.Unlock()
	cancel()
	wg.Wait()
	conn.Close()
}

func (s *stresser) Report() (int, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	// TODO: find a better way to report v3 tests
	return s.success, -1
}

type stresserV2 struct {
	Endpoint string

	KeySize        int
	KeySuffixRange int

	N int
	// TODO: not implemented
	Interval time.Duration

	mu      sync.Mutex
	failure int
	success int

	cancel func()
}

func (s *stresserV2) Stress() error {
	cfg := clientV2.Config{
		Endpoints: []string{s.Endpoint},
		Transport: &http.Transport{
			Dial: (&net.Dialer{
				Timeout:   time.Second,
				KeepAlive: 30 * time.Second,
			}).Dial,
			MaxIdleConnsPerHost: s.N,
		},
	}
	c, err := clientV2.New(cfg)
	if err != nil {
		return err
	}

	kv := clientV2.NewKeysAPI(c)
	ctx, cancel := context.WithCancel(context.Background())
	s.cancel = cancel

	for i := 0; i < s.N; i++ {
		go func() {
			for {
				setctx, setcancel := context.WithTimeout(ctx, clientV2.DefaultRequestTimeout)
				key := fmt.Sprintf("foo%d", rand.Intn(s.KeySuffixRange))
				_, err := kv.Set(setctx, key, randStr(s.KeySize), nil)
				setcancel()
				if err == context.Canceled {
					return
				}
				s.mu.Lock()
				if err != nil {
					s.failure++
				} else {
					s.success++
				}
				s.mu.Unlock()
			}
		}()
	}

	<-ctx.Done()
	return nil
}

func (s *stresserV2) Cancel() {
	s.cancel()
}

func (s *stresserV2) Report() (success int, failure int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.success, s.failure
}

func randStr(size int) string {
	data := make([]byte, size)
	for i := 0; i < size; i++ {
		data[i] = byte(int('a') + rand.Intn(26))
	}
	return string(data)
}
