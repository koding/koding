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
// limitations under the License.package recipe
package integration

import (
	"fmt"
	"testing"
	"time"

	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
	"github.com/coreos/etcd/etcdserver/api/v3rpc"
	pb "github.com/coreos/etcd/etcdserver/etcdserverpb"
	"github.com/coreos/etcd/pkg/testutil"
	"github.com/coreos/etcd/storage/storagepb"
)

// TestV3LeasePrmote ensures the newly elected leader can promote itself
// to the primary lessor, refresh the leases and start to manage leases.
// TODO: use customized clock to make this test go faster?
func TestV3LeasePrmote(t *testing.T) {
	clus := NewClusterV3(t, &ClusterConfig{Size: 3})
	defer clus.Terminate(t)

	// create lease
	lresp, err := toGRPC(clus.RandClient()).Lease.LeaseCreate(context.TODO(), &pb.LeaseCreateRequest{TTL: 5})
	if err != nil {
		t.Fatal(err)
	}
	if lresp.Error != "" {
		t.Fatal(lresp.Error)
	}

	// wait until the lease is going to expire.
	time.Sleep(time.Duration(lresp.TTL-1) * time.Second)

	// kill the current leader, all leases should be refreshed.
	toStop := clus.waitLeader(t, clus.Members)
	clus.Members[toStop].Stop(t)

	var toWait []*member
	for i, m := range clus.Members {
		if i != toStop {
			toWait = append(toWait, m)
		}
	}
	clus.waitLeader(t, toWait)
	clus.Members[toStop].Restart(t)
	clus.waitLeader(t, clus.Members)

	// ensure lease is refreshed by waiting for a "long" time.
	// it was going to expire anyway.
	time.Sleep(3 * time.Second)

	if !leaseExist(t, clus, lresp.ID) {
		t.Error("unexpected lease not exists")
	}

	// let lease expires. total lease = 5 seconds and we already
	// waits for 3 seconds, so 3 seconds more is enough.
	time.Sleep(3 * time.Second)
	if leaseExist(t, clus, lresp.ID) {
		t.Error("unexpected lease exists")
	}
}

// TestV3LeaseRevoke ensures a key is deleted once its lease is revoked.
func TestV3LeaseRevoke(t *testing.T) {
	defer testutil.AfterTest(t)
	testLeaseRemoveLeasedKey(t, func(clus *ClusterV3, leaseID int64) error {
		lc := toGRPC(clus.RandClient()).Lease
		_, err := lc.LeaseRevoke(context.TODO(), &pb.LeaseRevokeRequest{ID: leaseID})
		return err
	})
}

// TestV3LeaseCreateById ensures leases may be created by a given id.
func TestV3LeaseCreateByID(t *testing.T) {
	defer testutil.AfterTest(t)
	clus := NewClusterV3(t, &ClusterConfig{Size: 3})
	defer clus.Terminate(t)

	// create fixed lease
	lresp, err := toGRPC(clus.RandClient()).Lease.LeaseCreate(
		context.TODO(),
		&pb.LeaseCreateRequest{ID: 1, TTL: 1})
	if err != nil {
		t.Errorf("could not create lease 1 (%v)", err)
	}
	if lresp.ID != 1 {
		t.Errorf("got id %v, wanted id %v", lresp.ID, 1)
	}

	// create duplicate fixed lease
	lresp, err = toGRPC(clus.RandClient()).Lease.LeaseCreate(
		context.TODO(),
		&pb.LeaseCreateRequest{ID: 1, TTL: 1})
	if err != v3rpc.ErrLeaseExist {
		t.Error(err)
	}

	// create fresh fixed lease
	lresp, err = toGRPC(clus.RandClient()).Lease.LeaseCreate(
		context.TODO(),
		&pb.LeaseCreateRequest{ID: 2, TTL: 1})
	if err != nil {
		t.Errorf("could not create lease 2 (%v)", err)
	}
	if lresp.ID != 2 {
		t.Errorf("got id %v, wanted id %v", lresp.ID, 2)
	}
}

