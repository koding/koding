// Copyright 2016 CoreOS, Inc.
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

package recipe

import (
	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/clientv3"
	pb "github.com/coreos/etcd/etcdserver/etcdserverpb"
	"github.com/coreos/etcd/storage/storagepb"
)

// DoubleBarrier blocks processes on Enter until an expected count enters, then
// blocks again on Leave until all processes have left.
type DoubleBarrier struct {
	client *clientv3.Client
	key    string // key for the collective barrier
	count  int
	myKey  *EphemeralKV // current key for this process on the barrier
}

func NewDoubleBarrier(client *clientv3.Client, key string, count int) *DoubleBarrier {
	return &DoubleBarrier{client, key, count, nil}
}

// Enter waits for "count" processes to enter the barrier then returns
func (b *DoubleBarrier) Enter() error {
	ek, err := NewUniqueEphemeralKey(b.client, b.key+"/waiters")
	if err != nil {
		return err
	}
	b.myKey = ek

	resp, err := NewRange(b.client, b.key+"/waiters").Prefix()
	if err != nil {
		return err
	}

	if len(resp.Kvs) > b.count {
		return ErrTooManyClients
	}

	if len(resp.Kvs) == b.count {
		// unblock waiters
		_, err = putEmptyKey(b.client.KV, b.key+"/ready")
		return err
	}

	_, err = WaitEvents(
		b.client,
		b.key+"/ready",
		resp.Header.Revision,
		[]storagepb.Event_EventType{storagepb.PUT})
	return err
}

// Leave waits for "count" processes to leave the barrier then returns
func (b *DoubleBarrier) Leave() error {
	resp, err := NewRange(b.client, b.key+"/waiters").Prefix()
	if len(resp.Kvs) == 0 {
		return nil
	}

	lowest, highest := resp.Kvs[0], resp.Kvs[0]
	for _, k := range resp.Kvs {
		if k.ModRevision < lowest.ModRevision {
			lowest = k
		}
		if k.ModRevision > highest.ModRevision {
			highest = k
		}
	}
	isLowest := string(lowest.Key) == b.myKey.Key()

	if len(resp.Kvs) == 1 {
		// this is the only node in the barrier; finish up
		req := &pb.DeleteRangeRequest{Key: []byte(b.key + "/ready")}
		if _, err = b.client.KV.DeleteRange(context.TODO(), req); err != nil {
			return err
		}
		return b.myKey.Delete()
	}

	// this ensures that if a process fails, the ephemeral lease will be
	// revoked, its barrier key is removed, and the barrier can resume

	// lowest process in node => wait on highest process
	if isLowest {
		_, err = WaitEvents(
			b.client,
			string(highest.Key),
			resp.Header.Revision,
			[]storagepb.Event_EventType{storagepb.DELETE})
		if err != nil {
			return err
		}
		return b.Leave()
	}

	// delete self and wait on lowest process
	if err := b.myKey.Delete(); err != nil {
		return err
	}

	key := string(lowest.Key)
	_, err = WaitEvents(
		b.client,
		key,
		resp.Header.Revision,
		[]storagepb.Event_EventType{storagepb.DELETE})
	if err != nil {
		return err
	}
	return b.Leave()
}
