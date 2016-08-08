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

package integration

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strconv"
	"testing"

	"github.com/coreos/etcd/client"
	"github.com/coreos/etcd/pkg/testutil"

	"github.com/coreos/etcd/Godeps/_workspace/src/golang.org/x/net/context"
)

func init() {
	// open microsecond-level time log for integration test debugging
	log.SetFlags(log.Ltime | log.Lmicroseconds | log.Lshortfile)
	if t := os.Getenv("ETCD_ELECTION_TIMEOUT_TICKS"); t != "" {
		if i, err := strconv.ParseInt(t, 10, 64); err == nil {
			electionTicks = int(i)
		}
	}
}

func TestClusterOf1(t *testing.T) { testCluster(t, 1) }
func TestClusterOf3(t *testing.T) { testCluster(t, 3) }

func testCluster(t *testing.T, size int) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, size)
	c.Launch(t)
	defer c.Terminate(t)
	clusterMustProgress(t, c.Members)
}

func TestTLSClusterOf3(t *testing.T) {
	defer testutil.AfterTest(t)
	c := NewClusterByConfig(t, &ClusterConfig{Size: 3, UsePeerTLS: true})
	c.Launch(t)
	defer c.Terminate(t)
	clusterMustProgress(t, c.Members)
}

func TestClusterOf1UsingDiscovery(t *testing.T) { testClusterUsingDiscovery(t, 1) }
func TestClusterOf3UsingDiscovery(t *testing.T) { testClusterUsingDiscovery(t, 3) }

func testClusterUsingDiscovery(t *testing.T, size int) {
	defer testutil.AfterTest(t)
	dc := NewCluster(t, 1)
	dc.Launch(t)
	defer dc.Terminate(t)
	// init discovery token space
	dcc := mustNewHTTPClient(t, dc.URLs())
	dkapi := client.NewKeysAPI(dcc)
	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	if _, err := dkapi.Create(ctx, "/_config/size", fmt.Sprintf("%d", size)); err != nil {
		t.Fatal(err)
	}
	cancel()

	c := NewClusterByConfig(
		t,
		&ClusterConfig{Size: size, DiscoveryURL: dc.URL(0) + "/v2/keys"},
	)
	c.Launch(t)
	defer c.Terminate(t)
	clusterMustProgress(t, c.Members)
}

func TestTLSClusterOf3UsingDiscovery(t *testing.T) {
	defer testutil.AfterTest(t)
	dc := NewCluster(t, 1)
	dc.Launch(t)
	defer dc.Terminate(t)
	// init discovery token space
	dcc := mustNewHTTPClient(t, dc.URLs())
	dkapi := client.NewKeysAPI(dcc)
	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	if _, err := dkapi.Create(ctx, "/_config/size", fmt.Sprintf("%d", 3)); err != nil {
		t.Fatal(err)
	}
	cancel()

	c := NewClusterByConfig(t,
		&ClusterConfig{
			Size:         3,
			UsePeerTLS:   true,
			DiscoveryURL: dc.URL(0) + "/v2/keys"},
	)
	c.Launch(t)
	defer c.Terminate(t)
	clusterMustProgress(t, c.Members)
}

func TestDoubleClusterSizeOf1(t *testing.T) { testDoubleClusterSize(t, 1) }
func TestDoubleClusterSizeOf3(t *testing.T) { testDoubleClusterSize(t, 3) }

func testDoubleClusterSize(t *testing.T, size int) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, size)
	c.Launch(t)
	defer c.Terminate(t)

	for i := 0; i < size; i++ {
		c.AddMember(t)
	}
	clusterMustProgress(t, c.Members)
}

func TestDoubleTLSClusterSizeOf3(t *testing.T) {
	defer testutil.AfterTest(t)
	c := NewClusterByConfig(t, &ClusterConfig{Size: 3, UsePeerTLS: true})
	c.Launch(t)
	defer c.Terminate(t)

	for i := 0; i < 3; i++ {
		c.AddMember(t)
	}
	clusterMustProgress(t, c.Members)
}

func TestDecreaseClusterSizeOf3(t *testing.T) { testDecreaseClusterSize(t, 3) }
func TestDecreaseClusterSizeOf5(t *testing.T) { testDecreaseClusterSize(t, 5) }

func testDecreaseClusterSize(t *testing.T, size int) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, size)
	c.Launch(t)
	defer c.Terminate(t)

	// TODO: remove the last but one member
	for i := 0; i < size-1; i++ {
		id := c.Members[len(c.Members)-1].s.ID()
		c.RemoveMember(t, uint64(id))
		c.waitLeader(t, c.Members)
	}
	clusterMustProgress(t, c.Members)
}

