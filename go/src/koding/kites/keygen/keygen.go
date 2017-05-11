package keygen

import (
	"errors"
	"fmt"
	"time"

	"koding/kites/kloud/api/amazon"
	"koding/kites/metrics"

	dogstatsd "github.com/DataDog/datadog-go/statsd"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sts"
	"github.com/koding/kite"
	"github.com/koding/logging"
)

// TODO(rjeczalik): refactor Server/Provider to support multiple auth types (AuthRequest.Type)

var defaultLog = logging.NewCustom("keygen", false)

// DefaultBefore is a default behavior for Config.BeforeFunc field.
var DefaultBefore = func(expire time.Time) bool {
	return expire.Before(time.Now())
}

// Config defines configuration for Server, Provider and UserBucket types.
//
// TODO(rjeczalik): Split into ServerConfig / ClientConfig.
type Config struct {
	RootUser string // kite user allowed to impersonate other users; "koding" by default

	// S3 auth configuration
	AccessKey string // AWS access key; required
	SecretKey string // AWS secret key; required
	Bucket    string // S3 bucket resource for "s3" auth; required
	Region    string // S3 bucket region; "us-east-1" by default

	// AuthFuc is used to authorize temporary credential request
	// on top of kite authorization.
	//
	// If nil, only kite authorization is performed.
	AuthFunc func(*AuthRequest) error

	// AuthExpire is time after which auth obtained from
	// the servers expires.
	//
	// If 0, the default of 3h is used.
	AuthExpire time.Duration

	ProviderType string // value for Provider.Type; defaults to "s3"
	Kite         *kite.Kite
	ServerURL    string
	Timeout      time.Duration        // max time of client<->server communication; 15s by default
	BeforeFunc   func(time.Time) bool // time func to check expiration against; by default DefaultBefore is used
	Metrics      *dogstatsd.Client
	Log          logging.Logger
}

func (cfg *Config) username() string {
	if cfg.Kite == nil {
		return ""
	}

	if cfg.Kite.Config == nil {
		return ""
	}

	return cfg.Kite.Config.Username
}

func (cfg *Config) region() string {
	if cfg.Region != "" {
		return cfg.Region
	}

	return "us-east-1"
}

func (cfg *Config) log() logging.Logger {
	if cfg.Log != nil {
		return cfg.Log
	}

	return defaultLog
}

// AuthRequest represents request message for the "keygen.auth" method.
type AuthRequest struct {
	User string `json:"user"`
	Type string `json:"type"`
}

// AuthResponse represents response message for the "keygen.auth" method.
type AuthResponse struct {
	Type     string      `json:"type"`
	Resource string      `json:"resource"`
	Value    interface{} `json:"value"`
}

// Server is a keygen server.
type Server struct {
	cfg *Config
	sts *sts.STS
	s3  *s3.S3
}

// NewServer gives new server value created from the given configuration.
func NewServer(cfg *Config) *Server {
	awsCfg := &aws.Config{
		Credentials: credentials.NewStaticCredentials(cfg.AccessKey, cfg.SecretKey, ""),
		Region:      aws.String(cfg.region()),
	}

	if cfg.Log != nil {
		awsCfg.Logger = amazon.NewLogger(cfg.Log.Debug)
	}

	sess := session.New(awsCfg)

	s := &Server{
		cfg: cfg,
		sts: sts.New(sess),
		s3:  s3.New(sess),
	}

	if s.cfg.Kite != nil {
		s.cfg.Kite.HandleFunc("keygen.auth", metrics.WrapKiteHandler(cfg.Metrics, "keygen.auth", s.Auth))
	}

	return s
}