// TestV3LeaseExpire ensures a key is deleted once a key expires.
func TestV3LeaseExpire(t *testing.T) {
	defer testutil.AfterTest(t)
	testLeaseRemoveLeasedKey(t, func(clus *ClusterV3, leaseID int64) error {
		// let lease lapse; wait for deleted key

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		wStream, err := toGRPC(clus.RandClient()).Watch.Watch(ctx)
		if err != nil {
			return err
		}

		wreq := &pb.WatchRequest{RequestUnion: &pb.WatchRequest_CreateRequest{
			CreateRequest: &pb.WatchCreateRequest{
				Key: []byte("foo"), StartRevision: 1}}}
		if err := wStream.Send(wreq); err != nil {
			return err
		}
		if _, err := wStream.Recv(); err != nil {
			// the 'created' message
			return err
		}
		if _, err := wStream.Recv(); err != nil {
			// the 'put' message
			return err
		}

		errc := make(chan error, 1)
		go func() {
			resp, err := wStream.Recv()
			switch {
			case err != nil:
				errc <- err
			case len(resp.Events) != 1:
				fallthrough
			case resp.Events[0].Type != storagepb.DELETE:
				errc <- fmt.Errorf("expected key delete, got %v", resp)
			default:
				errc <- nil
			}
		}()

		select {
		case <-time.After(15 * time.Second):
			return fmt.Errorf("lease expiration too slow")
		case err := <-errc:
			return err
		}
	})
}

// TestV3LeaseKeepAlive ensures keepalive keeps the lease alive.
func TestV3LeaseKeepAlive(t *testing.T) {
	defer testutil.AfterTest(t)
	testLeaseRemoveLeasedKey(t, func(clus *ClusterV3, leaseID int64) error {
		lc := toGRPC(clus.RandClient()).Lease
		lreq := &pb.LeaseKeepAliveRequest{ID: leaseID}
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		lac, err := lc.LeaseKeepAlive(ctx)
		if err != nil {
			return err
		}
		defer lac.CloseSend()

		// renew long enough so lease would've expired otherwise
		for i := 0; i < 3; i++ {
			if err = lac.Send(lreq); err != nil {
				return err
			}
			lresp, rxerr := lac.Recv()
			if rxerr != nil {
				return rxerr
			}
			if lresp.ID != leaseID {
				return fmt.Errorf("expected lease ID %v, got %v", leaseID, lresp.ID)
			}
			time.Sleep(time.Duration(lresp.TTL/2) * time.Second)
		}
		_, err = lc.LeaseRevoke(context.TODO(), &pb.LeaseRevokeRequest{ID: leaseID})
		return err
	})
}

// TestV3LeaseExists creates a lease on a random client and confirms it exists in the cluster.
func TestV3LeaseExists(t *testing.T) {
	defer testutil.AfterTest(t)
	clus := NewClusterV3(t, &ClusterConfig{Size: 3})
	defer clus.Terminate(t)

	// create lease
	ctx0, cancel0 := context.WithCancel(context.Background())
	defer cancel0()
	lresp, err := toGRPC(clus.RandClient()).Lease.LeaseCreate(
		ctx0,
		&pb.LeaseCreateRequest{TTL: 30})
	if err != nil {
		t.Fatal(err)
	}
	if lresp.Error != "" {
		t.Fatal(lresp.Error)
	}

	if !leaseExist(t, clus, lresp.ID) {
		t.Error("unexpected lease not exists")
	}
}