func TestForceNewCluster(t *testing.T) {
	c := NewCluster(t, 3)
	c.Launch(t)
	cc := mustNewHTTPClient(t, []string{c.Members[0].URL()})
	kapi := client.NewKeysAPI(cc)
	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	resp, err := kapi.Create(ctx, "/foo", "bar")
	if err != nil {
		t.Fatalf("unexpected create error: %v", err)
	}
	cancel()
	// ensure create has been applied in this machine
	ctx, cancel = context.WithTimeout(context.Background(), requestTimeout)
	if _, err = kapi.Watcher("/foo", &client.WatcherOptions{AfterIndex: resp.Node.ModifiedIndex - 1}).Next(ctx); err != nil {
		t.Fatalf("unexpected watch error: %v", err)
	}
	cancel()

	c.Members[0].Stop(t)
	c.Members[1].Terminate(t)
	c.Members[2].Terminate(t)
	c.Members[0].ForceNewCluster = true
	err = c.Members[0].Restart(t)
	if err != nil {
		t.Fatalf("unexpected ForceRestart error: %v", err)
	}
	defer c.Members[0].Terminate(t)
	c.waitLeader(t, c.Members[:1])

	// use new http client to init new connection
	cc = mustNewHTTPClient(t, []string{c.Members[0].URL()})
	kapi = client.NewKeysAPI(cc)
	// ensure force restart keep the old data, and new cluster can make progress
	ctx, cancel = context.WithTimeout(context.Background(), requestTimeout)
	if _, err := kapi.Watcher("/foo", &client.WatcherOptions{AfterIndex: resp.Node.ModifiedIndex - 1}).Next(ctx); err != nil {
		t.Fatalf("unexpected watch error: %v", err)
	}
	cancel()
	clusterMustProgress(t, c.Members[:1])
}

func TestAddMemberAfterClusterFullRotation(t *testing.T) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, 3)
	c.Launch(t)
	defer c.Terminate(t)

	// remove all the previous three members and add in three new members.
	for i := 0; i < 3; i++ {
		c.RemoveMember(t, uint64(c.Members[0].s.ID()))
		c.waitLeader(t, c.Members)

		c.AddMember(t)
		c.waitLeader(t, c.Members)
	}

	c.AddMember(t)
	c.waitLeader(t, c.Members)

	clusterMustProgress(t, c.Members)
}

// Ensure we can remove a member then add a new one back immediately.
func TestIssue2681(t *testing.T) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, 5)
	c.Launch(t)
	defer c.Terminate(t)

	c.RemoveMember(t, uint64(c.Members[4].s.ID()))
	c.waitLeader(t, c.Members)

	c.AddMember(t)
	c.waitLeader(t, c.Members)
	clusterMustProgress(t, c.Members)
}

// Ensure we can remove a member after a snapshot then add a new one back.
func TestIssue2746(t *testing.T) {
	defer testutil.AfterTest(t)
	c := NewCluster(t, 5)

	for _, m := range c.Members {
		m.SnapCount = 10
	}

	c.Launch(t)
	defer c.Terminate(t)

	// force a snapshot
	for i := 0; i < 20; i++ {
		clusterMustProgress(t, c.Members)
	}

	c.RemoveMember(t, uint64(c.Members[4].s.ID()))
	c.waitLeader(t, c.Members)

	c.AddMember(t)
	c.waitLeader(t, c.Members)
	clusterMustProgress(t, c.Members)
}

// Ensure etcd will not panic when removing a just started member.
func TestIssue2904(t *testing.T) {
	defer testutil.AfterTest(t)
	// start 1-member cluster to ensure member 0 is the leader of the cluster.
	c := NewCluster(t, 1)
	c.Launch(t)
	defer c.Terminate(t)

	c.AddMember(t)
	c.Members[1].Stop(t)

	// send remove member-1 request to the cluster.
	cc := mustNewHTTPClient(t, c.URLs())
	ma := client.NewMembersAPI(cc)
	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	// the proposal is not committed because member 1 is stopped, but the
	// proposal is appended to leader's raft log.
	ma.Remove(ctx, c.Members[1].s.ID().String())
	cancel()

	// restart member, and expect it to send updateAttr request.
	// the log in the leader is like this:
	// [..., remove 1, ..., update attr 1, ...]
	c.Members[1].Restart(t)
	// when the member comes back, it ack the proposal to remove itself,
	// and apply it.
	<-c.Members[1].s.StopNotify()

	// terminate removed member
	c.Members[1].Terminate(t)
	c.Members = c.Members[:1]
	// wait member to be removed.
	c.waitMembersMatch(t, c.HTTPMembers())
}

// clusterMustProgress ensures that cluster can make progress. It creates
// a random key first, and check the new key could be got from all client urls
// of the cluster.
func clusterMustProgress(t *testing.T, membs []*member) {
	cc := mustNewHTTPClient(t, []string{membs[0].URL()})
	kapi := client.NewKeysAPI(cc)
	ctx, cancel := context.WithTimeout(context.Background(), requestTimeout)
	key := fmt.Sprintf("foo%d", rand.Int())
	resp, err := kapi.Create(ctx, "/"+key, "bar")
	if err != nil {
		t.Fatalf("create on %s error: %v", membs[0].URL(), err)
	}
	cancel()

	for i, m := range membs {
		u := m.URL()
		mcc := mustNewHTTPClient(t, []string{u})
		mkapi := client.NewKeysAPI(mcc)
		mctx, mcancel := context.WithTimeout(context.Background(), requestTimeout)
		if _, err := mkapi.Watcher(key, &client.WatcherOptions{AfterIndex: resp.Node.ModifiedIndex - 1}).Next(mctx); err != nil {
			t.Fatalf("#%d: watch on %s error: %v", i, u, err)
		}
		mcancel()
	}
}
