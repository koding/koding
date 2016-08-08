package ca

import (
	"bytes"
	"crypto"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	log "github.com/Sirupsen/logrus"
	cfcsr "github.com/cloudflare/cfssl/csr"
	"github.com/cloudflare/cfssl/helpers"
	"github.com/cloudflare/cfssl/initca"
	cflog "github.com/cloudflare/cfssl/log"
	cfsigner "github.com/cloudflare/cfssl/signer"
	"github.com/cloudflare/cfssl/signer/local"
	"github.com/docker/distribution/digest"
	"github.com/docker/go-events"
	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/identity"
	"github.com/docker/swarmkit/ioutils"
	"github.com/docker/swarmkit/picker"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

const (
	// Security Strength Equivalence
	//-----------------------------------
	//| Key-type |  ECC  |  DH/DSA/RSA  |
	//|   Node   |  256  |     3072     |
	//|   Root   |  384  |     7680     |
	//-----------------------------------

	// RootKeySize is the default size of the root CA key
	RootKeySize = 384
	// RootKeyAlgo defines the default algorithm for the root CA Key
	RootKeyAlgo = "ecdsa"
	// PassphraseENVVar defines the environment variable to look for the
	// root CA private key material encryption key
	PassphraseENVVar = "SWARM_ROOT_CA_PASSPHRASE"
	// PassphraseENVVarPrev defines the alternate environment variable to look for the
	// root CA private key material encryption key. It can be used for seamless
	// KEK rotations.
	PassphraseENVVarPrev = "SWARM_ROOT_CA_PASSPHRASE_PREV"
	// RootCAExpiration represents the expiration for the root CA in seconds (20 years)
	RootCAExpiration = "630720000s"
	// DefaultNodeCertExpiration represents the default expiration for node certificates (3 months)
	DefaultNodeCertExpiration = 2160 * time.Hour
	// CertLowerRotationRange represents the minimum fraction of time that we will wait when randomly
	// choosing our next certificate rotation
	CertLowerRotationRange = 0.5
	// CertUpperRotationRange represents the maximum fraction of time that we will wait when randomly
	// choosing our next certificate rotation
	CertUpperRotationRange = 0.8
	// MinNodeCertExpiration represents the minimum expiration for node certificates (25 + 5 minutes)
	// X - 5 > CertUpperRotationRange * X <=> X < 5/(1 - CertUpperRotationRange)
	// Since we're issuing certificates 5 minutes in the past to get around clock drifts, and
	// we're selecting a random rotation distribution range from CertLowerRotationRange to
	// CertUpperRotationRange, we need to ensure that we don't accept an expiration time that will
	// make a node able to randomly choose the next rotation after the expiration of the certificate.
	MinNodeCertExpiration = 30 * time.Minute
)

// ErrNoLocalRootCA is an error type used to indicate that the local root CA
// certificate file does not exist.
var ErrNoLocalRootCA = errors.New("local root CA certificate does not exist")

// ErrNoValidSigner is an error type used to indicate that our RootCA doesn't have the ability to
// sign certificates.
var ErrNoValidSigner = errors.New("no valid signer found")

func init() {
	cflog.Level = 5
}

// CertPaths is a helper struct that keeps track of the paths of a
// Cert and corresponding Key
type CertPaths struct {
	Cert, Key string
}

// RootCA is the representation of everything we need to sign certificates
type RootCA struct {
	// Key will only be used by the original manager to put the private
	// key-material in raft, no signing operations depend on it.
	Key []byte
	// Cert includes the PEM encoded Certificate for the Root CA
	Cert []byte
	Pool *x509.CertPool
	// Digest of the serialized bytes of the certificate
	Digest digest.Digest
	// This signer will be nil if the node doesn't have the appropriate key material
	Signer cfsigner.Signer
}

// CanSign ensures that the signer has all three necessary elements needed to operate
func (rca *RootCA) CanSign() bool {
	if rca.Cert == nil || rca.Pool == nil || rca.Signer == nil {
		return false
	}

	return true
}

// IssueAndSaveNewCertificates generates a new key-pair, signs it with the local root-ca, and returns a
// tls certificate
func (rca *RootCA) IssueAndSaveNewCertificates(paths CertPaths, cn, ou, org string) (*tls.Certificate, error) {
	csr, key, err := GenerateAndWriteNewKey(paths)
	if err != nil {
		log.Debugf("error when generating new node certs: %v", err)
		return nil, err
	}

	if !rca.CanSign() {
		return nil, ErrNoValidSigner
	}

	// Obtain a signed Certificate
	certChain, err := rca.ParseValidateAndSignCSR(csr, cn, ou, org)
	if err != nil {
		log.Debugf("failed to sign node certificate: %v", err)
		return nil, err
	}

	// Ensure directory exists
	err = os.MkdirAll(filepath.Dir(paths.Cert), 0755)
	if err != nil {
		return nil, err
	}

	// Write the chain to disk
	if err := ioutils.AtomicWriteFile(paths.Cert, certChain, 0644); err != nil {
		return nil, err
	}

	// Create a valid TLSKeyPair out of the PEM encoded private key and certificate
	tlsKeyPair, err := tls.X509KeyPair(certChain, key)
	if err != nil {
		return nil, err
	}

	log.Debugf("locally issued new TLS certificate for node ID: %s and role: %s", cn, ou)
	return &tlsKeyPair, nil
}

// RequestAndSaveNewCertificates gets new certificates issued, either by signing them locally if a signer is
// available, or by requesting them from the remote server at remoteAddr.
func (rca *RootCA) RequestAndSaveNewCertificates(ctx context.Context, paths CertPaths, token string, picker *picker.Picker, transport credentials.TransportAuthenticator, nodeInfo chan<- api.IssueNodeCertificateResponse) (*tls.Certificate, error) {
	// Create a new key/pair and CSR for the new manager
	// Write the new CSR and the new key to a temporary location so we can survive crashes on rotation
	tempPaths := genTempPaths(paths)
	csr, key, err := GenerateAndWriteNewKey(tempPaths)
	if err != nil {
		log.Debugf("error when generating new node certs: %v", err)
		return nil, err
	}

	// Get the remote manager to issue a CA signed certificate for this node
	// Retry up to 5 times in case the manager we first try to contact isn't
	// responding properly (for example, it may have just been demoted).
	var signedCert []byte
	for i := 0; i != 5; i++ {
		signedCert, err = GetRemoteSignedCertificate(ctx, csr, token, rca.Pool, picker, transport, nodeInfo)
		if err == nil {
			break
		}
		log.Warningf("error fetching signed node certificate: %v", err)
	}
	if err != nil {
		return nil, err
	}

	// Доверяй, но проверяй.
	// Before we overwrite our local certificate, let's make sure the server gave us one that is valid
	// Create an X509Cert so we can .Verify()
	certBlock, _ := pem.Decode(signedCert)
	if certBlock == nil {
		return nil, fmt.Errorf("failed to parse certificate PEM")
	}
	X509Cert, err := x509.ParseCertificate(certBlock.Bytes)
	if err != nil {
		return nil, err
	}
	// Include our current root pool
	opts := x509.VerifyOptions{
		Roots: rca.Pool,
	}
	// Check to see if this certificate was signed by our CA, and isn't expired
	if _, err := X509Cert.Verify(opts); err != nil {
		return nil, err
	}

	// Create a valid TLSKeyPair out of the PEM encoded private key and certificate
	tlsKeyPair, err := tls.X509KeyPair(signedCert, key)
	if err != nil {
		return nil, err
	}

	if len(X509Cert.Subject.OrganizationalUnit) != 0 {
		log.Infof("Downloaded new TLS credentials with role: %s.", X509Cert.Subject.OrganizationalUnit[0])
	}

	// Ensure directory exists
	err = os.MkdirAll(filepath.Dir(paths.Cert), 0755)
	if err != nil {
		return nil, err
	}

	// Write the chain to disk
	if err := ioutils.AtomicWriteFile(paths.Cert, signedCert, 0644); err != nil {
		return nil, err
	}

	// Move the new key to the final location
	if err := os.Rename(tempPaths.Key, paths.Key); err != nil {
		return nil, err
	}

	return &tlsKeyPair, nil
}

// PrepareCSR creates a CFSSL Sign Request based on the given raw CSR and
// overrides the Subject and Hosts with the given extra args.
func PrepareCSR(csrBytes []byte, cn, ou, org string) cfsigner.SignRequest {
	// All managers get added the subject-alt-name of CA, so they can be
	// used for cert issuance.
	hosts := []string{ou}
	if ou == ManagerRole {
		hosts = append(hosts, CARole)
	}

	return cfsigner.SignRequest{
		Request: string(csrBytes),
		// OU is used for Authentication of the node type. The CN has the random
		// node ID.
		Subject: &cfsigner.Subject{CN: cn, Names: []cfcsr.Name{{OU: ou, O: org}}},
		// Adding ou as DNS alt name, so clients can connect to ManagerRole and CARole
		Hosts: hosts,
	}
}

// ParseValidateAndSignCSR returns a signed certificate from a particular rootCA and a CSR.
func (rca *RootCA) ParseValidateAndSignCSR(csrBytes []byte, cn, ou, org string) ([]byte, error) {
	if !rca.CanSign() {
		return nil, ErrNoValidSigner
	}

	signRequest := PrepareCSR(csrBytes, cn, ou, org)

	cert, err := rca.Signer.Sign(signRequest)
	if err != nil {
		log.Debugf("failed to sign node certificate: %v", err)
		return nil, err
	}

	return rca.AppendFirstRootPEM(cert)
}

// AppendFirstRootPEM appends the first certificate from this RootCA's cert
// bundle to the given cert bundle (which should already be encoded as a series
// of PEM-encoded certificate blocks).
func (rca *RootCA) AppendFirstRootPEM(cert []byte) ([]byte, error) {
	// Append the first root CA Cert to the certificate, to create a valid chain
	// Get the first Root CA Cert on the bundle
	firstRootCA, _, err := helpers.ParseOneCertificateFromPEM(rca.Cert)
	if err != nil {
		return nil, err
	}
	if len(firstRootCA) < 1 {
		return nil, fmt.Errorf("no valid Root CA certificates found")
	}
	// Convert the first root CA back to PEM
	firstRootCAPEM := helpers.EncodeCertificatePEM(firstRootCA[0])
	if firstRootCAPEM == nil {
		return nil, fmt.Errorf("error while encoding the Root CA certificate")
	}
	// Append this Root CA to the certificate to make [Cert PEM]\n[Root PEM][EOF]
	certChain := append(cert, firstRootCAPEM...)

	return certChain, nil
}

// NewRootCA creates a new RootCA object from unparsed PEM cert bundle and key byte
// slices. key may be nil, and in this case NewRootCA will return a RootCA
// without a signer.
func NewRootCA(certBytes, keyBytes []byte, certExpiry time.Duration) (RootCA, error) {
	// Parse all the certificates in the cert bundle
	parsedCerts, err := helpers.ParseCertificatesPEM(certBytes)
	if err != nil {
		return RootCA{}, err
	}
	// Check to see if we have at least one valid cert
	if len(parsedCerts) < 1 {
		return RootCA{}, fmt.Errorf("no valid Root CA certificates found")
	}

	// Create a Pool with all of the certificates found
	pool := x509.NewCertPool()
	for _, cert := range parsedCerts {
		// Check to see if all of the certificates are valid, self-signed root CA certs
		if err := cert.CheckSignature(cert.SignatureAlgorithm, cert.RawTBSCertificate, cert.Signature); err != nil {
			return RootCA{}, fmt.Errorf("error while validating Root CA Certificate: %v", err)
		}
		pool.AddCert(cert)
	}

	// Calculate the digest for our Root CA bundle
	digest := digest.FromBytes(certBytes)

	if len(keyBytes) == 0 {
		// This RootCA does not have a valid signer.
		return RootCA{Cert: certBytes, Digest: digest, Pool: pool}, nil
	}

	var (
		passphraseStr              string
		passphrase, passphrasePrev []byte
		priv                       crypto.Signer
	)

	// Attempt two distinct passphrases, so we can do a hitless passphrase rotation
	if passphraseStr = os.Getenv(PassphraseENVVar); passphraseStr != "" {
		passphrase = []byte(passphraseStr)
	}

	if p := os.Getenv(PassphraseENVVarPrev); p != "" {
		passphrasePrev = []byte(p)
	}

	// Attempt to decrypt the current private-key with the passphrases provided
	priv, err = helpers.ParsePrivateKeyPEMWithPassword(keyBytes, passphrase)
	if err != nil {
		priv, err = helpers.ParsePrivateKeyPEMWithPassword(keyBytes, passphrasePrev)
		if err != nil {
			log.Debug("Malformed private key %v", err)
			return RootCA{}, err
		}
	}

	// We will always use the first certificate inside of the root bundle as the active one
	if err := ensureCertKeyMatch(parsedCerts[0], priv.Public()); err != nil {
		return RootCA{}, err
	}

	signer, err := local.NewSigner(priv, parsedCerts[0], cfsigner.DefaultSigAlgo(priv), SigningPolicy(certExpiry))
	if err != nil {
		return RootCA{}, err
	}

	// If the key was loaded from disk unencrypted, but there is a passphrase set,
	// ensure it is encrypted, so it doesn't hit raft in plain-text
	keyBlock, _ := pem.Decode(keyBytes)
	if keyBlock == nil {
		// This RootCA does not have a valid signer.
		return RootCA{Cert: certBytes, Digest: digest, Pool: pool}, nil
	}
	if passphraseStr != "" && !x509.IsEncryptedPEMBlock(keyBlock) {
		keyBytes, err = EncryptECPrivateKey(keyBytes, passphraseStr)
		if err != nil {
			return RootCA{}, err
		}
	}

	return RootCA{Signer: signer, Key: keyBytes, Digest: digest, Cert: certBytes, Pool: pool}, nil
}

func ensureCertKeyMatch(cert *x509.Certificate, key crypto.PublicKey) error {
	switch certPub := cert.PublicKey.(type) {
	// TODO: Handle RSA keys.
	case *ecdsa.PublicKey:
		ecKey, ok := key.(*ecdsa.PublicKey)
		if ok && certPub.X.Cmp(ecKey.X) == 0 && certPub.Y.Cmp(ecKey.Y) == 0 {
			return nil
		}
	default:
		return fmt.Errorf("unknown or unsupported certificate public key algorithm")
	}

	return fmt.Errorf("certificate key mismatch")
}

// GetLocalRootCA validates if the contents of the file are a valid self-signed
// CA certificate, and returns the PEM-encoded Certificate if so
func GetLocalRootCA(baseDir string) (RootCA, error) {
	paths := NewConfigPaths(baseDir)

	// Check if we have a Certificate file
	cert, err := ioutil.ReadFile(paths.RootCA.Cert)
	if err != nil {
		if os.IsNotExist(err) {
			err = ErrNoLocalRootCA
		}

		return RootCA{}, err
	}

	key, err := ioutil.ReadFile(paths.RootCA.Key)
	if err != nil {
		if !os.IsNotExist(err) {
			return RootCA{}, err
		}
		// There may not be a local key. It's okay to pass in a nil
		// key. We'll get a root CA without a signer.
		key = nil
	}

	rootCA, err := NewRootCA(cert, key, DefaultNodeCertExpiration)
	if err == nil {
		log.Debugf("successfully loaded the Root CA: %s", paths.RootCA.Cert)
	}

	return rootCA, err
}

// GetRemoteCA returns the remote endpoint's CA certificate
func GetRemoteCA(ctx context.Context, d digest.Digest, picker *picker.Picker) (RootCA, error) {
	// We need a valid picker to be able to Dial to a remote CA
	if picker == nil {
		return RootCA{}, fmt.Errorf("valid remote address picker required")
	}

	// This TLS Config is intentionally using InsecureSkipVerify. Either we're
	// doing TOFU, in which case we don't validate the remote CA, or we're using
	// a user supplied hash to check the integrity of the CA certificate.
	insecureCreds := credentials.NewTLS(&tls.Config{InsecureSkipVerify: true})
	opts := []grpc.DialOption{
		grpc.WithTransportCredentials(insecureCreds),
		grpc.WithBackoffMaxDelay(10 * time.Second),
		grpc.WithPicker(picker)}

	firstAddr, err := picker.PickAddr()
	if err != nil {
		return RootCA{}, err
	}

	conn, err := grpc.Dial(firstAddr, opts...)
	if err != nil {
		return RootCA{}, err
	}
	defer conn.Close()

	client := api.NewCAClient(conn)
	response, err := client.GetRootCACertificate(ctx, &api.GetRootCACertificateRequest{})
	if err != nil {
		return RootCA{}, err
	}

	if d != "" {
		verifier, err := digest.NewDigestVerifier(d)
		if err != nil {
			return RootCA{}, fmt.Errorf("unexpected error getting digest verifier: %v", err)
		}

		io.Copy(verifier, bytes.NewReader(response.Certificate))

		if !verifier.Verified() {
			return RootCA{}, fmt.Errorf("remote CA does not match fingerprint. Expected: %s", d.Hex())

		}
	}

	// Check the validity of the remote Cert
	_, err = helpers.ParseCertificatePEM(response.Certificate)
	if err != nil {
		return RootCA{}, err
	}

	// Create a Pool with our RootCACertificate
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(response.Certificate) {
		return RootCA{}, fmt.Errorf("failed to append certificate to cert pool")
	}

	return RootCA{Cert: response.Certificate, Digest: digest.FromBytes(response.Certificate), Pool: pool}, nil
}

// CreateAndWriteRootCA creates a Certificate authority for a new Swarm Cluster, potentially
// overwriting any existing CAs.
func CreateAndWriteRootCA(rootCN string, paths CertPaths) (RootCA, error) {
	// Create a simple CSR for the CA using the default CA validator and policy
	req := cfcsr.CertificateRequest{
		CN:         rootCN,
		KeyRequest: &cfcsr.BasicKeyRequest{A: RootKeyAlgo, S: RootKeySize},
		CA:         &cfcsr.CAConfig{Expiry: RootCAExpiration},
	}

	// Generate the CA and get the certificate and private key
	cert, _, key, err := initca.New(&req)
	if err != nil {
		return RootCA{}, err
	}

	// Ensure directory exists
	err = os.MkdirAll(filepath.Dir(paths.Cert), 0755)
	if err != nil {
		return RootCA{}, err
	}

	// Write the Private Key and Certificate to disk, using decent permissions
	if err := ioutils.AtomicWriteFile(paths.Cert, cert, 0644); err != nil {
		return RootCA{}, err
	}
	if err := ioutils.AtomicWriteFile(paths.Key, key, 0600); err != nil {
		return RootCA{}, err
	}

	return NewRootCA(cert, key, DefaultNodeCertExpiration)
}

// BootstrapCluster receives a directory and creates both new Root CA key material
// and a ManagerRole key/certificate pair to be used by the initial cluster manager
func BootstrapCluster(baseCertDir string) error {
	paths := NewConfigPaths(baseCertDir)

	rootCA, err := CreateAndWriteRootCA(rootCN, paths.RootCA)
	if err != nil {
		return err
	}

	nodeID := identity.NewID()
	newOrg := identity.NewID()
	_, err = GenerateAndSignNewTLSCert(rootCA, nodeID, ManagerRole, newOrg, paths.Node)

	return err
}

// GenerateAndSignNewTLSCert creates a new keypair, signs the certificate using signer,
// and saves the certificate and key to disk. This method is used to bootstrap the first
// manager TLS certificates.
func GenerateAndSignNewTLSCert(rootCA RootCA, cn, ou, org string, paths CertPaths) (*tls.Certificate, error) {
	// Generate and new keypair and CSR
	csr, key, err := generateNewCSR()
	if err != nil {
		return nil, err
	}

	// Obtain a signed Certificate
	certChain, err := rootCA.ParseValidateAndSignCSR(csr, cn, ou, org)
	if err != nil {
		log.Debugf("failed to sign node certificate: %v", err)
		return nil, err
	}

	// Ensure directory exists
	err = os.MkdirAll(filepath.Dir(paths.Cert), 0755)
	if err != nil {
		return nil, err
	}

	// Write both the chain and key to disk
	if err := ioutils.AtomicWriteFile(paths.Cert, certChain, 0644); err != nil {
		return nil, err
	}
	if err := ioutils.AtomicWriteFile(paths.Key, key, 0600); err != nil {
		return nil, err
	}

	// Load a valid tls.Certificate from the chain and the key
	serverCert, err := tls.X509KeyPair(certChain, key)
	if err != nil {
		return nil, err
	}

	return &serverCert, nil
}

// GenerateAndWriteNewKey generates a new pub/priv key pair, writes it to disk
// and returns the CSR and the private key material
func GenerateAndWriteNewKey(paths CertPaths) (csr, key []byte, err error) {
	// Generate a new key pair
	csr, key, err = generateNewCSR()
	if err != nil {
		return
	}

	// Ensure directory exists
	err = os.MkdirAll(filepath.Dir(paths.Key), 0755)
	if err != nil {
		return
	}

	if err = ioutils.AtomicWriteFile(paths.Key, key, 0600); err != nil {
		return
	}

	return
}

// GetRemoteSignedCertificate submits a CSR to a remote CA server address
// available through a picker, and that is part of a CA identified by a
// specific certificate pool.
func GetRemoteSignedCertificate(ctx context.Context, csr []byte, token string, rootCAPool *x509.CertPool, picker *picker.Picker, creds credentials.TransportAuthenticator, nodeInfo chan<- api.IssueNodeCertificateResponse) ([]byte, error) {
	if rootCAPool == nil {
		return nil, fmt.Errorf("valid root CA pool required")
	}
	if picker == nil {
		return nil, fmt.Errorf("valid remote address picker required")
	}

	if creds == nil {
		// This is our only non-MTLS request, and it happens when we are boostraping our TLS certs
		// We're using CARole as server name, so an external CA doesn't also have to have ManagerRole in the cert SANs
		creds = credentials.NewTLS(&tls.Config{ServerName: CARole, RootCAs: rootCAPool})
	}

	opts := []grpc.DialOption{
		grpc.WithTransportCredentials(creds),
		grpc.WithBackoffMaxDelay(10 * time.Second),
		grpc.WithPicker(picker)}

	firstAddr, err := picker.PickAddr()
	if err != nil {
		return nil, err
	}

	conn, err := grpc.Dial(firstAddr, opts...)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	// Create a CAClient to retrieve a new Certificate
	caClient := api.NewNodeCAClient(conn)

	// Send the Request and retrieve the request token
	issueRequest := &api.IssueNodeCertificateRequest{CSR: csr, Token: token}
	issueResponse, err := caClient.IssueNodeCertificate(ctx, issueRequest)
	if err != nil {
		return nil, err
	}

	// Send back the NodeID on the nodeInfo, so the caller can know what ID was assigned by the CA
	if nodeInfo != nil {
		nodeInfo <- *issueResponse
	}

	statusRequest := &api.NodeCertificateStatusRequest{NodeID: issueResponse.NodeID}
	expBackoff := events.NewExponentialBackoff(events.ExponentialBackoffConfig{
		Base:   time.Second,
		Factor: time.Second,
		Max:    30 * time.Second,
	})

	log.Infof("Waiting for TLS certificate to be issued...")
	// Exponential backoff with Max of 30 seconds to wait for a new retry
	for {
		// Send the Request and retrieve the certificate
		statusResponse, err := caClient.NodeCertificateStatus(ctx, statusRequest)
		if err != nil {
			return nil, err
		}

		// If the certificate was issued, return
		if statusResponse.Status.State == api.IssuanceStateIssued {
			if statusResponse.Certificate == nil {
				return nil, fmt.Errorf("no certificate in CertificateStatus response")
			}

			// The certificate in the response must match the CSR
			// we submitted. If we are getting a response for a
			// certificate that was previously issued, we need to
			// retry until the certificate gets updated per our
			// current request.
			if bytes.Equal(statusResponse.Certificate.CSR, csr) {
				return statusResponse.Certificate.Certificate, nil
			}
		}

		// If we're still pending, the issuance failed, or the state is unknown
		// let's continue trying.
		expBackoff.Failure(nil, nil)
		time.Sleep(expBackoff.Proceed(nil))
	}
}

// readCertExpiration returns the number of months left for certificate expiration
func readCertExpiration(paths CertPaths) (time.Duration, error) {
	// Read the Cert
	cert, err := ioutil.ReadFile(paths.Cert)
	if err != nil {
		log.Debugf("failed to read certificate file: %s", paths.Cert)
		return time.Hour, err
	}

	// Create an x509 certificate out of the contents on disk
	certBlock, _ := pem.Decode([]byte(cert))
	if certBlock == nil {
		return time.Hour, fmt.Errorf("failed to decode certificate block")
	}
	X509Cert, err := x509.ParseCertificate(certBlock.Bytes)
	if err != nil {
		return time.Hour, err
	}

	return X509Cert.NotAfter.Sub(time.Now()), nil

}

func saveRootCA(rootCA RootCA, paths CertPaths) error {
	// Make sure the necessary dirs exist and they are writable
	err := os.MkdirAll(filepath.Dir(paths.Cert), 0755)
	if err != nil {
		return err
	}

	// If the root certificate got returned successfully, save the rootCA to disk.
	return ioutils.AtomicWriteFile(paths.Cert, rootCA.Cert, 0644)
}

func generateNewCSR() (csr, key []byte, err error) {
	req := &cfcsr.CertificateRequest{
		KeyRequest: cfcsr.NewBasicKeyRequest(),
	}

	csr, key, err = cfcsr.ParseRequest(req)
	if err != nil {
		log.Debugf(`failed to generate CSR`)
		return
	}

	return
}

// EncryptECPrivateKey receives a PEM encoded private key and returns an encrypted
// AES256 version using a passphrase
// TODO: Make this method generic to handle RSA keys
func EncryptECPrivateKey(key []byte, passphraseStr string) ([]byte, error) {
	passphrase := []byte(passphraseStr)
	cipherType := x509.PEMCipherAES256

	keyBlock, _ := pem.Decode(key)
	if keyBlock == nil {
		// This RootCA does not have a valid signer.
		return nil, fmt.Errorf("error while decoding PEM key")
	}

	encryptedPEMBlock, err := x509.EncryptPEMBlock(rand.Reader,
		"EC PRIVATE KEY",
		keyBlock.Bytes,
		passphrase,
		cipherType)
	if err != nil {
		return nil, err
	}

	if encryptedPEMBlock.Headers == nil {
		return nil, fmt.Errorf("unable to encrypt key - invalid PEM file produced")
	}

	return pem.EncodeToMemory(encryptedPEMBlock), nil
}