// TestV3LeaseSwitch tests a key can be switched from one lease to another.
func TestV3LeaseSwitch(t *testing.T) {
	defer testutil.AfterTest(t)
	clus := NewClusterV3(t, &ClusterConfig{Size: 3})
	defer clus.Terminate(t)

	key := "foo"

	// create lease
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	lresp1, err1 := toGRPC(clus.RandClient()).Lease.LeaseCreate(ctx, &pb.LeaseCreateRequest{TTL: 30})
	if err1 != nil {
		t.Fatal(err1)
	}
	lresp2, err2 := toGRPC(clus.RandClient()).Lease.LeaseCreate(ctx, &pb.LeaseCreateRequest{TTL: 30})
	if err2 != nil {
		t.Fatal(err2)
	}

	// attach key on lease1 then switch it to lease2
	put1 := &pb.PutRequest{Key: []byte(key), Lease: lresp1.ID}
	_, err := toGRPC(clus.RandClient()).KV.Put(ctx, put1)
	if err != nil {
		t.Fatal(err)
	}
	put2 := &pb.PutRequest{Key: []byte(key), Lease: lresp2.ID}
	_, err = toGRPC(clus.RandClient()).KV.Put(ctx, put2)
	if err != nil {
		t.Fatal(err)
	}

	// revoke lease1 should not remove key
	_, err = toGRPC(clus.RandClient()).Lease.LeaseRevoke(ctx, &pb.LeaseRevokeRequest{ID: lresp1.ID})
	if err != nil {
		t.Fatal(err)
	}
	rreq := &pb.RangeRequest{Key: []byte("foo")}
	rresp, err := toGRPC(clus.RandClient()).KV.Range(context.TODO(), rreq)
	if err != nil {
		t.Fatal(err)
	}
	if len(rresp.Kvs) != 1 {
		t.Fatalf("unexpect removal of key")
	}

	// revoke lease2 should remove key
	_, err = toGRPC(clus.RandClient()).Lease.LeaseRevoke(ctx, &pb.LeaseRevokeRequest{ID: lresp2.ID})
	if err != nil {
		t.Fatal(err)
	}
	rresp, err = toGRPC(clus.RandClient()).KV.Range(context.TODO(), rreq)
	if err != nil {
		t.Fatal(err)
	}
	if len(rresp.Kvs) != 0 {
		t.Fatalf("lease removed but key remains")
	}
}

// acquireLeaseAndKey creates a new lease and creates an attached key.
func acquireLeaseAndKey(clus *ClusterV3, key string) (int64, error) {
	// create lease
	lresp, err := toGRPC(clus.RandClient()).Lease.LeaseCreate(
		context.TODO(),
		&pb.LeaseCreateRequest{TTL: 1})
	if err != nil {
		return 0, err
	}
	if lresp.Error != "" {
		return 0, fmt.Errorf(lresp.Error)
	}
	// attach to key
	put := &pb.PutRequest{Key: []byte(key), Lease: lresp.ID}
	if _, err := toGRPC(clus.RandClient()).KV.Put(context.TODO(), put); err != nil {
		return 0, err
	}
	return lresp.ID, nil
}

// testLeaseRemoveLeasedKey performs some action while holding a lease with an
// attached key "foo", then confirms the key is gone.
func testLeaseRemoveLeasedKey(t *testing.T, act func(*ClusterV3, int64) error) {
	clus := NewClusterV3(t, &ClusterConfig{Size: 3})
	defer clus.Terminate(t)

	leaseID, err := acquireLeaseAndKey(clus, "foo")
	if err != nil {
		t.Fatal(err)
	}

	if err = act(clus, leaseID); err != nil {
		t.Fatal(err)
	}

	// confirm no key
	rreq := &pb.RangeRequest{Key: []byte("foo")}
	rresp, err := toGRPC(clus.RandClient()).KV.Range(context.TODO(), rreq)
	if err != nil {
		t.Fatal(err)
	}
	if len(rresp.Kvs) != 0 {
		t.Fatalf("lease removed but key remains")
	}
}

func leaseExist(t *testing.T, clus *ClusterV3, leaseID int64) bool {
	l := toGRPC(clus.RandClient()).Lease

	_, err := l.LeaseCreate(context.Background(), &pb.LeaseCreateRequest{ID: leaseID, TTL: 5})
	if err == nil {
		_, err = l.LeaseRevoke(context.Background(), &pb.LeaseRevokeRequest{ID: leaseID})
		if err != nil {
			t.Fatalf("failed to check lease %v", err)
		}
		return false
	}

	if err == v3rpc.ErrLeaseExist {
		return true
	}
	t.Fatalf("unexpecter error %v", err)

	return true
}
