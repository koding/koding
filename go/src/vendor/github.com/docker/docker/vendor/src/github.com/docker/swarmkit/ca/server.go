package ca

import (
	"crypto/subtle"
	"fmt"
	"sync"

	"github.com/Sirupsen/logrus"
	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/identity"
	"github.com/docker/swarmkit/log"
	"github.com/docker/swarmkit/manager/state"
	"github.com/docker/swarmkit/manager/state/store"
	"github.com/docker/swarmkit/protobuf/ptypes"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

// Server is the CA and NodeCA API gRPC server.
// TODO(diogo): At some point we may want to have separate implementations of
// CA, NodeCA, and other hypothetical future CA services. At the moment,
// breaking it apart doesn't seem worth it.
type Server struct {
	mu             sync.Mutex
	wg             sync.WaitGroup
	ctx            context.Context
	cancel         func()
	store          *store.MemoryStore
	securityConfig *SecurityConfig
	joinTokens     *api.JoinTokens

	// Started is a channel which gets closed once the server is running
	// and able to service RPCs.
	started chan struct{}
}

// DefaultCAConfig returns the default CA Config, with a default expiration.
func DefaultCAConfig() api.CAConfig {
	return api.CAConfig{
		NodeCertExpiry: ptypes.DurationProto(DefaultNodeCertExpiration),
	}
}

// NewServer creates a CA API server.
func NewServer(store *store.MemoryStore, securityConfig *SecurityConfig) *Server {
	return &Server{
		store:          store,
		securityConfig: securityConfig,
		started:        make(chan struct{}),
	}
}

// NodeCertificateStatus returns the current issuance status of an issuance request identified by the nodeID
func (s *Server) NodeCertificateStatus(ctx context.Context, request *api.NodeCertificateStatusRequest) (*api.NodeCertificateStatusResponse, error) {
	if request.NodeID == "" {
		return nil, grpc.Errorf(codes.InvalidArgument, codes.InvalidArgument.String())
	}

	if err := s.addTask(); err != nil {
		return nil, err
	}
	defer s.doneTask()

	var node *api.Node

	event := state.EventUpdateNode{
		Node:   &api.Node{ID: request.NodeID},
		Checks: []state.NodeCheckFunc{state.NodeCheckID},
	}

	// Retrieve the current value of the certificate with this token, and create a watcher
	updates, cancel, err := store.ViewAndWatch(
		s.store,
		func(tx store.ReadTx) error {
			node = store.GetNode(tx, request.NodeID)
			return nil
		},
		event,
	)
	if err != nil {
		return nil, err
	}
	defer cancel()

	// This node ID doesn't exist
	if node == nil {
		return nil, grpc.Errorf(codes.NotFound, codes.NotFound.String())
	}

	log.G(ctx).WithFields(logrus.Fields{
		"node.id": node.ID,
		"status":  node.Certificate.Status,
		"method":  "NodeCertificateStatus",
	})

	// If this certificate has a final state, return it immediately (both pending and renew are transition states)
	if isFinalState(node.Certificate.Status) {
		return &api.NodeCertificateStatusResponse{
			Status:      &node.Certificate.Status,
			Certificate: &node.Certificate,
		}, nil
	}

	log.G(ctx).WithFields(logrus.Fields{
		"node.id": node.ID,
		"status":  node.Certificate.Status,
		"method":  "NodeCertificateStatus",
	}).Debugf("started watching for certificate updates")

	// Certificate is Pending or in an Unknown state, let's wait for changes.
	for {
		select {
		case event := <-updates:
			switch v := event.(type) {
			case state.EventUpdateNode:
				// We got an update on the certificate record. If the status is a final state,
				// return the certificate.
				if isFinalState(v.Node.Certificate.Status) {
					cert := v.Node.Certificate.Copy()
					return &api.NodeCertificateStatusResponse{
						Status:      &cert.Status,
						Certificate: cert,
					}, nil
				}
			}
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-s.ctx.Done():
			return nil, s.ctx.Err()
		}
	}
}

// IssueNodeCertificate is responsible for gatekeeping both certificate requests from new nodes in the swarm,
// and authorizing certificate renewals.
// If a node presented a valid certificate, the corresponding certificate is set in a RENEW state.
// If a node failed to present a valid certificate, we check for a valid join token and set the
// role accordingly. A new random node ID is generated, and the corresponding node entry is created.
// IssueNodeCertificate is the only place where new node entries to raft should be created.
func (s *Server) IssueNodeCertificate(ctx context.Context, request *api.IssueNodeCertificateRequest) (*api.IssueNodeCertificateResponse, error) {
	// First, let's see if the remote node is presenting a non-empty CSR
	if len(request.CSR) == 0 {
		return nil, grpc.Errorf(codes.InvalidArgument, codes.InvalidArgument.String())
	}

	if err := s.addTask(); err != nil {
		return nil, err
	}
	defer s.doneTask()

	// If the remote node is an Agent (either forwarded by a manager, or calling directly),
	// issue a renew agent certificate entry with the correct ID
	nodeID, err := AuthorizeForwardedRoleAndOrg(ctx, []string{AgentRole}, []string{ManagerRole}, s.securityConfig.ClientTLSCreds.Organization())
	if err == nil {
		return s.issueRenewCertificate(ctx, nodeID, request.CSR)
	}

	// If the remote node is a Manager (either forwarded by another manager, or calling directly),
	// issue a renew certificate entry with the correct ID
	nodeID, err = AuthorizeForwardedRoleAndOrg(ctx, []string{ManagerRole}, []string{ManagerRole}, s.securityConfig.ClientTLSCreds.Organization())
	if err == nil {
		return s.issueRenewCertificate(ctx, nodeID, request.CSR)
	}

	// The remote node didn't successfully present a valid MTLS certificate, let's issue a
	// certificate with a new random ID
	role := api.NodeRole(-1)

	s.mu.Lock()
	if subtle.ConstantTimeCompare([]byte(s.joinTokens.Manager), []byte(request.Token)) == 1 {
		role = api.NodeRoleManager
	} else if subtle.ConstantTimeCompare([]byte(s.joinTokens.Worker), []byte(request.Token)) == 1 {
		role = api.NodeRoleWorker
	}
	s.mu.Unlock()

	if role < 0 {
		return nil, grpc.Errorf(codes.InvalidArgument, "A valid join token is necessary to join this cluster")
	}

	// Max number of collisions of ID or CN to tolerate before giving up
	maxRetries := 3
	// Generate a random ID for this new node
	for i := 0; ; i++ {
		nodeID = identity.NewID()

		// Create a new node
		err := s.store.Update(func(tx store.Tx) error {
			node := &api.Node{
				ID: nodeID,
				Certificate: api.Certificate{
					CSR:  request.CSR,
					CN:   nodeID,
					Role: role,
					Status: api.IssuanceStatus{
						State: api.IssuanceStatePending,
					},
				},
				Spec: api.NodeSpec{
					Role:       role,
					Membership: api.NodeMembershipAccepted,
				},
			}

			return store.CreateNode(tx, node)
		})
		if err == nil {
			log.G(ctx).WithFields(logrus.Fields{
				"node.id":   nodeID,
				"node.role": role,
				"method":    "IssueNodeCertificate",
			}).Debugf("new certificate entry added")
			break
		}
		if err != store.ErrExist {
			return nil, err
		}
		if i == maxRetries {
			return nil, err
		}
		log.G(ctx).WithFields(logrus.Fields{
			"node.id":   nodeID,
			"node.role": role,
			"method":    "IssueNodeCertificate",
		}).Errorf("randomly generated node ID collided with an existing one - retrying")
	}

	return &api.IssueNodeCertificateResponse{
		NodeID:         nodeID,
		NodeMembership: api.NodeMembershipAccepted,
	}, nil
}

// issueRenewCertificate receives a nodeID and a CSR and modifies the node's certificate entry with the new CSR
// and changes the state to RENEW, so it can be picked up and signed by the signing reconciliation loop
func (s *Server) issueRenewCertificate(ctx context.Context, nodeID string, csr []byte) (*api.IssueNodeCertificateResponse, error) {
	var (
		cert api.Certificate
		node *api.Node
	)
	err := s.store.Update(func(tx store.Tx) error {

		// Attempt to retrieve the node with nodeID
		node = store.GetNode(tx, nodeID)
		if node == nil {
			log.G(ctx).WithFields(logrus.Fields{
				"node.id": nodeID,
				"method":  "issueRenewCertificate",
			}).Warnf("node does not exist")
			// If this node doesn't exist, we shouldn't be renewing a certificate for it
			return grpc.Errorf(codes.NotFound, "node %s not found when attempting to renew certificate", nodeID)
		}

		// Create a new Certificate entry for this node with the new CSR and a RENEW state
		cert = api.Certificate{
			CSR:  csr,
			CN:   node.ID,
			Role: node.Spec.Role,
			Status: api.IssuanceStatus{
				State: api.IssuanceStateRenew,
			},
		}

		node.Certificate = cert
		return store.UpdateNode(tx, node)
	})
	if err != nil {
		return nil, err
	}

	log.G(ctx).WithFields(logrus.Fields{
		"cert.cn":   cert.CN,
		"cert.role": cert.Role,
		"method":    "issueRenewCertificate",
	}).Debugf("node certificate updated")

	return &api.IssueNodeCertificateResponse{
		NodeID:         nodeID,
		NodeMembership: node.Spec.Membership,
	}, nil
}

// GetRootCACertificate returns the certificate of the Root CA. It is used as a convinience for distributing
// the root of trust for the swarm. Clients should be using the CA hash to verify if they weren't target to
// a MiTM. If they fail to do so, node bootstrap works with TOFU semantics.
func (s *Server) GetRootCACertificate(ctx context.Context, request *api.GetRootCACertificateRequest) (*api.GetRootCACertificateResponse, error) {
	log.G(ctx).WithFields(logrus.Fields{
		"method": "GetRootCACertificate",
	})

	return &api.GetRootCACertificateResponse{
		Certificate: s.securityConfig.RootCA().Cert,
	}, nil
}

// Run runs the CA signer main loop.
// The CA signer can be stopped with cancelling ctx or calling Stop().
func (s *Server) Run(ctx context.Context) error {
	s.mu.Lock()
	if s.isRunning() {
		s.mu.Unlock()
		return fmt.Errorf("CA signer is already running")
	}
	s.wg.Add(1)
	s.mu.Unlock()

	defer s.wg.Done()
	logger := log.G(ctx).WithField("module", "ca")
	ctx = log.WithLogger(ctx, logger)

	// Run() should never be called twice, but just in case, we're
	// attempting to close the started channel in a safe way
	select {
	case <-s.started:
		return fmt.Errorf("CA server cannot be started more than once")
	default:
		close(s.started)
	}

	// Retrieve the channels to keep track of changes in the cluster
	// Retrieve all the currently registered nodes
	var nodes []*api.Node
	updates, cancel, err := store.ViewAndWatch(
		s.store,
		func(readTx store.ReadTx) error {
			clusters, err := store.FindClusters(readTx, store.ByName(store.DefaultClusterName))
			if err != nil {
				return err
			}
			if len(clusters) != 1 {
				return fmt.Errorf("could not find cluster object")
			}
			s.updateCluster(ctx, clusters[0])

			nodes, err = store.FindNodes(readTx, store.All)
			return err
		},
		state.EventCreateNode{},
		state.EventUpdateNode{},
		state.EventUpdateCluster{},
	)

	// Do this after updateCluster has been called, so isRunning never
	// returns true without joinTokens being set correctly.
	s.mu.Lock()
	s.ctx, s.cancel = context.WithCancel(ctx)
	s.mu.Unlock()

	if err != nil {
		log.G(ctx).WithFields(logrus.Fields{
			"method": "(*Server).Run",
		}).WithError(err).Errorf("snapshot store view failed")
		return err
	}
	defer cancel()

	// We might have missed some updates if there was a leader election,
	// so let's pick up the slack.
	if err := s.reconcileNodeCertificates(ctx, nodes); err != nil {
		// We don't return here because that means the Run loop would
		// never run. Log an error instead.
		log.G(ctx).WithFields(logrus.Fields{
			"method": "(*Server).Run",
		}).WithError(err).Errorf("error attempting to reconcile certificates")
	}

	// Watch for new nodes being created, new nodes being updated, and changes
	// to the cluster
	for {
		select {
		case event := <-updates:
			switch v := event.(type) {
			case state.EventCreateNode:
				s.evaluateAndSignNodeCert(ctx, v.Node)
			case state.EventUpdateNode:
				// If this certificate is already at a final state
				// no need to evaluate and sign it.
				if !isFinalState(v.Node.Certificate.Status) {
					s.evaluateAndSignNodeCert(ctx, v.Node)
				}
			case state.EventUpdateCluster:
				s.updateCluster(ctx, v.Cluster)
			}

		case <-ctx.Done():
			return ctx.Err()
		case <-s.ctx.Done():
			return nil
		}
	}
}

// Stop stops the CA and closes all grpc streams.
func (s *Server) Stop() error {
	s.mu.Lock()
	if !s.isRunning() {
		s.mu.Unlock()
		return fmt.Errorf("CA signer is already stopped")
	}
	s.cancel()
	s.mu.Unlock()
	// wait for all handlers to finish their CA deals,
	s.wg.Wait()
	s.started = make(chan struct{})
	return nil
}

// Ready waits on the ready channel and returns when the server is ready to serve.
func (s *Server) Ready() <-chan struct{} {
	return s.started
}

func (s *Server) addTask() error {
	s.mu.Lock()
	if !s.isRunning() {
		s.mu.Unlock()
		return grpc.Errorf(codes.Aborted, "CA signer is stopped")
	}
	s.wg.Add(1)
	s.mu.Unlock()
	return nil
}

func (s *Server) doneTask() {
	s.wg.Done()
}

func (s *Server) isRunning() bool {
	if s.ctx == nil {
		return false
	}
	select {
	case <-s.ctx.Done():
		return false
	default:
	}
	return true
}

// updateCluster is called when there are cluster changes, and it ensures that the local RootCA is
// always aware of changes in clusterExpiry and the Root CA key material
func (s *Server) updateCluster(ctx context.Context, cluster *api.Cluster) {
	s.mu.Lock()
	s.joinTokens = cluster.RootCA.JoinTokens.Copy()
	s.mu.Unlock()
	var err error

	// If the cluster has a RootCA, let's try to update our SecurityConfig to reflect the latest values
	rCA := cluster.RootCA
	if len(rCA.CACert) != 0 && len(rCA.CAKey) != 0 {
		expiry := DefaultNodeCertExpiration
		if cluster.Spec.CAConfig.NodeCertExpiry != nil {
			// NodeCertExpiry exists, let's try to parse the duration out of it
			clusterExpiry, err := ptypes.Duration(cluster.Spec.CAConfig.NodeCertExpiry)
			if err != nil {
				log.G(ctx).WithFields(logrus.Fields{
					"cluster.id": cluster.ID,
					"method":     "(*Server).updateCluster",
				}).WithError(err).Warn("failed to parse certificate expiration, using default")
			} else {
				// We were able to successfully parse the expiration out of the cluster.
				expiry = clusterExpiry
			}
		} else {
			// NodeCertExpiry seems to be nil
			log.G(ctx).WithFields(logrus.Fields{
				"cluster.id": cluster.ID,
				"method":     "(*Server).updateCluster",
			}).WithError(err).Warn("failed to parse certificate expiration, using default")

		}
		// Attempt to update our local RootCA with the new parameters
		err = s.securityConfig.UpdateRootCA(rCA.CACert, rCA.CAKey, expiry)
		if err != nil {
			log.G(ctx).WithFields(logrus.Fields{
				"cluster.id": cluster.ID,
				"method":     "(*Server).updateCluster",
			}).WithError(err).Error("updating Root CA failed")
		} else {
			log.G(ctx).WithFields(logrus.Fields{
				"cluster.id": cluster.ID,
				"method":     "(*Server).updateCluster",
			}).Debugf("Root CA updated successfully")
		}
	}

	// Update our security config with the list of External CA URLs
	// from the new cluster state.

	// TODO(aaronl): In the future, this will be abstracted with an
	// ExternalCA interface that has different implementations for
	// different CA types. At the moment, only CFSSL is supported.
	var cfsslURLs []string
	for _, ca := range cluster.Spec.CAConfig.ExternalCAs {
		if ca.Protocol == api.ExternalCA_CAProtocolCFSSL {
			cfsslURLs = append(cfsslURLs, ca.URL)
		}
	}

	s.securityConfig.externalCA.UpdateURLs(cfsslURLs...)
}

// evaluateAndSignNodeCert implements the logic of which certificates to sign
func (s *Server) evaluateAndSignNodeCert(ctx context.Context, node *api.Node) {
	// If the desired membership and actual state are in sync, there's
	// nothing to do.
	if node.Spec.Membership == api.NodeMembershipAccepted && node.Certificate.Status.State == api.IssuanceStateIssued {
		return
	}

	// If the certificate state is renew, then it is a server-sided accepted cert (cert renewals)
	if node.Certificate.Status.State == api.IssuanceStateRenew {
		s.signNodeCert(ctx, node)
		return
	}

	// Sign this certificate if a user explicitly changed it to Accepted, and
	// the certificate is in pending state
	if node.Spec.Membership == api.NodeMembershipAccepted && node.Certificate.Status.State == api.IssuanceStatePending {
		s.signNodeCert(ctx, node)
	}
}

// signNodeCert does the bulk of the work for signing a certificate
func (s *Server) signNodeCert(ctx context.Context, node *api.Node) {
	rootCA := s.securityConfig.RootCA()
	externalCA := s.securityConfig.externalCA

	node = node.Copy()
	nodeID := node.ID
	// Convert the role from proto format
	role, err := ParseRole(node.Certificate.Role)
	if err != nil {
		log.G(ctx).WithFields(logrus.Fields{
			"node.id": node.ID,
			"method":  "(*Server).signNodeCert",
		}).WithError(err).Errorf("failed to parse role")
		return
	}

	// Attempt to sign the CSR
	var (
		rawCSR = node.Certificate.CSR
		cn     = node.Certificate.CN
		ou     = role
		org    = s.securityConfig.ClientTLSCreds.Organization()
	)

	// Try using the external CA first.
	cert, err := externalCA.Sign(PrepareCSR(rawCSR, cn, ou, org))
	if err == ErrNoExternalCAURLs {
		// No external CA servers configured. Try using the local CA.
		cert, err = rootCA.ParseValidateAndSignCSR(rawCSR, cn, ou, org)
	}

	if err != nil {
		log.G(ctx).WithFields(logrus.Fields{
			"node.id": node.ID,
			"method":  "(*Server).signNodeCert",
		}).WithError(err).Errorf("failed to sign CSR")
		// If this error is due the lack of signer, maybe some other
		// manager in the future will pick it up. Return without
		// changing the state of the certificate.
		if err == ErrNoValidSigner {
			return
		}
		// If the current state is already Failed, no need to change it
		if node.Certificate.Status.State == api.IssuanceStateFailed {
			return
		}
		// We failed to sign this CSR, change the state to FAILED
		err = s.store.Update(func(tx store.Tx) error {
			node := store.GetNode(tx, nodeID)
			if node == nil {
				return fmt.Errorf("node %s not found", nodeID)
			}

			node.Certificate.Status = api.IssuanceStatus{
				State: api.IssuanceStateFailed,
				Err:   err.Error(),
			}

			return store.UpdateNode(tx, node)
		})
		if err != nil {
			log.G(ctx).WithFields(logrus.Fields{
				"node.id": nodeID,
				"method":  "(*Server).signNodeCert",
			}).WithError(err).Errorf("transaction failed when setting state to FAILED")
		}
		return
	}

	// We were able to successfully sign the new CSR. Let's try to update the nodeStore
	for {
		err = s.store.Update(func(tx store.Tx) error {
			node.Certificate.Certificate = cert
			node.Certificate.Status = api.IssuanceStatus{
				State: api.IssuanceStateIssued,
			}

			err := store.UpdateNode(tx, node)
			if err != nil {
				node = store.GetNode(tx, nodeID)
				if node == nil {
					err = fmt.Errorf("node %s does not exist", nodeID)
				}
			}
			return err
		})
		if err == nil {
			log.G(ctx).WithFields(logrus.Fields{
				"node.id":   node.ID,
				"node.role": node.Certificate.Role,
				"method":    "(*Server).signNodeCert",
			}).Debugf("certificate issued")
			break
		}
		if err == store.ErrSequenceConflict {
			continue
		}

		log.G(ctx).WithFields(logrus.Fields{
			"node.id": nodeID,
			"method":  "(*Server).signNodeCert",
		}).WithError(err).Errorf("transaction failed")
		return
	}
}

// reconcileNodeCertificates is a helper method that calles evaluateAndSignNodeCert on all the
// nodes.
func (s *Server) reconcileNodeCertificates(ctx context.Context, nodes []*api.Node) error {
	for _, node := range nodes {
		s.evaluateAndSignNodeCert(ctx, node)
	}

	return nil
}

// A successfully issued certificate and a failed certificate are our current final states
func isFinalState(status api.IssuanceStatus) bool {
	if status.State == api.IssuanceStateIssued || status.State == api.IssuanceStateFailed {
		return true
	}

	return false
}