// Auth is a kite handler for the "keygen.auth" method.
func (s *Server) Auth(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, errors.New("missing argument")
	}

	var req AuthRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

	if req.User != s.rootUser() {
		req.User = r.Username
	}

	if err := s.userAuth(&req); err != nil {
		return nil, err
	}

	if req.Type != "s3" {
		return nil, fmt.Errorf("authorization type not supported: %q", req.Type)
	}

	policy := fmt.Sprintf(stsPolicyTmpl, s.cfg.Bucket, req.User)

	token := &sts.GetFederationTokenInput{
		Name:            &req.User,
		DurationSeconds: aws.Int64(int64(s.expire() / time.Second)),
		Policy:          &policy,
	}

	resp, err := s.sts.GetFederationToken(token)
	if err != nil {
		return nil, err
	}

	s.cfg.log().Debug("GetFedetationToken()=%+v", resp)

	policy = fmt.Sprintf(s3PolicyTmpl, s.cfg.Bucket, req.User, aws.StringValue(resp.FederatedUser.Arn))

	bucket := &s3.PutBucketPolicyInput{
		Bucket: &s.cfg.Bucket,
		Policy: aws.String(policy),
	}

	s.cfg.log().Debug("PutBucketPolicy()=%+v", bucket)

	_, err = s.s3.PutBucketPolicy(bucket)
	if err != nil {
		return nil, err
	}

	// TODO(rjeczalik): refactor "s3" to separate AuthProvider
	res := fmt.Sprintf("arn:aws:s3:::%s/%s", s.cfg.Bucket, req.User)

	return &AuthResponse{
		Type:     "s3",
		Resource: res,
		Value:    resp.Credentials,
	}, nil
}

func (s *Server) expire() time.Duration {
	if s.cfg.AuthExpire != 0 {
		return s.cfg.AuthExpire
	}

	return 3 * time.Hour
}

func (s *Server) rootUser() string {
	if s.cfg.RootUser != "" {
		return s.cfg.RootUser
	}

	return "koding"
}

func (s *Server) userAuth(cr *AuthRequest) error {
	if s.cfg.AuthFunc != nil {
		return s.cfg.AuthFunc(cr)
	}

	return nil
}

// Provider provides an implementation for the AWS credentials.Provider
// by obtaining temporary token from keygen server.
type Provider struct {
	cfg    *Config
	expire time.Time
}

var _ credentials.Provider = (*Provider)(nil)

// NewProvider gives new provider value created from the given configuration.
func NewProvider(cfg *Config) *Provider {
	p := &Provider{
		cfg: cfg,
	}

	return p
}

// Retrieve implements the credentials.Provider interface.
func (p *Provider) Retrieve() (v credentials.Value, err error) {
	client := p.cfg.Kite.NewClient(p.cfg.ServerURL)
	client.Auth = &kite.Auth{
		Type: "kiteKey",
		Key:  p.cfg.Kite.KiteKey(),
	}

	if err := client.DialTimeout(p.timeout()); err != nil {
		return v, err
	}

	defer client.Close()

	req := &AuthRequest{
		Type: p.typ(),
	}

	part, err := client.TellWithTimeout("keygen.auth", p.timeout(), req)
	if err != nil {
		return v, err
	}

	var cred sts.Credentials

	resp := &AuthResponse{
		Value: &cred,
	}

	if err := part.Unmarshal(resp); err != nil {
		return v, err
	}

	if resp.Type != req.Type {
		return v, fmt.Errorf("authorization type not expected: %q", resp.Type)
	}

	p.expire = aws.TimeValue(cred.Expiration)

	p.cfg.log().Debug("Retrieve()=%+v", resp)

	return credentials.Value{
		AccessKeyID:     aws.StringValue(cred.AccessKeyId),
		SecretAccessKey: aws.StringValue(cred.SecretAccessKey),
		SessionToken:    aws.StringValue(cred.SessionToken),
		ProviderName:    "keygen",
	}, nil
}

// IsExpired implements the credentials.Provider interface.
func (p *Provider) IsExpired() bool {
	return p.before(p.expire)
}

func (p *Provider) timeout() time.Duration {
	if p.cfg.Timeout != 0 {
		return p.cfg.Timeout
	}

	return 15 * time.Second
}

func (p *Provider) typ() string {
	if p.cfg.ProviderType != "" {
		return p.cfg.ProviderType
	}

	return "s3"
}

func (p *Provider) before(t time.Time) bool {
	if p.cfg.BeforeFunc != nil {
		return p.cfg.BeforeFunc(t)
	}

	return DefaultBefore(t)
}
