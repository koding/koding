// Copyright (c) 2015-2016 Marin Atanasov Nikolov <dnaeon@gmail.com>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package vcr_test

import (
	"testing"
	"time"

	"github.com/dnaeon/go-vcr/recorder"

	"github.com/coreos/etcd/client"
	"golang.org/x/net/context"
)

func TestEtcd(t *testing.T) {
	// Start our recorder
	r, err := recorder.New("fixtures/etcd")
	if err != nil {
		t.Fatal(err)
	}
	defer r.Stop() // Make sure recorder is stopped once done with it

	// Create an etcd configuration using our transport
	cfg := client.Config{
		Endpoints:               []string{"http://127.0.0.1:2379"},
		HeaderTimeoutPerRequest: time.Second,
		Transport:               r.Transport, // Inject our transport!
	}

	// Create an etcd client using the above configuration
	c, err := client.New(cfg)
	if err != nil {
		t.Fatalf("Failed to create etcd client: %s", err)
	}

	kapi := client.NewKeysAPI(c)

	// Etcd key and value we use
	wantKey := "/foo"
	wantValue := "bar"

	// Set the key in etcd
	_, err = kapi.Set(context.Background(), wantKey, wantValue, nil)
	if err != nil {
		t.Fatalf("Failed to set etcd key: %s", err)
	}

	// Get the key from etcd
	resp, err := kapi.Get(context.Background(), wantKey, nil)
	if err != nil {
		t.Fatalf("Failed to get etcd key: %s", err)
	}

	gotValue := resp.Node.Value
	if wantValue != gotValue {
		t.Errorf("want %q value, got %q value", wantValue, gotValue)
	}
}
