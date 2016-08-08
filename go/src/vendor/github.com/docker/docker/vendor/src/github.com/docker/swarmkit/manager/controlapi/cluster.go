package controlapi

import (
	"strings"

	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/ca"
	"github.com/docker/swarmkit/manager/state/store"
	"github.com/docker/swarmkit/protobuf/ptypes"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

func validateClusterSpec(spec *api.ClusterSpec) error {
	if spec == nil {
		return grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}

	// Validate that expiry time being provided is valid, and over our minimum
	if spec.CAConfig.NodeCertExpiry != nil {
		expiry, err := ptypes.Duration(spec.CAConfig.NodeCertExpiry)
		if err != nil {
			return grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
		}
		if expiry < ca.MinNodeCertExpiration {
			return grpc.Errorf(codes.InvalidArgument, "minimum certificate expiry time is: %s", ca.MinNodeCertExpiration)
		}
	}

	// Validate that AcceptancePolicies only include Secrets that are bcrypted
	// TODO(diogo): Add a global list of acceptace algorithms. We only support bcrypt for now.
	if len(spec.AcceptancePolicy.Policies) > 0 {
		for _, policy := range spec.AcceptancePolicy.Policies {
			if policy.Secret != nil && strings.ToLower(policy.Secret.Alg) != "bcrypt" {
				return grpc.Errorf(codes.InvalidArgument, "hashing algorithm is not supported: %s", policy.Secret.Alg)
			}
		}
	}

	// Validate that heartbeatPeriod time being provided is valid
	if spec.Dispatcher.HeartbeatPeriod != nil {
		heartbeatPeriod, err := ptypes.Duration(spec.Dispatcher.HeartbeatPeriod)
		if err != nil {
			return grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
		}
		if heartbeatPeriod < 0 {
			return grpc.Errorf(codes.InvalidArgument, "heartbeat time period cannot be a negative duration")
		}
	}

	return nil
}

// GetCluster returns a Cluster given a ClusterID.
// - Returns `InvalidArgument` if ClusterID is not provided.
// - Returns `NotFound` if the Cluster is not found.
func (s *Server) GetCluster(ctx context.Context, request *api.GetClusterRequest) (*api.GetClusterResponse, error) {
	if request.ClusterID == "" {
		return nil, grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}

	var cluster *api.Cluster
	s.store.View(func(tx store.ReadTx) {
		cluster = store.GetCluster(tx, request.ClusterID)
	})
	if cluster == nil {
		return nil, grpc.Errorf(codes.NotFound, "cluster %s not found", request.ClusterID)
	}

	redactedClusters := redactClusters([]*api.Cluster{cluster})

	// WARN: we should never return cluster here. We need to redact the private fields first.
	return &api.GetClusterResponse{
		Cluster: redactedClusters[0],
	}, nil
}

// UpdateCluster updates a Cluster referenced by ClusterID with the given ClusterSpec.
// - Returns `NotFound` if the Cluster is not found.
// - Returns `InvalidArgument` if the ClusterSpec is malformed.
// - Returns `Unimplemented` if the ClusterSpec references unimplemented features.
// - Returns an error if the update fails.
func (s *Server) UpdateCluster(ctx context.Context, request *api.UpdateClusterRequest) (*api.UpdateClusterResponse, error) {
	if request.ClusterID == "" || request.ClusterVersion == nil {
		return nil, grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}
	if err := validateClusterSpec(request.Spec); err != nil {
		return nil, err
	}

	var cluster *api.Cluster
	err := s.store.Update(func(tx store.Tx) error {
		cluster = store.GetCluster(tx, request.ClusterID)
		if cluster == nil {
			return nil
		}
		cluster.Meta.Version = *request.ClusterVersion
		cluster.Spec = *request.Spec.Copy()

		if request.Rotation.RotateWorkerToken {
			cluster.RootCA.JoinTokens.Worker = ca.GenerateJoinToken(s.rootCA)
		}
		if request.Rotation.RotateManagerToken {
			cluster.RootCA.JoinTokens.Manager = ca.GenerateJoinToken(s.rootCA)
		}
		return store.UpdateCluster(tx, cluster)
	})
	if err != nil {
		return nil, err
	}
	if cluster == nil {
		return nil, grpc.Errorf(codes.NotFound, "cluster %s not found", request.ClusterID)
	}

	redactedClusters := redactClusters([]*api.Cluster{cluster})

	// WARN: we should never return cluster here. We need to redact the private fields first.
	return &api.UpdateClusterResponse{
		Cluster: redactedClusters[0],
	}, nil
}

func filterClusters(candidates []*api.Cluster, filters ...func(*api.Cluster) bool) []*api.Cluster {
	result := []*api.Cluster{}

	for _, c := range candidates {
		match := true
		for _, f := range filters {
			if !f(c) {
				match = false
				break
			}
		}
		if match {
			result = append(result, c)
		}
	}

	return result
}

// ListClusters returns a list of all clusters.
func (s *Server) ListClusters(ctx context.Context, request *api.ListClustersRequest) (*api.ListClustersResponse, error) {
	var (
		clusters []*api.Cluster
		err      error
	)
	s.store.View(func(tx store.ReadTx) {
		switch {
		case request.Filters != nil && len(request.Filters.Names) > 0:
			clusters, err = store.FindClusters(tx, buildFilters(store.ByName, request.Filters.Names))
		case request.Filters != nil && len(request.Filters.NamePrefixes) > 0:
			clusters, err = store.FindClusters(tx, buildFilters(store.ByNamePrefix, request.Filters.NamePrefixes))
		case request.Filters != nil && len(request.Filters.IDPrefixes) > 0:
			clusters, err = store.FindClusters(tx, buildFilters(store.ByIDPrefix, request.Filters.IDPrefixes))
		default:
			clusters, err = store.FindClusters(tx, store.All)
		}
	})
	if err != nil {
		return nil, err
	}

	if request.Filters != nil {
		clusters = filterClusters(clusters,
			func(e *api.Cluster) bool {
				return filterContains(e.Spec.Annotations.Name, request.Filters.Names)
			},
			func(e *api.Cluster) bool {
				return filterContainsPrefix(e.Spec.Annotations.Name, request.Filters.NamePrefixes)
			},
			func(e *api.Cluster) bool {
				return filterContainsPrefix(e.ID, request.Filters.IDPrefixes)
			},
			func(e *api.Cluster) bool {
				return filterMatchLabels(e.Spec.Annotations.Labels, request.Filters.Labels)
			},
		)
	}

	// WARN: we should never return cluster here. We need to redact the private fields first.
	return &api.ListClustersResponse{
		Clusters: redactClusters(clusters),
	}, nil
}

// redactClusters is a method that enforces a whitelist of fields that are ok to be
// returned in the Cluster object. It should filter out all senstive information.
func redactClusters(clusters []*api.Cluster) []*api.Cluster {
	var redactedClusters []*api.Cluster
	// Only add public fields to the new clusters
	for _, cluster := range clusters {
		// Copy all the mandatory fields
		// Do not copy secret key
		newCluster := &api.Cluster{
			ID:   cluster.ID,
			Meta: cluster.Meta,
			Spec: cluster.Spec,
			RootCA: api.RootCA{
				CACert:     cluster.RootCA.CACert,
				CACertHash: cluster.RootCA.CACertHash,
				JoinTokens: cluster.RootCA.JoinTokens,
			},
		}

		redactedClusters = append(redactedClusters, newCluster)
	}

	return redactedClusters
}
