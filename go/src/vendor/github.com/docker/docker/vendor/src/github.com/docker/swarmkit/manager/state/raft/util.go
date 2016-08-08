package raft

import (
	"time"

	"golang.org/x/net/context"

	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/manager/state"
	"github.com/docker/swarmkit/manager/state/store"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

// dial returns a grpc client connection
func dial(addr string, protocol string, creds credentials.TransportAuthenticator, timeout time.Duration) (*grpc.ClientConn, error) {
	grpcOptions := []grpc.DialOption{
		grpc.WithBackoffMaxDelay(2 * time.Second),
		grpc.WithTransportCredentials(creds),
	}

	if timeout != 0 {
		grpcOptions = append(grpcOptions, grpc.WithTimeout(timeout))
	}

	return grpc.Dial(addr, grpcOptions...)
}

// Register registers the node raft server
func Register(server *grpc.Server, node *Node) {
	api.RegisterRaftServer(server, node)
	api.RegisterRaftMembershipServer(server, node)
}

// WaitForLeader waits until node observe some leader in cluster. It returns
// error if ctx was cancelled before leader appeared.
func WaitForLeader(ctx context.Context, n *Node) error {
	l := n.Leader()
	if l != 0 {
		return nil
	}
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()
	for l == 0 {
		select {
		case <-ticker.C:
		case <-ctx.Done():
			return ctx.Err()
		}
		l = n.Leader()
	}
	return nil
}

// WaitForCluster waits until node observes that the cluster wide config is
// committed to raft. This ensures that we can see and serve informations
// related to the cluster.
func WaitForCluster(ctx context.Context, n *Node) (cluster *api.Cluster, err error) {
	watch, cancel := state.Watch(n.MemoryStore().WatchQueue(), state.EventCreateCluster{})
	defer cancel()

	var clusters []*api.Cluster
	n.MemoryStore().View(func(readTx store.ReadTx) {
		clusters, err = store.FindClusters(readTx, store.ByName(store.DefaultClusterName))
	})

	if err != nil {
		return nil, err
	}

	if len(clusters) == 1 {
		cluster = clusters[0]
	} else {
		select {
		case e := <-watch:
			cluster = e.(state.EventCreateCluster).Cluster
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	return cluster, nil
}
