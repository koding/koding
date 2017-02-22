package tunnelproxymanager

import "github.com/aws/aws-sdk-go/aws/session"

// Config holds configuration parameters for tunnelproxymanager
type Config struct {
	// required
	AccessKeyID     string `required:"true"`
	SecretAccessKey string `required:"true"`

	Route53AccessKeyID     string `required:"true"`
	Route53SecretAccessKey string `required:"true"`

	// can be overridden
	Region          string
	EBEnvName       string
	AutoScalingName string
	HostedZone      HostedZone // defaults are in struct tags

	Session        *session.Session
	Route53Session *session.Session
	// optional
	Debug bool
}

type HostedZone struct {
	Name            string `default:"t.koding.com"`
	CallerReference string `default:"tunnelproxy_hosted_zone_v0"`
}
